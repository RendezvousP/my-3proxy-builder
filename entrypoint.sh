#!/bin/sh
set -e
sleep 2

# === PHẦN 1: TỰ ĐỘNG THÊM 1000 ĐỊA CHỈ IP VÀO CONTAINER ===
echo "--- Adding 1000 IP addresses to eth0 ---"
TOTAL_IPS=1000
for i in $(seq 1 $TOTAL_IPS); do
    SUBNET_B=$(((i - 1) / 253))
    HOST=$(((i - 1) % 253 + 2))
    IP_ADDR="10.10.${SUBNET_B}.${HOST}/32"
    ip addr add $IP_ADDR dev eth0
done
echo "--- IP address configuration complete ---"

# === PHẦN 2: TỰ ĐỘNG TẠO FILE CONFIG 3PROXY ===
CONFIG_FILE="/etc/3proxy/3proxy.cfg"
TOTAL_PROXIES=1000
HTTP_START_PORT=10001
SOCKS_START_PORT=20001
RADIUS_IP="10.10.0.1"
RADIUS_SECRET="myRadiusSecret" # <<< THAY MẬT KHẨU CỦA BẠN VÀO ĐÂY

echo "--- Generating 3proxy config file ---"
cat << EOF > $CONFIG_FILE
daemon
maxconn 1500
nscache 65536
stacksize 8000
timeouts 1 5 30 60 180 1800 15 60
setuid 65534
setgid 65534
nserver 8.8.8.8
nserver 8.8.4.4
nserver 9.9.9.9
log /var/log/3proxy/3proxy.log D
logformat "L%C - %U [%d/%b/%Y:%H:%M:%S %z] ""%T"" %E %I %O %N/%R:%r"
radius ${RADIUS_SECRET} ${RADIUS_IP}
auth radius
allow *
EOF

for i in $(seq 1 $TOTAL_PROXIES); do
    PORT=$((HTTP_START_PORT + i - 1))
    SUBNET_B=$(((i - 1) / 253))
    HOST=$(((i - 1) % 253 + 2))
    EXTERNAL_IP="10.10.${SUBNET_B}.${HOST}"
    echo "proxy -n -p${PORT} -i0.0.0.0 -e${EXTERNAL_IP}" >> $CONFIG_FILE
done

for i in $(seq 1 $TOTAL_PROXIES); do
    PORT=$((SOCKS_START_PORT + i - 1))
    SUBNET_B=$(((i - 1) / 253))
    HOST=$(((i - 1) % 253 + 2))
    EXTERNAL_IP="10.10.${SUBNET_B}.${HOST}"
    echo "socks -n -p${PORT} -i0.0.0.0 -e${EXTERNAL_IP}" >> $CONFIG_FILE
done
echo "--- Config generation complete ---"

# === PHẦN 3: KHỞI CHẠY 3PROXY ===
echo "--- Starting 3proxy service ---"
exec /usr/local/bin/3proxy /etc/3proxy/3proxy.cfg