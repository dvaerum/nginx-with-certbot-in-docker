FROM ubuntu:latest
MAINTAINER Dennis Værum <github@varum.dk>

RUN apt-get update
RUN apt-get upgrade --Yes
RUN apt-get install --Yes certbot nginx
RUN apt-get install --Yes curl socat
#RUN apt-get install --Yes supervisor

### CONFIG SUPERVISORD
#ADD src/etc /etc

### PLUGIN SCRIPTS ###
COPY src/plugins /plugins

### CONFIG NGINX ###
#RUN sed -Ei '/^[[:space:]]*(pid)/d' /etc/nginx/nginx.conf
RUN sed -Ei '1 i daemon off;' /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN rm /etc/nginx/sites-available/default
RUN mkdir -p /var/www/letsencrypt
COPY src/nginx /etc/nginx

### ADD SCRIPTS ###
COPY src/env.sh /env.sh
COPY src/certs-renew.sh /certs-renew.sh
COPY src/entrypoint.sh /entrypoint.sh

### acme.sh
ADD acme.sh /opt/acme.sh
RUN ln -s /opt/acme.sh/acme.sh /usr/bin/acme.sh

#ENTRYPOINT [ "/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf" ]
ENTRYPOINT [ "/entrypoint.sh" ]
