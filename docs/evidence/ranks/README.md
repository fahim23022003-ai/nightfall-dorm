# Phase 5A rendered ranking evidence

Agent D used actual Godot4.6.3 OpenGL/Mesa llvmpipe on a private Xorg display.
`tools/capture_ranks.gd` creates an isolated `user://rank-render-*.json` profile.
The PNGs are real engine frames, not mockups. The fixture injects XP, match time,
damage and Hunter health, then uses actual stage starts, settlement, results and
button clicks. Its five prepared wins **do not demonstrate reaching Mythic in
five normal matches**: XP7990 is deliberately injected before the final gate test.
Balance/pacing evidence belongs to the independent progression tests.

The final run passes **40 checks, zero failures**, producing13inspected PNGs.
`render-final.log` records passing assertions and exact audio diagnostics.

## Frames inspected

- `render-01-bronze-ranks`, `render-02-bronze-ranks-small`: seven distinctive
  loaded badges, original six thresholds, rank progress, records and six existing
  boosts. The large badge actually pulses. Smaller capture is960×540.
- `render-03-master-gates-locked`:8000XP alone leaves Master with stage/win/Reaper
  requirements visible. Highest rank is deliberately set toMaster in this injected
  preview to match its artificial XP.
- `render-04-master-final-stage-needed`: real prepared stage1–4 settlements have
  produced four advanced wins/three Reapers; final-stage and XP gates remain.
- `render-05-mythic-promotion`: actual stage5 settlement crosses7990→8411XP,
  grants Mythic, shows LongNight difficulty and the Master→Mythic transition.
  This frame captures the gold/violet badge pop and the XP number while it is
  increasing. `render-06-mythic-result` shows settled8411XP and exact+421breakdown;
  `render-07-mythic-result-small` verifies the same layout at960×540.
- `render-08-mythic-ranks`, `render-09-mythic-ranks-small`: distinctive purple/gold
  Mythic artwork, saved current/highest rank, completed gates, difficulty records,
  Reaper count and stage records. Existing equip controls remain available.
- `render-10-mythic-menu`: persistent prestige badge/text on the main menu.
- `render-11-mythic-loadout`: the existing six perks and difficulty preparation
  still fit; there is no Mythic-only perk.
- `render-12-defeat-breakdown`: limited loss XP, selected difficulty and existing
  Retry/ChangeLoadout/MainMenu actions. `render-13-retry-preserves-rank` follows
  a real RetryStage button click and confirms a fresh match retains Mythic.

## Findings fixed by the production owner

D identified missing selected difficulty on results; the stage caption now
includes it. The promotion rank line now names both ranks and shows old/new XP.
A long menu requirement initially spilled into the scene artwork; the owner
added wrapping and deferred sizing to respect the label's column. D also found
that new XP/pop tweens started while the existing results fade hid them. The
owner delayed them until0.95seconds so they visibly play after that fade. Final
frames show the corrected presentation. No production edits were made by D.

## Audio evidence and limits

`render-promotion-mix.wav` is an actual AudioEffectRecord master-bus recording,
using the engine's Dummy output device. The real settlement observer starts
`mythic_promotion` exactly once. All56streams decode, no assets are missing,
and four permanent music players remain started once across results/retry.
PCM measurements are in `render-audio-measurements.json`; no samples clip.
This establishes functional non-silent mixing, not subjective human audition.

Native Windows input, import/launch, speaker balance, animation feel, human
motivation and broad gameplay pacing remain UNVERIFIED. These are deliberately
prepared Linux fixtures. The llvmpipe unsupported-VSync warning is expected;
final logs contain no script/parse errors. Only the audit-owned Xorg is stopped.
