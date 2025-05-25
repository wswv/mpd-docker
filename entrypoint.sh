#!/bin/bash
set -e

# 清理可能的旧pid文件，防止mpd启动失败
rm -f /var/lib/mpd/state/mpd.pid

echo "Starting MPD with config: /etc/mpd/mpd.conf"
mpd --stdout --no-daemon /etc/mpd/mpd.conf &
MPD_PID=$!
echo "MPD started with PID: $MPD_PID"

echo "MPD is running. Waiting for process to finish..."
# 等待 MPD 进程结束 (这将使容器保持运行状态)
wait $MPD_PID