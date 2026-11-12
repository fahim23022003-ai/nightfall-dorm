# Phase 6 — final quality audit and Windows release candidate

Version **0.6.0-rc1**, Godot **4.6.3 stable standard**, private `work` branch.
Audit date: 12 November 2026 (Asia/Singapore).

**RELEASE CANDIDATE, PENDING WINDOWS VALIDATION.** Existing systems, focused
presentation repairs, fresh regular/extended checks, actual rendered/audio/stress
audit and a real private Windows cross-export are complete. No confirmed Critical
or High issue remains in accepted tests. This is not a fully released or
human/Windows-certified game.

## Baseline and responsibilities

Started with a clean working tree on `work`, HEAD and GitHub both
`dfe4bc8f3cf4e4082d07d39bc190f8c09ae4458d`. The user-supplied reference omitted
its final `d`; the full actual Git ID is retained here. Recovery tag
`pre-phase6-dfe4bc8`, baseline checkpoint `32f7457`. Main is unchanged.

Read AGENTS, project/export configuration, latest progress and Phase 5D-1/5D-2
reports. Inspected actual catalogs, UI/model/AI/persistence architecture, existing
checks, asset/font/audio provenance and historical Windows export records.
The runtime is Linux, with Godot 4.6.3 and Mesa software rendering. Export
capability is separate from native Windows runtime capability.

Root performs Agent B's production/fix/export role. C owns independent full
regression and fresh journey/input tests, A a bounded fresh balance/Endless audit,
and D actual rendering/audio/performance. Exclusive ownership prevents concurrent
production edits. Specialists stop after their evidence; no new gameplay system,
Android development, public release or main merge belongs to this audit.

## Full system inventory

The project has one main scene, `scenes/main.tscn`; code builds its mode/UI layers.
Screen count is not scene-file count. The following are implemented existing
systems, verified through actual source plus the named current audit coverage:

| System | Integration and audit coverage |
| --- | --- |
| Five campaign stages/five haunted maps | StageCatalog/MapCatalog, CampaignInterface/Profile, maps/campaign regular suites, A paid strategy runs, D all-map focused/overview renders |
| Normal, Long Night, Hell | RankCatalog difficulty rules, actual model/controller, difficulty matrices, A three-mode strategies, D loadout cards |
| Opening, creator title, mandatory nine-step tutorial | OnboardingCatalog/controller, fresh startup/flow suites, C new complete tutorial→campaign journey, D actual title/opening frames |
| Dynamic scenery/weather/noncombat creatures | HauntedEnvironment/MapPresentation, visual/horror suites, D map/animation/weather renders; these are not additional attacking enemies |
| Screams, laughs, tension, death/corpse presentation | HorrorFeedback/AudioDirector/DormPresentation, horror/audio/boss suites, actual D engine events/mixer capture |
| One Hunter/three archetypes/legal navigation | HunterState/StrategyCatalog, navigation/mechanic/difficulty suites, fresh A cases and real combat renders |
| Grim Reaper/special attacks | BossCatalog/controller, architecture/audio/QA/matrices, A 66 actual milestone waves, D transform→telegraph→impact |
| Door repair, purchases, upgrades, sales, Level 10 | Catalog/RoomState/MatchModel/economy, Phase1/replay/strategy regressions, exact paid ledgers and distinct Gold/Electricity refunds, A earned Level 10 |
| Four turret branches/room advantages/contracts | StrategyCatalog/controller, contracts/accounting tests, A five-map/three-trait/four-branch coverage, D branch/HUD rendering |
| Seven ranks/perks/twelve achievements/stage choices | RankCatalog/RewardCatalog/Profile, progression/rewards suites and C real tutorial→stage1→reward→next-stage journey |
| Twenty consumables and Legendary limits | ItemCatalog/ItemEffects/Profile, all existing item/combination suites, Practice and permanent stock transactions |
| Lucky Spin/pity/inventory/RM/shop | Saved reward draw and rollback architecture, replay pity/transaction tests, C genuinely funded shop→equip→use→reload journey |
| Endless/records/checkpoints | EndlessRun/ReplaySnapshot/ReplayProgress, replay suites, A 222 new earned waves and 12 fresh-profile resumes |
| Shareable Challenge Codes/results | Whitelisted versioned checksum codec, fixed-step real model, previous six-process reproduction plus fresh current code regressions and C malformed-input tests; no online verification |
| Four earned cosmetic designs | CosmeticCatalog/Presentation/Profile, stat-neutrality/unlock/save tests, D gallery/in-world overlays |
| Defeat analysis | Bounded actual match telemetry, facts/terminal tests and rendered UI; no speculative invented cause |
| Dedicated Practice | Real combat with temporary wallet, no persistent reward/stock changes, mode-isolation/UI tests, D resets/stress |

## Implemented / fixed

No new gameplay features or combat/economy balance changes were introduced.

- **LOW:** ranks page incorrectly always said one permanent perk slot, including
  Master/Mythic profiles. It now displays actual slot count and plural correctly,
  retaining unlock hints. D tests Bronze/Master/Mythic at both resolutions.
- **MEDIUM:** the fading Reaper awakening banner overlapped the first genuine
  special-attack telegraph. Actual attack/surge warnings now take priority over
  the decorative banner; transformation, attack timing/damage/audio are unchanged.
- **Release preparation:** explicit 0.6.0-rc1 project identity and Windows PE
  version 0.6.0.0, official matching templates, repeatable release export script,
  embedded-pack audit and packaged license/test/version notices.
- Replaced obsolete limitations describing one map/one archetype and wrote
  nontechnical Windows playtest/save-preservation instructions.

## Tests and failures/resolutions

C's new `phase6_journey.gd` passes **68 checks**: a genuinely fresh profile walks
through all nine tutorial objectives; a controlled qualified campaign victory
funds an actual Shop purchase; actual inventory selection, stage2 attack, KEY1
Repair and disk reload verify the integrated state. No permanent cash or stock
is injected. Controlled victory is not claimed as unaided human play.

`phase6_inputs.gd` passes **4,062 checks**, including 2,009 seeded empty/long/
malformed/control/Unicode/incompatible-code inputs. Invalid item/cosmetic/shop/
stage/mode identifiers leave profile values and bytes unchanged. Valid whitespace/
case normalization is accepted intentionally rather than called a security defect.

All74 existing regular suites plus core/import produce76 passing logs. The original long-running command then
exited2 before entering extended checks because root edited the running Bash
script in place to register the two new tests, shifting its reader offsets.
Current `bash -n tools/check.sh` passes. This runner error is retained; C resumes
only the remaining extended/profile/startup commands from an immutable list.
All ten remaining commands pass with exit0, no engine errors, no nonzero failure
counters and no warnings: three extended simulations, two controlled balance
checks, four profile-process steps and startup.
[Initial run receipt](evidence/phase6/regression-results.json) and
[completed remainder](evidence/phase6/regression-resume-results.json) preserve
this segmented execution rather than misreporting an uninterrupted exit0. The two new registered tests independently pass,
not falsely counted inside the earlier regular loop. The unmodified established
suites cover navigation, Reaper attacks, branches/traits/contracts, all 20 items,
Legendary combinations, currency/refunds/discounts/shop, achievements/rank,
migration/recovery/reward rollback, replay mode isolation, checkpoint/pity,
cosmetics/facts and actual scene/startup/profile process round trips. Each
process exit and engine error output are checked, not exit status alone.
[Independent QA summary](evidence/phase6/qa-summary.md) and
[final acceptance receipt](evidence/phase6/qa-acceptance.json) record accepted
coverage and exact log dispositions.

Retained development failures are distinguished from accepted results:

- C fixture initially damaged a dormant Hunter or clicked before result fade;
  corrected actual combat setup and animation waits, then passed the full journey.
- Input fixture initially expected normalized case/space to reject; corrected
  expectation to canonical validated equivalence, not a weaker codec rule.
- A's first resume comparator confused JSON numeric/Vector2 representation with
  state loss. Final comparison normalizes both persisted representations and
  exactly compares all fields without tolerance or omitted fields. No gameplay
  or save rule was changed.
- Root's first banner patch accessed the draw Control as a model. Actual D
  rendering caught a SCRIPT ERROR despite the harness assertion counter reading
  zero failures. It was rejected, retained, and corrected to HorrorFeedback's
  tracked model. Final affected rendering passes without engine errors.
- Initial embedded-pack fixture exited before audio/node drain and warned of
  leaked objects. Normal cleanup/drain produced a clean11-check pack test.
- Existing item-feedback fixture also quit before audio drain (a historical
  warning reproduced with verbose8 stream/8 playback references). Only its
  shutdown wait changes0.3→0.6s; the affected13-check verbose rerun is clean.
  The initial full log warning remains disclosed, not rewritten.

## Gameplay and balance

[Fresh bounded A audit](evidence/phase6/balance-summary.md) runs **16 campaign
cases**: fourteen prepared policies give ten wins/four defeats, while two
zero-XP/no-perk/no-stock Stage1 Normal strategies both win. Three archetypes,
three modes, branches/traits and finite Legendary/control budgets are covered.
Defeat under Hell strategies is an outcome, not automatically an implementation
failure. No forced win-rate target or blanket price reduction was applied.

Eight fresh earned-economy Endless runs clear **222 waves**, including **66 actual
Reaper milestone encounters**, **12 fresh-profile load/resumes** at waves5/20/60,
and eight legitimate safe exits followed by rejection of duplicate exits/rewards.
All eight earn a paid Level10 weapon; four actually deal L10 damage and four prove
availability only because combat targets elsewhere. The Normal fortress clears85
waves in3060.6 model seconds; Hell clears65 in1946.2s with exactly four Frost/one
Freeze over that run. No live HP/currency/position/time/wave injection is used.
Prepared progression/finite item budgets and scripted fast decisions are disclosed.

Earlier 39-run/130-wave Phase5D2 results are historical context, not counted as
fresh Phase6 tests. No observed defect justified a balance change. Human fun,
approachability and long-session strategic fairness still require human feedback.

## Performance observations — Linux only

Fresh headless long-run object count stays **1512** from wave60 onward. Static
memory changes **+96,336 bytes Normal /+32,128 Hell** include retained auditor
rows. Observed peaks: eight projectiles, nineteen combat events, 128 presentation
records; cleared checkpoints contain zero projectiles. These are finite traces,
not an infinite-run proof. The harness's final `checkpoint_bytes` is the closed
profile after safe exit (about2.7KB), not an active checkpoint-size measurement.

D's matched software-rendered preparation samples are short shared-host windows:

| View | Baseline mean / p95 ms | After mean / p95 ms |
| --- | ---: | ---: |
| 1280×720 |35.55 /47.52|36.14 /49.22|
| 1920×1080 |57.76 /71.66|57.14 /64.71|
| 720 Reduced Effects |37.55 /53.64|33.51 /40.88|

They do not establish an optimization, hardware FPS, Windows compatibility or
statistical improvement. Other audit processes share the host. A separate30s
actual Practice trace settles near55.7–55.8MB,116 nodes/2317–2320 objects, with24
audio children retained across12 resets. The final60s actual dense-render fixture uses16 genuinely purchased Level10
weapons, a declared temporary500kG/500kE budget and artificial1e9HP target. It
is stress evidence, not natural affordability/balance. It records1097 shots /
1480 frames,40.547ms mean /53.947ms p95, peak19 projectiles, objects2282–2286
sampled/peak2291,116 nodes,24 audio children and53.94–54.23MB static memory.
Presentation remains capped128. Eleven low-priority audio events drop under this
deliberate load; no critical backlog or missing stream appears.

## Visual/audio assessment

D's fresh broad baseline passes85 checks and captures57 actual PNGs at720/1080:
menus, all three difficulty selectors, shop, all inventory pages, ranks/perks,
achievements, spin/results, replay screens and all five maps. Source screenshots
are unedited engine output with fixture provenance; contact sheets are review
aids. Final accepted gates pass **314 checks/0**:85 broad baseline,45 details,162 dense
and22 warning-priority checks. There are **88 actual PNGs**:57 baseline,27 final
and4 explicitly preserved defect/rejected-attempt frames. D and root inspected
actual fixed warnings/rank counts; root also opened the dense final frame.
[Rendered review](evidence/phase6/render-review.md),
[screen index](evidence/phase6/render-index.md) and
[hash/dimension manifest](evidence/phase6/render-manifest.json) record exact sources.
Only the expected llvmpipe unsupported-VSync warning remains in accepted render
logs; the rejected first-fix script error is not counted as an acceptance pass.

Original Gothic materials, dimensional buttons/focus, resource icons and local
fonts remain coherent/readable in reviewed paths. Retained simplified directional
animation/repeated pads are art limits, not a new art-engine rewrite. Reduced
Effects and saved audio settings remain. Subjective production-quality judgments
cannot be certified by automation.

Actual baseline Master-bus recording is12.260136s stereo44.1kHz PCM, peak0.02172852
full scale, RMS0.00417837 and zero full-scale samples;105 streams/no missing assets.
Two cumulative low-priority drops span rapid prepared transitions, not a claim
of normal-time dropout. D exercises real Reaper/Inferno/Overdrive events. Physical
speakers, perceived mix/loudness and human listening remain UNVERIFIED.

## Save/economy safety and input validation

Tests use isolated profiles, never the user's ordinary save. PlayerProfile writes
a temporary file, flushes/decodes it, preserves a valid old generation as `.bak`,
then renames. Unknown future/malformed data is protected through existing recovery/
read-only rules. Existing old-save/migration, interrupted write, rollback/retry,
reward/stock/discount/refund cases are exercised by current regular QA.

Endless retains one between-wave checkpoint with durable spent-stock/use caps;
no reload milestone farming. Challenge/Practice use temporary loadouts and cannot
consume permanent stock or grant campaign/Endless rewards. Challenge permits
only validated fields/IDs/rulesets; code is data, never executable script.
Local saves are offline data, not server-enforced tamper-proof accounts.

## Windows export and licenses

Official Godot4.6.3 templates were absent in the resumed runtime. Downloaded the
full official1,255,918,323-byte archive, verified its SHA512 against official
release SHA512-SUMS, then extracted only Windows x86-64 release templates.
[Template verification](evidence/phase6/template-verification.json).

The first release export succeeds; actual PE x86-64/embedded PCK structure and
11 actual Linux-engine pack checks pass. They validate packaged main scene,
startup/profile/UI, fonts, icon,105 audio streams,20 items/five maps, Practice
and exclusion of docs/tests/tools. Native Windows execution is not performed.
The final rebuilt ZIP is `/workspace/NightfallDorm-Phase6-Windows-x64.zip`,
**51,304,125 bytes**, archive SHA256
`d60963d26dfa2a789efefdc7586c3137421965b6b3daa3797407ce155ba93537`.
[Final artifact receipt](evidence/phase6/windows-artifact.json) gives executable
hash/size, embedded pack size and exact source
`f5e6970280b365d2f5c3f0062323aa7e92b63ed9`. Final editor import/export/pack gates
exit0 with clean error scans; ZIP CRC/content checks pass. PE version is0.6.0.0.
The archive includes executable, VERSION.txt, SHA256SUMS, playtest guide and four
Godot/font notice files. This is an actual unsigned private testable Windows
artifact produced by Linux cross-export, **not** a native Windows test pass.
The binary is a workspace download, not stored in the GitHub source ZIP.

`tools/windows/export_release.py` builds with matching engine/templates, scans
errors, checks PE/pack, audits the pack with Linux Godot, and bundles executable,
version/checksum, playtest guide and notices. Native export procedure is in
[Windows playtest guide](WINDOWS_PLAYTEST_GUIDE.md). Binaries remain ignored Git
outputs; source/preset/evidence are private Git checkpoints, not a public release.

Font metadata confirms DejaVu Sans/Serif and Grenze Gotisch; bundled DejaVu
license and SIL OFL1.1/attribution are retained. Official Godot MIT license and
COPYRIGHT third-party notice are included in the private ZIP. Original procedural/
illustrated art and synthesized audio provenance is in ART_MANIFEST/AUDIO_SOURCES;
no paid/runtime-downloaded asset or copied commercial-game content is introduced.
This review preserves notices; it does not assign a new license to the user's game.

## Known limitations / unverified / human testing

[Current known limitations](KNOWN_LIMITATIONS.md) and
[nontechnical Windows checklist and bug report format](WINDOWS_PLAYTEST_GUIDE.md).
Native Windows launch, GPU/high-DPI/input/audio, human difficulty/enjoyment,
physical speaker balance and indefinite-session stability remain UNVERIFIED.
Challenge shared outcomes are self-reported, reproducibility is conditioned on
supported ruleset/engine/inputs, and Endless resume is between waves only.

## Release candidate status and Git delivery

**RELEASE CANDIDATE, PENDING WINDOWS VALIDATION.** No confirmed Critical/High
functional defect remains in the accepted finite scenarios. The remaining native
and human checks are explicit above, including enjoyment and audio quality.
No public release, automatic sharing, main merge or new feature phase occurs.

Runtime/build source: `f5e6970280b365d2f5c3f0062323aa7e92b63ed9`, already verified
pushed to private `work`. Complete documentation/evidence delivery receipt will
record its actual remote comparison after the remaining source/evidence push.
The Windows binary is separately identified by the checked artifact receipt.
