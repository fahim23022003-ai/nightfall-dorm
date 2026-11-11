# Android private-test export (Godot 4.6.3)

The existing Windows Desktop preset is retained byte-for-byte. Android Test shares the same scenes, rules, AI, audio, progression and `user://` persistence; it selects platform touch/display adaptations through the Android/mobile feature. No store publication or release signing is performed.

## Export configuration

| Setting | Value |
| --- | --- |
| Engine/templates | Godot4.6.3 stable, matching official templates |
| Preset | Android Test |
| App | Nightfall Dorm |
| Package | `org.nightfalldorm.game` |
| Version | `0.3.0-test`, code1 |
| Package format | Debug APK, prebuilt template; Gradle build disabled |
| Architectures | `arm64-v8a`, `armeabi-v7a`; no x86 emulator ABI in the phone APK |
| Orientation | Landscape, read from the shared project setting |
| Renderer | GL Compatibility, explicitly selected for mobile |
| API | Minimum24(Android7), target36(Android16), inherited from exact4.6.3 template |
| Icons | Original project SVG main/adaptive/monochrome launcher art in `assets/android/` |
| Permissions | No internet, microphone or external-storage permission requested by this offline game |
| Backup/sync | Local app save; Android system backup disabled; no cross-platform sync |

Godot requires `rendering/textures/vram_compression/import_etc2_astc=true` before Android export, including GL Compatibility projects. Windows texture originals and its preset remain available. Min/target SDK override fields stay empty because Godot's non-Gradle APK export cannot override them; the actual produced manifest is inspected instead of assuming older documentation defaults.

## Windows setup and APK export

1. Pull/download private branch **work** and import `project.godot` using **Godot4.6.3 standard**, not .NET. Confirm F5 still runs the Windows version.
2. Install the matching **4.6.3 export templates** through **Editor → Manage Export Templates**.
3. Install **OpenJDK17** (recommended by official Godot docs; newer versions are supported, cloud used OpenJDK21).
4. Install Android Studio's SDK/SDK Manager or Google's Android Command-line Tools. Install **Android SDK Platform36**, **Build-Tools36.0.0** and **Platform-Tools**. The standard official4.6 documentation also lists NDK28.1.13356709 and CMake3.10.2.4988404 for native/custom Gradle development; this project's prebuilt GDScript APK export does not compile native code and does not require those extra native-build packages.
5. In **Godot Editor Settings → Export → Android**, set **Java SDK Path** to the JDK root and **Android SDK Path** to the SDK root. Godot normally creates its debug keystore in editor user data after the JDK is configured. If unavailable, generate/configure a local debug keystore via Godot's documented workflow. Keep keys/passwords outside the repository. Debug credentials are intentionally absent from the tracked preset.
6. In **Project → Export**, select **Android Test**. Leave Gradle disabled, keep the two ARM architectures, and export to `builds/android/NightfallDorm_Android_Test.apk` with **Export With Debug** enabled. Do not select Windows Desktop for this step.
7. To use the CLI after editor setup:

```powershell
Godot_v4.6.3-stable_win64.exe --headless --path . --editor --import --quit
Godot_v4.6.3-stable_win64.exe --headless --path . --export-debug "Android Test" "builds/android/NightfallDorm_Android_Test.apk"
```

If Godot's executable is elsewhere, use its full path. Templates, SDK/JDK, keys and generated APKs are local dependencies/artifacts, not checked-in secrets or substitute source ZIPs.

On Linux/cloud, `bash tools/android/export_debug.sh` performs import, debug export and static APK verification after editor SDK/JDK/debug signing are configured. Optional `ANDROID_SDK_ROOT` selects verification tools; `GODOT_BIN` selects the engine. Cloud uses a separate writable XDG editor-config directory for signing setup so independent editor/test instances cannot overwrite each other's local SDK settings.

## Verify and install privately

`python tools/android/verify_apk.py builds/android/NightfallDorm_Android_Test.apk --sdk-root <sdk-root>` checks a real APK manifest/classes, Godot project/scripts, both ARM libraries, app label/package/API/orientation, APK signature,16KB native alignment, missing private keys and excluded development files. Verification uses `apksigner`, `zipalign` and modern `aapt2`; old `aapt` cannot correctly inspect every string-typed attribute emitted by the4.6.3 prebuilt exporter.

Copy the APK to an Android7+ ARM phone supporting OpenGL ES3.0. Open it and permit installation from your chosen file manager when Android asks. Alternatively enable Developer options/USB debugging and use:

```powershell
adb devices
adb install -r builds/android/NightfallDorm_Android_Test.apk
adb shell monkey -p org.nightfalldorm.game -c android.intent.category.LAUNCHER 1
```

This is a debug/private test, not a Google Play release. Future updates to an installed APK require the same signing key. Uninstalling to replace a differently signed test build removes its local app data; preserve needed progress first.

## Cloud tooling and evidence

The full official Godot4.6.3 export-template archive was already cached from earlier work. Its Android debug/release/source templates were extracted to the writable template directory. Official Google SDK archives (platform36, build-tools36, platform-tools37.0.3) were downloaded through the permitted network and checked against Google's repository XML SHA1 digests. Command-line tools19.0 were installed locally; sdkmanager initially failed because its default `.android` cache was under a read-only home, so SDK components were unpacked from verified official archives into `/workspace/android-sdk`. No system-wide/home permission changes or network-policy bypass was used.

A local debug key and its configuration are stored outside Git. No private key/password is in the tracked export preset, assets or verification logs. Signer certificates/fingerprints shown by verification are public debug-certificate metadata.

No emulator or KVM device was preinstalled. `adb devices` could not start its native server because it tried to create `/home/agent/.android` on the read-only filesystem; its actual output is retained in `docs/evidence/android/build-adb-devices.log`. Thus cloud Android installation/launch, real-device touch/audio and30/60FPS performance remain **UNVERIFIED**. Static APK validation and desktop touch simulation are separate evidence, not claims of device execution.

The official4.6.3 non-Gradle template exporter can leave an unused resource-table reference to `themed_icon.xml` after replacing its content into `icon.xml`. `aapt2` may warn about that unused template entry; the actual app icon path exists and the supplied adaptive/monochrome content is present. This is documented rather than silently called a flawless device test.

## Official references consulted

- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html (web endpoint blocked in cloud; same official documentation read via its GitHub4.6 source below)
- https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_for_android.rst
- https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/platform/android/export/export_plugin.cpp (exact engine's API24/36 defaults, no-Gradle restrictions, signing and icon behavior)
- https://dl.google.com/android/repository/repository2-3.xml (official component URLs/checksums)

Windows and Android saves are separate local `user://profile.json` files. No synchronization is implemented. Device audio quality, app suspend/resume and input comfort require a real phone check even when simulation and packaging tests pass.

## Final artifact and updates

The final named debug APK was actually exported at `/workspace/NightfallDorm_Android_Test.apk`, with a copy in ignored `builds/android/`. Exact size/SHA256 and final verification are in `docs/evidence/android/APK_MANIFEST.json` and `final-apk-verification.log`. Probe APKs are historical and are not the delivered file. No native Android launch/performance proof is claimed.

Use the same package identifier and debug signing key for updates that retain app data. A locally generated key may differ from the cloud debug key; Android then rejects an in-place update. Do not solve that by uninstalling without accepting/backing up private app data loss. Keys are deliberately outside Git. Windows and Android profiles are separate unless explicit synchronization is added later.

Packaged-project verification also loaded the APK's extracted Godot resources/bytecode in Linux Godot and passed main startup plus52 touch/196 layout checks. This does not execute the Android native libraries or certify Android drivers. If Android kills a background process, relaunch returns to menu; only permanent progression/settings are saved, not the full unfinished match world.
