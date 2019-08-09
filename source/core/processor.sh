#!/usr/bin/env bash

musicoon::processor::dir(){
  local folder="$1"
  local voidParentelle="$2" # subsegment of the full path - eg: /root/a/b/c -> root is root, a has audio, b and c do not -> a/b

  local cue=()
  local flac=()
  local gif=()
  local jpg=()
  local lossless=()
  local lossy=()
  local pdf=()
  local png=()
  local playlist=()
  local text=()
  local movies=()
  local trash=()
  local weird=()

  local fileinfo
  local extension
  local short

  while read -r entry; do
    extension="$(printf "%s" "${entry##*.}" | tr '[:upper:]' '[:lower:]')"
    fileinfo="$(file -b "$entry")"
    short=${fileinfo#*contains:}
    short="${short%%,*}"
    if [ "$short" == "FLAC audio bitstream data" ]; then
      flac+=("$entry")
    elif  [ "$fileinfo" == "ISO Media, Apple iTunes ALAC/AAC-LC (.M4A) Audio" ] || \
          [ "${short% 3*}" == "Monkey's Audio compressed format version" ]; then
      lossless+=("$entry")
    elif [ "$short" == "JPEG image data" ]; then
      jpg+=("$entry")
    elif [ "$short" == "MPEG ADTS" ]; then
      lossy+=("$entry")
    elif  [ "$short" == "Matroska data" ] || \
          [ "$short" == "MPEG sequence" ] || \
          [ "$short" == "Apple QuickTime movie (fast start)" ]; then
      movies+=("$entry")
    elif [ "$short" == "PNG image data" ]; then
      png+=("$entry")
    elif [ "$short" == "GIF image data" ]; then
      gif+=("$entry")
    elif [ "$short" == "M3U playlist text" ]; then
      playlist+=("$entry")
    elif [ "$short" == "PDF document" ]; then
      pdf+=("$entry")
    elif  [ "$short" == "Apple Desktop Services Store" ]; then
      trash+=("$entry")
    elif  [ "$short" == "UTF-8 Unicode text" ] || \
          [ "$short" == "Rich Text Format data" ] || \
          [ "$short" == "SoftQuad troff Context intermediate" ] || \
          [ "$short" == "UTF-8 Unicode (with BOM) text" ] || \
          [ "$short" == "Non-ISO extended-ASCII text" ] || \
          [ "$short" == "Little-endian UTF-16 Unicode text" ] || \
          [ "$short" == "ISO-8859 text" ] || \
          [ "$short" == "ASCII text" ]; then

      if [ "$extension" == "cue" ]; then
        cue+=("$entry")
      elif [[ "nfo log txt m3u m3u8 sfv" == *"$extension"* ]]; then
        text+=("$entry")
      # Useless in and for itself
      elif  [[ "md5" == *"$extension"* ]] || \
            [ "${entry#*.}" == "no.log.provided" ]; then
        trash+=("$entry")
      else
        dc::logger::warning "Unrecognized text file $entry with type $fileinfo"
      fi
    elif  [ "$short" == "MS-DOS executable" ] || \
          [ "$short" == "Microsoft Windows Autorun file" ] || \
          [ "$short" == "PE32 executable (GUI) Intel 80386" ] || \
          [ "$short" == "PE32 executable (DLL) (GUI) Intel 80386" ]; then
      dc::logger::error "Windows executable detected. This is is likely horse shit you do no want on your system ($entry)"
    elif  [ "$short" == "RIFF (big-endian) data" ] || \
          [ "$short" == "RIFF (little-endian) data" ]; then
      dc::logger::error "Ignoring random RIFF data ($entry)"
    elif  [ "$short" == "data" ]; then
      dc::logger::error "Unqualified raw data ($entry)"
    else
      weird+=("$entry")
      dc::logger::warning "Unrecognized file $entry with type $fileinfo (short is: $short)"
    fi
  done < <(find "$folder" -type f -maxdepth 1)

  local subParentelle="$voidParentelle/$(basename "$folder")"
  local weHaveAudio=""
  local weHaveNonStubSubs=""
  local subresponse
  if [ "${#flac[@]}" -gt 0 ] || [ "${#lossless[@]}" -gt 0 ] || [ "${#lossy[@]}" -gt 0 ]; then
    weHaveAudio=true
    subParentelle=""
  fi


  # Do we have a single album in there? Or multiple albums?
  # - first, try cue files
  # - do we have multiple non-equivalent cue-files?

  # Now process subfolders
  while read -r entry; do
    subresponse=$(musicoon::processor::dir "$entry" "$subParentelle")
    if [ "$subresponse" ]; then
      if [ "$weHaveAudio" ]; then
        rem
        # Move over the sub with us
      fi
    else
      weHaveNonStubSubs=true
    fi
  done < <(find "$folder" -type d -mindepth 1 -maxdepth 1)

  # If we do not have audio, and no non-stub subs, say it
  if [ ! "$weHaveAudio" ] && [ ! "$weHaveNonStubSubs" ]; then
    return 1
  fi
}

foo(){
  #################################
  # Convert all non-flac lossless files
  #################################
  local i
  for i in "${lossless[@]}"; do
    dc::logger::debug "Converting $i to flac"
    i="$(mo-grifier-convert -s --delete "$i")"
    if [ "$?" != "0" ]; then
      dc::logger::error "Dramatic failure. Could not convert audio file $file. All bets are off."
      exit "$ERROR_FAILED"
    fi
    flac+=("$i")
  done

  checkcue "${#flac[@]}}" "$folder" "${cue[@]}"
}
