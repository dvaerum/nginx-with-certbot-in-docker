#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

set -u

if [ "${DEBUG:-}" != '' ]; then
    set -x
fi

source "/env.sh"

mkdir -p "${CERT}"

#: "${DOMAINS:=}"
IFS=', ' read -r -a domains <<< "${DOMAINS-}"

### Clean-up old log files
LETSENCRYPT_LOG="/var/log/letsencrypt/letsencrypt.log"
NGINX_LOG_ACCESS="/var/log/nginx/access.log"
NGINX_LOG_ERROR="/var/log/nginx/error.log"
rm -f ${NGINX_LOG_ACCESS} ${NGINX_LOG_ERROR} ${LETSENCRYPT_LOG}
touch "${NGINX_LOG_ACCESS}"
touch "${NGINX_LOG_ERROR}"


###########################
echo Run plugin scripts ###
###########################
for file in /plugins/*.sh; do
    if [ -x ${file} ]; then
        ${file}
    fi
done


####################
echo Start Nginx ###
####################
new_domains=0

if ! [ -f "${DHPARAM}"  ]; then
    openssl dhparam -out "${DHPARAM}" 2048
fi

for domain in ${domains[@]}; do
    if ! [ -d "${LETSENCRYPT_LIVE}/${domain}" ]; then
        new_domains=1
    fi
done

if [ ${new_domains} -eq 1 ]; then
    rm -f "${NGINX_ENABLED}"/*
fi
/usr/sbin/nginx &


##############################################
echo Revoke and remove unused certificates ###
##############################################
if [ -d "${LETSENCRYPT_LIVE}" ]; then
    for old_domain in ${LETSENCRYPT_LIVE}/*; do
	old_domain="$(basename ${old_domain})"
    	remove=1
    	for new_domain in ${domains[@]}; do
    	    if [ "${old_domain}" = "${new_domain}" ]; then
       	    	remove=0
       	    fi
   	done
    	if [ ${remove} -eq 1 ]; then
            certbot revoke --non-interactive --cert-path "${LETSENCRYPT_LIVE}/${old_domain}/cert.pem"
            echo "Certbot - Return Code: '$?'"
	    rm -rf "${LETSENCRYPT}/archive/${old_domain}"
	    rm -rf "${LETSENCRYPT}/live/${old_domain}"
            rm -rf "${LETSENCRYPT}/renewal/${old_domain}.conf"
    	fi
    done
fi


#############################
echo Add new certificates ###
#############################
extra_args=""
if [ "${TEST:-}" != "" ]; then
    extra_args="${extra_args} --dry-run"
fi

for domain in ${domains[@]}; do
    if ! [ -d "${LETSENCRYPT}/${domain}" ]; then
        certbot certonly --domains "${domain}" --webroot --non-interactive --email "${EMAIL}" --agree-tos -w "/var/www/letsencrypt" ${extra_args}
        echo "Certbot - Return Code: '$?'"
    fi
done


##################################
echo Enable all available site ###
##################################
for config_file in "${NGINX_AVAILABLE}"/*; do
    if ! [ -h "${NGINX_ENABLED}/$(basename ${config_file})" ]; then
        ln -s "../sites-available/$(basename ${config_file})" "${NGINX_ENABLED}/$(basename ${config_file})"
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
files_to_follow="/var/log/cron.log"

if ! [ "$(tr '[:upper:]' '[:lower:]' <<< ${NGINX_LOG_ACCESS})" = "y" ]; then
    files_to_follow="${files_to_follow} ${NGINX_LOG_ACCESS}"
fi

if ! [ "$(tr '[:upper:]' '[:lower:]' <<< ${NGINX_LOG_ERROR})" = "y" ]; then
    files_to_follow="${files_to_follow} ${NGINX_LOG_ERROR}"
fi

tail -f ${files_to_follow}
