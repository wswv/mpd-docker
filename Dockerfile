# 使用debian:stable-slim作为基础镜像
FROM debian:stable-slim

# 设置默认的UID和GID，可通过构建参数覆盖
ARG USER_UID=1000
ARG USER_GID=1000

# 安装必要的依赖和MPD相关工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mpd \
    mpc \
    ncmpc \
    ncmpcpp \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建非root用户和组
RUN groupadd -g ${USER_GID} mpduser && \
    useradd -u ${USER_UID} -g mpduser -m -s /bin/bash mpduser

# 创建MPD需要的目录并设置权限
RUN mkdir -p /var/run/mpd /var/lib/mpd /var/log/mpd && \
    chown -R mpduser:mpduser /var/run/mpd /var/lib/mpd /var/log/mpd

# 复制MPD配置文件
COPY mpd.conf /etc/mpd.conf

# 设置工作目录
WORKDIR /var/lib/mpd

# 切换到非root用户
USER mpduser

# 暴露MPD默认端口
EXPOSE 6600

# 设置容器启动命令
CMD ["mpd", "--no-daemon", "/etc/mpd.conf"]