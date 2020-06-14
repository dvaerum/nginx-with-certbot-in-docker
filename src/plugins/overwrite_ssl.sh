#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

set -ue

SSL_CONF="/etc/nginx/snippets/ssl.conf"

# add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload";
sed -i "s/^#*add_header Strict-Transport-Security.*/add_header Strict-Transport-Security \"${STRICT_TRANSPORT_SECURITY:-max-age=15768000; includeSubdomains; preload}\";/" "${SSL_CONF}"

# add_header Content-Security-Policy   "nosniff";
sed -i   "s/^#*add_header Content-Security-Policy.*/add_header Content-Security-Policy   \"${CONTENT_SECURITY_POLICY:-frame-ancestors 'none'}\";/" "${SSL_CONF}"

# add_header X-Content-Type-Options    "nosniff";
sed -i    "s/^#*add_header X-Content-Type-Options.*/add_header X-Content-Type-Options    \"${X_CONTENT_TYPE_OPTIONS:-nosniff}\";/" "${SSL_CONF}"

# add_header X-Frame-Options           "DENY";
sed -i           "s/^#*add_header X-Frame-Options.*/add_header X-Frame-Options           \"${X_FRAME_OPTIONS:-DENY}\";/" "${SSL_CONF}"

PLUGIN_SSL_DISABLE_HEADER="${PLUGIN_SSL_DISABLE_HEADER:-X-Frame-Options}"
# NOTE: The `,,` in `${PLUGIN_SSL_DISABLE_HEADER,,}` make everything lowercase
for header in ${PLUGIN_SSL_DISABLE_HEADER,,}; do
    if [[ "${header}" =~ ^(strict-transport-security|content-security-policy|x-content-type-options|x-frame-options)$ ]]; then
        sed -i -e "s/^[^#].*${header}.*/#&/I" "${SSL_CONF}"
    fi
done

