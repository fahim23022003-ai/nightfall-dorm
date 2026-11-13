# Phase 6A — Night Omens

IMPLEMENTED and focused-tested on Godot 4.6.3, branch `work`, baseline `245748af2fbb39a59733b1c5204381e3589a62a0`. No agents, new dependencies, assets, builds or unrelated phases.

## New gameplay

Optional **Blood Moon**, **Blackout** and **Cursed Walls** challenges affect exactly the next Endless encounter. First offer: after clearing wave 1, targeting wave 2. Subsequent eligible intermissions satisfy completed-wave modulo 3 = 1, with upcoming Reaper encounters excluded. Early event waves therefore include 2, 8, 11, 14 and 17. All three fixed offers are visible together; no RNG is consumed and reload cannot reroll the offer set. Decline is the safe default.

Choose one Omen or Decline independently of existing **Reinforce / Salvage / Recharge**, which remain the Continue actions. Prices, regular wave scaling, AI, rewards probabilities and campaign contracts are unchanged. No Omen bonus gives permanent RM Cash, XP, inventory, pity progress or achievements. Existing legitimate Endless milestone rewards remain unchanged.

| Risk | Normal | Long Night | Hell |
|---|---:|---:|---:|
| Blood Moon: Hunter movement multiplier | +12% | +10% | +8% |
| Blackout: player's Dynamo output | −15% | −12% | −10% |
| Cursed Walls: player's incoming door damage | +10% | +8% | +6% |

Blood Moon composes with the fresh Hunter's movement tuning; each later fresh Hunter returns to regular tuning. Blackout affects only player Dynamos, not bed power or allies, and uses a bounded positive production multiplier. Cursed Walls composes before existing armor/shields/items at the central real damage path; existing mitigation still works. All effects clear on successful encounter completion; death/forfeit grants no bonus. Omens never enter Campaign, Practice or imported Challenges.

### Reward tuning

Quoted rewards are fixed when selected, saved, and displayed exactly. The following round to whole resources:

- Blood Moon Gold: clamp(12 × current bed Gold/sec, 35, 12000).
- Blackout Electricity: clamp(10 × sum of current base Dynamo output/sec, 7, 1000).
- Cursed Walls: clamp(6 × bed Gold/sec, 20, 6000) Gold plus clamp(6 × base Dynamo output/sec, 3, 500) Electricity.

Electricity reward reference intentionally uses base Dynamo output, not temporary multipliers. Bonuses are modest seconds-of-production quantities, capped to avoid late-game runaway awards. Longer waves can cost more lost Blackout production than the eventual bonus; the decision is not advertised as guaranteed net profit. Harder modes get smaller added penalties because their baseline pressure is already higher. Global in-run storage caps apply; completion shows the actual amount credited.

The genuine existing wave-45 checkpoint quotes 6277 Gold for Blood Moon, 60 Electricity for Blackout, or 3139 Gold +36 Electricity for Cursed Walls (523.125 bed Gold/sec). The early capture quotes 35 Gold /15 Electricity /20 Gold +9 Electricity respectively. This avoids a fixed tiny reward becoming irrelevant in advanced rooms without changing upgrade prices.

## Persistence and transaction safety

Optional `omen` data is added to the existing between-wave snapshot: selected ID, quoted reward, last paid wave, last actual payout. Missing data loads as no Omen; no main profile schema/version or Challenge ruleset change. Validation rejects invalid IDs, off-window selections, negative/oversized or inconsistent rewards and invalid paid-wave history.

Selection saves immediately using the existing transactional checkpoint writer; failure restores the previous model choice and disables unsafe Continue. Continue saves the selected checkpoint before starting the wave. A combat-phase guard rejects repeated Continue calls without reopening intermission or adding aid. Existing checkpoint save/reload keeps selected risk and quote. Mid-wave quit resumes the prior safe intermission and replays the entire encounter, with no new mid-wave save support.

Payout requires the designated active wave, dead Hunter, living player, live nonterminal combat state and an unpaid wave ID. It updates the run wallet once, clears the modifier and is then sealed into the normal completed-wave checkpoint. Repeated finish, reload of paid checkpoints, death and forfeit do not duplicate it. Replaying an older checkpoint also restores its older wallet; it cannot accumulate a previous unsaved payout. No user saves were overwritten.

## Presentation and input

Existing Gothic intermission panel now shows three illustrated offers and Decline, with exact risk, reward, selected state and next-wave-only duration. Aid choices remain beneath them. Existing compact wave HUD shows Omen name/icon, risk and conditional reward; door HP, Team and building controls remain unobstructed. Completion appears on the next intermission with actual credited resources.

Reuses original hell/power/bulwark icons, restrained blood/dark lighting tint and the existing eerie/start/reward audio paths and saved audio mixer. Reduced Effects reduces tint strength; no flashing or extra particles. No new sound assets/licenses. Subjective audio quality was not auditioned; capture audio driver was Dummy.

## TESTED

- New focused suite: **152 checks, 0 failures**. Accept/decline, exact real movement ×1.12, actual model Dynamo production ×0.85, real mitigated door damage ×1.10; paid survival through owned turret projectiles; expiry; repeated finish/reload prevention, including fresh profile reads from disk; death/forfeit; all three aid choices; deterministic intermittent offers; Reaper exclusion; difficulty bounds; old real checkpoint migration and corrupt data rejection.
- Six existing necessary regression gates all exit 0 without script errors: replay_endless (28426 assertions), replay_transactions (284), replay_migration (190), replay_practice (7505; 20 items/30 map-archetype scenarios), replay_codes (1490; 6 fresh processes), gameplay_visual_polish (50). These are existing gates, not thousands of newly generated cases. No entire extended project matrix rerun.
- Actual runtime capture/input: **57 checks, 0 failures**, exit 0. Mouse selection, keyboard Enter activation, selected-choice persistence, existing Continue aid, repeated Continue rejection, failed-save rollback, actual combat for each Omen/Decline, actual completion payout, 720p and 1080p rendering.
- Godot import and launch pass. Seven raw PNGs personally inspected; active HUD reward text was raised to fit the header before final capture. No visible overlap with door warning, build controls or Team.

### Prepared balance scenarios

Actual model ticks under Cursed Walls, seeded controlled budgets/building levels (not natural progression or human win-rate evidence):

| Prepared wave / door-bed level | Observed pressure result |
|---|---|
| Wave 2 / Level 1 | Weak door breached before the 30-second window; defeat, zero payout |
| Wave 14 / Level 5 | 30-second window survived, door HP 1537.08; encounter still active, no premature payout |
| Wave 44 / Level 10 | 30-second window survived, door HP 7255.56; encounter still active, no premature payout |

Wave counters and budgets are prepared for this pressure audit; this does not claim those runs were earned. The existing legitimate wave-45 checkpoint is loaded read-only for compatibility/reward sizing. Risks remain modest and bounded; actual long-run strategy enjoyment and final balance need human playtesting.

### Failures found and fixed

- Fresh disk reload showed only a 1.82e-12 Gold JSON floating-point difference, not a payout error. The test uses a strict 1e-7 serialization tolerance, then checks repeated completion leaves the freshly loaded wallet exactly unchanged. Initial diagnostic retained.
- Zero-reward checkpoint validation initially compared integer and floating arrays structurally, rejecting Decline/completed state. Numeric component validation fixes the real save bug; initial failing log retained.
- Fixtures initially reused an occupied pad / omitted required high-level branch choices; corrected to use available paid pads and valid branches. No production rules loosened.
- First capture fixture left the session Welcome open, blocking inputs. Fixture now closes it through the existing API; initial diagnostic retained, failed PNGs replaced with verified final captures.
- Continue now rejects repeated combat-phase calls safely. Failed selection saves roll back rather than leaving an unsaved accepted risk.

## Evidence and limitations

Raw real Godot screenshots at `docs/evidence/night-omens/screens/`:

A-intermission-720.png; A-intermission-1080.png; B-blood-moon-combat.png; C-blackout-combat.png; D-cursed-walls-combat.png; E-completed-reward.png; F-declined-combat.png.

Manifest includes dimensions/hashes; adjacent raw logs, regression results and capture fixture document setup. Captures use isolated profiles, temporary starting resources/door levels, controlled time/contact and shortened Hunter HP to reach intermission/completion through actual paid turret fire. These are genuine runtime scenes, not mockups or uninterrupted natural human playthroughs.

**UNVERIFIED:** native Windows execution/hardware performance, subjective audio/enjoyment and prolonged natural Endless balance. HUD Omen text is deliberately compact at 720p; full risk/reward is readable on the intermission and hover tooltip. No long-session benchmark or universal strategy-win-rate claim. Existing between-wave-only resume limitation remains.

No feature within this phase is intentionally incomplete. No next phase/release/main merge. Final commit is the commit containing this report; final delivery verifies normal remote `work` SHA equals local HEAD and a clean tree, and supplies permanent full-SHA PNG links.
