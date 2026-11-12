# Baseline HUD and build-panel review

Captured the actual clean `work` source **457560dc4a8712dd644b7a7cdca509218fe83f70** before overhaul production edits. Godot 4.6.3 on Linux, real Xorg/Mesa llvmpipe rendering, Dummy audio sink. The capture exited **0**, with **16 checks / 0 failures** and four fresh screenshots. All four were inspected at their actual resolution. Tracked runtime differences were empty immediately after capture; B was then notified that production edits could begin. Current production may subsequently differ.

## Fixture and evidence

A unique isolated profile started the real Stage 1 Normal campaign on Abandoned Dorm. The real claim/sleep APIs established ownership; the player was positioned at the bed for this controlled seated layout. Five NPC room states were populated for representative room labels. Combat was held while UI/rendering advanced. A real mouse click on an empty owned floor pad opened the build panel. Starting **25 Gold / 0 Electricity** remained unchanged. This is a controlled layout/input fixture, not a natural-play or purchasing simulation.

- [Default HUD, 720p](baseline-render/default-hud-720.png)
- [Open build panel, 720p](baseline-render/open-build-720.png)
- [Default HUD, 1080p](baseline-render/default-hud-1080.png)
- [Open build panel, 1080p](baseline-render/open-build-1080.png)
- `baseline-render.log`: exact engine output, including the driver limitation that changing V-Sync is unsupported.
- `baseline-ux-observations.json`: measured layout, camera, resources and check counts.
- `baseline-render-manifest.json`: file/source hashes and provenance.
- `baseline-display-cleanup.json`: only the capture's command-verified private display was stopped.

## Concrete UX findings and cause

Coordinates below are logical 1280×720; 1080p scales them by 1.5.

1. The default toolbar is fixed at **(20,460), 1240×46**, ending at y506. It sits about 64% down the screen rather than at the bottom; 214 pixels remain beneath it. In the closed-panel view, lower teammate rooms remain visible behind/below this toolbar, while the own-room view stays compact above it.
2. Opening the build panel reveals a fixed **(20,506), 1240×198** body down to y704. Header plus body occupies **244 pixels / 33.9%** of the viewport height. Its twelve build cards form a readable four-column, three-row grid, but the screen-wide lower panel covers the lower rooms. The Needle purchase is enabled at the real starting balance; more expensive cards are visibly unavailable.
3. Opening the panel causes **zero measured camera or player movement** at both resolutions: camera position `(325,219.6094)`, zoom `(0.763723,0.763723)`, player `(43,-17)`. Do not attribute the issue to a camera jump on opening. The room remains compact even when the panel is closed.
4. At baseline, `scripts/bottom_context_panel.gd:4–5` defines the fixed header/body rectangles. Installation places them; `refresh()` at lines 77–79 reapplies the fixed body position/size and directly assigns visibility. An animated panel must coordinate that refresh, or each refresh will overwrite a position tween.
5. At baseline, `scripts/game.gd:463–467` reserves a fixed 1160×320 focus area centered at `(640,295)`, including the approach head/foot extent, regardless of panel state. That safe region explains the persistent compact focus and unused closed-panel area. Reclaiming space should be an intentional camera/layout decision.

These findings support the requested compact bottom toolbar and intentionally opened, animated panel. The capture does not test future expansion slots, purchases, upgrades, refunds, combat, audio or new animations. Existing fonts, role art and Gothic styling are visibly present. No functional economy defect was found by this inspection.

## Limits

Native Windows, human playtesting, subjective visual quality and audio listening are **UNVERIFIED**. No production files, historical evidence, Git commits or push operations were changed by D. The private display is stopped. This bounded baseline task is complete; final implementation review waits for a separate request.
