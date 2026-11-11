# Independent QA — cartoon experience milestone

This bounded review covers the new focused camera, contextual placement confirmation and model-owned travelling projectiles. It does not rerun the earlier 144-match audit or claim visual enjoyment from headless tests.

## Actual camera and placement input

Command: `godot --headless --path . --script tests/redesign_ui.gd`.

Executed result: **173 assertions, zero failures**, exit status zero. Evidence: `docs/evidence/redesign/independent-qa.log`.

The test instantiates the actual main scene and sends viewport mouse motion/down/up with the real window stretch transform. All six rooms are exercised. It checks every floor pad projects into the unobscured play area, actual tile selection opens the correct contextual palette, choosing a building starts a preview without charging, actual confirmation charges once and creates the chosen building, duplicate confirmation cannot spend again, occupied tiles reject, Escape cancels without charge, out-of-room previews disable confirmation, and map mode cancels pending placement. The overview contains every room center; focus restores the proper zoom. Actual M/G input toggles map/tutorial; selecting an owned pad from the overview refocuses correctly. A preview can be relocated to another pad before committing. Insufficient resources, advanced prerequisites, pause, restart and return-to-menu state are covered.

UI fixtures freeze the node's frame processing to keep cameras and resources deterministic while dispatching input; they keep the production model's purchase guards active. Resource-rich fixtures isolate interaction correctness rather than prove natural affordability. Headless input does not establish artwork readability or visual polish; graphical evidence is separate.

## Independent projectile edges

Command: `godot --headless --path . --script tests/redesign_projectile_edges.gd`.

Initial executed result: **12 assertions, one failure**. After the production fix, the independent rerun executed **12 assertions, zero failures**, exit status zero. Final evidence: `docs/evidence/redesign/projectile-edges.log`.

Eleven passing assertions cover homing toward the actual moved target, no damage before arrival, a previously launched allied shot completing after its source room is eliminated while crediting only that source, expiry without phantom damage, correlated cancellation events, global projectile cap enforcement and recovery when a slot opens, and restart of both event ID sequences.

The reproduced and fixed failure was an awake-contact terminal ordering issue: an awake player has already been reached by a one-HP hunter when an allied projectile arrives in the same tick. Before the fix, the impact resolved victory before the exposed-player capture branch committed the elimination. The equivalent breached-bed case already gives defeat priority. The production owner moved awake-contact elimination ahead of projectile damage resolution. The independent rerun now verifies defeat, dead assigned-room state and exactly one elimination for the same scenario. The 173-assertion actual-input UI suite was rerun after this fix and remains passing.

Source-room-death flight persistence is an observed policy: already-fired shots can land after the source is eliminated, while new shots cannot launch from an eliminated room. There is one hunter identity; the test does not claim multi-enemy targeting support.

## Decision cadence, not a fun score

Command: `godot --headless --path . --script tests/redesign_pacing.gd`.

Executed result: **12 bounded scenarios, zero failures**; nine active victories and three passive defeats. Evidence: `docs/evidence/redesign/pacing.log`.

Seeds 7, 8 and 99 each run passive, balanced, guard and economist policies from normal starting funds. Every 0.1 simulated second, affordability is probed by cloning the live room and invoking the real production purchase methods on isolated copies. The test compares the original live state before and after the probe, including resources, levels, HP, buildings and `last_error`; the probe did not mutate it. Purchases are identified through actual increases in the player's recorded spending.

Observed active policies make **12–28 purchases**. Initial waiting time and the match-ending tail are tracked separately from actual purchase-to-purchase intervals. Their median interval between purchases is **3.6–7.7 seconds**, and the longest interval including the match-ending tail is **17.6–24.2 seconds**. A consecutive stretch with **no affordable legal purchase of any kind** lasts at most **4.9 seconds**. Longer waits of **13.8–22.8 seconds** occur while another legal action remains affordable: they are policy-selected saving or waiting, not economic inability to act. Passive players make zero purchases while an affordable action remains available throughout their 41.9–94.4 second matches.

This distinction does not establish that the affordable alternative is tactically valuable, nor does it prove a human player finds those waits entertaining. These are bounded economy and automation measurements. The longest waits suggest the UI should communicate saving goals and ongoing combat clearly; they do not justify arbitrary income inflation without further play evidence.
