# Dockerfile for MPD with myMPD Web UI (compiled from source) on Debian Bookworm Slim, custom UID/GID
FROM debian:bookworm-slim
MAINTAINER EasyPi Software Foundation

# 设置环境变量，确保 apt-get 在非交互模式下运行
ENV DEBIAN_FRONTEND=noninteractive

# 定义构建参数，用于指定用户和组的 UID/GID
ARG BUILD_UID=1000
ARG BUILD_GID=1000

# 定义我们自定义的用户和组名
ENV MPD_USER=mpduser
ENV MPD_GROUP=mpdusergroup

# --- 调试步骤 1.1: 创建自定义 GID 的组 ---
# 修复：将 groupadd 单独放在一个 RUN 层，确保组被完全创建并识别。
RUN set -xe \
    groupadd -g "${BUILD_GID}" "${MPD_GROUP}"

# --- 调试步骤 1.2: 创建自定义 UID 的用户，并将其加入到刚创建的组 ---
# 修复：将 useradd 放在另一个 RUN 层，现在 groupadd 已经完成。
RUN set -xe \
    useradd -u "${BUILD_UID}" -g "${MPD_GROUP}" -s /usr/sbin/nologin -m "${MPD_USER}"

# --- 调试步骤 2: 更新软件包列表 (初步更新) ---
RUN set -xe \
    apt-get update

# --- 调试步骤 3: 安装 MPD 及编译 myMPD 所需的依赖 ---
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
        libz-dev \
        # Add any other build dependencies myMPD might require on Debian Bookworm if compilation fails
    \
    # 确保 apt 缓存是最新的，为下一步下载源码做准备
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- 调试步骤 4: 克隆、编译并安装 myMPD ---
# 以 root 权限执行，因为需要安装到系统路径
RUN set -xe \
    # 重新 apt-get update，以防长时间未构建导致软件包信息过旧
    apt-get update \
    # 防御性安装：确保 git 在此 RUN 层中肯定可用，即使上一步骤存在缓存或 PATH 问题。
    && apt-get install -y --no-install-recommends git \
    \    
    && git clone https://github.com/jcorporation/myMPD.git /tmp/myMPD \
    && cd /tmp/myMPD \
    && cmake -DCMAKE_BUILD_TYPE=Release . \
    && make -j$(nproc) \
    && make install \
    \
    # 5. 清理编译工具和源代码，减小镜像大小
    # 卸载所有编译依赖和 git
    && apt-get purge -y git build-essential cmake libmpdclient-dev libssl-dev libcurl4-gnutls-dev libjson-c-dev libwebsockets-dev libmbedtls-dev libevent-dev libuv1-dev libz-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/myMPD

# --- 调试步骤 5: 更改软件包默认文件和目录的所有权 ---
# 确保在执行 chown 之前，这些目录和文件已经被 mpd 和 mympd (编译安装) 创建。
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