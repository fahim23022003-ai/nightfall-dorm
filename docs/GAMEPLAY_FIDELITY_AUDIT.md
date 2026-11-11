# Gameplay fidelity audit

11 November 2026, Singapore. Starting checkpoint: `ea9438edee9e97c90eac21518ff62d3bb45204bf`, verified against GitHub `work` before editing. The existing project was preserved.

## Evidence boundary

**Exact Haunted Dorm gameplay resemblance: UNVERIFIED.** Fresh requests to TapTap `https://www.taptap.io/post/1176667`, GamingOnPhone `https://gamingonphone.com/guides/haunted-dorm-beginners-guide-and-tips/`, and Google Play search each failed with curl exit 56, HTTP 000, proxy CONNECT 403. No authentic reference screenshots or video frames were obtained. There is no web-search/browser tool available in this session that supplies the missing source content. Repeating blocked requests or inventing mechanics would not improve evidence.

Previous documents define the requested game contract and measured Nightfall Dorm behavior; they are not independently verified Haunted Dorm statistics. No reference-based P0/P1 mechanic change is justified by inaccessible sources. The comparison below uses **U** for unavailable reference behavior, not a confirmed mismatch. All local values remain original configurable approximations.

## Gap analysis

| Feature | Reference behavior | Current implementation | Evidence | Difference / limitation | Priority |
| --- | --- | --- | --- | --- | --- |
| Menu / preparation | U | Menu, handbook, settings, configurable 30-second preparation | Scene suite; screenshots 01–02 | Exact original flow unknown | Unverified |
| Dorm map | U | Six rooms around a shared corridor | Screenshot 02 | One fixed map; original proportions unknown | P2 validation |
| Movement / room choice | U | Collision-aware movement, claim with E | Existing real-input evidence; model suite; screenshot 03 is a disclosed claim fixture | Bot doorway spawning simplified; reference unknown | Unverified |
| Sleeping / gold | U | Income only from living occupied beds | Gameplay/property checks; screenshot 04 | Exact original rates unknown | Unverified |
| Bed progression | U | Five levels, data-driven prices and requirements | Gameplay/audit checks; screenshots 05, 07 | Configured approximate balance | Unverified |
| Door defense | U | HP, upgrades, paid and facility repairs, breach | Gameplay/audit checks; screenshot 09 | Sleeping automatically closes door | Unverified |
| Turret placement | U | Six valid empty tiles per room; actual selection | Scene input checks; screenshots 06–07 | One fixed grid | Unverified |
| Turret combat / upgrades | U | Range, cooldown, actual HP damage, upgrades, visible traces | Rate/audit checks; screenshot 10 | Instantaneous attacks; no projectile flight/occlusion | Unverified |
| Electricity | U | Separate resource from dynamos, spent on advanced purchases | Property/gameplay checks; screenshot 07 | Exact original production/costs unknown | Unverified |
| Support structures | U | Repair, income amplification and turret enhancement work | Audit effects checks; screenshot 07 | Names and visuals original | Unverified |
| Hunter target / navigation | U | FSM, corridor routes, weak-door weighting and retargeting | Prior matrix; model/audit checks; screenshots 08–09 | Geometry-specific routing | P2 broader scenarios |
| Hunter attack / growth | U | Door attacks, breach, resident elimination, timed growth | Regression checks; screenshot 12 | Reference level triggers unknown | Unverified |
| Survivor bots | U | Five configured profiles saving/spending autonomously | Previous 144-run matrix; current rendered match | Spawn at assigned doorways | P2 human evaluation |
| Match pacing | U | Active/passive distinction in deterministic tests | Previous matrix; current 12 smoke runs and two graphical matches | Human difficulty remains untested | P2 validation |
| Results | U | Hunter death wins; player elimination loses; clean restart | Scene/audit suites; screenshots 11–12 | Exact original results presentation unknown | Unverified |
| Camera | U | Fixed top-down overview with canvas scaling | New 1280×800 frames; prior minimum/fullscreen evidence | Other devices/aspects not certified | P2 validation |
| UI / controls | U | Keyboard/mouse; new availability states and explicit selected upgrade prices | 3,209 new checks; scene suite; visual review | Touch/controller absent | P2 fixed / future scope |
| Combat presentation | U | Traces, flashes, HP bars, floating income, original shapes | Screenshots 04, 09–10 | Placeholder art, no authentic visual comparison | P2 polish |

## Implemented improvements

- **P2: unclear purchase affordance.** Unavailable actions previously looked actionable. Build, bed, door, repair and selected-building upgrades now disable for the actual lifecycle, tile, prerequisite, resource and level-cap conditions, with reasons/effects in tooltips. Queries do not spend resources or mutate transaction errors.
- **P2: ambiguous selected upgrade.** The selected building uses its friendly catalog name, and the upgrade button displays its current gold/electricity cost or MAX. Button styling now makes enabled/disabled controls easier to distinguish.
- **P3, trivial verified overlap:** an independent screenshot review found the hunter state caption over a top-room door-level label. It was moved to the side and combat recaptured. No AI or combat rules changed.
- **P1 delivery gap:** a Windows release export preset and actual x86-64 executable now exist. Official templates were SHA-512 verified before extraction. Native Windows execution is still unverified; see [WINDOWS_READINESS.md](WINDOWS_READINESS.md).

No speculative mechanic, unrelated feature, paid asset, or copied reference artwork was introduced. No verified P0 defect remains from this session.

## Quality assessment (0–10)

These are implementation judgments supported by executed tests and frames, **not original-game fidelity points**.

| Category | Score | Evidence and practical limit |
| --- | ---: | --- |
| Core gameplay resemblance | **UNVERIFIED** | No accessible authentic reference behavior/image/video; no substitute numerical score |
| Dorm layout / navigation | 8 | Actual full map plus collision/room tests; only one fixed layout |
| Bed economy | 9 | Income, levels, atomic costs and property tests; no human balance proof |
| Door defense | 8.5 | Repairs, HP/upgrades, breach and defeat tested; approximate balance |
| Turret combat | 8.5 | Actual traces/damage, range/cooldown and cap tests; deliberately simple attacks |
| Electricity / upgrades | 9 | Separate production/spending and all support effects exercised; local original rates |
| Ghost AI | 8.5 | Existing broad matrix and fresh rendered approach/attack/elimination; map-specific routing |
| Survivor bot AI | 8 | Saving/profile behavior and natural progression; doorway spawning and limited human-strategy evidence |
| Visual quality / UI | 7.5 | Independent bounded review: visual 7, UX 8; new actual frames, no critical sidebar overlap; placeholder art remains |
| Stability / coverage | 8.5 | Fresh regression suite, new availability consistency checks, clean export/pack smoke; native Windows/audio unverified |

The three largest remaining weaknesses are blocked reference verification, untested native Windows behavior, and placeholder presentation/human balance validation. The feasible delivery and UX portions were improved; the unavailable verification is not claimed complete.

## Tests actually executed this session

`bash tools/check.sh` passed (exit 0): 125 gameplay assertions, 19 scene/input checks, 71 audit assertions, 20,000 transactions / 175,941 property checks, six attack-rate scenarios and 12 completed representative simulations (nine victories, three defeats, zero unresolved). The first integrated run had 3,207 new UI checks; after two small tooltip/invalid-selection safeguards, the final focused run passed **3,209**, and the scene suite again passed 19/19. Final export-pack startup passed from an empty directory.

Two additional complete rendered matches used ordinary starting resources: automated balanced victory at approximately 149.50 simulated seconds, and passive defeat at approximately 41.70 seconds. They use fixture claim/sleep and accelerated time, not manual player skill. The combat-only recapture is a partial run and is not counted as another completed match. **Fresh completed match runs: 14.**

The previous 144-room/seed matrix and 27 timestep matches are retained evidence, not rerun claims. No model, AI, economy, price or damage rule changed, so repeating them would add little value here. Logs: [regressions](evidence/fidelity-regressions.log), [final availability](evidence/fidelity-ui-availability-final.log), [final scene](evidence/fidelity-scene-final.log), [captures](evidence/fidelity-captures.log), [combat recapture](evidence/fidelity-combat-recapture.log).

## Decision

**READY FOR MANUAL PLAYTEST.** The tested core and real Windows export are available for target-device verification. This does not certify exact Haunted Dorm equivalence, Windows execution, audio quality or finished commercial art. Source and evidence are committed and the authorized branch is pushed with remote-SHA verification at completion. The binary is a local downloadable playtest artifact; it is not deployed or published as a GitHub release.
