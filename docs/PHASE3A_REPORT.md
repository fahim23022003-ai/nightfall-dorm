# Phase 3A — stages and preparation

Continued existing `work` at `76c1e393838c4930918fb787eb540dea7d78bfb3`.
Local recovery tag: `pre-phase3a-76c1e39`. Phase1 placement/refunds and Phase2
horror/audio remain present. Windows project and export settings are unchanged.

## Campaign and flow

StageCatalog defines First Encounter, Dark Awakening, Midnight Siege, Endless
Shadows and Final Nightmare, with identity, predecessor requirement, objective,
original-map assignment, first-clear XP and moderate configurable hunter/prep
modifiers. Night watch/Long night remain independent difficulty choices.
Preparation decreases30→26seconds; Stage5 adds12%HP/8%damage/4%speed before the
selected difficulty multipliers. No new map art or later-phase features.

Start Game opens Stage Select: locks, completion, best time, rewards, campaign
progress and selected difficulty. Prepare opens the existing ranked-perk loadout,
showing stage/modifiers and equipped perk. The Ranks loadout shortcut also opens
the selected stage preparation. Locked stages/perks are checked in presentation
and model/profile entry paths. Perks apply to the actual match snapshot.

Victory shows stage identity, performance, XP/rewards and Next Stage, Stage Select,
Main Menu. Next Stage opens preparation without starting a match. Defeat offers
Retry Stage (same stage/difficulty), Change Loadout and Main Menu. Completed
stages can be replayed; Stage5 ends with Campaign complete, not an invalid Stage6.
Legacy direct start_match API remains for existing engine tests; normal Windows
menus use campaign flow.

## Persistence and rewards

The existing safe temporary-write/validation/backup profile path has an optional
validated campaign section. Legacy profiles migrate additively with XP, rank,
equipped perks and settings preserved. Records persist completion counts,
best time/damage/XP, difficulty and first match identity; highest unlocked stage
is derived from the saved predecessor chain. Selected stage/difficulty persist,
while equipped loadout remains the existing inventory.

Settlement requires the active campaign snapshot and matching difficulty/perks,
eligible play, a dead hunter and living player. Defeat cannot unlock a stage.
First-clear rewards use the existing XP system and are granted once. Replay and
duplicate/reloaded settlements cannot grant the same first-clear reward twice.
Corrupt/disconnected records, invalid locked selection and bad chronology are
rejected using existing corrupt-save preservation/backup recovery. Future saves
remain protected. Failed campaign starts report failure rather than success
from a previously running match.

## Verification

Final `bash tools/check.sh`: exit0, no script/parse/error signatures.
Campaign profile85 checks, independent flow54 checks,20 deterministic campaign
matches (all5 stages × both difficulties × balanced/passive):10wins/10losses,
zero unresolved. Flow tests include two actual separate Godot processes writing
and reloading stage2/hard/loadout/XP, full campaign completion, lock/replay/perk
guards and real result button actions.

All regular regressions passed, including Phase1 suites314/421, Phase2 horror
events319/feedback21/UI5/audio157, ranks/save348, model126, updated progressionUI53,
cameraUI221, scene24, projectiles22/edges12, furniture30/availability3209,
20ktransactions/175941invariants, six rate scenarios,12 representative
matches9wins/3losses, separate-process profile persistence and main startup.
Counts are different measures, not a combined scenario total.

Agent B primary development/integration; bounded profile/UI implementation,
independent Agent C QA and Agent D actual UI audit. Real Linux Godot/Mesa captures
and button tests are under `docs/evidence/campaign/`, reproducible with
`tools/capture_campaign.gd`. The audit passed57 checks and saved19 captures at
1280×720/960×540, including all perk preparations, locks/completion/records,
Next/Retry/Stage Select, hard XP-cap summary and actual failed-save/retry.
These are prepared UI fixtures, not natural human campaign runs.

Confirmed issues fixed: false-success failed-start path, XP-cap summary overlap,
save-retry/Main Menu overlap. Existing tests were updated for intentional
Stage Select → Prepare → Start Match navigation, without weakening purchase,
input, audio, perk or result checks. No known remaining bugs in tested paths.
Human balance, target hardware performance and native Windows execution remain
UNVERIFIED; no Windows binary exported. No Android work, Phase3B or Phase4.

## Backup

Commit verified changes to existing `work`, push without force and compare
remote full SHA with local HEAD. The final response records the actual pushed
commit. No deployment or public publication.
