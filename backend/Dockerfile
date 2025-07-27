FROM golang:1.24.2 AS builder

WORKDIR /workspace

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./main.go

FROM gcr.io/distroless/base-debian11
COPY --from=builder /workspace/server /server

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/server"]
