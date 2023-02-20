# Use Tailscale to connect to our exit node at home and work around AWS IP range blocks.
FROM alpine:latest as tailscale
WORKDIR /app
ENV TSFILE_AMD64=tailscale_1.36.1_amd64.tgz
ENV TSFILE_ARM64=tailscale_1.36.1_arm64.tgz
RUN if uname -m | grep -Eiq 'arm|aarch'; \
    then wget -O tailscale.tgz https://pkgs.tailscale.com/stable/${TSFILE_ARM64}; \
    else wget -O tailscale.tgz https://pkgs.tailscale.com/stable/${TSFILE_AMD64}; \ 
    fi && \
    tar xzf tailscale.tgz --strip-components=1


FROM ruby:2.7-alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

ENV AWS_LAMBDA_RIE_URL_ARM64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
ENV AWS_LAMBDA_RIE_URL_AMD64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie

RUN apk update
RUN apk add chromium chromium-chromedriver
RUN apk add build-base

RUN mkdir /app
COPY Gemfile /app
WORKDIR /app
RUN bundle install

RUN apk add curl
RUN gem install aws_lambda_ric
RUN if uname -m | grep -Eiq 'arm|aarch'; \
    then curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_ARM64"; \
    else curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_AMD64"; \
    fi && chmod +x /usr/local/bin/aws_lambda_rie

# Copy Tailscale bins from first layer.
COPY --from=tailscale /app/tailscaled /var/runtime/tailscaled
COPY --from=tailscale /app/tailscale /var/runtime/tailscale
RUN mkdir -p /var/run && ln -s /tmp/tailscale /var/run/tailscale && \
    mkdir -p /var/cache && ln -s /tmp/tailscale /var/cache/tailscale && \
    mkdir -p /var/lib && ln -s /tmp/tailscale /var/lib/tailscale && \
    mkdir -p /var/task && ln -s /tmp/tailscale /var/task/tailscale

# Then, finally, the app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec

RUN apk add bash
COPY include/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
