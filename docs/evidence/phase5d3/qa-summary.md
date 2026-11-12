# Phase 5D-3 independent QA acceptance

All requested focused gates pass on Godot 4.6.3 Linux. Root owns the full regular/
extended runner and final delivery; C made no production edits, commits or pushes.
Exact source/test/music hashes and accepted logs are in `qa-acceptance.json`.
Real user save files were never used. Temporary profiles are cleaned afterward.

| Gate | Accepted checks | Actual coverage |
| --- | ---: | --- |
| Audio |271|Actual fresh/returning launch, saved settings,19s opening/title cues, seven track/five voice audition controls, queue cancellation, skip/replay, real model music-state routing; permanent profile unchanged|
| Machine accounting |1668 /48 scenarios|All six machines/two branches/none/base/branch/later coupon; actual permanent coupon transactions and failed-save rollback; paid costs, Gold/E ledger,50% refunds, cap10, no duplicate sales, reuse|
| Structural/effect |99|Four bed/door branch pairs paid from1to10; failed atomic choice/no11, real occupied income/conversion, repair tradeoffs, powered healing and finite Electricity, support caps/no resurrection|
| Migration/combination |43|Genuine old checkpoint, all original paid states, legal sale funding, old→new branch choices/save/reload, malformed snapshots, old challenge archives, actual paid-stock Bulwark+Barricade+Shield damage|
| Tactical initial |60251 /15 map-archetype cases|All five maps/three archetypes, matched three-mode sample, lawful navigation, bounded movement, alternative targets, real abilities/windups/combos, Reaper clearing; six fresh Game-coded processes|
| Dash affected refresh |20076 /five Ravager cases|Final doorway recovery fix refreshed across all five maps, six same-code workers retained|
| Final Hell affected refresh |4033 /one HellCrusher map +three controlled strikes|Actual Normal4/Hard4/Hell3 warning frequency, >=.9s charged windup and exact armored hit; six fresh final-source Game workers covering HellCrusher/NormalRavager/HardStalker|
| Spectator |1420 /all five maps|Real roster clicks and physical keys, safe camera/zoom/bounds, actual model ownership/names/HP, own warning/listener, repairs/items, world/E denial, actual death, return/reset and Endless Continue|
| Support role preservation |400|All four offensive branches stay local; actual neutral/specialized projectile damage, cooldown and range with1/2/3Cooling/BallisticRelays and explicit caps|
| Contact guards |235 /50 controlled cases|All five maps/three archetypes; invalid contact/open/broken door preempts active windup/recovery, clears effects and preserves actual MOVE/BREACH/Reaper identity|
| Branch UI |425|Actual armed coupon/bed+door full-price cards/paid choices/stock retained, then one discounted machine+branch fee and one stock debit; truthful eligibility labels|

These counts include repeated invariants, not that many independent scenarios.
The full15 tactical cases and the two affected refreshes remain distinct evidence.
No production failure remains in the accepted C paths. Native Windows execution,
physical speakers, cross-platform bitwise timing and subjective scariness/fun are
UNVERIFIED. Actual rendered/mixer/source-license and natural-economy balance
findings are supplied separately by D/root and A, not inferred here.

## Important fixture and integration distinctions

Audio control tests instantiate the production Game/UI and inject ordinary mouse/
key events. Accelerated Onboarding clocks prove event routing/timing, not a human
listening session. Settings mute is intentionally honored. The final music gates
verify seven score players and108 decoded streams, not subjective music quality.

The machine matrix uses disclosed injected transaction budgets, never claimed as
natural Level10 reachability. Its four coupon placements prove exactly one stock
consumed only after success, including deliberate write failure and retry. Bed/
door retain their established full-price structural costs:9155G/952E bed and
9955G/950E door through Level10, with no extra branch fee; structural choices
advance existing Level5to6. Coupon and sell/refund eligibility is placeable
machines. Structure cards now state that clearly instead of implying a coupon
applies. Existing Needle/Arc branches remain the same choices.

The canonical old Arc10 profile has only34.82E. Migration first validates every
old level/branch/ledger/wallet, then a genuine50% sale of the owned Arc supplies
653E for new structural/support choices. No currency injection or frozen income
farming funds that migration. Reload compares every persisted field using the
existing exact numeric comparator for JSON int/float representation. Inventory
never changes. Invalid branch IDs, early structure branches, Level11, wrong-kind
machine branch, missing high-level branch and inflated refundable spend all fail.

Tactical fixtures deliberately use durable doors and paid repair supports with
prepared budgets to keep encounters alive long enough to observe reassessment.
These are functional navigation/ability tests, not balance win rates. Per tick,
there is the same Hunter object, legal map geometry and a finite actual movement
budget. Real warning events precede abilities, healed/failed sieges produce valid
alternative targets, Crusher charges/pressure, Stalker conceal/feint and Ravager
movement/combination recovery execute. Transformation clears normal abilities.

Final Challenge workers instantiate actual Game with beginner versus progressed
saved profiles. The ordinary start_challenge path normalizes perks/resources;
full fixed-step traces/outcomes are byte-identical across each fresh process pair.
Final six worker traces and clean logs are retained with `qa-code2-final-*` names.
Old NF2-1 codes are rejected for play while strict checksum-valid historical best
records still save/reload without locking the profile. No cross-platform perfect
determinism or online verification is claimed.

Spectator tests use actual Practice sessions on each map and prepared actual room
owners (deliberately permuted so owner !=room index). Real roster buttons show
actual names, health and states. Camera interactions leave the complete model
signature unchanged until intentional gameplay inputs. Actual R and repair-item
keys protect only the player's door; time/attacks continue. Physical W is proven
held while the player is awake: it moves nobody while watching and works again
after Return. Own E then sleeps normally. The actual breach/contact controller
eliminates a watched teammate once, updates the live count and retains its dead
room camera; own contact death reaches the normal result and refuses spectating.
All permanent profile fields/bytes stay identical through Practice resets/exits.
The real saved Endless Prepare→watch→Wave→Continue flow resets to own camera.

## Retained failures and resolutions

- Audio's first ten failures were fixture text matching: Godot capitalize uses
  title case for each word. Real button labels were correct; final actual clicks
  pass. Intermediate248/250 gates remain separate from final271.
- Migration initially tried60E structural purchases from34.82E and correctly
  failed, cascading later assertions. Actual owned-machine sale supplies legal
  funds. Raw Dictionary equality of old archive plays2 versus JSON2.0 was fixed
  using the existing exact numeric comparator, not looser save validation.
- Spectator's first31 failures expected a name while the prioritized own-danger
  warning intentionally replaced it, and projected world clicks hit actual HUD
  roster controls on some maps. Hiding the roster before world clicks corrected
  that fixture. The final1420 gate additionally proves physical-W movement and
  restoration, avoiding a vacuous logical-key-only movement check.
- Confirmed LOW product issue: structural branch cards displayed a COUPON suffix
  although their quoted price/accounting correctly remained full price. B removed
  that suffix and clarified machine-only eligibility. Actual425 UI checks now
  verify full prices, stock retention and subsequent eligible consumption. One
  first UI assertion used lowercase Beds text; case-insensitive semantic matching
  fixes that fixture without changing UI behavior.
- Root/A/D's separately reported Ravager recovery/Hell charged-frequency fixes
  received affected C refreshes above; unrelated matrices were not blindly rerun.

## Integration handoff

Seven standalone suites are ready for future registration after any active runner
finishes: `phase5d3_qa_audio`, `phase5d3_qa_economy`, `phase5d3_qa_structures`,
`phase5d3_qa_migration`, `phase5d3_qa_ai`, `phase5d3_qa_spectator`,
`phase5d3_qa_branch_ui`. The AI script supports affected-only `--ravager-only`
and `--final-ai` arguments; its default runs the complete focused coverage.
Do not edit a running Bash runner. Root's full suite has separate receipts.


## Final preservation follow-up

The root full legacy suite found a genuine cross-role aggregation bug not covered
by C's initial99 support-effect checks: the generic support helper also returned
offensive branch interval/range data, applying those properties globally a second
time. B now strictly limits that helper to Dynamo/Repair/Amplifier/Relay kinds.
C's new400-check gate uses every existing Needle/Arc branch with a neutral second
weapon, then genuinely purchases1/2/3CoolingRelays and1/2/3BallisticRelays. Actual
launch cooldowns, edge-of-range firing, projectile damage and arrival impacts
match explicit expected math. Offense does not leak globally; only real support
relays change bounded room rate/range. Machine payment/refund code is unchanged,
so its48-scenario transaction matrix was retained without unnecessary repetition.

B also moved actual contact/closed-door validity checks before tactical windup/
recovery. C's235-check gate runs50 controlled fixtures across all five maps and
three archetypes. A Hunter losing valid door contact immediately enters MOVE; an
open/broken door immediately enters BREACH. No remote hit, fake ability activation,
position jump, stale pressure/conceal/dash/recovery or suppressed repair factor
remains. Reaper cancels stale specials/shadow without transforming/refilling.

These are new targeted preservation gates on the final fix. Earlier accepted
valid-state/transaction/audio/camera logs remain historical focused gates with
prepatch source hashes retained in qa-acceptance.json. Root independently reruns
the unchanged original premium mechanic matrix (176279checks/270approaches), and
A refreshes final strategy evidence. C does not claim the entire earlier15-case
AI matrix or unrelated menus were rerun after these narrow changes. Add
`phase5d3_qa_support_roles` and `phase5d3_qa_contact_guards` to future runners only
after any active script reader finishes.
