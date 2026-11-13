# Audio sources, licenses and implementation

## Current provenance

The current soundtrack and vocals include third-party **CC0 recordings**. They
are not entirely sample-free or performed by this project. The seven Phase 5D-3
scores use recorded VSCO2 Community Edition instruments; voice derivatives use
the credited human/creature recordings listed in the Phase 5D-3 section below.
Original project compositions and processing are distinguished from the source
performances. Source URLs, authors, license declarations and hashes are retained
under `tools/audio/source/`. The Phase 5D-4 sampled SFX sources and recipes are documented below;
final boss and new-building playback integration is still being verified.

The earlier generator descriptions below are **historical records**. Counts,
durations and claims that assets contain no third-party samples describe those
earlier versions; they do not describe replacements introduced in Phase 5D-3 or
later. Do not run an old generator over the current recorded assets when preparing
a release. Native Windows playback and subjective audio quality require human
verification.

## Phase 5D-4 recorded-source SFX (integration in progress)

Thirty CC0-declared recorded/designed source clips are retained with pinned
source URLs, per-file authors, license declarations and SHA256 hashes in
`tools/audio/source/wrath_sfx/SOURCES.json`. Credits and the CC0 text accompany
that directory. Original Freesound pages returned HTTP 403 in this environment;
direct-origin confirmation remains UNVERIFIED. The retained pinned mirror has
explicit per-file licensing metadata; no claim of recording these performers is
made. Do not remove the source notices from distributions.

`tools/audio/design_wrath_sfx.py` creates 122 documented derivatives (27 existing
cue replacements and 95 additions), combining recorded gunfire, metal, fire,
glass, doors, footsteps and creature textures. Each recipe records source offset,
rate, filtering, level, duration and output hash in
`assets/audio/wrath-sfx-derivatives.json`. These are sampled sound designs, not
oscillator stand-ins. Their subjective impact still needs owner/Adie audition.

The seven existing musical scores are byte-preserved against
`assets/audio/wrath-protected-score-hashes.json`. A separate original 48-second
Crimson score uses the existing credited VSCO2 CC0 instruments: 120 BPM,
394 arranged note events. Its generator and arrangement are
`tools/audio/compose_crimson_score.py` and
`assets/audio/crimson-score-arrangement.json`.

Early actual engine recordings verify Needle and Arc launches/impacts and build/
upgrade events. Paired Music-muted Master output remains nonzero; 18 PCM files
contain no full-scale clipped samples. These captures are not evidence of every
new boss cue, and RMS values do not establish perceived scariness or Windows
speaker balance. Final integrated evidence belongs in the Phase 5D-4 report.

## Historical original synthesis implementation

All 105 files under `assets/audio/` are original, locally generated PCM WAV assets. They contain no recordings, samples, commercial-game material, external music, paid assets, or downloaded sound libraries. Their reproducible generators are tracked under `tools/audio/`, including the base, boss, progression, item, advanced-item and Legendary sources described below. They use Python's standard library (`math`, `random`, `struct`, `wave`). No third-party audio license or attribution applies. These are original project assets; distribution follows the project owner's license.

Run the matching generator under `tools/audio/` from the checkout to reproduce its asset group. Noise is deterministically seeded. Files are mono, signed 16-bit PCM; base assets use 22,050 Hz and later item groups include 44,100 Hz as documented below. Tracked Godot import settings disable compression, preserving these samples. Runtime loads through ResourceLoader (including packed-resource remaps) and falls back to a raw WAV only when an import is unavailable; no export was created during this task. Generation limits peaks to 0.62 full scale. The soundtrack uses an original eight-part minor/dissonant phrase over beating low drones; the danger arrangement adds a heartbeat-like pulse and unstable upper partials. Continuous drone frequencies fit integer cycles within each loop; transient phrases fade at the boundaries.

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

## Phase 5B-1 consumable audio

Twelve original local PCM files generated by `tools/audio/generate_item_audio.py` extend the previous56: eight distinct item activations, reward reveal, effect end, shield impact and trap explosion. Existing waveforms and four music stems remain unchanged. Actual mixed-output inspection and event/reset evidence are in docs/evidence/items/README.md; no human or native Windows audition is claimed.

## Phase 5B-2A audio

Eight original PCM activation cues from `tools/audio/generate_advanced_audio.py` extend the previous68to76without replacing existing waveforms. Earned activation/reveal/explosion cues use the existing bounded priority/retry queue, preserving frame/polyphony limits. Actual mixed-output and cue/reset evidence: docs/evidence/advanced-items/README.md.


## Phase 5B-2B Legendary cues

Five additional original PCM WAVs come from
`tools/audio/generate_legendary_audio.py`: `item_time_freeze`, `item_reaper_seal`,
`item_guardian_heart`, `item_cursed_fortune` and `item_legendary_reveal`.
These deterministic, sample-free motifs use distinct descending temporal tones,
rising seal notes, a protective major chord, a darker fortune phrase and a
separate reward fanfare. They are mono 44.1 kHz, 16-bit PCM, 1.05–1.6 seconds.
The existing bounded critical-cue queue plays real activation events, including
automatic Heart, and the fixed Legendary receipt selects its reveal cue.
No music stems, voice limits or bus settings were replaced. Engine-output
verification and subjective/native Windows limitations are recorded in
`docs/PHASE_5B2B_LEGENDARY_REPORT.md`.


## Phase 5B-3 reward feedback

Six original generated PCM cues (`tools/audio/generate_rewards_audio.py`) cover
perk unlock, achievement unlock/claim, difficult-stage completion, stage-bonus
selection and Mythic perk unlock. New import settings explicitly retain lossless
PCM. All are event-driven through the existing bounded audio architecture;
actual playback and recording results are in the Phase 5B-3 report.


## Phase 5C-1 opening, practice and shop

`tools/audio/generate_onboarding_audio.py` creates nine original sample-free PCM
cues for running/breathing, lightning/door impact/shriek/whisper, tutorial steps/
completion and shop purchase. It also replaces the menu loop with an original
12-second piece. Run this generator after the base generator to retain the new
menu arrangement. Imports retain lossless PCM. Existing audio management gains
named-event cleanup for skipping and smooth music attenuation/critical ducking;
no second audio manager or additional music players. Tests and actual mixer
recording are documented in the Phase 5C-1 report.


## Phase 5C-2 haunted audio

`tools/audio/generate_haunted_audio.py` creates nine original lossless PCM cues:
two distinct death screams, normal Hunter/Reaper laughs, thunder/wind/rain,
prestige upgrade and survivor notice. Weather uses the existing Ambient bus at
lower gain; death/notification cues use Effects and bounded priority/serialization.
Per-room event guards prevent repeated screams/laughter, distant reactions retain
controlled prominence, and menu/practice transitions clear owned queues.
Actual engine playback and numerical mix evidence are in the Phase 5C-2 report.


## Phase 5C-3 positional clarity and tension pacing

No WAVs were added or replaced: all 105 existing original streams remain. World
voices are now positioned around the actual listener through the inverse canvas
transform, preserving left/right information after camera movement and zoom.
Footsteps, door impacts and Reaper anticipation have stronger bounded panning;
existing world-distance attenuation, voice budgets and critical priorities remain.

Read-only actual-threat pacing smoothly reduces competing music/ambience during
danger, restores it during relief and suppresses weather events during critical
player danger or genuine elimination. Independent Music/Effects/Ambient settings
and mute remain authoritative; menu/practice reset stale tension.

Independent focused audio checks pass 103 assertions; the existing asset/event
suite passes 281 assertions with 105 decoded streams. Actual Master-bus capture
through Godot AudioEffectRecord is stored under `docs/evidence/visual-overhaul/`.
Its 42.818-second stereo mix peaks at 0.03653 full scale, RMS 0.00415, with zero
full-scale samples. This validates nonzero engine output and no clipping in that
fixture, not perceived loudness, sound quality or physical Windows speakers.
Native Windows and subjective human listening remain UNVERIFIED.


## Phase 5D-1 archetype telegraphs

All105 original audio assets remain unchanged. Model-owned `archetype_warning`
events route through the existing distance-aware danger cue and voice/bus
architecture. Crusher's heavy wind-up, Stalker's first strike and Ravager's burst
opening therefore have genuine event-driven anticipation; shop success reuses
its existing valid cue. No new audio authorship or subjective/nativeWindows
listening claim is made. Prior critical ducking, positional projection, settings
and bounded playback budgets remain.


## Phase 5D-2 wave continuity and replay modes

No WAV assets were added or replaced. All 105 original streams remain decoded
and playable through the existing buses and bounded voice pool. Wave transitions
and rewards reuse genuine encounter/reward cues; actual Reaper, combat, item,
scream and laughter events retain their established routing.

An independently reproduced defect cut off a playing death scream and pending
laugh on immediate Continue. The same-run encounter reset now preserves those
voices and serialized queues while clearing obsolete boss warnings. The actual
Continue retest passes 14 checks, including preservation and eventual queue drain.

`docs/evidence/replay/render-realtime-mix.wav` captures actual master-bus output
from real-time Practice Reaper combat and valid Inferno/Overdrive activations.
The 18.297-second stereo PCM recording peaks at 0.035522 full scale, RMS 0.004455,
with zero full-scale samples. Runtime diagnostics show 105 streams, no missing
assets, peak 6/16 voices, no dropped events/backlog, and 24 audio nodes unchanged
across five mode transitions. This verifies actual nonzero engine playback and
bounded routing, not subjective loudness or physical speakers.

The separate accelerated earned-run recording is stress evidence and reports
1,015 low-priority dropped events; it is not evidence of normal real-time sound.
Native Windows, hardware audio and human listening remain UNVERIFIED.

## Phase 5D-3 — recorded instruments and voices

The owner's listening feedback supersedes earlier waveform-only acceptance.
The old opening had no enabled musical target; synthesized oscillator material
and stacked attenuation failed the requested recognizable musical experience.
Current work replaces four musical assets and adds intro/approach/Endless scores.
`tools/audio/compose_horror_scores.py` renders authored chromatic motifs, changing
harmonies, contrasting phrases and orchestral ostinati using actual piano,
violin/tremolo, glockenspiel, bass drum and timpani recordings. Full note events,
tempo, tonic and durations are in `assets/audio/score-arrangements.json`.
These are sampled instrumental arrangements, not a claim of live orchestral
performance or human approval of scariness.

Instrument recordings: VSCO2 Community Edition, Sam Gossner/Versilian Studios,
Simon Dalzell/Ivy Audio; sample editing Elan Hickler/Soundemote. Pinned upstream
`sgossner/VSCO-2-CE` commit440300901dfe9275fd84e0b7763af1f8443ae62e supplies
CC0-1.0 license, README, original sample paths and hashes retained under
`tools/audio/source/vsco`. No GPL TimGM soundfont was used.

`prepare_recorded_vocals.py` converts genuine recorded human/creature performances,
with cropping, modest filtering/rate changes, fades and headroom; it does not
create speech or screams from oscillator beeps. Derived event/source mappings
are in `assets/audio/vocal-derivatives.json`. Pinned source metadata/credits and
original downloaded files are retained under `tools/audio/source/vocals`.
Only explicit CC0 declarations were selected. The Freesound redistribution mirror
records original artists/descriptions/source URLs; independent credits corroborate
selected recordings. Original Freesound page access is blocked403 in cloud,
so direct-original-page license confirmation is UNVERIFIED; metadata provenance
and actual content hashes are retained for review rather than invented.

Final engine PCM, actual musical-state routing, audibility comparisons, queue
cleanup, default/saved-volume checks and listening controls are documented in the
Phase5D3 report. Internal playback cannot certify physical Windows speakers,
perceived mix or subjective vocal credibility/scariness. The accessible listening
room lets the owner audition those directly. Earlier synthesized-audio reports
remain historical and should not be read as the new soundtrack's provenance.

## Phase 7 Nightmare Rebirth layered cue

`nightmare_rebirth.wav` is a finite 4.8-second original mix of the existing credited
`reaper_laugh.wav`, `hunter_evolve.wav` and `weather_thunder.wav` derivatives.
Their original source/CC0 provenance above remains unchanged; no new third-party
recordings were introduced. `tools/compose_nightmare_audio.py` records offsets,
gains, resampling and fade envelopes. Existing voice limits, spatial playback,
saved mixer preferences and score transitions apply. Human horror audition is
UNVERIFIED. All new SVG rig parts are original vector work generated by the
checked-in authoring script, with no third-party visual source.

`nightmare_defeat.wav` is the separate finite 3.0-second final-form defeat mix of
existing `reaper_laugh`, `ghost_defeat` and `weather_thunder`, with its recipe in
the same authoring script. Evolved charge/release uses each archetype's existing
voice/weapon family; Reaper's separate death cue is retained.

## Phase 8 — Cinematic Nightmare recorded-source edits

No third-party downloads or new licenses. `tools/compose_cinematic_audio.py`
authors finite layered edits of the existing credited/redistributable source
recordings below; upstream provenance and attribution earlier in this document
remain applicable. The edits are original project arrangements, not new human
performances or oscillator-generated voices.

Role | Movement / charge / release source recordings
---|---
Crusher | door_hit / hunter_charged_warning / reaper_impact
Stalker | footstep / hunter_stalker_warning / hunter_stalker_feint
Ravager | hunter_ravager_dash / hunter_ravager_warning / door_crack
Phantom Witch | intro_whisper / reaper_charge / impact_frost
Electric Ghost | impact_shock / hunter_charged_warning / shot_shock
Storm Wraith | weather_wind / reaper_charge / weather_thunder

Each role has `cinematic_<role>_move` (0.8s), `_charge` (2.0s),
`_release` (1.4s). Time-stretched layers, delayed doubles and finite envelopes
vary by event; movement is rate-limited. Source sample peaks are controlled at
0.28 /0.58 /0.60 respectively before existing distance/bus attenuation.
Charge/release use existing critical-voice scheduling/ducking and expiry.
The existing `nightmare_rebirth` arrangement is revised to5.0s with slowed
hunter_evolve/reaper_laugh and delayed weather_thunder (peak0.70), and
`nightmare_defeat` to3.0s using ghost_defeat/reaper_laugh (peak0.45).
Existing seven recorded scores are unchanged. Saved audio controls still apply.
Actual engine capture/mix evidence and subjective-listening limitations are
listed in the Phase8 report; controlled source peaks alone do not prove audibility.

### Phase 10 — Every Night Feels Different

Six new original sampled arrangements use the already-vendored VSCO 2 Community
Edition orchestral recordings (CC0; see the Phase 5D-3 source/redistribution notes
and `tools/audio/source/vsco/`). No commercial songs or new downloaded sources.
Reproduce with `python tools/audio/compose_session_scores.py`. The generator
writes note-level events, distinct motifs/harmonies/meters and SHA-256 values to
`assets/audio/session-score-arrangements.json`; these are new compositions,
not pitch-shifted copies of the previous scores.

| Stream | Original title | Length | Musical role |
| --- | --- | ---: | --- |
| music_lantern | Lantern Lament | 60s | triple-meter menu lament |
| music_portrait | Portraits at Midnight | 64s | slower chromatic menu theme |
| music_dust | Dust Waltz | 60s | quiet preparation/ordinary Endless |
| music_siege | Broken Vespers | 48s | fast danger/approach ostinato |
| music_procession | The Last Procession | 64s | ordinary Endless march |
| music_opening_alt | An Unwelcome Guest | 19s | alternate opening/title score |

Stereo PCM16, 22,050 Hz, sampled strings/cello/piano/bells/timpani, circular
sampled reverb and 30ms de-click boundaries. Peak 0.58; no source clipping.
The opening is one-shot; the other five loop. Existing eight musical identities
remain present, including Reaper and Crimson. Runtime has 14 bounded music
players, created once, with shared crossfade headroom and existing warning
ducking. Master captures and numerical analysis are in
`docs/evidence/every-night/audio/`. These verify signal and transitions, not
human scariness, musical enjoyment or seam quality on Windows headphones.
