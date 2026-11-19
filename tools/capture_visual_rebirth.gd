extends "res://tools/capture_spatial_construction.gd"
## Matched Phase 14 viewport evidence using a prepared, isolated Endless fixture.

const SEED := 67
const STEP := 1.0 / 24.0
const VIDEO_FRAMES := 144
const WARMUP_FRAMES := 30
const TIMED_FRAMES := 240

func run():
 var args := OS.get_cmdline_user_args()
 if args.is_empty() or args.size() > 2 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory and optional stills flag after --")
  quit(2)
  return
 var stills_only := args.size() == 2 and args[1] == "stills"
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 if not stills_only:
  DirAccess.make_dir_recursive_absolute(destination.path_join("frames"))
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var visual_enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var dense = _dense_fixture()
 for index in range(8):
  game.presentation.update(.125, dense)
  await _render_frame()
 check(root.get_texture().get_size() == Vector2(1280, 720), "real viewport is 1280×720")
 await capture("full16-720")
 var stalker_preview = game.presentation.nightmare_visual.stalker_preview
 var building_visual = game.presentation.building_visual
 check(not stalker_preview.frames.is_empty() == visual_enabled, "Stalker draw path matches requested renderer")
 check(building_visual.needle_rebirth_active() == visual_enabled, "Needle draw path matches requested renderer")
 _capture_crops(dense, destination)
 var frame_times := {}
 if not stills_only:
  frame_times = await _measure(dense)

 root.size = Vector2i(1920, 1080)
 await _render_frame()
 await capture("full16-1080")
 check(root.get_texture().get_image().get_size() == Vector2i(1920, 1080), "real viewport is 1920×1080")
 if stills_only:
  await _finish()
  return

 root.size = Vector2i(1280, 720)
 var combat = _combat_fixture()
 var start_hp: float = combat.hunter.hp
 var start_door: float = combat.player().door_hp
 var seen_events := {}
 var event_counts := {"needle_launch": 0, "needle_impact": 0, "stalker_warning": 0, "stalker_door_damage": 0}
 var placed_at_door := false
 var audio = game.audio_system
 var breath_count: int = audio.event_counts.get(AudioDirector.STALKER_BREATH, 0)
 await _render_frame()
 pcm_start()
 for index in range(VIDEO_FRAMES):
  if index == 24 and combat.hunter.attacks == 0 and combat.hunter.state != HunterState.State.ATTACK:
   # Keep the short selected-room shot reproducible if the corridor approach retargets.
   combat.hunter.position = combat.player().door_approach()
   combat.hunter.target = combat.player_room
   combat.hunter.state = HunterState.State.ATTACK
   combat.hunter.cooldown = .5
   placed_at_door = true
  game._process(STEP)
  _count_events(combat, seen_events, event_counts)
  await _render_frame()
  var filename := destination.path_join("frames/%04d.png" % index)
  var save_code := root.get_texture().get_image().save_png(filename)
  if save_code != OK:
   check(false, "sequence PNG %d" % index)
   break
 pcm_finish("master-unsynced")
 var breaths: int = audio.event_counts.get(AudioDirector.STALKER_BREATH, 0) - breath_count
 check(breaths == int(visual_enabled), "Stalker proximity voice follows preview switch")
 check(combat.shots > 0 and event_counts.needle_launch > 0, "actual Needle launches in clip")
 check(combat.hunter.hp < start_hp and event_counts.needle_impact > 0, "actual Needle damage in clip")
 check(combat.hunter.attacks > 0 and combat.player().door_hp < start_door, "actual Stalker strike in clip")
 await capture("combat-last-720")

 var result := {
  "settings": {"baseline": OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "0", "seed": SEED, "quality": game.profile.settings.get("graphics_quality", "default"), "clip_fps": 24, "clip_frames": VIDEO_FRAMES},
  "frame_time": frame_times,
  "combat": {
   "shots": combat.shots,
   "hunter_attacks": combat.hunter.attacks,
   "hunter_hp": combat.hunter.hp,
   "door_hp": combat.player().door_hp,
   "gold": combat.player().gold,
   "electricity": combat.player().electricity,
   "sampled_state_sha256": _state_digest(combat)
  },
  "events": event_counts,
  "staging": {"placed_at_door_on_frame_24": placed_at_door},
  "presentation": {"stalker_mesh_frames": stalker_preview.frames.size(),
   "needle_atlas_bound": building_visual.needle_rebirth_active(), "stalker_breaths": breaths},
  "checks": checks,
  "failures": failures
 }
 var summary := FileAccess.open(destination.path_join("capture.json"), FileAccess.WRITE)
 if summary != null:
  summary.store_string(JSON.stringify(result, "  ") + "\n")
 else:
  check(false, "write capture metadata")
 await _finish()

func _finish():
 print("VISUAL_REBIRTH_RENDER_CHECKS=", checks, " FAILURES=", failures)
 game.audio_system.shutdown()
 game.queue_free()
 await create_timer(.4).timeout
 quit(1 if failures else 0)

func _dense_fixture():
 var model = _fresh_room(0)
 var room = model.player()
 for tier in range(7):
  check(model.expansion.purchase(model), "paid expansion %d" % (tier + 1))
 for kind in Catalog.BUILDINGS:
  check(model.place_building(kind, candidate(room)), "paid placement " + kind)
 check(model.place_building("turret", candidate(room)), "paid second Needle")
 check(room.tile_count() == 16 and room.buildings.size() == 16, "sixteen legal slots occupied")
 for id in room.buildings.keys().slice(1):
  for level in range(2, 11):
   var building: Dictionary = room.buildings[id]
   var succeeded: bool
   if building.level == 4:
    succeeded = model.specialize_building(id, StrategyCatalog.branches(building.kind)[0])
   else:
    succeeded = model.upgrade_building(id)
   check(succeeded, "paid upgrade %s L%d" % [building.kind, level])
 _pose_stalker(model)
 model.running = false
 game.presentation.identity.heading = Vector2.LEFT
 return model

func _fresh_room(index: int):
 game.new_balance_version = 1
 game.return_menu()
 check(game.start_endless("abandoned_dorm", "standard", SEED), "real legacy Endless session")
 game.set_process(false)
 game.tutorial_enabled = false
 var model = game.model
 check(model.claim_room(index), "claim fixture room")
 var room = model.player()
 model.player_position = room.bed_position()
 model.sleep_player()
 if index == 0:
  room.gold = 500000
  room.electricity = 500000
  model.bot_claimed = 5
  for other in model.rooms:
   if other.index != index:
    other.owner = other.index
    other.sleeping = true
    other.closed = true
    other.resident_position = other.bed_position()
    other.bot_timer = 10000
 else:
  room.gold = 500
 room.bed_level = 4
 room.door_level = 4
 room.door_hp = room.max_hp()
 game.audio_system.reset_match(model)
 return model

func _combat_fixture():
 var model = _fresh_room(3)
 var room = model.player()
 var point: Vector2 = room.door_approach()
 var at: Vector2 = candidate(room, true)
 var distance := INF
 var bounds: Rect2 = room.bounds().grow(-32)
 for y in range(int(bounds.position.y), int(bounds.end.y), 9):
  for x in range(int(bounds.position.x), int(bounds.end.x), 9):
   var possible := Vector2(x, y)
   var separation := possible.distance_squared_to(point)
   if separation < distance and room.spatial.geometry_reason(possible) == "":
    at = possible
    distance = separation
 check(model.place_building("turret", at), "legal paid Needle at door")
 _pose_stalker(model)
 model.hunter.position = point + Vector2(0, -17)
 model.hunter.state = HunterState.State.MOVE
 game.presentation.identity.heading = Vector2.LEFT
 return model

func _pose_stalker(model):
 var hunter = model.hunter
 check(hunter.archetype == "stalker", "fixture uses deterministically selected Stalker")
 hunter.boss_policy.enabled = false
 hunter.position = model.player().door_approach()
 hunter.target = model.player_room
 hunter.state = HunterState.State.ATTACK
 hunter.cooldown = .5
 model.time = model.preparation + .1
 model.evolution.evolution_level = 1
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.update(STEP, model)

func _capture_crops(model, destination: String):
 var frame := root.get_texture().get_image()
 var room = model.player()
 var needle: Vector2 = room.tile_position(room.buildings.keys()[0])
 var subjects := {"stalker": model.hunter.position, "needle": needle}
 for subject in subjects:
  var center: Vector2 = root.get_final_transform() * game.world_to_screen(subjects[subject])
  var size := Vector2i(180, 170) if subject == "stalker" else Vector2i(96, 90)
  var offset := Vector2i(-90, -125) if subject == "stalker" else Vector2i(-48, -60)
  var region := Rect2i(Vector2i(center) + offset, size)
  check(Rect2i(Vector2i.ZERO, frame.get_size()).encloses(region), "native-pixel crop is in viewport")
  check(frame.get_region(region).save_png(destination.path_join(subject + "-crop.png")) == OK, "save native-pixel " + subject + " crop")

func _count_events(model, seen: Dictionary, counts: Dictionary):
 for event in model.combat_events:
  var key := "combat:" + str(event.id)
  if seen.has(key):
   continue
  seen[key] = true
  if event.room == model.player_room and event.kind == "turret" and event.type in ["launch", "impact"]:
   counts["needle_" + event.type] += 1
 for event in model.presentation_events:
  var key := "presentation:" + str(event.id)
  if seen.has(key):
   continue
  seen[key] = true
  if event.room != model.player_room:
   continue
  if event.type == "door_damage":
   counts.stalker_door_damage += 1
  elif event.type == "archetype_warning":
   counts.stalker_warning += 1

func _measure(model) -> Dictionary:
 var before := _state_digest(model)
 var durations: Array[float] = []
 for index in range(WARMUP_FRAMES + TIMED_FRAMES):
  var begin := Time.get_ticks_usec()
  game.presentation.update(STEP, model)
  await _render_frame()
  if index >= WARMUP_FRAMES:
   durations.append((Time.get_ticks_usec() - begin) / 1000.0)
 check(before == _state_digest(model), "measurement leaves sampled model state untouched")
 durations.sort()
 return {
  "warmup_frames": WARMUP_FRAMES,
  "sample_frames": TIMED_FRAMES,
  "median_ms": (durations[119] + durations[120]) / 2.0,
  "p95_ms": durations[ceili(TIMED_FRAMES * .95) - 1],
  "max_ms": durations.back(),
  "static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
  "render_video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
 }

func _state_digest(model) -> String:
 var rooms := []
 for room in model.rooms:
  rooms.append({
   "index": room.index, "gold": room.gold, "electricity": room.electricity,
   "door_hp": room.door_hp, "owner": room.owner, "sleeping": room.sleeping,
   "alive": room.alive, "buildings": room.buildings
  })
 var hunter = model.hunter
 var state := {
  "time": model.time, "rng": model.random.state, "rooms": rooms,
  "hunter": {"hp": hunter.hp, "at": hunter.position, "state": hunter.state,
   "target": hunter.target, "attacks": hunter.attacks, "cooldown": hunter.cooldown,
   "conceal_remaining": hunter.conceal_remaining, "charged_ready": hunter.charged_ready},
  "projectiles": model.projectiles, "shots": model.shots
 }
 return JSON.stringify(state, "", true, true).sha256_text()

func _render_frame():
 game.queue_redraw()
 if is_instance_valid(game.ui.horror_layer):
  game.ui.horror_layer.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
