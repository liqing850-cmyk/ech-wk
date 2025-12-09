#!/bin/bash
set -e

# 1. 启动虚拟桌面（给 PyQt 用）
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# 2. 启动简易窗口管理器（不然托盘图标可能不显示）
fluxbox &
sleep 1

# 3. 启动 VNC（方便你远程看到图形界面，密码 123456）
x11vnc -display :99 -forever -nopw -rfbport 5900 &

# 4. 启动 GUI（后台运行）
python gui.py &

# 5. 最后启动 Go 代理（前台运行，日志直接输出到 docker logs）
echo "ECHWorkersClient 容器启动完成！"
echo "→ SOCKS5 代理监听: 0.0.0.0:1080"
echo "→ VNC 远程桌面: 你的NAS_IP:5900（密码 123456）"
exec ech-workers
