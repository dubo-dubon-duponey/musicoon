#!/usr/bin/env bash

dc_time_start=0

timer::start(){
  dc_time_start=$(gdate +%s%N)
}

timer::reset(){
  dc_time_start=0
}

timer::wait(){
  result=$((($(gdate +%s%N) - $dc_time_start)/1000000))
  if [ "$result" -le 400 ]; then
	dc::logger::debug "Sleeping for $(bc <<< 'scale=2; (400 - '$result')/1000')"
	sleep $(bc <<< 'scale=2; (400 - '$result')/1000')
  fi
}
