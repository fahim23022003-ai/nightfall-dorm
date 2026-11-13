# Phase 5 — Adaptive combat readability

Completed one lightweight presentation pass from `c2d4a7a2183126ac5c5658dc61582e60bd98c136`, branch `work`, Godot 4.6.3. No agents, new dependencies, builds or gameplay systems.

## Implemented

- Preserved stable identity lanes. Sustained nearby clusters use ALLIES ×N after 0.35 seconds; a wider 96px leave radius and 0.8-second exit hold prevent mode chatter. Entry uses 58px for three nearby allies; two very close actors with long identity lanes can also group. Observed/threatened individuals stay separate. Full actual identities remain in Team. Display state is bounded to the existing five teammates and resets between matches. Grouping adds no clickable overlay or screen-wide panel.
- One shared high-level badge renderer aligns turret/support badge size, baseline and contrast. Badges yield to door HP in cramped rooms. Dense rooms soften unselected specialization rings; branch icons, earned art/crowns, meaningful combat effects, selected premium styling and functional values remain.
- During a real own-door threat, automatic positive upgrade/sale messages yield to the existing door warning. Failed-action feedback and explicitly opened Help remain available. Existing HP, threat, typed damage and contextual actions are preserved; no extra HUD panel or forced menu closure.

## Wave-45 consistency

**No status bug found or gameplay change made.** The canonical earned checkpoint contains one living player, five dead AI teammates (door HP zero), and their retained buildings. Runtime restore confirms TEAM 0/5 ALIVE. Visible rooms are not proof of living occupants. Actual restored AI building counts are 7, 7, 4, 5 and 6; the player retains 12 buildings and 4565.93 door HP. Screenshot rounds HP to 4566/6912.

## Tests and fixes

- **19 new focused checks / 0 failures:** delayed grouping, repeated redraw stability, enter/exit hysteresis, threatened identity priority, restored sparse names, short/long pair cases, transient overlap, reset, real checkpoint status, unchanged checkpoint, positive-message priority, errors/Help visibility and isolated profile bytes.
- **50 existing gameplay visual checks / 0 failures**, plus **30 existing label checks / 0 failures**: real mouse selection/paid upgrade, resources, typed HP damage, feedback limits/expiry, Reduced Effects, Lab layout, expansion and checkpoint/profile compatibility.
- **22 final runtime capture/input checks / 0 failures**, exit 0. Real mouse Team/high-level selection; T opens/closes Team; Escape closes the selected-building panel. Project imports and launches on Godot 4.6.3.
- Initial unit fixture moved the presentation clock backwards after reset; corrected the fixture, preserving the initial diagnostic. No product behavior was altered to satisfy it.
- Screenshot review caught a badge masking part of door HP; badges now move away from protected door information. Final wave-45 frame inspected with full HP visible. Initial capture was before grouping hold elapsed; final after capture waits 0.45 seconds of presentation time with the gameplay state frozen.
- A stale local model variable affected the first baseline fixture's printed wave diagnostic; corrected it for final restore/input checks. The baseline combat PNG is valid and unchanged; the corrected runtime log and direct checkpoint checks establish actual wave status.
- Hash evidence verifies 125 other script/UID files unchanged from baseline. No AI, balance, prices, stats, expansion, damage mechanics, rewards, save schema or main-menu edits. Only three production files change presentation.

## Actual rendered evidence

All six raw PNGs are in `docs/evidence/adaptive-readability/`, with dimensions, hashes, source identity, capture fixture and logs in `manifest.json` and adjacent evidence.

| Requirement | PNG |
|---|---|
| A Before crowded NPC combat, 1280×720 | before/A-before-crowded-720.png |
| B After crowded NPC combat, 1280×720 | after/B-after-crowded-720.png |
| C High-level expanded Endless, 1280×720 | after/C-endless-wave45-720.png |
| D Selected Level 10 Mirror Barrier, 1280×720 | after/D-selected-high-720.png |
| E Crowded combat, 1920×1080 | after/E-crowded-1080.png |
| F Team panel with clustered NPCs, 1280×720 | after/F-team-cluster-720.png |

The images were personally inspected. After combat shows ALLIES ×4 plus one individual name, reducing long leaders; Team shows all five full identities. The positive upgrade toast no longer competes with the active door warning. Selected Barrier and inspector remain visible.

These are real Godot viewport captures from isolated profiles and controlled temporary resources/seating, using real building, damage and input paths. NPC identities may vary by isolated profile. The wave-45 image restores the genuine earned checkpoint read-only and depicts intermission/preparation, not active late-wave combat. No mockups, generated gameplay, or claim of uninterrupted human playtesting.

## Performance and limits

Bounded Linux headless layout runs measured about 0.050–0.053ms/call (1000 calls/configuration). Limited same frozen crowded-snapshot renderer probe: 10 warmups and 40 forced redraw waits per presentation version; baseline mean 36.149ms/p95 44.302ms, adaptive mean 33.529ms/p95 38.797ms. Interface/map code is shared in this presentation comparison. No noticeable regression observed in this sample; shared-machine sequential timings are noisy, not a claimed FPS improvement, full-game/long-run benchmark or Windows evidence.

Remaining weaknesses: the earned 16-slot room still contains dense crown/branch artwork. Compact group counts intentionally require Team for individual identification; one separate name can remain near the cluster. Anti-flicker behavior is verified in bounded deterministic scenarios, not every conceivable camera/roster transition.

**UNVERIFIED:** native Windows execution, Windows hardware performance, human usability/scariness approval and long-session behavior. No entire regression suite was run for this small presentation pass. Required screenshots and focused scope are complete. Stop after Phase 5.

The final chat provides full-commit GitHub links after normal `work` push verification. The commit containing this report is the checkpoint; push is verified by comparing remote `work` SHA to local HEAD and checking a clean tree. No release or main-branch merge.
