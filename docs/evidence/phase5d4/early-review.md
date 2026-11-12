# Phase 5D-4 early UX and action-audio gate

This is an **early integration review**, before the new boss mechanics and six additional buildings. It does not certify the full phase. Agent D made capture tools/evidence only, with no production edits or Git actions.

## TESTED: actual rendered input

**301 checks / 0 failures** in the full UI run, followed by **209 / 0** in the affected final clarity run; both exit 0. There are **118 current fresh UI PNGs** at 1280×720 and 1920×1080, bound to exact working-source hashes in `early-render-manifest.json` and the source snapshots it identifies. All five maps, all eight existing permanent building types (Bed, Door, Needle, Arc, Dynamo, Repair Station, Dream Amplifier and Target Relay), expanded/compact items, guide, teammates, purchase, upgrade, branch selection and confirmation were rendered. All current PNGs were reviewed in contact sheets, with full-size HUD, inspector, build/disabled tooltips, Needle branch/tooltip, Door 1080p branch and rotated lab-map HUD checks.

Actual mouse/keyboard input verified direct BUILD and separate exclusive-branch confirmation. Selection alone did not spend Gold/Electricity or consume RNG; confirmation performed the actual paid upgrade. The fixed bottom region stayed stable, with **0.0 measured camera, zoom and player-position change** on tested panel transitions, including all five maps and every existing role's branch panel. Current and next stats, level and selected branch are readable. Full branch mechanics/tradeoffs remain in hover descriptions; the main cards show numerical comparison and cost. Disabled Arc purchase shows its real resource shortfall on hover.

Compared with the baseline, the permanent HUD is less dense: consumables default to compact controls, details are available through Items [I], help can be toggled, the team list collapses, and the build/upgrade/branch controls share one bottom location. This is observed behavior and layout evidence, not a claim of human usability approval.

### Failures found and rerun

* Initial actual render: **255 checks / 14 failures**. Seven of eight branch roles at both resolutions had text minimum heights of 93–110px in 86px cards, covering prices and Back/Confirm. Retained under `early-render-before-overlap-fix/`. The developer increased/fixed the bottom region, shortened the visible comparisons, retained full tooltips, and separated the controls; rerun passed.
* Root additionally detected a 3px close/card intersection. The final +6px card offset was checked in actual fresh frames against close, Back, Confirm and Godot minimum text sizes for all roles and resolutions. Thirty-two superseded choice/selection frames remain in `early-render-before-close-clearance/`; their final replacements and 18 new tooltip/disabled frames use the later source snapshot.
* Missing level/selected branch names and stale desktop preview-confirm help were reported during this gate and corrected by the developer. The current inspector and direct-BUILD descriptions are present in the accepted evidence.

The only accepted-render log warning is unsupported V-Sync switching on the dummy Xorg driver. No accepted-run script/parse errors or object-leak warnings were recorded.

## TESTED: actual engine output

**76 checks / 0 failures, exit 0**. Actual Linux Godot engine Master PCM was recorded with default Music 0.5 / Effects 0.65 / Ambient 0.5, then with only Music set to zero. Needle and Arc used actual model launches, traveling projectile impacts and Hunter damage; attacks/tactics were delayed at a legal door to isolate weapon playback. Purchases/upgrades used actual mouse input while the combat model was held between transactions. Practice inventory was temporary; permanent profile bytes stayed unchanged.

| Case | Actual events per mix | Default Master RMS / peak | Music-muted Master RMS / peak |
| --- | --- | --- | --- |
| Needle | 12 shots, 12 impacts, 432 damage | 0.012899 / 0.062073 | 0.006149 / 0.032715 |
| Arc | 6 shots, 6 impacts, 168 damage | 0.012031 / 0.069580 | 0.004065 / 0.032532 |
| Build / upgrade / confirmed branch | Build 1, upgrade 1, turret-upgrade 1; purchase 3, confirm 1 | 0.018043 / 0.070282 | 0.003244 / 0.025970 |

The recorded action signal is measurable in actual output and the real producer routes are active; this is more than file existence or a no-clipping check. All 18 PCM files have zero clipped samples. Individual Master/Effects/Music WAVs, exact duration/sample metrics, event counts, source hashes and a Master waveform plot are included in `early-audio/`, `early-audio-manifest.json` and `early-audio-pcm-metrics.json`. All captured source scripts and 204 WAV hashes were unchanged through this recording.

Effects/Music bus recordings precede their final faders/mute: the Music stem remains nonzero when Music is muted. **Use the Master recordings for output and mix comparisons.** This is expected recording placement, not a music-mute leak.

The initial audio harness clicked newly opened UI before its disabled/layout state had settled; Arc and transaction labels from that diagnostic are rejected, with **68 checks / 10 failures** retained under `early-audio-before-fixture-settle/`. Added frame/time settlement and explicit actual-sale, reusable-tile and context assertions produced the clean 76/0 rerun. No production defect is inferred from that fixture error.

## Integration follow-up

At this early gate, an actual confirmed Needle branch emitted the generic `turret_upgrade` plus `ui_confirm`; the dedicated new `branch_select` route did not fire because the building-upgrade producer lacked its specialization payload. Audio owner and primary developer were notified; the later production integration must supply the payload and receive a focused route/output check. This does not invalidate the existing real upgrade sound or branch mechanics, but the dedicated branch sound is **INCOMPLETE at this captured checkpoint**.

The audio owner is also independently hardening serialized death/evolution cues and stale pooled scream pointers. Those later changes are outside these recordings and require their own affected checks; the captured weapon/music assets and gains need no retuning based solely on this signal evidence.

## UNVERIFIED / outside this gate

Native Windows launch and controls, actual soundcard/headphone output, human judgments of audible clarity, loudness, satisfying gunfire or horror quality remain **UNVERIFIED**. RMS/waveforms do not establish subjective quality. The Dummy driver supplies the hardware sink; the recorded engine output is real.

Boss phases, minions, evolution, Crimson Domain, six new buildings, final mix under maximum combat density, long-run performance and final-phase regressions were not yet integrated for this review. They need the later independent final gate. Prior Phase 5D-3/baseline evidence was preserved.
