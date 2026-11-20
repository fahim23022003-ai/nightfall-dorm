# Gameplay and fallback regression checks

Nine current headless suites passed 6,111 assertions. The V1 runtime
test opted into V1. The audio and contact suites toggle their own
Living Nightmare flag. The other launchers use the legacy renderer
configuration for these compatibility checks.

| Suite | Assertions | Failures |
| --- | ---: | ---: |
| Hunter damage provenance and visual contacts | 62 | 0 |
| Living Nightmare soundtrack and heartbeat | 67 | 0 |
| Off-screen visual culling | 1116 | 0 |
| Adaptive readability | 19 | 0 |
| Hunter combat and mechanics | 75 | 0 |
| Boss, Crimson and existing rules | 153 | 0 |
| V1 maps, alternate routes and Haunted Hall | 495 | 0 |
| V2 persistence | 62 | 0 |
| Phase 6 inputs and performance predicates | 4062 | 0 |

The supplementary `gameplay_visual_polish` fixture still reports six
fixed economy or exact typed-damage expectations. A clean archive of
`da4ef63` produced the same log byte for byte. Both outputs are
included as an inherited failure, separate from the nine passing
suites.

[Run exit statuses](exit-status.txt) ·
[Previous checkpoint control](gameplay_visual_polish-da4ef63.log) ·
[Current supplementary output](gameplay_visual_polish.log)
