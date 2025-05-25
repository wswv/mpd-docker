## Introduction
This docker image fork from https://github.com/vimagick/dockerfiles/blob/master/mpd/Dockerfile, by the help of Gemini AI.
Here the new fork purpose to add more platform support, like Raspberry pi, mips, and privilege control.

## Instruction
### Project Structure (Recommended)

Before creating the docker-compose.yml, let's set up a recommended directory structure on your host machine:

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

### config/mpd.conf (Example)

Create this file inside the config directory. Ensure the paths inside are relative to the container's filesystem as previously discussed:
Ini, TOML
```conf
# config/mpd.conf
music_directory "/var/lib/mpd/music"
playlist_directory "/var/lib/mpd/playlists"
db_file "/var/lib/mpd/database/mpd.db"
log_file "/var/lib/mpd/log/mpd.log"
pid_file "/var/lib/mpd/state/mpd.pid"
state_file "/var/lib/mpd/state/mpdstate"
sticker_file "/var/lib/mpd/sticker/sticker.sql"

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
version: '3.8'

services:
  mpd:
    # Use 'build: .' to build the Dockerfile in the current directory
    build: .
    container_name: mpd_server
    restart: unless-stopped
    ports:
      - "6600:6600" # Host_Port:Container_Port

    volumes:
      # Music files (read-only)
      - ./music:/var/lib/mpd/music:ro
      # MPD configuration file
      - ./config/mpd.conf:/etc/mpd/mpd.conf:ro
      # Persistent data directories (read/write for MPD user)
      - ./data/playlists:/var/lib/mpd/playlists
      - ./data/database:/var/lib/mpd/database
      - ./data/log:/var/lib/mpd/log
      - ./data/state:/var/lib/mpd/state
      - ./data/sticker:/var/lib/mpd/sticker

    # Optional: If you need to access specific host devices (e.g., sound card)
    # devices:
    #   - /dev/snd:/dev/snd # Uncomment and adjust if you need direct audio hardware access

```
