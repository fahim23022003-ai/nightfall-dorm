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
