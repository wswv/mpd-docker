#!/bin/bash
set -e

# 清理可能的旧pid文件，防止mpd启动失败
rm -f /var/lib/mpd/state/mpd.pid

echo "Starting MPD with config: /etc/mpd/mpd.conf"
# 启动 MPD，运行在后台，并将日志输出到标准输出
# --no-daemon 确保MPD不脱离终端，但我们需要它在后台运行以便启动ympd
mpd --stdout --no-daemon /etc/mpd/mpd.conf &
MPD_PID=$!
echo "MPD started with PID: $MPD_PID"

# 等待 MPD 启动完成，可能需要几秒钟
sleep 2

echo "Starting ympd web UI..."
# 启动 ympd，绑定到所有网络接口 (0.0.0.0) 和端口 8000
ympd -h 0.0.0.0 -p 8000 &
YMPD_PID=$!
echo "ympd started with PID: $YMPD_PID"

# 保持容器运行，当MPD或ympd退出时，容器也会退出
# 使用 wait 命令等待所有子进程完成，确保容器不会提前退出
echo "Both MPD and ympd are running. Waiting for processes to finish..."
wait $MPD_PID $YMPD_PID