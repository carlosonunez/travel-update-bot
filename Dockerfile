FROM ruby:2.7-alpine3.15
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV AWS_LAMBDA_RIE_URL_ARM64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
ENV AWS_LAMBDA_RIE_URL_AMD64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update

RUN apk add libffi-dev readline sqlite build-base\
    libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc libc-dev \
    freetype fontconfig gcompat chromium@testing chromium-chromedriver@testing

RUN mkdir /app
COPY Gemfile /app
WORKDIR /app
RUN bundle install

RUN gem install aws_lambda_ric
RUN apk add curl
RUN if uname -m | grep -Ei 'arm|aarch'; \
    then curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_ARM64"; \
    else curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_AMD64"; \
    fi && chmod +x /usr/local/bin/aws_lambda_rie

COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec

ENTRYPOINT [ "/usr/local/bin/aws_lambda_rie", "aws_lambda_ric" ]
