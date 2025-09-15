# === GIAI ĐOẠN 1: BUILDER ===
FROM debian:stable-slim AS builder

RUN apt-get update && \
    apt-get install -y git build-essential wget && \
    git clone --depth 1 --branch 0.9.5 https://github.com/3proxy/3proxy.git /tmp/3proxy && \
    cd /tmp/3proxy && \
    make -f Makefile.Linux

# === GIAI ĐOẠN 2: FINAL IMAGE ===
FROM busybox:stable-glibc

RUN mkdir -p /etc/3proxy /var/log/3proxy /usr/local/bin

RUN echo 'nobody:x:65534:65534::/nonexistent:/sbin/nologin' > /etc/passwd && \
    echo 'nobody:x:65534:' > /etc/group

COPY --from=builder /tmp/3proxy/bin/3proxy /usr/local/bin/3proxy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/3proxy && \
    chown -R 65534:65534 /var/log/3proxy

EXPOSE 10001-11000
EXPOSE 20001-21000

USER nobody
ENTRYPOINT ["/entrypoint.sh"]
