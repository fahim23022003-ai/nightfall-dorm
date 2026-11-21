# Phase 20 Player-First Preview

Extract the Windows x64 ZIP and double-click **Play Phase 20 Preview.cmd**.
The separate preview profile starts on Low at 960×540. Use **Play Performance
Preview.cmd** to compare with the earlier rules and its own separate profile.
The earlier standalone Performance release remains available.

1. Complete Practice. Claim a room, sleep to earn Gold, place a Dynamo, cancel
   the placement tool and buy a Needle. Watch the Needle land a shot.
2. Continue to Story. In a real siege check Door HP, physical Armor and the
   ×1.5 Bed Gold display. Use **R** to pay for up to 25 seconds of repair,
   with a 60-second cooldown from purchase.
3. Open **G** for Help. Check that the match, including income and repair,
   stops until you resume. **I** opens Items without spending anything.
4. Drag with the middle mouse button to look around. Scroll to zoom and
   press **Home** to lock to your room. Use **M** for the map and **H** for
   its danger shading. Redder rooms reflect recent actual main Hunter hits.
5. Try **Record Phase 20 Diagnostic.cmd** for an isolated FPS comparison.
   Press **F10** once at the end of a representative match to save the local
   Godot report. Record the scene, machine count and preset for comparison.

## Scope and compatibility

Door rules apply to new Campaign and Story battles launched in Phase 20.
Endless snapshots, code challenges and the earlier fallback use their
existing repair and economy rules. Settings add optional validated values
for adaptive effects, tactical alerts and room identity.

Adaptive performance reduces decorative effects during sustained slow frames.
Hunter articulation, projectile travel, damage, telegraphs and audio retain
their existing implementation. Trim stays active until the next match or
until switched off in Settings.

The protected walkway remains in use. Demolition, gameplay-changing synergies
and random gameplay incidents are withheld. The existing paid Ward remains the
emergency defense action. The timed evolution warning uses the existing
evolution clock and audio. Room identity is a selectable preset. The attack
history reports recent room contact and key events within the current match.
Chapter trophies reflect earned chapter completion.

Linux Godot tests and the package resource checks can verify game logic and
exported content. Windows execution and Intel UHD frame timing require a
native Windows playtest.
