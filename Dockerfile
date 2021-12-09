# Builder image
FROM golang:1.17.1-bullseye AS build
ENV GOPATH /go
WORKDIR /go/src/headscale

COPY go.mod go.sum /go/src/headscale/
RUN go mod download

COPY . .

RUN go install -a -ldflags="-extldflags=-static" -tags netgo,sqlite_omit_load_extension ./cmd/headscale
RUN test -e /go/bin/headscale

# Production image
FROM gcr.io/distroless/base-debian11

COPY --from=build /go/bin/headscale /bin/headscale
ENV TZ UTC

EXPOSE 8080/tcp

CMD ["headscale", "serve"]

HEALTHCHECK --interval=1m --timeout=5s CMD curl -f http://127.0.0.1:8080/health || exit 1
