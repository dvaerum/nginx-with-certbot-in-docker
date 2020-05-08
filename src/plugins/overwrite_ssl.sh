#!/usr/bin/env bash

set -ue

sed -i "s/^add_header X-Frame-Options.*/add_header X-Frame-Options \"${X_FRAME_OPTIONS:-DENY}\";/" "/etc/nginx/snippets/ssl.conf"

