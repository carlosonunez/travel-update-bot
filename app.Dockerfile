FROM lambci/lambda:build-go1.x as base
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV FIREFOX_LAMBDA_URL=https://github.com/carlosonunez/firefox-lambda/raw/v82.0/firefox.zip
ENV GECKODRIVER_VERSION=0.28.0
ENV GECKODRIVER_URL=https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz
RUN yum -y install wget
RUN cd / && \
    wget -O firefox.zip $FIREFOX_LAMBDA_URL && \
    unzip firefox.zip | true
RUN wget -O geckodriver.tar.gz $GECKODRIVER_URL && \ 
    tar -xf geckodriver.tar.gz && \
    mv geckodriver /usr/local/bin && \
    ln -s /tmp/firefox/firefox /usr/local/bin/firefox

# Lastly, we prepare our app!
FROM base as app
ENV GITHUB_REPO=carlosonunez/flightaware-bot
ENV PROJECT_DIR=$GOPATH/github.com/$GITHUB_REPO
WORKDIR $PROJECT_DIR/src
COPY . $PROJECT_DIR/src
