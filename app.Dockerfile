FROM lambci/lambda:build-go1.x as base
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV FIREFOX_LAMBDA_URL=https://github.com/carlosonunez/firefox-lambda/raw/v82.0/firefox.zip
ARG INCLUDE_E2E=false
RUN test "$INCLUDE_E2E" == "true" && yum -y install wget || true
RUN if test "$INCLUDE_E2E" == "true"; \
    then cd / && \
      wget -O firefox.zip $FIREFOX_LAMBDA_URL && \
      unzip -o firefox.zip && \
      ln -s /tmp/firefox/firefox /usr/local/bin/firefox; fi

FROM base as app
ENV GITHUB_REPO=carlosonunez/flightaware-bot
ENV PROJECT_DIR=$GOPATH/github.com/$GITHUB_REPO
WORKDIR $PROJECT_DIR/src
COPY . $PROJECT_DIR/src
