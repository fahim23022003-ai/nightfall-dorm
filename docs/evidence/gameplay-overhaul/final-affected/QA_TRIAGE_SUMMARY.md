# Independent regression triage acceptance

The original122-command sweep completed with21 failed command gates. Its raw failures remain unchanged in `final-regressions/`. Every one of those21 gates has a completed, accepted affected run in this directory. No failing test was disabled and C changed no production code.

`qa-triage-receipt.json` records each reason, accepted log hash, test-source hash and result. Four additional affected/new gates verify108 first-contact checks,522 combat/economy checks,40 Challenge checks with12 fresh workers, and30 terminal-cleanup checks. These are separate from the original21 corrected gates.

## Real product findings fixed by B

- New Hunter menu portrait resources were missing; the unchanged existing journey now passes68/0 without engine errors.
- Challenge preview incorrectly displayed ruleset3 while generating4; the existing actual preview assertion remains, and the affected full replay UI passes1541/0.
- Witch/Electric/Storm lacked their first basic-contact warning. The original harmless-first-strike and partial-windup assertions remain intact across all six archetypes and three modes. The full mechanical gate passes354377checks/540approaches/0; independent actual-model first-contact checks pass108/0.
- A real Witch projectile remained frozen after caster death because terminal early returns skipped its cleanup. New30/0 actual scenarios verify immediate kill, terminal ticks, Endless checkpoint/nextwave, legal undead player elimination while Hunter targets an ally, guarded transformation and reflected lethal damage. Cast telemetry and cooldowns remain intact.

The earlier expansion Laboratory unreachable-bed finding and repair are recorded in the separate expansion acceptance.

## Fixture compatibility repairs

Current writes compare the advertised ruleset; signed invalid-field fixtures exercise the current version and use a genuinely future version. Frozen historical rulesets1/2/3 remain preserved and tested. Six-machine fresh-Endless fixtures pay for their six-slot expansion; the15-machine upgrade-cap fixture uses an authored16-slot room. Actual amounts, upgrades, branches, discounts,50% capital refunds, stock, duplicate-click and save/cooldown assertions remain.

Ordinary UI interactions wait for the actual0.26s drawer and close it before selecting a covered world pad. Separate adversarial tests still exercise moving-control input guards. Closed gameplay uses its larger470px focus area and must expose the room and sleeper; intentionally opened drawers are checked as bounded lower-screen overlays. All30 authored map rooms and six explicit Legacy rooms remain tested.

Expected Arc impact damage includes the independent Electric-versus-Earth0.9 factor; raw launch stats and support/range/rate assertions remain. Visible HP assertions use actual display rounding. Witch ranged damage is allowed only when an actual explicit Magic projectile event has a prior warning, valid line of sight and bounded range; closed-room wall crossing and illegal remote basic damage remain forbidden. Run-wide movement maxima are replaced by the stronger per-frame speed bound, since temporary dash speed can expire before the terminal frame. All144 actual map strategy simulations retain resource, unique-owner, terminal and per-stage victory/defeat coverage;76 wins,68 losses,0 unresolved,0 failures.

Initial C fixture diagnostics during porting are retained separately (method signature, unsupported runtime mobile-mode flag without rebuilding the matching UI, and obsolete open-side-inspector visibility assumption). They are not claimed as successful runs or product bugs.

No pending confirmed finding remains from this triage. Full phase acceptance, current source commit, export/native Windows limitations and GitHub verification are owned by root.
