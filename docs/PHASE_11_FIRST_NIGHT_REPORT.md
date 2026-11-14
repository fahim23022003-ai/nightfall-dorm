# Phase 11 — First Night Experience & Player-Ready Polish

**Functional implementation: PASS after focused checks. Overall player acceptance: PARTIAL**, pending independent human understanding/enjoyment and native Windows testing. No human approval is inferred from automation. Stop after Phase11; no next phase was started.

Verified starting branch **work**, clean baseline `a075a924a1514c0585b8a8ce30d002195f01dc28`. Engine **Godot 4.6.3.stable.official.7d41c59c4**. Implementation checkpoint `3748f646e6bedead1cb854981c0060d4df7b4ffa`; final production/build checkpoint **`8a291761f40cf1d1f972481a7d04f228423ddd36`**. The subsequent evidence/report commit does not change production code; its exact SHA and verified remote equality are supplied in the delivery reply. Only work was checked out/committed/pushed; no main operation, release publication, agents or save overwrite.

## Actual audit findings and fixes

- Real input found that B was advertised but not handled in ordinary Campaign/tutorial. B now opens the existing building workflow; before claiming a room it explains the prerequisite.
- Recover promised to reopen controls but only reset practice state. It now selects the nearest actual empty pad/build panel or the actual weapon needing an upgrade. Existing temporary practice funding is unchanged.
- Fresh practice lacked the advertised Skip option. Explicit Skip now saves the existing completion flag without rewards; Replay and Exit remain available. Save errors do not silently dismiss practice.
- Tutorial instructions and the old Help area competed. One compact lesson panel now owns the current objective, progress and action feedback; only the relevant control receives subtle emphasis. Optional Items is dimmer in practice. World markers remain real objects.
- Turret readiness uses the actual range resolver, including branch/range modifiers. Advancement still requires real claim/sleep/income/Dynamo output/in-range defense/upgrade/repair/combat results. A repair from an earlier failed attempt cannot satisfy a newly damaged repair lesson.
- Live runtime immediately navigated away from the Wave Report on the following frame. The intermission redirect now recognizes the report screen. Old frozen display fixtures had hidden this defect.
- Simultaneous world-space UPGRADED text collided. A bounded, coalesced summary lane replaces only these announcements; premium rings, prestige appearance, particles and transaction rules remain.
- Final 1080p inspection exposed long advanced Hunter HP text crowding Map. Its font fits the reserved lane with clipping as a final bound; the full value remains in the tooltip. Critical HP/danger and buttons remain readable.

## Implemented player flow

The existing nine-step tutorial and 15-second opening/four-second welcome story remain. Short objectives explain claim E → sleep E → Gold → Dynamo/Electricity → Needle/range O → upgrade → repair R → real weak practice Hunter → save and Stage1/Normal. Practice remains separate from permanent XP, RM Cash, inventory and rewards.

The recovery button reopens real controls. A completion CTA receives primary emphasis. The menu clarifies the next ordinary objective for a newly graduated player. No new onboarding menu stack was introduced.

`PlayerGuidance` reuses the existing Help/objective area: one relevant objective and one control highlight. It recognizes already-established production/defense, affordable door repair, an actually equipped/available repair item, and a full Endless room's existing expansion/move/undo controls. It does not continuously narrate a functioning defense. Help stays manually accessible. Saved **Show Guidance / Minimal Guidance / Off** preferences affect contextual presentation only. Minimal retains between-wave guidance; Off suppresses contextual objectives. Urgent combat warnings remain enabled in every mode. Learned Dynamo understanding is session-local; the preference is persistent.

Layouts are rendered at 1280×720, 1600×900 and 1920×1080. Primary building actions remain in the existing bottom controls. No click target is replaced by an informational overlay.

## Wave report and supported insights

The report uses the existing actual `WaveMetrics` ledger. Four summary tiles show Hunter damage **all rooms**, door damage **your room**, gross Gold and gross Electricity. Tabs separate Damage, Economy, Defense, Hunter Skills, optional Insights and Details.

Damage bars rank actual player building impacts/DoT; six top rows use original building artwork. The footer explicitly separates your room, allies, unshown weapons and Other sources. Support output is never weapon damage. Gross production excludes purchases, sales, theft, aid and Omen payouts. Actual repairs exclude upgrade HP-cap increases. Hunter skill warnings retain their existing factual list. Missing legacy telemetry stays unknown.

New **read-only** per-weapon observations distinguish eligible main-Hunter opportunity, range, actual door siege, temporary disabling and cooldown. They use the same range and disable conditions as gameplay, without RNG, resource spending, target selection or cooldown mutation. Separate support observations record time below the actual Electricity activation cost while an intact door is damaged; they explicitly acknowledge other activation conditions.

Optional insights are capped at **three**. Examples are observed out-of-range siege time, no in-range opportunity (without claiming placement was wrong), observed disabled time, actual absorbed magic, and affordable manual repair at actual damage events. Mixed/no historical evidence produces an honest unknown. Successful repair and recorded damage concentration can be described without inventing a failure cause. Zero damage alone never proves a bad turret.

Observation dictionaries are bounded to 256 IDs and validated. Existing save versions and checkpoint resource ledgers are preserved; observation/absorption fields are optional. Phase10 checkpoints without them load. No schema expansion for camera or transient UI is introduced.

## Intermission and notification scheduling

The current intermission clearly numbers **Review (optional) → Prepare (optional, frozen economy) → Aid + optional Omen → Continue**. The aid buttons themselves continue, so there is no new hidden confirmation step. Existing three aid values, Omen risks/payout conditions and checkpoint transactions are unchanged. The early Omen screenshot uses a disclosed prepared prior checkpoint; it is not a fresh ordinary wallet.

Upgrade scheduling uses at most **six batches**, coalesces bursts within **0.4s**, preserves exact action counts and compact label counts, and displays one batch for **2.8s**. Long batches expose full details by hover. Pausing, menus, construction previews/planning and urgent Hunter/boss warnings defer the lane without aging away queued feedback. Extreme bursts are summarized rather than accumulating unbounded text. The existing immediate transaction result remains available.

## Actual input, rendered and audio evidence

See [complete evidence gallery](evidence/first-night/INDEX.md). Original PNGs and the uncut video were inspected. Screenshot10 is the previous Phase10 report on its prepared wave1 fixture; screenshot11 is earned wave46. This compares layout, not equal scenario performance.

The [continuous engine video](evidence/first-night/video/native-input-silent.mp4) uses scripted engine keyboard/mouse events at normal speed. Its filename does not claim native OS gameplay input or a human test. The cold segment starts from a fresh isolated profile: no unlocks, teleports or injected ordinary economy. It claims/sleeps, buys real Dynamo/Needle, recovers from a closed panel, rejects an unaffordable action, upgrades, repairs, wins actual practice and reloads saved completion with zero XP/RM Cash. It then enters Stage1/Normal through real menu buttons and buys from default funds plus actual bed earnings, with pause/resume. That ordinary match is an opening interaction check, not a full campaign victory.

An explicit on-screen caption marks the later **separate earned45 scenario**. Only disposable profile/run transaction identity is rebound. The original earned wallet pays for Repair and four Arc10 upgrades; no Hunter HP edit or free resources. Actual Save/exit/Resume retains full16; full-health wave46 clears through ordinary `Game._process`; report tabs stay open; aid advances once to47. This is not a natural fresh1→46 playthrough.

Separate actual Master PCM is supplied because capture clocks are not synchronized. Signal measurements and engine logs accompany it. No audio assets or mixing were changed. Subjective audition and Windows audio-device behavior remain unverified.

## Verification results

**52/52 selected gate invocations pass after documented reruns** (initially49/52). The machine-readable [verification summary](evidence/first-night/verification-summary.json) is authoritative for final counts and reruns. Individual logs retain original failures and corrected results.

- Baseline model: **136/136** assertions.
- New feature checks: **21**, no failures. Includes read-only economy/HP/RNG, disabled/out-of-range reasons, legacy unknowns, corruption rejection, 144-action coalescing, queue bound, priority, preference disk roundtrip and checkpoint compatibility.
- Final UI checks: **28**, no failures. Actual Skip/Replay/Exit, saved completion, three resolutions, live report navigation, all tabs, paragraph/bar bounds, large HP lane and Guidance Off preserving urgent warnings.
- Actual continuous journey: **152**, no failures (includes the final actual Master-audio assertion).
- Earned twin-model continuation: **75**, no failures; waves **46,47,48,49,50** cleared. Both Show and Off runs begin from the same serialized state and produce identical combat, resources, projectiles and RNG signatures after each wave. No debug funds or HP edits.
- Rendered paid full16/earned46 path: **81**, no failures. Supplemental final layouts/early Omen: **10**, no failures.
- Existing relevant gates include main model, onboarding99, onboarding economy57,016/42 scenarios, session75/audio18/range11, Omens152, spatial1397 and earned continuation, saves, reward transactions, codes/pity/cosmetics, practice isolation, campaign simulations, purchase/refund/double-clicks, input, spectator all five maps, migration, evolution, existing combat/HUD, items/Legendaries, mobile layout, audio, scene/startup and cross-process persistence. Final results and explicitly resolved fixture failures are in the manifest. This is a relevant regression set, not a claim that every historical/extended matrix was rerun.
- Windows export: PE x86-64 and embedded PCK signatures valid; **77 embedded-pack checks** pass on Linux, including actual main scene/profile/UI initialization and real Practice launch. ZIP CRC and contents verified; development profiles/tests/docs/tools are excluded from the game pack. Notices/checklist are included beside the EXE.

## Failures found and corrected

1. Actual tutorial/campaign B/recovery/report issues described above were repaired in production.
2. New report bars initially inherited a 32px minimum and overlapped labels. Apply final size after styling/attachment; checked ≤10px. Paragraphs initially retained long unwrapped minimum widths; create wrapped text from an empty label and apply deferred bounded sizing. Long Insights/Details now fit.
3. Cold input initially stopped within path tolerance but just outside the 60-unit sleep radius. The script now targets a reachable point safely inside the radius and asserts sleeping. No movement/sleep rule was changed to make the test pass.
4. Show/Off test initially compared an in-memory state with its JSON-restored counterpart. Serialization precision differed. Both twins now start from identical serialized checkpoints and are compared exactly; no combat tolerance was relaxed.
5. Two existing UI suites looked up old literal Prepare/Continue labels. They failed to click and then cascaded into invalid context assertions. Update their literal locators to the intentional numbered labels; all transaction/camera/control assertions remain. Reruns: replay UI **1753**, spectator **1650 across5 maps**, no failures. Initial logs retained.
6. The broad existing navigation test exceeded the initial180s runner limit. With a600s allowance it completed in234.8s: **354,377 checks /540 approaches /0 failures**. No navigation assertion was removed or bypassed. The reproducible runner now grants that specific gate600s.
7. Supplemental screenshots initially retained a frozen opening overlay. Visual inspection caught it; cleanly dismiss the fixture overlay and rerender. Also rebuild the HUD after the fixture's normal wave transition so its static wave heading matches the model. These were capture setup errors, not claimed production defects.

## Performance and preservation

The twin full16 continuation runs 4,650 actual .1s model ticks combined, spanning 232.5 simulated seconds per model. Observed maxima: eight live projectiles, 128 presentation events, seven bounded observed buildings. Linux headless average model tick is approximately **0.8ms** in this shared cloud run; peak reported Godot static memory is approximately **193MB**. This is not Windows FPS, a controlled before/after benchmark or hours-long leak proof. No unbounded queue/observation growth occurred in the tested interval.

No Catalog price/stat changes, enemy AI tuning, damage arithmetic, reward odds, room progression or save resource ledger changes. All15 buildings, free placement, move undo, expansion, evolution/skills, Omens, soundtrack, campaign/Endless/Practice and saved progression remain under existing rules. New opportunities are observational only. The canonical earned45 file remains SHA256 `d20b729b9ccc804d0c1aa55874558da07c503d02cfa2455ee3a0f9b63f86eb1b`. Regenerated historical test evidence is archived separately and original files restored.

## Windows delivery

Portable archive: **`/workspace/NightfallDorm-Windows.zip`**, outside Git. Official matching 4.6.3 templates. The EXE includes the game pack, fonts/audio/resources; extracted users run it without installing Godot. Read VERSION.txt for production source SHA and SHA256SUMS.txt for the EXE hash. See [artifact receipt](evidence/first-night/windows/windows-artifact.json), [pack checks](evidence/first-night/windows/windows-pack-final.log) and [human checklist](PHASE_11_HUMAN_PLAYTEST_CHECKLIST.md).

Reproduce after committing the intended production source:

```sh
XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config XDG_CACHE_HOME=/workspace/runtime-cache \
python tools/windows/export_release.py --zip /workspace/NightfallDorm-Windows.zip --evidence-dir artifacts/phase11-windows
```

The ZIP is a private task artifact; no public release/upload was created and no binary export is committed. Native Windows execution, SmartScreen/device compatibility, controller/key perception, subjective audio and player enjoyment are **UNVERIFIED**. No fabricated Windows runtime screenshot is supplied.

## Remaining weaknesses and acceptance

| Area | Status |
| --- | --- |
| Guided real first night, skip/replay/recovery/completion | PASS, automated actual input |
| Optional objectives, relevant highlight, urgent warning preservation | PASS |
| Visual report and bounded factual insights | PASS |
| Compact intermission and scheduled notices | PASS |
| Rule/save preservation in tested scenarios | PASS |
| Human clarity, fun and independent strategy understanding | PARTIAL — checklist prepared; answers uncollected |
| Windows portable build preparation | PASS; native execution UNVERIFIED |
| Long-session/hardware performance assurance | PARTIAL — bounded five-wave test; hours-long Windows test unrun |

Full16 rooms remain visually dense by design. Rare very large upgrade bursts are clipped in the compact lane with full hover detail. Skills/Insights are deliberately conservative and may give no recommendation. Basic knowledge learned in guidance is session-local. The scripted tutorial pacing is faster than a new human's likely reading speed. Screenshot before/after report scenarios differ and cannot establish a balance improvement. No known unresolved confirmed production failure from this phase is presented as passed. Independent owner/Adie testing remains necessary.
