# Phase 12B — Fair Difficulty, Real Counters and Recovery

**IMPLEMENTED:** focused current-rule pressure/recovery, budgeted/range-aware bots, actual repair limitations and factual pre-breach defeat windows. **TESTED:** matched original-source comparisons, fresh Campaign strategies, independent correctness QA, normal-speed input victory and real720p/1080p rendering. **UNVERIFIED:** native Windows, human enjoyment/readability, optimal strategies and every possible build/seed. No new content/mode, price/income inflation or progression lock.

Started clean on `work` at `1b6d76e017e50c4b26ff0c73bb2ff279ef4721a5`. Recoverable implementation `35c813c`; final implemented source: `d1882972556ecf87b70a3cf10b4f01125e74882c`. Delivery HEAD/push verification is supplied with the final message and export receipt. Main is not modified; no release is published.

## Entry conditions and methodology

Long Night and Hell are available on a genuinely fresh profile. `begin_match` validates difficulty/stage, not a hard-mode progression lock; Stage1 is unlocked initially. No new lock was added to hide failures. All principal cases start25G/0E, zero permanent bonuses/items, Stage1 Abandoned Dorm, room0/Fortified. Six Hunter archetypes rotate through the seed sample. Room claim/sleep at t0 is automatic **only in simulations**. Policies use actual production prices, prerequisites, damage and NPCs, .1s model ticks and one paid decision/second. They see current door HP/resources/visible enemies, never future RNG. Simulations run faster than wall time; they are not normal-speed or human playtests.

The untouched Phase12 production source was extracted with `git archive` into a temporary reproduction fixture, not another Git worktree or a reset of working production. Same final policy code, seeds, map, room and entry funds were run against the original and revised source. [Source receipt](evidence/fair-difficulty/original-source-receipt.json) records baseline hashes. Existing Phase12 .2s results remain unchanged; slight event-time differences in .1s reproductions are not silently substituted into old evidence.

## Cause and fix

| Finding from actual code/traces | Classification | Focused change |
|---|---|---|
| Failed saves toward a larger purchase could fall through to cheaper weapons, delaying bed/power. | Weak test policy; not a game bug. | Explicit saving goals and visible-HP responses in two different paid policies; no new resource grants. |
| Hard Campaign continued old14-damage/32s or18/25s growth while intervals shortened; Endless caps per-wave growth. Existing difficulty, charged hits, kill buffs and contact pressure multiply this further. | Economy/pressure mismatch; surviving Endless did not validate Campaign. | After the existing45s active opening, current2 hard Campaign growth clock advances at half speed. Actual damage/interval/HP growth share that clock. Current combat level≤10/growth≤9. Normal opening, difficulty/base HP/archetype identities and Endless growth clock remain. |
| Hard bots saved for power/support queues before enough effective defense; repaired below35%. | Policy mismatch with revised economy. | Visible-siege defensive investment/repair, prerequisite infrastructure and useful weapon upgrades before the full support catalogue. Same wallets, prices and shared validation;1.2s decisions, no free funds. |
| First-empty-slot weapons could not cover their own door, reducing supporting fire and accelerating ally deaths. | Functional placement weakness. | Hard current2 bots place new weapons in legal fixed slots nearest their door; non-weapons retain ordinary empty-slot placement. All5 maps tested. Owned saved buildings are not moved. |
| Charged blows had short follow-up intervals and another special could immediately take the opportunity. | Weak recovery/counter window. | Additional1s after a charged hit, visible countdown, no new Arcane/Nightmare/tactical start during recovery. Existing in-flight effects may still resolve; this is not invulnerability. No full-heal retreat. |
| A repair station could display nominal healing while a fixed8–40E reserve prevented it operating. | Resource/preview mismatch. | Reserve scales continuously below70% HP to zero at30%; upkeep is still paid. Inspector shows funded estimate, nominal rate, exact reserve/stored E and pulse limitation. Compact next-tier line prevents clipping. |
| Defeat advice used wallet at death, not the available decision window. | Misleading inference risk. | Bounded pre-breach hit snapshots; report a real wallet/cost/effectiveness at least2s before breach. Do not promise a guaranteed save or recommend an unaffordable repair. |
| Adaptive information priority hid the new recovery line during the most urgent siege. | UI integration bug found in screenshots. | Preserve recovery plus door HP in existing compact lanes even during build inspection; no new panel. |

Controlled diagnostic runs removing contact growth, removing player repair suppression, or slowing legacy growth each still lost all5 Hell principal cases. Bots-only also lost5/5. Related changes were staged with retained outcomes; improved policies alone still lost all20 cases per mode/route in original source. No single-favourable-seed or single repair is presented as proof of a completed run. Diagnostic subclasses/toggles exist only in tools; production loads none of them. [Independent audit](evidence/fair-difficulty/independent-audit.md).

## Complete matched outcomes

Each row contains20 seeds: original failing1–5 plus held-out6–20. W/L are actual final victory/defeat, not survived openings. No timeouts in these Campaign comparisons.

| Difficulty / route | Original rules W/L | Revised W/L | Revised original1–5 W/L | Revised held-out6–20 W/L | Actual victory seconds | Actual defeat seconds |
|---|---|---|---|---|---|---|
| Long Night / bulwark | 0/20 | 20/0 | 5/0 | 15/0 | 190.4–231.5 | none |
| Long Night / assault | 0/20 | 20/0 | 5/0 | 15/0 | 184.9–222.7 | none |
| Hell / bulwark | 0/20 | 11/9 | 2/3 | 9/6 | 209.3–241.7 | 213.2–297.9 |
| Hell / assault | 0/20 | 14/6 | 3/2 | 11/4 | 196.3–277.8 | 189.1–228.5 |

Defensive **Bulwark** invests in an early useful Needle, Bed/Door3, power, Needle2, Door4 and paid Auto Repair/Frost. **Assault/control** takes earlier multiple Needles/Frost and weapon upgrades, then the larger door. Both use the same funds/requirements,1s decision cadence and conditional repairs. They are deliberately different policies, not claimed optimal guides. Exact timestamped orders and all outcome/breach times are in [outcomes.csv](evidence/fair-difficulty/outcomes.csv) and original `before-disciplined-*` / final `after-*` JSON. Detailed per-hit/purchase5s traces are retained for seeds1/2; all20 have final outcomes, first-room attacks, breach times and final NPC accounts. Unknown detailed fields for other seeds are not fabricated.

Hell still has genuine route-dependent losses, notably some Electric/Storm seeds and heavy pressure. Every archetype has demonstrated wins in the final sample, but neither route wins every seed. Bulwark median repair spending162G and median personal damage1054HP; Assault119G and1601HP. Earlier offense typically finishes faster and spends floor/power on weapons; heavier doors/paid healing trade offense for longer survival. These samples do not prove a universal dominant strategy or fairness for every encounter.

Long Night Bulwark had median personal damage0HP: these are team victories with deliberate fortification, not solo kills or proof that every run demands personal shooting. This is relevant to the remaining allied-carry limitation.

Passive Hell: **0/20 victories**, original1–5 plus held-out6–20, no purchases or forced results. Five passive Long Night cases produced3 wins/2 defeats through ally carry. This is a disclosed limitation: Long Night is more forgiving with competent allies and does not always require personal shooting. We did not invent a target win percentage or punish Normal simply for winning. Further owner/Adie balance acceptance is open.

One final Hell Bulwark seed5 run breached at229.1s yet defeated the Hunter at231.9s before the player was eliminated—an actual finish opportunity, not a forced rescue.

A poor first Needle placement followed by a legitimate sale/reinvestment recovered to3/3 Long Night wins (seeds1/6/12). It lost the50% sale portion rather than receiving free reimbursement. This demonstrates one recoverable mistake, not that every bad purchase is recoverable. Rare drops, run perks and merchant items are not needed for either principal Campaign route; those systems remain Endless-only.

## Pressure and repair arithmetic

Original difficulty/stage/archetype multipliers remain. Current2 hard Campaign effective active time is `min(active,45) + max(0,active−45)×.5`; existing growth formulas then calculate damage, intervals and finite HP growth. This changes the growth curve, not base HP or a hidden reaction to wealth. Normal current2 is unchanged except the explicit level/growth cap. Endless retains its prior per-wave clock/cap. Evolution forms/skills still use existing time/stage/kill rules and cap10. Contact escalation remains genuine sustained contact/hits,2.5s warning,+8% twice maximum per encounter; no blocked-hit farming.

After a charged ordinary-form strike, cooldown gains1s and `recovery_remaining` blocks new special starts. Reaper retains its own attacks/recovery and clears this ordinary recovery on transformation. Damage still passes through existing type/element/door mitigation, shields and Legendary rescue; no new guaranteed-hit or refill mechanic. Existing EXIT is post-elimination travel, not healing retreat.

Base station upkeep remains.35E×level/s (or stronger branch upkeep). A normal reserve8–40E is multiplied by clamp((door_fraction−.30)/.40,0,1). Thus reserve is full at70%, half at50%, zero at30%. Zero power cannot heal; full/breached/inactive doors do not receive free usable healing. UI is a funded nominal snapshot, **not exact last-tick delivered HP/s**: a fractional balance can wait for the next affordable upkeep pulse. Existing suppression/curses/Endless modifiers still apply.

No starting funds, income table, machine price, upgrade price, expansion progression, refund rule or reward probability was changed. Repair/infrastructure compete for real E/Gold; cap9 prevents an endless uncapped stat curve while late offense remains necessary. No new full-heal retreat, permanent control effect or repair refund loop was introduced. We do not claim to have exhaustively ruled out every contrived maxed-room stalemate.

## Understandable defeat evidence

Final Hell seed2/Bulwark: breach231.5s, elimination234.8s, door4,10 manual repairs/180G spent,1942.8 actual door damage, final source Hunter door strike/Electric Ghost. At227.8s—3.7s before breach—the recorded wallet was9.17G/11.22E. Neither manual repair nor next door upgrade was affordable then. The UI explicitly says so, rather than blaming a fictional missed button. Last recorded repair effectiveness65%, contact pressure2/2. Exact source/HP/resource/warning events remain in the raw trace. A recorded option in an earlier window is not a counterfactual guarantee that it would change the result.

Snapshots are bounded24 windows; door/damage histories are bounded as before, and detailed windows are transient since start/resume. Old saves without them show no fabricated history. Existing defeat flow/retry/rewards remain. [Actual720p/1080p evidence](evidence/fair-difficulty/INDEX.md).

## Economy activity and Normal greed

Sixty current Normal Endless cases—20 seeds each greedy/defense/balanced—remained alive at10min. They use the actual production model; optional drafts/merchant purchases were omitted in this controlled comparison. They are not claimed20-minute continuations. Original Phase12 longer evidence remains preserved.

The shared5.4G/s at5min is Bed3 base6×Fortified.9, and the test policies repeatedly buy power/weapon/support goals before Bed4. It is **not a wallet cap or a rule forcing every player to wait**: Bed4 is legal with Door2+ and200G/15E, while the policies choose competing investments. Current detailed seeds1/2 again show5.4; five-minute full-sample figures in Phase12 are separately retained rather than extrapolated. The two successful Campaign routes make different useful defense/offense purchases while often sharing the same income tier.

| Normal10-minute strategy (20 each) | Median actual door damage | Median / max repair Gold | Cleared-wave range |
|---|---|---|---|
| greedy | 107.27 | 0 / 48 | 5–7 |
| defense | 142.81 | 0 / 256 | 5–7 |
| balanced | 107.27 | 0 / 112 | 5–7 |

These distributions do **not** demonstrate a consistent Normal greed penalty: defense had higher median damage in this sample, all medians for repair spending were0, and wave ranges overlapped. We report that negative finding instead of inventing danger or nerfing Normal. Greed risk remains scenario-dependent and a human review question. Normal accessibility was deliberately retained.

Actual paid decision gaps in the hard routes: medians~13s for Assault/Hell Bulwark,~19s Long Night Bulwark; largest measured intervals~31–50s depending route. These are gaps between chosen successful transactions, not proof no alternative affordable action existed. Raw snapshots list actual available wallets/quotes and purchase goals. There are meaningful saving periods; human assessment of waiting/engagement remains unverified. Prestige prices/journey were not shortened for a target duration.

## Saves and scope

Legacy1 keeps old economy/pressure/bot rules and earned wealth/buildings. Current2 keeps its save format, wallets, investments, permanent inventory/unlocks and checkpoint boundaries. Existing2 Endless continuations adopt emergency reserve release, charged recovery and revised future NPC purchases/placement. Owned buildings are not auto-moved or downgraded. Campaign has no mid-match resume, so growth-clock changes affect new Campaign matches. No automatic conversion or save wipe. Fixed Challenge Codes remain legacy-rules comparisons; Practice/tutorial isolation is unchanged. Perks/merchant remain Endless2-only.

Canonical earned Hell45 SHA256 remains `d20b729b9ccc804d0c1aa55874558da07c503d02cfa2455ee3a0f9b63f86eb1b`; Phase12/earlier earned evidence is protected. Regenerated historical regression output is archived before restoring original bytes from the delivery baseline.

## Verification and retained failures

- Independent checkpoint QA:10/10 invocations,6577 assertions/0 failures at35c813c, source bytes checked512/512. Covers money, repairs, recovery, perk/merchant/refund and real process-restart stock protection. [QA report](evidence/fair-difficulty/independent-qa/QA.md). Later range placement/presentation fixes are covered by final focused tests/matrix/rendering.
- Final focused:94 fair-difficulty checks (includes every room on all5 maps),13 live-controller UI checks, earned-power67/UI31, Phase11 features21/UI28, tactical QA60262; all0 failures. Full regular/extended verification status is recorded below when completed.
- Final runtime captures14/0; input video40 gameplay assertions plus1 audio assertion=41/0. The JSON is written before that final audio assertion. Rendered inspector clipping and recovery-priority issues were fixed, recaptured and inspected.
- Retained failed experiments include the original failures, individual ablations, bots-only/pacing/recovery steps and weaker policy drafts. A test-only attempt to mutate readonly constants failed; it was replaced with a diagnostic subclass. An early unit fixture failed because its attacker was dormant; corrected to exercise valid real damage. A recording setup failed to sleep; another valid victory had an incorrect post-reward empty-inventory assertion. Logs remain labelled. Assertions were not disabled to claim a pass.
- Full regression status: 140/140 passed, first pass. The full suite ran once during stabilization; final targeted placement/UI changes were additionally covered by94/13 focused checks,60262 tactical assertions, final80-case matrix and final rendering. No historical assertions were removed.. Historical compatibility fixtures explicitly select legacy1; these are not misrepresented as new2 balance simulations. No repeated unrelated full-project audit was delegated.

Reproduction (Godot4.6.3; writable XDG data/config/cache required):

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/fair_difficulty.gd
godot --headless --path . --script tests/fair_difficulty_ui.gd
godot --headless --path . --script tools/phase12b_probe.gd -- --mode hell --policy bulwark --seeds 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 --output res://artifacts/hell-bulwark.json
python tools/verify_fair_difficulty.py
python tools/summarize_fair_difficulty.py
# DISPLAY=:98 with real X server for actual rendered/input evidence:
python tools/record_fair_difficulty.py
```

Baseline reproduction must use the archived original source and same final policy, not select Legacy1 (which is a different economy). Read-only source hashes and exact commands/labels are retained with the outputs. Scripts which regenerate historical evidence should be run with preservation/restore safeguards.

## Real runtime, audio and Windows evidence

Continuous MP4:204.42s,1280×720/24fps, normal wall-time actual production Game and scripted InputEvents. Fresh menu-selected Long Night Stage1/Stalker; walking/claim/sleep and paid mouse/keyboard construction/upgrades/repairs. Victory at189.28 simulation seconds/202.57 wall seconds. No assigned wallet/HP/player position, manual kills, time acceleration, items or rank bonuses. Post-victory rewards are legitimate; inventory need not remain empty after winning. The first fresh-profile archetype is the ordinary deterministic profile choice, not a prepared boss.

Separate actual Master FLAC190.125s, RMS.01371/peak.11438, zero full-scale samples; silent video and audio clocks are not synchronized. This proves engine signal, not Windows output or subjective quality. Video predates only final recovery-priority/repair-copy presentation corrections; final numeric rules and range-aware bots were present. Final720p/1080p stills independently verify those UI corrections. [Gallery/video/audio](evidence/fair-difficulty/INDEX.md).

Simulation screenshots use accelerated actual model ticks and frozen real Godot frames with captions; they are not human or normal-speed footage. The repair-inspector example uses an explicitly prepared budget/HP state solely for UI. Prior/stale iterations are kept in a separate folder and not labelled final. All final screenshots were inspected directly; no mockups or generated gameplay. Evolution announcements still temporarily occupy room space, but urgent door HP/recovery and actions remain readable. Human comfort/perceptual judgement remains unverified.

Windows package: Exported private portable x64 ZIP113,661,407bytes from `d1882972556ecf87b70a3cf10b4f01125e74882c`; embedded-pack Linux77/0 plus current-economy17/0, ZIP CRC clean and Phase12B checklist included. [Receipt](evidence/fair-difficulty/windows/windows-artifact.json). Source SHA may precede final documentation-only delivery HEAD. No native Windows execution, human enjoyment, subjective sound quality, exhaustive maxed-room stalemate proof or hours-long hardware performance is claimed. Existing all-map/AI/Reaper/item regressions are distinct from full new2 strategy playthroughs of every later Campaign stage, which were not exhaustively sampled.

## Completion

Focused implementation and demonstrated fresh winning routes are complete; meaningful Hell defeats and negative findings remain explicit. No claim of perfect balance or guaranteed survival. Human balance acceptance remains open, especially Long Night allied carry and harder Electric/Storm encounters. No unrelated phase was started.
