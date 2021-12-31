FROM ruby:2.5-alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG ENVIRONMENT

RUN apk update && apk add libffi-dev readline sqlite build-base\
    libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc libc-dev \
    freetype fontconfig gcompat chromium chromium-chromedriver

COPY . /var/task
WORKDIR /var/task
ENTRYPOINT ["ruby", "bin/flight-info.rb"]
