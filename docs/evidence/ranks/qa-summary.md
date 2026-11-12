# Independent Phase 5A progression QA

Agent C ran actual Godot 4.6.3 headless tests against the production catalog and
profile. `tests/mythic_progression.gd`: **200 checks passed, zero failures**
(`qa-final.log`, exit0). The existing ranked suite passes **350 checks**
(`qa-legacy-ranks.log`). Fixtures deliberately set terminal model state and
performance values; these are deterministic arithmetic/persistence tests, not
played matches or estimates of human progression speed.

Coverage includes all seven rank names, ordered thresholds and badge resources;
unchanged six perks and one-slot loadout; representative version1 profiles at
0/250/700/1400/2400/3800/20000XP; preserved XP, settings, equipment and campaign
clears; save/load after migration; all three modes' fixed XP and component sums;
actual dead-Reaper/stage bonuses; time-bounded losses and no defeat multiplier;
XP snapshot/delta consistency; exactly-once match/mode/Reaper counters; begin
without completion; genuine early defeat counted with zeroXP; every Mythic gate
independently; accomplishment-boundary promotion once; persisted Mythic after
reload; repeated victories without repeated promotion; and failed-write pending
settlement, explicit save retry and reload without duplicate XP/statistics.
Missing, malformed and unknown-version optional progression sections preserve
known XP/perks/campaign rather than resetting the established profile.

Two initial roundtrip checks failed because validated JSON counters were retained
as floats. Godot Dictionary equality distinguishes `1` from `1.0`; production
now converts validated saved counters to integers. `qa-initial.log` retains the
initial192checks/2failures. The developer also fixed a breakdown defect found
by independent inspection: removing a defeat's difficulty bonus must remove it
before calculating the loss adjustment. Final exact component-sum tests pass
for all modes.

The old ranked fixture marked victory while the Hunter still had positive HP.
It now uses an actually dead Hunter, consistent with production victory rules.
Old35%-loss assertions intentionally changed to the new exact oneXP-per30seconds
limit, with no difficulty multiplier and30XP maximum. Save compatibility, perk
calculation, rank boundary and deduplication assertions remain intact.

Diagnostic arithmetic at120occupied seconds/1500damage/500door damage:

| Prepared victory | XP | Repetitions to reach8000 from0, excluding first clears |
| --- | --- | --- |
| Ordinary Normal |196|41|
| Stage5 Normal Reaper |286|28|
| Stage5 Hell Reaper |429|19|

The same120-second loss earns4XP regardless of mode; losses cannot exceed2XP per
occupied minute or30XP per match. A20-second loss earns0. These comparisons
show the incentive direction and finite threshold scale. They do not predict
real match time, win rates, player grind or human difficulty. Mythic still
requires a genuine stage5 clear, three advanced victories and three Reaper defeats.
Historic saves did not store mode/Reaper totals; those unknown statistics cannot
be reconstructed or invented. Existing stage clear records remain preserved.

No production edits, commits or pushes were made by Agent C. The coordinator
owns broader gameplay regression and graphical evidence. Native Windows and
subjective UI/audio quality are outside this headless evidence.

The legacy real-input UI suite also passes **63 checks** (`qa-legacy-ui.log`).
Its prepared victory now uses a dead Hunter; expectations follow the new visible
PERMANENT BOOSTS label, XP-to-next-rank requirement and locked perk text. Added
checks cover all seven rank labels/current plus seven badges, complete rescue
perk tooltip, transparent Base120/Difficulty breakdown, Silver→Gold promotion,
and the animated counter reaching the exact saved old/new XP after completion.
The previous obsolete fixture caused empty settlement and invalid dictionary
access; no production change was needed for this test correction.

The separate-process profile fixture now also uses an actually dead Hunter.
Fresh cleanup/write/read/cleanup Godot processes all exited0; exact866XP,
Dreamer equipment, three saved volume settings/mute, cleared active match and
last-award duplication rejection remain unchanged assertions.
