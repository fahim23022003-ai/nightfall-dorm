# Verified Android milestone backup

Feature/content commit: `b80e75e1ccc75bb451dae0158a262b32804a7ad5`. Private repository `fahim23022003-ai/nightfall-dorm`, branch `work`.

Successful push:

```text
To https://github.com/fahim23022003-ai/nightfall-dorm.git
   0de1434..b80e75e  work -> work
 * [new tag] pre-android-2026-11-11 -> pre-android-2026-11-11
```

Actual subsequent `git ls-remote`:

```text
b80e75e1ccc75bb451dae0158a262b32804a7ad5	refs/heads/work
0de14345e6f4f66f027fd1038a82a6278947eca3	refs/tags/pre-android-2026-11-11
```

Branch SHA matched local HEAD. Recovery tag matched the exact pre-port Windows/Phase2 baseline. No force push was used. Source, touch/layout modules, assets, presets, QA, build tools and evidence are backed up; the APK is a local ignored artifact, not a public/private hosted release.

Final APK: `/workspace/NightfallDorm_Android_Test.apk`;67632749bytes;SHA256 `01e8225e87e2919a9dd15c1b82fd30fcc4054051591870fce5214b6f2d9315b7`. Manifest/signature/ARM libraries/native alignment/offline GLES launcher checks passed. Signing keys/passwords stayed outside Git.

Additional final verification extracted only the APK's own Godot assets into a temporary directory, then ran Linux Godot against that exported project (not workspace source). It started the actual main scene, passed52 real touch/lifecycle checks and196 layout checks using external test harnesses. The tests used isolated QA saves. This verifies packaged resources/bytecode and mobile logic on Linux; it is expressly NOT Android ABI/OS/device execution. Native Android gameplay/performance remain UNVERIFIED.

This documentation follow-up records the verified feature commit. Its own final pushed SHA is reported after remote verification in the task response. No Windows EXE, store publication or external deployment was made.
