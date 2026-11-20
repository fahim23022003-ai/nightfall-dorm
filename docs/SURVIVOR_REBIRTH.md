# Survivor & UX Rebirth · The Nightmare Lobby Update

The preview follows `c4e82c9` and uses the existing Living Nightmare
Story profile. The new Windows launcher enables Survivor Rebirth.
The original Living Nightmare and fixed, V1 and V2.3 fallback
launchers remain available. The Hunter art and gameplay systems were
left intact. [Before-change Godot evidence](evidence/survivor-rebirth/baseline/)

## Shared spawn and first-arrival rooms

A fresh Campaign, Story or Endless encounter starts the human and five
NPCs together at a reachable exterior point. The map seed and match
attempt choose the spawn. A Story retry retains its mission map. The
optional Endless snapshot fields preserve the original shared start
and pending physical actors. Old snapshots keep their original state.

The player moves at 180 world units per second and AI survivors at 90.
Preference and congestion affect which room a runner walks toward.
Ownership changes through the same physically valid claim transaction
for both player and NPCs. NPCs can leave a rival's room if they were
already inside when it changed hands. The interface shows live bodies
and distinguishes vacant rooms, room approaches and completed claims.

The 35-seed V2 matrix passed across all ten macro layouts and all five
themes. The longest shortest human walk to a claimable room was 9.22
seconds. With the human idle and Hunter disabled for the race-only
measurement, the last NPC's claim took up to 156.25 seconds in a
Spine map. Full paced matches on wider maps remain an owner playtest
focus. [Model tests and timings](evidence/survivor-rebirth/room-rush/)

## Ready lobby

Story preparation retains mission difficulty, equipped consumables
and perks. Start Match opens six offline survivor cards and the
mission's authored Hunter art. When the human clicks Ready, the AI
continue becoming Ready independently. The match loads once all six
are Ready. If the human leaves Ready untouched, it confirms at 15
seconds, followed by the 0.42-second loading transition. The clock
pauses while unfocused. Back and Esc return to preparation until the
match starts. None of these actions starts the model or saves changes
to the loadout before the actual launch.

The audio director owns a distinct lobby score and the local ready,
arrival and countdown cues. It crossfades to gameplay. The previous
adaptive game mix and five-second siege heartbeat remain active.
[Early Ready, auto-ready and continuous room-claim films](evidence/survivor-rebirth/lobby/) · [1280×720 and 960×540 integration](evidence/survivor-rebirth/integration/)

## Defeat, tutorial and interface

A recorded defeat after room occupation credits 6–14 permanent RM
Cash in the preview, subject to the wallet cap. Time and contribution
bonuses are capped. Existing victory and XP rules are unchanged. An
unfinished attempt, a training game or re-opening a settled outcome
earns no duplicate cash. The native Story fixture earned 7 RM on
each of two real early breaches, bought a 12 RM Radar through Shop,
equipped it through Inventory and verified it on the next match.
[Defeat receipts and purchase walkthrough](evidence/survivor-rebirth/economy/)

The 19-step training course uses input, successful transactions and
live control bounds. It teaches both machines, requires the actual
placement Cancel action, and waits for Dynamo power to fund an upgrade
before teaching a paid door repair. The tutorial has its own disposable
match and wallet. [Uncut tutorial and receipts](evidence/survivor-rebirth/tutorial/)

The desktop Main Menu, Story preparation, Shop, Inventory, Settings
and Build use the shared gothic palette and focus rules. Each screen
retains actual costs, inventory and settings actions. [Native UI audit](evidence/survivor-rebirth/ui/)

## Verification and playtest

The Godot checks include Story progression, paid construction and
migration, eight Grim Reaper direction atlases,
all 240 ordinary directional atlases, audio, saves and the older
launch paths. Automated combat, menu and tutorial evidence is filed
alongside the source. The Linux renderer benchmarks include both
lobby and active combat on Standard and Low. The Windows export is
verified through its embedded Godot pack. Native Windows usability,
Intel UHD performance and owner artistic review remain pending.
[Performance](evidence/survivor-rebirth/performance/) · [Windows playtest guide](SURVIVOR_REBIRTH_WINDOWS_PLAYTEST.md)
