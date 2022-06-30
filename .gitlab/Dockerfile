FROM ubuntu:latest
RUN apt update
RUN apt install -y xz-utils gnupg2 curl gcc
RUN curl -fsS https://dlang.org/install.sh | bash -s dmd
RUN bash -c "source ~/dlang/dmd-*/activate && dub fetch dscanner"
