#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="tag audio files in a way that works well with Roon, using the Musicbrainz webservice"

# Initialize
dc::commander::initialize
dc::commander::declare::flag refresh "^$" "force acoustic and musicbrainz queries to refresh from the server" optional
dc::commander::declare::arg 1 "^(nuke|prune|scan|acoustquery|cue|process)$" "command" "command to run"
dc::commander::declare::arg 2 ".+" "path" "music folder (for the scan command)" optional
# Start commander
dc::commander::boot
# Requirements
dc::require mutagen-inspect
dc::require shasum
dc::require uchardet

db::init

# Ensure the tables are there
audiofile::db::init

dc::fs::isdir "$DC_PARGV_2"
folder="$(realpath "$DC_PARGV_2")"

case "$DC_PARGV_1" in
  nuke)
    db::nuke
    dc::logger::info "Database has been nuked"
    exit
  ;;
  prune)
    finger::prune
    dc::logger::info "Stale entries have been pruned from the database"
    exit
  ;;
  scan)
    # Ensure what we have been given is an existing folder
    dc::fs::isdir "$DC_PARGV_2"
    folder="$(realpath "$DC_PARGV_2")"
    while read -r filename; do
      audiofile::db::lookup "$filename" > /dev/null
    done < <(find "$folder" -type f -iname "*.flac")
  ;;
  acoustquery)
    while read -r entry; do
      ws::acoustid::lookup "$(printf "%s" "$entry" | jq -rc .fingerprint)" "$(printf "%s" "$entry" | jq -rc .duration)"
    done < <(audiofile::db::dump::acoustid)
  ;;
  process)
    musicoon::processor::dir "$folder"
  ;;
  cue)
    readonly UA="User-Agent: DuboAcoustIdBashCLI/$CLI_VERSION"
    # readonly queryparams="release-groups+media+discids+recordings+artist-credits+artists+labels+isrcs+artist-rels+release-rels+url-rels+recording-rels+place-rels+work-rels+recording-level-rels+work-level-rels"

    while read -r fold; do
      times=()
      while read -r filename; do
          # XXX borked
          tn="$(audiofile::db::lookup "$filename" | jq -rc '.meta[] | select(.Tracknumber != null) | .Tracknumber')"

          tn="$(basename "$filename")"
          tn="${tn:0:2}"

          if [ "${tn:0:1}" == 0 ]; then
            tn=${tn:1}
          fi

          times[tn]="$(audiofile::db::lookup "$filename" | jq -rc .data.frames)"
      done < <(find "$fold" -type f -maxdepth 1 -iname "*.flac")

      if [ "${#times[@]}" -gt 0 ]; then
        # echo "passing ${times[@]}"
#        d="$(mo-finger-discid --type=lengths --unit=fraction "$(printf "%s " "${times[@]}")")"
        d="$(mo-finger-discid --type=lengths --unit=frame "$(printf "%s " "${times[@]}")")"
        printf "%s" "$d" | jq .
        did="$(printf "%s" "$d" | jq -rc .musicbrainz)"
        toc="$(printf "%s" "$d" | jq -rc .toc | tr ' ' '+')"
# inc=$queryparams&
        dc::http::request "https://musicbrainz.org/ws/2/discid/$did?toc=$toc" "GET" "" "$UA" \
            "Host: musicbrainz.org:443" "Cache-Control: no-cache" "Pragma: no-cache" "Accept: application/json" "Accept-Language: en-US,*"

        jq '.releases[].title' "$DC_HTTP_BODY"
      fi
    done < <(find "$folder" -type d)
  ;;
esac
