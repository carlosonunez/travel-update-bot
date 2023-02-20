FROM ubuntu:jammy
RUN apt -y update
RUN apt -y install gpg

ENTRYPOINT [ "gpg" ]
