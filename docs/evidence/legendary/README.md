# Phase 5B-2B rendered and audio evidence

Agent D uses actual Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg display.
`tools/capture_legendary_items.gd` invokes production controllers, saved inventory
transactions, input events, combat methods, UI rendering and the real engine
mixer. Its isolated profile deliberately seeds 20 units per item, configured
room resources, door levels, times and boss state. These are prepared fixtures,
not naturally earned rewards or natural human matches. Reward selection itself
uses the genuine persisted settlement with a disclosed RNG seed search.

Final full capture: **115 checks, zero failures, 22 PNGs**. The final log has no
script, parse or rendering errors; the unsupported VSync warning is expected.
A subsequent inventory-only capture passes **22 checks** after the cosmetic card
enclosure change; its four inventory images replace the earlier frames.

## Inspected rendered frames

- `render-01` / `02` / `03` / `04`: original, advanced and Legendary inventory
  pages plus 960×540 Legendary inventory. Original icons, quantities and
  descriptions remain visible. Descriptions no longer intersect Equip buttons;
  two-slot selection remains separate from permanent perks.
- `render-05` / `06` / `07`: actual 20-item wheel, exact visible odds and gold
  Legendary reveal. Each Legendary is 1% Victory and 0.25% Consolation. A real
  seeded Victory receipt grants four Cursed Fortune units before the animation;
  Skip and acknowledgement do not grant them again. The reveal icon scales in
  with the distinct cue and gold rarity text.
- `render-08` / `09` / `10` / `11` / `12`: blue expanding clock rings, frozen
  Hunter, countdown and independent economy; simplified Reduced Effects;
  960×540 view; expiry and shorter Reaper freeze while a genuine Shadow Surge
  telegraph is held. The Hunter animation clock is asserted held, and its charged
  attack resumes. The warning remains readable above the separate left banner.
- `render-13` / `14` / `15`: invalid Seal feedback without consumption or cooldown,
  actual special counter window, then golden binding geometry and exact
  `SPECIAL ATTACK INTERRUPTED!`. The successful activation clears stale failure
  feedback and preserves special cooldown and targeting.
- `render-16` / `16a` / `17`: real lethal-hit interception consumes one Heart,
  restores the prepared door to 270/1800 HP, displays exact notification,
  launches golden wings/heart and a finite 360-HP shield. Expanded and reduced
  wing frames are rendered without polygon failures. Shield expiry is checked.
- `render-18` / `19` / `20` / `21`: cursed chest, coins and purple aura with actual
  +500 Gold, explicit warning, curse countdown and stronger Hunter readout;
  small and reduced views; final expiry. Important resource counters, door HP,
  combat warnings, repair controls and hotbars remain readable in these fixtures.

## Actual engine audio

`render-legendary-mix.wav` records the master bus through AudioEffectRecord,
not a concatenation of source assets. It contains 11.7029 seconds of stereo
44.1 kHz PCM, peak 2589/32767, RMS 200.39 and **zero clipped samples**.
`render-audio-measurements.json` retains the exact measurement. All four new
activation cues and the Legendary reveal play through production events;
81 streams decode, no assets are missing, four music stems start, and no critical
cue remains queued. Eleven competing noncritical cues are intentionally dropped
by the existing bounded voice/frame budget in the accelerated fixture. No voice
limits were raised. Dummy output does not constitute human listening.

## Coverage and findings

The script exercises all three inventory pages, exact 20-item victory and defeat
odds, Legendary reveal and acknowledgement without a second grant, keyboard
activation, normal and Reaper Freeze, continued income, held animation clock,
charged attack recovery, invalid and valid Seal, automatic lethal Heart rescue,
finite shield expiry, Fortune's actual 500 Gold and curse timer, shared match
budget, saved Reduced Effects, and 960×540 presentation.

Initial findings were sent to the production owner: Guardian wing geometry at
animation age zero failed polygon triangulation; the Legendary banner obscured
the existing combat warning; inventory descriptions intersected Equip buttons;
Freeze status overlapped door HP; an invalid Seal toast lingered after success.
The initial assertion about `1%` versus the correctly displayed `1.0%` was a test
formatting error, not incorrect probabilities. The initial log is retained. A further expiry-frame review found `EFFECT ENDED` intersecting door HP; the
developer moved end events into outlined foreground lanes shared with numerical
feedback, spaced 26 pixels apart to avoid simultaneous text collisions. All confirmed presentation defects were fixed
and the affected rendered paths rerun successfully; the final screenshot set
contains the corrected presentation.

Native Windows import, gameplay, controls, hardware FPS and speakers remain
UNVERIFIED. Subjective cinematic appeal, musical quality and human balance are
UNVERIFIED. A software display and numerical engine recording cannot establish
those claims. The expected unsupported VSync warning is a Mesa environment limit.

The regular audio regression subsequently found that the five new WAV import
files used Godot's default ADPCM setting rather than the project's PCM setting.
B changed them to `compress/mode=0` and reimported; D repeated the full rendered
capture and engine recording against those final runtime assets. Earlier
compressed-audio evidence is retained as `render-compressed*`; it is not the
final audio measurement.

Only D-owned private Xorg processes (PIDs 56562 and 59162) were stopped.
