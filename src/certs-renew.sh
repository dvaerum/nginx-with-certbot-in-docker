#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

### Enable "exit on error (errexit)" & "exit on unbound variables (nounset)"
set -u
### Option enable debugging (xtrace)
[ -n "${DEBUG_BASH:-}" ] && set -x

source "/env.sh"

###########################
echo Renew certificates ###
###########################

if [ -d "${LETSENCRYPT_LIVE}" ]; then
    ### CertBot
    if [ "${CLI_TOOL}" == "certbot" ]; then
        ### HTTP Challenge
        if [ "${ACME_METHOD}" == "http" ]; then
            certbot renew --webroot -w /var/www/letsencrypt ${extra_args}
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
        acme.sh --renew-all ${extra_args}
    fi
    /usr/sbin/nginx -s reload
fi

