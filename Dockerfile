# ============ 第一阶段：编译 Go 程序 ============
FROM golang:1.23-alpine AS builder
WORKDIR /src
# 复制 Go 必要文件
COPY ech-workers.go go.mod go.sum ./
# 下载依赖并编译（静态链接，体积最小）
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /ech-workers ech-workers.go

# ============ 第二阶段：运行环境（支持 GUI + CLI） ============
FROM python:3.11-slim

# 安装 PyQt5 + 虚拟显示器 + 系统托盘依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pyqt5 \
    python3-pyqt5.qtsvg \
    xvfb \
    x11vnc \
    fluxbox \
    && rm -rf /var/lib/apt/lists/*

# 复制编译好的 Go 二进制
COPY --from=builder /ech-workers /usr/local/bin/ech-workers

# 项目文件
WORKDIR /app
COPY gui.py requirements.txt ./

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建配置目录（Linux 标准路径）
RUN mkdir -p /root/.config/ECHWorkersClient

# 暴露端口
EXPOSE 1080    # SOCKS5 代理端口
EXPOSE 5900    # VNC 端口（远程看 GUI 用）

# 启动脚本（最关键的一行）
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
