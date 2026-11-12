# Phase 5C-3 actual visual comparison evidence

## Baseline

Before images were captured from verified source `f2f69f383e562c0ba8b6178bc3ba8d012da31024`
before the production developer began editing. Actual Godot 4.6.3 OpenGL/Mesa,
private Xorg display, prepared isolated profile; `before-render.log` passes
**51 checks, zero failures**, producing **33 PNGs**. No existing player profile
was used. These are rendered production methods and state, not mockups or natural
human matches. The scene fixture manually supplies Master XP, stage records,
item stacks and selected perks to expose the relevant UI; it does not claim these
were naturally earned or that its synthetic historical statistics are a player save.

The paired capture script creates the same states for both phases: menu, stages,
permanent-perk/difficulty preparation, shop, three inventory pages, ranks, two
achievement pages, settings, preparation/approach/siege/danger/pause/death,
five worlds, paid Level 10 Arc, legitimate result settlement and Lucky Spin,
practice panel, opening/title, plus menu/shop/loadout/gameplay at 1920×1080 and
Reduced Effects. Primary captures are 1280×720. Source PNGs are unedited engine
viewport images. Existing haunted environments already appear in the baseline.

## Baseline findings from actual frames

- Main menu, gameplay HUD, shop, inventory, ranks, settings and pause share large,
  uniform blue/slate filled surfaces and identical rounded frames. Current text
  contrast is generally good and should be preserved.
- Shop cards expose real prices, balance, stock and effects, but their flat fills
  and bright multicolored outlines lack a clear metal/glass material identity.
- Rank/loadout screens have readable perk explanations but little visual depth.
  Most cards/buttons repeat the same surface regardless of function.
- Rooms use repetitive checker flooring and similar pad rectangles. Props and
  actor silhouettes are recognizable, but decoration/lighting lack enough local
  variation to communicate the requested Gothic Industrial treatment.
- The existing exterior trees/creatures and Level 10 crowns are present. This
  task must integrate those systems rather than count them as newly absent.

## Rendered redesign review

`after-final.log` passes **100 checks, zero failures**, rendering the original
33 paired states plus 15 supplementary views. A targeted detail run
(`after-detail.log`, **26 checks/zero failures**, zero engine errors) advances the actual model to a
visible mid-transformation pose and adds a real automatic Guardian rescue with
9,999 stock and 123,456,789 Gold/Electricity. There are **50 after PNGs** total. Agent D inspected the major screen
families individually, including all inventory/achievement pages, settings,
results/spin/pause/tutorial/cinematic/title, 720p/1080p and Reduced Effects,
all five map overviews, focused sieges, charged warning and Reaper states.

Observed improvements and refinements:

- The main menu now has an original cracked-window Gothic facade, wall cladding,
  stains, fog and distant Hunter. Its licensed serif wordmark and engraved green
  primary action distinguish it from secondary controls. D requested stronger
  primary hierarchy and facade depth after the first actual comparison; both
  were refined and recaptured.
- Main and secondary UI use worn, shaded metal/glass surfaces with quiet label
  centers, muted antique-gold headings, grouped resources and restrained alarm
  materials. Shop prices, balances, owned stock and purchase feedback remain
  readable. Actual injected mouse input purchases once, ignores an OS duplicate
  double-click and permits a later ordinary purchase.
- All three inventory pages and both achievement pages fit. Slot hints, rarity,
  stock, active duration and shared cooldown remain legible with 9,999 stock.
  Gold and Electricity compact separately at large values, preserving exact
  values in tooltips. No new label overlap was observed in these actual frames.
- Each map retains its real layout and distinct palette/props. Rooms have cracked
  floor seams and local themed furnishings; corridors have worn rails, marks,
  lamps and debris away from the build pads. Damage and breach leave bounded,
  event-derived marks; the eliminated room dims and its genuine survivor notice
  remains readable. Existing weather/creatures/elimination artwork is preserved.
- Actual path movement produced rightward and leftward Hunter facing. Pausing
  holds position, heading and Hunter animation; actual Time Freeze does likewise,
  then expires and movement resumes on a valid selected route. Charged warning,
  policy-triggered Reaper transformation, scythe anticipation/impact and breach
  produce real model events and distinct visual poses. The Reaper uses its
  distinct robe and animated scythe rather than the normal Hunter scaled up.
- D found a real theme-inheritance omission in tutorial Recover/Exit and opening
  Skip/title Continue controls. B applied the reusable theme to onboarding and
  the final actual frames confirm the fix. The focus view also now suppresses a
  decorative map title formerly clipped beneath the top HUD; overview keeps it.

Remaining relatively flat elements are the repeated functional pad grids,
simple exterior silhouettes and retained colorful survivor/bed sprites. They
remain recognizable and do not obstruct combat. This review establishes visible
material, hierarchy and atmosphere changes; it does not establish a human-rated
art-quality score. Room-prop variety is deliberately bounded rather than cluttering
pads or changing collision layouts.

Additional observed issues were fixed and verified in the final targeted run:

- The temporary Legendary flourish originally shared the left notification area.
  Its bounded right-side anchor now leaves the notice, danger ribbon and controls
  clear at both 720p and 1080p; actual Time Freeze plus an actual approach notice
  was rendered and inspected at both resolutions.
- A disabled Legendary initially said READY / USED; it now says USED. Duplicate
  AUTOMATIC / AUTO text squeezed the Guardian icon at maximum stock; concise
  AUTO lethal keeps the original icon visible. Actual slot bounds and measured
  text width now preserve icon space with 9,999 stock.
- The focused Lab world-door HP label grazed the danger ribbon; it now renders
  below it. The real HP value, Hunter and repair control remain readable.

No confirmed blocking visual defect remains in the reviewed fixtures. Subjective
quality and performance on untested hardware remain unverified.

## Fixtures and evidence limits

The paired practice screenshot intentionally preserves the original prepared
fixture: it manually sets objective step 3 without claiming a room first, while
its top HUD still shows step 1. This discrepancy is fixture state, not an observed
normal tutorial progression failure. `extra-genuine-room-tutorial-panel.png`
separately shows a genuinely claimed room with matching objective/HUD step 3.
Likewise the synthetic XP fixture has no historical highest-rank statistic; the
rank screen's Bronze historical record is not evidence of a production save bug.
Random spin icon pose/reward can differ; the visible distribution and legitimate
settlement/claim paths are the same.

An initial supplementary assertion incorrectly required movement immediately
after Freeze even though the Hunter had validly arrived at a door and entered
ATTACK. `after-fixture-review.log` retains that failed fixture run. The final
fixture checks timer expiry/animation independently, then explicitly selects a
reachable MOVE target and verifies navigation resumes. This was not a gameplay
regression. `after-initial.log` and `after-pre-onboarding-polish.log` preserve
intermediate successful render reviews; final screenshots supersede those views.

## Audio and performance

`render-visual-mix.wav` is an actual Godot Master-bus stereo recording via
AudioEffectRecord on the Dummy output driver, not a fabricated sound sample.
`render-audio-analysis.json` records duration, nonzero peak/RMS and full-scale
sample count. Final diagnostics expose **105 loaded streams, no missing assets**,
and actual footsteps, door reactions/breaks, survivor scream, Hunter/Reaper laugh,
transformation/scythe, item, shop and victory events. Bounded low-priority event
suppression is reported, not hidden; no pending critical events remain. This is
engine mixing evidence, not subjective headphone or physical speaker validation.

`render-performance.json` describes the final capture's warmed short controlled
Linux/Mesa software-rendering frame observations at 720p,1080p and Reduced Effects.
Material cache size remains constant during each repeated-redraw sample. Root
child count is only a bounded fixture observation, not proof of zero memory growth.
Matched baseline/after perf-only runs are recorded in `performance-baseline.json`
and `performance-after.json` (six checks each). The same isolated hell-stage-1
occupied-room preparation scene warms for 0.35 s, then measures 2.5 s per resolution.
Baseline is a clean temporary export of source `f2f69f3`, not a branch switch. Intermediate short initial and post-culling sequential observations were:

| Mode | Baseline mean / p95 ms | Initial after mean / p95 ms | Intermediate post-culling mean / p95 ms |
| --- | --- | --- | --- |
|720p normal|31.337 / 38.637|36.333 / 45.890|38.557 / 62.488|
|1080p normal|47.561 / 51.940|55.760 / 70.046|50.611 / 58.842|
|720p Reduced|32.911 / 50.727|32.173 / 38.896|29.915 / 34.925|

B added bounded offscreen cosmetic culling after the first matched observation;
all model/presentation updates continue and the all-five-map overview fixture is
refreshed to check visible geometry remains present. Initial results are preserved
in `performance-after-pre-culling.*`. The second sample improved 1080p/Reduced,
while 720p normal exhibited larger timing outliers. Intermediate post-culling mean times versus the
single baseline are +23.0%, +6.4%, and -9.1% respectively. These variable normal
samples show software-renderer cost; they do not support an unqualified
no-performance-regression claim or isolate the exact cause. Across unchanged
after render passes, 720p normal observations varied roughly 26–30 fps.
After material cache 18→18 remained stable. These
shared-host short samples cannot establish native Windows frame rates or replace
hardware profiling. The original BEFORE screenshot pass did not record timings.

The variance prompted a focused **8-second-per-case** sequential comparison,
recorded in `performance-baseline-long.*`, `performance-after-long.*` and
`performance-comparison-long.json`. B also removed a redundant per-frame door
style override, applying it only on danger-state transitions.

| Mode | Baseline mean / p95 ms | Final mean / p95 ms | Mean change |
| --- | --- | --- | --- |
|720p normal|31.925 / 43.625|31.279 / 40.310|-2.0%|
|1080p normal|48.073 / 55.009|46.365 / 54.234|-3.6%|
|720p Reduced|29.313 / 36.804|28.265 / 34.047|-3.6%|

The final long run exits 0 with six checks/zero failures and **zero engine errors**;
its warm material cache stays 18→18. It does not reproduce the earlier slower
normal-mode samples. This supports comparable performance in this controlled
software-rendered fixture, not a guarantee for Windows hardware or dense endgame.

During the first long after run, log inspection caught three genuine missing
`danger_skin` metadata errors on initial match creation, despite a six/zero test
counter. `performance-after-long-pre-meta-fix.*` preserves that error-bearing run.
B added an explicit metadata-existence guard and reran actual UI startup; the
final long run is clean. Test counters alone were not treated as sufficient.

Native Windows import/run, physical Windows controls/display, human play,
subjective horror/art/audio quality and hardware FPS remain **UNVERIFIED**.
The independent QA and full regression results are in the parent phase report.
The D-owned private Xorg process 81047 was stopped after display work; no other
display process was stopped.
