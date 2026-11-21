# Phase 22 · Final UI Refinement

The desktop preview puts all 15 machines in four browsable categories. A card shows its purpose, actual price and availability. Hover or keyboard focus reveals the Level 1 stats and footprint. Choosing an affordable machine opens placement. The machine inspector shows what an upgrade changes, what it costs and what the machine has contributed. Selling requires a second action that shows the actual refund.

[Phase 21 and Phase 22 side by side](comparison.jpg) · [Original Phase 21 catalogue](../phase21/low/09-build.png) · [Phase 22 catalogue](build.png) · [Machine inspector](machine-inspector.png) · [Sale confirmation](sell-confirmation.png)

## Playtest

Extract the Windows ZIP and run **Play Phase 22 Preview.cmd**. Low starts at 960×540 with a separate test profile. **Play Performance Preview.cmd** uses the previous fallback and its separate profile. The Phase 21 release also remains available. Both videos below use real mouse and keyboard events in Linux Godot at normal speed, 960×540 and 30 fps. The dummy audio driver produces silent footage.

[Windows ZIP](https://github.com/fahim23022003-ai/nightfall-dorm/releases/download/phase22-ui-refinement-preview/NightfallDorm-Phase22-Windows-x64.zip) · [Installation and controls](../../PHASE22_PLAYTEST.md) · [UI walkthrough](walkthrough.mp4) · [Three-lesson tutorial](tutorial.mp4)

## Interaction tests

- The independent catalogue test passed 93 checks across the 15 machines. The inspector passed 44, including paid upgrade, cancellation and exact refund. The progression-menu test passed 41 across navigation, per-difficulty preparation, a paid Shop purchase and perk equipment.
- On Low, a 227-check walkthrough exercised blocked placement, moving and undoing the same machine, paid upgrade, sale cancellation, exact confirmed sale proceeds, emergency Ward payment and large reading text in Help. A later 245-check release-source run verified those transactions, the fixed Repair hint, Team, placement cursors and session recall for Settings and Inventory. Godot captured both desktop resolutions. The published gallery prioritizes Low.
- The tutorial uses actual movement, claiming, sleep, Build, Cancel, Dynamo and Needle purchases, and a real hit. Both presets passed 50 checks on the screenshot route. This caught an early defect in which the lesson inspected the overlay instead of its active course, and opened the wrong category. The final compact lesson shows exactly one machine. [Dynamo lesson](tutorial-dynamo.png) · [Needle lesson](tutorial-needle.png)
- Victory and defeat were settled by the game model. Separate native tests opened Timeline eight times per outcome and returned with Back or Escape. The tests checked the wallet and award record throughout and passed 63 and 64 checks respectively. The defeat-to-purchase-to-equip route passed 85 checks. [Victory](victory.png) · [Defeat](defeat.png) · [Timeline](timeline.png)
- The regular mechanics suite passed 136 assertions, scene smoke 33, Full Grid saves 64, procedural V2 persistence 62, Story progression 620, lobby integration 89, weapon feedback 148, Player First 27 and Campaign profile 89. Separate processes wrote and reloaded a settled profile, checked its rank and audio settings, and rejected duplicate settlement. The build keeps the existing save formats, prices, footprints, damage, Story tracks and Hunter rigs.

## Owner refinement status

**VERIFIED** means an implemented path was exercised. **COMPLETE** describes implementation where the remaining judgment is artistic, ergonomic or hardware-dependent. **EXPERIMENTAL** marks a narrower option with a stated boundary.

| # | Refinement | Status and observed behavior |
|---|---|---|
| 01 | Contextual actions | VERIFIED. Move, Range, Undo and Sell follow the actual selection and eligibility. The Team shortcut stays inside More. |
| 02 | Panel positioning | VERIFIED. The placement card anchors opposite a far-right room. The compact lesson drawer leaves floor space visible. Opening drawers preserves camera control. |
| 03 | Affordability | VERIFIED. Build and Shop use actual quotes, holdings and unlock reasons. |
| 04 | Immediate feedback | VERIFIED. Placement, blocked cells, upgrade, refund, equipment and repair readiness reflect the real operation. |
| 05 | Building hover details | VERIFIED. Focus and hover select a fixed detail pane with the appropriate artwork, footprint and stats. |
| 06 | Icon language | COMPLETE. Existing Build, Repair, Ward, inventory, resource and progression icons are reused across the relevant menus and guide. Controls also carry text. |
| 07 | Shortcut hints | VERIFIED. B, R, I, G, Q, Esc, V, O, Z and F are shown in context. |
| 08 | Cleaner selection | VERIFIED. One click on an eligible card starts placement. The session remembers category and recent machine. |
| 09 | Selected states | VERIFIED. Category checkmark, focus outline, selected card, availability text and disabled Place distinguish interactions. |
| 10 | Story progress | VERIFIED. Difficulty-specific level, clear progress and upcoming checkpoint come from the existing Story track. |
| 11 | Empty states | VERIFIED. Inventory starts with owned/equipped stock. Browsing unowned stock is explicit. Shop shows the actual shortfall. |
| 12 | Back and Resume | VERIFIED. Match Help pauses. Escape restores play. Archives, Classic Campaign, preparation, Timeline and Settings were navigated with actual input. |
| 13 | Adjustable scale | EXPERIMENTAL. Normal and larger reading text apply to Settings descriptions, Help and inventory descriptions for this session. The fixed HUD and full interface retain their designed sizes. |
| 14 | Crisis HUD | VERIFIED. Critical door HP, the repair shortfall or timer, and emergency Ward are visible. A funded Ward spent 6 Electricity through its original command. |
| 15 | Action cursor | VERIFIED for valid and blocked placement. World placement uses a crosshair or blocked cursor, machines use a pointing hand and middle-drag camera movement uses the drag cursor. The grid also describes the obstruction. |
| 16 | Visual inspection | VERIFIED. Machine art, live state, current/next values, combat receipts and expandable detail share one inspector. |
| 17 | Nonblocking hints | VERIFIED for catalogue and action dock. Build detail has a fixed pane. Hovering Repair shows a mouse-ignoring left-edge hint. Other menus retain Godot's native tooltips. |
| 18 | UI sounds | COMPLETE. The existing mixer routes navigation, cancellation, confirmation, failure, purchase and equipment cues. The captured videos are silent. Listening quality remains open for owner review. |
| 19 | Menu position | VERIFIED for Build and Settings. Inventory retains the selected owned item when still available. These choices are session-local. |
| 20 | Destructive confirmation | VERIFIED. Cancel keeps the asset. Confirm rechecks the machine identity, level, specialization, eligibility and quoted refund before selling. |
| 21 | Status communication | VERIFIED. Ready/locked, valid/blocked, critical door, equipped state and selected category use text or symbols in addition to color. |
| 22 | Reward cards | VERIFIED. Values come from settlement. Zero rewards use compact text. Reopening Timeline preserves cash and XP. |
| 23 | Transitions | VERIFIED. The retained catalogue changes category immediately. Back, Resume and modal closure were exercised. The offline lobby keeps its original ready and loading rules. |
| 24 | Automated cleanliness | VERIFIED on the tested desktop flows. Mouse hit targets, viewport bounds, keyboard/focus and screenshot review exposed clipped Repair and Cancel hints, which were corrected. Some secondary controls still render at roughly 10–11 physical pixels on Low. |

[Calm HUD](hud-calm.png) · [Critical door](critical-door.png) · [Repair hint](repair-hint.png) · [Blocked placement](placement-blocked.png) · [Settings](graphics.png) · [Help](help.png) · [Owned inventory](inventory.png) · [Shop](shop.png) · [Ranks](rank.png) · [Story preparation](story-prepare.png)

## Performance

Godot 4.6.3 Compatibility ran on Linux Mesa llvmpipe. The fixed Story fixture used seed 1527566656, player room 3 and one paid Needle. Each surface had five warm-up frames and 45 measured frames with a fixed simulation step of 1/60 s. We reused the Phase 21 HUD measurements. Three final-design HUD samples include two optimization passes and a release-source pass. The latter includes the left-edge dock hint. Scheduling and host load affect the tails.

| Workload | Phase 21 median / p95 ms | Phase 22 median range / p95 range ms |
|---|---:|---:|
| Low Build | 20.91 / 24.38 | 23.71–27.13 / 30.97–36.30 |
| Low placement | 19.28 / 21.49 | 20.24–24.88 / 25.82–28.12 |
| Low active combat | 17.55 / 23.06 | 17.30–20.49 / 19.22–24.68 |
| Low paused Help | 19.67 / 21.34 | 10.92–14.80 / 11.60–24.85 |
| Standard Build | 40.94 / 50.33 | 42.65–48.19 / 55.73–89.71 |
| Standard placement | 35.35 / 41.27 | 36.92–44.06 / 44.63–63.97 |
| Standard active combat | 33.25 / 45.21 | 33.35–38.53 / 46.66–50.95 |
| Standard paused Help | 41.59 / 49.51 | 19.29–23.14 / 26.49–35.17 |

The first large catalogue reached 28.51–29.69 ms Low median and 34.56–44.56 ms p95. Caching the visible category's original art and static row labels improved that candidate. Phase 21's smaller catalogue still renders faster. The shipping UI keeps the room and combat live while selecting a building. The fully opaque Help and Settings screens can skip drawing the covered world.

The tutorial screenshot harness includes synchronous framebuffer readbacks and PNG saves. To separate those costs from ordinary play, we also replayed the same course on Phase 21 and the final Phase 22 design with screenshot writing disabled. Phase 21 ran twice from the archived reference source. Gameplay events, camera, simulation, cues and input stayed active.

| Tutorial without screenshot writes | Phase 21 median / p95 ms | Phase 22 median / p95 ms |
|---|---:|---:|
| Low · two runs | 24.95–25.72 / 33.95–36.43 | 22.22–24.55 / 37.89–39.07 |
| Standard · two runs | 37.26–40.25 / 52.94–58.98 | 36.13–36.23 / 49.12–49.25 |

With screenshots enabled, the release-source Low walkthrough measured 23.66 ms median, 53.71 ms p95 and 66.07 ms p99. Phase 21 recorded 23.51, 49.54 and 74.93 ms. Standard measured 38.15, 91.96 and 100.73 ms against 36.82, 84.48 and 95.55 ms. Low spikes remain a playtest priority. No native Windows or Intel UHD performance, human usability rating or owner approval is claimed.

The final release-to-present probes passed 337 checks at each resolution. Median measured category switches were 42–44 ms on Low and 97–98 ms on Standard. Switching between Graphics and Audio measured 36–39 ms on Low and 68–70 ms on Standard. These input-to-present measurements include scheduling and rendering.

[Raw timings, layout checks, settlements and transition samples](metrics.json) · [Windows package receipt](windows-package.json)

## Verification boundaries

Four specialists handled the catalogue, machine inspector, progression menus and native input QA in separate file scopes. The lead integrated the changes, checked screenshots, investigated timing regressions, tested profile persistence and verified packaging. The embedded Windows x64 Godot pack was exercised under Linux. The public ZIP was downloaded and checked against its SHA-256 and archive CRC. Native Windows execution and listening review remain pending.
