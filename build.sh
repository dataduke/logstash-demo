#!/bin/bash

# Exit 1 if any script fails.
set -e

# Docker image name and tag have defaults.
DOCKER_IMAGE_NAME="epages/to-logstash"
[[ -n "${LS_DOCKER_REPO}" ]] && DOCKER_IMAGE_NAME="${LS_DOCKER_REPO}"
DOCKER_IMAGE_TAG="latest"
[[ -n "${LS_DOCKER_TAG}" ]] && DOCKER_IMAGE_TAG="${LS_DOCKER_TAG}"

printf "\n%s\n\n" "=== Build docker image [${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}] ==="

docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} `dirname "$0"`
