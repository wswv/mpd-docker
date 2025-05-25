# Dockerfile for MPD with myMPD Web UI (compiled from source) on Debian Bookworm Slim, custom UID/GID
FROM debian:bookworm-slim


ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_UID=1000
ARG BUILD_GID=1000

ENV MPD_USER=mpduser
ENV MPD_GROUP=mpdusergroup

# --- 调试步骤 1.1: 创建自定义 GID 的组 ---
RUN set -xe \
    groupadd -g "${BUILD_GID}" "${MPD_GROUP}"

# --- 调试步骤 1.2: 创建自定义 UID 的用户，并将其加入到刚创建的组 ---
RUN set -xe \
    useradd -u "${BUILD_UID}" -g "${MPD_GROUP}" -s /usr/sbin/nologin -m "${MPD_USER}"

# --- 调试步骤 2: 强制更新软件包列表并安装 git ---
# 这一步专门用于确保 git 及其核心依赖被安装。
# 我们会在这里安装 git，并清理 apt 缓存，以便后续步骤可以依赖 git。

RUN set -xe \
    echo "--- Starting apt-get update for git ---" \
    && apt-get update --fix-missing \
    # 尝试修复缺失的索引
    && echo "--- apt-get update for git finished ---" \
    \
    # 增加调试信息，查看 sources.list 内容
    && echo "--- /etc/apt/sources.list content ---" \
    && cat /etc/apt/sources.list \
    && echo "--- /etc/apt/sources.list.d/ content ---" \
    && ls -l /etc/apt/sources.list.d/ \
    \
    && echo "--- Attempting to install git ---" \
    && apt-get install -y --no-install-recommends git \
    && echo "--- git installation finished ---" \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- 调试步骤 3: 安装 MPD 及编译 myMPD 所需的其他依赖 ---
# 现在 git 已经安装好了，这里安装其他编译工具和库。
# 再次更新，确保其他包的最新信息
RUN set -xe \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        mpd \
        mpc \
        ncmpc \
        ncmpcpp \
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
        libz-dev \
    \
    # 清理 apt 缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- 调试步骤 4: 克隆、编译并安装 myMPD ---
# 现在 git 已经安装好了，直接使用 git clone。
RUN set -xe \
    git clone https://github.com/jcorporation/myMPD.git /tmp/myMPD \
    && cd /tmp/myMPD \
    && cmake -DCMAKE_BUILD_TYPE=Release . \
    && make -j$(nproc) \
    && make install \
    \
    # 5. 清理编译工具和源代码，减小镜像大小
    # 卸载所有编译依赖 (不包括 mpd, mpc, ncmpc, ncmpcpp, mympd)
    # 注意：git 也会被移除，因为它在编译后不再需要。
    && apt-get purge -y build-essential cmake libmpdclient-dev libssl-dev libcurl4-gnutls-dev libjson-c-dev libwebsockets-dev libmbedtls-dev libevent-dev libuv1-dev libz-dev git \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/myMPD

# --- 调试步骤 5: 更改软件包默认文件和目录的所有权 ---
RUN set -xe \
    chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/log/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /run/mpd \
    && mkdir -p /etc/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /etc/mpd \
    \
    # myMPD 的数据目录通常是 /var/lib/mympd
    && mkdir -p /var/lib/mympd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mympd \
    # myMPD 的配置目录通常是 /etc/mympd
    && mkdir -p /etc/mympd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /etc/mympd

# --- 调试步骤 6: 创建并设置 MPD 额外数据目录的权限 ---
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
VOLUME /var/lib/mympd # myMPD 也有自己的数据目录

# 暴露 MPD (6600) 和 myMPD Web UI (8000) 的端口
EXPOSE 6600 8000

# 切换到自定义的非 root 用户。
USER "${MPD_USER}"

# 容器启动时执行 entrypoint 脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]