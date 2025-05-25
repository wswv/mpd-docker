# Dockerfile for MPD only on Debian Stable (Bookworm)
FROM debian:stable # <--- 将这一行从 debian:bookworm-slim 改为 debian:stable


ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_UID=1000
ARG BUILD_GID=1000

ENV MPD_USER=mpduser
ENV MPD_GROUP=mpdusergroup

# --- 1.1: 创建自定义 GID 的组 ---
RUN set -xe \
    groupadd -g "${BUILD_GID}" "${MPD_GROUP}"

# --- 1.2: 创建自定义 UID 的用户，并将其加入到刚创建的组 ---
RUN set -xe \
    useradd -u "${BUILD_UID}" -g "${MPD_GROUP}" -s /usr/sbin/nologin -m "${MPD_USER}"

# --- 2: 更新软件包列表并安装 MPD 和基本客户端 ---
RUN set -xe \
    apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        mpd \
        mpc \
        ncmpc \
        ncmpcpp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- 3: 更改 MPD 默认文件和目录的所有权 ---
RUN set -xe \
    chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/log/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /run/mpd \
    && mkdir -p /etc/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /etc/mpd

# --- 4: 创建并设置 MPD 额外数据目录的权限 ---
RUN set -xe \
    mkdir -p /var/lib/mpd/music \
                /var/lib/mpd/playlists \
                /var/lib/mpd/database \
                /var/lib/mpd/state \
                /var/lib/mpd/sticker

# 复制 entrypoint 脚本到容器中，并赋予执行权限
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 声明卷
VOLUME /var/lib/mpd

# 暴露 MPD 端口 (6600)
EXPOSE 6600

# 切换到自定义的非 root 用户。
USER "${MPD_USER}"

# 容器启动时执行 entrypoint 脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]