#!/usr/bin/env bash


fpcalc::analyze(){
  dc::require fpcalc

  local file="$1"
  fpcalc -json "$file" 2>/dev/null
}
