#!/usr/bin/env bash

db::nuke(){
  rm "$HOME/tmp/musicoon/musicoon.db"
}

db::init(){
  dc-ext::sqlite::init "$HOME/tmp/musicoon/musicoon.db"
}

# Initialize the database table
audiofile::db::init(){
  # Initialize sqlite
  dc-ext::sqlite::ensure audiofiles "parent TEXT, filename TEXT, size TEXT, digest TEXT, data JSON, fingerprint TEXT, duration TEXT, meta JSON, PRIMARY KEY(digest, filename)"
}

# Lookup a unique file, either from the db, or fingering it then storing the result
# Non audio files will fail in unexpected ways
# XXX all of this fucking shebang is very unsafe - need better escaping methods for sqlite data insertion
audiofile::db::lookup(){
  local filename="$1"
  local digest
  local directory
  local lookup

  dc::logger::info "Fingerprinting file $filename"

  digest=$(dc::crypto::shasum::compute "$filename")
  # XXX deserialization is still a problem - json entities are escaped as string
  lookup="$(dc-ext::sqlite::select audiofiles "json_object(\
    'fingerprint', json_object('fingerprint', fingerprint, 'duration', duration), \
    'filesystem', json_object('parent', parent, 'filename', filename, 'digest', digest, 'size', size), \
    'data', json(data), \
    'meta', json(meta))" "filename=\"$filename\" AND digest=\"$digest\"")"

  if [ ! "$lookup" ]; then
    dc::logger::debug "Unknown file, finger locally and save"

    directory="$(dirname "$filename")"

    if ! lookup="$(audiofile::readinfo "$filename" "$digest")"; then
      dc::logger::warning "Failed to get info from the file, ignoring"
      return
    fi

    dc-ext::sqlite::insert audiofiles "parent, filename, digest, size, data, fingerprint, duration, meta" \
      "\"$directory\", \"$filename\", \"$digest\", \"$(printf "%s" "$lookup" | jq -rc '.filesystem.size')\", \
      \"$(printf "%s" "$lookup" | jq -rc '.data' | sed -E "s/\"/\"\"/g")\", \
      \"$(printf "%s" "$lookup" | jq -rc '.fingerprint.fingerprint')\", \
      \"$(printf "%s" "$lookup" | jq -rc '.fingerprint.duration')\",  \
      \"$(printf "%s" "$lookup" | jq -rc '.meta' | sed -E "s/\"/\"\"/g")\""
  fi

  dc::logger::debug "Done"
  printf "%s" "$lookup"
}

# Retrieve all stored results from the database
audiofile::db::dump::everything(){
  dc-ext::sqlite::select audiofiles "json_object(\
    'fingerprint', json_object('fingerprint', fingerprint, 'duration', duration), \
    'filesystem', json_object('parent', parent, 'filename', filename, 'digest', digest, 'size', size), \
    'data', json(data), \
    'meta', json(meta))" "TRUE"
}

audiofile::db::dump::acoustid(){
  dc-ext::sqlite::select audiofiles "json_object('fingerprint', fingerprint, 'duration', duration)" "TRUE"
}

# Prune the database for stale entries
audiofile::db::prune(){
  local all
  local filename
  local digest

  all="$(dc-ext::sqlite::select audiofiles "json_object('filename', filename, 'digest', digest)" "TRUE")"

  # For all file, digest entries, check:
  while read -r entry; do
    filename=$(printf "%s" "$entry" | jq -rc .filename)
    digest=$(printf "%s" "$entry" | jq -rc .digest)
    # if the file is still there
    if [ -f "$filename" ]; then
      # if the digest matches
      if dc::crypto::shasum::verify "$filename" "$digest"; then
        continue
      fi
    fi
    # if not, delete
    dc::logger::debug "Deleting stale entry $filename $digest"
    dc-ext::sqlite::delete audiofiles "filename=\"$filename\" AND digest=\"$digest\""
  done < <(printf "%s\n" "$all")
}
