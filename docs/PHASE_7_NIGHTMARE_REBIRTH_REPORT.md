# Phase 7 — Nightmare Rebirth

Baseline: `6479803808cb8625f55aa9eeb547e62e2b658d48`, branch `work`. Single implementation owner; no agents, new runtime dependencies, main changes or release publication. Godot 4.6.3.

## IMPLEMENTED

### Independent Hunter evolution

Evolution is separate from combat level and the existing fifteen kill-earned buffs. Endless evolution is `clamp(1 + floor((wave-1)/5),1,10)`: level4 wave16, level7 wave31, level10 wave46. Campaign is the monotonic bounded maximum of `1 + stage_index + floor(active_Hunter_seconds/75) + floor(acquired_buffs/3) + Hell_bonus(1)`. No new blanket HP/damage/speed multiplier. Existing Endless combat-level cap and wave scaling remain.

Original / Awakened / Nightmare tiers cover levels1–3 /4–6 /7–9. Every level adds attached detail; level10 has a fourth authored form. Six roles have seven independently drawn parts each across four tiers: **168 original SVG parts**. Distinct headgear, skeletal plates, claws, cloth, coils and storm shapes preserve archetype identity. Independent feet, arm swings, head follow-through, cloth lag, contact shadows and direction-aware layering replace the previous single-body presentation. Actual warning, attack cooldown, suppression, hit and death state drive anticipation, recoil, guarding, hurt and collapse poses. This is layered 2D vector artwork, not a 3D conversion or hand-painted frame-by-frame animation.

The HUD displays real Evolution Level; combat level remains explained in the tooltip. Level10 manifestation waits until the living ordinary Hunter is attacking or moving within450px of the player. The 3.6-second reveal does not freeze the match or restore HP. The final silhouette emerges during the sequence; the signature is gated until reveal. `final_revealed` and evolution level persist in the existing optional evolution snapshot. Old wave45 checkpoints derive level9 immediately. Transient channels/reveal timers are not checkpointed. Practice and normalized Challenge retain their prior mechanics and naturally remain evolution1. Reaper transformation is separate and clears ordinary evolved attacks.

### Twelve new finite skills

Existing tactical and magical abilities remain. One new evolved skill unlocks at4 and a signature at10. At10, successful opportunities alternate between the two. New actions do not overlap original tactical/arcane launches or Reaper specials.

Hunter | Evolved skill | Level10 signature
---|---|---
Crusher | Seismic Faultline: four small physical contact pulses | Ossuary Cathedral: 4s physical damage received ×0.7, magic ×1.2; initial physical strike
Stalker | Lantern Snare: marked-room projectile speed ×0.8 for4s; magic strike | Hollow Oath: marked-door repair ×0.85 for4s; magic strike
Ravager | Blood Quills: physical retaliation15%, total capped at one ordinary hit, magic bypass | Carrion Rend: remove20% of an active temporary barrier, physical strike; does not destroy buildings
Phantom Witch | Hex Orchard: occupied target-bed income ×0.8 for4s, stored funds untouched; ice magic strike | Moonless Ritual: three ice-magic pulses over4s
Electric Ghost | Static Cage: marked-room turret range ×0.85 for4s, no permanent disable; electric strike | Grounded Overload: magic received ×0.7, physical ×1.2 for4s; electric strike
Storm Wraith | Pressure Front: projectiles within100px travel ×0.55 for4s | Thunder Convergence: three pulses, up to three valid visible intact doors within200px of the target door

Evolved warnings last2.0s, signatures2.8s. Cooldowns46/64s, plus6s Long Night or12s Hell; initial delay12s. Taking more than5% max HP during windup, Frost/Seal, invalid contact/target, death or Reaper transition interrupts. Target/contact validation also ends ongoing effects. Pulse channels hold ordinary attacks; finite stances/marks allow ordinary attacks without initiating a second special.

Initial strikes are at most0.8 ordinary damage and8% door max HP; pulses0.25 ordinary damage and3.5%. Hard/Hell apply0.9/0.8 on these added amounts, preserving existing base pressure. Existing typed mitigation, shields, absorption and reflection remain applicable. No universal immunity, resource deletion, recursive reflection, endless retaliation or permanent control. Stored cast counters and sequence are bounded.

### Presentation and audio

One actual-state pipeline draws warnings, charge, release, impact and short aftermath. Physical events use amber fractures/rings, curses use runes and trails, electric events use thick branched arcs. Impact branches are emitted only after positive actual damage to valid rooms. Witch trails follow the real projectile. Door HP is rendered above enlarged Hunter art. Reduced Effects lowers motion/ornaments/sparks; intermissions do not retain frozen attack effects.

Two finite sound layers reuse the project's credited recordings: `nightmare_rebirth.wav`4.8s and `nightmare_defeat.wav`3.0s. Their offline composition recipes are in `tools/compose_nightmare_audio.py`; provenance is appended to [AUDIO_SOURCES.md](AUDIO_SOURCES.md). Charge/release/impact routing reuses distinct existing physical/curse/electric samples and priority/ducking. Existing music files, source credits, audio buses, saved volume/mute and voice limits remain.

Actual engine Master capture with isolated music/ambience muted and Effects0.7 measured rebirth7.895s RMS0.001917/peak0.054657 and defeat3.437s RMS0.001250/peak0.007660. Both contain signal without clipping. This proves routing/output, not subjective scariness or adequate human-perceived loudness.

### All seventeen building systems

A reusable modular renderer covers all fifteen Catalog placeables plus bed/door. Original illustrations, selected treatment, branch glyphs and level badges remain. Every level adds/changes physical geometry: casing/feet at2, coils/tanks at3, braces at4, branch structures at5, expanded supports at6, platforms at7, assemblies at8 and role-specific late architecture at9/10. No price, cap, specialization, damage or refund changes.

Type | Role-specific physical evolution / activity
---|---
Needle | barrel supports, cannon assembly, real firing recoil
Arc | coil housings, conductive frame and firing arcs
Dynamo | gears, coils, capacitors and active production motion
Repair station | articulated tools and repair head; activity gated by real repair eligibility
Dream amplifier | reservoir/vault architecture and economy apparatus
Target relay | receivers and elevated radar dish
Flame | tanks and heat chamber; real attack feedback
Frost | enlarging crystal fan and support cage
Shock | ground coils and conductive structure
Auto repair | articulated paired arms and emergency module
Shield | dome supports and energy framing
Decoy | horned lure idol and receiver assembly
Mirror Barrier | diamond reflection frame
Plasma | paired energy reservoirs
Antenna | multiple elevated receivers
Bed | reinforced frame, posts, canopy and occupied-bed motion
Door | hinges, plates, branch crest, buttresses and arch

Existing paid upgrade events drive finite component reveal/fragments; level5/10 retain premium accents and sound. Inspection galleries render all170 appearances using the actual production renderer. Actual paid9→10 selection/reveal and rejected11 are captured separately. Distant/unobserved animation clocks are reduced; textures/geometry are cached, with no new per-frame scene entities.

### Night Omens

Blood Moon gains a visible moon and crimson Hunter aura; Blackout dims environmental presentation while retaining readable UI and adds machinery sparks; Cursed Walls marks the actual player door and reacts during its damage state. These begin/end with the existing active Omen. Decline remains normal. No Omen risk, reward, eligibility or persistence logic was changed.

## TESTED

Raw logs, screenshots, reproduction fixtures and movies: [evidence index](evidence/nightmare-rebirth/INDEX.md).

- New Nightmare gate: **132 checks,0 failures**. Covers progression, once-only reveal, old checkpoint derivation, all12 actual effects/expiry, counterplay, typed factors, persistence, Challenge preservation, registered artwork and audio duration.
- **14 existing focused gates passed**: evolution648, boss153, defenses972, combat2580 across5 maps, Endless28426, transactions284, migration190, Practice7505, Challenge1490 across6 processes, Omens152, visual polish50, items11203, adaptive readability19, audio782. Six affected gates were rerun after final mechanical fixes and passed. No tests disabled.
- Main runtime/input/capture fixture **214/0**; actual Omen accept/decline/clearance capture **57/0**; final guarding/hurt/death capture **16/0**.
- Earned progression/render fixture **61/0**. Original read-only earned wave45 checkpoint continued into **Hell wave46**, full Hunter HP180600. Four extra Arc turrets were genuinely purchased/upgraded to10 and two existing repair stations5→10 with existing funds. Real fixed0.1s simulation produced victory after **42.8 simulated seconds**, player alive, evolution10 reveal seen. No free funds, HP reduction or AI override in this continuation. **No evolved cast completed in this winning run**; all12 releases were instead verified in controlled integration scenarios. This is not a new run from wave1 or a human playtest.
- Rendered Linux/Mesa llvmpipe sample: **400 frames**,20 simulated seconds, mean frame wait38.532ms, p9548.069ms, nodes184→184, maximum projectiles3/events23/effect voices16;168 rig assets cached. This is a bounded software-rendering observation, not Windows60FPS or hours-long memory proof.
- Godot4.6.3 import/compilation passed. Actual1280×720 captures and1920×1080 galleries/intermission inspected. Original canonical checkpoint and historic evidence remain preserved. Tests used isolated profiles, not user saves.

## FAILURES AND FIXES

Initial import exposed nonconstant packed-array declarations and invalid external-constant array concatenation; cached variables and literal cue entries corrected them. Early gallery captures were clipped by gameplay camera transforms; CanvasLayer framing corrected them. A fixture-only missing horror-layer guard and orphan gallery nodes were repaired before final capture. Generic high-level cages obscured building roles; role-specific late structures replaced them. Door status was initially vulnerable to enlarged art overlap; foreground rendering protects it. Old45 evolution initially appeared1 before the next active tick; restore now derives9 immediately. Persistent new stances initially competed with tactical launches; action arbitration now prevents overlap. Final visual review added genuine guarding/death-weapon poses and removed intermission aftermath. Passing final evidence supersedes draft previews.

## UNVERIFIED

Native Windows launch/hardware frame rate, subjective fear/music loudness, human approval of animation/readability, and sustained natural Campaign/Endless balance across all strategies. No fresh1→46 human run was performed. Captures clearly distinguish prepared skill states, production art inspection and legitimate checkpoint continuation. MP4/GIF previews encode sampled actual engine frames; they are not continuous gameplay recordings.

## INCOMPLETE / remaining weaknesses

No requested code workstream is intentionally left as a mockup. Artistic limits remain: vector cutout rigs retain a stylized angular look; some Level10 rooms remain ornament-dense; the 1080p170-cell matrix needs zoom for fine detail. A short stable-node sample cannot establish long-session stability. Human Windows playtesting is still required before claiming final visual/balance acceptance.

## Delivery

Final commit: the Git commit containing this report (resolve with `git log -1 --format=%H -- docs/PHASE_7_NIGHTMARE_REBIRTH_REPORT.md`). The external delivery message records its exact SHA and actual verified push status, avoiding a self-referential commit hash. Target is existing private `work`; no main merge, release or next phase. Open `project.godot` with Godot4.6.3 and run normally; use isolated profiles for reproduction fixtures.
