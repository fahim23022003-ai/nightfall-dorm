# Phase 6 independent QA

## Scope and execution

Agent C owns `tests/phase6_journey.gd`, `tests/phase6_inputs.gd`, authorized
legacy item-feedback fixture cleanup, and this phase's QA/regression evidence. Root
owns production fixes, release/export configuration and final delivery. Starting
baseline was clean `work` at `dfe4bc8f3cf4e4082d07d39bc190f8c09ae4458d`.
Engine: Godot 4.6.3 Linux, headless, isolated temporary profiles under writable
XDG directories. No real player profile is used. No Windows execution or human
play/listening evidence is inferred from these tests.

The user explicitly requested fresh full regular and extended regression. C runs
`bash tools/check.sh --extended` once, preserving its stdout and every generated
suite log. Both process exit status and `SCRIPT ERROR` / `Parse Error` / `ERROR:` /
nonzero `FAILURES=` counters are checked. A wrapper snapshots historical tracked
evidence bytes before running; regenerated old-phase data is copied into Phase 6
before restoring those historical files. Initial command results, duration and
restored paths are recorded in `regression-results.json`; the resumed tail is
recorded in `regression-resume-results.json` and final acceptance in
`qa-acceptance.json`.

**Regular and extended/tail status: PASS in documented segments.** The original
command completed all 74 regular suites plus core and import (76 clean assertion/
engine-error logs), then exited 2 before the extended block. Root registered the
two new tests by editing `tools/check.sh` while Bash was executing the live file;
its buffered read position shifted and it reported an unexpected EOF/quote.
The current file passes `bash -n`. This is an orchestration error, not a gameplay
or assertion failure. The original exit/log/results remain unchanged and are not
reported as a successful uninterrupted command. C resumes only the remaining
three extended suites, two balance fixture gates, four profile-process steps and
startup through an immutable Python command list. No passed regular simulation
is rerun. The two new suites pass independently as documented below.
Root's bounded ranks-header and Reaper-warning presentation fixes landed during
the run; later corresponding UI/horror/rank suites and D's affected rendered
retests cover those changes. Completed unrelated model suites are not repeated.

## New targeted release integration tests — PASS

### `phase6_journey.gd`: 68 checks, zero failures

This supplements previously separate tutorial, campaign and shop tests by using
one genuinely fresh temporary profile across the system boundaries:

1. Opening skip routes to the unchanged mandatory tutorial. Actual movement,
   navigation, E input, real tutorial purchases/income/repair/combat satisfy the
   nine objectives and save graduation.
2. Real Start Game / Prepare / Start Match controls launch stage 1. Navigation
   and E claim/sleep the player. A disclosed qualified combat fixture kills the
   activated Hunter; production tick seals and settles its terminal.
3. The ordinary result/Spin/skip/reveal acknowledgment and stage choice controls
   keep already saved stock unchanged; Next Stage opens stage 2 preparation.
4. The first victory's genuinely credited RM Cash funds a real Shop repair-kit
   purchase. There is no injected permanent RM or item stock.
5. Actual inventory Equip, stage 2 launch and real Hunter-controller damage
   precede KEY1 repair. Exactly one permanent item is spent; HP actually rises.
6. A new PlayerProfile instance reloads the same disk path and retains tutorial,
   stage unlock, earned RM balance, XP and consumed stock.

This is controlled engine integration evidence, not a natural human-earned match
or balance/time measurement. Tutorial's own recovery resources are temporary.
Result controls wait for their existing animation to enable before real clicks.

Retained initial/second/third logs document harness setup errors: dormant Hunter
correctly ignored direct fixture damage; then clicks were attempted during the
ordinary disabled result animation. Cascaded assertions are not product defects.
The final test activates its controlled Hunter and waits actual animation rather
than changing production behavior or emitting button callbacks directly.

### `phase6_inputs.gd`: 4,062 checks / 2,009 cases, zero failures

Seeded mutations, empty input, an oversized payload, incompatible fields,
controls, non-ASCII/full-width identifiers and bidirectional text exercise the
real Challenge decoder. Every response is controlled; accepted inputs reproduce
the canonical normalized code and rejected inputs have an explanation. The
oversized payload is rejected by the actual length limit.

Malformed item, cosmetic, Shop, stage and difficulty identifiers are submitted to
actual profile APIs. Every invalid operation is refused and both the reward
snapshot and saved file bytes remain identical. Tests use an isolated file and
clean it afterward. These input-boundary tests deliberately use direct API calls;
actual UI/mode integration is covered separately.

The initial log retains a harness assertion that incorrectly demanded original
case/whitespace preservation. The documented decoder intentionally accepts edge
whitespace and uppercases canonical codes. Final assertions correctly compare
that explicit normalization. GDScript literal NUL parsing warnings in that first
fixture were removed by using a valid runtime control character; they were not
application crashes or evidence of save mutation.

## Player-journey coverage map

| Journey | Evidence and limits |
| --- | --- |
| A: fresh opening/tutorial/campaign/reward/Next Stage | New same-profile journey; `onboarding_flow` and `campaign_flow`; controlled combat terminal, not natural play |
| B: progressed profile/loadout/Long Night/result/save | Premium preparation UI, campaign difficulty/round-trip, item/economy/Long Night simulations; prepared progression budgets |
| C: Hell/Reaper/item/result | Legendary/boss/difficulty integration and actual combat simulations; D actual rendering/audio |
| D: Shop/loadout/campaign/item persistence | New same-profile journey spends actual first-win RM and reloads consumed stock |
| E: Endless/intermission/checkpoint/resume/exit | Replay UI/transactions/retirement, 45 real Hunter approaches, bounded late damage; A long-run audit and D genuine earned profile renders |
| F: Challenge generate/import/play/compare | Replay UI/codes; six fresh engine workers, fixed-step complete traces; D real clipboard/result card |
| G: Practice/item/reset/exit/permanent safety | Replay Practice/UI exact permanent-field and file-byte signatures, all20 shared item effects |
| H: cosmetic unlock/equip/world/restart | Replay facts/cosmetic and UI save/stat-neutrality; D actual equipped world/raster checks |

These are representative journeys split across complementary real scene/model/
profile tests, not a claim that all eight were played naturally by a human.
Prepared fixture state is disclosed. No multiplayer/online verification exists.

## Save and transaction coverage

Existing fresh regression suites cover historical v1 progression migration,
profiles without pre-5C onboarding/reward blocks, old progressed 20-item saves,
missing safe defaults, malformed/future optional blocks preserved read-only,
atomic write/reward/Shop rollback and retry, durable purchased/consumed stock,
Endless interrupted checkpoint/resume/retirement second-save failure, bounded
local Challenge records, pity rollback/queued receipt boundaries and duplicate
claims. Frozen previous-writer fixtures are preserved. Neither profile paths nor
application name are changed by C.

## Remaining assessment

The full run exposes a historical `items_activation_feedback` teardown warning:
13 assertions pass, but its 0.3-second immediate process drain leaves eight
AudioStreamWAV and eight AudioStreamPlaybackWAV references at exit. The same
warning is present in the prior Phase 5D-2 historical log. A verbose reproduction
is preserved in `qa-item-feedback-leak-verbose.log`. With root's authorization,
only this fixture's post-shutdown drain changes to 0.6 seconds. Its affected
verbose rerun passes 13/0 with no engine warnings, errors or leaked instances in
`qa-item-feedback-drain-final.log`. No production audio code is changed. The
initial full run is not falsely called warning-free.

No confirmed C production failure has been found in completed checks. Root/D
reported two presentation defects (actual perk-slot header and decorative Reaper
warning overlap); C does not duplicate their implementation/raster ownership.
All ten resumed commands pass with exit 0, zero engine/assertion errors and no
warnings, including three extended simulations, eight strategy/two Endless
controlled balance fixtures, four fresh profile-process steps and actual startup.
The resumed segment takes 29.450 seconds; the completed original regular segment
ran 1,159.780 seconds before the live-script read interruption. These are test
wall-clock durations on Linux, not game FPS or human play times.

Both regenerated historical files (boss matrix and rank/reward balance JSON) were
copied into Phase 6 and restored byte-identical to the starting baseline. C's
final gate is ACCEPTED. Production checkpoint supplied by root is
`f5e6970280b365d2f5c3f0062323aa7e92b63ed9`; D separately verifies the bounded
presentation changes. No further test run is needed for documentation-only edits.
Native Windows, physical input/speakers, real hardware performance, subjective
horror/fun/strategy difficulty and human long-session behavior are UNVERIFIED.


## Selected fresh counters

| Acceptance | Passed evidence |
| --- | --- |
| Core |126 assertions|
| Endless |28,123 checks /45 actual approaches|
| Endless transactions /retirement |284 /21 checks|
| Codes |759 checks /six fresh worker processes|
| Pity /migration |20,180 /190 checks|
| Practice /facts-cosmetics |3,644 /25 checks|
| Replay UI |1,537 checks|
| Premium mechanics |172,343 checks /270 approaches|
| Navigation |57,056 checks /90 approaches|
| Room/map core /integration |15,348 /5,107 checks|
| Five-map simulations |144 completed,79 wins/65 losses,zero unresolved|
| Difficulty matrix |90 completed matches|
| Building/refund regressions |512 +421 checks|
| Audio assets/events |281 assertions /105 streams|
| New connected journey |68 checks|
| New input safety |4,062 checks /2,009 cases|

Repeated invariants are included in counters; they are not that many independent
scenarios. Simulated defeats are valid outcomes rather than test failures. Detailed
logs preserve actual results. Existing earned Level10/long-run evidence is also
audited by A; C does not relabel previously earned profiles as new human runs.
