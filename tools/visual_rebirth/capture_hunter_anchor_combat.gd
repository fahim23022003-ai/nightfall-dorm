extends "res://tools/visual_rebirth/capture_hunter_direction_motion.gd"
## Each anchored cut reports rendered directions and a live Needle/door exchange.

const Articulation=preload("res://scripts/articulated_hunter.gd")
const ANCHORS := [1, 4, 7, 10]
const LOOK_ROUTE := [
 Vector2(95, 305), Vector2(150, 305), Vector2(150, 344),
 Vector2(102, 344), Vector2(102, 305), Vector2(158, 305), Vector2(113, 342),
]

func is_articulated_pilot(archetype: String, level: int) -> bool:
 return OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE")=="1" and not Articulation.catalog_key(archetype,level).is_empty()

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [2, 3] or not args[0].is_absolute_path() or args[1] not in StrategyCatalog.ARCHETYPE_IDS:
  push_error("Pass an absolute evidence root, a Hunter ID, and optionally one anchor level after --.")
  quit(2)
  return
 if OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") != "1":
  push_error("Enable the production visual preview before recording.")
  quit(2)
  return
 var levels := [int(args[2])] if args.size() == 3 else ANCHORS
 if levels[0] not in ANCHORS:
  push_error("Anchor must be 1, 4, 7, or 10.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var archetype := args[1]
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()

 var records: Array[Dictionary] = []
 for level in levels:
  var child := destination.path_join("l%02d" % level)
  var frames := child.path_join("frames")
  DirAccess.make_dir_recursive_absolute(frames)
  records.append(await _capture_segment(archetype, level, frames))
 var report := FileAccess.open(destination.path_join("anchor-motion.json"), FileAccess.WRITE)
 check(report != null, "anchor report opens")
 if report != null:
  report.store_string(JSON.stringify({
   "archetype": archetype,
   "fps": 24,
   "viewport": [1280, 720],
   "fixture": "Prepared seeded Endless. The chosen level, starting player wallet and Hunter route are staged. Each path is checked before the production movement primitive and heading tracker run. Live ordinary combat uses normal MatchModel ticks and one legally paid Needle.",
   "combat_staging": "Ordinary attacks are isolated by postponing special-ability cooldowns. A higher door level extends the comparison. The initial countdown leaves time for a paid Needle to land before the first Hunter windup. Windup durations, damage, and projectiles remain in the model.",
   "segments": records,
  }, "  ") + "\n")
 await _finish()

func _capture_segment(archetype: String, level: int, frames: String) -> Dictionary:
 frame_number = 0
 frame_records.clear()
 observed_textures.clear()
 projection_signs.clear()
 missing_view_frames = 0
 var model = _setup_anchor_combat(archetype, level)
 check(game.ui.hunter_label.text.begins_with("HUNTER EVO %d " % level), "HUD matches captured level %d" % level)

 await _record(frames, model, archetype, level)
 for hold in range(5):
  game.presentation.update(STEP, model)
  await _record(frames, model, archetype, level)
 for index in range(1, LOOK_ROUTE.size()):
  await _walk(frames, model, LOOK_ROUTE[index], archetype, level)
 var door: Vector2 = model.player().door_approach()
 await _walk(frames, model, door, archetype, level)
 var approach_frames := frame_number

 var pilot:=is_articulated_pilot(archetype, level)
 var initial_door: float = model.player().door_hp
 var initial_hunter: float = model.hunter.hp
 var events := {}
 var first_live_hit := -1
 var seen_hit_pose := false
 var seen_tell_pose := false
 var seen_release_pose := false
 for tick in range(150):
  game._process(STEP)
  await _record(frames, model, archetype, level)
  for event in model.combat_events:
   if event.room == model.player_room and event.kind == "turret" and event.type in ["launch", "impact"] and not events.has(event.type):
    events[event.type] = frame_number - 1
  if model.hunter.windup_remaining > 0 and not events.has("ordinary_warning"):
   events["ordinary_warning"] = frame_number - 1
  if model.player().door_hp < initial_door and not events.has("door_strike"):
   events["door_strike"] = frame_number - 1
  if model.hunter.hp < initial_hunter and first_live_hit < 0:
   first_live_hit = frame_number - 1
  var rendered_pose: String = frame_records.back()["pose"]
  seen_hit_pose = seen_hit_pose or rendered_pose == "hit"
  seen_tell_pose = seen_tell_pose or rendered_pose == ("windup" if pilot else "tell")
  seen_release_pose = seen_release_pose or rendered_pose in (["contact","follow"] if pilot else ["strike","release"])
  if first_live_hit >= 0 and seen_hit_pose and seen_tell_pose and seen_release_pose and events.size() == 4 and frame_number > int(events["door_strike"]) + 13:
   break

 check(events.has("ordinary_warning"), "%s L%d ordinary warning appeared" % [archetype, level])
 check(events.has("door_strike") and model.hunter.attacks > 0, "%s L%d primary strike damaged door" % [archetype, level])
 check(events.has("launch") and events.has("impact") and first_live_hit >= 0, "%s L%d paid Needle hit Hunter" % [archetype, level])
 check(seen_hit_pose, "%s L%d production hit pose reached canvas" % [archetype, level])
 check(seen_tell_pose and seen_release_pose, "%s L%d production tell and release poses reached canvas" % [archetype, level])
 var poses := {}
 for record in frame_records:
  poses[record["pose"]] = true
 if pilot:
  var contact_frame: Dictionary=frame_records[int(events.get("door_strike",0))]
  check(poses.has("move") and observed_textures.size()==4, "%s covers physical locomotion in each authored direction" % archetype)
  var error: float=contact_frame.actual_contact_error
  check(contact_frame.pose=="contact" and error>=0.0 and error<=2.0, "%s claw lands on the damage-event socket" % archetype)
 else:
  check(poses.has("turn") and (poses.has("stalk") or poses.has("glide")), "%s L%d movement and turn poses reached canvas" % [archetype, level])
 check(missing_view_frames == 0, "%s L%d modern renderer bound every frame" % [archetype, level])
 var frames_used := frame_records.duplicate()
 var result := {
  "level": level,
  "frame_count": frame_number,
  "approach_frames": approach_frames,
  "events": events,
  "first_hunter_damage_frame": first_live_hit,
  "bound_hit_pose": seen_hit_pose,
  "bound_tell_pose": seen_tell_pose,
  "bound_release_pose": seen_release_pose,
  "poses": poses.keys(),
  "door_damage": initial_door - model.player().door_hp,
  "hunter_damage": initial_hunter - model.hunter.hp,
  "textures": observed_textures.duplicate(),
  "frames": frames_used,
 }
 print("HUNTER_ANCHOR ", archetype, " L", level, " frames=", frame_number, " events=", events, " hit=", seen_hit_pose, " views=", observed_textures.size())
 return result

func _record(directory: String, model, archetype: String, level: int) -> void:
 if is_articulated_pilot(archetype,level):
  await record_articulated(directory,model)
  return
 await super._record(directory, model, archetype, level)
 if archetype == "witch":
  frame_records.back()["pose"] = game.presentation.nightmare_visual.witch_preview.pose_name

func record_articulated(directory: String, model: MatchModel) -> void:
 await _render_frame()
 var image := root.get_texture().get_image()
 var rig=game.presentation.nightmare_visual.articulated
 var socket: Vector2=game.presentation.nightmare_visual.articulated_contact()
 var event: Dictionary=game.presentation.hunter_combat.latest_body_contact(model)
 var measured: float=socket.distance_to(Vector2(event.point)+Vector2(145,40)) if not event.is_empty() and socket.is_finite() else -1.0
 if rig.last_asset.is_empty():
  missing_view_frames+=1
 else:
  observed_textures[rig.last_asset]=true
 frame_records.append({
  "frame":frame_number,"pose":rig.pose_name,"texture":rig.last_asset,
  "joint_points":Array(rig.joint_points).map(func(point):return [point.x,point.y]),
  "actual_contact_error":measured,
 })
 if image.get_size()!=Vector2i(1280,720) or image.save_png(directory.path_join("%04d.png" % frame_number))!=OK:
  check(false,"save native 720p frame")
 frame_number+=1

func _setup_anchor_combat(archetype: String, level: int):
 game.new_balance_version = 1
 game.return_menu()
 var seed_value := 66 + StrategyCatalog.ARCHETYPE_IDS.find(archetype)
 check(game.start_endless("abandoned_dorm", "standard", seed_value), "seeded real Endless %s" % archetype)
 game.set_process(false)
 game.tutorial_enabled = false
 var model = game.model
 check(model.hunter.archetype == archetype, "requested natural archetype seed matches")
 check(model.claim_room(3), "claim room for clear corridor combat")
 var room = model.player()
 model.player_position = room.bed_position()
 model.sleep_player()
 room.gold = 500
 room.bed_level = 4
 room.door_level = 5
 room.door_hp = room.max_hp()
 var door: Vector2 = room.door_approach()
 var at: Vector2 = candidate(room)
 var best := INF
 var bounds: Rect2 = room.bounds().grow(-32)
 for y in range(int(bounds.position.y), int(bounds.end.y), 9):
  for x in range(int(bounds.position.x), int(bounds.end.x), 9):
   var point := Vector2(x, y)
   var distance := point.distance_squared_to(door)
   if distance < best and room.spatial.geometry_reason(point) == "":
    at = point
    best = distance
 check(model.place_building("turret", at), "legally pay for nearby Needle")
 model.hunter.boss_policy.enabled = false
 model.hunter.state = HunterState.State.MOVE
 model.hunter.position = LOOK_ROUTE[0]
 model.hunter.target = room.index
 model.hunter.cooldown = .75
 model.hunter.nightmare.cooldown = 999
 model.hunter.arcane.cooldown = 999
 model.hunter.tactical_cooldown = 999
 model.time = model.preparation + .1
 model.evolution.evolution_level = level
 model.evolution.final_revealed = level == 10
 model.evolution.rebirth_remaining = 0.0
 game.audio_system.reset_match(model)
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.reset()
 game.presentation.nightmare_visual.reset()
 game.presentation.update(STEP, model)
 game.ui.update_match()
 return model

func _walk(frames: String, model, goal: Vector2, archetype: String, level: int) -> void:
 check(model._visible(model.hunter.position, goal), "%s route to %s is visible and walkable" % [archetype, goal])
 var guard := 0
 while not model.hunter.position.is_equal_approx(goal) and guard < 45:
  model.hunter.navigate(goal, STEP)
  game.presentation.update(STEP, model)
  await _record(frames, model, archetype, level)
  guard += 1
 check(model.hunter.position.is_equal_approx(goal), "%s walked to prepared waypoint" % archetype)
