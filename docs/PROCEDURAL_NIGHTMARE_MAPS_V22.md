# Procedural Nightmare Maps V2.2 fairness audit

The V2 Campaign preview keeps V2.1's commitment to a productive siege.
On Hard and Hell, the first-form Hunter now compares alternate doors
when defenses erase at least half its landed strike damage during the
reassessment window, including at least one strike's worth of damage.
The comparison uses observed net door loss to estimate time to breach.
The existing 55-second estimate ceiling and route improvement threshold
still apply. A defended door buys time through actual defense. The
Hunter continues the siege when the other doors offer slower or riskier
approaches.

Open **Map** before claiming a room and select a vacant room to inspect
its opening. The forecast shows the survivor's estimated walk to the
entry and the Hunter's estimated travel from spawn if it targets that
door first. The Hunter can choose other targets and different routes
during the match. The countdown, room geometry and door traits use the
existing rules.

The banner **Defense held · Hunter rerouting** identifies a successful
defense-induced switch away from the player. Existing charge and boss
warnings keep priority. Standard, Endless, fixed maps, V1 and the Reaper
use their existing rules. The change uses match-local observations and
adds no fields to saved checkpoints.

## Evidence

[Matched matches, exact cases and spending timelines](evidence/nightmare-maps-v22/qa/) ·
[Godot combat and map evidence](evidence/nightmare-maps-v22/visuals/) ·
[Combat performance](evidence/nightmare-maps-v22/performance/) ·
[Regression logs](evidence/nightmare-maps-v22/regressions/)
