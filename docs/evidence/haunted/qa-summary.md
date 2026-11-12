# Independent Phase 5C-2 QA

Agent C used production Godot 4.6.3 model, catalog, environment and audio code
on Linux. Direct accounting/combat fixtures inject resources explicitly; they are
not the reachability or human-balance evidence. Root owns the complete regular/
extended regression run; D owns actual rendered/audio presentation inspection.

## Final focused results

- `haunted_qa.gd`: **78,195 checks, zero failures**. Most checks are repeated
  bounded/exterior invariants over 1,400 updates on each of five maps; this is not
  78,195 distinct scenarios. Covers per-kind caps, all valid prices and separate
  Gold/Electricity deductions, prerequisites, failed upgrades, Level 11 rejection,
  actual investment ledgers, discounted upgrades and half refunds, double sales,
  tile reuse, all-map/mode genuine breach-to-bed elimination navigation and
  inactive dead-bot economy/actions.
- Actual projectile impacts at Levels 1/4/7/10 across all three modes verify
  bounded damage/cooldown, ranked + stage + transformed-Reaper interactions.
  Level 10 Overdrive/Time Freeze tests retain the saved one-Legendary limit and
  real shots during finite freeze.
- The cosmetic environment never changes model RNG, Hunter state, currency,
  projectile targets or combat records. All five creature types remain outside
  the complete protected room/corridor footprint and navigation. Collections stay
  bounded; positions animate; maps have distinct themes; real lightning produces
  delayed thunder, a truly hidden apparition becomes visible then disappears,
  and pause/invalid timesteps preserve state.
- Actual sequential Hunter eliminations observed together serialize two distinct
  death screams, with at most one death-scream voice. Duplicate/new-ID callbacks
  and a callback for a living survivor cannot add deaths. Real ordinary/Reaper
  breaches play distinct laughs once; notification name/room text is real;
  menu transitions clear pending owned sounds.
- `haunted_economy.gd`: **5,382 checks, zero failures**. Four controlled economic
  workshops use only occupied-bed income and Dynamo electricity. No Hunter is
  active here. Needle Level 10 costs **1,740 Gold /258 Electricity**, reaching it
  in 215.5 seconds, or 209.5 with the disclosed income/power perks. Arc costs
  **8,265 Gold /1,302 Electricity**, reaching it in 466.5 or 453 seconds. These
  workshops prove accounting and economic possibility, not survival.

## Live earned-resource reachability and balance

`haunted_balance.gd`: **60 complete live matches, zero invariant failures**:
five maps × three difficulties × Needle/Arc economic policy × cap-4/cap-10 arm.
Paired profiles use Master Deep Sleeper + Last Light and a finite fixture stock
of four Emergency Shields plus one Guardian Heart. Match Gold and Electricity
are earned normally. There are no injected resources, immortal doors, forced
Hunter targeting, paused/dormant AI or artificially advanced match clocks.

The policy develops beds, Dynamos, amplifiers and repair before reserving the
full weapon investment. After purchase, valid upgrades are attempted every
0.1 seconds. This fast automated upgrade cadence is disclosed; it is not a human
speed or win-rate claim. Both arms use the same policy and finite item budget.

Both Level 10 weapons were achieved during actual normal-stat live matches:

| Weapon | Stage/mode | First Level 10 | Match outcome | Actual bed income generated |
| --- | --- | ---: | --- | ---: |
| Needle | Haunted Hospital /Normal | 191.1s | Victory at 191.5s | 5,453.7 Gold |
| Arc | Underground Laboratory /Normal | 218.7s | Reaper victory at 229.3s | 14,263.9 Gold |

Total cap-4 → cap-10 outcomes: Normal 10W/0L →10/0; Long Night 10/0 →10/0;
Hell 3/7 →2/8. Waiting for expensive prestige upgrades worsened one Hell case.
The cap-10 policy achieved no Level 10 in tested Long Night/Hell matches: many
ended before the reserve was sufficient, or the player died. These results prove
at least one real earned live reach of each weapon and preserve meaningful
threat; they do not prove universal reachability, improved win rates, all possible
strategies or human balance. No Hunter stats were increased to offset the feature.
The initial slower-upgrade matrix is retained as `balance-initial.log`.

## Existing fixture adaptations

- `phase1_building.gd` now tests refund levels through each kind's actual cap and
  supplies the required bed/door fixture: **512 checks pass**.
- `audit_regressions.gd` tests per-kind maximum caps with legitimate prerequisites,
  preserving its separate original Level 4 utility/heavy-effect assertions:
  **84 checks pass**.
- `audit_properties.gd` uses each kind's valid cap in the same resource invariant:
  **20,000 transactions /175,889 checks pass**.
- `horror_feedback.gd` supplies genuinely dead/broken state for simulated valid
  events, checks the required uppercase room text and additionally rejects fake
  living-survivor/intact-door callbacks: **22 checks pass**.

No gameplay assertions were disabled. Buildings remain transient match state;
there is no new saved-building format to migrate. Existing profile compatibility,
20 items, progression, RM shop and tutorial are covered by root's full regressions.

## Findings and limitations

C requested serialization of batched death screams; B added the bounded queue and
it passes real mixer-voice tests. Other initial C failures were fixture details:
cooldown had legitimately advanced by the test's 0.001-second tick, a projectile
needed its next model tick to impact, a notification uses `text` rather than
`message`, and a logical SceneTreeTimer was insufficient to wait for real audio
playback. Final testing yields actual frames/wall time until the real voice
finishes. Initial logs are retained; these were not production combat defects.

No confirmed functional failure remains in these tested paths. Native Windows,
subjective horror/sound quality, hardware performance and human balance remain
UNVERIFIED. Actual graphical inspection is reported separately by Agent D.
