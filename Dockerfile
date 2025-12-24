FROM debian:stable-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
  apt-get install -y wget jq &&\
  wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 &&\
  chmod a+x yq_linux_amd64 &&\
  mv yq_linux_amd64 /usr/bin/yq &&\
  wget https://github.com/tdewolff/minify/releases/download/v2.20.19/minify_linux_amd64.tar.gz &&\
  tar -xzf minify_linux_amd64.tar.gz &&\
  chmod a+x minify &&\
  mv minify /usr/bin/ &&\
  apt-get autoremove -y && apt-get clean -y

COPY main.sh /main.sh
COPY gen.sh /gen.sh
COPY append.sh /append.sh
COPY pinout.html /pinout.html
COPY script.js /script.js
COPY style.css /style.css
ENTRYPOINT ["/main.sh"]
