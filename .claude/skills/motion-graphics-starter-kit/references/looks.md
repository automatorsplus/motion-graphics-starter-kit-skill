# Looks

Pick ONE look per film and hold it. A reference video beats this list: if the member sent one, its look wins and
this file only fills gaps. Everything here is built in code (HTML, CSS, SVG, GSAP), so it renders the same every
time and costs nothing.

HyperFrames renders by seeking to each frame, so every "random" value must be seeded or derived from the frame
number. Never `Math.random()` at render time.

## Claymation, built in code

The look of plasticine under a warm lamp, made without a single generated image.

- **Shapes:** everything rounded. Blobs, pills, thick discs, chunky outlines. No sharp corners, no hairlines.
- **Shading:** each shape gets a radial gradient lit from the top left (a light spot, the base colour, a darker
  rim) plus a soft contact shadow underneath. That one gradient is most of the clay feel.
- **Texture:** one SVG `feTurbulence` grain layer over the whole frame at 6 to 10% opacity, multiply blend. It
  reads as fingerprints and matte surface.
- **Animate on twos:** step motion to 12 updates a second (`ease: "steps(N)"` in GSAP, or round the progress per
  frame). Smooth 60fps motion instantly reads as vector, not clay.
- **Boil:** every 2 frames, nudge each shape by 1 to 2px and 0.5 degrees, seeded by frame number. Subtle. It is the
  thing that makes stop motion feel handmade.
- **Squash and stretch:** anything that lands squashes (scaleY 0.8, scaleX 1.15) for 2 to 3 frames, then settles.
- **Type:** fat rounded faces (Fredoka, Baloo 2 or Chewy from Google Fonts, downloaded into `assets/fonts/` as
  SKILL.md section 3 shows), coloured like the clay, with the same gradient and contact shadow.
- **Sets:** a felt or paper backdrop colour, a tabletop line, props as simple clay forms.
- **The member's own assets:** product shots and character art go in as images. Never redraw them. Sit them on a
  clay plinth, give them a contact shadow and a squash-in landing so they live in the same world. If an image has
  a background, keep it on a rounded clay-coloured card rather than faking a cut-out.

## Type slam on flat colour (launch films, app promos)

The style of most high-end motion graphics reels: confident, fast, graphic.

- **Flat colour fields** that swap hard on the beat. Two or three colours plus one accent, nothing else.
- **Huge heavy type**, one to three words on screen at a time, filling half the frame. It slams in: scale 1.3 to 1
  over 4 to 6 frames with a power4 ease-out, plus a 2 to 3 frame directional blur.
- **Hard cuts on beats**, not crossfades. A white or accent flash frame on the biggest drop.
- **A live product UI:** cards, a chat bubble, a calendar that builds piece by piece as if someone is using it.
  Each piece lands on a beat with a pop.
- **Texture of a HUD:** a dot grid, thin crosshairs, small mono labels and counters ticking up in the corners.
- **One morph** somewhere: a dot field gathering into the logo, a card unfolding into the next scene. That one
  transition is what people remember.

## Premium product hero

For a single product that has to look expensive.

- Dark ground, one hero object, a slow push in on the whole film.
- A light sweep (a soft white gradient band) crossing the product on a downbeat.
- Short lines of thin, wide-spaced type that fade up, never slam.
- Fewer cuts: one per bar. The music does the energy.

## Pacing rules that apply to every look

- **Motion in the first frame.** Never open on a static logo or a black frame. The hook is the most striking
  image you have, already moving.
- **One idea per beat.** If a scene needs a sentence to explain, it is two scenes.
- **Stillness before the climax.** Hold, or drop the music, for half a bar before the biggest moment.
- **The end card holds.** Name and line on screen, readable and still, for at least 2 seconds.
- **Readable at phone size.** Nothing under about 40px on a 1080p frame.
