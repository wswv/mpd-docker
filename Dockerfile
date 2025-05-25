# Dockerfile for mpd with non-root user
FROM alpine
MAINTAINER EasyPi Software Foundation

# Create a dedicated group and user for mpd
# -G mpd: Assigns the user to the 'mpd' group
# -s /sbin/nologin: Sets a shell that doesn't allow login
# -D: Don't assign a password
# mpd: The username
RUN set -xe \
    && addgroup -S mpd \
    && adduser -S -G mpd -s /sbin/nologin -D mpd \
    && apk add --no-cache mpd mpc ncmpc ncmpcpp

# Set capabilities (still needed for binding to privileged ports if not using host network, or for other features)
# However, for non-root, it's generally about file system access and specific operations.
# For standard unprivileged ports (>= 1024), capabilities might not be strictly needed for binding.
# For listening on 6600, it's fine. The setcap -r is to remove capabilities.
RUN setcap -r /usr/bin/mpd

# Create and set permissions for MPD's data directory for the non-root user
# These directories will be used if volumes are NOT mounted for them.
# If volumes ARE mounted, ensure your host directories have appropriate permissions for the user ID (UID) used inside the container.
RUN mkdir -p /var/lib/mpd/music \
    /var/lib/mpd/playlists \
    /var/lib/mpd/database \
    /var/lib/mpd/log \
    /var/lib/mpd/state \
    /var/lib/mpd/sticker \
    && chown -R mpd:mpd /var/lib/mpd

# Define the volume for MPD's data. If you mount a volume from the host,
# ensure the host directory has permissions matching the 'mpd' user inside.
VOLUME /var/lib/mpd

EXPOSE 6600

# Switch to the non-root 'mpd' user
USER mpd

# Command to run mpd
# Ensure your mpd.conf specifies directories relative to the container and
# that the 'mpd' user has write access to necessary directories (e.g., for database, log, state).
CMD ["mpd", "--stdout", "--no-daemon", "/etc/mpd/mpd.conf"]