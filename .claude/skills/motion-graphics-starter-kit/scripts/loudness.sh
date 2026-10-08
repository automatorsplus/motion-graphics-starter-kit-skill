#!/usr/bin/env bash
# Measure a rendered film's loudness and set it with ONE plain gain change. No limiter, no compressor,
# no normaliser: the mix you built is the mix that ships, only louder or quieter.
#
#   loudness.sh <film.mp4>                     # measure only
#   loudness.sh <film.mp4> --apply [target]    # write <film>-final.mp4 at the target (default -14 LUFS)
#
# The gain is capped so the true peak stays at or under -1 dBTP. If the cap stops it short of the target,
# it says so and reports the loudness actually reached. Video is stream-copied, never re-encoded.
set -euo pipefail
IN="${1:-}"; MODE="${2:-}"; TARGET="${3:--14}"
[ -f "$IN" ] || { echo "usage: loudness.sh <film.mp4> [--apply [target_lufs]]" >&2; exit 1; }

measure() { # prints: I TP
  ffmpeg -hide_banner -nostats -i "$1" -map 0:a:0 -af ebur128=peak=true -f null - 2>&1 \
    | awk '/Integrated loudness:/{f=1} f&&/I:/{i=$2} /True peak:/{p=1} p&&/Peak:/{tp=$2} END{print i, tp}'
}

if ! ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$IN" | grep -q .; then
  echo "NO AUDIO STREAM in $IN"; exit 3
fi

read -r I TP < <(measure "$IN")
echo "measured: ${I} LUFS integrated, ${TP} dBTP true peak"
[ "$MODE" = "--apply" ] || exit 0

GAIN=$(awk -v t="$TARGET" -v i="$I" -v p="$TP" 'BEGIN{g=t-i; cap=-1-p; if (g>cap) g=cap; printf "%.1f", g}')
CAPPED=$(awk -v t="$TARGET" -v i="$I" -v g="$GAIN" 'BEGIN{print ((t-i)-g > 0.05) ? "yes" : "no"}')
OUT="${IN%.*}-final.mp4"
ffmpeg -hide_banner -loglevel error -y -i "$IN" -map 0:v:0 -map 0:a:0 -c:v copy -af "volume=${GAIN}dB" -c:a aac -b:a 320k -movflags +faststart "$OUT"
read -r I2 TP2 < <(measure "$OUT")
echo "applied: ${GAIN} dB plain gain -> $OUT"
echo "result:  ${I2} LUFS integrated, ${TP2} dBTP true peak (target ${TARGET} LUFS, peak ceiling -1 dBTP)"
if [ "$CAPPED" = "yes" ]; then
  echo "note: the peak ceiling stopped the gain short of ${TARGET}. The mix has a loud transient (usually an SFX hit)."
  echo "      To get closer: turn that one sound down in the composition (data-volume) and re-render. Do not add a limiter."
fi
