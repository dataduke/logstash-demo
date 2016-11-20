#!/bin/bash

# Exit 1 if any script fails.
set -e

############
# logstash #
############

HOST_LOG_DIR="${LS_LOG}";
HOST_CONFIG_DIR="${LS_CONFIG}";

###################
# logstash config #
###################

# Set defaults.
export LS_ENV="env.list";
export LS_CONF="logstash-demo.conf";
export LS_PATTERN="*demo*.json";
export LS_INFO="logstash-info.json";
export LS_ERROR="logstash-error.json";
export ES_TEMPLATE="template-demo.json";
export ES_DOCUMENT_TYPE=${VERSION};
export ES_INDEX_ALIAS="log-demo";

#################
# elasticsearch #
#################

# The elasticsearch configuration.
[[ "${LS_OUTPUT}" =~ ^.*(elasticsearch)|(document)|(template).*$ ]] && {
  [[ -z "${ES_HOSTS}" ]] && { echo "ERROR: ES_HOSTS is not set."; exit 1; }
  [[ -z "${ES_USER}" ]] && { echo -e "\nINFO: ES_USER is optional and not set. Check if hosts ${ES_HOSTS} use auth."; }
  [[ -z "${ES_PASSWORD}" ]] && { echo -e "\nINFO: ES_PASSWORD is optional and not set. Check if hosts ${ES_HOSTS} use auth."; }
  [[ -z "${ES_TEMPLATE}" && "${LS_OUTPUT}" =~ ^.*(elasticsearch)|(template).*$ ]] && { echo "ERROR: ES_TEMPLATE is not set."; exit 1; }
  [[ -z "${ES_INDEX_ALIAS}" && "${LS_OUTPUT}" =~ ^.*(elasticsearch)|(template).*$ ]] && { echo -e "\nINFO: ES_INDEX_ALIAS is optional and not set. Check if template [${ES_TEMPLATE}] needs an alias."; }
  [[ -z "${ES_INDEX}" ]] && { echo "ERROR: ES_INDEX is not set."; exit 1; }
  [[ -z "${ES_DOCUMENT_TYPE}" && "${LS_OUTPUT}" != "template" ]] && { echo "ERROR: ES_DOCUMENT_TYPE is not set."; exit 1; }
}

##########
# docker #
##########

# The docker configuration has defaults.
DOCKER_LOG_VOL="/usr/share/logstash/log" # do not change - derived from dockerfile LS_LOG_VOL!
DOCKER_CONFIG_VOL="/usr/share/logstash/config" # do not change - derived from dockerfile LS_CONFIG_VOL!
DOCKER_IMAGE_NAME="dataduke/logstash-demo"; [[ -n "${LS_DOCKER_REPO}" ]] && DOCKER_IMAGE_NAME="${LS_DOCKER_REPO}"
DOCKER_IMAGE_TAG="latest"; [[ -n "${LS_DOCKER_TAG}" ]] && DOCKER_IMAGE_TAG="${LS_DOCKER_TAG}"
DOCKER_CONTAINER_NAME="logstash-indexer"; [[ -n "${LS_DOCKER_CONTAINER}" ]] && DOCKER_CONTAINER_NAME="${LS_DOCKER_CONTAINER}"

# Special flags for docker run are always used and can only be ommitted by actively disabling them.
DOCKER_RUN_REMOVE=''; [[ $LS_DOCKER_REMOVE == true ]] && DOCKER_RUN_REMOVE='-it --rm'
DOCKER_RUN_DETACH='--detach=true'; [[ "${LS_OUTPUT}" =~ ^.*(verbose)|(console).*$ ]] || [[ $LS_DOCKER_DETACH == false ]] && DOCKER_RUN_DETACH='--detach=false'
DOCKER_RUN_NETWORK='--net="host"'; [[ $LS_DOCKER_NETWORK == false ]] && DOCKER_RUN_NETWORK=''

# Print info.
printf "\n%s\n\n" "=== Start docker container [${DOCKER_CONTAINER_NAME}] from image [${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}] ==="
printf "%s\n" "Process logs with pattern:          ${LS_PATTERN}"
printf "%s\n" "Mount log directory:                ${LS_LOG}"
printf "%s\n" "Mount config directory:             ${LS_CONFIG}"
printf "%s\n" "Set logstash input types:           ${LS_INPUT}"
printf "%s\n" "Set logstash output types:          ${LS_OUTPUT}"
printf "%s\n" "Use logstash env file:              ${LS_ENV}"
printf "%s\n" "Use logstash conf file:             ${LS_CONF}"
printf "%s\n" "Use info log file:                  ${LS_INFO}"
printf "%s\n" "Use error log file:                 ${LS_ERROR}"
printf "%s\n" "Use elasticsearch template file:    ${ES_TEMPLATE}"
printf "%s\n" "Set elasticsearch hosts:            ${ES_HOSTS}"
printf "%s\n" "Set elasticsearch index alias:      ${ES_INDEX_ALIAS}"
printf "%s\n" "Set elasticsearch index:            ${ES_INDEX}"
printf "%s\n" "Set elasticsearch document type:    ${ES_DOCUMENT_TYPE}"
printf "\n%s\n\n" "--- Start configuration is applied."

# Run docker container.
docker run ${DOCKER_RUN_REMOVE} ${DOCKER_RUN_DETACH} ${DOCKER_RUN_NETWORK} \
  --env-file "${LS_CONFIG}/${LS_ENV}" \
  -v ${HOST_LOG_DIR}:${DOCKER_LOG_VOL} \
  -v ${HOST_CONFIG_DIR}:${DOCKER_CONFIG_VOL} \
  --name ${DOCKER_CONTAINER_NAME} \
  ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
  logstash -f "${DOCKER_CONFIG_VOL}/${LS_CONF}"

exit $?
