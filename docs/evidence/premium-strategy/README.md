# Phase 5D-1 rendered premium UI and strategy review

## Baseline provenance

Before production edits, Agent D captured **45 actual Godot viewport PNGs** from
verified clean `work` production source
`496b9b9df9efbe95f99f2efc0e7a5de3c6597815`. Only the coordinator's checkpoint
document changed during capture. The baseline gate was announced before B began
UI implementation. `render-before.log` exits 0 with **73 checks, zero failures**
and zero engine errors. `render-manifest.json` records dimensions and SHA256.

The new `tools/capture_premium_strategy.gd` reuses the previous capture's read-only
fixture helpers without modifying old tools/evidence. A unique isolated profile
is prepared with Master XP, five stage records, two permanent perks, 20 of all 20
items and 200 RM Cash. These manually supplied fixture resources are not naturally
earned progress or a human player's save. Gameplay fixtures use actual stage
startup, room claim/sleep, paid Arc purchase/upgrades, settlement and Lucky Spin.
The tutorial view genuinely claims its room before selecting its sleep objective.

Actual Godot 4.6.3/OpenGL/Mesa llvmpipe renders under a private Xorg display. Primary
states are captured at 1280×720 and 1920×1080: main menu, pointer-hover/held-press/
focus, stages, each of the three selected difficulties, shop/hover/press,
preparation/siege HUD, building inspector and pause. Additional 720p frames show
actual shop success, three inventory pages, ranks, two achievement pages,
settings, handbook, Level 10 upgrade/sale inspector, result/spin, tutorial,
opening and title. Source images are unedited engine output.

## Baseline observations supplied to the developer

- Existing metal/glass nine-slice theme and haunted facade are meaningful Phase 5C-3 work
  to preserve. Many actions still share the same generic rectangular material
  without action-specific emblems. Heading text mostly uses the ordinary body
  font; only the main brand has the existing serif treatment.
- Hover and held-press are actual injected mouse events. Cropped Start-button
  pixels differ from neutral (roughly 9/255 and 3.5/255 mean RGB respectively).
  Focus is visually very subtle, mostly text pixels. The after review must
  establish a clearly visible focus cue, not infer it from a theme definition.
- Normal and Long Night share almost identical material; Hell adds red and a
  selection check. Gameplay descriptions are mostly tooltip-only. The loadout
  is already dense, so adding mode cards/contracts requires deliberate layout.
- Common shop items have recognizable 56px glyphs, but lack richer product
  illustration/presentation. Actual purchase produces 182 RM and 21 Repair Kits,
  confirming functioning transactions rather than mock controls.
- Gold has a coin and Electricity a cyan bolt; persistent RM Cash is plain text.
  Resource identities can be made more consistently distinct across screens.
- Building cards already have tight text/cost space; new action emblems and
  specialization choices should preserve hit areas, explicit prices and legibility.

No quantitative timing baseline was recorded before the gate. Timing taken after
production starts must not be described as the original `496b9b9` baseline.

## Final rendered comparison

There are **45 preserved BEFORE / 113 AFTER PNGs**: 45 paired states plus 68 new
strategy-specific views. `render-manifest.json` rechecks all baseline hashes as
unchanged and records every image's dimensions/SHA256.

| Final run | Checks / failures | Engine errors |
| --- | --- | --- |
|45 paired screens/state views, `render-after-final.log`|85 / 0|0|
|Actual strategy/UI/input/accounting/mixer fixtures, `render-details-final.log`|264 / 0|0|
|Five maps focused/overview plus warmed observations, `render-maps-observations.log`|21 / 0|0|

Checks include repeated paid upgrades and invariants, not that many independent
human scenarios. D inspected actual main/stage/mode/shop/HUD/build/pause screens,
all inventory and achievement pages, ranks/settings/handbook/result/spin,
tutorial/opening/title, both resolutions, new perk/contract screens, all three
Hunter warning poses, every branch's selection/Level 10 inspector, all three room
traits and all five map environments. The coordinator independently receives
these source images; no screenshot is a static UI mockup.

Actual improvements over the saved baseline:

- Action-specific doorway, shop chest, storage, crest, book, gear, retry,
  construction, upgrade, repair and sale emblems distinguish purposes. Raised
  top chamfers, restrained side rails, a shallow shadow, pressed-depth movement,
  smooth hover tint and a bright keyboard-focus ring visibly change real controls.
  Logged actual BaseButton draw modes confirm hover/held press; focus ownership
  is checked. Mouse release outside cancels without buying/launching.
- Locally bundled Grenze Gotisch headings give the menu, mode names, major events,
  campaign, secondary screens and Welcome title a distinct Gothic identity.
  Body descriptions, quantities, cash balance, prices, HP and refunds stay in the
  readable Interface font. Existing Phase 5C-3 facade, fog, surfaces and gameplay art remain.
- Normal/Long Night/Hell are real equal-size shield/moon/flame cards, with distinct
  materials, explicit descriptions and a textual selected state. The new separate
  perk and optional-contract screens avoid squeezing more rows into the old
  preparation page. A click on Long Night saves the actual difficulty selection.
- Common products now have larger original mechanical-tool/chest/battery/radar
  illustrations. RM Cash has a distinct banknote; Gold a coin; Electricity a cyan
  electrical emblem. Prices/effects/owned quantities remain clear at both sizes.
  Actual purchase consumes 18 RM and adds exactly one Repair Kit; an empty wallet
  produces genuine disabled affordability states.
- Deterministically selected actual Crusher/Stalker/Ravager models produce their
  own real warning events and readable poses/name cues. The Crusher's heavy
  treatment, Stalker's spectral outline and Ravager's claw accents are visible;
  the original Hunter art is reused rather than a fully new rig. Preparation
  explains strengths/weaknesses; gameplay preserves real TEAM count and compact
  contract state, with full counterplay/failure text available in tooltips.
- Paid level 4 Needle/Arc choices show both mutually exclusive specializations,
  actual tradeoffs, real discounted Gold/Electricity prices and original branch
  emblems. All four branches are selected through real buttons, consume the
  armed coupon only on success, advance to 5 and then receive five actual paid
  upgrades to 10. Precision's 204px range is visible. Real UI sale credits the exact
  50% eligible-investment refund once and cannot repeat the refund.
- Room plaque icons/name/benefit/drawback remain above empty pad rows; the nearest
  vacant-room guide makes the actual tradeoff clear before claiming. All five
  original worlds render with their real geometry. Reaper transformation,
  telegraph and impact are genuine model transitions and are shown separately.
- Actual three-turret construction fails Limited Defense. Its receipt shows no
  bonus and the full reason. No Legendary Help first qualifies for 8 RM; repeating
  that stage/mode/contract at the second resolution truthfully shows already
  claimed and pays 0. Duplicate settlement pays nothing. Keyboard Enter on the
  focused Settings action opens the actual settings screen.

Representative pairs and new views:

| View | BEFORE | AFTER |
| --- | --- | --- |
|Main menu 720p|[Before](before/01-menu-720.png)|[After](after/01-menu-720.png)|
|Keyboard focus|[Before](before/04-play-focus-720.png)|[After](after/04-play-focus-720.png)|
|Selected Hell 1080p|[Before](before/06-mode-hell-1080.png)|[After](after/06-mode-hell-1080.png)|
|Common shop 1080p|[Before](before/07-shop-1080.png)|[After](after/07-shop-1080.png)|
|Max upgrade/refund|[Before](before/20-upgrade-max-panel.png)|[After](after/20-upgrade-max-panel.png)|
|Optional contracts|—|[Actual cards](after/extra-contracts-720.png)|
|Needle choices|—|[Actual discounted choices](after/extra-specialization-turret-720.png)|
|Arc Level 10|—|[Storm Coil 1080p](after/extra-level10-storm-1080.png)|
|Room choice|—|[Fortified](after/extra-room-1-720.png)|
|Failed contract|—|[Actual result](after/extra-contract-failed-result-720.png)|
|Reaper|—|[Actual telegraph](after/extra-reaper-telegraph-1080.png)|

## Issues found and corrected

- Gothic wordmark line metrics initially collided with the subtitle. Actual ink
  now clears it; compact action-icon budgeting restores the full How to Play label.
- Initial wide black shadow ledges and sidebars looked heavy/slatted. B reduced
  them to a shallow translucent shadow and narrow rails; final real images show
  the refinement rather than retaining the first pass.
- Trait drawbacks initially sat behind top-row pads. The plaque was moved upward;
  actual focused views on Dorm/Hotel/Lab and the other maps confirm clearance.
- New strategy text initially replaced persistent TEAM count and cut a long
  failure reason mid-sentence. The compact HUD now retains TEAM and ACTIVE/FAILED;
  the full reason remains in the tooltip and contract result card.
- New sale icons squeezed long refund labels. Economic font/icon/gap budgeting
  now keeps both exact refunds and 50% visible in paid Level 10 ordinary/discounted
  inspectors at 720p/1080p. C's independent glyph-budget tests supplement the raster.
- Returning from a recent level-up/result to practice retained a combat warning,
  falsely announcing Hunter growth in safe practice. B resets stale warning/
  danger/level/floating state; the final actual tutorial frame is safe and clear.
- Major Welcome/complete/dormitory headings initially kept the default font.
  Their bounded horror-font treatment is now centered using actual glyph width;
  creator credit/story/instructions retain the body font.

## Fixture limitations and intermediate evidence

The isolated fixture manually supplies progress/resources and positions actors.
Branch purchases are real and ledger-backed, but these funds are not earned in a
natural match. Result views use prepared sufficient occupied-time/damage and
Hunter HP, then the real model tick seals its terminal outcome and the normal
profile transaction settles it. They establish UI/transaction integration, not
human victory rates, strategy superiority or anti-cheat security.

The first baseline max-building inspector used direct fixture mutations before
its normal HUD update, so historical header values can lag its prepared building.
After review explicitly refreshes read-only item/HUD state before each match
capture, as normal production processing does. Old evidence was not rewritten.
The synthetic XP fixture similarly has no matching historical highest-rank stats.
Prepared Reaper time jumps are not a natural encounter trajectory; no healing or
balance conclusion is drawn from cross-frame HP changes in those fixtures.

`render-after-initial.log` retains the first 85/0 paired review before refinements.
`render-details-initial.log` retains one fixture failure: its second-resolution
assertion incorrectly expected another 8 RM for an already claimed contract. The
actual production receipt correctly paid 0. The final test checks the first 8 and
later 0 explicitly; the test was corrected without altering production rewards.
The final 264/0 run and its engine-error scan are the accepted detail evidence.

## Bounded frame and audio observations

`render-frame-observations.json` records warmed 2.5-second Linux llvmpipe samples:
mean 32.678 ms at 720p, 46.430 ms at 1080p, 31.003 ms at Reduced 720p; p95 approximately 39.972,
52.225 and 37.000 ms. Warm material cache 18→18 is stable. This is a short prepared
stage 1 observation on a shared software-rendering host, without a fresh prephase
measurement; it is neither a Windows FPS guarantee nor proof of performance
change. Root-child count is a fixture bound, not a long-session memory test.

`render-premium-mix.wav` is an actual stereo 44,100 Hz Godot Master-bus recording via
AudioEffectRecord/Dummy output: 43.096 seconds, peak 0.0230103, RMS 0.00386990,
**zero full-scale samples**. 105 streams load with no missing assets. Real purchase,
refund, Needle/Arc, coupon, archetype warning, Reaper transformation/charge/impact
and victory events were observed. Thirty-three bounded low-priority events were
suppressed during concentrated prepared upgrade bursts; no critical events were
pending at capture end. This is mixer evidence, not subjective listening.

No confirmed blocking presentation defect remains in these reviewed fixtures.
Retained map/survivor artwork, functional repeated pad grids and some small
ornaments remain relatively simple. Character animation continues to use the existing 2D sprites.
Native Windows import/run, physical controls/display, hardware/long-session FPS,
subjective human beauty/fear/audio comfort and human balance remain **UNVERIFIED**.
The parent report owns broader regressions, balancing, saves and final Git status.

The owned private Xorg process 97986 was stopped after the final display work;
no other display process was stopped.
