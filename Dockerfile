FROM ubuntu:latest
MAINTAINER Dennis Værum <nn@varum.dk>

RUN apt-get update
RUN apt-get upgrade --Yes
RUN apt-get install --Yes certbot nginx cron
RUN apt-get install --Yes curl

run curl https://get.acme.sh | sh

### PLUGIN SCRIPTS ###
COPY src/plugins /plugins

### CONFIG NGINX ###
RUN rm /etc/nginx/sites-enabled/default
RUN rm /etc/nginx/sites-available/default
COPY src/nginx /etc/nginx

### CONFIG CRON ###
COPY src/certbot-renew-cron /etc/cron.daily/certbot-renew-cron
RUN chmod 0755 /etc/cron.daily/certbot-renew-cron
RUN touch /var/log/cron.log

COPY src/env.sh /env.sh
COPY src/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
