#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM golang:1.23-alpine3.21 AS build

ENV DELVE_VERSION=v1.22.1

RUN set -ex; \
    apk add --no-cache \
        file \
        bash \
        clang \
        lld \
        musl-dev \
        pkgconfig \
        git \
        make;

RUN CGO_ENABLED=0 go install "github.com/go-delve/delve/cmd/dlv@${DELVE_VERSION}";

FROM scratch

COPY --from=build /go/bin/dlv /dlv
