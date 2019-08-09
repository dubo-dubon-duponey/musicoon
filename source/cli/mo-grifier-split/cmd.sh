#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="deal with cue files"

# Initialize
dc::commander::initialize
dc::commander::declare::flag delete "^$" "if extracting, delete the original cue and audio files after successfully splitting them" optional
dc::commander::declare::flag destination ".+" "if extracting, where to put the output file - will default to the same directory if left unspecified" optional
dc::commander::declare::flag toc "^$" "prints out the TOC instead of splitting (for discid computation)" optional
dc::commander::declare::arg 1 ".+" "cue" "original cue file to extract or print out"

# Start commander
dc::commander::boot

filename="$DC_PARGV_1"
destination="${DC_ARGV_DESTINATION:-$(dirname "$filename")}"

# Filename is mandatory and must be a readable file
dc::fs::isfile "$filename"

# Must be writable, and create if doesn't exist
dc::fs::isdir "$destination" writable create

# Get the cue content
cue="$(encoding::toutf8 "$filename")"

if [ "$DC_ARGV_BARE" ]; then
  # Convert it to utf8, then print out the gist of it, or fail if it's invalid
  cue::bare "$cue" "$(dirname "$filename")"
  exit
fi




dc::logger::info "Processing $filename"

result="$(cue::processing "$cue" "$(dirname "$filename")")"
printf "%s" "$result" | jq .DISCID

# $(( duration_ts / framerate )) <- seconds
# $(( duration_ts % framerate * 1000000 / framerate )) <- microseconds

while read -r entry; do
  # ts="${entry##* }"
  file="$(dirname "$filename")/${entry% *}"
  result="$(getTrackInfo "$file")"
  printf "%s" "$result" | jq -rc .computed
#  echo "----------------"
#  echo "$file"
  # mo-finger-info "$file"
#  duration="$(mo-finger-info "$file" | jq -rc '.streams[0].duration_ts')"
#  framerate="$(mo-finger-info "$file" | jq -rc '.streams[0].sample_rate')"
#  frames="$((duration / framerate * 75 + ( duration % framerate ) * 75 / framerate ))"
#  echo "$frames"
done < <(printf "%s" "$result" | jq -rc '.FILES[] | .FILE + " " + (.TRACKS[] | select(."01" != null) | ."01")')


#printf "%s" "$result"  | jq -rc '.FILES[].TRACKS[] | select(."01" != null) | ."01"'
exit

splitter::split "$(cue::processing "$cue" "$(dirname "$filename")")" "$(dirname "$filename")" "$destination"


# track data model:
# existing tags
# filename


