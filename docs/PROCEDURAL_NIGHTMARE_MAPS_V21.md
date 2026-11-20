# Procedural Nightmare Maps V2.1

The tactics pass applies to the Hunter's first form in Hard and Hell
Campaign matches with the V2 preview enabled. Launch with
`NIGHTFALL_PROCEDURAL_MAPS_V2=1`, or use the Windows playtest launcher.
The layout generator and all ten families carry over from V2.

## Siege decisions

The Hunter now considers the navigable travel time, remaining door HP,
active station repairs and weapon coverage at each reachable occupied
room. Its scoring uses the same estimates for choosing a first approach
and reconsidering a siege. It keeps attacking if its current door is
losing meaningful HP. If the door is holding, the Hunter switches only
when an alternative offers a clear improvement after travel. That
comparison requires a gain above both five seconds and 20% of the
current estimate.

The player's warning banner indicates a continued siege or a new approach
toward their room. Existing attack and boss telegraphs keep priority.
A reinforced and repaired door can buy time. Covering its approach with
weapons raises the estimated cost of staying there and damages a Hunter
that follows through. Weapon range, damage, income, costs, NPC rules,
Hall rules and the Reaper's phases use their existing values.

Standard, Endless, fixed maps and V1 retain their earlier Hunter
decisions. Save and checkpoint formats stay compatible across preview
flags. The Windows comparison launchers use separate test profiles.

## Verification

[Matched simulations and failure analysis](evidence/nightmare-maps-v21/qa/) ·
[Godot gameplay evidence](evidence/nightmare-maps-v21/visuals/) ·
[Active-combat timing](evidence/nightmare-maps-v21/performance/) ·
[Regression logs](evidence/nightmare-maps-v21/regressions/) ·
[Windows export verification](evidence/nightmare-maps-v21/windows/) ·
[Windows playtest checklist](HELL_TACTICS_WINDOWS_PLAYTEST.md)
