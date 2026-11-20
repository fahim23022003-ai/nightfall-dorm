# Independent Survivor Rebirth integration

A Godot 4.6.3 Linux graphical run sent ordinary mouse events to the
**Continue Story**, difficulty and **Start Match** buttons. The Stage 1 Long Night profile
started with one legally purchased Repair Kit and one known unlocked perk.
The tests used a separate profile and a stepped lobby clock to isolate
exact simulation times from window timing. The runner can arm the
focus handler explicitly on an X11 dummy display without a window manager.

- The offline lobby shows one human and five AI at both 1280×720 and
  960×540. Ready and Back remain fully inside the visible window.
- Pressing Ready before the AI finish joining marks only the human
  ready. Waiting, suspending, backing out and backing out during loading
  preserve the profile bytes, queued mission, active match time, room
  ownership and stocked items.
- With all five AI ready, the early Ready path started a match at an
  elapsed lobby time of 10.75 seconds plus its 0.42-second transition.
  Without Ready, the countdown waited through 14.99 seconds and
  auto-readied at 15.0 seconds. Both paths issued one ticket,
  retained the selected Story track and loadout, and began at
  match time zero. Repeating Ready did not issue an extra cue.
- All six actors spawned together in a valid exterior corridor.
  The retry kept the same packed map and chose another legal spawn.
  A remote claim was rejected. Normal walking reached the floor
  and the actual E interaction claimed it at 5.90 seconds.
- Sampled AI running reached 90.0 world pixels per second.
  Human movement reached 180.005 within floating-point tolerance.
  The player's bed was reached by legal walking. E closed the
  owned room and unlocked normal gold production at 6.65 seconds.

The native run passed 105 checks. Dummy audio was used for this
rendered run. The sound workstream checks actual cue playback
separately. Native Windows and human usability remain unverified.

[Lobby 1280×720](01-offline-lobby-1280.png) ·
[Lobby 960×540](02-offline-lobby-960.png) · [Loading](03-ready-loading.png) ·
[Exterior spawn](04-exterior-spawn.png) · [Claim](05-claimed-room.png) ·
[Sleep and income](06-sleep-and-income.png) · [Receipt](integration.json)

## Fallback regressions

Ten headless suites ran with Survivor Rebirth disabled unless
the individual feature fixture enabled its own flags. All 5,321
assertions passed, including Story transactions, both boss forms,
signed Hunter contacts, audio, room grid saves, V2 persistence and
4,062 input checks. The rollout-time scene smoke was rerun after the
teammate panel's type annotation landed. Final proof contains the
clean rerun. The fallback Story test reports its known ObjectDB
teardown warning.

[Regression logs](regressions/) · [Native engine log](native-engine.log)

## Reproduce

Run from the project at Godot 4.6.3 in a graphical session.

```sh
XDG_DATA_HOME=/tmp/nd-survivor-lobby godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script tests/survivor_lobby_integration.gd -- /tmp/nd-survivor-lobby-evidence
```
