# Phase 5B-3 rendered UI and audio evidence

Agent D used actual Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg display,
with an isolated profile and production UI methods plus real mouse events.
`tools/capture_rewards.gd` is the reproducible source. These are prepared test
fixtures, not naturally played matches or human balance evidence. XP, prior
records, stock, elapsed time and terminal combat damage are deliberately seeded
to reach the interfaces; settlement, claims, saved choice, transitions and
inventory effects use real production transactions. Original player data is
untouched.

Final source run: **382 checks, zero failures, 22 screenshots**. Final log has
no script/engine errors; the expected VSync warning is environmental.

## Inspected screenshots

- `render-01` through `render-07`: Bronze's locked perks and one slot, Master
  two-perk build and two separate consumable slots, actual removal/replacement,
  XP-only Mythic locked, earned Mythic offense build, 960×540 layout, and all
  seven rank/perk icons. Combined bonus preview is visible. Automated bounds
  check all seven actual 40px icons and perk-description/button separation.
- `render-08`: real prepared stage-1 Hell victory settlement shows XP, actual
  unlocked achievements, new perk reveal and spin gate. Numeric reward values
  remain visible alongside the short side panels.
- `render-09` through `render-11`: all 20 exact spin odds remain, an already
  persisted reward is revealed and acknowledged, then the saved next-stage
  choice appears. Skipping animation does not choose the outcome.
- `render-12` through `render-16`: three named stage options, small layout,
  Economic Preparation selected exactly once, persisted/reloaded choice,
  intended stage-2 loadout and actual +25 starting Gold. Initial room Gold25
  becomes50; unrelated item stock/perks are not used to implement this bonus.
- `render-17` through `render-21`: two pages cover all12 achievements, actual
  condition progress and reward details, earned/locked/claimed states, one
  real First Victory claim changes XP535→550 and adds one Repair Kit; another
  claim is rejected and reload retains the claimed flag. Small and Reduced
  Effects views retain values and controls.
- `render-22`: a prepared stage-5 Hell Reaper victory crosses the real existing
  Mythic gates and shows Reaper Slayer's original icon and new-perk feedback.

D inspected all22 actual frames in contact sheets, plus detailed normal/small
perk, ranks, stage-choice, claim and result frames. Functional controls and
reward numbers remain readable in these compositions. Subjective appeal and
all possible display/camera states are not established.

## Findings and reruns

Initial fixture failures were not production defects: seeded stage5 lacked
required earlier records so its save correctly failed; the capture attempted
new result controls before the existing 0.95s intro completed; starting Gold was
incorrectly assumed100 instead of25. The fixture now uses a complete stage
record chain, waits for enabled controls and asserts the actual50 Gold result.
Initial/second logs remain; the initial script stopped at its invalid index.

Actual visual defects found and fixed by B: SVG minimum size forced64px perk
icons over adjacent text; setting expansion before finalsize now gives40px
loadout/28px ranks icons. The long Reaper perk description extended under its
button; deferred final width now wraps it correctly. D also identified missing
Mythic-perk cue dispatch and requested numeric achievement progress and combined
selected-bonus preview; B integrated those before the passing final capture.

## Audio and limitations

The final WAV is an actual AudioEffectRecord master-bus recording with Dummy
output, not concatenated source sounds. The recording is 9.4737 seconds, peak943/32767, RMS91.21, zero clipped samples.
Numeric measurements are in
`render-audio-measurements.json`. All six new cues are observed through real
engine event counts: perk unlock, achievement unlock, achievement claim,
difficult stage, stage selection and Mythic perk.87streams decode with no
missing assets; four permanent music players start once. Existing voice/frame
limits are retained. Human listening was not performed.

UNVERIFIED: native Windows import, gameplay, keyboard/mouse/hardware FPS and
speakers; subjective cinematic appeal, musical quality and human balance.
Expected unsupported VSync warning reflects the software display. D stops only
the private Xorg process started for this task.

A final caption-only refresh uses human stage numbers/titles on the choice
screen. The normal and960×540 choice frames were inspected again; final
382checks pass with the same six actual audio cues.
