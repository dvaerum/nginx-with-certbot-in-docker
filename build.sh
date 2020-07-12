#!/usr/bin/env bash
# ex: set tabstop=8 softtabstop=0 expandtab shiftwidth=2 smarttab:

set -eu

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --print-vars)
  PRINT_VARS=1
  shift # past argument
  ;;
  --build)
  BUILD=1
  shift # past argument
  ;;
  --deploy)
  DEPLOY=1
  shift # past argument
  ;;
  *)    # unknown option
  POSITIONAL+=("$1") # save it in an array for later
  shift # past argument
  ;;
esac
done
#set -- "${POSITIONAL[@]}" # restore positional parameters


GIT_BRANCH="${TRAVIS_BRANCH:-}"
[ -z "${GIT_BRANCH}" ] && GIT_BRANCH="$(git branch --show-current)"


if [ ${GIT_BRANCH} == 'master' ]; then
   DOCKER_TAG=latest
else
   DOCKER_TAG=${GIT_BRANCH}
fi


REPO_SLUG="${TRAVIS_REPO_SLUG:-}"
[ -z "${REPO_SLUG}" ] && REPO_SLUG="$(git remote get-url origin | egrep --only-matching '[^/]+/[^/]+$')"

[ -z "${REPO:-}" ]            && REPO="${REPO_SLUG##*/}"
[ -z "${USERNAME:-}" ]        && USERNAME="${REPO_SLUG%/$REPO}"
[ -z "${DOCKER_USERNAME:-}" ] && DOCKER_USERNAME="${USERNAME}"


if [ "${PRINT_VARS:-0}" == 1 ]; then
  echo "PRINT_VARS:       ${PRINT_VARS:-}"
  echo "BUILD:            ${BUILD:-}"
  echo "DEPLOY:           ${DEPLOY:-}"
  echo "REPO:             ${REPO:-}"
  echo "DOCKER_TAG:       ${DOCKER_TAG:-}"
  echo "USERNAME:         ${USERNAME:-}"
  echo "DOCKER_USERNAME:  ${DOCKER_USERNAME:-}"
  if [ -z "${DOCKER_PASSWORD:-}" ]; then
    echo "DOCKER_PASSWORD:  Password have to been given"
  else
    echo "DOCKER_PASSWORD:  *************"
  fi
fi


if [ "${BUILD:-0}" == 1 ]; then
  docker pull "$(sed -En 's_FROM[ ]+(.+)_\1_p' 'Dockerfile')"
  [ ! -d acme.sh ] && git clone --depth 1 "https://github.com/acmesh-official/acme.sh" --branch "dev"
  docker build -t "${USERNAME}/${REPO}:${DOCKER_TAG}" .
  rm -rf "acme.sh"
fi

if [ "${DEPLOY:-0}" == 1 ]; then
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push "${USERNAME}/${REPO}:${DOCKER_TAG}"
fi

