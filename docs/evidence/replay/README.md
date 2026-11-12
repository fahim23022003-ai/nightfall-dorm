# Phase 5D-2 rendered replayability review

## Preserved compact baseline

Agent D captured **six actual Godot viewport PNGs** before production changes,
from clean `work` source `d16a82da5baccdf5bcbe566635ee949c086c7a32`.
Only the coordinator's checkpoint document changed during capture. The baseline
gate was announced before B began implementation. `render-before.log` exits 0:
**14 checks, zero failures and zero engine errors**. `render-manifest.json`
records each image's dimensions and SHA256. Old phase evidence/tools are unchanged.

The compact baseline contains menu, campaign gameplay HUD and current Victory
Spin/odds at **1280×720 and 1920×1080**. The isolated prepared profile supplies
Master XP, stage records, item stacks and selected perks. Gameplay uses real
stage startup, claim/sleep and production rendering. The spin is produced by a
prepared eligible terminal state, the real model's terminal seal and ordinary
saved settlement/claim; it is not a natural human-earned victory. No existing
player profile is used. Screens are unedited engine output on Godot 4.6.3,
OpenGL/Mesa llvmpipe and a private Xorg display.

## Baseline design observations

- Existing action emblems, Gothic headings and dimensional surfaces are readable
  and should be preserved. The menu already occupies its available lower area;
  new feature actions require deliberate reflow rather than additional bottom rows.
- The top gameplay HUD is full. Endless wave/best/modifier information needs
  reserved space while keeping resources, Hunter state, TEAM and warnings readable.
- The spin's individual 20-item odds column is dense. Pity progress should have
  reserved space and truthful actual conditional odds, with legible type.
- Natural earned Needle10/Arc10 evidence should use a real saved intermission
  checkpoint from a qualifying earned run. Temporary Practice resources can
  demonstrate mechanics but cannot establish natural Endless affordability.

## Final review — TESTED

The after set contains **119 unedited Godot PNGs**, plus the **6 preserved before
PNGs**. The manifest records every filename, dimensions and SHA-256. Paired
`01-menu`, `02-gameplay` and `03-victory-spin` use the baseline fixtures; detailed
feature evidence uses the disclosed profiles below. Contact sheets are labeled
review aids, not replacement or retouched evidence. No production code was edited
by D. B implemented the product; D exercised and reviewed it independently.

### Evidence index

| Feature | Representative after PNGs (each also has a 1080 counterpart unless marked) |
| --- | --- |
| Real skull action and distinct material | `01-menu-720`, `detail-endless-distinct-hover-720`, `detail-endless-distinct-pressed-720`, `detail-endless-keyboard-focus-720`, `extra-endless-setup-720` |
| New early run | `endless-actual-new-run-wave1-720`, `endless-actual-wave1-occupied-720` |
| Genuine earned later play | `earned-advanced-level10-combat-720`, `detail-endless-wave21-reduced-720`, `earned-needle-level10-combat-720`, `earned-arc-level10-combat-720` |
| Real Reaper milestone | `earned-needle-reaper-milestone-720`, `earned-arc-reaper-milestone-720` |
| Frozen preparation and newest ledger | `earned-needle-frozen-preparation-720`, `earned-needle-newest-paid-ledger-720`, `earned-needle-reloaded-newest-ledger-720` |
| Final reward/checkpoint clarity | `detail-authentic-wave20-final-milestones-720`, `earned-advanced-safe-end-720` |
| Codes and actual local results | `extra-code-generated-720`, `extra-code-copied-720`, `extra-code-rejected-720`, `challenge-pasted-normalized-rules-720`, `challenge-actual-result-720`, `challenge-result-copied-720` |
| Conditional pity and actual reward | `pity-epic-guarantee-receipt-next-720`, `pity-legendary-guarantee-receipt-next-720`, `pity-epic-actual-reward-720`, `pity-legendary-actual-reward-720`, `pity-consolation-unchanged-720` |
| Four cosmetic shapes | `extra-cosmetic-gallery-locked-720`, `cosmetics-four-equipped-gallery-720`, `cosmetics-damaged-door-branch10-world-720`, `cosmetics-damaged-door-branch10-reduced-720` (reduced world view is 720 only) |
| Factual defeat | `defeat-real-campaign-result-720`, `defeat-real-door-facts-before-reward-stock-720`, `challenge-factual-exposed-defeat-720` |
| Dedicated Practice and old tutorial | `extra-practice-setup-720`, `practice-paid-level4-720`, `practice-real-branch-selection-720`, `practice-real-combat-720`, `practice-pause-reset-720`, `practice-reaper-720`, `practice-legendary-limit-720`, `practice-original-tutorial-preserved-720` |
| Audio transition | `detail-immediate-wave-transition` (720), `audio-real-time-reaper-combat-720` |

Paths above are under `render-screens/after/` and end in `.png`.
`render-final-verification.json` indexes the authoritative passing logs and exact
standalone counters. The final accepted standalone engine runs have **531 checks / 0 failures**
(before: 14 checks / 0 separately).
Other logs preserve intermediate attempts and are not summed into final totals.
Earlier `earned-*` frames precede the bounded material/milestone/audio refinements;
`detail-*` and the latest Challenge frames show the final affected UI. Source
hashes identify the final production tree; unchanged families were not broadly
rerendered for unrelated text/audio fixes.

### Actual results and fixture provenance

- **Endless earned evidence:** A's canonical Needle/Arc/advanced profile JSONs were
  copied, then loaded/resumed by the production Game API. The source/copy manifest
  records their hashes; canonical originals remain byte-identical. A earned the
  live funds, HP, positions, elapsed time, waves and paid investments through
  actual simulation. D injected none of those into the earned runs. A's headless
  profiles had not completed onboarding: only the isolated GUI runtime copy was
  marked tutorial-completed, preventing menu return from entering onboarding.
  Needle10's original investment is 1765G/262E; Arc10's is 8290G/1306E. D observed
  actual owned L10 launch/impact events in wave 6 for Needle/Arc and wave 21 for the
  genuine wave 20 advanced checkpoint, plus real Reaper wave 5 transformation.
  D advanced ordinary fixed simulation ticks in batches for these combat views;
  this is simulation evidence, not human play or real-time FPS evidence.
- **Frozen/save behavior:** real Prepare controls froze model time and both
  currencies. A real utility sale opened a pad; a real 30G Generator purchase was
  saved through the Wave panel and Save & exit, then restored with its newest
  actual investment and wallet intact. Continue created a fresh Hunter object.
  End run here cleared the active run/checkpoint and showed a separate result.
- **Actual early flow:** the real New Endless control started wave 1 with 25G/0E.
  D walked an actual navigation path to a reachable bedside point, then injected
  ordinary E press/release input twice to claim and sleep. No live currency, HP,
  time, position or wave was injected into that early walk. Prepared menu profile
  stock/perks are disclosed above; this does not establish human balance.
- **Challenge:** actual pasted alternate preset 15G/0E and Overdrive/Frost×2,
  neutral perks, real fixed-step simulation, then genuine unoccupied-survivor
  contact at 64.73s produced a sealed defeat/local record. Code and self-reported
  result clipboard contents were read back. All permanent profile fields matched
  except the intentionally added local challenge-best record.
- **Pity:** isolated profiles deliberately began at dry counters 7/12 and 7/39;
  these were prepared boundary tests, not naturally earned streaks. Prepared
  eligible campaign combat used actual transformation, Hunter damage, terminal
  seal and ordinary saved settlement. Epic+ guarantee produced actual 80% Epic /
 20% Legendary odds; Legendary guarantee produced 100% Legendary (four 25% items).
  The persisted receipt reloaded without reroll or duplication; the displayed NEXT
  counters reflected the subsequent draw. An actual eligible Consolation kept
 6/18 Victory dry counters unchanged.
- **Cosmetics:** the authentic best-wave 20 record plus controlled qualifying
  campaign/Reaper wins unlocked the four catalog conditions through real reward
  transactions. Gallery Equip controls persisted them. The world view uses
  intentionally temporary Practice resources and a genuinely paid Precision
  Needle10; this proves appearance readability, not natural affordability.
  Door HP was prepared at 28% specifically to inspect cracks. Equipping/toggling
  every appearance left the live combat/economy/model signature identical.
- **Defeat:** a controlled occupied campaign fixture used real door damage,
  manual repair, break and actual Hunter bed-contact elimination. Facts preserved
  stock 20/20 before reward, real wallet, repair 1, 222.5 door damage and the final
  damage→break→elimination sequence, with at most two factual tips. The prepared
  setup is not advertised as a naturally lost player match.
- **Practice:** actual Begin/branch/sale/item/Pause→Reset controls, normal 26.4 door
  damage, local Repair 5→4, reset 5, real Reaper and one-Legendary restriction were
  observed. Exact signatures of every permanent profile field matched before and
  after combat, items, sale, reset and exit. The original nine-step tutorial was
  separately entered and exited through its real Exit practice control.

### Visual findings and fixes

D inspected the complete screen families at 720/1080 and full-size representative
frames. Gothic surfaces/headings, gameplay numbers, old menu actions and prices
remain readable. New pages are functional production UI, not mockups. Endless has
an actual skull and its own black/violet material, distinct from campaign Hell;
hover, held press and keyboard focus remain visible. The wave HUD reserves its
own title/modifier strip while retaining currencies, Hunter HP, TEAM and warnings.

Feedback led B to fix missing spaces in helper/condition text and make clipboard
success visible. Intermission now distinguishes current eligible milestones from
persisted profile claims, next/all-claimed state and checkpoint status. The four
cosmetics add an iron arched door, turret spires/halo, bed canopy/posts and crest;
cracks/HP, branch identity, Prestige10 crown and exact refund remain visible,
including Reduced FX. Root's full-size result review also found that Challenge results encoded the mode
without labeling it explicitly. B added actual map, difficulty, archetype and
ruleset to both the result paragraph and copied summary; D reran the same real
Challenge path and clipboard readback at both resolutions. No remaining confirmed
blocking layout defect was found.
The existing item-odds column remains small/dense at 720 but is readable at the
captured scale and does not overlap pity or reward controls.

### Audio — TESTED engine evidence

`render-realtime-mix.wav` is an actual master-bus recording of real-time Practice
Reaper combat with actual Inferno and Overdrive activations after the legitimate
shared cooldown. `render-audio-metrics.json` records 105 nonzero playable streams,
no missing assets, peak 6/16 voices, zero dropped events/critical backlog, four
existing music players and 24 audio children unchanged across five mode transitions.
Actual routed events include shots/impacts, Reaper transformation/charge/impact/
scythe, encounter scream, weather and both item activations. WAV duration, PCM
peak/RMS and full-scale sample count are in `render-waveform-metrics.json`.

D confirmed a real defect: immediately Continue after a genuine controlled NPC
breach/elimination stopped its playing death scream and erased pending laughter.
B replaced the full match audio reset with an encounter reset. The final actual
rerun preserves both the playing voice and pending cue across Continue and lets
those queues drain; no fabricated presentation records are used. Before-fix log
`render-audio-transition-fourth.log` reports preservation=false; accepted log
`render-audio-transition-accepted.log` reports true with 14 checks/0.

`render-earned-mix.wav` is also real engine output, but its simulation was
accelerated in batches;1015 low-priority dropped events there cannot establish
natural real-time audio behavior. It remains disclosed as stress/earned evidence.

### Retained intermediate failures

Logs retain failed harness attempts: an occupied full pad; headless onboarding
interception; initial wrong player-room/preparation/rescue assumptions in the
controlled audio test; a click on an intentionally disabled second Legendary;
strict Dictionary int/float comparison after JSON reload; a click before the
campaign result fade completed; manual tutorial-phase cleanup leaving its
controls; a navigation endpoint inside the intentionally solid bed furniture.
These were corrected in D's capture tool and affected cases rerun. They are not
misreported as product defects. `render-early-initial.log` retains the 14/2 bed-center
attempt; `render-early-focused.log` is the accepted successful early flow. The
first real-time mix attempted the second item during its legitimate shared
cooldown; the final verified recording waits and asserts both stocks consumed.

### Limits — UNVERIFIED

Native Windows import/execution, physical PC controls/speakers, human-perceived
sound/art/horror quality, hardware FPS and human balance remain **UNVERIFIED**.
Mouse/keyboard events here were injected into actual Linux Godot controls. All
screens and internal audio were produced on Mesa software rendering with Dummy
hardware output; no Windows performance or subjective listening claim is made.
No fresh performance baseline/comparison was recorded for this phase. No remaining
confirmed visual/audio blocker is marked INCOMPLETE by this bounded D audit;
root/C's broader regression and source report determine overall delivery.

D stops only its private owned Xorg display after capture. Git commits/push and
final source report are owned by root; this index does not claim a GitHub push.
