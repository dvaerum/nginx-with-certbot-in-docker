#!/usr/bin/env bash

LETSENCRYPT="/etc/letsencrypt"
LETSENCRYPT_LIVE="${LETSENCRYPT}/live"
LETSENCRYPT_LOG="/var/log/letsencrypt/letsencrypt.log"
NGINX="/etc/nginx"
NGINX_AVAILABLE="${NGINX}/sites-available"
NGINX_ENABLED="${NGINX}/sites-enabled"
DHPARAM="${LETSENCRYPT}/dhparams.pem"
EMAIL="${EMAIL:-nn@gmail.com}"

### Set default tool and method
CLI_TOOL="${CLI_TOOL:-certbot}"
ACME_METHOD="${ACME_METHOD:-http}"


### Variables for acme.sh
export LE_WORKING_DIR="/opt/acme.sh"
export LE_CONFIG_HOME="${LETSENCRYPT}/config"
export CERT_HOME="${LETSENCRYPT}/certs"
export ACCOUNT_EMAIL="${EMAIL}"
