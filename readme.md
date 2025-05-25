## Introduction
This docker image fork from https://github.com/vimagick/dockerfiles/blob/master/mpd/Dockerfile, by the help of Gemini AI.
Here the new fork purpose to add more platform support, like Raspberry pi, mips, and have non-root privilege control.

## Instruction
### Project Structure (Recommended)

Before creating the docker-compose.yml, let's set up a recommended directory structure on your host machine:
```conf
mpd-docker/
├── Dockerfile                  # Your Dockerfile (from the previous response)
├── docker-compose.yml          # The docker-compose file we're creating now
├── config/
│   └── mpd.conf                # Your custom mpd.conf (see example below)
├── music/                      # Your music files will go here
│   └── Artist/
│       └── Album/
│           └── song.flac
└── data/
    ├── playlists/              # MPD playlists will be stored here
    ├── database/               # MPD database file (mpd.db)
    ├── log/                    # MPD log file (mpd.log)
    ├── state/                  # MPD state file (mpdstate)
    └── sticker/                # MPD sticker database (sticker.sql)

```
### config/mpd.conf (Example)

Create this file inside the config directory. Ensure the paths inside are relative to the container's filesystem as previously discussed:
Ini, TOML
```conf
# config/mpd.conf
music_directory "/var/lib/mpd/music"
playlist_directory "/var/lib/mpd/playlists"
db_file "/var/lib/mpd/database"
log_file "/var/log/mpd/mpd.log"
pid_file "/var/run/mpd/pid"
state_file "/var/lib/mpd/state"
sticker_file "/var/lib/mpd/sticker.sql"

audio_output {
    type "alsa"
    name "My ALSA Device"
}

bind_to_address "0.0.0.0"
port "6600"

# Optional: Set a user if you want MPD to drop privileges *further*
# (though our Dockerfile already runs it as 'mpd')
# user "mpd"

# Audio output example (adjust as needed for your setup)
# For most users, "null" or "pulse" might be more practical in a Docker context,
# or you might need host-level audio drivers if running on a dedicated audio device.
audio_output {
    type            "null" # Use "null" for testing, or if audio isn't needed from the container
    name            "My Null Output"
}

# Add other settings like mixer, replaygain, etc.

```

### docker-compose.yml

Place this file in the mpd-docker/ root directory.
```YAML

# docker-compose.yml
services:
  mpd:
    image: ${DOCKERHUB_USERNAME}/mpd-custom:latest
    container_name: mpd
    ports:
      - "6600:6600"
    volumes:
      - /path/to/your/music:/var/lib/mpd/music
      - /path/to/your/playlists:/var/lib/mpd/playlists
    environment:
      - USER_UID=${USER_UID:-1000}
      - USER_GID=${USER_GID:-1000}
    restart: unless-stopped


```
