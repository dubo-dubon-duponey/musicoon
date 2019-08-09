#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="fingerprint local music files, using fpcalc (from the acoustid package)"
# shellcheck disable=SC2034
readonly CLI_EXAMPLES="Fingerprint a file:
> mo-finger-fingerprint -s some_audio_file
> {\"duration\": \"12:03.05\", \"fingerprint\": \"XYZ\"}
"
dc::commander::initialize
dc::commander::declare::arg 1 ".+" "file" "music file to analyze"
dc::commander::boot

dc::fs::isfile "$DC_PARGV_1"

if ! fpcalc::analyze "$DC_PARGV_1"; then
  dc::logger::error "Failed to fingerprint file $1. Is this a valid music file?"
  exit "$ERROR_FAILED"
fi
