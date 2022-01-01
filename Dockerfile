FROM ruby:2.7-alpine3.15
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG ENVIRONMENT

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update

RUN apk add libffi-dev readline sqlite build-base\
    libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc libc-dev \
    freetype fontconfig gcompat chromium@testing chromium-chromedriver@testing

COPY . /var/task
WORKDIR /var/task
ENTRYPOINT ["ruby", "bin/flight-info.rb"]
