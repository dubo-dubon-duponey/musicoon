#!/usr/bin/env bash

#INSTRUMENTS_MB=()
#while read -r role; do
#  INSTRUMENTS_MB+=("$role")
#done <"$_here/instruments-mb-sort.txt"

# swap out words and put in parentheses: bass trumpet -> trumpet (bass)
# match from the start and ignore end

# echo "import mutagen\nmutagen.File("11. The Way It Is.ogg")\n_.info.pprint()" | python


# tracks=()

while read file; do
	extension="${file##*.}"

	echo " > Working on file: $file"

	# Get only flac, alac and mp3 files
	if [ "$extension" != "flac" ] && [ "$extension" != "mp3" ] && [ "$extension" != "m4a" ]; then
		echo "Not an audio file. Moving along"
		continue
	fi

  # Extract the album and track id from the tags
	filedata="$(mutagen-inspect "$file")"
	id="$(printf "%s" "$filedata" | grep -i MUSICBRAINZ_ALBUMID)"
	id="${id#*=}"
	trackid="$(printf "%s" "$filedata" | grep -i MUSICBRAINZ_RELEASETRACKID)"
	trackid="${trackid#*=}"

	if [ ! "$id" ] || [ ! "$trackid" ]; then
	  echo "The file has not album or trackid. Ignoring it!"
	  continue
	fi

	echo " > Album: $id"
	echo " > Track: $trackid"

  # If we do not know about this album already, query the web service
	var=cache_$(printf "%s" "$id" | tr '-' '_')
	if [ ! "${!var}" ]; then
		echo "Querying web service for album $id"
		declare $var="$(webservice::query "$id")"
	fi

	# Ok, we got webservice data in ${!var}
	# XXX update all relevant tags with web-service response

	# I - possibly update the version tag
	desiredVersion="$(serialize::version "${!var}")"
	currentVersion="$(printf "%s" "$filedata" | grep -i VERSION)"
	if [ "$desiredVersion" != "$currentVersion" ]; then
	  echo "VERSION=$desiredVersion"
	  # XXX update tag
	fi

	trackdata="$(printf "%s" "${!var}" | jq -c --arg trackid "$trackid" '.media[].tracks[] | select(.id==$trackid)')"

  # II - Move all performers tags to personnel tags

  # III - Add recorded at relationships
	# Go fetch the track specific info out of the json blob
	while read -r relation; do
    type="$(printf "%s" "$relation" | jq -rc '.type')"
    targettype="$(printf "%s" "$relation" | jq -rc '.["target-type"]')"
    if [ "$type" == "instrument" ]; then
      artist="$(printf "%s" "$relation" | jq -rc .artist.name)"
      attributes="$(printf "%s" "$relation" | jq -rc .attributes[])"
      while read -r role; do
        if ! normalized="$(instrument::exist "$role")"; then
          echo "WARNING: instrument $role is not a recognized Roon role"
          continue
        fi
        echo " > PERSONNEL=$artist - $normalized"
      done < <(printf "%s" "$relation" | jq -rc .attributes[])
    elif [ "$type" == "performance" ]; then
      artist="$(printf "%s" "$relation" | jq -rc .artist.name)"
      attributes="$(printf "%s" "$relation" | jq -rc .attributes[])"
      if [ "$targettype" == "recording" ]; then
        echo "ignoring target recording"
      elif [ "$targettype" == "work" ]; then
        echo "ignoring target work"
      else
        echo " > UNKNOWN=$artist"
        echo "$attributes"
        echo "$targettype"
      fi
    else
      artist="$(printf "%s" "$relation" | jq -rc .artist.name)"
      attributes="$(printf "%s" "$relation" | jq -rc .attributes[])"
      [ "$attributes" ] || attributes="$type"
      while read -r role; do
        if ! normalized="$(role::exist "$role")"; then
          echo "WARNING: role $role is not a recognized Roon role"
          continue
        fi
        echo " > PERSONNEL=$artist - $normalized"
      done < <(echo "$attributes")
    fi
	done < <(printf "%s" "$trackdata" | jq -rc '.recording.relations[]')

  # Now, extract the "recorded at" info, if there is one
	recat="$(printf "$trackdata" | jq -c '.recording.relations[] | select(.place != null) | select(.type == "recorded at")')"
	if [ ! "$recat" ]; then
	  echo "This track does not have a 'recorded at' advanced relationship. Ignoring."
	  continue
	fi

  # Get the location, begin and end dates
  location="$(printf "%s" "$recat" | jq -rc '(.place.name + " (" + .place.address + ")")')"
  begin="$(printf "%s" "$recat" | jq -rc '.begin')"
  end="$(printf "%s" "$recat" | jq -rc '.end')"
  if [ "$begin" ]; then
    if [ "$begin" == "$end" ]; then
      echo "RECORDINGDATE=$begin"
    else
      echo "RECORDINGSTARTDATE=$begin"
      echo "RECORDINGENDDATE=$end"
    fi
  fi
  echo "RECORDINGLOCATION=$location"

done < <(find "$folder" -type f)





#	printf "$trackdata" | jq -c '.recording.relations[] | select(.place != null) | (.place.name + " (" + .place.address + ")")'
# recorded at begin end
#	if  | (.name + " (" + .address + ")")'

# A. add VERSION from label + cat + release date etc
# B. add recorded at date + location
# C. convert aall instrument performance to PERSONNEL
# XXX careful with the inverted date format



#printf "%s" "$data" | jq -c '.media[].tracks[]'

#./musicbrainz-to-roon.sh | jq -c '.media[].tracks[]'
#dmp@macArella:~/Music$ ./musicbrainz-to-roon.sh | jq '.media[].tracks[].recording.relations[].place.name'

# .media[].tracks[].recording.relations[].place
# place
# end
# begin


