#!/usr/bin/env bash
# First-time setup for the Motion Graphics Starter Kit. Run from the project root:
#
#   bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh
#   bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh --set FAL_KEY=your_key_here
#   bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh --higgsfield   # also set up generated scenes
#
# Checks the tools, installs HyperFrames' own skills with HeyGen's CLI, makes sure the render
# browser is present, and (optionally) writes and proves a fal.ai key for generated music.
# Nothing is generated and nothing is billed. Ends on PASS or a list of what to fix.
#
# `--set` exists so Claude can do the setup: the member pastes the key in the chat, Claude runs
# this, the member never opens a terminal or a text editor.
set -uo pipefail
ok=0; bad=0
pass(){ echo "  ✓ $1"; ok=$((ok+1)); }
fail(){ echo "  ✗ $1"; bad=$((bad+1)); }
note(){ echo "  · $1"; }
HF=0; for a in "$@"; do [ "$a" = "--higgsfield" ] && HF=1; done

if [ "${1:-}" = "--set" ]; then
  ARG="${2:-}"
  case "$ARG" in
    FAL_KEY=*) : ;;
    *) echo "usage: setup.sh --set FAL_KEY=your_key_here"; exit 1 ;;
  esac
  VAL="${ARG#*=}"; VAL=$(printf '%s' "$VAL" | tr -d '"'"'"' \r')
  if [ -z "$VAL" ] || [ "$VAL" = "your_key_here" ]; then
    echo "That is the placeholder, not a key. Get one at https://fal.ai/dashboard/keys"; exit 1
  fi
  touch .env; chmod 600 .env
  if grep -q '^FAL_KEY=' .env; then TMP=$(mktemp); grep -v '^FAL_KEY=' .env > "$TMP"; mv "$TMP" .env; chmod 600 .env; fi
  printf 'FAL_KEY=%s\n' "$VAL" >> .env
  grep -qx '\.env' .gitignore 2>/dev/null || printf '.env\n' >> .gitignore
  echo "  ✓ FAL_KEY written to $(pwd)/.env (${#VAL} characters, not shown), locked to you, .env gitignored"
  echo
fi

echo "Motion Graphics Starter Kit: setup check"
echo
echo "Tools"
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
  if [ "$NODE_MAJOR" -ge 22 ]; then pass "Node $(node -v)"; else fail "Node $(node -v) is too old: HyperFrames needs Node 22 or newer (https://nodejs.org)"; fi
else
  fail "Node is not installed: get Node 22 or newer from https://nodejs.org (or: brew install node)"
fi
for t in ffmpeg ffprobe; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t"; else fail "$t is not installed (macOS: brew install ffmpeg · Windows: winget install ffmpeg)"; fi
done
for t in curl jq python3; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t"; else
    case "$t" in
      jq) note "jq not installed: only needed for fal.ai music (brew install jq)";;
      python3) note "python3 not installed: only needed for the no-key music fallback";;
      *) fail "$t is not installed";;
    esac
  fi
done

if [ "$bad" -eq 0 ]; then
  echo
  echo "HyperFrames (HeyGen, free, Apache 2.0)"
  if npx -y hyperframes@latest --version >/dev/null 2>&1; then
    pass "HyperFrames CLI $(npx -y hyperframes@latest --version 2>/dev/null | tail -1)"
  else
    fail "could not run npx hyperframes: check your internet connection and npm"
  fi
  # The core set (/hyperframes, the hyperframes-* domain skills, /media-use) plus the two
  # workflows this kit hands off to. Installed by HeyGen's own CLI, never copied into this kit.
  if npx -y hyperframes@latest skills update general-video motion-graphics >/tmp/mgsk-skills.log 2>&1; then
    pass "HyperFrames skills installed or already current (core set + general-video + motion-graphics)"
  else
    fail "HyperFrames skills did not install. Last lines:"; tail -5 /tmp/mgsk-skills.log | sed 's/^/      /'
    echo "      fallback: npx skills add heygen-com/hyperframes --all"
  fi
  if npx -y hyperframes@latest browser ensure >/tmp/mgsk-browser.log 2>&1; then
    pass "render browser ready"
  else
    fail "render browser not ready. Last lines:"; tail -5 /tmp/mgsk-browser.log | sed 's/^/      /'
  fi
fi

echo
echo "Routing"
# HyperFrames' own entry skill calls itself the mandatory first read for any video request, so on some
# prompts (an animated logo sting, for one) Claude picks it over this kit. One line in the project's
# CLAUDE.md settles which comes first. Added once, never duplicated.
if grep -q "motion-graphics-starter-kit" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md already sends new films to this kit"
else
  [ -s CLAUDE.md ] && printf '\n' >> CLAUDE.md
  printf '%s\n' "## Motion graphics" "" "For any NEW motion graphics film (ad, logo sting, launch film, promo, reel), use the motion-graphics-starter-kit skill first, not /hyperframes. It hands the build to HyperFrames' own skills itself." >> CLAUDE.md
  pass "added two lines to $(pwd)/CLAUDE.md so new films start in this kit, not at /hyperframes"
fi

echo
echo "Music (optional)"
ENVFILE=""; DIRUP="$PWD"
while [ "$DIRUP" != "/" ]; do
  if [ -f "$DIRUP/.env" ] && grep -q '^FAL_KEY=' "$DIRUP/.env"; then ENVFILE="$DIRUP/.env"; break; fi
  DIRUP=$(dirname "$DIRUP")
done
if [ -z "${FAL_KEY:-}" ] && [ -n "$ENVFILE" ]; then
  FAL_KEY=$(grep '^FAL_KEY=' "$ENVFILE" | head -1 | cut -d= -f2- | tr -d '"'"'"' \r')
fi
if [ -z "${FAL_KEY:-}" ] || [ "$FAL_KEY" = "your_key_here" ]; then
  note "no FAL_KEY: films get a music bed made in code, or none. That is fine."
  note "for generated music (ElevenLabs Music on fal.ai, about \$0.60 a film): get a key at https://fal.ai/dashboard/keys"
else
  RESP=$(curl -sS -m 20 -X POST "https://rest.alpha.fal.ai/storage/upload/initiate" \
    -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
    -d '{"file_name":"setup-check.txt","content_type":"text/plain"}' 2>&1)
  if printf '%s' "$RESP" | grep -q '"upload_url"'; then
    pass "fal.ai accepted the key (${#FAL_KEY} characters, not shown). Generated music is on."
  else
    fail "fal.ai rejected the key: $(printf '%s' "$RESP" | head -c 160)"
  fi
fi

echo
echo "Generated scenes (optional, Higgsfield)"
if ! command -v higgsfield >/dev/null 2>&1 && [ "$HF" -eq 1 ]; then
  if npm install -g @higgsfield/cli >/tmp/mgsk-hf.log 2>&1; then pass "Higgsfield CLI installed"; else
    fail "Higgsfield CLI did not install (npm install -g @higgsfield/cli). Last lines:"; tail -3 /tmp/mgsk-hf.log | sed 's/^/      /'
  fi
fi
if command -v higgsfield >/dev/null 2>&1; then
  ACC=$(higgsfield account status 2>&1 | tail -1)
  if printf '%s' "$ACC" | grep -qi "credits"; then
    pass "Higgsfield signed in: $ACC"
  else
    note "Higgsfield CLI is installed but not signed in: run  higgsfield auth login  (opens the browser)"
  fi
else
  note "not set up: every film is built in code, which is fine. For generated scenes run setup again with --higgsfield"
fi

echo
if [ "$bad" -eq 0 ]; then
  echo "PASS. Ready. Describe the film you want, one line is enough."
  exit 0
else
  echo "$bad thing(s) to fix above, then run this again."
  exit 1
fi
