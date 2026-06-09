ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
ARG ETHERPAD_VERSION=3.3.0

# Stage 1: pull the pre-built Etherpad tree (incl. node + pnpm) from the
# official image. Both the upstream image and the HA base use Alpine, so
# binaries cross over cleanly.
FROM etherpad/etherpad:${ETHERPAD_VERSION} AS upstream

# Stage 2: assemble the add-on on top of the HA base.
FROM ${BUILD_FROM}

ARG ETHERPAD_VERSION
ENV ETHERPAD_VERSION=${ETHERPAD_VERSION} \
    NODE_ENV=production \
    ETHERPAD_PRODUCTION=true \
    CI=true

RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      nodejs \
      npm \
      socat \
      tini \
    && rm -rf /var/cache/apk/*

COPY --from=upstream /opt/etherpad-lite /opt/etherpad-lite

# pnpm is needed at runtime for Etherpad's plugin-migration step.
# Apk's node is smaller than upstream's statically-built binary, so we
# re-install pnpm rather than copying the larger upstream layout.
RUN npm install -g pnpm@10.33.0 \
 && npm cache clean --force \
 && rm -rf /root/.npm

COPY rootfs/ /

EXPOSE 9001

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -fsS http://127.0.0.1:9002/ -o /dev/null || exit 1

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
