#!/usr/bin/env bash
set -ux

source "/env.sh"

mkdir -p "$CERT"

: "${DOMAINS:=}"
IFS=', ' read -r -a domains <<< "$DOMAINS"

####################
echo Start Nginx ###
####################
new_domains=0

if ! [ -f "$DHPARAM"  ]; then
    openssl dhparam -out "$DHPARAM" 2048
fi

for domain in ${domains[@]}; do
    if ! [ -d "$LETSENCRYPT_LIVE/$domain" ]; then
        new_domains=1
    fi
done

if [ $new_domains -eq 1 ]; then
    rm -f "$NGINX_ENABLED"/*
fi
/usr/sbin/nginx &


##############################################
echo Revoke and remove unused certificates ###
##############################################
if [ -d "$LETSENCRYPT_LIVE" ]; then
    for old_domain in $LETSENCRYPT_LIVE/*; do
	old_domain="$(basename $old_domain)"
    	remove=1
    	for new_domain in ${domains[@]}; do
    	    if [ "$old_domain" = "$new_domain" ]; then
       	    	remove=0
       	    fi
   	done
    	if [ $remove -eq 1 ]; then
            certbot revoke --non-interactive --cert-path "$LETSENCRYPT_LIVE/${old_domain}/cert.pem"
	    rm -rf "$LETSENCRYPT/archive/$old_domain"
	    rm -rf "$LETSENCRYPT/live/$old_domain"
            rm -rf "$LETSENCRYPT/renewal/$old_domain.conf"
    	fi
    done
fi


#############################
echo Add new certificates ###
#############################
for domain in ${domains[@]}; do
    if ! [ -d "$LETSENCRYPT/$domain" ]; then
        certbot certonly --domains "${domain}" --webroot --non-interactive --email "${EMAIL}" --agree-tos -w /var/www/letsencrypt
    fi
done

##################################
echo Enable all available site ###
##################################
for config_file in "$NGINX_AVAILABLE"/*; do
    if ! [ -h "$NGINX_ENABLED/$(basename $config_file)" ]; then
        ln -s "../sites-available/$(basename $config_file)" "$NGINX_ENABLED/$(basename $config_file)"
    fi
done
/usr/sbin/nginx -s reload


##########################
echo Start cron daemon ###
##########################
cron &


#####################################
echo Follow logs for nginx & cron ###
#####################################
if [ "$(tr '[:upper:]' '[:lower:]' <<< $NGINX_LOG_ACCESS)" = "y" ]; then
    NGINX_LOG_ACCESS="/var/log/nginx/access.log"
else
    NGINX_LOG_ACCESS=""
fi

if [ "$(tr '[:upper:]' '[:lower:]' <<< $NGINX_LOG_ERROR)" = "y" ]; then
    NGINX_LOG_ERROR="/var/log/nginx/error.log"
else
    NGINX_LOG_ERROR=""
fi

tail -f "$NGINX_LOG_ACCESS" "$NGINX_LOG_ERROR" "/var/log/cron.log"
