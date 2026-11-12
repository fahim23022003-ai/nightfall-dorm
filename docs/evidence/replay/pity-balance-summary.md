# Pity threshold balance audit

Godot 4.6.3 Linux, 12 November 2026; seed 7331, 100,000 draws per arm,
500,000 total. The production arm calls `SpinPity.roll`; alternative thresholds
use the same registered 20-item weights and filter/renormalize rule. No
production odds or item effects were changed by A. Transaction, reload and
eligibility exploit tests belong to C.

Ordinary Victory odds remain Common/Rare/Epic/Legendary **40/40/16/4%**;
Consolation remains **80/16/3/1%**. On the eighth qualifying Victory draw without
Epic+, lower rarities are removed: the conditional distribution is exactly
**80% Epic / 20% Legendary**, not 16/4%. On the fortieth without a Legendary,
the conditional distribution is **100% Legendary**, with priority over Epic+.
Epic or Legendary resets the Epic+ counter; only Legendary resets the Legendary
counter. Consolation neither advances nor resets the Victory-only counters.

| Arm | Observed Legendary % | Mean draws per Legendary | 95th percentile gap | Maximum observed gap | Mean Epic+ gap |
| --- | ---: | ---: | ---: | ---: | ---: |
| Base Victory | 4.049 | 24.697 | 72 | 217 | 5.002 |
| Candidate 6 / 30 | 6.638 | 15.065 | 30 | 30 | 3.619 |
| Production 8 / 40 | 5.534 | 18.070 | 40 | 40 | 4.080 |
| Candidate 10 / 50 | 4.965 | 20.141 | 50 | 50 | 4.410 |
| Base Consolation | 1.014 | 98.503 | 297 | 563 | 24.517 |

The current 8/40 choice is a reasonable middle candidate: it substantially
limits the dry tail while increasing average high-rarity supply less than 6/30.
The observed overall 5.534% Legendary rate includes ordinary and guaranteed
draws; it does not replace the conditional odds shown to the player. No sample
exceeded the eight-draw Epic+ or 40-draw Legendary boundaries. This supports
retaining the current thresholds; it does not prove human satisfaction.

The fastest **eligible** Consolation scenario used for a conservative pacing
comparison is 60 occupied seconds, plus the actual requirement for at least
100 damage dealt or taken. A quick ineligible loss grants no spin and makes no
pity progress. At a declared 180 seconds per victory versus 60 seconds per
eligible loss, measured mean gaps imply approximately **3252.6 seconds per
Victory Legendary drop versus 5910.2 seconds per Consolation drop**. Victory
also grants four item units per drop, versus one on defeat. These timings are
explicit assumptions, consistent with prior automated campaign pacing, not
measured human speeds. Extremely slow victories can alter the per-drop time
comparison; no claim covers every trajectory or player. Losses do not move the
guarantee closer.

No paid spin or gambling mechanism is introduced. Relevant evidence:
`pity-balance-results.json` and `pity-balance-initial.log`; 500,000 draws, zero
harness failures, actual process exit 0 and no engine errors. Reproduce with:

```sh
godot --headless --path . --script tests/endless_balance_audit.gd -- --pity
```

Native Windows, human timing and subjective reward satisfaction remain
UNVERIFIED. The Monte Carlo rates are seeded sample observations rather than
exact stationary probabilities.
