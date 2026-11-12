# Phase 6 independent rendered, audio and performance audit

## Scope and provenance

Agent D used actual Godot 4.6.3 / OpenGL / Mesa llvmpipe on a private Linux Xorg
display at 1280×720 and 1920×1080. All screenshots are unedited viewport output.
`tools/capture_phase6.gd` reuses existing production Game/UI/combat and earlier
capture helpers with isolated `user://phase6-render-*` profiles. It never opens
real user profiles and does not alter production. Prepared Master progression,
finite stocks, all stage records and controlled combat positions/times are visual
fixtures, not naturally earned economy, human skill or Windows verification.

The broad baseline covers menu, stages, three difficulty selections, shop,
all three inventory pages, ranks/perks, both achievement pages, Endless setup,
codes, Practice setup, cosmetics, focused siege and map overview on all five maps,
actual sealed campaign results, saved spin and a real-time Practice Reaper fight.
57 PNGs and 85 checks pass. Captured before the two narrow presentation fixes;
no old-phase evidence was overwritten. The initial prepared rank fixture set XP
without its matching highest-rank flag, so its Highest:Bronze text is a fixture
inconsistency, not a save defect; focused final ranks use consistent prepared flags.

Five contact sheets of all baseline families were inspected; representative
full-size 720p loadout, ranks, Legendary descriptions, Practice and later genuine
Reaper/telegraph/collapse/title frames were opened separately. Gothic typography,
material buttons, distinct green/violet/red difficulties, skull Endless action,
resource colors, descriptions and actual world variations remain readable.
No blocking navigation or clipping defect was found in these sampled pages.
The existing many repeated build pads and simplified actors remain artistic
limits; this is not human certification of premium art or subjective enjoyment.

## Findings and repairs

- **LOW, fixed:** ranks page said `1 slot; Master unlocks 2` even when two slots
  were available. Root now renders actual `perk_slots()` with correct plural.
  Actual Bronze/Master/Mythic pages at both resolutions verify 1/2/2 and fit.
- **MEDIUM, fixed:** the first real Reaper Scythe windup overlapped the fading
  awakening banner in the same top-center region. Before rasters are preserved
  as `baseline/reaper-overlap-{720,1080}.png`. Root gives actual boss attack/Surge
  counterplay priority over the decorative announcement. No attack timer, audio
  event or combat rule was changed.
- The first overlap-fix attempt accessed `c.model` on a draw Control, producing
  engine errors despite the stress assertions reporting 162/0. That run is
  explicitly rejected; log/JSON/rasters include `first-fix-error`. Root corrected
  the reference to existing `HorrorFeedback.last_model`, updated by the real model.
  Only affected stress/warning cases were rerun. No failed run is hidden or counted
  as accepted just because its checks or process exit returned zero.

The focused detail pass records 45/0 checks for ranks, actual Reaper
transformation/windup/impact, actual bed-contact survivor elimination/collapse/
remains, the existing opening and Created by Fahim card, bounded live combat and
12 actual Practice resets. Its manual screenshot inspection discovered the overlap;
its assertions alone did not establish that the raster was correct.

## Engine audio

`render-audio-baseline.wav` is real Master-bus PCM from a real-time temporary
Practice Reaper with successful Inferno and Overdrive activation after their
shared cooldown. Duration 12.260136 seconds, stereo 44,100Hz, peak0.02172852 full
scale, RMS0.004178366 and zero full-scale samples. `render-waveform.json` records
those measured values. Event diagnostics show 105 streams, no missing assets and
no pending critical queue. Two cumulative low-priority drops span the earlier
rapid prepared fixture transitions; this is disclosed rather than described as
zero-drop normal gameplay. No physical speakers or human listening were used.
Existing bounded voice budgets and four music players remain; intentional music
crossfades can have two nonzero weights, which is not duplicate music instances.

## Linux performance observations

Each matched preparation observation uses the same inherited map/renderer fixture,
a 0.35s warm-up and a 2.5s sample. Source after changes differs only in presentation
and release metadata. Shared host scheduling, prior page/material caches and short
windows limit comparisons; do not infer a frame-rate improvement from small deltas.

| Fixture | Baseline mean / p95 ms | Current mean / p95 ms |
| --- | ---: | ---: |
| 720p normal |35.552 /47.523|36.140 /49.221|
| 1080p normal |57.756 /71.658|57.143 /64.709|
| 720p Reduced Effects |37.550 /53.636|33.514 /40.883|

Material cache size is unchanged within each warm redraw window (45 baseline,
30 focused process). Root child count remains one. These are llvmpipe Linux
wall-frame observations, not native Windows/GPU FPS or a fresh hardware benchmark.

A separate 30-second real-time Practice fight stabilizes after initial deferred
UI deletion at 116 nodes and 2,317–2,320 objects; static memory is approximately
55.7–55.8MB, with 24 audio children. Twelve actual menu→Practice resets retain
that same bounded audio pool. This is finite runtime evidence, not proof of an
infinite session or every scene combination.

A denser sixty-second fixture separately fills all 16 Mansion pads with paid
Level 10 Needle/Arc weapons and actual branch upgrades, activates real Overdrive
and Inferno, uses normal effects for 30s then Reduced Effects. Its finite500k Gold/
500k Electricity and 1e9 target HP are intentionally injected stress inputs, not
natural economy or survival evidence. All upgrade payments, projectiles, combat,
effect rendering and audio use production code. Final acceptance and samples are
indexed in the manifest and accompanying `render-dense.json`.

## Unverified and limits

Native Windows import/executable/input/hardware, physical speakers, human-perceived
mix/horror/animation quality and long-session human balance remain UNVERIFIED.
Software-rendered screenshots cannot prove all animation frames or all overlapping
item/room combinations are perfect. No full art rewrite or new gameplay was added.


## Final acceptance

Four accepted assertion runs total **314 checks, zero failed checks and no engine
errors** (85 broad baseline,45 focused details,162 final dense stress,22 final
warning priority). The known unsupported-driver V-Sync warning is environment
specific and retained. There are88 actual PNGs:57 broad baseline,27 current and
four preserved defect/rejected-attempt rasters. Their dimensions and SHA256 plus
exact current production-script hashes are in `render-manifest.json`.

The final repaired warning was opened at both resolutions and Reduced Effects
on/off: Scythe counterplay text remains clear; the fading decorative title is
suppressed. Separate actual awakening frames show the announcement still plays
before any special attack.

Final dense run:1,480 frames in60 seconds; mean40.547ms /p95 53.947ms, peak19
projectiles and2,291 objects. Nodes remain116, audio children24; sampled objects
2,282–2,286 and static memory53.94–54.23MB over10–60 seconds, with presentation
records capped128. Actual shots reach1,097. Eleven low-priority audio events are
dropped by the existing bounded budget under deliberately dense stress; critical
backlog/missing assets remain zero. This is disclosed, not labelled lossless audio.

Only D's private owned Xorg was stopped. No production edits, Git commits/pushes
or new gameplay features were made by D. Remaining Windows/human/hardware limits
are unchanged.
