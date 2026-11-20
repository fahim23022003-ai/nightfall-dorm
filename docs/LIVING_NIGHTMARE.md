# Living Nightmare

Project baseline `32c205d` was verified against `origin/work`. Baseline
720p Godot captures record the Crusher's opening and a Stalker siege.
The earlier preview applied small per-vertex offsets to a full-body
texture and selected independently painted cardinal poses. The silhouette
could travel and deform while the joints, weight transfer and contact pose
showed limited movement. [Pre-change Godot evidence](evidence/living-nightmare/baseline/)

The Living Nightmare launcher enables the opt-in update, Phase 14F visuals,
Full Room Grid and V2 maps with an isolated profile. The previous V2.3
playtest, V1 and fixed launchers remain separate.

## Character and combat presentation

The initial 2D pilot uses authored cutouts from the approved directional
character art, reconstructed areas underneath moving parts and independent
joint motion. Godot samples the actual attack target and landed hit record
for contact. VFX usage follows legitimate door damage, material and the
Hunter's identity. Neither the art nor the effects changes damage,
attack timing, Hunter AI, buildings or navigation.

## Audio

The earlier score kept multiple zero-gain loops running and reused tracks
across combat situations. The opt-in router keeps the menu score in the
menu, crossfades the gameplay score by state, and retains existing volume,
mute and track settings. The first direct siege at the human player's
door starts a bounded heartbeat and ducks the score. Existing strike
events still drive contact sounds.

## Story Mode

**Continue Story** opens the current mission for the selected difficulty.
The 50 authored entries form ten chapters with short clues and existing
Hunter encounters. Each difficulty has a separate position and highest
clear. First-clear XP is shared across difficulties and the corresponding
historical Campaign missions. Global rank, item inventory, achievement
records and Endless remain in the existing profile.

A loss gives a one-level setback down to the latest earned five-level
checkpoint, with Level 1 as the overall floor. The mission's seed is
deterministic across retries. A Level 50 clear finishes only that
difficulty and opens the ending in the archive.

The Story record is versioned. Migration copies the original file once
to `.before-story-v1.bak` before writing the new record. It only imports
a contiguous run of legacy stage clears on a difficulty explicitly
recorded in the old profile. Other archived clears remain intact and still
count toward the shared first-clear reward. Existing profiles with an
invalid Story record remain read-only.

[50-level catalog](../scripts/story_catalog.gd) ·
[Windows playtest instructions](LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md)

## Verified coverage

- **Articulated pilots.** Stalker Level 1, Ravager Level 1 and both Reaper
  forms use independently traced front, back, left and right art. The
  renderer solves arm and leg joints from those cutouts and animates body,
  head and garment sections separately. The model owns timing.
  [Animation footage and contact checks](evidence/living-nightmare/animation/)
- **Combat effects.** All six ordinary archetypes and the Reaper use distinct
  contact effects on confirmed hits. A blocked strike cannot leave a landed
  contact mark. Durable doors use impact effects appropriate to their material.
  Standard and Low captures retain the hit cues. Stalker and Ravager
  fingertips and the Reaper blade reached the door at the sampled damage
  frame. [Full contact reel and receipts](evidence/living-nightmare/vfx/)
- **Audio.** A live 720p Godot capture with stereo audio includes the
  menu, preparation, approach, siege, desperate defense, Hall recovery,
  Reaper, Crimson and victory routes. The opening player-door heartbeat
  measured 4.96 seconds. The fixture stages later event states and gives
  the first siege enough time to hear the full warning. There are also
  paired audible mixes and a separate defeat check.
  [Synchronized audio and playback tests](evidence/living-nightmare/audio/)
- **Story.** Native screenshots and video show the menu, difficulty and
  loadout, Level 1 clear, Level 17 defeat returning to 16, chapter
  transition, and the Level 50 ending. Later capture profiles stage the
  previous clear records. The captured outcomes use the game's combat
  and settlement rules. Twenty-seven item-free automated battles included
  a final victory on each difficulty. Only selected levels, rooms and
  policies were played through combat.
  [Story screenshots and catalog](evidence/living-nightmare/story/) ·
  [Migration and match checks](evidence/living-nightmare/qa/)
- **Preservation.** Thirty matched V2 Campaign cases have identical
  gameplay receipts across the preview switch. Ten broader suite runs
  cover the older Campaign and save paths, Endless, boss mechanics,
  core model, V2, Full Room Grid and inputs.
  [Regression logs and matched runs](evidence/living-nightmare/regressions/)

## Performance and remaining delivery

The 24-building Stalker room went from 37.96/46.55 ms to 45.84/71.53 ms
median/p95 on Standard. Low went from 37.32/46.52 ms to 40.13/58.88 ms.
This was Linux Mesa llvmpipe. The Reaper timing also varied between runs.
The preview keeps the legacy launchers available, and native Windows
speed, Intel UHD behavior, and human visual approval remain open.
[Timing data, memory, and workload](evidence/living-nightmare/performance/)

Resume from the evidence commit above the verified preview export:

1. Review the tracked joints at normal gameplay speed across all four views.
   Refine Stalker's independent hair strands and finger movement, Ravager
   foot planting, and the Reaper's rear view and occluded blade. The new
   rig has discrete directions and uses 2D artwork.
2. Author and verify the remaining 58 ordinary evolution states. Start with
   Stalker and Ravager levels 4, 7 and 10, then Crusher, Witch, Electric
   and Storm anchor rigs. The existing 60-state artwork continues to
   render. Turn, stagger, evolution, healing, death and supernatural
   gesture acceptance still needs complete coverage.
3. Verify the menu, audio, story difficulty and combat readability through
   native Windows play. Profile the rendering cost with the Intel target.
   Expand combat and pacing playthroughs into the middle chapters.
4. Extend chapter presentation from the briefings, result animations and
   archive to additional rendered story scenes and original chapter stings.
   Approve a final build after animation and owner playtest checks.

[Windows archive verification and package hashes](evidence/living-nightmare/windows/)
