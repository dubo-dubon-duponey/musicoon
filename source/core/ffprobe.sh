#!/usr/bin/env bash

ffprobe::info(){
  dc::require ffprobe

  local filename="$1"
  local noformat="$2"

  local args=(-show_error -show_data -show_streams -print_format json)

  [ "$noformat" ] || args+=(-show_format)

  ffprobe "${args[@]}" "$filename" 2>/dev/null
}
