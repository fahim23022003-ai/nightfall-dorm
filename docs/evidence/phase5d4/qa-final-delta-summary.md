# Additive final-delta acceptance — independent QA C

TESTED: `tests/phase5d4_qa_final_delta.gd` **302 checks / zero failures / actual exit 0**, Linux Godot 4.6.3. Receipt: `qa-final-delta-receipt.json`; log: `qa-final-delta-accepted.log`. The earlier 7,357-check acceptance and its source hashes remain unchanged.

- Fifteen real unclaimed lethal-contact scenarios cover all five maps and Normal/Long Night/Hell. The actual model tick records one terminal elimination, no invented room owner/dead room, no evolution buff or credit, and no fabricated room-elimination event.
- Forged terminal strings are rejected. Repeated ticks, duplicate settlement, reload and reuse of an old terminal against a new run cannot duplicate claims or close the wrong run. A failed final save rolls back the settlement and permits one valid retry.
- Settlement and reload preserve the normalized existing profile's XP, RM Cash, all 20 item stocks, spins, achievements, campaign/statistics, Endless records, pity and cosmetics. The run closes without a stuck active/resume state and gives zero payout.
- Forty-five real Challenge preview combinations format the literal `55%HP` safely. The actual visible Challenge screen label shows the formatted threshold and ruleset 3. Preview does not change the permanent save.

The initial injected-all-items fixture legitimately discovered an already-earned Item Collector achievement on first reload. The final fixture saves and reloads before its baseline, retains achievement checks, and compares JSON numbers by value. Initial failed logs are retained; no product behavior was weakened to pass.

The receipt records all five source hashes that changed since the earlier snapshot. Game framing/input and AudioDirector terminal-cue changes were already committed in `1d16069` and covered by the parent's repeated full-regression gates and specialist evidence. The new narrow mechanics are the unclaimed terminal counter and escaped percent literal. The additional WrathPresentation feedback was independently reviewed as bounded, read-only drawing: at most 11 live burn actors, one lure and the latest heal per room; no node creation, RNG consumption or model writes. D owns its actual rendered inspection.

UNVERIFIED: native Windows, hardware mouse behavior and subjective visual/audio quality. C performed no new full-suite sweep or Git push. Root owns complete sweep results and final remote verification.
