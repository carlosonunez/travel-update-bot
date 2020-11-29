FROM golang:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV GITHUB_REPO=carlosonunez/flightaware-bot
ENV PROJECT_DIR=$GOPATH/github.com/$GITHUB_REPO

RUN apk add git gcc musl-dev firefox
WORKDIR $PROJECT_DIR/src

# NOTE: Ensure that /data exists in the image used to run Selenium Hub and that
# it contains the mocked websites under test.
ENV FIXTURES_PATH=/data
COPY . $PROJECT_DIR/src
