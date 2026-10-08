---
name: motion-graphics-starter-kit
description: The front door for making any new motion graphics film when this kit is installed, used INSTEAD of starting at /hyperframes (it calls HyperFrames' own skills itself). Turns a brief, from one line up to a full brief with logos, product shots, characters and reference videos, into a finished MP4 with music and sound effects, checked frame by frame before it is called done. Use whenever someone asks for a motion graphics video, an animated ad, a logo sting or animated logo, a launch film, a promo, a product hook, a showreel, a reel of their products or characters, kinetic type, or a video in the style of examples they share.
---

# Motion Graphics Starter Kit

One brief in, one finished film out: a motion graphics MP4 with music and sound effects cut to the beat, checked
before you say it is done. The rendering engine is HyperFrames by HeyGen (free, Apache 2.0): a film is an HTML page
with timed animation, rendered frame by frame to video. This skill is the front door and the finish line. HeyGen's
own skills do the building in the middle.

**This skill comes before `/hyperframes`.** HeyGen's entry skill describes itself as the mandatory first read
for any video request. When this kit is installed, a NEW film starts here instead: this file decides the brief,
then hands the build to HeyGen's workflow skill in section 3, which is the same place `/hyperframes` would route
to. Edits to an existing HyperFrames project can go straight to HeyGen's skills.

Read this file top to bottom on every run. `references/looks.md` holds the looks. `examples/` holds three ready
prompts. `test-kit/` is for comparing two models on the same prompt and is not part of a normal run.

## First time in a project: you do the setup

If this is the first film in this project, or anything below fails for a missing tool, run the setup yourself.
The member answers questions; they never open a terminal.

```bash
bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh
```

It checks Node 22+, ffmpeg and ffprobe, installs HyperFrames' own skills with HeyGen's CLI
(`npx hyperframes skills update general-video motion-graphics`, which brings the core set: `/hyperframes`, the
`hyperframes-*` domain skills and `/media-use`), fetches the render browser, and adds two lines to the project's `CLAUDE.md` so new films start in this kit
rather than at `/hyperframes` (tell the member it did). If a tool is missing, tell the
member the one install line it prints and offer to run it.

**Music key, optional.** Generated music needs a fal.ai key. Ask once: *Do you want generated music? It needs a
fal.ai key and costs about $0.60 a film. Without one I make a beat in code.* If they paste a key:

```bash
bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh --set FAL_KEY=<the key they pasted>
```

It writes `.env` (locked, gitignored) and proves the key with a free call. Never echo the key back. If they say no,
carry on: every film still gets music and sound effects.

**Generated scenes, optional.** Most films are built entirely in code. For real generated scenes (a claymation
world around their product, a character acting something out) the kit uses Higgsfield: GPT Image 2 for stills,
Gemini Omni Flash for short clips animated from those stills. Ask once, only if the member wants that kind of film:
*Do you want generated scenes? It uses your Higgsfield account and credits (about 6.5 credits a still, 18 a 4-second
clip). Without it, everything is built in code.* If yes, `setup.sh --higgsfield` installs the Higgsfield CLI if
needed and checks the sign-in; if it is not signed in, run `higgsfield auth login`, which opens their browser to
sign in. Never ask for or handle a Higgsfield password or token.

If HyperFrames' skills do not show in your skill list after install, they are on disk anyway: read
`~/.claude/skills/<name>/SKILL.md` (or `.claude/skills/<name>/` in the project) directly.

## 1. Intake: one line is enough

Read what the member gave and pull out:

| Field | Default if they did not say |
| --- | --- |
| Subject: what the film is for | **ask, this is the only question allowed** |
| Length | 15 seconds |
| Shape | 16:9, 1920x1080. 9:16 (1080x1920) if they say vertical, Reels, TikTok or Shorts |
| Look | from their words or reference videos, else pick from `references/looks.md` |
| Ending | the name, plus their line if they gave one |
| Assets | none: build everything in code |
| Generated scenes | none. Only when they ask for real scenes or a look that needs them, and Higgsfield is set up |
| References | none |

Ask **at most one question**, and only when the subject is unclear. Everything else gets the default; state the
defaults in one line and start. Do not interview.

**Assets.** List every file in any folder they point at and open every image with Read before planning. Note what
each one is (logo, product, character) and what it should do in the film. Their logos and product shots are used
as given: never redraw, recolour or regenerate them.

**Reference videos.** A local file: pull one frame a second (`ffmpeg -i ref.mp4 -vf fps=1,scale=640:-2 ref/%03d.png`)
and read them. A link: if `yt-dlp` is installed, download it at low resolution (`yt-dlp -f "bv*[height<=480]" -o ref.mp4 <url>`)
and do the same. If it is not installed, say so and offer to install it (`python3 -m pip install yt-dlp`), which
counts as your one question. Write five style notes before planning: palette, type, how things enter and exit,
cuts per second, texture. Those notes ARE the look.

## 2. Plan: beats on a tempo, then one look

Pick a tempo first. Every cut lands on a beat, so the film and the music agree.

- **120 BPM** by default: a beat is 0.5s, a bar (4 beats) is 2s.
- 100 to 110 BPM for premium and calm. 128 to 140 BPM for hype.

Shape for a 15-second film (scale it for other lengths):

| Bars | Time at 120 BPM | Job |
| --- | --- | --- |
| 1 | 0 to 2s | **The hook.** The most striking image, already moving in the first frame. No logo first, no black open |
| 2 to 5 | 2 to 10s | **The build.** One idea per beat or half-bar: the product, what it does, the proof |
| 6 | 10 to 12s | **The peak.** Half a bar of held breath, then the biggest move in the film |
| 7 to 8 | 12 to 15s | **The end card.** Name and line, landed on a downbeat, then still for at least 2s |

The plan is: BPM, the look (five style notes), and a beat table with one row per scene: start, end, what is on
screen, how it moves, which sound effect lands. It is saved as `PLAN.md` in section 3, right after the project
exists. This table drives the build, the music prompt and the checks.

## 3. Build it in HyperFrames

```bash
npx hyperframes init <film-slug> --non-interactive --resolution landscape   # or portrait for 9:16
cd <film-slug>
```

`init` needs an empty folder, so it comes first. Run every later command from inside `<film-slug>/`. In the
commands below, `$KIT` stands for this skill's folder as an absolute path (for example
`/path/to/project/.claude/skills/motion-graphics-starter-kit`): write the real path in each command, because
shell variables do not survive between your tool calls.

Then, inside the project, in this order. Do not skip a step.

1. **Write `BRIEF.md`** in HyperFrames' own format, now, before anything else. It is HyperFrames' no-repeat token:
   with it, its skills read the brief instead of running their own intent interview (which would break this
   kit's one-question promise), and a later session can resume the project.

   ```markdown
   ---
   workflow: general-video          # motion-graphics if the film is under 10 seconds
   flow: automation
   storyboard: no
   message: "<the one thing the film must say>"
   aspect: 1920x1080                # or 1080x1920
   length: 15s
   ---

   ## Intent
   <the member's request, in their own words>

   ## Assets
   - assets/<file>: <what it is, where it belongs>

   ## Notes
   - Plan, tempo and beat table: PLAN.md. Music and sound effects are added by the starter kit (assets/music.*, assets/sfx/).
   ```

2. **Save the plan as `PLAN.md`.**
3. **Copy their assets** into `assets/`, and the fonts you will use into `assets/fonts/`. HyperFrames needs
   every font as a local file with an `@font-face`, so download it rather than linking it, for example
   `curl -L -o assets/fonts/Fredoka.ttf "https://github.com/google/fonts/raw/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf"`
   (Google Fonts' own repository; the path is `ofl/<family>/` or `apache/<family>/`).
4. **Generated stills and clips, only if the film uses them** (section 3b below). They come before the music so
   the beat table can be checked against real clip lengths.
5. **Make the music now, before the scenes** (section 4 below), so the build is cut to real beats.
6. **Follow HyperFrames' workflow skill** named in `BRIEF.md` (`/general-video`, or `/motion-graphics` under 10
   seconds), and read `/hyperframes-core` before writing any composition HTML. Their rules on structure, timing
   attributes and deterministic rendering are the contract; this skill does not repeat them. Use your beat table
   for every `data-start` and `data-duration`.
7. Hold the kit's own bar while you build: motion in frame one, one idea per beat, type readable on a phone,
   their assets untouched, and the look from `PLAN.md` on every scene.

Optional extra: the free motion presets library at https://github.com/cth9191/motion-design has ten more named
looks. Mention it if the member wants more styles; do not install it unasked.

## 3b. Generated stills and clips (optional, Higgsfield)

Only when the member asked for generated scenes and Higgsfield is set up, and only once `BRIEF.md` and `PLAN.md`
exist in the project: no credits are spent on a scene that is not in the beat table. Plan them in the beat table first: one
still per scene that needs one, and a clip only where that scene must move on its own (a character acting, liquid,
flames). Everything else is the still animated in code (push in, parallax, slam), which costs nothing.

Say the total before the first call, from the beat table, for example *Higgsfield: 5 stills and 3 four-second clips,
about 86 credits*. Check the balance and exact prices for free:

```bash
bash $KIT/scripts/higgsfield_gen.sh cost image 16:9
```

Then, one call per still, writing one shared style sentence at the start of every prompt so the scenes match:

```bash
bash $KIT/scripts/higgsfield_gen.sh image assets/gen/s1.png 16:9 "<style sentence> <the scene>" --image assets/<their product>.png
```

Pass their product, character and logo images as `--image` references (repeat the flag, up to about four) and say
in the prompt to copy them exactly. Open every still with Read before animating it. Reject and regenerate any still
where their product, label or character has drifted, and do not animate a still you have not looked at.

A clip from a still (4 to 8 seconds; 4 covers two bars at 120 BPM):

```bash
bash $KIT/scripts/higgsfield_gen.sh clip assets/gen/c1.mp4 16:9 assets/gen/s1.png 4 "<what moves>. Single continuous shot, no text."
```

Place clips as `<video muted>` with `data-start` on their beat: the music and sound effects are the soundtrack.
Generated scenes never replace their real assets: the end card and any packshot use their own logo and product
files, untouched. Run the calls in the background in parallel when there are several, and keep the stills and clips
in `assets/gen/`.

## 4. Music, cut to the tempo

**With a fal.ai key:** say the cost in one line (*Music: ElevenLabs Music on fal.ai, $0.60 for this film*), then:

```bash
bash $KIT/scripts/fal_music.sh <seconds> "<prompt>" assets/music.mp3
```

Write the prompt from the beat table:
genre and mood from the look, the BPM, and the shape in seconds, for example *Punchy electronic launch track,
instrumental, 120 BPM. 0 to 2s a tight synth stab and riser, 2s the beat drops in, driving through 10s, half a
second of silence at 10.5s, a big hit at 11s, resolving to a clean final chord at 13s that rings out to 15s. No
vocals.* fal bills by the minute, rounded up, so any film under a minute is $0.60.
The script finds `FAL_KEY` in the project's `.env` by itself, walking up from the film folder. Never copy `.env`
into the film folder or anywhere else.

**Without a key:** a bed made in code, free:

```bash
python3 $KIT/scripts/synth_music.py --seconds 15 --bpm 120 --drop 1 --out assets/music.wav
```

`--mood dark` for a minor key. It prints the bar times. Its drums are peaky, so under the peak ceiling in section 6
a film on this bed usually lands around -16 LUFS rather than -14. That is fine; say the number.

**Silent** only if the member asked for no music.

Place it as one `<audio>` with an `id`, `data-timeline-role="music"`, `data-start="0"` and `data-volume="1"`,
then find the real beats:

```bash
npx hyperframes beats
```

It writes `beats/<file>.json`. If the detected beats drift from your plan (generated music rarely lands exactly on
the asked BPM), move your scene starts to the detected beats, not the other way round.

## 5. Sound effects on the cuts

HyperFrames ships about twenty sound effects that work with no key and no account (Pixabay licence, free for
commercial use). Pull one into the project by name:

```bash
npx hyperframes media-use resolve --type sfx --intent "whoosh" --project .
```

Names: `whoosh`, `whoosh-short`, `whoosh-cinematic` (5.5s build), `impact-bass-1`, `impact-bass-2`, `riser`
(10s, start it 10s before the peak), `pop`, `click`, `click-soft`, `key-press`, `typing`, `ping`, `notification`,
`chime`, `sparkle`, `glitch-1`, `glitch-2`, `glitch-3`, `error`. If the command is unavailable, the same files sit
in the installed `/media-use` skill under `audio/assets/sfx/`: copy what you need into `assets/sfx/`.

Where they go, from the beat table:

- a whoosh on every scene transition, timed so its peak lands ON the cut
- an impact on every slam and on the logo landing
- pop or click on UI pieces appearing
- a riser into the peak, sparkle or chime on the end card

Each is its own `<audio>` with an `id` and `data-start` at the moment it should be heard. Start at
`data-volume="0.5"`; impacts can go to 0.7. Fewer, well placed sounds beat one on every frame.

## 6. Check, render, set the loudness

```bash
npx hyperframes check --at-transitions     # samples every transition, not just scene middles
npx hyperframes render -o renders/<film-slug>.mp4 --quality delivery
bash $KIT/scripts/loudness.sh renders/<film-slug>.mp4 --apply
```

`check` must end with no errors, **and its warnings are not noise.** Every `content_overlap` or out-of-canvas
warning has a time: look at the frame at that time and fix it if it is real. The usual culprit is a word
handoff, where the old line has not cleared before the new one lands. In testing, `check` passed while two
headline words sat on top of each other for four frames; only the warning at that time pointed at it. Low
contrast warnings on deliberately muted text can stand, but say so.

`loudness.sh` measures the mix and applies **one plain gain change** toward -14 LUFS (the loudness YouTube,
Instagram and TikTok normalise to), capped so the true peak stays at or under -1 dBTP. No limiter, no compressor,
nothing else touches the sound. It writes `renders/<film-slug>-final.mp4`. If it reports the peak cap stopped it
short, find the loudest sound effect, lower its `data-volume`, re-render and run it again. A film within about
1.5 LU of -14 is fine; say the number either way.

## 7. Verify the MP4, then report

Check the file the viewer gets, not the composition:

```bash
bash $KIT/scripts/verify_film.sh renders/<film-slug>-final.mp4 <times> --expect-seconds 15
```

The times: the middle of every scene, **0.1s after every moment one word or line replaces another**, every
time `check` warned about, and the last second. Seams are where films break, and a scene's middle never shows
them.

Then **open every frame it wrote with Read** and check each one against the beat table:

- the scene that should be there is there, nothing cut off or overlapping, no blank or half-loaded frame
- every word is spelled right and readable at phone size: no text under about 40px tall on a 1080p frame,
  small taglines included; their logo and product are intact and unaltered
- the end card shows the name and line, fully landed
- duration is what was asked, there is an audio stream, loudness is near -14 LUFS and true peak at or under -1 dBTP

Fix what fails, re-render and check again. Then report to the member:

- the path of the final MP4, its duration, size and loudness
- one line on the look and the tempo
- what was spent (music: $0.60 or nothing; Higgsfield credits if any were used)
- **what you did not verify.** Frames are stills, so say plainly that motion between your sampled frames and
  how the sound feels in sync were not checked by eye or ear, and ask them to watch it once with sound

Offer one round of changes. To preview and edit by hand, `npx hyperframes preview` opens HeyGen's Studio on the
project.

## Rules

- Never call a film done because the render command finished. Done is the checks in section 7, passed.
- Never claim you watched or listened to the film. You read frames and measured numbers; say that.
- One plain gain change on the finished mix is the only audio processing. No limiters, compressors or normalisers.
- The member's logos, products and characters are used as given.
- The member's request is the go-ahead to render. If a HyperFrames workflow says to wait for approval before
  rendering, this kit overrides it: render, verify, then show them the result.
- The only paid calls in this skill are music on fal.ai and generated scenes on Higgsfield. Each cost is said
  before it runs, and neither is used unless the member said yes to it.
- Do not copy HeyGen's skills into this one. They install and update through `npx hyperframes skills`.
