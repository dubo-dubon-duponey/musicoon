#!/usr/bin/env bash

. lib/libmusicoon-strip

testLineValue(){
  local result="$(cue::helpers::linevalue "FOO BAR BAZ \"SOMETHING\" BAD")"
  dc-tools::assert::equal "SOMETHING" "$result"
  local result="$(cue::helpers::linevalue "FOO SOMETHING")"
  dc-tools::assert::equal "SOMETHING" "$result"
  local result="$(cue::helpers::linevalue 'FOO BAR BAZ "SOMETHING\" NASTY" BAD')"
  dc-tools::assert::equal 'SOMETHING\" NASTY' "$result"
}

testToJSON(){
  local result="$(cue::helpers::linetojson "REM BAR BAZ \"SOMETHING\" BAD")"
  dc-tools::assert::equal "\"BAR BAZ\": \"SOMETHING\"" "$result"
  local result="$(cue::helpers::linetojson "PERF SOMETHING")"
  dc-tools::assert::equal "\"PERF\": \"SOMETHING\"" "$result"
  local result="$(cue::helpers::linetojson 'TRAC BAR BAZ "SOMETHING\" NASTY" BAD')"
  dc-tools::assert::equal "\"TRAC BAR BAZ\": \"SOMETHING\\\" NASTY\"" "$result"
}
