ARG ALPINE_VER="3.19"
ARG PYTHON_VER="3.12"
ARG BASEIMAGE_ARCH="amd64"
ARG DOCKER_ARCH="amd64"

FROM kurapov/alpine-jemalloc:latest-${DOCKER_ARCH} AS jemalloc

FROM ${BASEIMAGE_ARCH}/python:${PYTHON_VER}-alpine${ALPINE_VER}

LABEL Description="Home Assistant"

ARG ALPINE_VER
ARG BASEIMAGE_ARCH

ARG BRANCH="none"
ARG COMMIT="local-build"
ARG BUILD_DATE="1970-01-01T00:00:00Z"
ARG NAME="kurapov/alpine-homeassistant"
ARG VCS_URL="https://github.com/2sheds/alpine-homeassistant"

ARG UID=1000
ARG GUID=1000
ARG MAKEFLAGS=-j4
ARG VERSION="0.100.0"
ARG DEPS="openssl-dev"
ARG PLUGINS="home-assistant-frontend|PyNaCl|defusedxml|distro|zeroconf|hass-nabucasa|aiohttp_cors|scapy|aiodiscover|psutil-home-assistant|securetar"

RUN apk add --update-cache git nmap iputils tzdata && \
    apk add --virtual=build-dependencies build-base libffi-dev ${DEPS} && \
    addgroup -g ${GUID} hass && \
    adduser -h /data -D -G hass -s /bin/sh -u ${UID} hass && \
    wget -q "https://raw.githubusercontent.com/home-assistant/home-assistant/${VERSION}/requirements_all.txt" -P /usr/src/ && \
    grep -w -E "${PLUGINS}" /usr/src/requirements_all.txt | grep -v '#' > /tmp/requirements_plugins.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_plugins.txt homeassistant=="${VERSION}" && \
    apk del build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY --from=jemalloc /usr/local/lib/libjemalloc.so* /usr/local/lib/

ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so.2

EXPOSE 8123

ENTRYPOINT ["hass", "--config=/data"]

