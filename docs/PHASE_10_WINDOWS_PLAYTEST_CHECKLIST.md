# Phase 10 — Windows playtest checklist

Status: native Windows and human sound/comfort verification NOT PERFORMED here.
Use Godot 4.6.3 and the `work` branch ZIP after the verified push. Open existing
`project.godot`, wait for imports, then F6/F5 as appropriate (F5 starts the game).
Back up your usual profile before testing; do not replace it with prepared evidence
profiles. The evidence checkpoint contains a disclosed prepared wallet, not earned
campaign progress. All ordinary saves/inventory retain their existing paths.

## Soundtrack

- Open Settings → Soundtrack · playlist preferences. Default Dynamic Shuffle.
- Start/quit/reopen several times. Alternate opening scores and varied menu themes
  should be audible; Music/Effects/Ambient sliders and saved mute still apply.
- Choose Manual Track, pick an ordinary score, quit/reopen, and verify the choice.
- Listening Room is an audition only; leaving it restores the active preference.
- Try Classic and Off. Off silences music while warnings/attacks still use Effects.
- During ordinary Endless preparation hear quieter music, approaching Hunter hear
  tension, dangerous siege hear combat, Reaper/Crimson hear their dedicated scores.
- Pause/resume and return to menu after defeat. Listen for duplicate streams,
  unintended silence, obvious loop seams, harsh clipping or warning masking.
- Judge musical enjoyment/scariness with headphones at normal saved volume.

## Construction and range

- In Endless, B opens the existing palette. Select a weapon and move the cursor.
  Its ring must follow the real preview, scale with camera zoom and match the
  inspector's range. Red indicates invalid placement or temporary weapon lock;
  being inside the ring still requires an eligible target.
- Place normally, select/upgrade/specialize it, inspect updated range. O toggles.
- In Campaign/Practice, selecting a fixed-pad weapon also supports O/range.
- Select a Dynamo/repair/support: read ROOM-WIDE effects; no invented weapon circle.
- In preparation/intermission, Move [V], commit, then Undo move [Z]. Check original
  position/identity/level/cooldown and unchanged resources. Undo is single-use.
- Try rapid move/undo, cancel by Esc/right click, invalid overlaps, pause, combat,
  upgrade, sale and a new wave. Unsafe old moves must not become undoable later.
- Fill 16 positions through legitimate play. Select each core, move/undo, upgrade,
  sell and reuse the free floor. No duplicate charges or refunds.

## Wave reports and atmosphere

- Finish a real Endless wave → Wave report. Check actual damage and successful
  impacts, door damage, repair, gross Gold/Electricity generation and support.
- A distant turret that never hits should not gain theoretical DPS damage credit.
  Dynamo produces Electricity, not damage. Sales/aid/Omen payouts are not generation.
- Save/quit/resume an intermission; the report must survive. Older checkpoints
  should say telemetry is unavailable; next wave should collect a fresh report.
- Confirm Reinforce/Salvage/Recharge and accept/decline Omens remain available.
- Compare repeated nights; fog/moonlight/weather should vary without moving actors
  or altering combat outcomes. Try Low/Medium/High, Reduced Motion and Flashes.
- Check 1280×720 and 1920×1080. Door HP, Team and build controls must remain clickable.
- Play Normal Campaign, Long Night, Hell, Endless and Reaper encounters; check
  inventory/rank/shop/pity/cosmetics still work, then test normal checkpoint Continue.
- Run an extended session on your Windows hardware and report frame pacing/audio
  accumulation. The supplied Linux short samples cannot establish Windows performance.
