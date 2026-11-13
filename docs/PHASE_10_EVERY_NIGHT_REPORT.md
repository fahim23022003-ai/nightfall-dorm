# Phase 10 — Every Night Feels Different

Baseline verified: `work` at `6f9e6536ff767598ba455fc27e5bf6377515eea8`.
Recoverable local baseline tag: `checkpoint/phase10-baseline-6f9e653`.
Godot 4.6.3 official, Linux/GL Compatibility/Mesa llvmpipe. No agents used.
This phase extends the existing project; no AI, economy, item odds, damage,
range, upgrade prices, room-expansion progression or campaign rules were retuned.

## IMPLEMENTED

### Adaptive soundtrack and original music

Inspection found one fixed score per state and preview buttons, but no saved
soundtrack preference or session history.

`Soundtrack` owns a separate presentation RNG and small nonrepeat bags per musical
family. It saves only bag/last-track history to the profile path plus
`.soundtrack.json`, with temporary-file flush/rename and a validated backup.
Playlist history never participates in Challenge Codes or the combat RNG.

- Dynamic Shuffle is the migrated/new default; Classic preserves the original
  state selections. Manual Track applies only to ordinary gameplay, while opening,
  menu and boss identities retain appropriate music. Off silences music only.
- Settings → Soundtrack exposes the persistent preference, manual choices and
  current playing title. Listening Room audition stays separate and does not draw
  from the bag; all14 scores are available for audition. Existing volumes and mute
  remain unchanged. Off mutes the actual Music bus; explicit auditions temporarily
  override that playlist preference while still respecting global volume/mute.
- Six genuinely new sampled compositions: Lantern Lament 60s, Portraits at Midnight
  64s, Dust Waltz 60s, Broken Vespers 48s, The Last Procession 64s, and alternate
  19s opening An Unwelcome Guest. Original note/meter/harmony arrangements use
  existing CC0 VSCO2 recordings, not commercial songs or pitch-only variants.
  See [sources/licenses](AUDIO_SOURCES.md) and the note-level arrangement manifest.
- Opening family has two one-shot scores; menu three themes; calm two; approach
  two; danger two; ordinary Endless three. Original Reaper and Crimson remain
  dedicated. Even-wave preparation remains calm in Shuffle; urgent danger overrides
  ordinary Endless music. Victory settles toward the menu family.
- Crossfades retain existing warning ducking. Linear summed music gain is normalized
  during overlaps. Players are reused: exactly 14 music players, four ambience
  streams and the existing bounded effect pool. Pause stops playback without seeking;
  shutdown prevents further host-frame routing. Old paused models cannot freeze
  a returned-menu playlist.

### Range, selection and construction ergonomics

- Turret placement/movement and weapon inspection render a translucent real-world
  distance circle using the same `BuildingStats.weapon_stats` resolver as firing,
  including branch, concealment, room factors and Nightmare range modifiers.
- Works with camera scale and room orientation; fixed-pad Campaign/Practice
  inspection also supports range. O/button toggles it. No overlay during ordinary
  closed-inspector combat. Red means invalid placement or a temporary weapon lock;
  outside the ring is out of range. Hidden/ineligible enemies remain ineligible.
- Support inspection labels actual room-wide effects ROOM-WIDE and draws no
  fabricated weapon range. Existing door/Team/click targets remain above/nonblocked
  by this presentation-only drawing.
- Undo last move [Z] is single-use in the same preparation/intermission. It restores
  the same instance and position; no purchases, ledgers, cooldowns or resources are
  rolled back. Buying/upgrading/selling/expanding invalidates history; phase/wave,
  geometry, level/branch and instance guards reject stale operations. Undo clears
  the old move tween so rapid undo cannot briefly display the superseded position.
- Smaller deterministic core hit regions and nearest-core selection reduce adjacent
  selection mistakes. All 16 prestige cores were clicked successfully. Build toolbar
  shows used/capacity; existing snap/cancel/planning controls remain.

### Actual per-wave Endless report

`WaveMetrics` collects actual successful impact damage and hits, source-attributed
Flame DoT, actual door damage/healing, gross Gold/Electricity production, successful
support/defensive-item activations and encountered skills. Support production is
separate from damage. Shared item/reflection damage without a weapon source stays
Other; allied Hunter damage is separate. Damage to minions is excluded from the
explicit Hunter totals. Hit counts mean positive-damage projectile impacts, not
invented DoT hits. Healing includes continuous repair, manual repair, stations,
Plasma, repair/Feather/Guardian effects and rank rescue when actually applied to
this door. Upgrade HP-cap increases are not repair.

The compact Wave report button expands the existing intermission into the top-six
report; long skill lists have a compact summary and full hover text. Existing aid
and Omen decisions remain. Identity rows are retained after a sale/destruction and
bounded to256 (overflow damage remains Other); skill history is bounded to32.
Optional versioned telemetry is included in the existing checkpoint schema.
Legacy snapshots display unavailable history instead of inferred zero performance;
continuing starts fresh collection. Rewards and the gameplay RNG are untouched.

### Restrained atmosphere

Per-night presentation seeds vary moonlight, fog phase/height/drift, lightning timing
and distant ambient movement using the existing weather system. Reaper/door danger
and existing Omens receive subtle exterior color/fog identities underneath all
architecture. Low/Medium/High remain; Reduced Motion freezes weather movement and
Reduced Flashes/Effects suppress added flashes/tints. No new enemies, stats or
Omen consequences are introduced.

## TESTED

Final result: **zero unresolved failing gates**. All128 regular named gates pass,
plus the main136 assertions, four cross-process persistence invocations and fresh
startup. The four new/retained targeted suites are included in those128, not added
twice to that count.

| Focused evidence | Checks | Failures |
| --- | ---: | ---: |
| Session features, JSON migration and actual accounting | 75 | 0 |
| Audio routing, actual Off bus mute, preview and lifecycle | 18 | 0 |
| Fixed-pad range input and camera scaling | 11 | 0 |
| Existing Night Omens | 152 | 0 |
| Real rendered full16/upgrade/sale/undo/report scenario | 216 | 0 |
| Continuous native-input video | 48 | 0 |
| Actual report entry/back clicks and tooltip | 6 | 0 |
| Bounded performance/player lifecycle | 5 | 0 |

Final gate counts and per-suite evidence are recorded in
[evidence/logs](evidence/every-night/logs/) and the final gate summary.
Focused checks cover nonrepeat bags/history/preferences, JSON disk migration,
combat RNG isolation, real range/concealment/camera scaling, fixed-pad toggle,
move/undo validity/resources, actual impacts/DoT and production/repair accounting,
legacy telemetry, boss/Crimson priority, preview isolation, pause/resume, shutdown,
menu return and stable music-player counts. Night Omen152 checks pass after the
JSON fix. Relevant existing free-placement, earned continuation, transactions,
mode, item, economy, campaign, audio and scene gates are included in the regular run.
The optional extended balance matrix is not rerun: no balance formulas changed.

### Real report reconciliation

The captured full-health wave uses the normal model until legitimate wave clear,
with a disclosed prepared wallet and posed Hunter contact. It is not natural earning.

| Measured quantity | Actual value |
| --- | ---: |
| Hunter start HP → end HP | 4600.0 → 0.0 |
| Player + allied credited Hunter damage | 4600.0 + 0.0 |
| Sum of player building damage + Other | 4600.0 + 0.0 |
| Successful recorded building impacts | 9 |
| Actual door damage / repair | 58.08 / 58.08 HP |
| Income counter delta / displayed generation | 482.97253 / 482.97253 Gold |
| Gross power counter delta / displayed generation | 79.42897 / 79.42897 Electricity |
| Successful support/defense activations | 2 |

The L10 Needle supplied the recorded damage; many distant high-level weapons did
not reach this doorway. They correctly receive no theoretical DPS credit. A separate
focused actual burn-tick test reconciles DoT without adding fictitious impacts.
[Raw data](evidence/every-night/screens/reconciliation.json),
[real prepared checkpoint](evidence/every-night/screens/prepared-wave1-checkpoint.json).

### Twenty independent process sessions

These are separate Godot engine processes running the production AudioDirector and
opening/menu routes with one isolated shared history file, not twenty constructors
in one process and not twenty human playthroughs. All20 PIDs differ. No adjacent
opening or menu repeat; two openings naturally alternate under nonrepeat protection.

| Session | PID | Opening selection | Menu selection |
| --- | ---: | --- | --- |
| 1 | 329868 | music_intro | music_portrait |
| 2 | 329878 | music_opening_alt | music_lantern |
| 3 | 329888 | music_intro | music_menu |
| 4 | 329898 | music_opening_alt | music_portrait |
| 5 | 329908 | music_intro | music_lantern |
| 6 | 329918 | music_opening_alt | music_menu |
| 7 | 329928 | music_intro | music_lantern |
| 8 | 329938 | music_opening_alt | music_portrait |
| 9 | 329948 | music_intro | music_menu |
| 10 | 329958 | music_opening_alt | music_lantern |
| 11 | 329968 | music_intro | music_menu |
| 12 | 329978 | music_opening_alt | music_portrait |
| 13 | 329988 | music_intro | music_lantern |
| 14 | 329998 | music_opening_alt | music_menu |
| 15 | 330008 | music_intro | music_portrait |
| 16 | 330018 | music_opening_alt | music_menu |
| 17 | 330028 | music_intro | music_portrait |
| 18 | 330038 | music_opening_alt | music_lantern |
| 19 | 330048 | music_intro | music_menu |
| 20 | 330058 | music_opening_alt | music_portrait |

### Audio and rendered evidence

[Evidence index](evidence/every-night/INDEX.md) links every requested A–N subject,
actual720p/1080p screenshots, before/after, uncut video and actual engine PCM.
The video is 37.87s of scripted native OS input; encoded at24fps with
no cuts/speedup. The MP4 is silent; separate internal Master WAV is supplied without
claiming exact A/V sync. Prepared occupancy/wallet and frozen build showcase are
explicitly captioned; subsequent combat uses ordinary wall-time processing.

[Per-state priority and actual zero-signal pause](evidence/every-night/audio/priority-summary.json)
confirm the central pause interval is silent and dedicated boss tracks dominate
their steady-state segments.

The25s Master capture traverses menu/calm → Broken Vespers → Reaper → Crimson →
pause/resume → victory. Its peak is 0.16852, RMS
0.02748, with 0 clipped PCM samples.
Per-frame gain logs contain 596 overlap frames
and maximum summed music linear gain 0.67347.
The six source arrangements have0 clipped samples, bounded0.58 peaks and zero
PCM endpoint step. This verifies signal/mixing/de-clicking, not subjective seam quality.
Screenshots were inspected; range text was removed from the selected-core/crown area
because inspector stats already show range. Full-room and wave-report layouts remain
readable at the captured resolutions.

### Performance and preservation

30 warmup +240 measured frames per state on Linux shared Mesa software rendering:
range-off full16 inspector mean 38.20ms / p95
48.95ms; actual range-on mean
38.73ms / p95 48.86ms.
Nodes stay198 before/after each sample;200 state updates leave14 music players.
The measured extra mean is about0.53ms (1.4%) in this short current-executable sample,
within an uncharacterized shared-machine environment. A separate concurrent-launch
stress sample measured39.89ms off /45.88ms on and is retained in
`performance-concurrent-launches.json`; simultaneous engine launches confound its
attribution. The final pair uses a fixed cosmetic seed with no other Godot tests
running locally. Neither sample proves perceptual performance. No old-executable/Windows or
hours-long performance claim. [Raw samples](evidence/every-night/performance.json).

Canonical earned Hell wave45 is byte-preserved, SHA256:
`d20b729b9ccc804d0c1aa55874558da07c503d02cfa2455ee3a0f9b63f86eb1b`.
44 generated historical test outputs are archived separately then restored; ordinary
player profiles were not used. Existing optional checkpoint and preference migration
preserve inventory, progression, rewards and actual-spend ledgers.

## FAILURES AND FIXES

1. Range polygon repeated its closing vertex: real renderer rejected triangulation.
   Fixed to64 unique vertices and reran actual captures successfully.
2. JSON IDs become floats: strict string conversion rejected valid saved telemetry.
   Canonical integer comparison fixes genuine disk reload; JSON roundtrip and all
   Night Omen save/payout checks pass afterward.
3. New auto-import defaults used QOA while the existing soundtrack gate requires
   PCM16. New imports now match the original soundtrack; target/import gate passes.
4. Host drain frames after audio shutdown attempted to route an unloaded track.
   Terminal stream guard fixes the error; actual explosion/audio drain rerun passes.
5. Manual selection initially replaced the cinematic; ordinary even-wave music
   could mask urgent danger. Dedicated opening/boss and calm-prep/danger priorities
   now have focused coverage. A finished/paused model no longer freezes menu history.
6. Final UI inspection found the report label ignored mouse input, preventing
   its promised full-skill tooltip. The label now passes mouse input, and actual
   report-button/back/hover capture verifies the fix.
7. The older culling fixture assumed two newly constructed environments always
   shared a night seed. It now explicitly supplies the same presentation seed
   while retaining all1116 culling/RNG assertions; different nights remain varied.
8. Two native video-driver attempts chose the wrong popup row. The driver was
   corrected and the final continuous recording passes; these are automation
   failures, not evidence of human acceptance. Failed logs are retained in attempts.
9. Fast process probes drained audio for only0.05s and produced exit-reference
   warnings. Final independent probes use the existing recommended0.5s drain;
   the original logs are archived and the final20 launches are checked separately.

## UNVERIFIED / INCOMPLETE

Native Windows launch/audio hardware, human enjoyment/scariness, musical seam
perception, mouse comfort and long-session hardware performance remain UNVERIFIED.
The video/report are controlled production-runtime scenarios, not human playtests
or naturally earned full16 runs. Short Linux samples do not prove absence of every
possible long-run leak. Simultaneous upgrade announcements can still briefly overlap;
this phase does not replace the prior visual language or remake the HUD.

No requested feature is intentionally left as a mockup. There is no new gameplay
power, online system, mobile redesign, rotation tool or future phase in this batch.
Use the [Windows checklist](PHASE_10_WINDOWS_PLAYTEST_CHECKLIST.md) for human validation.

## Git delivery

Implementation checkpoint: `fa2de9ae14de93dc44b3ed0d75f46a93608b0df3`.
Verified production-source commit: `1705ff6d9f51ef9023efd367a18483144ed14613`.
It was successfully pushed to `work`; independent `git ls-remote` returned the same
SHA. See [source push receipt](evidence/every-night/source-push-verification.json).
No main ref or release was written. A following evidence/documentation commit
includes the final report, logs, screenshots, longer test-probe drain and fixed-seed
performance fixture; production gameplay code remains at the verified source commit.
The final delivery message records that final commit SHA, fresh remote equality
and clean working tree; this report cannot contain its own commit hash.

Modified production areas: Soundtrack/AudioDirector/Profile settings; SessionInterface
and existing Game/GameInterface; ConstructionControls/SpatialConstruction/BuildingStats;
WaveMetrics/MatchModel/RoomState/DefenseEffects/ItemEffects/EndlessRun/ReplaySnapshot;
ReplayInterface and HauntedEnvironment/DormPresentation. Existing scenes are reused;
no scene was rebuilt. New assets are the six scores and composition manifest, with
focused tests and reproducible capture/analysis tools.
