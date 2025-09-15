# Sử dụng base image Alpine, nhẹ và hiệu quả
FROM alpine:latest

# Cài đặt các công cụ cần thiết: curl để tải, tar để giải nén, và iproute2 cho lệnh 'ip'
RUN apk add --no-cache curl tar iproute2

# Dùng 'curl -L' để tải file (mạnh mẽ hơn wget) và giải nén phiên bản 3proxy 0.9.5 cho ARM64
RUN curl -L https://github.com/3proxy/3proxy/releases/download/0.9.5/3proxy-0.9.5.aarch64.tar.gz -o /tmp/3proxy.tar.gz && \
    tar -xzf /tmp/3proxy.tar.gz -C /usr/local/bin/ --strip-components=1 bin/3proxy

# Sao chép file entrypoint vào image
COPY entrypoint.sh /entrypoint.sh

# Cấp quyền thực thi
RUN chmod +x /usr/local/bin/3proxy && \
    chmod +x /entrypoint.sh

# Chỉ định lệnh sẽ chạy khi container khởi động
ENTRYPOINT ["/entrypoint.sh"]
