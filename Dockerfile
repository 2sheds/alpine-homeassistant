ARG QEMU_ARCH=x86_64
FROM multistage/qemu-user-static:${QEMU_ARCH} AS qemu

ARG ALPINE_VER="3.10"
ARG BASEIMAGE_ARCH
ARG QEMU_ARCH
FROM ${BASEIMAGE_ARCH}/alpine:${ALPINE_VER} AS alpine_qemu
ONBUILD COPY --from=qemu /usr/bin/qemu-${QEMU_ARCH}-static /usr/bin/

ARG ALPINE_VER
FROM alpine:${ALPINE_VER} AS alpine_native
ONBUILD RUN echo "qemu-user-static: Registration not required for native arch"

ARG BUILD_ENV=native

FROM alpine_${BUILD_ENV}
MAINTAINER Oleg Kurapov <oleg@kurapov.com>
LABEL Description="Home Assistant"

ARG ALPINE_VER
ARG PKG_ARCH
ARG QEMU_ARCH

ARG BRANCH="none"
ARG COMMIT="local-build"
ARG BUILD_DATE="1970-01-01T00:00:00Z"
ARG NAME="kurapov/alpine-homeassistant"
ARG VCS_URL="https://github.com/2sheds/alpine-homeassistant"

ARG UID=1000
ARG GUID=1000
ARG MAKEFLAGS=-j4
ARG VERSION="0.100.0"
ARG PLUGINS="frontend|pyotp|PyQRCode|sqlalchemy|distro|http|nmap|weather|uptimerobot|rxv|wakeonlan|websocket|paho-mqtt|samsungctl[websocket]|pychromecast|aiohttp_cors|jsonrpc-websocket|jsonrpc-async"

ENV WHEELS_LINKS="https://wheels.home-assistant.io/alpine-${ALPINE_VER}/${PKG_ARCH}/"

LABEL \
  org.opencontainers.image.authors="Oleg Kurapov <oleg@kurapov.com>" \
  org.opencontainers.image.title="${NAME}" \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.revision="${COMMIT}" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.source="${VCS_URL}"

ADD "https://raw.githubusercontent.com/home-assistant/home-assistant/${VERSION}/requirements_all.txt" /tmp

RUN apk add --no-cache git python3 ca-certificates libffi-dev libressl-dev nmap iputils && \
    addgroup -g ${GUID} hass && \
    adduser -h /data -D -G hass -s /bin/sh -u ${UID} hass && \
    pip3 install --upgrade --no-cache-dir pip && \
    apk add --no-cache --virtual=build-dependencies build-base linux-headers python3-dev && \
    sed '/^$/q' /tmp/requirements_all.txt > /tmp/requirements_core.txt && \
    sed '1,/^$/d' /tmp/requirements_all.txt > /requirements_plugins.txt && \
    egrep -e "${PLUGINS}" /requirements_plugins.txt | grep -v '#' > /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir --no-index --only-binary=:all: --find-links ${WHEELS_LINKS} -r /tmp/requirements_core.txt && \
    pip3 install --no-cache-dir --no-index --only-binary=:all: --find-links ${WHEELS_LINKS} -r /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir homeassistant=="${VERSION}" && \
    apk del build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

EXPOSE 8123

ENTRYPOINT ["hass", "--open-ui", "--config=/data"]

