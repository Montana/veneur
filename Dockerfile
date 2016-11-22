FROM golang:1.7
MAINTAINER The Stripe Observability Team <support@stripe.com>

RUN mkdir -p /build
ENV GOPATH=/go
RUN apt-get update
RUN apt-get install -y zip
RUN go get -u -v github.com/kardianos/govendor
RUN go get -u -v github.com/ChimeraCoder/gojson/gojson
RUN go get -u github.com/golang/protobuf/protoc-gen-go
RUN wget https://github.com/google/protobuf/releases/download/v3.1.0/protoc-3.1.0-linux-x86_64.zip
RUN unzip protoc-3.1.0-linux-x86_64.zip
RUN cp bin/protoc /usr/bin/protoc
RUN chmod 777 /usr/bin/protoc

WORKDIR /go/src/github.com/stripe/veneur
ADD . /go/src/github.com/stripe/veneur


# This allows us to test Dockerfile changes without committing every single time
# to avoid a dirty tree
RUN git checkout Dockerfile
RUN cp -r henson /build/
RUN go generate
RUN gofmt -w .

# Run twice so we get the output, but also non-zero exit status
# if there are unstaged changes OR staged changes that have been
# undone in the working tree but *not* staged
RUN git diff-index HEAD && \
  git diff-index --quiet HEAD 

RUN test -n $(git status --porcelain)
RUN govendor test -v -timeout 10s +local
RUN go build -a -v -ldflags "-X github.com/stripe/veneur.VERSION=$(git rev-parse HEAD)" -o /build/veneur ./cmd/veneur
