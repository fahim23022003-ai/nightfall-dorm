# Original audio sources and implementation

All 56 files under `assets/audio/` are original, locally generated PCM WAV assets. They contain no recordings, samples, commercial-game material, external music, paid assets, or downloaded sound libraries. Their complete reproducible sources are `tools/audio/generate_audio.py` and `tools/audio/generate_boss_audio.py`, written for Nightfall Dorm using Python's standard library (`math`, `random`, `struct`, `wave`). No third-party audio license or attribution applies. These are original project assets; distribution follows the project owner's license.

Run `python tools/audio/generate_audio.py` from the checkout to reproduce them. Noise is deterministically seeded. Files are mono, signed 16-bit PCM at 22,050 Hz. Tracked Godot import settings disable compression, preserving these samples. Runtime loads through ResourceLoader (including packed-resource remaps) and falls back to a raw WAV only when an import is unavailable; no export was created during this task. Generation limits peaks to 0.62 full scale. The soundtrack uses an original eight-part minor/dissonant phrase over beating low drones; the danger arrangement adds a heartbeat-like pulse and unstable upper partials. Continuous drone frequencies fit integer cycles within each loop; transient phrases fade at the boundaries.

## Stored assets

| Group | Files | Duration and purpose |
| --- | --- | --- |
| Music | `music_menu`, `music_calm`, `music_danger` | 12 seconds each; permanent loop players crossfade by menu, threat, distance and door vulnerability |
| Environment | `ambient_dorm`, `proximity_loop`, `generator_loop` | 8, 4 and 2 seconds; room tone, nearby-hunter pulse and operating dynamo hum |
| Combat | `shot_needle`, `shot_arc`, `impact`, `ghost_hurt`, `ghost_defeat`, `door_hit`, `door_crack`, `door_break` | Distinct 0.08–0.95 second attack, actual impact, ghost damage and door cues |
| Construction | `build`, `turret_upgrade`, `bed_upgrade`, `door_upgrade`, `repair`, `upgrade` | 0.30–0.45 second placement, category-specific upgrade, repair and completion cues |
| Economy | `income`, `electricity`, `purchase`, `failure` | 0.10–0.25 second gold, electricity, accepted purchase and insufficient-resource cues |
| Interface/progression | `button`, `menu`, `match_start`, `victory`, `defeat`, `rank`, `reward` | Distinct menu/navigation, start, terminal and progression feedback |
| Horror | `footstep`, `danger`, `breach`, `hunter_spawn`, `hunter_level`, `elimination` | Distance-sensitive movement and presence, warning, sudden breach, spawn, escalation and resident loss |

Every name above corresponds to a real `.wav` file. No placeholder audio paths or silent stand-in players are used. Runtime missing/decode failures are reported with the precise asset path and the unavailable cue is skipped safely. Existing decoded assets continue to work.

## Runtime integration

`AudioDirector` is an independent Node. `_ready()` calls idempotent `setup()`, which reuses or creates `Music`, `Effects` and `Ambient` buses. Six persistent loop players start once; music is not restarted by state updates. Sixteen reusable effect voices, a six-cue update budget (two slots reserved for critical cues), a bounded priority retry queue, noncritical voice stealing, category cooldowns, source-distance attenuation and conservative bus/voice gains limit excessive overlap. `shutdown()` and `_exit_tree()` stop playback and release stream references. For graceful application exit the host should call shutdown, allow 0.5 seconds for the audio thread to drain, and then quit. An immediate forced engine shutdown can report retained audio-playback references because it skips that drain; the bounded runtime voice count does not grow.

The host calls:

- `set_mix({music, effects, ambient, muted})` with normalized values. This controls independent buses; the host's PlayerProfile owns persistence.
- `reset_match(model)` after a reset/configuration, preventing stale observations and sounds from carrying across matches.
- `update_state(delta, model, mode)` once per frame. It observes actual door HP and hunter attack counts, bed/door/building levels, income/electricity, deaths, hunter level/state, and unique projectile combat-event IDs.
- `event(name, optional_world_position)` for explicit UI/purchase/rank/reward/outcome actions. Prefer `victory` or `defeat` for exact outcome cues. Supported aliases include `button_click`, `menu_navigation`, `menu_open`, `rank_promotion`, `reward_unlock` and `insufficient`.

Hunter proximity uses actual distance to the player's door (or awake player), actual target/state and current door-health ratio. Approaching raises ambience and a proximity pulse; attacking a damaged nearby door adds urgency. Moving away or dying reduces intensity smoothly. Spawn/level warnings are global so an offscreen hunter cannot suppress important escalation feedback. Door impacts also observe the attack counter, avoiding missed cues when a repair facility heals between snapshots. World sound effects beyond 850 pixels are culled and nearby effects are attenuated continuously.

`get_diagnostics()` exposes started music stems, current intensity/proximity, loop weights, decoded stream count, missing assets, effect counts, voice occupancy, budgets, dropped cues and current mix. Counts mean a real player was started, not merely that an action requested a sound. Ordinary effects may be intentionally throttled in dense battles. Terminal, rank/reward, breach and escalation cues are prioritized and retried if necessary instead of being permanently lost to a busy frame. Ghost defeat and match victory use distinct sounds.

## Verification and limits

`tests/audio_system.gd` loads real AudioDirector and MatchModel instances. It checks PCM presence/content/peak bounds, permanent loops and boundary continuity, buses, separate volumes/mute, transition weights without restarts, actual upgrade/build/repair/resource/impact/escalation/breach/outcome triggers, event deduplication, distance response, bounded polyphony, safe unavailable-stream handling, distinct waveforms and clean restart/shutdown. The current standalone test output is recorded by the coordinator after final integration.

Headless tests establish asset decoding, playback requests and control logic. They do not establish perceived musical quality, loudness on Windows speakers, or listening comfort. No human listening session is claimed. Graphical audio monitoring or acoustic capture, if performed independently, must be reported separately from these checks. Settings save/load is verified in the host profile/integration suite, not by this stateless director's standalone test.

## Horror and immersion extension (12 November 2026)

Nine additional original files extend the existing 37 without replacing their
waveforms: 'scream_1', 'scream_2', 'scream_3', 'door_reaction', 'sale',
'refund', 'insufficient_gold', 'insufficient_power', and 'eerie'. Screams
are locally synthesized vocal-like harmonic formants with deterministic breath,
pitch jitter and an amplitude envelope. They are not recordings or imitations
of any person. The source generator remains fully offline and standard-library
only. All new WAV import files retain uncompressed PCM, matching existing assets.

Effect voices now use pooled AudioStreamPlayer2D nodes with subtle spatial
panning and explicit listener-distance volume attenuation; menu/music/ambient
loops remain AudioStreamPlayer. Their shared frame/voice limits and conservative
gains remain in place. Sources beyond 850 world pixels are culled; closer remote
reactions are quieter than player-room reactions. Camera zoom does not determine
threat intensity. Model-owned, monotonic presentation event records trigger real
encounters, door damage, destruction, elimination and transactions. Snapshot
fallback remains for directly mutated diagnostic fixtures, with per-update event
keys suppressing duplicate playback when the authoritative record exists.

A first threatening arrival emits one of three scream variations. Per-room ten
second throttles, a two second global interval and an actively playing scream
check prevent a multi-room overlap. A destruction reaction interrupts a prior
scream and uses its own prioritized cue. Event IDs prevent every-frame repeats;
records from the terminal tick are consumed once even when the host switches to
the result screen. Match restart clears encounter throttles and event cursors.
Sale/refund cues are prioritized with bounded retry; resource failure cues have
separate tones and cooldowns. Occasional eerie environmental stings occur only
in a running match at deterministic intervals, not on every frame. Existing
music stems, smooth threat crossfades and persistent bus preferences are retained.

Verification uses actual Godot decoding/playback and checks every decoded PCM
sample for nonzero signal and peak headroom (maximum allowed 20,317 on signed
16-bit PCM), all 46 resource files, spatial effect voice playback, action/impact
triggers and preserved smooth transitions. Synthetic screams are functional
assets, but their subjective scariness, Windows speaker output and listening
comfort require human target-device review; no personal listening claim is made.

## Phase 4B Reaper audio

Nine additional original files are generated by `tools/audio/generate_boss_audio.py`: `music_reaper`, `reaper_ambience`, `reaper_transform`, `reaper_scythe`, `reaper_charge`, `reaper_surge`, `reaper_impact`, `reaper_hurt`, `reaper_death`. They use the same 22,050 Hz mono16-bit PCM format, deterministic local synthesis and uncompressed Godot import. New peaks are capped at0.58 fullscale. The original46 waveforms are preserved. The fourth permanent music stem crossfades on transformation without restarting players; boss ambience uses distance and disappears on results. See PHASE_4B_BOSS_REPORT.md for test/inspection limits.

## Phase 5A Mythic promotion

`mythic_promotion.wav` is an original synthesized prestige cue generated by `tools/audio/generate_mythic_audio.py`, with no samples or runtime downloads. It extends the existing55assets without replacing them. The actual rank-promotion observer selects it only for a new Mythic promotion; ordinary rank audio and four permanent music stems remain in place. See PHASE_5A_RANK_REPORT.md and docs/evidence/ranks for actual mixing and duplication tests.
