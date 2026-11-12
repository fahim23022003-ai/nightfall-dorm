# Phase 5B-2A visual and audio evidence

Agent D ran real Godot4.6.3 OpenGL/Mesa llvmpipe using a private Xorg display.
Final `tools/capture_advanced_items.gd`: **84 checks, zero failures,20PNGs**.
`render-final.log` records real transactions, saves and engine sound diagnostics.
The coordinator/developer own production changes; D edited only this capture and
its evidence. The script creates an isolated profile with a clearly prepared
20-unit/item inventory and configured stage/health/time/doors. These are genuine
rendered production methods, not naturally earned/played matches or balance data.

## Inspected actual frames

- `render-01-original-inventory`, `render-02-advanced-inventory`, and
  `render-03-advanced-inventory-small`: two pages preserve the original eight and
  expose the additional eight names, rarities, quantities, original icons and
  functional descriptions. Existing permanent perk selection remains separate.
  The advanced page remains usable at960×540.
- `render-04-three-rarity-wheel-odds` and `render-05-epic-reveal`: all16icons are
  in the actual animated selector. The seeded actual victory settlement chooses
  an Epic reward before animation. Exact odds are visible, Skip reveals it, and
  acknowledgement proceeds without granting again. The three-rarity header now
  measures490/490available pixels and fits inside its panel.
- `render-06-barricade-shield-combination`: metallic door overlay, shield dome,
  actual absorption/mitigation and duration are visible. The positive shield
  value and the two BLOCK totals occupy separate numbered lanes left of the
  door; actual door HP and shield HP remain separate and readable.
- `render-07a-reduced-effects-setting`, `render-07-reduced-effects`: the real
  Reduced visual effects checkbox saves, reloads correctly, and lowers particle
  counts while retaining gameplay markers and readable values.
- `render-08-feather-rescue`: a real nonlethal threshold-crossing attack triggers
  one durable feather consumption, +270HP for the prepared1800HP door, golden
  feather burst and a USED hotbar state. The incoming-114 and restored+270 are
  visually separated from the actual624HP result.
- `render-09-inferno-burn`: actual in-range owned turrets fire, projectile impacts
  ignite a single burn, and real elapsed damage reduces HP. The prepared Reaper
  form shows fiery turret/projectile accents, burn status and remaining duration;
  this explicit form setup is not a natural transformation playthrough.
- `render-10-pillow-income`: the occupied bed glows, displays bonus income and
  actually changes its income modifier. `render-11-coupon-price-preview` shows
  the real12G discounted Needle purchase rather than20G. Arming spends no stock;
  successful controller purchase spends one, stores actual12G investment, and
  the asserted refund is6G. `render-12-coupon-purchase` shows the purchase effect.
- `render-13-decoy-navigation`: the doll sprite/aura/countdown sit at a valid
  door approach and the actual Hunter moves toward it. `render-14-shadow-smoke`
  shows the room's smoke and a valid different room target, rather than teleport.
- `render-15-rescue-selection`, `render-16-team-rescue`, and
  `render-17-team-rescue-small`: only the living teammate's damaged intact door
  is enabled; selection actually heals it, consumes one stock and produces a
  beam/heal marker at the teammate door. Full-map framing makes the remote
  teammate visible. Empty/invalid rooms are disabled.
- `render-18-expiry` verifies temporary timers clear. `render-19-retry-clean-activation`
  follows actual defeat→spin→acknowledge→Retry button clicks; the new match has
  clean temporary state and a fresh Pillow activation is heard again.

The previous dense door feedback is materially improved: numeric aggregation
and separate text lanes keep resource/heal/block values outside the essential
HP area, with outlines and effect text drawn above particles. Transient world
art can still be busy in deliberately simultaneous prepared bursts, but these
inspected compositions keep door bars, warnings and building controls readable.

## Actual functional audio

The final observer diagnostics show all eight new activation cues playing,
including the automatic feather, plus actual owned-impact burn effects and
existing feedback. The Retry Pillow cue increments a second time. All76streams
load, no assets are missing, four permanent music players remain started once,
and there are no queued critical sounds left at the final diagnostic.

`render-advanced-mix.wav` is an actual AudioEffectRecord master-bus recording,
not a concatenation of source WAVs: stereo44.1kHz,15.0465seconds, peak1294/32767,
RMS201.49, **zero clipped samples**. Measurements are in
`render-audio-measurements.json`. Godot used Dummy output while its actual mixer
was recorded; no human audition or Windows speaker quality is claimed.

## Findings and provenance

Initial rendering found a real three-rarity heading overflowing the spin panel;
the developer reduced its font, and the final width assertion and screenshot
pass. Initial dense prepared starts also dropped some earned activation sounds
when ordinary effects filled the noncritical frame pool. The developer routed
all item activation cues through the existing bounded critical retry mechanism;
all activation cues play in the final run. Noncritical competing effects may
still be deliberately dropped by voice/frame limits (nine in this accelerated
fixture), preserving the existing audio budget.

The first Inferno assertion failure came from this capture's two turret pads
being outside range; the capture now buys actual in-range pads. It was a fixture
issue, not a production burn defect. `render-initial.log` and `render-second.log`
retain these earlier states; `render-final.log` is the passing final source run.
No production assertions were disabled.

UNVERIFIED: native Windows import/launch/FPS/input/speakers, subjective excitement
or musical quality, natural human play and every possible camera composition.
The software display emits an expected unsupported VSync warning; final output
contains no script/parse errors. Only the D-owned Xorg process was stopped.
