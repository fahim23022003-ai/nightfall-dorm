# Android adaptation — bounded independent experience audit

Agent D reviewed the new mobile layout, interface and touch-controller source plus application/audio lifecycle integration. This review owns no production files. Native Android gameplay, device frame rate, physical finger sizing, audio hardware output and perceived sound quality remain **UNVERIFIED** unless separately recorded below. No phone or speaker listening session is claimed.

## Controls and lifecycle inspected

The mobile path shares the existing model, economy, buildings, hunter, bots, progression and saves. It adds a visible movement stick, tap-driven room/bed navigation, mobile menu/reward/settings layouts, scrollable reward/help content, and enlarged interaction controls. Windows keeps its existing interface branch. Unavailable build choices can open a confirmation with a visible rejection reason instead of depending exclusively on hover; final purchases remain guarded by the production model.

The application suspension path saves the profile, clears touch/route state and pending placement, pauses the match and sets audio players' `stream_paused`. Resume unpauses streams without starting new music players and leaves the match paused until explicit Resume. Android and Windows use separate local `user://` storage; no synchronization service is implemented. Source inspection is not itself proof of Android OS lifecycle delivery or speaker behavior.

Mobile effects use ten reusable voices; the desktop default remains sixteen. Six existing permanent music/ambient loop players are retained. This is a bounded resource configuration, not a measured Android performance certification. A 30-FPS battery-saver cap and normal 60-FPS cap are user settings; achieved device FPS remains unverified.

## Concrete independent findings

A temporary headless fixture instantiated the actual main scene with `mobile_mode=true`, created a real occupied room and opened the actual build inspector. It used production transforms and controls; no source files or test assertions were modified. Its output was:

```text
EXPERIENCE_CLOSE_CARD_INTERSECTION=[P: (1188.0, 470.0), S: (52.0, 22.0)]
EXPERIENCE_VISIBLE_PAD_EDGE_MODE=bed tile=0 distance_to_bed=39.6232261657715
```

1. **Close button overlaps Dynamo card:** the enlarged close target is 64×60, starting at local `(350,4)`, while the third build card begins at `(276,42)` and is 126×166. Their actual rectangles overlap by 52×22. Shift both card groups and their illustrations/labels downward sufficiently to leave the close target distinct; both rows can still fit the 450-high drawer. This is an actual scene-geometry finding, not a screenshot claim.
2. **Visible floor pad edge can select the bed:** tapping `tile_position(0)+(-21,-18)` lands within the drawn empty pad, but the broad bed-radius check runs first and opens bed upgrades. Prefer owned floor-pad hit tests before bed/door fallback while sleeping, so the pad's displayed hit area behaves consistently.

Both findings were sent to the main production owner and fixed incrementally: build-card groups move down 36 pixels, and floor-pad hit testing precedes bed/door fallback. The same independent actual-scene fixture reran after those corrections:

```text
EXPERIENCE_CLOSE_CARD_INTERSECTION=[P: (0.0, 0.0), S: (0.0, 0.0)]
EXPERIENCE_VISIBLE_PAD_EDGE_MODE=build tile=0 distance_to_bed=39.6232261657715
```

**Both reproduced defects are fixed in the retested scene.** Each temporary harness exited 0; the explicit measured behaviors, rather than exit status alone, establish the findings and their correction. Rendered review follows separately when captures exist.

## Graphical evidence

Actual Xorg/Mesa captures now exist under `docs/screenshots/android/`. Independently viewed these nine frames:

- `16x9-menu.png`, `16x9-build.png`.
- `19_5x9-build.png`, `19_5x9-confirm.png`.
- `20x9-safe-loadout.png`, `20x9-safe-rewards-scrolled.png`, `20x9-safe-settings.png`, `20x9-safe-confirm.png`, `20x9-safe-resumed-paused.png`.

The menu actions and rank are readable. Gold/electricity, hunter HP, Map/Help/Pause and bottom bed/door/build/repair controls remain visible. All six build cards, prices and short effects fit; the corrected close target has clear space above the card row. Confirm and Cancel are separate large controls; the selected placement preview remains visible in the bedroom. The shifted camera leaves the owned room usable beside the inspector.

Loadout/rewards use a bounded scroll viewport; rows beyond that viewport are deliberately clipped inside the list rather than spilling across the footer. The observed settings sliders, mute/guide/battery toggles, difficulty selectors, Start Night, Back and resumed Pause controls fit their safe-area layout. This still-frame review does **not** independently prove scrolling gestures or button actions; those require Agent C's actual-input tests. No obvious new essential-control clipping or overlap was seen in the inspected frames.

The 20:9 capture helper/log reports a synthetic safe area `(80,18,1500,688)` in a1600×720 viewport, scale0.9556. The reviewed UI stays within that area. This establishes the simulated layout behavior, not an Android cutout/OS hardware certification.

The helper's actual lifecycle log reports `paused=true frozen=true music_starts=3/3 mobile_voices=10`, consistent with source inspection: background/resume did not restart the three music stems and left the match paused. It is a Linux simulation, not an Android OS lifecycle or acoustic test.

The same log reports a slow software preview (10FPS in one sampled frame); it is explicitly labeled Linux software preview rather than Android device performance. Neither60FPS nor30FPS achieved device performance is claimed. Physical phone touch comfort, native Android rendering/cutouts, speaker/audio-focus handling and full device lifecycle remain **UNVERIFIED** pending installation/playtesting.
