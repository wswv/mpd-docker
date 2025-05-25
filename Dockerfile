# Dockerfile for MPD with myMPD Web UI on Debian Bookworm Slim, custom UID/GID
FROM debian:bookworm-slim


ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_UID=1000
ARG BUILD_GID=1000

ENV MPD_USER=mpduser
ENV MPD_GROUP=mpdusergroup

# --- 调试步骤 1: 创建自定义 UID/GID 的组和用户 ---
RUN set -xe \
    groupadd -g "${BUILD_GID}" "${MPD_GROUP}" \
    && useradd -u "${BUILD_UID}" -g "${MPD_GROUP}" -s /usr/sbin/nologin -m "${MPD_USER}"

# --- 调试步骤 2: 更新软件包列表 ---
RUN set -xe \
    apt-get update

# --- 调试步骤 3: 安装 MPD 和编译 myMPD 所需的依赖 ---
# 注意：这里安装了编译 myMPD 所需的工具和库
RUN set -xe \
    apt-get install -y --no-install-recommends \
        mpd \
        mpc \
        ncmpc \
        ncmpcpp \
        git \
        build-essential \
        cmake \
        libmpdclient-dev \
        libssl-dev \
        libcurl4-gnutls-dev \
        libjson-c-dev \
        libwebsockets-dev \
        libmbedtls-dev \
        libevent-dev \
        libuv1-dev \
        libz-dev # 确保所有可能的依赖都包含

# --- 调试步骤 4: 克隆、编译并安装 myMPD ---
# 以 root 权限执行，因为需要安装到系统路径
RUN set -xe \
    git clone https://github.com/jcorporation/myMPD.git /tmp/myMPD \
    && cd /tmp/myMPD \
    && cmake -DCMAKE_BUILD_TYPE=Release . \
    && make -j$(nproc) \
    && make install \
    \
    # 5. 清理编译工具和源代码，减小镜像大小
    && apt-get purge -y build-essential cmake git libmpdclient-dev libssl-dev libcurl4-gnutls-dev libjson-c-dev libwebsockets-dev libmbedtls-dev libevent-dev libuv1-dev libz-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/myMPD

# --- 调试步骤 6: 更改 MPD 默认文件和目录的所有权 ---
RUN set -xe \
    chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/log/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /run/mpd \
    && mkdir -p /etc/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /etc/mpd \
    \
    # 确保 myMPD 也能写入其数据目录（如果有的话，通常是 /var/lib/mympd）
    && mkdir -p /var/lib/mympd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mympd

# --- 调试步骤 7: 创建并设置 MPD 额外数据目录的权限 ---
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
VOLUME /var/lib/mympd # myMPD 也可能有自己的数据目录

# 暴露 MPD (6600) 和 myMPD Web UI (8000) 的端口
EXPOSE 6600 8000

# 切换到自定义的非 root 用户。
USER "${MPD_USER}"

# 容器启动时执行 entrypoint 脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]