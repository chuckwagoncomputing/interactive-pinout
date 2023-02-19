FROM alpine:edge

RUN apk add minify yq bash perl coreutils

COPY main.sh /main.sh
COPY gen.sh /gen.sh
COPY append.sh /append.sh
COPY pinout.html /pinout.html
COPY script.js /script.js
COPY style.css /style.css
ENTRYPOINT ["/main.sh"]
