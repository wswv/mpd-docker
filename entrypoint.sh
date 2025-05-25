#!/bin/bash
set -e

# 清理可能的旧pid文件，防止mpd启动失败
rm -f /var/lib/mpd/state/mpd.pid

echo "Starting MPD with config: /etc/mpd/mpd.conf"
mpd --stdout --no-daemon /etc/mpd/mpd.conf &
MPD_PID=$!
echo "MPD started with PID: $MPD_PID"

# 等待 MPD 启动完成，可能需要几秒钟
sleep 2

echo "Starting myMPD web UI..."
# -p 8000: port, -h 0.0.0.0: bind to all interfaces
# -c: create default config if not exists (在新版本中可能不是必须的)
# myMPD 的配置路径通常是 /var/lib/mympd/config/mympd.conf
/usr/local/bin/myMPD -p 8000 -h 0.0.0.0 --config /var/lib/mympd/config/mympd.conf & # 假设安装在 /usr/local/bin
MYMPD_PID=$!
echo "myMPD started with PID: $MYMPD_PID"

echo "Both MPD and myMPD are running. Waiting for processes to finish..."
wait $MPD_PID $MYMPD_PID