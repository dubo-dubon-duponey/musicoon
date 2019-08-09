#!/usr/bin/env bash

# Takes a single audio file, and derive its properties:
# - acoustid
# - filesystem info
# - audio data
# - tags
audiofile::readinfo(){
  local path="$1"
  local digest="$2"
  local finger
  local probe
  local tags
  local duration
  local framerate
  local frames
  local digest

  # Get the fingerprint
  finger="$(fpcalc::analyze "$path")"
  # Get the stream infos
  probe="$(ffprobe::info "$path")"
  # Get the tags from mutagen
  tags="$(mutagen::read::tojson "$path")"

  duration="$(printf "%s" "$probe" | jq -rc '(.streams[] | select(.codec_type == "audio") | .duration_ts)' )"
  framerate="$(printf "%s" "$probe" | jq -rc '(.streams[] | select(.codec_type == "audio") | .sample_rate)' )"
  frames="$((duration / framerate * 75 + ( duration % framerate ) * 75 / framerate ))"

  [ "$digest" ] || digest=$(dc::crypto::shasum::compute "$path")

  if ! printf "%s" "$probe" | jq \
    --argjson tags "$tags" \
    --arg frames "$frames" \
    --arg digest "$digest" \
    --arg parent "$(dirname "$path")" \
    --arg file "$(basename "$path")" \
    --argjson fingerprint "$finger" \
    '{
    "fingerprint": $fingerprint,
    "filesystem": {
        "parent": $parent,
        "filename": $file,
        "size": .format.size,
        "digest": $digest
    },
    "data": {
        "frames": $frames,
        "container": .format.format_name,
        "codec": (.streams[] | select(.codec_type == "audio") | .codec_name),
        "duration_ts": (.streams[] | select(.codec_type == "audio") | .duration_ts),
        "sample_rate": (.streams[] | select(.codec_type == "audio") | .sample_rate),
        "channels": (.streams[] | select(.codec_type == "audio") | .channels),
        "bits": (.streams[] | select(.codec_type == "audio") | .sample_fmt)
    },
    "meta": $tags
}'; then
    printf "%s" "$tags" | >&2 hexdump -C
#  printf "%s" "$tags" | >&2 jq .
#  dc::logger::info "Got fingers: $finger"
    dc::logger::error "FAIL"
    exit 1
  fi
# .bits_per_raw_sample doesn't give anything for ape
}
