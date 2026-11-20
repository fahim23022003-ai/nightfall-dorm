# Survivor Rebirth tutorial verification

Both walkthroughs are continuous 1280×720 Linux Godot 4.6.3 screen recordings at 24 fps. The test issues keyboard and mouse events against the running game and uses a new disposable profile on every pass. The videos contain the picture track.

| Route | Result | Capture | Evidence |
|---|---:|---|---|
| Continue Story | 88 checks passed | [54-second walkthrough](continue-story.mp4) | [Transactions](continue-story.json), [test log](continue-story.log) |
| Replay Tutorial with the Windows preview launcher flags | 91 checks passed | [56-second walkthrough](replay.mp4) | [Transactions](replay.json), [test log](replay.log) |

Both routes traverse all 19 lessons. They verify legal room claim and bed income, rejected doorway placement, a 20 Gold Needle Turret, explicit cancellation of the still-active tool, a 120 Gold Dynamo, a Needle upgrade funded by 40 Gold and 8 Electricity earned from the Dynamo, a real paid door repair, and actual Hunter attacks and Needle shots. The replay route also checks that right-click, reopening Build, and switching machine panels cannot acknowledge explicit cancellation or closure. Completing either route persists the tutorial completion flag. Practice leaves the XP, RM Cash, inventory, pending spins, and active-match ledger unchanged.

With the Survivor Rebirth and Living Nightmare flags off, the prior onboarding passed 99 flow checks, 164 profile checks, and 57,016 economy checks across 42 scenarios. [Flow](fallback-onboarding_flow.log) · [Profile](fallback-onboarding_qa.log) · [Economy](fallback-onboarding_economy.log)
