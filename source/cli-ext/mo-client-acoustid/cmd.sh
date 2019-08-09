#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="1.0.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="query the AcoustId web-service"

dc::commander::initialize
dc::commander::declare::flag refresh "^$" "Will force a roundtrip to the server, to refresh a possibly cached entry" optional
dc::commander::declare::flag meta ".*" "What to include in the return value (space separated list of: recordings, recordingids, releases, releaseids, releasegroups, releasegroupids, tracks, compress, usermeta, sources)" optional
dc::commander::declare::flag duration "^[0-9.]+$" "Duration, if in fingerprint mode" optional
dc::commander::declare::arg 1 ".+" "data" "either the fingerprint of a track (must come along with a --duration=XXX flag), or a trackid"
dc::commander::boot

# Init the database
dc-ext::sqlite::init "$HOME/tmp/dc-client-acoustid/cache.db"
dc-ext::http-cache::init

# Basic config
readonly APPKEY="NJWSshfioI"
readonly SERVICE="https://api.acoustid.org/v2/lookup"
readonly UA="User-Agent: DuboAcoustIdBashCLI/$CLI_VERSION"

[ ! "$DC_ARGE_REFRESH" ] || export DC_HTTP_CACHE_FORCE_REFRESH=true

acoustid::lookup::fingerprint(){
  local duration="$1"
  local fingerprint="$2"
  local meta="$3"
  [ ! "$meta" ] || meta=" $meta"
  meta="$(printf "%s" "$meta" | sed -E "s/ /%20/g")"
  dc-ext::http-cache::request "$SERVICE?format=json&client=$APPKEY&duration=$duration&fingerprint=$fingerprint&meta=compress$meta" "GET" "" "$UA"
}

acoustid::lookup::trackid(){
  local trackid="$1"
  local meta="$2"
  [ ! "$meta" ] || meta=" $meta"
  meta="$(printf "%s" "$meta" | sed -E "s/ /%20/g")"
  dc-ext::http-cache::request "$SERVICE?format=json&client=$APPKEY&trackid=$trackid&meta=compress$meta" "GET" "" "$UA"
}

# If there is a duration, round it to the second
duration=
if [ "$DC_ARGV_DURATION" ]; then
  duration=$(printf "%.0f" "$DC_ARGV_DURATION")
fi

# Do fingerprint or id mode depending on whether there is a duration specified
if [ "$duration" ]; then
  acoustid::lookup::fingerprint "$duration" "$DC_PARGV_1" "$DC_ARGV_META"
else
  acoustid::lookup::trackid "$DC_PARGV_1" "$DC_ARGV_META"
fi

# Spit it out
printf "%s" "$DC_HTTP_BODY" | dc::portable::base64d | jq .
# \ | dc::portable::base64d | jq .
