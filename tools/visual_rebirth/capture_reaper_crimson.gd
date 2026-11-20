extends "res://tools/capture_visual_rebirth.gd"
## Capture the existing low-health Crimson Execution trigger and scythe flight.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 var frames := destination.path_join("frames")
 DirAccess.make_dir_recursive_absolute(frames)
 root.size = Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()

 var model = _fresh_room(3)
 var h = model.hunter
 var room = model.player()
 h.boss_policy = BossCatalog.encounter("stage_5", "hell")
 h.target = room.index
 h.state = HunterState.State.ATTACK
 h.position = room.door_approach()
 model.running = true
 model.time = model.preparation + float(h.boss_policy.deadline)
 h.tick(STEP, model)
 check(h.state == HunterState.State.TRANSFORM, "existing deadline starts Reaper awakening")
 for frame in range(60):
  if h.state != HunterState.State.TRANSFORM:
   break
  model.time += STEP
  h.tick(STEP, model)
 check(h.transformed and h.state != HunterState.State.TRANSFORM, "normal Hunter tick completes transformation")
 h.state = HunterState.State.ATTACK
 h.position = room.door_approach()
 h.hp = h.max_hp * .09
 h.arcane.cooldown = 999.0
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.update(STEP, model)
 game.presentation.identity.heading = Vector2.DOWN
 var events := {}
 var pose_seen := {}
 var frame_count := 0
 var preview = game.presentation.boss_presentation
 var audio = game.audio_system
 var audio_seen := {}
 for frame in range(128):
  model.time += STEP
  model.wrath.tick(STEP, model)
  h.tick(STEP, model)
  game.presentation.update(STEP, model)
  audio.update_state(STEP, model, game.mode)
  game.ui.update_match()
  await _render_frame()
  var viewport := root.get_texture().get_image()
  if viewport.get_size() != Vector2i(1280,720) or viewport.save_png(frames.path_join("%04d.png" % frame)) != OK:
   check(false, "save rendered Crimson sequence")
   break
  frame_count += 1
  for event in model.presentation_events:
   if event.type in ["boss_ability_warning","boss_ability_activate"] and event.get("ability","") != "crimson_execution":
    continue
   if event.type in ["boss_ability_warning","boss_ability_activate","scythe_throw","scythe_embed"] and not events.has(event.type):
    events[event.type] = frame
  if not pose_seen.has(preview.preview_pose_name):
   pose_seen[preview.preview_pose_name] = frame
  for cue in ["wrath_warning_crimson_execution","wrath_activate_crimson_execution","scythe_throw","scythe_embed"]:
   if audio.event_counts.get(cue,0) > 0 and not audio_seen.has(cue):
    audio_seen[cue] = frame
  if events.has("scythe_embed") and frame > int(events.scythe_embed) + 18:
   break
 check(events.size() == 4 and model.wrath.domain_active(), "actual warning, release, throw and embed events inside Crimson Domain")
 check(pose_seen.has("tell") and pose_seen.has("release"), "preview drew timed warning and release poses")
 check(audio_seen.has("scythe_throw") and audio_seen.has("scythe_embed"), "real audio director consumed throw and embed")
 var receipt := FileAccess.open(destination.path_join("crimson-motion.json"), FileAccess.WRITE)
 check(receipt != null, "write evidence receipt")
 if receipt != null:
  receipt.store_string(JSON.stringify({
   "fixture":"Seeded Endless room, existing boss deadline, then set transformed HP to 9% to exercise the real low-health trigger. Advance the Hunter and Wrath ticks at 24 Hz.",
   "frame_count":frame_count, "events":events, "poses":pose_seen, "audio_cues":audio_seen,
   "viewport":[1280,720], "fps":24,
  },"  ") + "\n")
 print("CRIMSON_EVIDENCE_FRAMES=",frame_count," EVENTS=",events," AUDIO=",audio_seen)
 await _finish()
