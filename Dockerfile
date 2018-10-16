FROM ubuntu:latest
MAINTAINER Dennis Værum <nn@varum.dk>

RUN apt-get update
RUN apt-get upgrade --Yes
RUN apt-get install --Yes software-properties-common
RUN add-apt-repository ppa:certbot/certbot
RUN apt-get update
RUN apt-get install --Yes certbot nginx

### CONFIG NGINX ###
RUN rm /etc/nginx/sites-enabled/default
RUN rm /etc/nginx/sites-available/default
# RUN /usr/bin/openssl dhparam -out /etc/nginx/dhparams.pem 2048
COPY nginx /etc/nginx

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
