ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
ARG ETHERPAD_VERSION=3.1.0

# Stage 1: pull the pre-built Etherpad tree (incl. node + pnpm) from the
# official image. Both the upstream image and the HA base use Alpine, so
# binaries cross over cleanly.
FROM etherpad/etherpad:${ETHERPAD_VERSION} AS upstream

# Stage 2: assemble the add-on on top of the HA base.
FROM ${BUILD_FROM}

ARG ETHERPAD_VERSION
ENV ETHERPAD_VERSION=${ETHERPAD_VERSION} \
    NODE_ENV=production \
    ETHERPAD_PRODUCTION=true

# Minimal apk surface: just bash + curl for bashio/HEALTHCHECK; node and
# pnpm come from the upstream image so we don't re-download them.
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      tini \
    && rm -rf /var/cache/apk/*

COPY --from=upstream /usr/local/bin/node /usr/local/bin/node
COPY --from=upstream /usr/local/lib/node_modules/pnpm /usr/local/lib/node_modules/pnpm
RUN ln -s /usr/local/lib/node_modules/pnpm/bin/pnpm.mjs /usr/local/bin/pnpm

COPY --from=upstream /opt/etherpad-lite /opt/etherpad-lite

COPY rootfs/ /

EXPOSE 9001

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -fsSk http://127.0.0.1:9001/ -o /dev/null \
   || curl -fsSk https://127.0.0.1:9001/ -o /dev/null \
   || exit 1

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Etherpad Foundation <contact@etherpad.org>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Etherpad" \
    org.opencontainers.image.authors="Etherpad Foundation" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://etherpad.org" \
    org.opencontainers.image.source="https://github.com/ether/etherpad" \
    org.opencontainers.image.documentation="https://etherpad.org/doc" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
