FROM alpine:latest
RUN apk add --no-cache bash netcat-openbsd procps
WORKDIR /app
COPY check.sh .
RUN chmod +x check.sh
COPY loop.sh .
RUN chmod +x loop.sh
CMD ["./loop.sh"]
