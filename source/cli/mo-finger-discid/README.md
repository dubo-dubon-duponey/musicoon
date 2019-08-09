# mo-finger-discid

Takes a list of track offsets (or track lengths), either in mm:ss.ff (minutes, seconds, frames) format, or in frames format,
and spit out both the cddb discid and musicbrainz discid.

## TL;DR

```
# List of offsets, including leadout, in timecodes
mo-finger-discid "00:02.00 04:08.45 08:24.90"

# List of offsets, with leadout, in frames
mo-finger-discid --unit=frame "150 18645 37890"

# List of track lengths, using timecodes
mo-finger-discid --type=lengths "04:06.45 04:16.45"

# List of track lengths, in frames
mo-finger-discid --unit=frame --type=lengths "18495 19245"
```

Output:

```
{
  "cddb": "1001f702",
  "musicbrainz": "lwHl8fGzJyLXQR33ug60E8jhf4k-"
}
```

## Background


### Musicbrainz ID computation

Outlined in: https://musicbrainz.org/doc/Disc_ID_Calculation

Implemented in: https://github.com/metabrainz/libdiscid/tree/master/src

In a shell:
 
Concatenate the following strings:
  * first track number in hexadecimal form (2 bytes) (usually that's `01`)
  * last track number in hexadecimal form (2 bytes) (maximum would be `99`)
  * lead-out of the last track (in frames), in hexadecimal (8 bytes) - typically, that would be
 the last track offset + last track length
  * offset of each existing track (in frames), in hexadecimal (8 bytes)
  * beyond existing tracks, add `00000000` (`0`, hex 8 bytes), so to have a total of 99 tracks

Then sha1 the resulting string.

Then base64 encode the resulting sha - replace protected chars by their equivalent.


### cddb

Outlined in: http://ftp.freedb.org/pub/freedb/misc/freedb_howto1.07.zip

 * for each track, excluding the lead-out, take the offset expressed in seconds in decimal base, and add each number (eg: 123 seconds would become 1+2+3=6)
 * sum all of the above together, as `n`
 * compute the actual audio length of the disc: that's the lead-out offset minus the first track offset, as `t`
 * total number of tracks as `k`
 * The discid is as follow: `(n % 0xFF) << 24 | t << 8 | k )`

### Notes

 * "red book": https://en.wikipedia.org/wiki/Compact_Disc_Digital_Audio
 * "sectors" aka "timecode frames" (not to be confused with frames below), is 33 bytes of data
 * "frames" (not the same frames as above) = 1/75th of a second
 * "timecodes" are expressed in mm:ss.ff (minutes, seconds, frames)
 * musicbrainz use of a custom base64 to avoid having to urlencode the parameter is mind-boggling, mister Mayhem and Chaos :-)

