#!/usr/bin/env bash

# Cue splitter
# Based on:
# https://en.wikipedia.org/wiki/Cue_sheet_(computing)
# http://wiki.hydrogenaud.io/index.php?title=Cue_sheet
# https://web.archive.org/web/20160201021136/http://digitalx.org/cue-sheet/syntax/
# https://web.archive.org/web/20081218052946/http://digitalx.org/cuesheetsyntax.php

# XXX go to sleep
# Interesting: cat "/Users/dmp/Music/Dock/azmotentative//Audio Active/Audio Active - Bong - 2000/Audio Active - Bong.cue"
# Also, all L7 playlists because of the implied pregaps

# Expect
cue::bare(){
  local cue="$1"
  local root="$2"

  local entry
  local i
  local file

  local OFS="$IFS"
  IFS=''
  while read -r entry; do
    # Grab indexes and tracks
    if printf "%s" "$entry" | grep -q "^(  TRACK|    INDEX)"; then
      printf "%s\n" "$entry"
      continue
    fi
    # Anything else that is not a FILE entry gets discarded
    if ! printf "%s" "$entry" | grep -q "^FILE"; then
      continue
    fi

    # The WAVE part is irrelevant (cuebreakpoint doesn't even recognize anything else)
    if ! file="$(cue::helpers::checkfile "$entry" "$root")"; then
      dc::logger::error "File entry is invalid..."
      exit "$ERROR_FAILED"
    fi
    printf "FILE \"%s\" WAVE\n" "$file"
  done < <(printf "%s\n" "$cue")
  IFS="$OFS"
}

cue::helpers::timestamp(){
  local entry="$1"
  local audio="$2"
  local mil="${entry##*:}"
  local min
  local samplerate

  samplerate="$(metaflac --show-sample-rate "$audio")"
  entry="${entry%:*}"
  # Remove one millisecond to get the upper boundary?
  # mil=$(( $mil - 1 ))
  min="${entry%%:*}"
  entry="${entry##*:}"

  if printf "%s" "$min" | grep -q "^0"; then
    min=${min#*0}
  fi

  if printf "%s" "$mil" | grep -q "^0"; then
    mil=${mil#*0}
  fi

  if printf "%s" "$entry" | grep -q "^0"; then
    entry=${entry#*0}
  fi

  # Use samples instead
  printf "%s" "$(( ((min * 60 + entry) * 75 + mil ) * samplerate / 75 ))"

  #printf "%s" "$min:$entry.$mil"
}

# Should be fed the result of "processing"
splitter::split(){
  local json="$1"
  local root="$2"
  local destination="$3"

  local time=()

  local albumartist
  local album
  local date
  local discid
  # local comment
  local barcode
  albumartist="$(printf "%s" "$json" | jq -rc "select(.PERFORMER != null) | .PERFORMER")"
  album="$(printf "%s" "$json" | jq -rc "select(.TITLE != null) | .TITLE")"
  date="$(printf "%s" "$json" | jq -rc "select(.DATE != null) | .DATE")"
  discid="$(printf "%s" "$json" | jq -rc "select(.DISCID != null) | .DISCID")"
  #comment="$(printf "%s" "$json" | jq -rc "select(.COMMENT != null) | .COMMENT")"
  barcode="$(printf "%s" "$json" | jq -rc "select(.CATALOG != null) | .CATALOG")"

  destination="$destination/$albumartist/($date) $album ($discid - $barcode)"
  mkdir -p "$destination"

  local pregapped=""

  local tracknumber
  local title
  local isrc
  local artist

  while read -r file; do
    audio="$(printf "%s" "$file" | jq -rc ".FILE")"
    time=()
    tracknumber=()
    title=()
    isrc=()
    artist=()

    # time+=("00:00.00")
    while read -r track; do
      if [ ! "$pregapped" ]; then
        tracknumber+=("$(printf "%s" "$track" | jq -rc ".TRACK")")
        title+=("$(printf "%s" "$track" | jq -rc "select(.TITLE != null) | .TITLE")")
        isrc+=("$(printf "%s" "$track" | jq -rc "select(.ISRC != null) | .ISRC")")
        artist+=("$(printf "%s" "$track" | jq -rc "select(.PERFORMER != null) | .PERFORMER")")
      else
        tracknumber+=("$(printf "%s" "$pregapped" | jq -rc ".TRACK")")
        title+=("$(printf "%s" "$pregapped" | jq -rc ".TITLE")")
        isrc+=("$(printf "%s" "$pregapped" | jq -rc "select(.ISRC != null) | .ISRC")")
        artist+=("$(printf "%s" "$pregapped" | jq -rc "select(.PERFORMER != null) | .PERFORMER")")
        pregapped=""
      fi

      # Generally ignore the pregaps
      value="$(printf "%s" "$track" | jq -rc '."00"')"
      if [ "$value" != "null" ]; then
        dc::logger::warning "Ignoring index 0 with value $value"
      fi

      # Look at index 1
      value="$(printf "%s" "$track" | jq -rc '."01"')"
      if [ "$value" != "null" ]; then
        time+=("$(cue::helpers::timestamp "$value" "$root/$audio")")
      else
        # No index 1 in this track, likely, we are on a pregap on the previous file and need to port the info to the next track
        dc::logger::info "Pregap info, porting to the next round"
        #dc::logger::error "Index 1 NULL: $value"
        pregapped="$track"
      fi

      value="$(printf "%s" "$track" | jq -rc '."02"')"
      if [ "$value" != "null" ]; then
        dc::logger::error "We have index 2 in here!!!! with value $value"
      fi

      value="$(printf "%s" "$track" | jq -rc '.PREGAP')"
      if [ "$value" != "null" ]; then
        dc::logger::warning "Ignoring pregap here with value $value"
      fi

    done < <(printf "%s" "$file" | jq -rc ".TRACKS[]")
    # time+=('-0')
    time+=('-0:00')

    dc::logger::info "Converting from $root/$audio"

    local args
    local i
    local j
    local varname

    for (( i=0; i<$((${#time[@]}-1)); i++)); do
      dc::logger::info "Track ${tracknumber[$i]}-${title[$i]} "

      args=("$root/$audio" "$destination/${tracknumber[$i]}-${title[$i]}.flac" "" "${time[$i]}" "${time[$(( i + 1 ))]}")

      for j in ALBUMARTIST ALBUM DATE DISCID BARCODE COMMENT; do
        varname="$(printf "%s" "$j" | tr '[:upper:]' '[:lower:]')"
        if [ "${!varname}" ]; then
          args+=("$j=${!varname}")
        fi
      done

      for j in ARTIST TITLE ISRC TRACKNUMBER; do
        varname="$(printf "%s" "$j" | tr '[:upper:]' '[:lower:]')[$i]"
        if [ "${!varname}" ]; then
          args+=("$j=${!varname}")
        fi
      done
      flac::encode "${args[@]}"
    done

  done < <(printf "%s" "$json" | jq -rc ".FILES[]")
}

# Notes
# this is wrong https://unix.stackexchange.com/questions/10251/how-do-i-split-a-flac-with-a-cue
# mutagen-inspect original file to get fallback metainfo?
