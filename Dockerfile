# Dockerfile for MPD with Web UI (ympd) on Debian Bookworm Slim, custom UID/GID
FROM debian:bookworm-slim


# 设置环境变量，确保 apt-get 在非交互模式下运行
ENV DEBIAN_FRONTEND=noninteractive

# 定义构建参数，用于指定用户和组的 UID/GID
# 默认值设置为 1000，这是 Linux 系统中常见非 root 用户的 UID/GID
ARG BUILD_UID=1000
ARG BUILD_GID=1000

# 定义我们自定义的用户和组名
ENV MPD_USER=mpduser
ENV MPD_GROUP=mpdusergroup

RUN set -xe \
    # 1. 创建自定义 UID/GID 的组和用户，在安装 mpd 包之前完成
    #    -g: 指定 GID
    #    -u: 指定 UID
    #    -s /usr/sbin/nologin: 设置不可登录的 shell
    #    -m: 创建用户主目录 (虽然我们不直接使用，但最佳实践)
    && groupadd -g "${BUILD_GID}" "${MPD_GROUP}" \
    && useradd -u "${BUILD_UID}" -g "${MPD_GROUP}" -s /usr/sbin/nologin -m "${MPD_USER}" \
    \
    # 2. 更新软件包列表并安装 mpd, ympd 等
    #    --no-install-recommends 减少镜像大小
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        mpd \
        ympd \
        mpc \
        ncmpc \
        ncmpcpp \
    \
    # 3. 清理 apt 缓存和临时文件，以减小镜像大小
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    \
    # 4. 更改软件包默认文件和目录的所有权为自定义用户
    #    mpd 软件包安装后，一些文件/目录会默认属于 UID 100 的 'mpd' 用户。
    #    我们需要将这些文件的所有权更改为我们自定义的 'mpduser'。
    #    注意: '/var/lib/mpd' 会被 mpd 软件包创建。
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/lib/mpd \
    #    '/var/log/mpd' 也会被 mpd 软件包创建。
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /var/log/mpd \
    #    '/run/mpd' 也会被 mpd 软件包创建，用于 pid 文件。
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /run/mpd \
    #    确保 /etc/mpd 目录存在 (用于挂载 mpd.conf)，并确保我们自定义用户拥有其所有权
    #    虽然 /etc/mpd 通常不需要自定义用户写，但确保一致性
    && mkdir -p /etc/mpd \
    && chown -R "${MPD_USER}":"${MPD_GROUP}" /etc/mpd \
    \
    # 5. 创建并设置 MPD 额外数据目录的权限 (这些目录可能不是 mpd 包默认创建的)
    #    由于上面已经 chown -R /var/lib/mpd，这里的子目录创建后会自动继承所有权
    && mkdir -p /var/lib/mpd/music \
                /var/lib/mpd/playlists \
                /var/lib/mpd/database \
                /var/lib/mpd/state \
                /var/lib/mpd/sticker

# 复制 entrypoint 脚本到容器中，并赋予执行权限
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 声明卷，表明这是一个数据卷目录
VOLUME /var/lib/mpd

# 暴露 MPD (6600) 和 ympd Web UI (8000) 的端口
EXPOSE 6600 8000

# 切换到自定义的非 root 用户。
USER "${MPD_USER}"

# 容器启动时执行 entrypoint 脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]