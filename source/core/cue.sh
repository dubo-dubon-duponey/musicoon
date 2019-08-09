#!/usr/bin/env bash

# List of file extensions we support for files referenced in CUEs
readonly MUSICOON_SUPPORTED_AUDIO=(flac ape m4a wav mp3 ogg)
# First four letters of keys that are authorized in a CUE file - any line starting with a key not listed here will interrupt parsing
readonly MUSICOON_ALLOWED_KEYS=("PERFORMER" "TITLE" "FILE" "TRACK" "COMPOSER" "PREGAP" "ISRC" "CATALOG" "FLAG" "SONG")


# Extract the string value from a cue "KEY: VALUE" line
cue::helpers::linevalue(){
  local entry="$1"
  # Get anything after the key
  entry="$(dc::string::trimSpace entry)"
  # If it's a quoted string, get that
  if printf "%s" "$entry"| grep -q '"'; then
    # XXX do something for escaped quotes?
    entry="${entry#*\"}"
    entry="${entry%\"*}"
  else
  # If not, get the last word
    entry="${entry##* }"
  fi
  printf "%s" "$entry"
}

# Produce JSON ready key: value out of a line
cue::helpers::linetojson(){
  local entry="$1"
  # Clean-up
  entry="$(dc::string::trimSpace entry)"
  # If it's a quoted string, get that
  if printf "%s" "$entry"| grep -q '"'; then
    # XXX do something for escaped quotes?
    key="${entry%% \"*}"
    entry="${entry#*\"}"
    entry="${entry%\"*}"
  else
  # If not, get the last word
    key="${entry% *}"
    entry="${entry##* }"
  fi

  # Post-process tracks
  if [ "${key:0:5}" == "TRACK" ]; then
    key="${key#* }"
    printf "%s" "\"$key\""
    return
  fi
  # Post-process indexes
  if [ "${key:0:5}" == "INDEX" ]; then
    key="${key#* }"
  # Post-process REM
  elif [ "${key:0:3}" == "REM" ]; then
    key="${key#* }"
  # VERBOTEN key, break out
  elif ! helpers::array::contains "${key}" "${MUSICOON_ALLOWED_KEYS[@]}"; then
    dc::logger::error "Cue file contains unrecognized key (starting with $(printf "%s" "${key:0:3}" | hexdump -C), will stop here: $key (and $value)"
    exit "$ERROR_FAILED"
  fi

  # Print out json fragments
  printf "\"%s\": \"%s\"" "$key" "$entry"
}

# Analyze a "FILE" line, and return a file path that exist (possibly swapping out file extension)
# XXX this will fail to detect audio files with an extension that is not lowercase
# XXX this will also fail if an absolute path has been used for the file entry (which would be crazy, but then)
# More generally, we could use some working "realpath" here (coreutils' realpath on mac is pigged-out at this time)
cue::helpers::checkfile(){
  local entry="$1"
  local root="$2"
  local i
  local ext=""
  local cleaned

  # Sometimes, the file string is unquoted... so, strip the last word in all cases since we ignore it
  entry="${entry% *}"
  # Extract the value
  entry="$(cue::helpers::linevalue "$entry")"
  # Some cue files use windows style backslashes, so, convert that
  entry="$(printf "%s" "$entry" | sed -E "s/[\\]/\//g")"

  cleaned="$entry"

  # Strip out the extension and try to find a matching file with a known extension
  ext="${entry##*.}"
  if [ -f "$root/$entry" ]; then
    printf "%s" "$entry"
    return
  fi

  entry="${entry%.*}"
  ext=""
  for i in "${MUSICOON_SUPPORTED_AUDIO[@]}"; do
    if [ -f "$root/$entry.$i" ]; then
      ext="$i"
      break
    fi
  done

  # Didn't work? Try to strip folder names
  if [ ! "$ext" ]; then
    entry="$(basename "$entry")"
    for i in "${MUSICOON_SUPPORTED_AUDIO[@]}"; do
      if [ -f "$root/$entry.$i" ]; then
        ext="$i"
        break
      fi
    done
  fi

  # Still didn't work? Sometimes, an extension is just being slapped on top of the previous name
  if [ ! "$ext" ]; then
    entry="$cleaned"
    for i in "${MUSICOON_SUPPORTED_AUDIO[@]}"; do
      if [ -f "$root/$entry.$i" ]; then
        ext="$i"
        break
      fi
    done
  fi

  # Last chance. Conflated extensions, stripped folders.
  if [ ! "$ext" ]; then
    entry="$(basename "$entry")"
    for i in "${MUSICOON_SUPPORTED_AUDIO[@]}"; do
      if [ -f "$root/$entry.$i" ]; then
        ext="$i"
        break
      fi
    done
  fi

  if [ ! "$ext" ]; then
    dc::logger::error "This is a broken cue file, missing audio file $entry"
    exit "$ERROR_FAILED"
  fi
  printf "%s" "$entry.$ext"
}

# Takes a cue content and turn it into json
# XXX comments are collapsed - there may be multiple comments
cue::processing(){
  local cue="$1"
  local rootdirectory="$2"
  local entry
  local line

  local file=()
  local files=()
  local track=()
  local tracks=()
  local root=()

  local filecandidate

  local dirty

  local OFS="$IFS"
  IFS=''
  while read -r entry; do
    # Hitting something not valid in the file, stop here
    if ! line=("$(cue::helpers::linetojson "$entry")"); then
      dirty=true
      break
    fi

    if printf "%s" "$entry" | grep -q "^    "; then
      # Track data
      track+=("$line")
      continue
    fi

    if printf "%s" "$entry" | grep -q "^  TRACK"; then
      # New track
      # If there was a previous track in the file, close it
      # If there is a pending track, close it
      if [ "${#track[@]}" -gt 0 ]; then
        tracks+=("$(helpers::tojsonobject "${track[@]}")")
        track=()
      fi
      track+=("\"TRACK\": $line")
      continue
    fi

    if printf "%s" "$entry" | grep -q "^FILE"; then
      # New file
      # If there is a pending track, close it
      if [ "${#track[@]}" -gt 0 ]; then
        tracks+=("$(helpers::tojsonobject "${track[@]}")")
        track=()
      fi
      # If we had tracks, close them
      if [ "${#tracks[@]}" -gt 0 ]; then
        file+=("\"TRACKS\": $(helpers::tojsonarray "${tracks[@]}")")
        tracks=()
      fi
      # If we had a previous file, close it
      if [ "${#file[@]}" -gt 0 ]; then
        files+=("$(helpers::tojsonobject "${file[@]}")")
        file=()
      fi

      if ! filecandidate="$(cue::helpers::checkfile "$entry" "$rootdirectory")"; then
        dc::logger::error "File entry is invalid... Failing hard."
        exit "$ERROR_FAILED"
      fi

      file=("\"FILE\": \"$filecandidate\"")
      continue
    fi

    # Otherwise, it's album level metadata
    root+=("$line")
  done < <(printf "%s\n" "$cue")
  IFS="$OFS"

  # Close any pending stuff
  if [ "${#track[@]}" -gt 0 ]; then
    tracks+=("$(helpers::tojsonobject "${track[@]}")")
  fi
  # If we had tracks, close them
  if [ "${#tracks[@]}" -gt 0 ]; then
    file+=("\"TRACKS\": $(helpers::tojsonarray "${tracks[@]}")")
  fi
  # If we had a previous file, close it
  if [ "${#file[@]}" -gt 0 ]; then
    files+=("$(helpers::tojsonobject "${file[@]}")")
  fi

  root+=("\"FILES\": $(helpers::tojsonarray "${files[@]}")")
  root="$(helpers::tojsonobject "${root[@]}")"

  if [ "$dirty" ]; then
    dc::logger::error "HOLA!!!! The CUE file contains invalid tokens. We exited and managed to parse part of it below. You should really double check what's going on."
  fi

  if ! printf "%s" "$root" | jq . 2>/dev/null; then
    dc::logger::error "Catastrophic failure! What we produced is not valid json."
    printf "%s" "$root"
    exit "$ERROR_FAILED"
  fi
}
