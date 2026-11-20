# Survivor Rebirth pre-edit baseline

Godot 4.6.3 native 1280×720 viewport captures from verified tracked-clean
`c4e82c9` on `work`. Isolated throwaway profiles and Linux Mesa
llvmpipe were used for each capture. The SHA receipt holds both the
checked-out and remote branch IDs.

## Main menu and Story

The baseline shows the existing Continue Story menu, Level 1
preparation and actual victory on one generated Standard match.
The capture uses the real scene and ordinary settlement. Its prepared
profile provides a deterministic seed. [Menu](story-main-menu.png) ·
[Preparation](story-level-01-preparation.png) ·
[Result](story-level-01-victory.png) · [Capture receipt](story.json)

## Post-start room selection and movement

On the original V2 Hell Labyrinth fixture, seed 10358, the map was
inspected at the opening. The player walked through Room 02's entrance
using normal actor movement, claimed it at 2.40 seconds, and slept at
3.00 seconds. The initial forecast estimated three seconds to the door
and seven seconds for a Hunter approach. Wallet started at 25 Gold and
0 Electricity. The first actual door strike landed at 48.0 seconds.
The walk clip reproduces the elapsed three-second simulation at 30
encoded frames per second. [Map](labyrinth-room-02-opening-forecast.png) ·
[Walk](old-walk-from-spawn.mp4) · [Bed](normal-bed-entry.png) ·
[Door strike](first-live-door-strike.png) · [Capture receipt](opening.json)

## Fresh tutorial and Shop

A new temporary profile entered the original welcome. Its actual
main menu action opened the tutorial. Using the existing practice
skip exited to the menu. A separately prepared 100 RM Shop balance
paid 18 RM for one Repair Kit through the real purchase button. The
updated wallet and inventory matched after loading the profile again.
[Welcome](old-welcome.png) · [Tutorial](old-tutorial.png) ·
[Shop](old-shop.png) · [Purchase](old-shop-purchase.png) ·
[Capture receipt](tutorial-shop.json)

Each curated capture finished with zero assertions failed.
These pre-edit runs establish existing appearance and input behavior.
They use no owner profile or native Windows test session.

## Reproduce

Use the committed `tools/capture_living_story.gd` and
`tools/capture_fair_start.gd` runners at the recorded checkpoint.
Run the saved tutorial and Shop fixture as a Godot script in a
graphical session, with a fresh `XDG_DATA_HOME`, after copying the text
fixture to a file ending in `.gd`.

[Baseline revision](revision.txt) · [Native tutorial and Shop fixture](capture-tutorial-shop.gd.txt)
