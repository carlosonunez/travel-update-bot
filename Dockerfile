FROM lambci/lambda:build-ruby2.5
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG ENVIRONMENT

RUN yum install -y ruby25-devel gcc libxml2 libxml2-devel libxslt libxslt-devel patch

# Use a special version of Chrome that has shared memory disabled
# as Lambda functions do not have access to /dev/shm and the regular version of
# Chrome will exceed Lambda storage limits.
# See also: https://github.com/alixaxel/chrome-aws-lambda
COPY include/chrome_lambda.zip /tmp
RUN unzip -d /opt /tmp/chrome_lambda.zip

ENTRYPOINT ["ruby", "-e", "puts 'Welcome to flight-info'"]
