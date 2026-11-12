# Gameplay, Hunter and HUD overhaul

Status: IN PROGRESS. This report is updated as implementation and independent checks finish; planned behavior below is not acceptance evidence.

## Starting state and safety

Started from clean `work` commit `457560dc4a8712dd644b7a7cdca509218fe83f70`. Recovery tag `pre-gameplay-overhaul-457560d`. Existing Godot4.6.3 project, its single authored main scene and script-built world/UI are reused. Initial inspection is recorded in [inspection](evidence/gameplay-overhaul/inspection.md). Baseline model133/0 and scene30/0 checks passed. Existing save profiles are not used for testing.

## Implementation contracts

The fixed large bottom region becomes a compact closed toolbar with an explicitly opened sliding drawer. Opening or closing is animated; repeated input and purchase transactions remain guarded. Attacks must not automatically dismiss the drawer.

Endless room growth follows3→6→8→10→11→12→14→16 slots. Positions are stable and append-only; visible floor/wall geometry, navigation and camera use the same room dimensions. Campaign layouts and previous saved structures must be preserved.

Physical/Magic is separate from elemental affinity. New Barrier reflection, Plasma storage and Antenna shielding share the damage routing used by actual attacks. Reflection is nonrecursive, storage is bounded, shields do not stack without limit. Existing actual-spend refund and discount rules apply.

The current Crusher already represents a physical tank, and the existing Grim Reaper is retained as an elite encounter. Existing archetypes and Phase5D4 boss mechanics must not be replaced by duplicate cosmetic enemies. New archetypes must add real telegraphed behavior. Original cartoon horror art and animation must react to actual combat states.

## Final acceptance

IMPLEMENTED: compact bottom toolbar and guarded0.26s sliding contextual drawer, checkpoint `7cbc337`. Existing actions retained; drawer stays open during attacks. Further workstreams remain in progress.

TESTED: baseline133/0 model,30/0 scene,16/0 rendered. HUD developer115/0 and independent rendered164/0 checks at720p/1080p passed; raw evidence retained. Independent adversarial input gate is finishing.

UNVERIFIED: native Windows execution and subjective human usability/art/audio judgments.

INCOMPLETE: implementation and final integration checks are ongoing.
