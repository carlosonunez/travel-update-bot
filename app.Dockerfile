FROM golang:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV GITHUB_REPO=carlosonunez/flightaware-bot

RUN mkdir -p /go/github.com/$GITHUB_REPO/{bin,src}
WORKDIR /go/github.com/$GITHUB_REPO/src
COPY . /go/github.com/$GITHUB_REPO/src
RUN [ "sh", "-c", "echo 'Working on it!'" ]
