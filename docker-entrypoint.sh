#!/bin/bash

# Exit 1 if any script fails.
set -e

# Add logstash as command if needed
if [[ "${1:0:1}" = '-' ]]; then
    set -- logstash "$@"
fi

# If running logstash
if [[ "$1" = 'logstash' ]]; then

    # Change the ownership of the mounted volumes to user logstash at docker container runtime
    chown -R logstash:logstash ${LS_CONFIG_VOL} ${LS_LOG_VOL}

    # Get LS_ENV
    LS_ENV_PATH=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${LS_ENV}" )

    # Get LS_CONF
    {
        # Render logstash conf if exists as jinja template
        printf "\n%s\n" "=== Render logstash conf [${LS_CONF}.j2] in [${LS_CONFIG_VOL}] with [${LS_ENV}] ==="
        LS_CONF_JINJA=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${LS_CONF}.j2" )
        [[ ${LS_CONF_JINJA} ]] && python ${JINJA_SCRIPT} --verbose -f "${LS_ENV_PATH}" -e "LS_CONFIG_VOL" "LS_LOG_VOL" -t "${LS_CONF_JINJA}"
    }

    # Get ES_TEMPLATE if pushed
    [[ "${LS_OUTPUT}" =~ ^.*(elasticsearch)|(template).*$ ]] && {

        # Render elasticsearch template if exists as jinja template
        printf "\n\n%s\n" "=== Render elasticsearch template [${ES_TEMPLATE}.j2] in [${LS_CONFIG_VOL}] with [${LS_ENV}] ==="
        ES_TEMPLATE_JINJA=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${ES_TEMPLATE}.j2" )
        [[ ${ES_TEMPLATE_JINJA} ]] && python ${JINJA_SCRIPT} --verbose -f "${LS_ENV_PATH}" -t "${ES_TEMPLATE_JINJA}"

    }

    # Test connection to elasticsearch hosts
    [[ "${LS_OUTPUT}" =~ ^.*(elasticsearch)|(document)|(template).*$ ]] && {

        # Print info
        printf "\n\n%s\n" "=== Test connection to elasticsearch hosts ${ES_HOSTS} ==="

        # Get log settings
        [[ "${LS_OUTPUT}" =~ ^.*(log)|(info)|(error).*$ ]] && LOG=true || LOG=false

        # Set ES_HOSTS as hosts array
        declare -a HOSTS=$( echo ${ES_HOSTS} | tr '[]' '()' | tr ',' ' ' )

        # Test each host
        NOT_AVAILABLE=false
        for host in "${HOSTS[@]}";
        do
            ES_CLUSTER=$( curl --silent --retry 5 -u ${ES_USER}:${ES_PASSWORD} -XGET "${host}?pretty" )
            if [[ $(echo "$ES_CLUSTER" | grep "name" | wc -l) -gt 0 ]]; then
                printf "\n%s\n\n" "--- Following elasticsearch host reached: ${host}"; echo "$ES_CLUSTER";
            elif [[ $( echo "$ES_CLUSTER" | grep "OK" | wc -l ) -eq 1 ]]; then
                echo "ERROR: Following elasticsearch host requires correct auth credentials: ${host}" | ( $LOG && gosu logstash tee -a "${LS_LOG_VOL}/${LS_ERROR}" )
                NOT_AVAILABLE=true
            else
                echo "ERROR: Following elasticsearch host is currently not available: ${host}" | ( $LOG && gosu logstash tee -a "${LS_LOG_VOL}/${LS_ERROR}" )
                NOT_AVAILABLE=true
            fi
        done

        # Exit if any host cannot be reached
        $NOT_AVAILABLE && { echo "ERROR: Aborting start of logstash agent with logstash conf [${LS_CONF}]" | ( $LOG &&  gosu logstash tee -a "${LS_LOG_VOL}/${LS_ERROR}" ); exit 1; }
    }


    # Start logstash agent
    printf "\n\n%s\n\n" "=== Start logstash agent with logstash conf [${LS_CONF}] ==="
    set -- gosu logstash "$@"

fi # running logstash

# As argument is not related to logstash,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"
