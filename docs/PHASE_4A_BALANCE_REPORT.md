# Phase 4A — advanced hunter, Long Night and Hell

## Status and provenance

IMPLEMENTED: three configurable difficulties, revised advanced target decisions,
continuous siege pressure, telegraphed charged attacks and difficulty feedback.
Continued clean work at 4c2f6b330a95df5fb1578483f627323fac011867.
Recovery tag: pre-phase4a-4c2f6b3. Existing campaign/profile, building/refund
and horror-event tests passed before production changes. Agent A loaded the
original code before edits; retained baseline logs identify that context.

## Why Long Night was easy

The pre-change 60-match diagnostic resolved all matches: active strategies
won 50/50, minimal defense lost 0/10. Balanced Normal averaged 191.8 seconds;
Long Night 193.1 seconds, nearly identical. Balanced, door-first and marksman
players were never attacked in those 30 samples across both modes. Hard balanced
player damage was only 6.4% of team damage; hard door-first 2.6%.

- Old Hard changed HP/damage/speed by only 15%/15%/5%, sharing Normal's
  45-second escalation and attack interval.
- Door HP ×1.8 dominated bounded defense penalties and distance, encouraging
  avoidance of defended players while five teammates killed the hunter.
- Travel consumed attack commitment, allowing early departure after arrival.
- Candidate threat omitted cross-room turrets that actually fired into approaches.
- Paid 70 HP repairs cost 12 gold; late 26 gold/s beds and amplifiers could fund
  healing above old pressure. Needle upgrades multiply base DPS by 5.44.
  Extra slots increase strategic headroom; small rank perks were not the root.

See DIFFICULTY_BASELINE.md. These samples are not human win rates.

## Configurable differences

| Setting | Normal | Long Night | Hell |
| --- | --- | --- | --- |
| Initial HP multiplier | 1.0 | 1.15 | 1.25 |
| Initial attack multiplier | 1.0 | 1.30 | 1.50 |
| Movement multiplier | 1.0 | 1.08 | 1.12 |
| First escalation opening | 45 active seconds | 45 | 45 |
| Later level cadence | 45 seconds | 32 | 25 |
| Damage growth per tier before multipliers | 10 | 14 | 18 |
| Attack-interval multiplier | 1.0 | 0.94 | 0.88 |
| Charged pattern | none | fourth strike ×1.65 | third strike ×1.9 |
| Charge warning | none | 0.75 seconds | 0.9 seconds |
| Sustained siege repair floor | 100% | 65% | 40% |
| XP multiplier | 1.0 | 1.25 | 1.50 |

Stage factors compose independently. Growth ramps over eight seconds; speed and
minimum interval remain bounded. Normal retains original balance. No huge HP
pool, turret nerf, price increase, income nerf, slot removal or rank expansion.

Advanced modes evaluate accessible route length and neighboring firing defenses,
use lower door weighting, and commit during the actual siege rather than travel.
Static graph estimates share a nearest visible start across candidates.
Decisions occur at selection/reassessment, not every frame. No player bias,
movement cheat or teleportation was added.

Charged attacks emit a warning event and cannot damage before the delay.
Displaced ATTACK state returns to navigation instead of damaging a remote door.
Custom-map stalls reseek accessible targets without artificial relocation.
Retargeting cancels an old charge. Continuous pressure ramps only after the
opening and restores full repair effectiveness when the hunter leaves.
Manual and automatic repairs use the same communicated factor. Reassessment
has its own timer and cannot reset continuous siege pressure.

Hell has a red preparation button, expert-risk explanation and visible
charged/cadence/repair modifiers. Stage/perks persist through selection and retry.
Existing alerts/audio carry heavy warnings; HUD shows actual attack, interval,
windup and own-door repair effectiveness. No competing inventory or warning UI.

## Investigation and verified counterplay

Initial tuning produced zero Hell wins in 25 samples and early 37–59 second
hospital defeats. Moving stronger mechanics behind 45 active seconds provided
a fair establishment window without adding more HP. Independent QA found remote
attacks; the position guard fixed them. Agent D found pressure resetting at
same-target reassessment, an oversized HP-bar minimum and long warning text.
Separate timers, deferred bar sizing and shorter text fixed these.

Final targeted behavior/UI: 268 checks, zero failures.
Final 90-strategy matrix across all five maps, three difficulties and six policies:
Normal 29W/1L, Long Night 14W/16L, Hell 1W/29L, with zero navigation, resource
or unresolved failures. Policies include balanced, turret, door, economy,
delayed defense and adaptive repair, with existing perks and earned resources.
This shows sampled separation, not a human difficulty rating.

Final Hell room probes: 5W/25L in 30 economy/dreamer matches, victories on maps
1–4. Six proactive 75%-health repair Mansion probes produced two victories,
rooms 1/2 at 193.2/188.1 seconds with 4556.9/4904.2 player damage. The same
later-reacting policy lost. Earned-resource victories are thus demonstrated on
every map without relaxing the continuous 40% repair floor. Other room/policy
combinations are not certified beatable by this finite sample.

The regular plus extended regression checks earlier phases, all maps, campaign,
save compatibility, perks, purchase/double-click/refunds, audio/alerts and existing
timestep/room/rank matrices. All suites completed successfully, in resumed batches after correcting the
spatial fixtures. New 90-strategy matrix passed; all-map144 matches finished
70W/74L/0unresolved, campaign20 matches8W/12L, legacy12 matches9W/3L.
Extended checks:27 timestep matches,144 room/strategy matches and48 rank/perk
matches (22W/26L), zero failures;20ktransactions/175941invariants passed.
Separate-process profile roundtrip and main startup passed. No repeated large
matrix was needed after test-only fixture corrections.
Logs are retained in docs/evidence/difficulty/. Legacy fixtures now place the
hunter at the actual approach, and Hard growth assertions derive from its
intentional new profile; no assertions were disabled.

Actual Linux Godot/Mesa audit: 23 checks, eight captures, exit 0. Real mouse
selection/start/retry preserves Hell/stage; genuine 0.9-second warning has no
early hit. Sustained 40% repairs heal 28 HP, exactly 70×0.4. Actual HP bar height
is eight pixels without text overlap; warnings fit at 1280×720 and 960×540.
These are prepared fixtures, not manual Windows playthroughs.

## Limits and next playtest

TESTED: production behavior, finances, navigation, earned-resource counterplay,
save/load and rendered Linux UI. No known remaining failure in tested paths.

UNVERIFIED: native Windows feel/FPS/audio, subjective fear, broad human balance,
every strategy/room/perk/seed combination. Tick timings are diagnostic evidence,
not target-hardware certification. Hell is severe in these samples. Experienced
players should test room choice, proactive repairs and early damage investment.
No claim is made that simulation win rates predict your friend's results.

INCOMPLETE/out of scope: Phase 4B Grim Reaper, Mythic ranks, Android/APK and
unrelated features were not started. Windows project/export settings unchanged.

## Backup

Final response records exact committed/pushed SHA after comparing remote work
with local HEAD. Push without force to the existing private branch; a local
commit alone does not establish backup. No public deployment or publication.
