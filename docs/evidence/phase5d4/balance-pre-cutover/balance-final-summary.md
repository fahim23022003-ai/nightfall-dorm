# Phase5D4 independent balance audit

## Status and method

IMPLEMENTED by B; independently TESTED here on Linux Godot4.6.3. Native Windows play, human difficulty and subjective sound are UNVERIFIED. These scripted policies are evidence of specific strategies, not population win rates or a claim of universal balance.

Immutable pre-change d507600 baseline:51 live campaign cases,0 integrity failures, preserved in balance-baseline*. Final paired runtime: same51 inputs plus18 freshseed/archetype cases,69/0, all actual process exits0 and no engine errors. Actual navigation→claim→sleep, real economy/NPC AI/combat/settlement; no live player money/HP/clock/position injection. No-turret arms have0XP/perks/stock and exactly0player shots/damage. Prepared campaign records only grant eligible stage access. Active controls have finite Master Dreamer/FirstAid,4Shields+1GuardianHeart. HighNPC counterfactual separately injects10000G+1000E per NPC once and is not natural economy evidence.

## Owner feedback investigation and paired findings

| Policy | Baseline Normal/LongNight/Hell wins | Final same inputs |
|---|---|---|
| Idle after sleeping |1/5,2/5,0/5 |1/5,2/5,0/5 |
| Bed/door only (no Dynamo) |5/5,5/5,4/5 |5/5,5/5,2/5 |
| No weapons, economic/support buildings |5/5,5/5,4/5 |5/5,5/5,3/5 |
| Active Master Hell |3/3 |3/3 |
| HighNPC, idle player Hell counterfactual |1/3 |1/3 |

Fresh seeds: bed/door-only Normal5/5,LongNight5/5,Hell1/5; activeHell3/3. Active Hell victories deal actual player1969–4546 damage. This does not support a blanket NPC damage nerf. NPCs remain helpful, and some no-offense Hell runs can win; such wins are substantially less consistent in this sample. Normal and LongNight passive carry still occurs and is explicitly not hidden.

Baseline actual NPC maximums: Bed5/Door5/machines4. The static emergency-upgrade path could exceed the advertised budget, but none of these51 runs actually did. Do not present that as the measured cause. Real NPC main-Hunter output in four baseline bed/door Hell wins averaged39–55damage/s over whole combat windows, below a hypothetical fully in-range L4Needle/Arc/Relay room≈412DPS. Player repair frequency and strong occupied-bed income also matter; no-turret means no player offense, not no economy or repairs.

Missing Reaper: Stage1 and NormalStage2 are intentionally ineligible; early terminal outcomes can beat the old80/90active-second opening. The highNPC Hospital counterfactual formerly killed the Hunter69.6s before transformation. Final same input now reaches realPhaseI/II and Crimson, victory76.8s. Eligible ordinary low-damage runs can still end before55% threshold or deadline; no promise every match transforms.

Across69 final campaign runs: PhaseI38,PhaseII36;35 Crimson casts,28 target NPC rooms and7 player rooms; live undead peak10; all15 evolution buff IDs acquired naturally at least once, unique acquisition never exceeds6. No observed domain/live-minion coexistence. NPCs dealt21331 actual damage to minions, tracked separately from main-Hunter damage.

## Evolution and boundedness review

All15 catalog entries have actual code paths. Awards require the authoritative real elimination transition, Hunter/Undead source, unique owner ledger, maximum6 nonduplicate buff IDs. Endless intentionally preserves that run ledger; no additional awards for the same survivor across waves. Reset/new-run is distinct. UndeadCommander is explicitly dormant until eligible boss transformation; ShadowStep is excluded after transformation.

Worst multiplicative attack recovery of BloodFrenzy×Relentless×Momentum is .9×.92×.9=.7452 of current interval, only after their conditions; movement maximum1.12×1.1×1.15=1.4168 during temporary momentum/pursuit. DoorCrusher×Savage special damage1.288; IronSkin10%; CursedArmor finite5%HP/8s; SoulHunger4%maxHP per real unique kill. These are finite and cannot all coexist with every other buff under the6award cap. SoulDrain bounded8G/2E per20s contact; DreadAura12% only current siege room. This review does not substitute for C's focused mechanical/anti-farming tests.

## New-building genuine progression and strategy

Initial slot policies exposed a strategy limitation: spending the only <155px pad on the bootstrap Needle prevents a useful Shock Trap there. The audit policy was corrected through an actual Needle sale/50%refund, then reserved the closest pad for Shock, next for Flame/Frost. This is not a production failure or free relocation. Initial eight-pad economy and long-range strategies are retained as diagnostics; their stalled all-six goal is not called complete.

Corrected16pad Mansion room2 runs earned all six new machines plus Arc,bed,door,Dynamo and amplifier through10. Normal seed71 uses Master finite4Shield+1Heart and alternative branch set. Hell seed47 uses Mythic Marksman/ReaperSlayer finite4Frost+1TimeFreeze and first branch set. Decisions every0.2s are faster/more regular than a typical human. No live resource/HP/position/time/wave injection.

Normal40clear/5687.9s: Shock10 wave10; Flame/Frost10 wave10; AutoRepair/Shield10 wave11; Decoy10 wave12. Actual Decoy29 and Shield2 activations. AutoRepair0 because own door never crossed that branch threshold; do not infer natural healing from this run.

Hell40clear/5415.4s: Shock10 wave7,Flame8,Frost9,AutoRepair10,Shield11,Decoy12. Actual paidAutoRepair114 activations,16659.9675HP restored,Shield106 activations,Decoy43.11domains per corrected40wave run,live undead≤10. Main/minion damage is separated.

A fresh20wave replay of the Normal corrected policy recorded genuine Level10 contact impacts: Flame2476.8,Frost1365,Shock4332,Arc67503.26. Flame burn is separate from projectile impact and is not counted in those contact figures. Full actual-investment checkpoint at completed12 is preserved as balance-earned-71standard.json and reopened successfully.

Costs at10 in that checkpoint (separate actual eligible investment Gold/Electricity): Flame6550/1132,Frost6985/1306,Shock5680/1132,AutoRepair7420/1306,Shield8725/1828,Decoy6115/1132. Values include specialization and all paid upgrades; no coupon was supplied in these earned runs. C covers discounted half-refund accounting.

## AutoRepair actual-handler controlled comparison

17 controlled cases,0failures. Fixtures deliberately supply5000G/E and start10% doorHP; they isolate real RoomState.tick_economy versus DefenseEffects.tick for30s, without a natural-survival claim. AtL10/siege repair factor.35: oldConservation588HP free; oldSustain992.25HP for75E; newEfficient1430HP for49G+30E; Emergency1544.4HP for67.2G+27E. At normal factor1 oldSustain2835HP versus newEfficient2200HP, so new building does not universally replace the old one. Late emergency initial1s restores257.4HP versus oldSustain33.075HP, providing a paid clutch niche. Two AutoRepair stations do not double the healing or payment because of room cooldown. Emergency threshold means it is not continuous always-on healing.

## Long-run stability and remaining limits

Old powerful Storm fortress controls naturally clear35 Normal and35Hell with two fresh checkpoint restores each. Extended same finite-budget Hell fortress requested120waves, clears74 and loses on75 after2669.2s (44.5min simulation). All initial4Frost+1Freeze consumed; no replenishment. Atwave74 Crusher finally breaks the door as the Hunter dies; wave75 sees that already-breached room and the player is eliminated. This is the actual terminal sequence, not an arbitrary forced defeat. Alive team falls from6 early to1 by60, six unique evolution awards total.26domains,undead≤10; three fresh restores5/20/60. Engine objects1520 at every sampled completed wave. Static memory26.15–26.56MB across that run, bounded transient buffers; final profile2698bytes after settlement. No claim of proving absence of all memory leaks or real-time FPS from accelerated headless simulation.

Corrected all-six powerful build extension requested120waves and naturally lost on53 after52clears/8097.3s (134.96min simulated). AutoRepair761activations restored110335.9675HP; Shield326activations absorbed48183.16999HP; Decoy56. Two fresh checkpoint restores5/20; initial4Frost+1Freeze exhausted. Final Crusher wave dealt25070.04actualHP/66hits despite844manual repairs, breached, then eliminated the player with98022.68HunterHP remaining. Six evolution awards,16PhaseII/domains,live minions≤10. This is a meaningful tradeoff: replacing extra Arc towers with utility buildings increases durability/control but reduces outgoing damage, so this particular all-six layout loses earlier than the narrower Storm fortress. It does not establish universal superiority of the new roles. All-six late runs finish with1living teammate (the player); NPC attrition contributes real pressure. Static memory26.17–26.64MB/objects1520 in completed-wave samples; transient projectiles≤6/combat events≤10/presentation events≤128. End-of-run profile2666bytes.

Full earned Hell all-sixL10 checkpoint at completed12 is preserved and fresh-restored as balance-earned-47hell.json. Normal canonical19053bytes/SHA256650a49ce6915dc8db11792a3dc87a6493058f644ed994774e6b8bde65d2ea2dc; Hell19079bytes/SHA256c6ad2f113740c991794cecb7231a2463c48dbf6475461d96815dba06202d460a. Both profile1/replay1/snapshot1/ruleset3. Source canonical files must remain unmodified; D may change tutorial flag only in a separate GUI copy.

Final audit totals:69 campaign cases,12 Endless cases (including disclosed initial placement policies and short evidence replays),25 successful fresh checkpoint comparisons,17 controlled repair cases;0integrity failures,all final process exits0. The pre-change51case baseline remains separate. No production files were edited by this auditor. Bounded runs and a single terminal policy do not establish every possible combination is balanced. Strong optimized early/midgame defenses can still leave the player room mostly untouched while NPCs fight; this is disclosed, not silently tuned to a desired win rate. ReducedEffects, perception, native Windows handling, and human difficulty remain independent validation responsibilities.

Source note: paired no-offense/active policies predate narrow sold-Decoy/domain foreign-control fixes but use neither buildingDecoy nor affected control/trap effects; pressure/economy coefficients unchanged. Earned runs use those fixes. Only presentation scripts changed after balance-final-runtime-start.json; exact current gameplay hashes and artifacts are in balance-final-manifest.json. Raw logs/JSON are the authoritative per-case evidence; initial exploratory cases are labeled by their policy/configuration and retained.
