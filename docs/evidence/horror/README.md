# Phase 2 horror presentation audit

Agent D captured actual Linux Godot 4.6.3 OpenGL/Mesa llvmpipe frames on a
private Xorg dummy display. These are prepared fixtures that invoke production
hunter ticks and event consumers, not natural matches or Windows runtime proof.
The fixture is reproducible with `tools/capture_horror.gd` and the existing
`docs/GRAPHICAL_TESTING.md` Xorg setup. No Android tools were used.

Inspected final captures:

- `01-remote-alert-build-inspector.png`, 1280×720: “Mia is under attack · Room 5”
  replaces its earlier approach notification after escalation and fits below the tutorial. The build inspector,
  repair and lower room controls remain unobscured.
- `02-map-danger.png`, 1280×720: remote room danger ring, low door HP and actual
  damage indicator remain visible in the strategic map.
- `03-player-impact-cracks.png`, 1280×720: actual 22 HP hit displays `-22.0`,
  door HUD reads 33/150 after prepared 55 HP start, low-HP red/crack presentation
  and impact ring visible. Alerts remain separate from building controls.
- `04-door-destruction.png`, 1280×720: two rapid production hits remove the
  remaining 33 HP. The original 22 HP hit and these 33 HP now form one readable
  `-55.0` number for the same burst, with 0/150 HUD and destruction ring/shards.
  “Room 2 door destroyed!” replaces the player's earlier encounter alert.
  Agent D originally reported overlapping same-door damage labels; the main
  developer fixed aggregation, and this final recapture verifies one label.
- `05-remote-alert-960x540.png`: the 960×600 physical window uses a 960×540
  viewport under the project's aspect-preserving design. Remote alerts and the
  complete build inspector remain readable. The filename records actual image
  dimensions, not requested physical window dimensions.

No alert/control overlap or clipping defect in the inspected final frames. Alerts are
noninteractive and intentionally cover some left-hand map area, not building
buttons. Screenshots do not prove subjective horror quality, Windows input or
performance. A screenshot cannot by itself verify the full shake/fade animation;
automated lifecycle checks complement these rendered states.

`engine-mix.wav` is an actual AudioEffectRecord recording from this fixture.
`mix-analysis.json` reports stereo 44.1 kHz 16-bit PCM, peak 811/32767,
RMS 259.94 and zero clipped samples. It is non-silent with substantial headroom.
The engine diagnostics in `render.log` show 46 decoded streams, zero missing
assets, scream variations 1/2, door reaction/break/crack/hit, and proximity/danger
loop weights, with music stems started only three times. Four optional effects
were dropped by the intended concurrency guard. No personal listening verdict
is claimed: audible quality and native device playback remain UNVERIFIED.

The renderer logs an expected unsupported VSync-setting warning on llvmpipe;
there are no script/parse/error signatures and all five PNG saves returned OK.
Only the private display process started for this audit was stopped afterward.
