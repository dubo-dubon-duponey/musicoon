#!/usr/bin/env bash

ws::acoustid::lookup(){
  local fingerprint="$1"
  local duration="$2"
  local lookup
  local refresh="$DC_ARGE_REFRESH"
  [ ! "$refresh" ] || refresh="--refresh"

  # Wait if the previous query ended in the window
  # XXX this will wait regardless of the fact some are straight from db
  # Ideally, finish up the multi-thread+throttler http queue and pass along a list of fingerprints instead
  timer::wait
  timer::start

  if ! lookup=$(mo-client-acoustid --meta="releases tracks" $refresh --duration="$duration" "$fingerprint"); then
    dc::logger::error "failed querying acoustid service - abort!"
    exit "$ERROR_FAILED"
  fi

  printf "%s\n" "$lookup"

  #if [ "$DC_HTTP_CACHE" == "hit" ]; then
  #  timer::reset
  #fi

  # printf "%s" "$lookup"
  # | dc::portable::base64d
  # recordings, recordingids, releases, releaseids, releasegroups, releasegroupids, tracks, compress, usermeta, sources
}
