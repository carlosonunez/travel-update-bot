FROM softinstigate/serverless
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN npm install serverless-domain-manager --save-dev
RUN npm install serverless-offline --save-dev
