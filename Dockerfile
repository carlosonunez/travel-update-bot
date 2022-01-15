FROM ruby:2.7-buster
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV AWS_LAMBDA_RIE_URL_ARM64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
ENV AWS_LAMBDA_RIE_URL_AMD64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie

RUN apt -y update
RUN apt -y install zlib1g-dev liblzma-dev patch chromium chromium-driver
RUN apt -y install qemu binfmt-support qemu-user-static

RUN mkdir /app
COPY Gemfile /app
WORKDIR /app
RUN bundle install

RUN gem install aws_lambda_ric
RUN if uname -m | grep -Eiq 'arm|aarch'; \
    then curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_ARM64"; \
    else curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_AMD64"; \
    fi && chmod +x /usr/local/bin/aws_lambda_rie

COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY include/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
