#!/usr/bin/env bash

discid::musicbrainz(){
  local firstTrackNumber="$1"
  local lastTrackNumber="$2"
  shift
  shift

  # Swap out the last offset
  local offsets=("$@")
  local finalOffset="${offsets[$(( ${#offsets[@]} - 1 ))]}"
  unset offsets[$(( ${#offsets[@]} - 1 ))]
  local i

  dc::crypto::shasum::compute - 1 raw < <(
    printf "%02X" "$firstTrackNumber"
    printf "%02X" "$lastTrackNumber"
    printf "%08X" "$finalOffset"
    for (( i=0; i<99; i++)); do
      printf "%08X" "${offsets[$i]:-0}"
    done
  ) | helpers::fromhex "$(cat /dev/stdin)" | base64 | sed -E "s/\+/./g" | sed -E "s/\//_/g" | sed -E "s/=/-/g"
}

_mo_internal::cddbhash(){
  local n="$1"
	local ret=0;

	while [ "$n" -gt 0 ]; do
		ret=$(( ret + n % 10 ))
		n=$(( n / 10 ));
	done
	printf "%s" "$ret"
}

discid::cddb(){
  local tok=("$@")
  local n=0
  local i
  local t

  for (( i=0; i<$((${#tok[@]}-1)); i++ )); do
    tok[i]=$(( ${tok[$i]} / 75 ))
    n=$(( n + $(_mo_internal::cddbhash "${tok[$i]}") ))
  done

  t=$(( ${tok[$i]} / 75 - ${tok[0]} ))

  printf "obase=16; %s\n" "$(( (n % 0xFF) << 24 | t << 8 | (${#tok[@]} - 1) ))" | bc
}
