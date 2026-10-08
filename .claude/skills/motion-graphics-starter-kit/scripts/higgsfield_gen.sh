#!/usr/bin/env bash
# Generated stills and clips on Higgsfield, through the Higgsfield CLI. Optional: only for films that need
# real generated scenes (a claymation world, a product in a set) rather than shapes built in code.
#
#   higgsfield_gen.sh cost  image <aspect>                                   # credits, spends nothing
#   higgsfield_gen.sh cost  clip  <aspect> <start.png> <seconds>             # credits, spends nothing
#   higgsfield_gen.sh image <out.png> <aspect> "<prompt>" [--image ref.png ...]
#   higgsfield_gen.sh clip  <out.mp4> <aspect> <start.png> <seconds> "<prompt>"
#
# <aspect> is 16:9 or 9:16. Stills are GPT Image 2 at 2k, high quality; pass the member's product or character
# images as --image references so the scene matches them. Clips are Gemini Omni Flash 1.1, image-to-video, 1080p,
# animated from a still. Every call prints its credit cost before it runs.
#
# Needs the CLI (npm install -g @higgsfield/cli) signed in (higgsfield auth login) on a plan with credits.
set -euo pipefail
command -v higgsfield >/dev/null 2>&1 || { echo "Higgsfield CLI not installed: npm install -g @higgsfield/cli, then higgsfield auth login" >&2; exit 1; }

IMG=(gpt_image_2 --resolution 2k --quality high)
VID=(gemini_omni_flash_1_1 --mode image-to-video --resolution 1080p)

fetch() {  # job json -> file
  local json="$1" out="$2" url
  url=$(printf '%s' "$json" | python3 -c "import json,sys
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  [ -n "$url" ] || { echo "No result in the job response: $json" >&2; exit 1; }
  mkdir -p "$(dirname "$out")"; curl -sS -o "$out" "$url"; echo "$out"
}

case "${1:-}" in
  cost)
    if [ "${2:-}" = "clip" ]; then
      higgsfield generate cost "${VID[@]}" --aspect_ratio "$3" --start-image "$4" --duration "${5:-4}" --prompt x 2>&1 | tail -1
    else
      higgsfield generate cost "${IMG[@]}" --aspect_ratio "${3:-16:9}" --prompt x 2>&1 | tail -1
    fi
    higgsfield account status 2>&1 | tail -1 ;;
  image)
    OUT="$2"; AR="$3"; PROMPT="$4"; shift 4
    echo "Still on Higgsfield (GPT Image 2, 2k): $(higgsfield generate cost "${IMG[@]}" --aspect_ratio "$AR" --prompt x 2>&1 | tail -1)"
    J=$(higgsfield generate create "${IMG[@]}" --json --aspect_ratio "$AR" --prompt "$PROMPT" "$@" --wait --wait-timeout 15m)
    fetch "$J" "$OUT" ;;
  clip)
    OUT="$2"; AR="$3"; START="$4"; SECS="$5"; PROMPT="$6"
    echo "Clip on Higgsfield (Gemini Omni Flash 1.1, ${SECS}s 1080p): $(higgsfield generate cost "${VID[@]}" --aspect_ratio "$AR" --duration "$SECS" --start-image "$START" --prompt x 2>&1 | tail -1)"
    J=$(higgsfield generate create "${VID[@]}" --json --aspect_ratio "$AR" --duration "$SECS" --start-image "$START" --prompt "$PROMPT" --wait --wait-timeout 20m)
    fetch "$J" "$OUT" ;;
  *) sed -n 2,14p "$0"; exit 1 ;;
esac
