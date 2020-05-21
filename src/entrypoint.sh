#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

### Enable "exit on error (errexit)", "exit on unbound variables (nounset) & "job controller (monitor)"
set -eum

### Option enable debugging (xtrace)
[ -n "${DEBUG_BASH:-}" ] && set -x

source "/env.sh"

### Make an "array" containing all the domains
IFS=', ' read -r -a domains <<< "${DOMAINS-}"

### Select CLI tool
if [ -z "${CLI_TOOL:-}" ]; then
    CLI_TOOL=certbot
elif [ "${CLI_TOOL}" == "certbot" ] || [ "${CLI_TOOL}" == "acme.sh" ] ; then
    echo "The cli tool '${CLI_TOOL}' will be used"
else
    echo "The variable CLI_TOOL can only be 'certbot' or 'acme.sh' and currently it is '${CLI_TOOL}'"
    exit 1
fi

### Select acme challenge method
if [ -z "${ACME_METHOD:-}" ]; then
    ACME_METHOD=http
elif [ "${ACME_METHOD}" == "http" ]; then
    echo "The acme challenge selected is '${ACME_METHOD}'"
elif [ "${ACME_METHOD::3}" == "dns" ]; then
    [ "${CLI_TOOL}" == "certbot" ] && ACME_METHOD="dns-${ACME_METHOD:4}"
    [ "${CLI_TOOL}" == "acme.sh" ] && ACME_METHOD="dns_${ACME_METHOD:4}"
    echo "The acme challenge selected is '${ACME_METHOD}'"
else
    echo "The variable ACME_METHOD can only be 'http' or 'dns-FOLLOW_BY_PLUGIN' and currently it is '${ACME_METHOD}'"
    exit 1
fi

### Extra argument to enable testing and debugging
extra_args=""
if [ "${CLI_TOOL}" == "certbot" ]; then
    [ -n "${TEST:-}" ] && extra_args="${extra_args} --test-cert"
fi
if [ "${CLI_TOOL}" == "acme.sh" ]; then
    [ -n "${TEST:-}" ] && extra_args="${extra_args} --test"
    [ -n "${DEBUG:-}" ] && extra_args="${extra_args} --debug"
fi
export extra_args

### Make sure these files are removed
rm -f "/etc/letsencrypt/live/README" "${LETSENCRYPT_LOG}"


#############################
echo Enable/Disable logs  ###
#############################
if [ "$(tr '[:upper:]' '[:lower:]' <<< ${NGINX_LOG_ACCESS:-y})" == "y" ]; then
    sed -Ei 's:^([[:space:]]*)access_log.*:\1access_log /dev/stdout;:' /etc/nginx/nginx.conf
else
    sed -Ei 's:^([[:space:]]*)access_log.*:\1access_log /dev/null;:' /etc/nginx/nginx.conf
fi

if [ "$(tr '[:upper:]' '[:lower:]' <<< ${NGINX_LOG_ERROR:-y})" == "y" ]; then
    sed -Ei 's:^([[:space:]]*)error_log.*:\1error_log /dev/stderr;:' /etc/nginx/nginx.conf
else
    sed -Ei 's:^([[:space:]]*)error_log.*:\1error_log /dev/null;:' /etc/nginx/nginx.conf
fi


#############################
echo Start background job ###
#############################
while true; do sleep ${RENEW_INTERVAL:-1d}; /certs-renew.sh; done &
jobs -l


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
jobs -l


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
            ### CertBot
            if [ "${CLI_TOOL}" == "certbot" ]; then
                certbot revoke --non-interactive --cert-path "${LETSENCRYPT_LIVE}/${old_domain}/cert.pem" ${extra_args}
                _rc=$?
                echo "Certbot - Return Code: ${_rc}"
                if [ ${_rc} -ne 0 ]; then
                    cat ${LETSENCRYPT_LOG}
                fi

                rm -rf "${LETSENCRYPT}/archive/${old_domain}"
                rm -rf "${LETSENCRYPT}/live/${old_domain}"
                rm -rf "${LETSENCRYPT}/renewal/${old_domain}.conf"
            fi
            ### acme.sh
            if [ "${CLI_TOOL}" == "acme.sh" ]; then
                acme.sh --revoke --domain "${old_domain}" ${extra_args}
                acme.sh --remove --domain "${old_domain}" ${extra_args}

                rm -rf "${LETSENCRYPT}/certs/${old_domain}"
                rm -rf "${LETSENCRYPT}/live/${old_domain}"
            fi
        fi
    done
fi


#############################
echo Add new certificates ###
#############################
for domain in ${domains[@]}; do
    if ! [ -d "${LETSENCRYPT}/${domain}" ]; then
        ### CertBot
        if [ "${CLI_TOOL}" == "certbot" ]; then
            ### HTTP Challenge
            if [ "${ACME_METHOD}" == "http" ]; then
                certbot certonly --domains "${domain}" --webroot --non-interactive --email "${EMAIL}" --agree-tos -w "/var/www/letsencrypt" ${extra_args}
                _rc=$?
            fi

            ### DNS Challenge
            if [ "${ACME_METHOD::3}" == "dns" ]; then
                echo "Not implemented for certbot"
                exit 1
            fi

            echo "Certbot - Return Code: ${_rc}"
            if [ ${_rc} -ne 0 ]; then
                cat ${LETSENCRYPT_LOG}
            fi
        fi
        ### acme.sh
        if [ "${CLI_TOOL}" == "acme.sh" ]; then
            mkdir -p "/etc/letsencrypt/certs/${domain}" "/etc/letsencrypt/live/${domain}"
            chmod 700 "/etc/letsencrypt/certs/${domain}"

            ### HTTP Challenge
            if [ "${ACME_METHOD}" == "http" ]; then
                acme.sh --issue --webroot "/var/www/letsencrypt" ${extra_args} --domain "${domain}"
            fi

            ### DNS Challenge
            if [ "${ACME_METHOD::3}" == "dns" ]; then
                acme.sh --issue --dns "${ACME_METHOD}" --dnssleep 300  ${extra_args} --domain "${domain}"
            fi

            ln -s "../../certs/${domain}/${domain}.cer" "/etc/letsencrypt/live/${domain}/cert.pem"
            ln -s "../../certs/${domain}/ca.cer"        "/etc/letsencrypt/live/${domain}/chain.pem"
            ln -s "../../certs/${domain}/fullchain.cer" "/etc/letsencrypt/live/${domain}/fullchain.pem"
            ln -s "../../certs/${domain}/${domain}.key" "/etc/letsencrypt/live/${domain}/privkey.pem"
        fi
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


#####################################
echo Call nginx to the foreground ###
#####################################
jobs -l
fg
