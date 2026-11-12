# Phase 5B-3 — rank perks, achievements and meaningful rewards

IN PROGRESS. Baseline clean `work` at
`88a6821aaa3df885f2fcf954eb817b2961ffc6e6`; remote verified.
Recovery tag: `pre-phase5b3-88a6821`.

Agent B owns production, C independent QA, A bounded design review, D later actual
render/audio inspection. Final mechanics, rewards, tests and delivery verification
will replace this draft. Native Windows and subjective quality are UNVERIFIED.
Stop after Phase 5B-3.

## Perk compatibility and loadouts

The suggested effects overlap the existing six perks. Their IDs, unlock ranks
and tuning are preserved to keep existing profiles and strategies valid:

| Rank | Existing perk | Actual bonus |
| --- | --- | --- |
| Bronze | Pocket Change | +5 starting Gold |
| Silver | Reinforced Frame | +5% door maximum HP |
| Gold | Deep Sleeper | +3% occupied bed Gold income |
| Platinum | Clean Current | +4% Dynamo Electricity |
| Diamond | Steady Aim | +3% turret damage |
| Master | Last Light | Once below 25% intact door HP: heal 10% |
| Mythic | Reaper Slayer (new) | +6% owned-turret damage against transformed Reaper |

One permanent slot applies below Master; Master and Mythic allow two. Consumables
retain their separate two item-type slots and one Legendary activation limit.
Mythic requires the existing accomplishment gates as well as XP.

## Planned stage choices and achievement definitions

The new catalog defines three next-stage options: +5% door maximum HP, +25 starting
Gold, or +8% owned-turret damage until 60 seconds after Hunter arrival. Choices
must be saved, unique and applied to their intended stage only.

Twelve deterministic achievements cover victory, Hunter defeat, Long Night,
Hell, Reaper defeat/three defeats, a full surviving team, 1,500 actual door
damage, 10,000 occupied-bed income, 30 purchases/upgrades, ten distinct item types,
and a successful Legendary activation during an eligible completed match.
Final transaction rules, actual rewards and test results follow after validation.

| Achievement | XP | One guaranteed item |
| --- | ---: | --- |
| First Victory | 15 | Instant Repair Kit |
| First Blood | 10 | Gold Supply Crate |
| Night Survivor | 25 | Emergency Shield |
| Hell Survivor | 40 | Inferno Ammo; Hell Survivor title |
| Reaper Hunter | 30 | Turret Overdrive |
| Reaper Slayer | 50 | Last Stand Feather |
| Perfect Team | 25 | Team Rescue Signal |
| Iron Fortress | 25 | Iron Barricade |
| Economy Master | 25 | Golden Pillow |
| Master Builder | 25 | Construction Coupon |
| Item Collector | 20 | Emergency Battery |
| Legendary Survivor | 35 | Shadow Smoke |

These definitions do not grant Legendary stock. Claimed rewards enter existing XP
and inventory. Unlock and claim are separate persisted states; actual granting,
cap handling, failure rollback and retry behavior require the tests below.
