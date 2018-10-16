#!/usr/bin/env bash
set -eu

LETSENCRYPT="/etc/letsencrypt"
LETSENCRYPT_LIVE="$LETSENCRYPT/live"
NGINX="/etc/nginx"
NGINX_AVAILABLE="$NGINX/sites-available"
NGINX_ENABLED="$NGINX/sites-enabled"

IFS=', ' read -r -a domains <<< "$DOMAINS"

###################
### Start Nginx ###
###################
new_domains=0
nginx_pid=0

for domain in "${domains[@]}"; do
    if ! [ -d "$LETSENCRYPT_LIVE/$domain" ]; then
        new_domains=1
    fi
done

if [ $new_domains -eq 1 ]; then
    rm -f "$NGINX_ENABLED"/*
fi
/usr/sbin/nginx &
nginx_pid=$!


#############################################
### Revoke and remove unused certificates ###
#############################################
for $old_domain in "$LETSENCRYPT_LIVE/*"; do
    remove=1
    for $new_domain in "${domains[@]}"; do
        if [ "$old_domain" = "$new_domain" ]; then
            remove=0
        fi
    done
    if [ $remove -eq 1 ]; then
        certbot revoke --cert-path "$LETSENCRYPT_LIVE/${old_domain}/cert.pem"
        rm -rf "$LETSENCRYPT/archive/$old_domain"
        rm -rf "$LETSENCRYPT/live/$old_domain"
        rm -rf "$LETSENCRYPT/renewal/$old_domain.conf"
    fi
done


############################
### Add new certificates ###
############################
for $domain in "${domains[@]}"; do
    if ! [ -d "$LETSENCRYPT/$domain" ]; then
        certbot certonly --domains collabora.best.aau.dk --webroot -w /var/www/letsencrypt
    fi
done

#####################
###
#######################
for $config_file in "$NGINX_AVAILABLE/*"; do
    if ! [ -h "$NGINX_ENABLED/$(basename $config_file)" ]; then
        ln -s "../sites-available/$(basename $config_file)" "$NGINX_ENABLED/$(basename $config_file)"
    fi
done
/usr/sbin/nginx -s reload

##########################
### Renew certificates ###
##########################
certbot_pid=0
if [ -d $LETSENCRYPT_LIVE ]; then
    certbot renew --webroot -w /var/www/letsencrypt &
    certbot_pid=$!
fi

###################
###
######################
if [ $certbot_pid -gt 0 ]; then
    wait $certbot
fi

fg
