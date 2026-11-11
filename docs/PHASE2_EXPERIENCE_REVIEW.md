# Phase 2 independent experience review

Agent D reviewed the actual AudioDirector, generated assets and generator, host/UI call sites, progression UI source, and AUDIO_SOURCES.md. This is a bounded experience audit, separate from the QA gameplay/persistence suites. Listening quality, speaker output and subjective musical balance remain **UNVERIFIED**: no audible monitoring or recorded-output listening was performed.

## Real PCM asset evidence

Python's standard-library `wave` and signed-sample analysis decoded all **36 WAV files**. Every file is mono, signed 16-bit, 22,050 Hz, has nonzero RMS, and contains **zero clipped samples**. Measured peaks range from approximately 0.110 to 0.330 full scale. Effects last 0.065–1.5 seconds; music loops are 12 seconds; environment loops are 8, 4 and 2 seconds. Loop end-to-start sample deltas are 0–0.0041 full scale, consistent with the periodic oscillator source and boundary fades. These measurements establish valid non-silent PCM and available headroom, not an audible quality verdict.

The generator is original local deterministic synthesis using Python standard-library oscillators/noise/envelopes. No external sample source was observed. AUDIO_SOURCES.md matches the stored inventory and implementation.

## Integration inspected

- Music, Effects and Ambient buses are created/reused, independently attenuated, and muted by normalized saved settings. Three music stems and three ambience loops start persistently and crossfade through volume weights rather than restarting each frame.
- Distance, hunter state/level and player-door vulnerability influence smooth danger/proximity intensity. Generator buildings enable an operating-room hum.
- Combat events use unique IDs for actual projectile launch/impact cues. Door HP/attack counters, breaks, building/bed/door upgrades, income/power changes, eliminations and hunter escalation drive separate cues. UI button/menu/purchase/failure and progression rank/reward hooks are present.
- Sixteen reusable effect voices, six cues per update, per-event cooldowns and distance culling limit dense-event overlap. PCM loop endpoints are calculated correctly for the generated mono 16-bit assets.
- The host constructs and configures AudioDirector, resets observations at match start, updates once per frame, and persists settings through PlayerProfile.

## Concrete saturation issue found

A temporary headless Godot fixture decoded 36 streams with no missing assets, occupied all 16 effect voices, and then transitioned the match to victory. Actual output:

```text
AUDIT saturated voices=16
AUDIT victory count after saturated outcome=0
AUDIT victory count after freeing voices=0
AUDIT streams=36 missing=[]
```

The outcome observer marks the result consumed even when `event()` rejects playback because voices/budget are full. Thus the victory cue can be permanently lost under saturation; the same general risk applies to one-shot progression cues. This was sent to the audio production owner for priority/reservation/retry handling. The temporary audit fixture emitted an ObjectDB teardown warning, so it is not cited as evidence of clean application shutdown or a production leak. The defect reproduction concerns the explicit event counts above.

Graphical progression/settings/result review will be appended after actual Phase 2 frames are supplied. Source layout inspection alone is not presented as rendered validation.

## Saturation correction independently verified

The production owner added critical-cue priority/reserved update budget, bounded deferred critical cues, and replacement of a noncritical voice when the pool is full. Repeating the same independent fixture on the updated code produced:

```text
AUDIT saturated voices=16
AUDIT victory count after saturated outcome=1
AUDIT victory count after freeing voices=1
AUDIT streams=37 missing=[]
```

The important outcome now starts under saturation and is not duplicated when voices become free. The same temporary fixture still emits its teardown warning; no clean-shutdown claim is inferred from this probe. The owner's dedicated audio suite covers that separately.

The final inventory adds a distinct `ghost_defeat.wav`: mono 16-bit PCM, 22,050 Hz, 0.95 seconds, peak 0.2763, RMS 0.0554, zero clipped samples. Therefore the final inventory is **37 real non-silent WAV assets**, extending the initial 36-file numerical analysis above. This is still asset/control verification, not a listening session.

## Actual mixed-output evidence

The coordinator recorded the real Godot Master bus through AudioEffectRecord while rendering the Phase 2 UI with the Dummy output driver. Independent numerical analysis of `docs/evidence/phase2/mixed-preview.wav` found:

- Stereo, signed 16-bit PCM at 44,100 Hz; 339,968 frames, **7.7090 seconds**.
- **659,476 of 679,936 samples nonzero**.
- Peak **0.040192** full scale (approximately −27.9 dBFS); RMS **0.0067166** (approximately −43.5 dBFS).
- **Zero clipped samples**.

This establishes actual non-silent engine-mixed output, beyond asset files and playback requests. The captured mix is numerically quiet/conservative at the captured settings. No listening session was performed, so musical quality, relative cue intelligibility, perceived loudness and listening comfort remain UNVERIFIED. The retained initial render log records seven successful graphical captures, successful recording save, 37 decoded streams, zero missing assets, three persistent music starts, and real rank/reward/ghost-defeat/victory cue counts.

## Rendered Phase 2 UI review

Independently viewed all seven actual `docs/screenshots/phase2/` frames. The loadout, threat and promotion images are explicitly constructed fixtures, not evidence of naturally earned ranks or a natural match outcome.

- Menu rank badge, lifetime XP and next-rank goal are readable and separated from Start/Settings/Rewards controls.
- Settings has three clearly labelled independent volume sliders, mute, fullscreen and tutorial toggles; no clipping seen.
- Bronze and Gold rewards screens clearly distinguish unlocked, equipped and rank-gated boosts, with rank thresholds/progress and the next reward.
- Loadout identifies the equipped boost and selected difficulty; its one-boost rule is visible.
- The own-door warning is prominent and the promotion/result panel fits its statistics, XP breakdown, promotion label and navigation controls.
- **Concrete issue found:** Last light's long description runs underneath the Equip/Master button and beyond its text column in rewards/loadout frames 03, 04 and 07. This was reported to the coordinator for explicit wrapping/bounds correction. Other inspected text/buttons do not overlap.

The visual review is bounded to these captured desktop layouts. It does not certify arbitrary resolutions, input behavior from still frames, target-platform audio hardware or commercial presentation quality.

During the final wrap-fix recapture, reviewing `/tmp/phase2-render-final.log` caught a separate startup regression: assigning `auto_accept_quit` to Window aborts Game._ready, leaving UI/audio uninitialized and causing subsequent Nil update errors. This was reported immediately to the coordinator; it must be corrected and the recapture rerun before final readiness. The initial seven valid frames reviewed above are not substituted for that final validation.

## Coordinator correction and final evidence

After the independent reviewer finished, the coordinator corrected `get_tree().auto_accept_quit` ownership and reran the real renderer successfully. Initial failed output is retained as historical evidence; `render-final.log` is the corrected result. An initial width-only wrap attempt still overlapped; explicit short newline-separated copy fixed Last light. The coordinator viewed the corrected03/04 frames and added two actual scene text-column assertions (Phase2UI now52/0). This final confirmation is the coordinator's review, not a second independent-agent claim.

The exact analyzed original recording is committed as `docs/evidence/phase2/mixed-preview.wav`; recaptures can produce different lengths/timing. Its original RMS/peak facts above refer to that preserved file. New live-rendered normal-fund matches additionally reached victory/defeat with earned XP and successful disk reload; see `natural-render.log`.
