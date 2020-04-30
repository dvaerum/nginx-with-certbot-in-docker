#!/usr/bin/env bash

LETSENCRYPT="/etc/letsencrypt"
LETSENCRYPT_LIVE="$LETSENCRYPT/live"
NGINX="/etc/nginx"
NGINX_AVAILABLE="$NGINX/sites-available"
NGINX_ENABLED="$NGINX/sites-enabled"
CERT="/var/www/letsencrypt"
DHPARAM="$LETSENCRYPT/dhparams.pem"
EMAIL="${EMAIL:-nn@nn.nn}"

