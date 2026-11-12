# Phase 4A difficulty communication render audit

Agent D used actual Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg dummy
screen. Final `tools/capture_difficulty.gd` run: **23 checks, 0 failures, exit0;
eight PNG saves returned OK**. `render.log` records the actual policy and UI
measurements. No Android or export tools were used.

These are prepared interaction/combat fixtures, not naturally played wins or
proof of difficulty balance. A new isolated campaign profile selects Hell using
a real button, launches Stage1, claims/sleeps through production APIs, receives
resources and a level5 door for visual inspection. Time is placed80 seconds after
preparation. Actual hunter ticks perform the preceding two ordinary attacks,
then start the genuine third-attack charge. The siege timer is set to its ramp
endpoint for inspection. The result is explicitly forced to test retry UI.

Inspected final frames:

- `01-hell-risk-preparation.png` / `02-hell-risk-preparation-960x540.png`: all
  three difficulties, Hell's red expert-risk hint, stage identity/environment,
  existing perk controls and Start Match remain legible and separate. The actual
  Hell button persists difficulty without changing selected Stage1.
- `03-heavy-windup-and-threat-hud.png` / `03b-heavy-windup-960x540.png`: genuine
  charge event, explicit0.9s Heavy Strike warning, damage/interval/WINDUP detail.
  The charge itself does not hit. A subsequent tick below the delay cannot deal
  damage; a tick crossing the delay does. The actual HP bar is286×8 at(704,46),
  with detail starting at(704,58); no overlapping rectangles.
- `04-charged-impact-repair-pressure.png`: actual charged impact, rising damage
  number and sustained REPAIRS40% warning. The warning's rendered text width is
  327px inside its476px label, avoiding the earlier overflow.
- `05-repair-pressure-960x540.png`: real paid repair during the siege restores
  28HP (70×40%); the pressure warning and controls remain clear.
- `06-hell-defeat-retry-960x540.png` / `07-hell-retry-preserved-960x540.png`:
  eligible defeat result remains readable. Actual Retry Stage preserves Hell
  and Stage1 in the new match.

Three confirmed issues were reported and fixed by main development: same-target
reassessment reset the sustained siege factor; the longer pressure warning left
its panel; and HP-bar initialization retained a cached27px height overlapping
new threat detail. Final assertions and captures verify a persistent40% factor,
short fitted warning text, and an actual8px bar after deferred sizing. Merely
requesting8px or changing its font initially did not shrink the existing height;
final evidence measures the resulting control, not its requested size.

Final captured Hell policy:45s opening,25s growth interval, charged third strike
at1.9×,0.9s windup,40% repair floor over12s. The full policy dictionary is in the
log. These numbers describe this captured build, not every future balance change.
Alert slide-in is settled through presentation-only updates without advancing
combat. No new audio recording or personal audible-quality verdict is claimed.
Native Windows execution, target hardware FPS and human difficulty remain
UNVERIFIED. Unsupported VSync-setting warning is expected on llvmpipe; final
log has no script/parse/error signatures. Only the audit's Xorg display was stopped.
