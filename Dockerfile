FROM ubuntu:bionic

# Set the kong version to run
ENV KONG_VERSION 2.3.2

RUN set -ex; \
    apt-get update \
    && apt-get install -y curl \
    && apt-get install -y --no-install-recommends perl unzip git \
    && { apt-get install -y --no-install-recommends zlibc || true; } \
    && { apt-get install -y --no-install-recommends zlib1g-dev || true; } \
    && rm -rf /var/lib/apt/lists/*
RUN set -ex; \
    curl -fL "https://bintray.com/kong/kong-deb/download_file?file_path=kong-$KONG_VERSION.bionic.$(dpkg --print-architecture).deb" -o /tmp/kong.deb \
	&& dpkg -i /tmp/kong.deb \
	&& rm -rf /tmp/kong.deb \
    && mkdir -p "/usr/local/kong" \
	&& chown -R kong:0 /usr/local/kong \
	&& chown kong:0 /usr/local/bin/kong \
	&& chmod -R g=u /usr/local/kong

COPY ./kong/plugins/ /usr/local/custom/kong/plugins/
COPY ./docker/scripts/ .

RUN bash plugin_setup.sh

RUN ["chmod", "+x", "./docker-entrypoint.sh"]

USER kong
RUN kong version

ENTRYPOINT [ "./docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]