ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install jq to parse Home Assistant add-on options from /data/options.json
# and nginx to provide ingress-safe reverse proxying in front of TREK.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq nginx \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# The base image ENTRYPOINT is ["dumb-init", "--"]; we override only CMD.
CMD ["/run.sh"]
