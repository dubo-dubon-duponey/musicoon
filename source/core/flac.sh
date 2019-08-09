#!/usr/bin/env bash

flac::decode(){
  dc::require flac

  local input="$1"
  local output="$2"
  local args=(-d "$input" -o "$output")
  if [ "$3" ]; then
    args+=("--delete-input-file")
  fi
  flac "${args[@]}"
}

flac::encode(){
  dc::require flac

  local input="$1"
  local output="$2"
  local delete="$3"
  local skip="$4"
  local until="$5"
  shift
  shift
  shift
  shift
  shift

  local i
  # --exhaustive-model-search is incredibly expensive
  local args=(--compression-level-8 --silent)
  for i in "$@"; do
    # args+=("--tag=\"$(printf "%s" "$i" | sed -E "s/\"/\\\\\"/")\"")
    # XXX check this works
    args+=("--tag=$i") # $(printf "%s" "$i" | sed -E "s/\"/\\\\\"/g")")
  done
  if [ "$skip" ]; then
    args+=("--skip=$skip")
  fi
  if [ "$until" ]; then
    args+=("--until=$until")
  fi
  [ ! "$delete" ] || args+=("--delete-input-file")
  args+=(-o "$output" "$input")
  echo flac "${args[@]}"
  # Force LC_ALL=C, otherwise flac will expect times to follow the locale convention (coma versus dot)
  LC_ALL=C flac "${args[@]}"

  # Diff: 70 vs. 93 (mine longer)
  # 49 vs. 62 (mine longer)
}

flac::analyze(){
  dc::require flac

#  flac -a?
  flac -wt "$input"
}
