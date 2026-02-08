#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import subprocess
import socket

# 检查Python3和依赖
def check_deps():
    try:
        import flask
    except ImportError:
        print("【第一步】正在安装Flask依赖（轻量化，仅需数秒）...")
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'flask', '--quiet', '--no-cache-dir'], 
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("✅ 依赖检查完成，所有环境就绪")

# 检查8888端口是否被占用
def check_port(port=8888):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(('0.0.0.0', port))
        s.close()
        return False
    except:
        return True

# 启动Flask服务（后台运行，轻量化）
def start_server():
    port = 8888
    if not check_port(port):
        print(f"❌ 端口{port}被占用，请先释放端口再启动")
        sys.exit(1)
    # 切换到api目录
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
    # 后台启动，日志重定向到null（轻量化）
    subprocess.run([
        'nohup', sys.executable, 'app.py',
        '>', '/dev/null', '2>&1', '&'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # 获取服务器IP
    def get_ip():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('8.8.8.8', 80))
            ip = s.getsockname()[0]
        except:
            ip = '127.0.0.1'
        finally:
            s.close()
        return ip
    ip = get_ip()
    print(f"🚀 Nginx WebUI启动成功！")
    print(f"🌐 访问地址：http://{ip}:{port}")
    print(f"💡 提示：如果无法访问，请检查Debian防火墙是否开放8888端口（执行：ufw allow 8888）")

if __name__ == '__main__':
    if os.geteuid() != 0:
        print("❌ 请以root权限运行（执行：sudo python3 run.py）")
        sys.exit(1)
    check_deps()
    start_server()