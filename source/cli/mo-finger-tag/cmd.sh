#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="read and write tags to local music files"

dc::commander::initialize
# recordings, recordingids, releases, releaseids, releasegroups, releasegroupids, tracks, compress, usermeta, sources
dc::commander::declare::flag write "^$" "write instead of read" optional
dc::commander::declare::arg 1 ".+" "file" "music file to read/write tags"
# Start commander
dc::commander::boot

# Ensure the file exist and is readable
dc::fs::isfile "$DC_PARGV_1"

if [ "$DC_ARGE_WRITE" ]; then
  mutagen::write::json "$DC_PARGV_1"
else
  mutagen::read::json "$DC_PARGV_1"
fi
