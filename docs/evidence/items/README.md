# Phase 5B-1 rendered item and audio evidence

Agent D ran actual Godot4.6.3/OpenGL/Mesa llvmpipe on a private Xorg display.
`tools/capture_items.gd` finished **92 checks, zero failures**, exit0.
There are **23 actual PNG captures**, not mockups. The fixtures use an isolated
profile with an explicit starting stock grant, prepared resources/time/HP and
controlled attack positions. They test presentation and production methods,
not natural-match balance or human win rates.

## Inspected behavior

Representative frames were visually inspected for inventory, wrapped descriptions,
original icons, victory/consolation wheel/reveal, active hotbar, all eight effects,
expiry, small-window radar and actual Retry activation. Checks use real keyboard
1/2 events, real hotbar clicks, actual settlement/claim, and actual shield/trap
combat methods. Captures include1280×720 and960×540 output.

- Inventory shows all8types, rarity, quantity, free equip controls and full function
  descriptions. Repair text initially clipped at498px versus432px; the developer
  wrapped it and added a tooltip. Final screenshot shows the condition in full.
- Victory results gate into the animated wheel; skip reveals the saved item.
  The quantity shown already includes settlement's reward. Continuing does not
  add it again. Consolation clearly shows its separate90/10rarity odds and one
  earned item versus victory's four. Per-item probabilities appear before reveal.
- Repair displays green restoredHP and crosses; gold displays a wobbling crate,
  rising lid/coin particles and150gold; battery displays80electricity with blue
  lightning. HUD resource and door values actually change.
- Radar displays live Hunter coordinates/target and countdown, with a world
  crosshair/pulse; information disappears on expiry. It remains readable at960.
- Shield has visibleHP/countdown, blue door ring and absorbed-hit feedback; the
  actual attack leaves doorHP unchanged while reducing shieldHP.
- Overdrive shows orange turret rings and projectile glow; actual firing logic
  is independently verified by Agent C rather than inferred from these images.
- Frost shows the Reaper with ice particles/ring and an active countdown. Trap
  shows its armed position and a real one-time220damage explosion. The feedback
  wording was corrected to identify damage rather than a positive resource gain.
- Expiry removes active timers/markers and shows an end effect. Actual Retry
  returns clean effects and plays a fresh repair cue, proving the same model
  object's reset does not suppress new item events.

The first run exposed missing activation audio after resetting the same model;
production now tracks the ItemEffects identity. Its initial log retains that
failure. Some initial activation checks also failed because the fixture manually
cleared cooldown without refreshing a disabled hotbar before clicking; the
fixture now refreshes UI, with no production bypass of actual consumption.
Final run passes all eight activation cues, repeated-input quantity checks,
shield damage absorption, trap trigger, radar expiry and Retry cue checks.

## Actual engine audio

`render-item-mix.wav` is an AudioEffectRecord master-bus recording from the final
run: stereo44.1kHz,15.418seconds, peak1071/32767, RMS183.02, zero clipped samples.
Measurements are in `render-audio-measurements.json`. It demonstrates functional
non-silent mixing through the engine using a Dummy output device; no human
listening session or Windows speaker test is claimed.

Final diagnostics load68streams with no missing assets. All eight distinct item
activation cues played, plus reveal, shield hit, explosion and expiry sounds.
Repair played again after an actual Retry. Four permanent music players remained
started once. Two ordinary competing cues were intentionally throttled in these
accelerated fixtures; item activation cues all passed.

## Limits

UNVERIFIED: native Windows import/input/FPS/audio, subjective excitement and sound
quality, natural human play, every room/screen composition and rapid multi-effect
scenarios. Dense prepared overlapping bursts can place several transient values
near a door; the hotbar and existing building/door controls remain accessible.
No full cinematic sprite animation or acoustic microphone capture is claimed.
Only the audit-owned Xorg process was stopped. No production files, commits or
pushes were made by Agent D.
