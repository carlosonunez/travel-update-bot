FROM ruby:2.7-alpine3.15
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update

RUN apk add libffi-dev readline sqlite build-base\
    libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc libc-dev \
    freetype fontconfig gcompat chromium@testing chromium-chromedriver@testing

RUN mkdir /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY Gemfile /app

WORKDIR /app

RUN bundle install
RUN gem install aws_lambda_ric
ENTRYPOINT [ "aws_lambda_ric" ]
