#!/usr/bin/env bash
# Generate an instrumental music bed with ElevenLabs Music v2.5 on fal.ai.
#
#   fal_music.sh <seconds> "<prompt>" <out.mp3>
#
# Cost: fal bills $0.60 per output minute, rounded UP to the whole minute, so any film up to
# 60 seconds costs $0.60 a track (price on fal.ai/models/elevenlabs/music/v2.5, checked 8 Oct 2026).
# Needs FAL_KEY (exported, or in a .env file in this folder or any parent), curl and jq.
set -euo pipefail
SECS="${1:-}"; PROMPT="${2:-}"; OUT="${3:-}"
[ -n "$SECS" ] && [ -n "$PROMPT" ] && [ -n "$OUT" ] || { echo "usage: fal_music.sh <seconds> \"<prompt>\" <out.mp3>" >&2; exit 1; }

if [ -z "${FAL_KEY:-}" ]; then
  DIRUP="$PWD"
  while [ "$DIRUP" != "/" ]; do
    if [ -f "$DIRUP/.env" ] && grep -q '^FAL_KEY=' "$DIRUP/.env"; then
      FAL_KEY=$(grep '^FAL_KEY=' "$DIRUP/.env" | head -1 | cut -d= -f2- | tr -d '"'"'"' \r'); break
    fi
    DIRUP=$(dirname "$DIRUP")
  done
fi
[ -n "${FAL_KEY:-}" ] || { echo "No FAL_KEY found. Use the code-made bed (synth_music.py) or add a key with setup.sh --set." >&2; exit 1; }
AUTH="Authorization: Key $FAL_KEY"
MODEL="elevenlabs/music/v2.5"

MS=$(awk -v s="$SECS" 'BEGIN{printf "%d", s*1000+0.5}')
MINUTES=$(( (MS + 59999) / 60000 ))
echo "Generating ${SECS}s of music on fal.ai ($MODEL). Billed: ${MINUTES} minute(s) x \$0.60 = \$$(awk -v m="$MINUTES" 'BEGIN{printf "%.2f", m*0.6}')"

PAYLOAD=$(jq -n --arg p "$PROMPT" --argjson ms "$MS" '{prompt: $p, music_length_ms: $ms, force_instrumental: true}')
SUBMIT=$(curl -sS -X POST "https://queue.fal.run/$MODEL" -H "$AUTH" -H "Content-Type: application/json" -d "$PAYLOAD")
STATUS_URL=$(printf '%s' "$SUBMIT" | jq -r '.status_url // empty')
RESPONSE_URL=$(printf '%s' "$SUBMIT" | jq -r '.response_url // empty')
[ -n "$STATUS_URL" ] || { echo "Submit failed: $SUBMIT" >&2; exit 1; }

for _ in $(seq 1 60); do
  STATE=$(curl -sS "$STATUS_URL" -H "$AUTH" | jq -r '.status')
  case "$STATE" in
    COMPLETED) break ;;
    FAILED|CANCELLED) echo "Music job $STATE." >&2; exit 1 ;;
  esac
  sleep 3
done
[ "$STATE" = "COMPLETED" ] || { echo "Still $STATE after 3 minutes. Status URL: $STATUS_URL" >&2; exit 2; }

URL=$(curl -sS "$RESPONSE_URL" -H "$AUTH" | jq -r '.audio.url // empty')
[ -n "$URL" ] || { echo "No audio URL in the result." >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
curl -sS -o "$OUT" "$URL"
echo "$OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" 2>/dev/null)s)"
