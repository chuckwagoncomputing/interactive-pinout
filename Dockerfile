FROM debian:stable-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
  apt-get install -y wget &&\
  wget https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64 &&\
  chmod a+x yq_linux_amd64 &&\
  mv yq_linux_amd64 /usr/bin/yq &&\
  apt-get autoremove -y && apt-get clean -y

COPY main.sh /main.sh
COPY gen.sh /gen.sh
COPY append.sh /append.sh
COPY pinout.html /pinout.html
COPY script.js /script.js
COPY style.css /style.css
ENTRYPOINT ["/main.sh"]
