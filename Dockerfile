# === GIAI ĐOẠN 1: BUILDER ===
# Sử dụng Debian để biên dịch 3proxy
FROM debian:stable-slim AS builder

# Cài đặt công cụ và biên dịch 3proxy
RUN apt-get update && \
    apt-get install -y git build-essential wget && \
    git clone --depth 1 --branch 0.9.5 https://github.com/3proxy/3proxy.git /tmp/3proxy && \
    cd /tmp/3proxy && \
    make -f Makefile.Linux

# === GIAI ĐOẠN 2: FINAL IMAGE ===
# Sử dụng BusyBox làm nền tảng cuối cùng, siêu nhẹ và tương thích cao
FROM busybox:stable-glibc

# Tạo các thư mục cần thiết
RUN mkdir -p /etc/3proxy /var/log/3proxy /usr/local/bin

# Tạo user và group 'nobody' để 3proxy chạy an toàn
RUN echo 'nobody:x:65534:65534::/nonexistent:/sbin/nologin' > /etc/passwd && \
    echo 'nobody:x:65534:' > /etc/group

# SỬA LỖI Ở ĐÂY: Sao chép file 3proxy từ đúng đường dẫn của nó sau khi build
COPY --from=builder /tmp/3proxy/bin/3proxy /usr/local/bin/3proxy

# Sao chép entrypoint
COPY entrypoint.sh /entrypoint.sh

# Cấp quyền cho entrypoint và thư mục log
RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/3proxy && \
    chown -R 65534:65534 /var/log/3proxy

# Mở các cổng proxy
EXPOSE 10001-11000
EXPOSE 20001-21000

# Chuyển sang user không có quyền hạn
USER nobody

# Chỉ định lệnh sẽ chạy khi container khởi động
ENTRYPOINT ["/entrypoint.sh"]
