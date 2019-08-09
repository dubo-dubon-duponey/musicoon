#!/usr/bin/env bash

MUSICOON_RN_INSTRUMENTS=()
MUSICOON_MB_INSTRUMENTS=()

reldb::build::roon(){
  local roon="https://kb.roonlabs.com/Credit_Roles"
  local family
  local value

  # Roon stuff
  dc::http::request "$roon" "GET"
  roon="$(cat "$DC_HTTP_BODY")"
  roon="${roon##*--------}"
  while read -r line; do
    family="${line%\|*}"
    value="${line#*\|}"
    case "$family" in
      "production")
      ;;
      "performer")
        MUSICOON_RN_INSTRUMENTS+=("$value")
        #if [ "${value:$(( ${#value} - 1 ))}" == ")" ]; then
        #  main="${value%%\(*}"
        #  ext="${value#*\(}"
        #  ext="${ext%\)*}"
        #  value="$ext $main"
        #fi
        MUSICOON_RN_INSTRUMENTS_NORMALIZED+=("$(helpers::normalize "$value")")
      ;;
      "ensemble")
      ;;
      "conductor")
      ;;
      "composer")
      ;;
      "main performer")
      ;;
    esac
  done < <(helpers::html::unescape "${roon%%</div>*}" | tr '[:upper:]' '[:lower:]')
}

helpers::html::unescape(){
  local data="$1"
  printf "%s" "$data" | \
    sed -E "s/&#(x27|39);/'/g";
}

helpers::normalize(){
  iconv -f utf8 -t ascii//TRANSLIT
  local data="$1"
  printf "%s" "$data" | \
    sed -E "s/(ă|ầ|ậ|ä|à|ā|á|â|å|ắ|ã)/a/g" | \
    sed -E "s/(č|ç)/c/g" | \
    sed -E "s/(đ)/d/g" | \
    sed -E "s/(è|é|ê|ề|ē|ė|ệ)/e/g" | \
    sed -E "s/(ģ)/g/g" | \
    sed -E "s/(ī|í|ı|ị)/i/g" | \
    sed -E "s/(ô|ő|ō|ố|ɔ|ó|ö|ò|õ)/o/g" | \
    sed -E "s/(š|ş)/s/g" | \
    sed -E "s/(ú|û|ü|ū|ụ|ứ|ư)/u/g" | \
    sed -E "s/(ỳ)/y/g" | \
    sed -E "s/(ż)/z/g";
}

reldb::build::mb(){
  local mbinst="https://musicbrainz.org/instruments"
  local mbattrs="https://musicbrainz.org/relationship-attributes"
  local mbrelsmap="https://musicbrainz.org/relationships"

  # MB instruments
  dc::http::request "$mbinst" "GET"
  mbinst="$(cat "$DC_HTTP_BODY" | sed -E 's/<a[^>]+><bdi>([^<]+)<\/bdi><\/a>/\
|\1\
/g')"

  while read -r line; do
    if [ "${line:0:1}" == "|" ]; then
      MUSICOON_MB_INSTRUMENTS_NORMALIZED+=("$(helpers::normalize "${line:1}")")
      MUSICOON_MB_INSTRUMENTS+=("${line:1}")
    fi
  done < <(helpers::html::unescape "$mbinst" | tr '[:upper:]' '[:lower:]')
}
