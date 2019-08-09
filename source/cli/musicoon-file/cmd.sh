#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="Retrieves all relevant information about a given audio file"

dc::commander::initialize
dc::commander::declare::flag "type" "^(offsets|lengths)$" "treat input as a collection of offsets (default) or file lengths" optional
# XXX would be better if we could handle a succession of arguments
dc::commander::declare::arg 1 ".+" "file_path" "path to an audio file"
# Start commander
dc::commander::boot

filename="$DC_PARGV_1"
dc::fs::isfile "$filename"

audiofile::readinfo "$filename"

# .format.format_name
# .streams[] select(codec_type == "audio") .codec_name
