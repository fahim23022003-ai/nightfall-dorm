# Phase5D4 early independent UX gate

Accepted **698 checks, zero failures**, all five maps, exit0 and clean engine log.
Exact hashes are in qa-ui-acceptance.json; real Game and ordinary mouse/keyboard
events use an isolated saved profile. This gate covers the first UX milestone
with the currently registered original six machines. Later new-machine/boss
coverage is separate; no completed-feature claim is inferred here.

## Actual verified behavior

- One wide fixed bottom context parent keeps the same geometry/identity across
  floor palette, machine, bed, door and exclusive branch states. Opening/closing/
  selecting previews does not change camera position, zoom, target or character
  position. Deep recursive primitive model/RNG snapshots remain identical.
- Every registered card is a real BUILD action with role/price/reasons. BUILD is
  now explicit final purchase, not an extra nested placement confirmation. Old
  placement APIs remain for their callers, but the owner-facing new flow is tested.
- Risky rightmost-column whole-card clicks geometrically overlap the inspector
  after control swap. An actual first press/release plus OS-double-click flagged
  second press/release buys one Level1 machine for exactly one base Gold/Electricity
  price. It cannot accidentally buy a Level2 upgrade. No stuck mouse-follow preview
  remains. Holding mouse down then Escape before release spends nothing; the same
  pad reopens cleanly. No direct callback emission substitutes for these clicks.
- Bed/door buttons use literal Gold/Electricity labels. Free exclusive branch
  selection shows actual selected state/icon and leaves every model value alone.
  Back/cancel and cross-kind reopening do not carry a purchase. Only a separate
  explicit Confirm charges once and advances exactly one tier; rapid trailing
  double-click events do not charge again. All temporary purchases/previews across
  maps leave permanent profile fields and save bytes unchanged.
- A separate paid real-relay/Overdrive fixture independently calculates weapon
  damage, interval, effectiveDPS and range with Cooling/Ballistic relays, prepared
  perk/stage factors and actual temporary item activation. Normal conceal and
  Reaper are tested as separate valid states. Actual inspector text, projectile
  launch and arrival damage match the expected math exactly once; stage/boss
  multipliers are not double-applied at launch and impact.

Counts include repeated invariants, not698 independent human sessions. Natural
progression/balance, actual pixels/font fit and captured audio are independently
reviewed by A/D; native Windows and subjective comfort remain UNVERIFIED.

## Preserved failures/resolution

qa-ui-initial.log preserves611checks/10failures: full-price structural labels
still usedG/E abbreviations contrary to the requested explicit units. B changed
those labels without altering accounting. The stronger second698-check gate
had five fixture-only failures because Level4 uses LEVEL4+actual numbers+branch
instructions instead of the literal wordCURRENT. The final assertion checks
actual36.0hit/54.4DPS/Level4 and explicit choice instructions, strengthening
semantic evidence without changing UI or relaxing the numerical behavior.
All paid confirmation and effective-stat additions pass in the final gate.
