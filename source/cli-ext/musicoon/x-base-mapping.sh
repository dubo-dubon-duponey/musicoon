#!/usr/bin/env bash

# readonly _here=$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)
_here=/Users/dmp/Projects/Source/current-vcs/dubo-dubon-duponey/sh-art/roonifier

INSTRUMENTS_ROON=()
while read -r role; do
  INSTRUMENTS_ROON+=("$role")
done <"$_here/instruments-roon-sort.txt"

ROLES_ROON=()
while read -r role; do
  ROLES_ROON+=("$role")
done <"$_here/composer-roon-sort.txt"
while read -r role; do
  ROLES_ROON+=("$role")
done <"$_here/conductor-roon-sort.txt"
while read -r role; do
  ROLES_ROON+=("$role")
done <"$_here/ensemble-roon-sort.txt"
while read -r role; do
  ROLES_ROON+=("$role")
done <"$_here/main-performer-roon-sort.txt"
while read -r role; do
  ROLES_ROON+=("$role")
done <"$_here/production-roon-sort.txt"

# Resolve musicbrainz -> roon inconsistent instrument lists
instrument::unalias(){
  local instrument
  instrument="$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')"
  case "$instrument" in
    "17-string bass koto")  instrument="17-string koto";;
    "accordina")            instrument="melodica";;
    "afoxé")                instrument="afoxe";;
    "afuche/cabasa")        instrument="afuche / cabasa";;
    "alto viol")            instrument="alto viola";;
    "analog synthesizer")   instrument="analogue synthesizer";;
    "arghul")               instrument="arghoul";;
    "arrabel")              instrument="rabel";;
    "ashiko")               instrument="ashiko drum";;
    "drums (drum set)")     instrument="drum set";;
  esac
  printf "%s" "$instrument"
}

instrument::exist(){
  local role
  local candidate
  # local canlength=${#candidate}
  candidate="$(printf "%s" "$1" | tr "[:upper:]" "[:lower:]")"
  for role in "${INSTRUMENTS_ROON[@]}"; do
    if [ "$candidate" == "$role" ]; then
      printf "%s" "$role"
      return
    fi
  done
  exit 1
}

role::exist(){
  local role
  local candidate
  # local canlength=${#candidate}
  candidate="$(printf "%s" "$1" | tr "[:upper:]" "[:lower:]")"
  for role in "${ROLES_ROON[@]}"; do
    if [ "$candidate" == "$role" ]; then
      printf "%s" "$role"
      return
    fi
  done
  exit 1
}
