# === GIAI ĐOẠN 1: BUILDER ===
# Sử dụng Debian làm môi trường build đầy đủ và ổn định
FROM debian:stable-slim AS builder

# Cài đặt các công cụ cần thiết và biên dịch 3proxy từ mã nguồn
RUN apt-get update && \
    apt-get install -y git build-essential && \
    git clone --depth 1 --branch 0.9.5 https://github.com/3proxy/3proxy.git /tmp/3proxy && \
    cd /tmp/3proxy && \
    make -f Makefile.Linux

# === GIAI ĐOẠN 2: FINAL IMAGE ===
# Sử dụng BusyBox làm nền tảng cuối cùng, đã được chứng minh tương thích
FROM busybox:stable-glibc

# Tạo các thư mục cần thiết
RUN mkdir -p /etc/3proxy /var/log/3proxy /usr/local/bin

# Tạo user 'nobody' để chạy 3proxy với quyền hạn thấp nhất, tăng cường bảo mật
RUN echo 'nobody:x:65534:65534::/nonexistent:/sbin/nologin' > /etc/passwd && \
    echo 'nobody:x:65534:' > /etc/group

# Sao chép file 3proxy đã được biên dịch ở Giai đoạn 1 từ đúng đường dẫn
COPY --from=builder /tmp/3proxy/bin/3proxy /usr/local/bin/3proxy

# Sao chép file entrypoint
COPY entrypoint.sh /entrypoint.sh

# Cấp quyền thực thi và quyền sở hữu thư mục log
RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/3proxy && \
    chown -R 65534:65534 /var/log/3proxy

# Chuyển sang user không có quyền hạn
USER nobody

# Chỉ định lệnh sẽ chạy khi container khởi động
ENTRYPOINT ["/entrypoint.sh"]
