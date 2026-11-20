extends "res://tools/capture_visual_rebirth.gd"
## The normal Hunter tick reaches the existing deadline, awakening and boss strike.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir()+"/"
 phase = destination.get_file()
 var frames := destination.path_join("frames")
 DirAccess.make_dir_recursive_absolute(frames)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()

 var model = _fresh_room(3)
 var hunter = model.hunter
 var room = model.player()
 hunter.boss_policy = BossCatalog.encounter("stage_5", "hell")
 check(hunter.boss_policy.get("enabled", false), "configured an existing enabled boss encounter")
 room.door_level = 5
 room.door_hp = room.max_hp()
 var door: Vector2 = room.door_approach()
 hunter.state = HunterState.State.MOVE
 hunter.position = door+Vector2(0,-65)
 hunter.target = room.index
 hunter.cooldown = 1.0
 hunter.nightmare.cooldown = 999
 hunter.arcane.cooldown = 999
 hunter.tactical_cooldown = 999
 model.time = model.preparation+float(hunter.boss_policy.deadline)-1.1
 model.running=true
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.reset()
 game.presentation.nightmare_visual.reset()
 game.presentation.update(STEP,model)
 check(model._visible(hunter.position, door), "approach route to selected door is walkable")

 var count := 0
 var poses := {}
 var textures := {}
 var presentation = game.presentation.boss_presentation
 var before_door: float = room.door_hp
 var hp_before_transform := -1.0
 var hp_at_transform := -1.0
 var events := {}
 for frame in range(212):
  model.time += STEP
  var hp_before_tick: float = hunter.hp
  hunter.tick(STEP, model)
  game.presentation.update(STEP, model)
  game.ui.update_match()
  await _render_frame()
  var viewport := root.get_texture().get_image()
  if viewport.get_size()!=Vector2i(1280,720) or viewport.save_png(frames.path_join("%04d.png" % frame))!=OK:
   check(false, "save native Reaper motion frame")
   break
  count += 1
  var expected := "transformed" if hunter.transformed else "approach"
  var selected: String = presentation.preview_texture_path
  if selected.get_file().begins_with(expected):
   textures[selected] = true
  poses[presentation.preview_pose_name] = true
  for event in model.presentation_events:
   if event.type in ["boss_transform","boss_awakened","boss_warning","boss_impact"] and not events.has(event.type):
    events[event.type]=frame
    if event.type=="boss_transform":
     hp_before_transform=hp_before_tick
     hp_at_transform=hunter.hp
  if events.has("boss_impact") and frame>int(events["boss_impact"])+16:
   break

 var forms := {}
 for path in textures:
  forms["approach" if path.get_file().begins_with("approach") else "transformed"] = true
 check(forms.size() == 2, "both exact boss forms reached production draw")
 check(poses.has("evolve") and poses.has("tell") and poses.has("release"), "actual boss pose sequence reached production draw")
 check(events.size()==4, "actual transformation, awakening, boss warning, and boss impact occurred")
 check(hp_at_transform>0 and hp_at_transform<=hp_before_transform, "existing transformation did not grant HP")
 check(room.door_hp<before_door and hunter.last_boss_attack!="", "actual selected boss attack damaged the door")
 var metadata := FileAccess.open(destination.path_join("reaper-motion.json"),FileAccess.WRITE)
 check(metadata!=null, "Reaper recording metadata writable")
 if metadata!=null:
  metadata.store_string(JSON.stringify({
   "fps":24, "viewport":[1280,720], "frame_count":count,
   "fixture":"Prepared seeded Endless room, using the game's enabled Stage 5 Hell encounter policy. Set time just before the existing transformation deadline. Advance HunterState.tick directly at 24 Hz, not a full world tick.",
   "events":events, "last_boss_attack":hunter.last_boss_attack,
   "poses":poses.keys(), "textures":textures.keys(),
   "door_damage":before_door-room.door_hp,
   "hunter_hp_before_transform":hp_before_transform, "hunter_hp_at_transform":hp_at_transform,
  },"  ")+"\n")
 print("REAPER_MOTION_FRAMES=",count," EVENTS=",events)
 await _finish()
