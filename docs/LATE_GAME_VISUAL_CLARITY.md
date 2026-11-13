# Phase 4 — Late-game visual clarity

## IMPLEMENTED

One bounded pass starting from `34bebd905d94af28af91c01832010508672a2f5e`, Godot 4.6.3, branch `work`. Only `scripts/dorm_presentation.gd` changes production code. Previous selection, upgrade feedback, door/ward layout and typed damage rendering are preserved.

Actual baseline screenshots confirmed two problems:

1. Arriving survivor NPCs shared nearly identical name positions; names collapsed into an unreadable cluster during a real Crusher door attack.
2. Adjacent Level 10 turret rings/spikes formed a gold visual mass in the genuine expanded wave-45 room, competing with building silhouettes.

Two fixes, within the limit of three:

- **Bounded NPC label layout:** stable room-ID lanes, compact dark backing, thin actor leader lines, and a short fixed list of side placements. Observed/threatened teammates have priority. Labels avoid each other, door health, Hunter silhouette, active typed damage, the open upgrade area and Team panel. Offscreen or obstructed labels may be suppressed; actual full names, room IDs, HP and spectating remain in the existing Team panel. Sleeping residents no longer duplicate floating names already available in room plaques/Team. No clock-driven shuffling, physics or AI changes; at most five candidates, six placement attempts each, with bounded blockers.
- **Quieter unselected prestige ornaments:** rings/spikes use 28% alpha, crown accent is subdued, and the extra animated orbit is reserved for selected structures. Original building art, prestige crowns, branch icons and level badges remain. Selected placeable structures retain full ornament detail. No interesting combat effect or projectile was removed.

Existing PHYSICAL/MAGIC labels, damage flashes, door health and upgrade controls were already readable and remain unchanged. No third redesign was needed.

## TESTED

- Godot 4.6.3 imports/launches successfully.
- New focused label checks: **30 passed, 0 failed**. Five tightly clustered controlled arrivals are identified in the representative test corridor at both 1280×720 and 1920×1080, with Reduced Effects on/off. Actual names/room IDs, nonintersecting bounds, deterministic stationary layout, observed/threatened priority, upgrade/Team protected areas, sleeping-label cleanup, Team identity fallback, isolated saved-profile bytes and unchanged resources/health/RNG are checked.
- Previous focused visual regression gate: **50 passed, 0 failed**. Actual selection and paid upgrade, exact costs, failed-upgrade feedback, physical/magic HP damage, bounded aggregation/expiry, Reduced Effects, horizontal Lab layout, real 16-slot expansion and checkpoint/profile compatibility remain passing.
- Independent rendered capture checks: **15 passed, 0 failed, process exit 0**. Normal, upgrade, physical combat, magical combat and genuine expanded Endless captures inspected, plus crowded 1080p and the actual clicked Team panel.
- Initial label spacing was too narrow for the collision margins, unnecessarily dropping names. Wider identity lanes plus an additional bounded side placement corrected the focused failure; passing evidence and initial diagnostic are retained. No failing tests were disabled.
- Hash proof records **127 other script/UID files unchanged** from the starting commit, including gameplay, AI, audio, saves, prices, rewards and menu logic.
- No whole regression suite, export/build, new dependency or save migration was performed.

## Rendered evidence

Raw, uncomposited game screenshots are committed under `docs/evidence/late-game-clarity/`. Root and the independent visual reviewer inspected the actual output.

| Requirement | PNG relative to evidence directory |
|---|---|
| A — Crowded combat before | `before/03-physical-combat-720.png` |
| B — Crowded combat after | `after/03-physical-combat-720.png` |
| C — Expanded Endless after | `after/04-earned-endless-sixteen-720.png` |
| D — Crowded NPC identification | `after/08-crowded-team-identification-720.png` |
| E — Crowded gameplay at 1920×1080 | `after/07-crowded-combat-1080.png` |

Additional early, selected-upgrade and positive magical-hit frames are included. The after-combat frame shows four nonoverlapping world names; the fifth actor is offscreen. The opened Team panel shows all five full names and room/health information. Do not confuse the all-five controlled layout test with this four-visible-actor screenshot.

These are Linux Godot engine renders using isolated test profiles, controlled temporary wallets/seating and real gameplay APIs. Actual naturally claimed NPC arrivals and a positive door hit are captured. Late Endless restores a read-only copy of the genuinely earned wave-45 checkpoint `docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json`, unchanged. The wave-45 scene is an intermission/preparation view, not active late-wave combat. This is not an uninterrupted human playthrough. User saves are not overwritten. Manifests contain image dimensions, hashes, source identity and setup disclosures.

## Performance and limitations

New layout alone: 1,000 calls took 39.68–41.63 ms per configuration in the final Linux headless test (about 0.040–0.042 ms/call). This is a bounded helper measurement, not full gameplay performance.

Independent same-scene Linux Mesa llvmpipe redraw probe: 90 forced redraw waits per version after 20 warmups. Baseline mean **32.709 ms**, p95 **38.690 ms**; after mean **33.508 ms**, p95 **40.244 ms**. The observed mean difference is **+0.799 ms (about 2.4%)**. Sequential shared-environment timing is noisy; it shows no substantial regression in this small sample, but is not statistical proof, FPS/CPU profiling, a long-run test or a Windows benchmark. Raw timing evidence is retained.

**UNVERIFIED:** native Windows execution/performance and subjective human usability. No human approval is implied by automated passes.

Remaining weaknesses: packed 16-slot rooms still contain dense original crown/branch art; leaders can be long in a tight arrival cluster. Safe suppression is intentional when there is no free label position; Team remains the reliable complete roster. This pass improves readability without claiming perfect labeling in every possible configuration.

No required scenario is incomplete. No gameplay balance, AI, Reaper mechanics, upgrade costs/stats, expansion, reward, save format or main-menu changes. Stop after this focused phase.

The final delivery supplies full-commit GitHub PNG links after normal push verification. The Git commit containing this document is the checkpoint identity; local HEAD is compared with remote `work` rather than inferring push from commit success.
