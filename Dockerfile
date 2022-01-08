FROM public.ecr.aws/lambda/ruby:2.7
LABEL maintainer="Carlos Nunez <dev@carlosnunez.me>"

RUN if uname -m | grep -Eiq 'arm|aarch'; \
    then >&2 echo -ne "ERROR: Unfortunately, because Google has not published an \
ARM-compatible Chromium build and because this base image ships with an \
increasingly-ancient version of CentOS and glibc/zlib, \
there are no known working ARM-compatible binaries of Chromium that will work \
on Amazon Linux 2.\n\n\
Consequently, this image _must_ target the x86_64 CPU architecture.\n\n\
Please re-run 'docker build' with the '--platform linux/x86_64' flag enabled.\n\n\
I'm as pissed about this as you are. So much for the 'OPEN WEB'."; \
    exit 1; \
    fi;

RUN yum -y install amazon-linux-extras yum-utils
RUN amazon-linux-extras install epel -y && yum-config-manager --enable epel
RUN yum -y install chromium chromedriver

COPY Gemfile ${LAMBDA_TASK_ROOT}
RUN bundle install

COPY lib ${LAMBDA_TASK_ROOT}
COPY bin/flight-info.rb ${LAMBDA_TASK_ROOT}

ENV GEM_HOME=/vendor
