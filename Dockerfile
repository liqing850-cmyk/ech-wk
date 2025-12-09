# 阶段1: 编译Go代理（使用仓库的go.mod）
FROM golang:1.23-alpine AS go-builder
WORKDIR /app
# 复制Go文件（假设仓库有ech-workers.go和go.mod）
COPY ech-workers.go go.mod go.sum ./
RUN go mod download && go build -o ech-workers ech-workers.go

# 阶段2: Python GUI环境（兼容NAS Linux）
FROM python:3.9-slim
# 安装依赖：PyQt5、Xvfb（虚拟显示，支持GUI无头运行）、pystray（托盘）
RUN apt-get update && apt-get install -y \
    pyqt5-dev-tools \
    xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir PyQt5 pystray
WORKDIR /app
# 从Go阶段复制二进制
COPY --from=go-builder /app/ech-workers /usr/local/bin/
# 复制Python文件
COPY gui.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 暴露代理端口（默认1080，可自定义）
EXPOSE 1080

# 启动脚本：后台运行Go代理，前台可选GUI（用Xvfb模拟显示）
# 在NAS上，CLI模式优先；GUI需VNC访问
CMD ["sh", "-c", "\
    Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & \
    export DISPLAY=:99 && \
    mkdir -p /root/.config/ECHWorkersClient && \
    (python gui.py &) || echo 'GUI启动失败，使用CLI' && \
    ./ech-workers"]
