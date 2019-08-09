#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="use ffprobe to analyze audio files"

dc::commander::initialize
# recordings, recordingids, releases, releaseids, releasegroups, releasegroupids, tracks, compress, usermeta, sources
dc::commander::declare::arg 1 ".+" "file" "file to analyze"
dc::commander::declare::flag "no-format" "^$" "do not show format information (useful to do stream only comparison)" optional
# Start commander
dc::commander::boot

# Ensure the file exist and is readable
dc::fs::isfile "$DC_PARGV_1"

ffprobe::info "$DC_PARGV_1" "$DC_ARGE_NO_FORMAT"

