# Phase 5C-2 actual rendered and audio evidence

Agent D ran Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg display.
`tools/capture_haunted.gd` uses an isolated prepared tutorial-graduate profile,
actual stage configuration and real production transactions/input. It seeds
completed campaign records so all five maps can be inspected, prepares living
teammate rooms, and places the real Hunter at a valid attack approach. These
are prepared fixtures, not naturally played matches or earned-resource balance
claims. C owns the separate economy and live-match simulations.

The full capture passes 151 checks with zero failures and creates 31 PNGs.
The final log must have no script/parse/engine errors; the expected software
VSync warning does not affect rendering. The capture script and final logs are
reproducible. Initial failed logs remain to document actual findings and fixes.

## Inspected actual frames

- Five world frames show original dead forest, medical exterior/flickering signs,
  hotel broken windows/streets, laboratory observation glass and mansion
  graveyard/tree/bat surrounds. Existing room/corridor layouts remain. All five
  ambient kinds are registered and their full 30-pixel safety footprint is outside
  protected room/corridor areas. At least one actor is actually visible in every
  normal full-map frame; the final capture observes four visible non-flash actors
  per map. Cosmetic movement leaves model RNG and Hunter HP unchanged.
- Five additional creature close-ups use a clearly prepared 3× inspection camera
  to show the walker, eyes, crawler, watcher and apparition designs. This is a
  rendering inspection, not a claim that normal gameplay uses this zoom/framing.
- Lightning reveals an otherwise zero-alpha apparition; thunder is scheduled
  after the flash and actually plays later. Reduced Effects suppresses the flash
  overlay and lowers visual counts while retaining the apparition marker. Normal
  and 960×540 world views keep combat HUD, doors and floor pads readable.
- A genuine normal Hunter strike breaks a 1-HP prepared teammate door. The living
  survivor panics during real breach navigation; the Hunter must reach within
  12 pixels of the bed before actual elimination. Captures show the real strike
  pose/sweep, a collapsing survivor, abandoned-room tint and a persistent fallen
  body while the Hunter follows its existing exit route. Dead economy and bot
  construction stop; references remain intact.
- The red warning reads `SURVIVOR ELIMINATED`, followed by actual name, room and
  remaining count on a separate line. The team count drops from six to five and
  four. A real player-door breach has higher priority than teammate death. No
  forced retarget or artificial death is used.
- A second prepared encounter uses the existing transformed Reaper and an actual
  telegraphed attack. Its breach uses the distinct deeper laugh; the second real
  elimination uses the alternate death scream. Duplicate new-ID callbacks add
  neither scream nor laugh.
- Actual mouse upgrades show original Level 4, new Level 5 armor, Level 9 and
  Level 10 prestige. Gold/power are deliberately funded for visual accounting
  fixtures. The coupon discounts an actual eligible upgrade; paid ledgers remain
  real. Level 10 shows original armor, crown, readable max badge/pulse and actual
  enhanced projectile. The inspector rejects Level 11 and displays compact
  separate-resource refunds. Actual sale refunds half the real paid investment,
  cannot repeat and frees the tile for an Arc turret, also upgraded to Level 10.
  Small-window and Reduced Effects views remain readable.

## Actual audio

The master-bus WAV is an AudioEffectRecord capture of the real engine mixer,
not concatenated source WAVs. Dummy output was used; no human listening is
claimed. Final recording: 18.668844 seconds, peak 723/32767, RMS 147.08291, zero clipped samples. Exact measurements are in
`render-audio-measurements.json`.

Final diagnostics show all nine new cues played: two death screams, normal and
Reaper laughter, thunder, wind, rain, prestige upgrade and survivor notice.
105 streams load, no assets are missing, and four permanent music stems start
once. Weather voices route through Ambient; muting Ambient leaves Effects
unmuted. Critical death/notice/prestige cues use the existing bounded voice and
retry budgets. Ordinary competing cues may be intentionally dropped; this does
not mean an earned critical cue was omitted. All named new cues are confirmed
through actual player-start diagnostics.

## Findings fixed and rerun

The first run exposed an existing mutable draw-layer callback drawing through
a new Control outside its draw signal, and a reduced flag reset between frames.
B fixed both. Actual screenshots then revealed off-camera initial creatures,
truncated elimination/count text, long refund floats, max badge/door-HP overlap,
stacked upgrade pulses and coupon savings mislabeled as a block. B corrected
these, added real-event Hunter strike feedback and preserved original combat
logic. A duplicate text replacement briefly caused a parse error; it is retained
in `render-third-parse.log` and fixed before the final clean run. No assertions
were disabled. The final frame timing lets the player-breach warning slide in
before capture and lets the real Hunter exit during the collapse/aftermath.

UNVERIFIED: native Windows import/run/input/hardware FPS/speaker output,
subjective fear or art/audio quality, human balance and every possible camera
composition. The software display and numerical recording cannot establish
those claims. Only D-owned Xorg process 75873 is stopped after final evidence.
