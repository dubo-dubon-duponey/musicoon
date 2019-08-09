# CUE file parsing on the command line

> circa 2019

## What, why

CUE files are a "catalog" describing the layout of CDs (or DVDs).
Typically, they inform where track start and stop, pregap silences, and overall organization of data inside a medium.

In the wild, they are mostly found serving two purposes:
 * act as a playlist (mainly motivated by use for players which cannot render sample accurate gapless playback between tracks)
 * catalog for single-file CD rips
 * accuraterip

While there are many serious GUI softwares supporting (extended) CUE files (EAC, XLD), command line support is more fragmented.

The go-to command line utility is `cuebreakpoint` (from the `cuetools` C package), referenced in many SO threads,
albeit it suffers from many shortcomings, namely:
 * susceptibility to cue file encoding
 * inability to deal with extended syntax (EAC for example is known to use INDEX 00 at the end of a track to describe the subsequent track pregap)
 * useless with multi-files CUE

This page attempts at listing resources useful to understanding CUE files, and a comparison of projects that provide CUE files command line parsing.

Note that our focus is SOLELY on CUE files use for audio files, and that we use macOS.

## Reading list

 * [Wackypedia](https://en.wikipedia.org/wiki/Cue_sheet_(computing\))
 * [Hydrogen Audio](http://wiki.hydrogenaud.io/index.php?title=Cue_sheet)
 * [Pseudo-spec](https://web.archive.org/web/20160201021136/http://digitalx.org/cue-sheet/syntax/)

## Existing solutions

Here is the list of github projects popping up for "cuefile" or "cuetools" keywords:

Note that "does build: no" means we were not able to build the project with 
minimal effort.

| name | language | overall note | does build | does work | is useful | dependencies | notes | url |
| --- |  --- |  --- |  --- | --- | --- | --- | --- | --- |
| CUEFileParser | javascript | 1/5 | yes | ~ | no | node, npm | regular expressions will not match filenames, track parsing is broken | https://github.com/teken/CUEFileParser |
| splitter |  ruby |  1/5 | yes | ? | no | ruby | doesn't seem to work with flac files | https://github.com/jutonz/splitter |
| abgt-splitter | ruby | 1/5 | yes | ? | no | ruby | is tied with "AGBT" podcast and not a generic tool | https://github.com/bensymonds/abgt-splitter |
| CueFileCutter | .net | 0/5 | no | ? | ? | mono | missing dependencies?| https://github.com/SethSenpai/CueFileCutter |
| DiscTools | .net |  0/5 | no | ? | ? | mono | missing dependencies? | https://github.com/Asnivor/DiscTools |
| cuetools.net | .net | 0/5 | no | ? | ? | mono | missing dependencies? | https://github.com/gchudov/cuetools.net |
| Audio-Cuefile-ParserPlus | perl | ? | yes | ? | ? | perl | looks promising, but couldn't make it work | https://github.com/trinitronx/Audio-Cuefile-ParserPlus |
| Audio-Cuefile-Parser | perl | 0/5 | no | ? | ? | perl | doesn't build | https://github.com/gitpan/Audio-Cuefile-Parser |
| deflacue | python | 3+?/5 | yes | yes | yes | python sox | EVALUATE | https://github.com/idlesign/deflacue |
| cuetools | C | 3/5 | yes | yes | yes | autoconf automake libtool | | https://github.com/svend/cuetools |
| cuetools | java | 1/5 | yes | no? | no | gradle java | | https://github.com/ppvolok/cuetools |

"Note" rationale:
  * 0: doesn't build
  * 1: build, not functioning
  * 2: build, somewhat functions
  * 3: build, works for basic CUE syntax
  * 4: build, works for basic and extended CUE syntax
  * 5: build, works fully, supports metadata and is "smart"

## Bench

Our test include 116 cue files of various origins, some of them invalid.

"Level 0" means the tool is able to parse the file.

"Level 1" means the tool properly report the TOC

The following solutions have been ran through the tests:

 * C cuetools
 * python deflacue
 * musicoon

## Interesting cuefiles

 * contains a log file concatenated with it: /Volumes/MacOuille/Music/Seeds/rutorrents//Dub War - Pain/Dub War - pain.cue
 * contains non quoted filenames: /Volumes/MacOuille/Music/Seeds/rutorrents//Dubwar/Dub_War-Wrong_Side_Of_Beautiful.cue
 * contains paths that need slash conversion and diranem removal: /Volumes/MacOuille/Music/Seeds/rutorrents//Galliano #/Galliano - The Plot Thickens (1994)/Galliano - The Plot Thickens.cue
 * with complicated pregaps: /Volumes/MacOuille/Music/Seeds/rutorrents//Electronic Eye - 1995 - The Idea of Justice [FLAC]/Electronic Eye - The Idea of Justice.flac.cue
