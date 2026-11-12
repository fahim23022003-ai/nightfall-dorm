# Initial project inspection

Starting checkpoint: `457560dc4a8712dd644b7a7cdca509218fe83f70`, clean `work`. Recovery tag `pre-gameplay-overhaul-457560d`. Existing Phase5D4 reports and progress were read before implementation. No user profile is used for tests.

The authored scene is `scenes/main.tscn`: a Node2D driven by `scripts/game.gd`. The game builds its UI and world through script components. This is not a missing-scene project. Assets include 204 WAVs, 152 PNGs,142 SVGs and four fonts before changes; imported companions are also present. Existing art, sampled SFX and seven musical tracks are retained.

`MatchModel` owns gameplay transactions and legal damage routing; `RoomState` owns resources, actual spend, building levels and ownership; `HunterState`, `ReaperWrath`, `HunterEvolution` and `UndeadAgent` own the existing archetypes, boss phases, buffs and minions. `Catalog`, `BuildingStats`, `StrategyCatalog` and `DefenseEffects` share prices, previews and real mechanical effects. `ReplaySnapshot` validates checkpoints; `ChallengeCode` defines portable rules. Existing ranked/campaign progression is implemented in the profile, rank and stage catalogs and Game stage flow. Endless is a separate run mode with safe intermissions/checkpoints, not an extra campaign timer.

Existing Hunter roster is Crusher, Stalker and Ravager, plus an existing two-phase Grim Reaper encounter with summoned undead and final Crimson Domain. They must be extended rather than duplicated. Crusher already covers the proposed physical tank; Reaper covers the hybrid elite role. Existing weapon types include Needle, Arc, Flame, Frost and Shock; support machines include production, repair, shields and decoys. Existing physical/magical presentation is not yet a centralized defensive damage-type contract.

The prior bottom context implementation uses a fixed header at y460 and body at y506 in a1280x720 canvas. The panel consumes the lower260pixels, and camera framing reserves that space even while closed. This explains why a bottom-aligned implementation can still look central or obstructive. The new request requires a compact closed toolbar and an explicitly opened sliding drawer, preserving its existing transaction handlers.

Current map layouts already provide authored slots (10 or16 on supported room layouts), but do not implement the requested earned physical room growth. Endless expansion must use append-only slot positions, validate geometry and checkpoint data, and avoid silently changing campaign room capacity.

Baseline model test:133 assertions,0 failures, actual Godot headless execution; raw log `baseline-model.log`. Additional baseline scene/render receipts are retained separately. Initial architecture was independently inspected by the developer; save/geometry risks are independently reviewed by QA before final verification.

Root actual rendered inspection: `baseline-render/default-hud-720.png` shows the header strip crossing the map at y460–506 with the contextual body hidden, confirming the owner’s central-controls complaint. It is not enough to hide the body; every header widget must move to the closed bottom position. Fresh baseline scene30/0 and independent render16/0 also pass.
