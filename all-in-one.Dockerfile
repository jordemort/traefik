### Build webui - adapted from webui/Dockerfile and Makefile
FROM node:14.16 AS webui

ENV WEBUI_DIR /src/webui
RUN mkdir -p $WEBUI_DIR

COPY webui/package.json $WEBUI_DIR/
COPY webui/yarn.lock $WEBUI_DIR/

WORKDIR $WEBUI_DIR
RUN yarn install

COPY webui/ $WEBUI_DIR/

RUN npm run build:nc
RUN chown -R $(shell id -u):$(shell id -g) ./static

### Build binary - adapted from Makefile       
FROM golang:1.20 as binary

WORKDIR /usr/src/traefik
COPY . .
COPY --from=webui /src/webui/static/ ./webui/static/

RUN mkdir -p dist
RUN ./script/make.sh generate binary

### Build final container image - from Dockerfile
FROM scratch
COPY script/ca-certificates.crt /etc/ssl/certs/
COPY --from=binary /usr/src/traefik/dist/traefik /
EXPOSE 80
VOLUME ["/tmp"]
ENTRYPOINT ["/traefik"]
