# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.22

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DDCLIENT_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="saarg"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    wget && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    bind-tools \
    inotify-tools \
    perl \
    perl-digest-sha1 \
    perl-io-socket-inet6 \
    perl-io-socket-ssl \
    perl-json \
    perl-netaddr-ip && \
  echo "***** install perl modules ****" && \
  curl -L http://cpanmin.us | perl - App::cpanminus && \
  cpanm \
    Data::Validate::IP \
    JSON::Any && \
  echo "**** install ddclient ****" && \
  if [ -z ${DDCLIENT_VERSION+x} ]; then \
    DDCLIENT_VERSION=$(curl -sX GET "https://api.github.com/repos/ddclient/ddclient/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p \
    /tmp/ddclient && \
  curl -o \
  /tmp/ddclient.tar.gz -L \
    "https://github.com/ddclient/ddclient/archive/${DDCLIENT_VERSION}.tar.gz" && \
  tar xf \
  /tmp/ddclient.tar.gz -C \
    /tmp/ddclient --strip-components=1 && \
  cp /tmp/ddclient/ddclient.in /usr/bin/ddclient.in && \
  ln -s /usr/bin/ddclient.in /usr/bin/ddclient && \
  mkdir -p /etc/ddclient/ && \
  cp /tmp/ddclient/sample-get-ip-from-fritzbox /etc/ddclient/get-ip-from-fritzbox && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /config/.cpanm \
    /root/.cpanm \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
