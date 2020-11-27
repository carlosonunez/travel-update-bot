FROM golang:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV GITHUB_REPO=carlosonunez/flightaware-bot
ENV PROJECT_DIR=$GOPATH/github.com/$GITHUB_REPO

RUN apk add git gcc musl-dev
COPY . $PROJECT_DIR/src
WORKDIR $PROJECT_DIR/src
RUN [ "sh", "-c", "echo 'Working on it!'" ]
