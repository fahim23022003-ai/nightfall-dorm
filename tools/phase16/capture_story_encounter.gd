extends "res://tools/capture_living_story.gd"
## Compose a short fixture immediately before a real Story combat event.

const FRAME_STEP := 1.0 / 24.0

func run() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or not int(args[1]) in [4, 29, 36]:
  push_error("Pass an absolute output directory and level 4, 29 or 36 after --.")
  quit(2)
  return
 directory = args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 if DisplayServer.get_name() == "headless":
  push_error("This capture requires a desktop renderer.")
  quit(2)
  return
 var level := int(args[1])
 root.size = Vector2i(1280, 720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH", "user://phase16-encounter-%d.json" % OS.get_process_id())
 preload("res://tests/onboarding_test_support.gd").prepare()
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game)
 game.onboarding.set_process(false)
 verify(stage_track(level - 1) and game.start_story("standard"), "Start the authored Story encounter")
 var model: MatchModel = game.model
 var room: RoomState = model.rooms[0]
 model.player_position = room.door_position() - room.door_normal() * 35.0
 game.interact_survivor()
 verify(model.player_room == 0, "Claim room from the real doorway")
 model.player_position = room.bed_position()
 game.interact_survivor()
 verify(room.sleeping, "Interact with the real bed")

 # Position the camera and stage the event's prerequisites outside the recording.
 # From here, production logic advances at normal speed and emits the events.
 model.bot_claimed = 5
 var hunter := model.hunter
 hunter.target = room.index
 hunter.position = room.door_approach()
 hunter.state = HunterState.State.ATTACK
 hunter.cooldown = 60.0
 match level:
  4:
   model.time = model.preparation
   for tick: int in range(220):
    model.tick(0.05)
  29:
   model.time = model.preparation + 29.95
   hunter.position = model.map_data.halls.west.entrance
   hunter.state = HunterState.State.MOVE
   hunter.hp = hunter.max_hp * 0.40
  36:
   model.time = model.preparation + float(hunter.boss_policy.deadline) - 1.0
   hunter.state = HunterState.State.SEEK
 game.focus_camera(true)

 var watched := false
 var event_times := {}
 var required: Array = {
  4: ["nightmare_warning", "nightmare_impact"],
  29: ["hunter_retreat", "hunter_recovering", "hunter_recovery_ended"],
  36: ["boss_transform", "boss_awakened"],
 }[level]
 for frame: int in range(264 if level == 29 else 156):
  game._process(FRAME_STEP)
  for event: Dictionary in model.presentation_events:
   if required.has(event.type) and not event_times.has(event.type) and (level != 4 or event.get("skill") == "cage"):
    event_times[event.type] = event.time
  if level == 29 and not watched and frame >= 24:
   watched = game.watch_hunter()
  await RenderingServer.frame_post_draw
  if frame == (72 if level == 29 else 42):
   verify(root.get_texture().get_image().save_png(directory.path_join("encounter-720.png")) == OK, "Save real encounter frame")
 for event_type: String in required:
  verify(event_times.has(event_type), "Production event rendered: " + event_type)
 if level == 29:
  verify(watched and model.haunt_recovery.visits == 1, "Watch the real Hunter finish a Hall visit")
 print("PHASE16_STORY_FILM ", level, " events=", event_times, " failures=", failures)
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 quit(int(failures > 0))
