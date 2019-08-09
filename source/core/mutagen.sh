#!/usr/bin/env bash

# Any modification to the python script requires bumping the cli version!
mutagen::write(){
  dc::require mutagen-inspect

  local file="$1"
  local _here
  _here=$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)
  local tagger="$_here/mo-tagger-write-$CLI_VERSION.py"

#  if [ ! -f "$tagger" ]; then
    cat <<-EOF > "$tagger"
#/usr/bin/env python
# -*- coding: utf8 -*-
##########################################################################
# Mutagen based simple tagger
# Released under MIT
# Copyright (c) $(date +"%Y") Dubo Dubon Duponey
##########################################################################

import mutagen
import sys
import re

audio = mutagen.File(sys.argv[1])

newtags=[]
for line in sys.stdin:
    split = re.findall("(\w+)=(.*)", line)
    key = split[0][0]
    value = split[0][1]
    newtags.append((key, value))
    if key in audio:
        del audio[key]

# XXX reset everything
for key in audio:
    del audio[key]

for tag in newtags:
    audio.tags.append(tag)

print(audio.pprint())

# audio.save()

EOF
#  fi

  python "$tagger" "$file"
}

mutagen::read(){
  dc::require mutagen-inspect

  local file="$1"
  local _here
  _here=$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)
  local tagger="$_here/mo-tagger-read-$CLI_VERSION.py"

#  if [ ! -f "$tagger" ]; then
    cat <<-EOF > "$tagger"
#/usr/bin/env python
# -*- coding: utf8 -*-
##########################################################################
# Mutagen based simple tagger
# Released under MIT
# Copyright (c) $(date +"%Y") Dubo Dubon Duponey
##########################################################################

import mutagen
import sys

audio = mutagen.File(sys.argv[1])
print(audio.pprint())

EOF
  #fi

  python "$tagger" "$file"

}

mutagen::read::tojson(){
  local file="$1"
  local nocap="$2"
  local tag
  local key
  local value
  local tags=()

  while read -r tag; do
    # Avoid the first line
    if ! printf "%s" "$tag" | grep -q "="; then
      continue
    fi
    # Strip out undue carriage returns mainly
    tag="$(dc::string::trimSpace tag)"
    # Split out on first =
    key="$(printf "%s" "${tag%%=*}" | sed -E "s/\"/\\\\\"/g")"
    [ ! "$nocap" ] || key="$(printf "%s" "$key" | tr '[:lower:]' '[:upper:]')"

    # XXX mp4 tags contains hex encoded chars (\x00) that jq chokes on
    # AND I HATE YOU FUCKING HATE YOU SED BASH AND THE REST JUST FUCKING DROP DEAD :)
    # Also, carriage returns may appear anywhere in the tags
    # And HT...
    # XXX should rather be \n - maybe...
    value="$(printf "%s" "${tag#*=}" | sed -E "s/\"/\\\\\"/g" | sed -E "s/\\\\x/\\\\\\\\x/g" | sed $'s/\r/ /g' | sed $'s/\t/ - /g')"

    tags+=("$(printf '{
      "%s": "%s"
    }' "$key" "$value")")
  done < <(mutagen::read "$path")

  helpers::tojsonarray "${tags[@]}"
}

mutagen::write::fromjson(){
# XXXX
  dc::logger::error "Not implemented"
  exit 1
#  helpers::tojsonarray "${tags[@]}"
}
