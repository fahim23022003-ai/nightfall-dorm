# Cartoon experience redesign — executed evidence

11 November 2026. Status: **PARTIAL — playable and regression-tested; target-platform and final presentation work remain.**

## What changed

Original cartoon atlases replace the prior ornate look across all six room themes, five bed stages, five door stages, player animation, five bot identities, hunter state poses, both turret upgrade families and all support-machine upgrade stages. A focused room camera, map/zoom controls, attack attention, optional tutorial, illustrated three-by-two build cards, green/red preview and explicit confirmation replace the cramped overview and immediate purchase flow. Existing model geometry, economy and AI were preserved.

Travelling homing projectiles now own their flight and impact in the simulation. Impact applies actual damage and credited statistics; expired/invalid/terminal shots cancel. Construction, upgrades, repairs, income and attacks have event-linked presentation.

## Actual checks and discovered fixes

Phase A rendered one prepared student room before all six rooms were converted. Agent D independently found a clipped Dream amplifier title and a hunter HP bar extending below the HUD; explicit two-line titles and bar repositioning fixed those issues. Prepared fixtures disclose extra resources and direct setup; they are not natural progression proof.

Agent C independently exercised real scene input, all six focused rooms, valid/invalid/cancelled placements, affordability, map, tutorial, pause and clean restart: **173 assertions passed**. Projectile edge tests first failed an awake-contact/impact race; defeat now commits before an already-flying shot can award victory. Independent rerun: **12 passed, zero failed**. Dedicated flight tests: **22 passed**. See `REDESIGN_QA_REPORT.md`.

Final graphical captures also exposed two separate artifacts: an overcompressed floor texture formed a tiny checkerboard under doors, and the hunter atlas retained a visible low-alpha rectangular backdrop. The sill now uses a solid architectural surface; the atlas was edited for real transparency. Final captures are regenerated after those corrections.

## Render evidence

Command (actual Xorg/Mesa rendering, no headless visual inference):

```sh
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --path . --script tools/capture_redesign.gd
```

Use the writable XDG variables from README. Captures: `docs/screenshots/redesign/`; raw final output: `docs/evidence/redesign/render.log`. The helper captures the actual 1280×720 viewport after `RenderingServer.frame_post_draw`.

- `01-menu`, `02-overview`: actual menu and strategic map.
- `room-1-theme` through `room-6-theme`: prepared claimed/sleeping room fixtures, 1000 gold / 200 electricity for interaction inspection.
- `03-build-cards`, `04-valid-preview`, `05-invalid-preview`, `06-upgrade-panel`: production controls and renderer with prepared funds; no unconfirmed purchases.
- `stage-1-fixture` through `stage-4-fixture`, `stage-5-bed-fixture`: explicit level fixtures, not naturally earned levels.
- `10-own-door-attack-fixture`: hunter placed at the player's doorway and production attack tick executed; demonstrates damage warning/camera/pose without claiming naturally chosen targeting.
- `07-natural-sleep-income` through `16-defeat`: two complete rendered, normal-fund matches. Room claim/bed setup is scripted; subsequent active purchases use production BotAI at 4× speed. One active victory and one passive defeat. The capture helper checks actual terminal model results before exiting successfully. It does not establish human fun or manual control quality.

Camera/input projections were independently tested in all six rooms. Native Windows runtime, audible output, high-DPI and touch were not tested. The software driver warns that VSync cannot be changed; this is disclosed rather than counted as a game failure.

## Pacing and remaining work

Twelve additional normal-fund pacing runs resolved (9 active wins / 3 passive defeats). Active median time between purchases: **3.6–7.7s**; maximum measured no-affordable-action stretch: **4.9s**. Longer 13.8–22.8s waits were chosen savings while other legal actions remained affordable. These are deterministic policy observations, not human enjoyment or exact Haunted Dorm timings.

Reference parity remains **UNVERIFIED**: previous official listing/TapTap/GamingOnPhone requests were blocked by proxy 403. No inaccessible reference statistics were invented. Remaining limitations include incomplete bot directions, one map/hunter, session-local settings, distance-only turret targeting, Windows/audio validation and human balancing.

## Final independent visual and release check

Agent D inspected the final actual build-card, own-door-attack, overview, maintenance room and victory frames after the alpha/sill corrections. Cards, ownership, pads, warning/HP and result buttons were readable; no blocking visual defect was found in those frames. A minor maintenance plaque/door overlap led to a smaller wall-label font and a fresh eight-frame room/menu/overview capture (`rooms-final.log`). Additional small atlas edge fragments and limited directional coverage remain polish work, not hidden proof of commercial completion.

Final `bash tools/check.sh --extended` exited0: all regular suites passed again, plus27 complete timestep matches and144 complete matrix matches (72 active victories/72 passive defeats). `final-tests.log` is the actual output; this is183 headless matches within that final release suite. Independent pacing12 and final rendered2 are separate executions, not novel unique scenario counts.

Windows export completed with no error signatures. Local demo: `/workspace/NightfallDorm-CartoonRedesign-Windows-x64.zip`; checksums and font/engine notices are inside. The embedded pack started with Linux Godot in an empty directory (`windows-pack-smoke.log`, exit0). This verifies packed resources, not native Windows behavior. EXE/ZIP are local ignored artifacts, not GitHub releases.
