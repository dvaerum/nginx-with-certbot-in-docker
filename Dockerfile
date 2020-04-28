FROM ubuntu:latest
MAINTAINER Dennis Værum <nn@varum.dk>

RUN apt-get update
RUN apt-get upgrade --Yes
RUN apt-get install --Yes software-properties-common
RUN add-apt-repository ppa:certbot/certbot
RUN apt-get update
RUN apt-get install --Yes certbot nginx
RUN apt-get install --Yes cron

### PLUGIN SCRIPTS ###
COPY plugins /plugins

### CONFIG NGINX ###
RUN rm /etc/nginx/sites-enabled/default
RUN rm /etc/nginx/sites-available/default
COPY nginx /etc/nginx

### CONFIG CRON ###
ADD certbot-renew-cron /etc/cron.daily/certbot-renew-cron
RUN chmod 0755 /etc/cron.daily/certbot-renew-cron
RUN touch /var/log/cron.log

COPY env.sh /env.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
