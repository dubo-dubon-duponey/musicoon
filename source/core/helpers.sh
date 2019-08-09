#!/usr/bin/env bash

# Convert a single mm:ss.ff entry to a number of frames
helpers::mmssffToFrames(){
  local min="$1"
  local sec=${min#*:}
  local frame=${sec#*.}
  sec=${sec%.*}
  min=${min%:*}
  if [ "${min:0:1}" == "0" ]; then
    min=${min:1:1}
  fi
  if [ "${sec:0:1}" == "0" ]; then
    sec=${sec:1:1}
  fi
  if [ "${frame:0:1}" == "0" ]; then
    frame=${frame:1:1}
  fi
  if ! printf "%s" "$1" | grep -q ":"; then
    min="0"
  fi
  printf "%s" "$(( $min * 60 * 75 + $sec * 75 + $frame ))"
}

helpers::fractionToFrames(){
  local sec="$1"
  local fraction=${sec#*.}
  sec=${sec%.*}
  if [ "${sec:0:1}" == "0" ]; then
    sec=${sec:1:1}
  fi
  if [ "${fraction:0:1}" == "0" ]; then
    fraction=${fraction:1:1}
  fi
  printf "%s" "$(( $sec * 75 + $fraction * 75 / 100 ))"
}

# Convert a list of mm:ss.ff to a list of frames
helpers::mmssffListToFramesList(){
  local tok=("$@")
  local ret=()
  for (( i=0; i<$((${#tok[@]})); i++ )); do
    ret+=("$(helpers::mmssffToFrames "${tok[$i]}")")
  done
  printf "%s " "${ret[@]}"
}

helpers::fractionListToFramesList(){
  local tok=("$@")
  local ret=()
  for (( i=0; i<$((${#tok[@]})); i++ )); do
    ret+=("$(helpers::fractionToFrames "${tok[$i]}")")
  done
  printf "%s " "${ret[@]}"
}

# Convert a list of lenghts to a TOC
helpers::frameLengthsToFrameTOC(){
  local tok=("$@")
  local ret=(0)
  local previous=0
  for (( i=0; i<$((${#tok[@]})); i++ )); do
    previous=$(( ${tok[$i]} + previous ))
    ret+=( "$previous" )
  done
  printf "%s " "${ret[@]}"
}

# Add two seconds to a list of offsets in frame format
helpers::addTwoSeconds(){
  local tok=("$@")
  local ret=()
  for (( i=0; i<$((${#tok[@]})); i++ )); do
    ret+=($(( ${tok[$i]} + 150 )))
  done
  printf "%s " "${ret[@]}"
}

# Take a succession of codepoints and print the corresponding chars
# Replacement for:
# perl -pe 's/([0-9a-f]{2})/chr hex $1/gie'
helpers::fromhex(){
  local codepoints="$1"
  local i=0
  while [ ${#codepoints} -gt $i ]; do
    printf "\x$(printf "%s" "${codepoints:$i:2}")"
    i=$((i+2))
  done
}

helpers::tojsonarray(){
  local sep=""
  printf "["
  for i in "$@"; do
    printf "%s%s" "$sep" "$i"
    sep=", "
  done
  printf "]"
}

helpers::tojsonobject(){
  local sep=""
  printf "{"
  for i in "$@"; do
    printf "%s%s" "$sep" "$i"
    sep=", "
  done
  printf "}"
}

helpers::array::contains() {
  local match="$1"
  shift
  local e
  for e; do
    [ "$e" == "$match" ] && return 0;
  done
  return 1
}

helpers::dropbom(){
  local data="$1"
  local bomi
  local bom="ef
bb
bf"
  bomi="$(printf "%s" "${data:0:1}" | hexdump | awk '{for(i=2; i<=NF; ++i) print $i}')"
  if [ "$bomi" == "$bom" ]; then
    printf "%s" "${data:1}"
    return
  fi
  printf "%s" "$data"
}
