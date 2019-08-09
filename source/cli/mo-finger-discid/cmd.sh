#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="generates a discid (cddb or musicbrainz) from a CD TOC or array of file lengths"

dc::commander::initialize
dc::commander::declare::flag "type" "^(offsets|lengths)$" "treat input as a collection of offsets (default) or file lengths" optional
dc::commander::declare::flag "unit" "^(timecode|frame|fraction)$" "input is specified as mm:ss.ff (default), or as frames" optional
# XXX would be better if we could handle a succession of arguments
dc::commander::declare::arg 1 ".+" "toc" "list of offsets (or lengths) in mm:ss.ff format (minutes, seconds, frames)"
# Start commander
dc::commander::boot

list=($DC_PARGV_1)

# If we do not have frames, convert to frames
if [ "$DC_ARGV_UNIT" == "timecode" ]; then
  list=($(helpers::mmssffListToFramesList "${list[@]}"))
elif [ "$DC_ARGV_UNIT" == "fraction" ]; then
  list=($(helpers::fractionListToFramesList "${list[@]}"))
fi

# If we have lengths instead of offsets, convert
if [ "$DC_ARGV_TYPE" == "lengths" ]; then
  list=($(helpers::frameLengthsToFrameTOC "${list[@]}"))
  list=($(helpers::addTwoSeconds "${list[@]}"))
fi

dc::logger::info "Received toc:" "${list[@]}"

toc=("${list[@]}")
leadout=${toc[$(( ${#toc[@]} - 1 ))]}
unset toc[$(( ${#toc[@]} - 1 ))]
tocstring="1 $(( ${#list[@]} - 1 )) $leadout ${toc[@]}"

# XXX this will fail if a cd starts with a non "1" first track, or end with an offsetted track number
# Not sure why that would happen - opening data tracks? copy protected discs?
printf "{
  \"musicbrainz\": \"%s\",
  \"cddb\": \"%s\",
  \"toc\": \"%s\"
}" "$(discid::musicbrainz 1 $(( ${#list[@]} - 1 )) "${list[@]}")" "$(discid::cddb "${list[@]}")" "$tocstring"

