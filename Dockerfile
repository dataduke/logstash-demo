FROM logstash:2.1.0

##########################################
# Install packages and templating script #
##########################################

RUN apt-get update && apt-get install -y \
    curl build-essential \
    python-setuptools && \
    easy_install Jinja2 && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

ENV JINJA_SCRIPT="render_jinja_template.py"
COPY util/${JINJA_SCRIPT} /
RUN chown logstash:logstash /${JINJA_SCRIPT} && \
    chmod +x ${JINJA_SCRIPT}

######################
# Configure Logstash #
######################

ENV LS_CONFIG_VOL="/usr/share/logstash/config" \
    LS_LOG_VOL="/usr/share/logstash/log"

RUN mkdir -p ${LS_CONFIG_VOL} ${LS_LOG_VOL}
COPY config/ ${LS_CONFIG_VOL}/
RUN chown -R logstash:logstash ${LS_CONFIG_VOL} ${LS_LOG_VOL}
VOLUME ["${LS_CONFIG_VOL}", "${LS_LOG_VOL}"]

RUN rm /docker-entrypoint.sh
COPY docker-entrypoint.sh /
RUN chown logstash:logstash /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["logstash", "agent"]
