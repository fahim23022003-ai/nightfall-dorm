# Phase 9 real runtime evidence

Engine: Godot4.6.3 on Linux/X11, GL Compatibility/Mesa llvmpipe. Every PNG is
original production game rendering, not generated art or a mockup. The BEFORE
shot is the baseline commit; AFTER shots are isolated controlled scenarios.
Prepared temporary wallets and paid upgrades make the layout checks practical.
The earned45 source is unchanged; this is not a human or natural1→45 playtest.

| Capture | Original PNG |
|---|---|
| 01-fixed-slots | [Open original](screens/01-fixed-slots.png) |
| 02-free-preview | [Open original](screens/02-free-preview.png) |
| 03-valid-green | [Open original](screens/03-valid-green.png) |
| 04-invalid-overlap | [Open original](screens/04-invalid-overlap.png) |
| 05-three-flexible | [Open original](screens/05-three-flexible.png) |
| 06-expansion-unlocked | [Open original](screens/06-expansion-unlocked.png) |
| 07-six-custom | [Open original](screens/07-six-custom.png) |
| 08-midgame-layout | [Open original](screens/08-midgame-layout.png) |
| 09-moving-building | [Open original](screens/09-moving-building.png) |
| 10a-original-position | [Open original](screens/10a-original-position.png) |
| 10b-moved-position | [Open original](screens/10b-moved-position.png) |
| 11-sixteen-capacity | [Open original](screens/11-sixteen-capacity.png) |
| 12-sixteen-custom-L10 | [Open original](screens/12-sixteen-custom-L10.png) |
| 13-selected-L10 | [Open original](screens/13-selected-L10.png) |
| 14-relocated-live-combat | [Open original](screens/14-relocated-live-combat.png) |
| 15-late-layout-1080 | [Open original](screens/15-late-layout-1080.png) |
| 16-old-earned45-migrated | [Open original](screens/16-old-earned45-migrated.png) |
| 17-practice-fixed-pads | [Open original](screens/17-practice-fixed-pads.png) |
| 18-planning-overlay | [Open original](screens/18-planning-overlay.png) |

Capture10 has two originals: before selection and after the same-instance move.
Capture16 is the genuine canonical wave45 checkpoint after migration, with no
relocation or additional buildings. Its dead teammates remain correctly dead.
Other captures use prepared fixture resources, explicitly not an economy proof.

## Continuous input video

[Watch/download the uncut1280×720 video](video/native-input-silent.mp4).
[Actual internal Master audio](video/native-input-master.wav).
[Timeline, checks and state](video/timeline.json), [media info](video/media-info.json),
[audio measurements](video/audio-metrics.json), [engine log](video/engine.log).

Native XTest mouse/keyboard events are driven by a script, not a human. The video
starts through the real Endless menu, uses real build/move/expansion controls and
ends with ordinary wall-time combat ticks from the relocated layout. The room is
prepared occupied with3000Gold/700Electricity and Bed/Door2; NPC timers are held
for the construction demonstration and the Hunter is posed at a legal doorway.
There are no price changes, reduced Hunter HP, cuts or accelerated playback.
Simulation is frozen during the instructional build showcase, then the ordinary
preparation clock and live combat run at wall time. These preconditions are
captioned in-frame and in the source fixture.

The MP4 is88.208seconds,24fps,1280×720 and silent; real music/SFX were captured separately from Godot's
Master bus on a Dummy audio device. The movie predates the final move-cue origin correction (door → actual moved
building); the dedicated event-packet regression verifies that last correction.
No placement, movement or economy behavior changed afterward.
The audio and X11 clocks differ: synchronized
hardware playback and subjective listening are UNVERIFIED. No invented music is
added to the video. Exact durations are in media-info/audio-metrics.

Reproduce using `tools/capture_spatial_construction.gd`,
`tools/record_spatial_construction.gd`, `tools/spatial_performance.gd` plus the
[OS input helper](fixtures/spatial_xinput.py.txt) and
[recording wrapper](fixtures/record_spatial.py.txt). Fixtures are test scaffolding,
not runtime gameplay shortcuts. Recording wrapper paths describe this session.

## Test and performance evidence

- [Spatial model](logs/spatial-focused.log)
- [Actual rendered input](logs/spatial-ui.log)
- [Legacy saves, recovery and effects](logs/spatial-saves-effects.log)
- [Runtime screenshot checks](logs/spatial-render.log)
- [Incremental performance data](performance.json) and [log](logs/spatial-performance.log)
- [Legitimate earned46 continuation](earned46.json) and [log](logs/spatial-earned46.log)
- [Baseline Endless gate](logs/baseline-replay-endless.log)
- [Captured layout/source observations](observations.json)

[All124 effective regular gates](regular-results.json) and [raw logs](logs/regular/)
pass. [Initial and corrected attempt receipts](logs/attempts/) retain failures
that were subsequently repaired. [Historical-output restoration manifest](historical-evidence-restored.json)
records32 restored earlier outputs; new metrics are archived in regression-generated/.
Final import, scene/startup and separate-process profile logs are in logs/. Original historical
repository evidence is preserved; new copies live here. Windows verification,
human control comfort and long-duration hardware performance remain unverified.
