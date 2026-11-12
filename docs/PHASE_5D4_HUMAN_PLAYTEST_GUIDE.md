# The Reaper’s Wrath — owner and Adie playtest guide

This is a private Windows playtest, not a published release. Linux engine tests
cannot establish Windows hardware performance, physical input behavior, musical
impact or whether the interface feels clear to a new player.

## Start with the correct version

Use the Phase 5D-4 Windows x64 ZIP when its build receipt is available. Extract
all files and launch `NightfallDorm.exe`; keep `VERSION.txt` to identify the exact
source commit. A GitHub **work** branch source ZIP contains the Godot project,
not a prebuilt executable. Open `project.godot` with the documented compatible
Godot 4.6.3 if using that source ZIP. Do not download an older/default branch by
accident. No public release or main-branch merge is part of this work.

Ordinary play preserves existing progression. For isolated experiments, open a
Command Prompt in the extracted folder and run:

```bat
set NIGHTFALL_PROFILE_PATH=user://phase5d4-owner-playtest.json
NightfallDorm.exe
```

Use a different filename for Adie. This keeps the normal profile separate. Do
not manually copy test save data into your normal profile. Practice Room uses
temporary stock/resources and grants no permanent progression.

## First five minutes: controls and building workflow

1. Enter Practice Room, choose an archetype, claim a room and sleep as prompted.
2. Identify Gold, Electricity, time, survivors and the Hunter at the top.
3. Click an empty numbered floor pad. All available buildings appear in the same
   bottom panel. Hover a disabled BUILD card to read its actual requirement.
4. Click BUILD once. Try a rapid double-click: one building and one payment should
   result, with no following-mouse placement or accidental extra upgrade.
5. Select the building. Read its current level, actual current/next stats and
   literal upgrade price. Upgrade in that same panel.
6. At the branch choice, selecting a card is a free preview. Compare its numerical
   effect and tooltip, then Confirm the exclusive choice. Back cancels the preview.
7. Try holding a button, pressing Escape, then releasing. A cancelled action must
   not purchase or upgrade. Repeat after reopening the panel.
8. Sell a machine. The quote returns 50% of actual Gold and Electricity invested,
   including discounted upgrades. Upkeep is not refundable. The pad is reusable.
9. Open Items [I], Help [G] and the collapsible Team panel [T]. Spectate a teammate
   and return to your room. Your character and ownership must stay unchanged.

Repeat the core flow at 1280×720 and 1920×1080. Human acceptance matters: record
any label that you had to guess, even if the action technically worked.

## Compare specializations and the six new buildings

The two branches are exclusive, and upgrades stop at Level10. Try each branch in
separate Practice resets so you can compare actual combat and resource use.

| Building | What to observe |
| --- | --- |
| Flame Turret | Burning damage over time; concentrated burn versus weaker multi-target coverage. Burns do not stack without a bound. |
| Frost Tower | Actual movement/attack slowing, stronger on one target or weaker over several; Reaper resistance prevents permanent control. |
| Shock Trap | A permanent ranged electrical machine with periodic charged attacks; stronger bursts versus faster weaker recovery. |
| Auto Repair Station | Paid door-repair bursts with a useful late-siege role; watch both Gold and Electricity. Emergency repairs wait for low HP. |
| Shield Generator | Finite absorption and duration, paid Electricity and a shared room cooldown. It cannot make a door permanently invulnerable. |
| Decoy Beacon | A bounded legal-path diversion, with short strong or longer weaker lure behavior. Selling it ends its active lure. |

Needle and Arc remain valid alternatives. Compare range, cost and actual damage,
not just level or visual effects. Bed, Door, Dynamo and existing support branches
retain their prior roles. Inspect their current/next values and branch drawbacks.

## Hunter and Hell Mode comparison

Use the same map, archetype and difficulty for both players. Compare:

- Bed/door upgrades and repairs, but no offensive player buildings.
- An active strategy with thoughtfully placed offensive defenses.
- A mixed build using one or two new support/control roles.

Watch who deals damage and whether allies win before you participate. NPCs should
help without reliably carrying a passive Hell player. A few wins or losses are
not a statistical win-rate estimate. Report the actual strategy and moment the
run became easy or impossible.

Each unique genuine Hunter/undead survivor kill grants one eligible bounded buff.
Read the queued evolution announcement and inspect the Hunter’s acquired-buff
information. It must name the actual effect. Duplicate death notifications must
not award another buff. New independent runs reset the ledger; Endless checkpoints
preserve it together with survivor state.

## Find and test the Reaper encounter

Campaign eligibility is **Normal stages3–5** and **Long Night/Hell stages2–5**.
Introductory ineligible stages do not promise a Reaper. Eligible encounters allow
the HP transition after eight active Hunter seconds: below55% HP, or the existing
210-active-second deadline. Endless has its defined milestone waves. Practice
provides controlled boss training without risking permanent inventory.

The same enemy transforms without a health refill. The short transformation and
phase guards are finite. PhaseII awakens at35% HP. At10%, a single combined
**Eternal Sacrifices / Crimson Execution** event selects a valid human or AI room.
The scythe flies to and embeds in that room; a roughly30-second Crimson Domain
creates real pressure. The Hunter travels legally to it—there is no teleport.
Other rooms cannot shoot the domain boss; existing undead are cleared so it is
one boss against the selected room. Observe from that room or use spectating.

Check the warning, target and countdown before these attacks:

- Ordinary undead and the major assault of up to10 attackable zombies.
- Limited Soul Steal, and PhaseII Soul Reaper taking half the current wallet only
  after its interruptible channel completes.
- Contact Scythe Slash, temporary Rules Judgement and PhaseII Phantom Scream.
- Temporary Final Judgement production suppression, with stored resources intact.
- The embedded scythe’s bounded damage/destruction pressure. Use applicable
  shields or Reaper Seal; Level10 machines are not automatically immune.

Try real defensive decisions. The domain must permit a win or survival, not a
scripted execution. Check cleanup on timeout, boss death and target death. Locks,
scythe visuals, music and camera controls must recover. Report any attack whose
warning is hidden, too small or impossible to respond to.

## Audio listening and active combat

Settings → Audio listening room provides **Music**, **Voices** and **Action SFX**
tabs. The seven previous scores remain, with a new Crimson climax. Listen at your
usual saved volume, then compare Music-muted combat to identify the effects.

Listen for distinct Needle/Arc/Flame/Frost/Shock fire, actual impacts, bed/door
upgrades, branch confirmation, shield/repair/decoy activations, death/evolution,
zombie spawning/attacks/deaths and boss warnings. During dense combat, crucial
warnings should remain recognizable without exhausting gunfire overlap. Try low
Effects volume and mute, leave the scene, and return: preferences should persist
and old effects should not continue playing. Test Reduced Effects separately.

Please judge the sound directly: frightening, satisfying, weak, harsh, repetitive
or unclear. Signal measurements do not substitute for your ears.

## Longer play and preservation

Resume a real between-wave Endless checkpoint. Check buildings, branches, exact
wallets, stock and previously claimed rewards. Compare a freshly generated
Challenge Code with Adie on the same version; conditions are normalized, but
manual results are self-reported, not an online verified leaderboard. Older
ruleset codes are archival and are rejected for new play rather than silently
changing their conditions.

Check campaign rewards, RM Cash/shop, spins/pity, cosmetics, achievements, the
cinematic, first-time tutorial and all20 consumables. During a long Endless run,
watch for growing frame times, persistent sounds, undead left after a wave,
invisible curses or camera problems. Record Windows hardware and resolution.

## Send a useful finding

Include `VERSION.txt` commit, map, difficulty, stage/wave, archetype, building
levels/branches, equipped unused items and what you clicked. Add a screenshot or
short recording if possible. State expected and observed behavior, and whether
it happens consistently. Human feedback can reject a confusing or unsatisfying
experience even when automated checks pass.
