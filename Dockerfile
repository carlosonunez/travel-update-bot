FROM lambci/lambda:build-ruby2.5
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG ENVIRONMENT

RUN yum install -y ruby25-devel gcc libxml2 libxml2-devel libxslt libxslt-devel patch

COPY include/phantomjs_lambda.zip /
WORKDIR /
RUN unzip /phantomjs_lambda.zip && rm /phantomjs_lambda.zip
WORKDIR /var/task
ENTRYPOINT ["ruby", "-e", "puts 'Welcome to flight-info'"]
