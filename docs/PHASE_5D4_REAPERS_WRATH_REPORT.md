# Phase 5D-4 — The Reaper’s Wrath

## Status

**IMPLEMENTED:** first contextual HUD and specialization workflow milestone; licensed sampled SFX assets and additional Crimson score. Boss, evolution and building integration remains in progress.
**TESTED:** actual starting branch/HEAD and remote equality; 53 baseline render/input checks with 22 fresh screenshots; 51 baseline strategy scenarios. All 97 regular/extended baseline commands pass (1456.456 seconds), with zero engine/assertion errors or warnings.
**FAILURES AND FIXES:** findings are being investigated; no acceptance inferred.
**UNVERIFIED:** native Windows, physical sound/input, subjective horror, visual
quality, beginner usability and human difficulty on this new version.
**INCOMPLETE:** gameplay expansion and final integrated acceptance; see table below.

## Baseline and delivery

Clean `work`: `d507600f64c3c55ff858a9d5bc5d3c938b6e5f6d`; remote matches.
Recovery `pre-phase5d4-d507600`. Existing main, user profiles and historical
evidence remain outside modification. No public release or new Phase 6 audit.

## Required acceptance workstreams

| Workstream | Functional acceptance | Evidence status |
| --- | --- | --- |
| HUD | Readable hierarchy and one consistent contextual build/upgrade panel at 720p/1080p; actual mouse/keyboard flow | 53 checks / 22 screenshots passed |
| Specializations | Actual computed stat differences, benefit/drawback, confirmation, exclusive selection | Early independent input QA 698/0; affected legacy branch UI 518/0 |
| NPC / Hell | Genuine no-turret and active strategies across maps/archetypes; explain damage and targeting, preserve accessible Normal | 51 baseline cases passed |
| Hunter evolution | All 15 distinct bounded effects, one reward per genuine unique kill, seeded choice, readable notification and sound | Pending |
| Reaper eligibility | Diagnose actual restrictions and early deaths, communicate eligibility, genuine visible transformation | Pending |
| Reaper Phase I | Attackable navigated undead, limited Soul Steal, Scythe Slash, temporary Rules Judgement | Pending |
| Reaper Phase II | Enhanced Undead, 50% current-balance Soul Reaper, Phantom Scream, temporary Final Judgement | Pending |
| Combined ultimate | Once-only final 10% Eternal Sacrifices / Crimson Execution, valid player or AI target, ~30s bounded 1v1, cleanup on all exits | Pending |
| Six new buildings | Flame, Frost, Shock, Auto Repair, Shield, Decoy; real effects, artwork, Levels 1–10, two branches, actual-spend refunds | Pending |
| Interactive audio | Sampled gunfire, impacts, building actions, evolution and every major boss cue; preserved seven scores, documented licenses | Source audit underway |
| Preservation | Saves, all modes/maps/items/rewards/spectating/tutorial; Challenge reproducibility limits; no practice rewards | 97 commands passed |
| Performance | Ten undead, many weapons and audio voices, long Endless, repeated transitions; measured Linux evidence only | Pending |

## Baseline findings (before changes)

[Rendered baseline](evidence/phase5d4/baseline/render-review.md): the build panel
moves the camera about 140.6 world units sideways, and controls move vertically
between purchase, confirmation, upgrades and branches. Current specialization
mechanics are real, but computed comparisons and explicit confirmation are
missing. These are observed problems, not an inference from passing UI tests.

[Balance baseline](evidence/phase5d4/balance-baseline-summary.md): 45 no-offense
cases cover all five maps/stages and three difficulties. Bed/door-only repair
policies win 4/5 Hell cases with zero player offense, compared with 0/5 fully
idle Hell cases. NPCs earned and spent their own resources. Their observed caps
were Bed5/Door5/machine4, so a latent emergency-upgrade budget issue must not be
misrepresented as the measured cause. Six additional controls distinguish active
Hell play from explicitly funded high-NPC counterfactuals.

Reaper appears correctly in eligible ordinary baseline cases. Stage restrictions
and HP/time conditions explain others; a funded NPC stress case kills an eligible
Hunter at 69.6s, before the old 80-active-second opening. No universal missing
asset/state defect is claimed. New behavior must address the early-death route
and explain eligibility while preserving stage progression.

## Checkpoints

Baseline source and recovery tag recorded above. Production milestones and exact
Git delivery will be appended after implementation tests complete; this document is not a claim
of a finished implementation or successful push.

## First contextual UI checkpoint

Fixed bottom actions replace shifting purchase/upgrade panels. Opening the panel
does not move the camera on any map. BUILD purchases directly into the selected
pad. Branch cards show computed effects; preview is free and a separate Confirm
button makes the exclusive transaction. Current and next weapon/production values
use effective gameplay calculations. Idle detail body collapses.

Independent input QA: 698 checks, zero failures. Actual rendered UI: 301 checks
plus 209 final clarity checks, zero failures, at 720p and 1080p. Root inspected
the current 720p build palette. Legacy affected purchasing 908, premium UI 3483,
branch UI 518 and onboarding 92 checks pass. Initial card/button overlaps and
missing current-level/branch labels were fixed; diagnostic evidence is retained.
These checks do not establish beginner usability or human approval.

Early actual engine combat audio: 76 checks pass; Needle 12 launches/12 impacts
and Arc 6/6 in each paired default/Music-muted capture. Master output remains
nonzero with music muted; 18 PCM recordings have no full-scale samples. This
is evidence of existing weapon playback, not yet the new boss or building events.
