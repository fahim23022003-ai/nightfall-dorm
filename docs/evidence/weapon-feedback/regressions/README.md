# Regression runs

Twenty-nine relevant suites completed with zero failed assertions,
reporting 41,100 checks. The weapon-specific suite covered physical
flight, model HP deltas, all offensive types, Wildfire's separate
targets, NPC contribution, reactive reflection, zero damage, canceled
targets, lane reuse, damage modes and a real Endless checkpoint. Other
suites covered projectiles, integrated combat, the Reaper, audio,
profile and save migration, construction, Story and the lobby.

The old audio-target suite still reports six Haunted Hall asset
assertions. The same six failures were reproduced on the pre-change
Phase 16 production source. Its weapon-target assertions passed. The UI
branch suite ran with a fixed 60 Hz clock and passed all 60 scenarios,
with a Godot ObjectDB exit warning after the checks. The embedded
Windows pack passed its separate validation.

[Weapon suite](weapon_feedback.log) · [Audio system](audio_system.log) · [Legacy audio comparison](phase16-reference-audio-targets.log) · [Endless](replay_endless.log) · [UI branch suite](phase5d4_qa_ui_branches.log)
