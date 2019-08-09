#!/usr/bin/env bash

testDiscID(){

  # List of offsets, including leadout, in timecodes
  result="$(mo-finger-discid --unit=timecode "00:02.00 04:08.45 08:24.90" | jq -rc .)"
  dc-tools::assert::equal "$result" '{"musicbrainz":"lwHl8fGzJyLXQR33ug60E8jhf4k-","cddb":"1001F702","toc":"1 2 37890 150 18645"}'

  # List of offsets, with leadout, in frames
  result="$(mo-finger-discid --unit=frame "150 18645 37890" | jq -rc .)"
  dc-tools::assert::equal "$result" '{"musicbrainz":"lwHl8fGzJyLXQR33ug60E8jhf4k-","cddb":"1001F702","toc":"1 2 37890 150 18645"}'

  # List of track lengths, using timecodes
  result="$(mo-finger-discid --unit=timecode --type=lengths "04:06.45 04:16.45" | jq -rc .)"
  dc-tools::assert::equal "$result" '{"musicbrainz":"lwHl8fGzJyLXQR33ug60E8jhf4k-","cddb":"1001F702","toc":"1 2 37890 150 18645"}'

  # List of track lengths, in frames
  result="$(mo-finger-discid --unit=frame --type=lengths "18495 19245" | jq -rc .)"
  dc-tools::assert::equal "$result" '{"musicbrainz":"lwHl8fGzJyLXQR33ug60E8jhf4k-","cddb":"1001F702","toc":"1 2 37890 150 18645"}'
}

# Test cases: marylin manson 99 tracks cd
# pregap and index 00 cue files
# RATM for multi files, multi tracks

