FROM golang:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN mkdir -p /go/github.com/carlosonunez/travel-update-bot/{bin,src}
COPY . /go/github.com/carlosonunez/travel-update-bot/src
WORKDIR /go/github.com/carlosonunez/travel-update-bot/src
RUN [ "sh", "-c", "echo 'Working on it!'" ]
