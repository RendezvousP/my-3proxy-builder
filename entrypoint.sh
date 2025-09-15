#!/bin/sh
set -e
mkdir -p /etc/3proxy

# Tao file cau hinh
cat <<EOF > /etc/3proxy/3proxy.cfg
nserver 8.8.8.8
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
maxconn 500
radius admin 10.3.0.254
auth radius
flush
EOF

# tao bien global
batdau=1
ketthuc=250 # Giữ nguyên 250 proxy như file gốc
prefix="10.3."
netmark="/24"

HTTP_START_PORT=10001
SOCKS_START_PORT=20001

for i in $(seq $batdau $ketthuc); do
	subindex=$(( (i - 1) / 250 ))
	hostindex=$(( (i - 1) % 250 + 1 ))
	IP="$prefix$subindex.$hostindex"
	HTTP_PORT=$((HTTP_START_PORT + i - 1))
	SOCKS_PORT=$((SOCKS_START_PORT + i - 1))

    echo "proxy -a -p$HTTP_PORT -i$IP -e$IP" >> /etc/3proxy/3proxy.cfg
	echo "socks -a -p$SOCKS_PORT -i$IP -e$IP" >> /etc/3proxy/3proxy.cfg
done

for i in $(seq $batdau $ketthuc); do
	subindex=$(( (i - 1) / 250 ))
	hostindex=$(( (i - 1) % 250 + 1 ))
	IP="$prefix$subindex.$hostindex$netmark"
    ip addr add $IP dev eth0
done

# Thuc thi dich vu 3proxy
exec /usr/local/bin/3proxy /etc/3proxy/3proxy.cfg
