# Phase 3A campaign render and navigation audit

Agent D ran actual Linux Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg dummy
display using `tools/capture_campaign.gd`. Final run: **57 checks, 0 failures,
exit 0**; all 19 PNG saves returned OK. `render.log` contains the exact outputs.
No Android or export tooling was used.

These are prepared fixtures. Bronze initial state is a new isolated profile.
Master XP is injected solely to inspect every unlocked perk's presentation.
Victories/defeat are forced eligible result fixtures: claim/sleep through actual
model APIs, set elapsed/occupied time, then enter the production game result and
profile settlement path. They are not naturally completed campaign matches.

Inspected final rendered states:

- `01-new-campaign-locked.png`: Stage1 unlocked, Stages2–5 locked; clicking a
  disabled Locked button leaves stage select unchanged.
- `02-stage1-bronze-preparation.png`: only eligible Bronze options enabled.
- `03-preparation-*.png`: all six valid single-perk choices shown separately,
  alternating Night watch / Long night. No text/button overlap or truncation.
  There is one equipped slot, not support for equipping all perks together.
- `04-stage1-victory-next.png`, `05-stage2-preparation.png`: stage identity,
  first-clear XP and Next Stage. Actual mouse Next Stage opens Stage2 preparation.
- `06-stage2-defeat-retry.png`: failed-stage result, no clear reward. Actual
  Retry Stage restarts Stage2.
- `07-cleared-best-record.png`, `08-stage-select-960x540.png`: cleared marker,
  retained best70.0s time, unlocked Stage2 and later locks, at both viewport sizes.
- `09-hard-preparation-960x540.png`: actual Long night button updates independent
  persistent difficulty; Last light description and all bottom actions fit.
- `10-campaign-complete-960x540.png`, `11-all-stages-cleared-960x540.png`:
  Stage5 completion, Campaign complete, all five best records; actual result
  Stage Select button returns to stage select.
- `12-hard-xp-cap-result.png`: Long night replay at lifetime XP cap, already
  claimed stage reward, cap adjustment and rank line. Agent D found an earlier
  four-line reward/cap overlap; main developer condensed this to three lines.
  Final capture confirms the cap line and Master100000000XP are separate.
- `13-save-failed-result-960x540.png`: actual profile write failure induced by
  temporarily using a missing parent directory. Save failed—retry and Main menu
  have separate visible buttons and tested nonintersecting hitboxes.
- `14-save-retry-recovered-960x540.png`: restore valid path, click actual Retry;
  save succeeds and the failure button disappears without navigating away.

All final inspected labels, stage subtitles, buttons and reward summaries fit
at 1280×720 and 960×540 viewports. The latter is the actual aspect-preserving
viewport inside a requested 960×600 physical window. No remaining layout defect
was found in these fixtures. Native Windows behavior, subjective audio quality,
and naturally played campaign balance remain outside this rendered audit.
The renderer's unsupported VSync-setting warning is expected under llvmpipe;
there were no script/parse/error signatures. Only this audit's Xorg display was
stopped afterward.
