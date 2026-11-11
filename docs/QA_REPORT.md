# QA report — Nightfall Dorm

Final validation uses **Godot 4.6.3 stable**, Linux, Codex Cloud, 11 November 2026. Tests execute production GDScript and the actual main scene. The later independent audit supersedes the initial 11-win/one-loss balance results; preserved older evidence is historical. See [AUDIT_TEST_REPORT.md](AUDIT_TEST_REPORT.md) for baseline failures, fixes, expanded simulations and assessment.

## Acceptance coverage

| Test | Actual exercised behavior | Final outcome |
|---|---|---|
| 01 | Editor import plus scan for parser/script errors | PASS |
| 02 | Main scene load; menu/help/settings/start/result UI | PASS |
| 03 | Continuous player movement through corridor and doorway, interact to claim, move to bed, interact to sleep | PASS |
| 04 | Empty/dead beds earn zero; occupied beds earn configured rates | PASS |
| 05 | Bed cost deduction, income change and prerequisite rejection | PASS |
| 06 | Door upgrade raises max HP while preserving existing damage | PASS |
| 07 | Rejected transactions preserve resources and gameplay state; negative/nonfinite costs rejected | PASS |
| 08 | Valid empty tiles; occupied/out-of-range rejection; all 36 tile rectangles inside rooms and clear of beds | PASS |
| 09 | Actual turret damage, range, cadence, upgraded damage/speed, heavy/relay effects and invalid-target rejection | PASS |
| 10 | Occupied-room targeting, movement, growth, retargeting and post-breach doorway exit | PASS |
| 11 | Door damage and cooldown; intact closed door protects sleeping survivor | PASS |
| 12 | Manual/facility repairs, HP cap and destroyed-door rejection | PASS |
| 13 | Five autonomous bots claim, walk to beds, sleep and spend; reserved-room allocation regression | PASS |
| 14 | Electricity production/spending; actual level-four utility effects | PASS |
| 15 | Controlled lethal damage and naturally earned victories | PASS |
| 16 | Real breaches and exposed-player catches cause defeat; elimination committed exactly once; defeat wins simultaneous terminal events | PASS |
| 17 | Model reset and actual Restart button restore clean match | PASS |
| 18 | Error-scanned startup, pause, terminal guards, adverse transitions, property tests and bounded full-match runs | PASS for exercised paths |

## Final executed results

- Gameplay suite: **125 assertions, zero failures**.
- Scene/UI suite: **19 checks, zero failures**. Actual viewport mouse events select tile two and build a generator there; other menu and result flows also use real Button signals.
- Audit regression suite: **71 assertions, zero failures**.
- Property suite: **20,000 seeded transactions**, including **18,007 rejections**, with **175,941 invariant checks and zero failures**.
- Basic natural simulations: **12 matches, nine victories, three defeats, zero unresolved**.
- Extended natural matrix: **144 matches, 72 active victories and 72 passive defeats, zero unresolved**.
- Frame-step probe: **27 matches**, no unresolved runs; terminal outcomes agree at steps 0.02, 0.05 and 0.1 seconds for every sampled strategy/room triplet.
- Isolated rate probe: **six scenarios**, identical 30-second counts at all three steps: 34 turret shots and 28 hunter attacks.
- Import and main-scene startup: clean error-scanned logs.

Counts represent assertions, checks or whole matches as labeled; they are not additive counts of distinct gameplay scenarios. Natural simulations use ordinary resources and legal production purchases. Controlled unit tests separately inject resources and positions to isolate rules. The extended matrix covers all six rooms and seeds 1–12; the frame probe includes a legal turret-focused purchase policy as an additional strategy.

## Representative natural match results

| Seed / room (one-based) | Passive | Balanced | Guard | Economist |
|---|---:|---:|---:|---:|
| 7 / room 2 | Defeat 68.8 s | Victory 125.5 s | Victory 127.8 s | Victory 125.7 s |
| 8 / room 3 | Defeat 41.9 s | Victory 134.7 s | Victory 146.4 s | Victory 142.4 s |
| 99 / room 4 | Defeat 94.4 s | Victory 149.7 s | Victory 149.7 s | Victory 149.7 s |

The expanded active matrix actually exercises advanced electricity spending, heavy turrets and enhancement relays in all 72 active matches. Some reach bed/door displayed level five. This is evidence of functional progression, not exact reference-game pacing. Automated balanced play wins all sampled rooms, leaving optimal-strategy difficulty and replay variety for wider playtesting.

## Reproduction and evidence

```sh
bash tools/check.sh
bash tools/check.sh --extended
```

The standard wrapper imports, runs core/scene/basic-simulation/audit/property/rate suites, starts the main scene and scans errors while preserving process exit failures. `--extended` adds bounded frame-step and 144-match matrices. In cloud, the wrapper configures writable XDG directories outside the checkout.

Final recorded commands returned exit status zero. The audit matrix was captured after final balance/timer changes; subsequent production edits were equivalent catalog-based initial door HP, feedback, and exposed-catch state bookkeeping. Default checks were repeated after those edits. Evidence is in `docs/evidence/audit-final-checks.log`, `audit-final-matrix.log`, `audit-final-timesteps.log` and `audit-final-rates.log`; refreshed per-command logs live under ignored `artifacts/`. The old `qa-final.log` records the initial implementation before this audit.

Bug details and independent assessment are in [AUDIT_TEST_REPORT.md](AUDIT_TEST_REPORT.md). Graphical results are separate in [AUDIT_VISUAL_REVIEW.md](AUDIT_VISUAL_REVIEW.md) and [VISUAL_REVIEW.md](VISUAL_REVIEW.md). Headless success does not prove graphics or physical audio quality. Windows execution/export, touch input, all graphics drivers and exhaustive long-session stability remain unverified. Exact Haunted Dorm numerical parity is not established.
