# Phase 5D-4 Audio/SFX specialist checkpoint

## Implemented

`AudioDirector` plus sound-only `wrath_audio_catalog.gd` preserve existing event
identifiers while adding explicit machine, Hunter, evolution, minion and Reaper
routes. This component never chooses targets, applies damage, changes inventory,
saves progress or consumes gameplay RNG.

- 30 pinned, explicitly CC0-declared recorded/designed sources supply physical
  rifle transients, metal/wood/door impacts, blades, glass, fire, electrical
  texture, clicks and creature vocals. Source catalog, authors, original URLs,
  mirror commit URLs, hashes, generic CC0 legal text and credits are retained in
  `tools/audio/source/wrath_sfx/`. Direct original Freesound pages remain blocked;
  direct-original license confirmation is UNVERIFIED. Mirror maintainers are
  not claimed to have performed every recording.
- 122 cue recipes render 116 distinct WAV hashes. Six intentional aliases keep
  common UI confirmation behavior consistent; this is not a claim of 122 unique
  original performances or 122 independently human-approved sounds. Recipes
  include 27 physical replacements for legacy effects and 95 new identifiers.
  Exact source cuts, rates, layers, gains and derived hashes are in
  `assets/audio/wrath-sfx-derivatives.json`.
- Needle/Arc and Flame/Frost/Shock have source-specific shots and impacts,
  exclusive-branch variants, and L8+ body variants. New support machines have
  placement/activation cues. Bed and door upgrades use distinct arrangements.
- Soft hover/confirmation/failure/Shop/reward sounds avoid combat explosions on
  ordinary clicks. Genuine recorded survivor/Hunter/Reaper voices remain, with
  bounded category gain adjustments so transients and voices are not routed at
  the old blanket -20dB level beneath the music.
- Seven existing score WAVs are byte-identical to Git `d507600`; a separate
  48-second/120BPM sampled VSCO climax arrangement has 394 authored note events.
  `music_crimson` starts once per genuine domain transition, crossfades existing
  music and is exposed for the listening room. Its source arrangements/hashes
  are in `crimson-score-arrangement.json`. Subjective composition quality is
  UNVERIFIED.

## Bounded mixing and cleanup

There are 204 decoded streams, 12 loop players (eight music/four ambience) and
16 pooled effect players, for 28 players total. No player is created per shot,
minion, preview or evolution. Five weapon-family cooldowns coalesce dense
repeated fire without using model RNG. Critical voices preempt noncritical ones;
priority belongs to each live pooled voice, not an outdated name alone.

The generic critical queue caps at 24 and expires obsolete warnings. Ability
activation/end, boss death, new encounter and scene lifecycle clear owned
telegraphs. Existing Music/Effects/Ambient settings and mute remain authoritative.
Music is ducked during critical cues rather than stopped/restarted at every hit.

Death/evolution reactions use a separate bounded six-victim queue: real death
voice, evolution sting/category, then the next death. They cannot expire behind
a long recorded scream. Actual victim-room metadata is consumed once, duplicate
reactions are rejected, laughter yields until the reactions finish, and menu/reset
cancels pending context. This is transient audio state, not new save data.

## Accepted focused tests

`audio-final-test-receipt.json` indexes final accepted runs; older PCM receipts preserve earlier checkpoints:

- `phase5d4_audio.gd`: **782/0**, source/hash/decode/registry checks, exact seven
  protected score hashes, branch/high-tier differentiation, pool/queue bounds,
  expiry, saved volume/mute, actual cue-player starts and internal Master PCM.
- `phase5d4_audio_explosion.gd`: **9/0**, real configured Practice, actual keyboard
  deployment and ordinary Hunter navigation trigger exactly one sampled trap
  explosion, decrease actual HP and preserve permanent profile bytes. Captured
  Master 13.746s, RMS0.005275, peak0.052094, zero full-scale samples (Music0,
  Effects0.65). Standard temporary practice budget; no actor position/HP injection.
- `phase5d4_audio_lifecycle.gd`: **13/0**, terminal records are observed once,
  death/evolution survives result, obsolete warnings and domain stop, explicit
  menu clears combat queues and retains Listening Room preview functionality.
- `phase5d4_audio_reactions.gd`: **5/0**, actual pooled voice identity is preserved
  across another room's door breach and ordinary encounter vocals yield to death.
- `phase5d4_audio_targets.gd`: **209/0**, main Hunter ID1/Undead IDs>=2/Reaper
  dispatch, distinct bed/door audio and all 204 imported streams explicitly PCM16.

All accepted processes exit0 without engine errors/warnings. The seven protected
hashes were also compared independently with actual Git object bytes, not only a
newly written manifest.

Direct event-unit recordings at Effects0.65/1.0 with Music0 demonstrate meaningful
internal output and no full-scale samples; exact current values are in
`audio-unit-metrics.json`. A separate 10.5-second temporal unit recording contains
two real prerecorded death streams and two evolution/category pairs without
playing-state overlap. These use synthetic routing records and actual stream
players, **not** a claim of actual game kills. Sequence timestamps use unit-fed
AudioDirector delta; PCM length is the measured recording duration.

D independently captured actual Needle/Arc combat and input-driven building/
upgrade transactions with normal music versus Music0 (76 checks). That early
capture is gameplay proof, distinct from the direct unit recordings. Its source
snapshot precedes final PCM-import policy and pooled-reaction fixes; final actual
new-machine/boss/domain/max-mix capture remains a separate integration gate.

## Failures and corrections retained

- Original routing at `d507600` permits a pooled encounter reference to stop and
  reuse a player currently carrying a death scream; a later encounter can also
  overlap that death. Frozen source reproduction returns six checks/two expected
  failures (`audio-pooled-reaction-baseline-confirmed.log`). Corrected routing
  returns five/0; the extra baseline check compiles the frozen source.
- The first guard assertion checked only `playing`, which can be true after the
  pooled player is reused for `door_reaction`; final assertions also check the
  actual stream identity. The initial partial finding remains in the logs.
- A run while B's new `DefenseEffects` class was not registered produced compile
  errors despite a misleading five/0 counter. It is explicitly rejected in
  `audio-pooled-reaction-core-import-blocked.log`, not an acceptance pass.
- Godot defaults new imports to QOA. Legacy PCM-data checks correctly exposed the
  format mismatch. All 96 new imports now use PCM16 consistently with existing
  audio; raw source recordings and old seven score bytes remain untouched.
- Bed/door initially shared a recipe. Their important interactions now use
  different wood/light-metal versus heavy iron arrangements.
- The initial contract treated main Hunter ID0; B's actual entity registry uses
  ID1 with Undead>=2. D identified the mismatch, now covered by the target suite.
- The first target fixture assumed a dormant Hunter was attackable. The producer
  correctly refused it; the routing fixture now explicitly prepares SEEK state
  without changing game rules. Initial209/1 is retained separately.

## Remaining integration / unverified

Actual production of every PhaseI/II ability, genuine unique-kill evolution,
10-minion fights, all six new machines and Crimson-domain cleanup must still be
checked through B's completed controller with independent C/D. Required final
captures include full Music/Effects1.0 stress, mixed versus isolated real gameplay,
warning priorities, menu/domain music continuity and long-run player counts.
No whole-game safety or gain-perfect claim follows from source peak normalization
or the direct unit recordings. If the actual stress mix clips, bus dynamics or
priority should be adjusted and affected captures repeated.

The final legacy item_explosion uses a recorded explosion/debris transient
(FxKid2/Freesound367622, explicit CC0 mirror metadata) layered with a physical
impact, replacing its earlier synthetic asset. This adds no new item or mechanic.

Native Windows, physical output, human listening, perceived mix, scariness and
source realism remain UNVERIFIED. No specialist commit or push was performed.
