# Visual and interaction audit

The later [extended audit](AUDIT_VISUAL_REVIEW.md) supersedes the initial pass below. It includes actual final result-veil rendering, real nondefault-tile selection, generator purchases and electricity, specific rejection messages, effect tooltips, and physical 960×600/fullscreen validation. Historical first-pass limitations below describe that earlier revision, not the final audited state.

Agent D independently inspected the actual game through a Godot 4.6.3 OpenGL window on Xorg `:99`, rendered by Mesa llvmpipe at 1280×800. Inputs were real XTest keyboard/mouse events; screenshots were captured with ImageMagick. See GRAPHICAL_TESTING.md for reproducible display setup. These results are separate from headless QA.

## Executed interactions

- Opened main menu, How to Play, Back, Settings, Back, and Start Game.
- Clicked the sound slider and fullscreen control without a crash. The cloud has no audio output device, so audible sound quality is **unverified**.
- Used WASD through a doorway; pressed E to claim an available room, approached its bed, and pressed E to sleep. The UI changed AWAKE → SLEEPING and income 0 → 2 gold/s; the door closed visibly.
- Paused/resumed with Escape. Bought a real Needle turret from the sidebar; gold decreased, a turret appeared on the selected floor tile, and a range ring appeared.
- Observed bot-owned rooms, buildings, bed/door upgrades, floating income, the hunter entering ATTACK, player door HP falling, hunter HP falling, and a natural player defeat with statistics and restart/menu controls.
- Final revision repeated room entry/claim/sleep and turret purchase after layout corrections.

## Issues found and fixed by production owner

1. Handbook final line overlapped Back: moved Back to y750; final screenshot confirms separation.
2. Beds overlapped build tiles: shifted/compressed grid horizontally; final screenshot confirms beds occupy a separate strip.
3. Sidebar tile details overlapped upgrade controls: reduced/reorganized details; final screenshot confirms separation.
4. Bed/door prices were only available in a tooltip: added current prices to visible action labels.
5. Result statistics appeared directly over map labels: added a dark full-screen veil.

## Presentation assessment

- All six rooms and their corridor fit a fixed overview camera. The player's room has a cyan outline, bots have strategy labels, and vacant rooms are explicit.
- Beds are cyan rectangles, doors have a separate frame and HP bar, floor slots have numbers, turrets have barrel shapes, generators use E symbols, and the hunter has an original pointed red silhouette and state label.
- Gold, electricity, bed income, door HP, hunter HP/level, countdown, and current tile appear as text. Resource costs are readable at the tested size.
- Combat uses tracers, flashes, health bars and state labels. This is coherent original placeholder art, not final commercial horror artwork.
- Purchase rejection gives a generic combined explanation; a future improvement is precise per-button failure reasons and disabled affordability states.
- Screen scaling uses Godot canvas_items stretching, but mobile touch controls, narrow aspect ratios, controller support, and Windows hardware rendering have not been visually validated.

## Evidence

Actual PNG frames in `docs/evidence/`: `menu.png`, `how-to.png`, `settings.png`, `match-sleeping.png`, plus final combat/result captures described below. Files containing `first` document the initial audit before fixes and should not be mistaken for the final layout.

Final retained frame notes:

- `menu.png`: final real menu frame, visually inspected after OpenGL initialization.
- `how-to.png`: final handbook with Back separated from final text.
- `settings.png`: real settings screen from first pass; controls remain unchanged except slider increment configuration.
- `match-sleeping.png`: final grid, sleeping state, 2 gold/s, visible bed/door upgrade prices, and clear empty-tile details.
- `match-final.png`: final gameplay at 37 seconds with hunter active at 756/900 HP and attacking a bot door. This frame exposed a remaining extra line when an occupied tile was selected; production owner subsequently collapsed that description into one line. That tiny final text change was code-reviewed but is not depicted in this retained frame.
- `match-result-first.png`: actual natural defeat at 45 seconds before the result veil correction. The later veil correction was code-reviewed, not recaptured as a natural result in this audit.

No claim is made that Windows rendering, audio playback, narrow-screen layout, or the final result veil has been graphically verified.
