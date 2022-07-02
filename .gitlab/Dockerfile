FROM ubuntu:latest
RUN apt update
RUN apt install -y xz-utils gnupg2 curl gcc git libssl-dev libcrypto-dev
RUN curl -fsS https://dlang.org/install.sh | bash -s dmd
RUN bash -c "source ~/dlang/dmd-*/activate && dub fetch dscanner"
RUN curl -s -o /usr/bin/codecov https://uploader.codecov.io/latest/linux/codecov && chmod +x /usr/bin/codecov
