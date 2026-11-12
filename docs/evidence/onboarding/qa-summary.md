# Independent Phase 5C-1 QA

Agent C ran real Godot 4.6.3 model/controller/profile code on Linux. These are
prepared deterministic fixtures, not native Windows play, human win rates or
subjective audiovisual evaluation. Root owns full legacy regressions and D owns
actual rendered walkthrough/audio evidence.

## Final results

- `tests/onboarding_qa.gd`: **164 checks, zero failures**. Fresh mandatory flag,
  durable/failed tutorial completion, all four registered Common shop products,
  exact prices/cash/stock/serial, duplicate/stale/future/nonwhole tokens, saved
  replay protection, insufficient cash, stock caps, serial cap, read-only profiles,
  save-failure rollback, non-Common exclusion, genuine match RM awards, settlement
  retry/RNG rollback, duplicate reload protection, quick defeats, tutorial reward
  and stock isolation, actual RM cap credit and safe legacy/corrupt migration.
- `tests/onboarding_flow.gd`: **92 checks, zero failures**. Fresh-launch intro,
  actual keyboard skipping at six cinematic times, fifteen-second cinematic plus
  four-second card, exact title/creator strings, no replay on menu return, real
  movement/navigation and E/R input, occupied-bed Gold, separate generator
  Electricity, real purchases/upgrades/repair, weak combat with real Hunter
  attacks and turret shots, sold/far defenses, full-grid recovery, completion
  save failure/retry, mid-tutorial relaunch, and replay preserving existing XP,
  cash, stock, pending Lucky Spin and saved stage offer.
- `tests/onboarding_economy.gd`: **57,016 checks over 42 synthetic scenarios,
  zero failures**. Each scenario draws 1,000 seeded rewards from fixed legitimate
  performance inputs across Normal/Long Night/Hell, victory/defeat and occupied
  times 1, 20, 60, 89, 90, 180 and 600 seconds. These mostly repeated bounds/gate
  assertions must not be mistaken for 57,016 distinct gameplay scenarios.

The flow also invokes a real shop callback twice with a newly rendered token,
then injects an OS-style `double_click=true` mouse press/release after **550 ms
of actual wall time**, when the purchase button is demonstrably enabled. It
spends nothing. A subsequent ordinary mouse press/release buys exactly one item.
Mouse motion updates hover before clicks. This tests both the debounce and the
longer operating-system double-click guard, without disabling legitimate buys.

## Economy observations

At 180 occupied seconds and the disclosed 1,000 Hunter-damage/200 door-damage
fixture, Normal victory averages **33.041 RM**, Hell victory **53.041 RM**, and
qualifying defeat **4.996 RM**. At the 90-second loss eligibility boundary, defeat
averages **3.996 RM** (2.664 per occupied minute). Quick losses before 90 seconds
and idle defeats with no qualifying contribution earn zero. Victory expectation
is substantially higher under equivalent duration/performance fixtures.

Current Common prices are Repair 18, Gold 16, Battery 16 and Radar 12 RM. A typical
reward *in these fixtures* funds useful Common supplies; no human match duration,
player earnings distribution, grinding target or universal intent detection is
claimed. The gates prevent tested instant-loss and duplicate-claim cases, not
all conceivable deliberate offline play or save editing.

## Fixture adaptations and initial failures

Legacy scene tests now use `tests/onboarding_test_support.gd` to explicitly save
a tutorial-graduate profile and invoke the real opening skip after scene startup.
There is no production test-environment bypass. Existing gameplay assertions were
retained. Model/profile tests remain independent of the fresh-game UI gate;
startup smoke still tests the real opening.

Initial profile QA compared nested JSON receipt containers with different integer
versus floating-point types; final assertions compare the exact receipt fields
semantically. Initial navigation targeted the blocking bed center and tested
exactly 45 movement units against a greater-than-45 condition; final fixtures use
the actual bed approach lane and sufficient real movement. Neither was a
production failure. Initial shop mouse testing used a SceneTreeTimer rather than
the shop's wall clock: in accelerated headless execution, its nominal 0.5 seconds
finished while the 450 ms wall-clock lock was still active. Final testing waits
actual elapsed wall time and asserts the button enabled before testing input.
Initial logs are preserved alongside passing reruns.

An actual early import defect in `onboarding.gd` named a drawing helper
`draw_ellipse`, conflicting with Godot 4.6's native method signature. B renamed
the helper; later imports and runtime tests compile. B also repaired identified
practice recovery risks: an out-of-range turret cannot satisfy the defense
objective; a sold defense returns to the purchase lesson; a full wrong grid can
free a real practice pad. These recoveries are covered by the passing flow.

No confirmed functional failure remains in C's tested scenarios. Native Windows,
human timing/experience and subjective cinematic/audio quality are UNVERIFIED.
