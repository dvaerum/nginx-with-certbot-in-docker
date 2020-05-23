#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab:

set -eu

TEST_FOLDER="$PWD/test"
#ARGS="-v ${TEST_FOLDER}/sites-available:/etc/nginx/sites-available --env TEST=1 --env DEBUG=1 --env DOMAINS=test.varum.dk --env DEBUG_BASH=1 --env RENEW_INTERVAL=1m"
ARGS="-v ${TEST_FOLDER}/sites-available:/etc/nginx/sites-available --env TEST=1 --env DOMAINS=test.varum.dk --env DEBUG_BASH=1"


if ! [ -d "test" ]; then
    echo "Could not find the folder: test"
    exit 1
fi
if [ -z "${ACME_METHOD:-}" ] || [ -z "${DOMAIN:-}" ] || [ -z "${DOCKER_ENV:-}" ]; then
    echo "read the test/README.md file"
    exit 1
fi

curl --silent 'https://letsencrypt.org/certs/fakelerootx1.pem' --output "$TEST_FOLDER/fakelerootx1.pem"


### Build and remove old contianers
[ -n "$(docker ps --format '{{.Image}} {{.ID}}' | awk '/certbot/ {print $2}')" ] && docker stop $(docker ps --format '{{.Image}} {{.ID}}' | awk '/certbot/ {print $2}')
./build.sh --build


### TEST DNS Challenge (acme.sh)
dns_challenge() {
    docker_id=$(docker run \
        ${DOCKER_ENV} \
        --env CLI_TOOL="acme.sh" \
        --env ACME_METHOD="${ACME_METHOD}" \
        --env DOMAINS="${DOMAIN}" \
        ${ARGS} \
        --detach dvaerum/nginx-with-certbot-in-docker:dev)


    docker logs -f "${docker_id}" | grep --max-count=1 'Call nginx to the foreground'
 
    ip="$(docker inspect ${docker_id} | jq -r '.[0].NetworkSettings.Networks.bridge.IPAddress')"
    if curl --silent --cacert "${TEST_FOLDER}/fakelerootx1.pem" --resolve "${DOMAIN}:443:${ip}" "https://${DOMAIN}" | grep --quiet 'Thank you for using nginx.'; then
        return 0
    else
        return 1
    fi
}

### Run tests
if dns_challenge; then
    echo "=== TEST: The DNS Challenge (succeeded) ==="
else
    echo "=== TEST: The DNS Challenge (failed) ==="
    exit 1
fi

exit 0
