#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

### Sleep, if nginx is not ready
while ! ps aux | grep www-data | grep --quiet 'nginx: worker process'; do
    sleep 1;
done

