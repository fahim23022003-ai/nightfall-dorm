# Reproducing the cloud graphical smoke test

The cloud machine has Godot 4.6.3, Xorg with `dummy_drv.so`, Mesa software rendering, and ImageMagick. No shared-desktop control tool was exposed. The test used a real Godot OpenGL window on an Xorg dummy display; screenshots are actual rendered frames, not generated art. A dummy display does not establish performance or hardware compatibility on Windows.

From `/workspace/nightfall-dorm`, start a display (only if `:99` is unused):

```sh
Xorg :99 -config "$PWD/docs/evidence/xorg-dummy.conf" -logfile /tmp/nightfall-xorg.log -noreset -nolisten tcp
```

In another shell:

```sh
DISPLAY=:99 xdpyinfo
mkdir -p /workspace/runtime-data /workspace/runtime-config /workspace/runtime-cache
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config XDG_CACHE_HOME=/workspace/runtime-cache godot --path /workspace/nightfall-dorm --rendering-method gl_compatibility --audio-driver Dummy
```

Capture the desktop from another shell:

```sh
import -display :99 -window root /tmp/nightfall-frame.png
```

The setup and log stay outside game source. Retained frames and the audit results are documented in VISUAL_REVIEW.md. Headless automated tests are a separate check.

The Dummy audio driver avoids expected ALSA device errors on this machine. Audible effects remain unverified. Wait until the log reports the OpenGL API/device before capturing; a screenshot during initial renderer startup can be black.

## Reproducible real-input path

With `:99` started as above, run:

```sh
python /workspace/nightfall-dorm/tools/graphical_smoke.py
```

The helper uses the installed `libX11.so.6`, `libXtst.so.6` through Python ctypes, `xwininfo`, and ImageMagick. It starts and terminates its own Godot process. It waits for renderer initialization, focuses a 1280×800 window, clicks Start, walks into the middle north room, claims it, moves to bed, sleeps, buys the default-tile Needle turret, and pauses. Inspect `docs/evidence/audit-input-sleep-build.png` for **ROOM 2 · SLEEPING**, a closed door, a visible turret, and the reduced gold counter. The helper does not manipulate match-model state. It checks runtime log errors, but rendered outcome inspection is a separate required step.

For actual desktop fullscreen behavior, start the installed window manager in another shell before testing:

```sh
DISPLAY=:99 XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config XDG_CACHE_HOME=/workspace/runtime-cache dbus-run-session -- xfwm4 --replace --compositor=off
```

Without a window manager, fullscreen requests can retain the old physical window size; that is a test-environment limitation. The real-input helper measures the client rectangle and translates design coordinates to physical input coordinates, including letterboxing and window decorations.

## Explicit graphical state fixtures

```sh
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config XDG_CACHE_HOME=/workspace/runtime-cache godot --path /workspace/nightfall-dorm --resolution 960x600 --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/visual_fixtures.gd
```

This helper deliberately populates a room and resources to inspect maximum-level text, all six building icons, the physical 960×600 layout, fullscreen, a specific rejected purchase, and the result veil. Its captures are UI fixtures, not naturally attained gameplay. It uses the public `Window.size`/`Window.mode` APIs; low-level `DisplayServer.window_set_size` can bypass Window bookkeeping and create misleading cropped-frame results in a test harness.

The extended helper waits for real bed income, clicks a second floor tile and buys a Dynamo, waits for positive electricity, hovers the Arc turret effect tooltip, and returns to the main menu from the active match. It uses installed Tesseract OCR to fail if rendered text does not confirm SLEEPING, selected Turret L1, tile 2 selection, Generator L1, and positive electricity. This guards against a timed input sequence merely running without producing the intended state. Actual images remain the evidence for visual review.

For a rendered match with an automated player:

```sh
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config XDG_CACHE_HOME=/workspace/runtime-cache godot --path /workspace/nightfall-dorm --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/visual_match.gd
```

This explicit fixture resets to seed 71, claims room 2 and sleeps at time zero, then lets BotAI spend the player's actual default 25 starting gold and earned resources. It advances engine time at 4× speed and captures actual gameplay and a natural terminal result. It does not inject resources, building upgrades, hunter damage or a result. It is evidence of an automated-player match, not manual skill or pacing at normal speed.

Start the state fixture at `--resolution 960x600` when Xfwm4 is running. A requested initial client size of 1280×800 exceeds the 1280×800 desktop once window decorations are included, so the window manager can automatically maximize it and ignore a subsequent size-only request. The fixture log records actual physical sizes; use those recorded sizes when assessing each frame.
