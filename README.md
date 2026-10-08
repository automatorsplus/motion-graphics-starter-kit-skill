# Motion Graphics Starter Kit for Claude Code

> Part of the **Automators+** skills library -- Claude Code skills shared exclusively with the Automators+ community.

Type what you want, from one line up to a full brief with your logos, product shots and example videos. Get back a
finished motion graphics MP4 with music and sound effects cut to the beat, checked frame by frame before Claude
calls it done. Built on HyperFrames, HeyGen's free, open source engine that renders HTML animation to video.

## What You Get

- **One line in, one film out** -- no interview. Claude asks one question at most, and only if it cannot tell what the film is for
- **Cut to a tempo** -- the film is planned as beats on a BPM, so every cut lands on the music
- **Music either way** -- generated with ElevenLabs Music on fal.ai if you add a key (about $0.60 a film), or made in code for free
- **Sound effects included** -- about twenty whooshes, impacts, pops and risers that ship with HyperFrames, no account needed
- **Social loudness** -- one plain volume change to about -14 LUFS, the level YouTube, Instagram and TikTok play at. No limiter squashing your mix
- **Checked before done** -- HyperFrames' own check sampled at every transition, then frames pulled from the final MP4 at every scene and every word change and read, plus duration, loudness and peak. Claude tells you what it could not check
- **Your assets stay yours** -- logos, products and characters are used as given, never redrawn
- **Three ready prompts** -- a reel of your products and characters, a one-product hook ad, a launch film in the style of videos you like
- **A test kit** -- run the same prompt on two models and see which film wins and what each one cost, read from the session logs on your own machine

## Setup

Install the skill, open Claude in your project and say *set up the Motion Graphics Starter Kit*. **Claude runs
the setup for you**: it checks your tools, installs HyperFrames' own skills with HeyGen's CLI, and adds two lines
to your project's `CLAUDE.md` so new films start in this kit rather than at HyperFrames' own entry skill. You do
not open a terminal.

You need:

- **Node 22 or newer** ([nodejs.org](https://nodejs.org))
- **ffmpeg** (`brew install ffmpeg` on a Mac, `winget install ffmpeg` on Windows)

If either is missing, Claude tells you the one line to install it.

Optional, for generated music: a fal.ai key from [fal.ai/dashboard/keys](https://fal.ai/dashboard/keys). Pay as
you go, $0.60 per film under a minute, nothing monthly. Claude asks if you want it; paste the key in the chat
and Claude saves it to `.env` and proves it with a free call. Without a key every film still gets music, made in
code.

Under the hood it is one command, if you would rather run it yourself:

```bash
bash .claude/skills/motion-graphics-starter-kit/scripts/setup.sh
```

HyperFrames' skills install to your user skills folder (`~/.claude/skills/`), so they are available in every
project. They come from HeyGen and update with `npx hyperframes skills update`; nothing of theirs is copied into
this kit.

## Install the Skill

```bash
git clone https://github.com/automatorsplus/motion-graphics-starter-kit-skill
```

Copy `.claude/skills/motion-graphics-starter-kit/` into your project's `.claude/skills/` folder, or into
`~/.claude/skills/` to have it in every project. Copy the whole folder: the skill runs its scripts, examples and
test kit from there, so the SKILL.md on its own is not enough.

## Try It

The three prompts in `examples/`, ready to fill in:

- Build me a motion graphics video in the claymation style. Use all the products and characters from [folder]. Add music and sound effects so it really pops. Render it to MP4.
- Make a really insane, highly creative ad / motion graphics video for [product] in the claymation style, about 15 seconds. It needs a real wow factor: this is the hook at the start of a YouTube video, so it has to keep viewers hooked. Add music and sound effects so it really pops.
- Make a 15-second launch film for [app]. It needs outstanding motion graphics that really stand out, not something basic or corporate. Look at the motion graphics in these example videos: [links], and build it in that style with HyperFrames. End on the name and the line: [tagline]. Add music and sound effects cut to the beats. Render it to MP4.

Or just one line: *make me a 10-second animated logo sting for my bakery, vertical.*

## How It Works

The skill definition is in [`.claude/skills/motion-graphics-starter-kit/SKILL.md`](.claude/skills/motion-graphics-starter-kit/SKILL.md)
and reads top to bottom: intake, a beat plan on a tempo, music first, the build in HyperFrames, sound effects on
the cuts, check and render, loudness, then the frame-by-frame check of the final file. The looks (including
claymation built entirely in code) are in `references/looks.md`. The scripts in `scripts/` do the setup, the fal.ai
music call, the code-made music bed, the loudness and the final checks.

Want more looks? The free motion presets library at [github.com/cth9191/motion-design](https://github.com/cth9191/motion-design)
has ten more. Optional, not needed.

## Compare Two Models

`test-kit/README.md` shows how to run the same prompt in two fresh sessions at the same effort level and judge the
films blind. `test-kit/cost_from_logs.py` reads Claude Code's session logs on your machine and prints each
session's replies, tokens, wall time and token cost at list prices (dated in the script; output tokens are
estimated).

## Credit

HyperFrames and its skills are by HeyGen, Apache 2.0 ([github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)).
The bundled sound effects are from Pixabay under the Pixabay Content License.

## License

MIT

---

*Shared with the Automators+ community*
