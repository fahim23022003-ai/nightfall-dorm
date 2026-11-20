# Hunter motion evidence

The six ordinary Hunter films contain chaptered samples of L1, L4, L7 and L10 at
the normal gameplay camera scale. Each chapter uses a prepared seeded Endless
room and stages the comparison level. The Hunter moves through checked walkable
waypoints using the game's movement primitive and heading tracker. At the door,
normal match ticks drive the ordinary windup, strike, paid Needle launches and
projectile impacts. The prepared starting countdown gives the first projectile
time to land before the windup. The native warning, strike and projectile
timings are measured after that setup. The stage records include the exact
texture bound on each frame, the selected pose and the actual impact frames.
All 24 chapters bind five authored views and record a live warning, door strike
and Needle hit with a rendered reaction. The six files contain 3,836 frames.
[Verification totals](motion-verification.json)

- [Crusher](crusher-anchors.mp4)
- [Stalker](stalker-anchors.mp4)
- [Ravager](ravager-anchors.mp4)
- [Phantom Witch](witch-anchors.mp4)
- [Electric Ghost](electric-anchors.mp4)
- [Storm Wraith](storm-anchors.mp4)

The [Stalker reveal](stalker-l10-rebirth.mp4) starts from a prepared encounter
with evolution 10 ready to reveal. Match ticks produce the existing transition,
including the display of L9 before the reveal and the real L10 art swap.
[Reaper’s forms and Soul Siege](reaper-forms-and-siege.mp4) starts just before the
existing transformation deadline and advances the normal Hunter tick through
awakening, warning and impact. In the [Reaper direction plate](reaper-cardinals-720.png),
both forms use the same camera, with authored cardinal headings staged one at a
time and crops taken without rescaling.

The films use genuine Godot 4.6.3 viewports at 1280×720 on Linux llvmpipe. The
captures advance in fixed 24 Hz increments. The MP4s are silent. The footage
demonstrates presentation and recorded combat events in prepared cases.

## Reproduce an ordinary Hunter film

Run in a graphical session with the preview enabled. Use a fresh capture
directory for each Hunter. The encoder checks the frame inventory and the
dimensions and frame count of the resulting video.

```sh
NIGHTFALL_VISUAL_REBIRTH=1 godot --path . --audio-driver Dummy \
  -s tools/visual_rebirth/capture_hunter_anchor_combat.gd -- /tmp/nightfall-crusher crusher
python tools/visual_rebirth/encode_hunter_anchor_combat.py /tmp/nightfall-crusher /tmp/nightfall-films
```

The supplemental recorders are `capture_stalker_rebirth_motion.gd`,
`capture_reaper_form_motion.gd` and `capture_reaper_cardinals.gd` in
`tools/visual_rebirth/`. Each takes an absolute destination directory.
