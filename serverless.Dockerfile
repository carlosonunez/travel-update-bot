FROM carlosnunez/serverless:v2.69.1
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN npm install serverless-domain-manager --save-dev

# python3 has a bad symlink in this image, but it is installed.
RUN ln -s /usr/bin/python3 /usr/local/bin/python3

# Install Docker so that we can build images and push them
RUN apk add docker

# Copy the app into the container to improve performance
# on non-Linux operating systems.
COPY . /app
WORKDIR /app

ENTRYPOINT [ "serverless" ]
