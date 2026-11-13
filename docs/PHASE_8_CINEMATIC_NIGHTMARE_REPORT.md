# Phase 8 — Cinematic Nightmare

Baseline `6971a18af50602e9bc80dc323bde0777d80c7c55`, existing `work`, Godot4.6.3.
One implementation owner, no agents or new dependencies. No main merge, release,
new combat features, stat changes or save reset.

[Honest baseline review](PHASE_8_VISUAL_BASELINE.md) ·
[Actual screenshots, video, raw tests and metrics](evidence/cinematic-nightmare/INDEX.md) ·
[Windows/human checklist](PHASE_8_WINDOWS_PLAYTEST_CHECKLIST.md).

## IMPLEMENTED

### Original shaded art and character motion

The168 seven-part Hunter layers were reauthored with curved anatomy, directional
material gradients, bone/cloth separation, joints, creases and restrained eye
light. Four actual silhouette tiers remain at1/4/7/10; intermediate levels retain
attached scars/veins. Crusher has asymmetrical armor, tusks and enlarged forearm;
Stalker an elongated jaw, thin limbs and shadow veil; Ravager organic foreclaws,
digitigrade haunches, a forward bestial head and expanding maw; Witch horns,
veils, spectral appendages and extra eyes; Electric Ghost broken floating limb
sections and a fractured energy skull; Storm Wraith cloud fragments and a final
vortex face. These are original layered2D SVG assets, **not actual3D models** or
external/generated gameplay mockups.

Read-only presentation state now smooths acceleration/deceleration, torso lean,
stride, cast anticipation and attack release/recovery. Independent head, feet,
forearm and cloth motion retain role-specific gait rates. Actual attacks trigger
recoil; hit/suppression/cast/death state drives reactions. Endless encounter
changes reset animation state so a previous Hunter's attack counter cannot
suppress the next one's recoil. Geometry, AI, navigation and collision are intact.
Directional mirroring/rear layering remain; full hand-authored eight-direction
animation is not claimed.

### Skill VFX and final transformation

All twelve existing Nightmare skills retain their exact mechanics, timing,
resource rules, counterplay and cooldowns. Their visual signatures differ:

Skill | Presentation identity (existing real effect unchanged)
---|---
Seismic Faultline | separated physical ground fractures / force pulses
Ossuary Cathedral | raised skeletal arch / physical armor stance
Lantern Snare | four converging lantern threads / projectile drag mark
Hollow Oath | enclosing cursed arch / repair mark
Blood Quills | radial quill silhouettes / actual retaliation impact
Carrion Rend | three directional claw slashes / barrier-cut aftermath
Hex Orchard | cursed petals / actual occupied-bed mark
Moonless Ritual | triple rotating sigils / elevated curse channel
Static Cage | vertical electrical ribs / marked affected turret cores
Grounded Overload | paired lightning horns / grounded charge core
Pressure Front | displaced wind crescents / projectile-pressure field
Thunder Convergence | elevated storm crown / branched channel and actual hit arcs

The original physical/magic/electric effect families are stronger and readable.
Positive-impact arcs only use real damaged-room events; local channel ornament
is not displayed as fictitious damage to additional rooms. DoorHP is still drawn
above large art. Persistent Hex feedback now marks the bed whose income changes,
not an unrelated door component.

The existing3.6s level10 event now coordinates a gathering pose, local darkness,
fracturing shards, a ground-pressure ellipse, silhouette swap and explicit
warning countdown. It does not add a cinematic pause, HP refill or new immunity.
Reaper is separate. Small event-driven camera impulses supplement existing
feedback; no new hit-stop or gameplay slowdown was introduced.

### Buildings and the16-slot room

**68 original shaded construction textures** cover four physical tiers for all
fifteen buildings plus bed/door. A shared modular renderer adds physical ribs,
reservoirs or branch assemblies within each tier, giving all170 level appearances.
Different roles use actual cannon arrays, conductive coils, burner tanks,
crystal fans, repair arms, economy vaults, receivers, shield housings, mirror
facets, plasma reservoirs, decoy horns, bed frames/canopies and door locks/plates.
Identical gold cages/crowns have been removed. Paid upgrades retain their genuine
selection/reveal feedback and sound.

Battlefield machines use a bounded54×67.5 texture envelope whose nontransparent
cores fit their placement pads. Bed/door use64×80. Selection retains the existing
corner outline and fixed badge lanes. A larger production-renderer preview lives
inside the intentionally opened bottom drawer; its input filter ignores clicks.
Exclusive branches retain physical receiver/radiator versus central-housing
geometry, icons/descriptions, computed stats and costs. All original production,
repair, recoil, aim and powered-state animation hooks remain tied to real activity.

The matched full16 before/after uses the same canonical earned45 checkpoint,
actual purchased upgrades and fixed camera. It is a frozen intermission art
comparison, not two different combat outcomes. The before uses preserved baseline
renderer code with the current HUD; it is not an edited image. Separate real
wave46 combat captures cover720p/1080p, all10 and a clearly controlled mixed7–10
inspection. Detailed preview replaces overlapping outward prestige decoration.

### Atmosphere, UI and quality settings

Bounded moonlight wedges, moving fog wisps and projected Hunter shadows add depth
without new Light2D/particle nodes. Blood Moon adds diffuse crimson halo/light;
Blackout retains accessible dimming and generator sparks; Cursed Walls has moving
actual-door glyphs. The existing Omen risks, payouts, selection and checkpoint
logic are unchanged. Decline returns normal presentation.

Urgent door/skill/transformation warnings own the warning row; secondary Hunter
progression is retained in hover details rather than repeating the same urgent
message. Resources, Team, bottom controls and existing shortcuts remain available.
Settings now expose Low/Medium/High plus separate Reduced Motion and Reduced
Flashes; Reduced Effects overrides quality. Low removes optional atmospheric and
branch detail while retaining critical target warnings/timing. Motion preferences
reduce rig/camera/door feedback; flashing preferences reduce local hit/weather
response. These do not change simulation. Optional new preferences migrate with
neutral defaults; no save-version bump or checkpoint format changes.

### Audio work and output evidence

Eighteen role cues (six × movement0.8s / charge2.0s / release1.4s) are original
finite edits of the existing credited recordings. The source table and licenses
remain in [AUDIO_SOURCES.md](AUDIO_SOURCES.md); `compose_cinematic_audio.py` records
the composition recipe. No new stock download, paid asset or synthetic oscillator
voice was substituted. The transformation arrangement is5.0s and defeat3.0s.
Existing recorded scores/vocals/credits remain. New charge/release events use
existing priority, expiry and music ducking; movement is rate-limited.

Review found new cue names inheriting the generic quiet gain. Explicit gains now
separate quiet movement(-22dB), charge(-11dB), release(-12dB), transformation
(-10dB) and defeat(-13dB), before unchanged bus/distance controls. Voices remain
capped16 and queued critical events expire. Continuous overlap capture records
actual music/effects/ambience on the internal Master bus; all six new role
warning/release routes occur and music ducking reaches0.48. Exact measured RMS,
peaks and zero clipped-sample counts are in `audio-metrics.json`.

The X11 movie and Dummy-driver Master WAV are supplied separately: their capture
clocks differ, so **frame-accurate audiovisual sync is unverified**. The game uses
the same real events for VFX and SFX; no artificially synchronized soundtrack is
presented as a device recording. Headphone audition, subjective scariness and
real Windows output remain unverified.

## TESTED

- **45 new focused checks/0 failures**: preference validation/persistence, legacy
  defaults, read-only rendering, complete cached art and event/priority assets.
- **20 existing selected gates pass**, including136 regular assertions,132
  Nightmare checks, evolution648, boss153, defenses972, combat2580 across5maps,
  audio782, Endless28426, transactions284, migration190, Practice7505, Challenge
  Codes1490 across6processes, Omens152, visual polish50, items11203, adaptive
  readability19, inputs4062/2009cases, five-map spectator1650, drawer130 and
  scene smoke33. Raw initial failures and effective final results are retained.
- Runtime capture234/0; dense-room/input93/0; accepted/declined Omen57/0;
  actual X11 settings/reload and component-mark capture12/0; final reveal/art
  capture23/0. Old registered rules, prices and snapshot components have no diff.
- Canonical earned45 continuation repeats the legitimate full-health **Hell46
  victory in42.8 simulated seconds** with actual paid Arc/repair upgrades and
  original funds. No free money, Hunter HP edit or path override. Rebirth occurred;
  no new skill completed in that particular winning run. Controlled scenarios
  separately prove every skill. This is not a natural1→46 or human playthrough.
- An uncut X11 movie records all six roles at normal wall time; each actually
  walks, attacks, receives a real test hit and completes an evolved/signature
  cast. The final Storm segment performs the legitimate progression calculation
  from an explicitly prepared campaign threshold, then its once-only reveal and
  signature. Prepared wallets/levels/cooldowns are declared in-frame/fixtures.
  Duration/frame counts and per-role wall/simulation times are in media metadata.
- Godot4.6.3 import and runtime compilation pass. Real720p/1080p screenshots were
  inspected; original user saves/canonical checkpoint and historical evidence
  were preserved. Extended balance matrices were not rerun: combat rules did not
  change. This is a focused regression batch, not a claim that every repository
  test or every strategy was rerun.

## Performance — Linux software rendering

Same environment, Godot4.6.3 GL Compatibility, Mesa25.0.7 llvmpipe/LLVM19.1.7,
1280×720. Paired400-frame dense46 samples include real simulation/UI/audio.
Before/after measurements and warmed early/six-archetype/full16 samples are in
the evidence index. The **mean improved but95th-percentile wait regressed**;
this is not an across-the-board performance win. Node populations are stable
(184 baseline,185 updated, the intentional inspection control adds one).
Full16 and each representative scene remain bounded; voices≤16, events bounded,
textures cached, no growing visual scene-node population in these short samples.

These are bounded render-wait observations on a shared software renderer, not
Windows hardware benchmarks, memory profiling, hours-long stability or60FPS
claims. Human Windows frame-pacing assessment remains necessary.

### Exact final measurements

Scene | Frames | Mean frame wait ms |95th percentile ms | Nodes start→end
---|---|---|---|---
Baseline dense46 |400 |45.774 |54.916 |184→184
Updated dense46 |400 |41.971 |57.140 |185→185
Full16 |200 |39.785 |51.489 |185→185
early preparation |60 |39.730 |49.947 |186→186
midgame crusher evolved warning/release |80 |40.288 |55.311 |186→186
midgame stalker evolved warning/release |80 |41.761 |54.081 |186→186
midgame ravager evolved warning/release |80 |41.824 |54.521 |186→186
midgame witch evolved warning/release |80 |40.732 |52.064 |186→186
midgame electric evolved warning/release |80 |39.453 |49.102 |186→186
midgame storm evolved warning/release |80 |37.796 |46.597 |186→186

Final uncut screen recording: **80.208s**, **1923 frames**,1280×720, approximately24 encoded FPS; engine per-segment rendered rates **23.54–25.88 FPS**. Simulation seconds match wall seconds within the per-frame observations. Scene resets are recorded and labeled.

- Actual `continuous-combat-master`: 78.483s, RMS 0.011135, peak 0.070465, clipped samples 0.
- Actual `rebirth-master`: 7.988s, RMS 0.005960, peak 0.054810, clipped samples 0.
- Actual `true-form-defeat-master`: 3.529s, RMS 0.002945, peak 0.019745, clipped samples 0.

The separate Master recording clock differs from screen time; do not treat the WAV as frame-synchronized footage. These metrics establish actual signal and output bounds, not subjective loudness or horror quality.

## FAILURES AND FIXES

1. First render review: raised weapons hid faces; side placement/size corrected.
2. New compact cores looked too small in inspection; gallery/drawer scale enlarged
   while pad footprints stayed bounded.
3. Early silhouette sheet: Ravager/Crusher shared too much outline. Organic
   foreclaws, digitigrade legs, forward head and distinct cloth/fragment anatomy
   were authored; affected real captures were refreshed.
4. Initial full16 fixture showed transient build dust over cores and a stale
   wave45 title after directly advancing the model. Waiting for effects and
   rebuilding the real HUD corrected the evidence fixture, not game rules.
5. Migration gate17 failures: strict whole-dictionary equality rejected three
   legitimate new optional preferences. The assertion now verifies **every old
   setting and each neutral new default**, rather than suppressing coverage.
6. Old HUD/spectator/scene fixtures left the welcome modal open, blocking actions
   by design. Debug state confirmed `welcome=true`. Graduate setup now explicitly
   closes it; no production onboarding bypass was added. All affected gates pass.
7. Initial settings-input script could not select the native popup with its End
   sequence; that left the popup intercepting the next click. Actual X11 mouse
   selection/toggle and reload checks pass. Keyboard gameplay is independently
   covered by the input/drawer/spectator gates.
8. Animation state is reset for new Endless Hunters; stale event impulses are
   ignored. Hex's feedback targets the actual bed. Audio gets explicit gains and
   priority rather than the generic quiet fallback.

## Visual quality gates — rendered inspection, not human approval

Gate | Result | Actual evidence | Specific remaining weakness
---|---|---|---
1 Six archetypes from silhouettes | PARTIAL | silhouette sheet and24-form sheet | roles differ more after revision; blind name-free human recognition untested
2 Level1 versus10 without labels | PASS (developer inspection) | six closeups / four-tier sheet | some intermediate1→4 changes remain subtler than7→10
3 Unmistakable level10 event | PASS (developer inspection) | continuous Storm segment / reveal frames | local presentation, not a full cinematic or3D morph
4 Dangerous signature preparation | PASS (developer inspection) | six signature warning PNGs | small text still needs normal-resolution owner review
5 Impactful actual release | PASS (developer inspection) | twelve release/aftermath pairs | close-contact effects stay local; no fake distant hits added for spectacle
6 Clear16-prestige combat | PASS (developer inspection) | matched full16 /720p/1080p live combat | small cores require the inspection drawer for fine detail
7 Sophisticated level10 buildings | PASS (developer inspection) | all17 L1/5/10 and170-cell matrix | common metal palette; within-tier changes are smaller than milestone machinery
8 Articulated creature movement | PARTIAL | uncut real-time movie / attack and hurt states | cutout joints, foot sliding and limited facing views remain visible; not full skeletal3D
9 SFX/VFX synchronization | PARTIAL | actual cast events, role counts, Master WAV | common-event timing verified; Dummy/X11 capture clocks and human mix approval unverified
10 Cleaner / more compelling than7 | PARTIAL | matched before/after and movie | spacing/shading improvement visible; fear, preference and final artistic acceptance require owner/Adie

PASS here is the implementation owner's visual assessment after inspecting real
renders, never an assertion that humans approved art because tests passed.

## UNVERIFIED / INCOMPLETE

Native Windows launch/GPU pacing, headphones/speakers, subjective horror,
name-free recognition and natural long-run human enjoyment remain unverified.
No programming workstream is left as a placeholder mode or static mockup; however
**final artistic acceptance is PARTIAL**, particularly fluidity, silhouette
recognition and emotional horror. The renderer is still layered vector2D and
cannot honestly be described as eliminating all cutout qualities. No normal-map
lighting, full3D or bespoke eight-direction painted animation is claimed.

## Files and delivery

Primary files: `nightmare_presentation.gd`, `building_evolution_visual.gd`,
`dorm_presentation.gd`, `map_presentation.gd`, `audio_director.gd`,
`cinematic_quality.gd`, `building_inspection_preview.gd`, `bottom_context_panel.gd`,
`interface.gd`, `game.gd`, preference migration and small reduced-feedback hooks.
Authoring generators, capture tools, original art/audio, focused tests and narrow
legacy-fixture corrections are included. Existing scene files/physics/nav were
reused; no replacement project was created.

Open the existing `project.godot` with Godot4.6.3 and run normally. The commit
containing this report identifies delivery (`git log -1 --format=%H --
docs/PHASE_8_CINEMATIC_NIGHTMARE_REPORT.md`). The final chat records the exact SHA
and independently checked `origin/work` equality/clean status after the push.
No main merge, release publication or later phase.
