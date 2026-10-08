#!/usr/bin/env bash
# Check a finished film the way a viewer gets it: from the MP4, not from the composition.
#
#   verify_film.sh <film.mp4> <t1> <t2> ... [--expect-seconds N]
#
# Pass one time per scene (the middle of each scene works best) plus the last frame.
# Prints duration, size, fps, audio stream, loudness and true peak, then writes one PNG per time and a
# contact sheet to <film>-frames/. Read EVERY frame before calling the film done.
set -euo pipefail
IN="${1:-}"; shift || true
[ -f "$IN" ] || { echo "usage: verify_film.sh <film.mp4> <t1> <t2> ... [--expect-seconds N]" >&2; exit 1; }
EXPECT=""; TIMES=()
while [ $# -gt 0 ]; do
  case "$1" in --expect-seconds) EXPECT="$2"; shift 2 ;; *) TIMES+=("$1"); shift ;; esac
done

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
VID=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,codec_name -of csv=p=0 "$IN")
AUD=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 "$IN" || true)
echo "file:     $IN ($(du -h "$IN" | cut -f1))"
echo "duration: ${DUR}s${EXPECT:+ (asked for ${EXPECT}s)}"
echo "video:    $VID   (codec,width,height,fps)"
if [ -n "$AUD" ]; then
  echo "audio:    $AUD   (codec,rate,channels)"
  ffmpeg -hide_banner -nostats -i "$IN" -map 0:a:0 -af ebur128=peak=true -f null - 2>&1 \
    | awk '/Integrated loudness:/{f=1} f&&/I:/{i=$2} /True peak:/{p=1} p&&/Peak:/{tp=$2} END{printf "loudness: %s LUFS integrated, %s dBTP true peak\n", i, tp}'
  SIL=$(ffmpeg -hide_banner -nostats -i "$IN" -map 0:a:0 -af silencedetect=n=-50dB:d=1.0 -f null - 2>&1 | grep -c silence_start || true)
  echo "silences: ${SIL} stretch(es) of 1s+ below -50 dB"
else
  echo "audio:    NONE. The film has no sound."
fi
if [ -n "$EXPECT" ]; then
  awk -v d="$DUR" -v e="$EXPECT" 'BEGIN{x=d-e; if (x<0) x=-x; if (x>1.0) print "WARNING:  duration is more than 1s off what was asked"}'
fi

[ ${#TIMES[@]} -gt 0 ] || exit 0
DIR="${IN%.*}-frames"; mkdir -p "$DIR"; rm -f "$DIR"/f*.png
k=0
for t in "${TIMES[@]}"; do
  k=$((k+1)); f=$(printf "%s/f%02d_%ss.png" "$DIR" "$k" "$t")
  ffmpeg -hide_banner -loglevel error -y -ss "$t" -i "$IN" -frames:v 1 "$f" && echo "frame:    $f"
done
COLS=$(( k < 4 ? k : 4 )); ROWS=$(( (k + COLS - 1) / COLS ))
ffmpeg -hide_banner -loglevel error -y -pattern_type glob -i "$DIR/f*.png" \
  -vf "scale=480:-2,tile=${COLS}x${ROWS}:padding=6:color=black" -frames:v 1 "$DIR/contact-sheet.png" \
  && echo "sheet:    $DIR/contact-sheet.png"
