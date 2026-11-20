extends "res://tools/capture_visual_rebirth.gd"
## Record model-driven heading changes on a scripted route through the dorm hall.

const ROUTE := [
 Vector2(95, 305), Vector2(173, 305), Vector2(173, 343),
 Vector2(105, 343), Vector2(105, 300), Vector2(173, 300), Vector2(113, 342),
]
const HOLD_FRAMES := 8

var frame_number := 0
var frame_records: Array[Dictionary] = []
var observed_textures := {}
var projection_signs := {}
var missing_view_frames := 0

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [2, 3] or not args[0].is_absolute_path() or args[1] not in StrategyCatalog.ARCHETYPE_IDS:
  push_error("Pass an absolute evidence directory, an ordinary Hunter ID, and optional level after --.")
  quit(2)
  return
 if OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") != "1":
  push_error("Enable the production visual preview before capturing direction motion.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var archetype := args[1]
 var level := int(args[2]) if args.size() == 3 else 1
 if level < 1 or level > 10:
  push_error("Hunter level must be from 1 to 10.")
  quit(2)
  return
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 var frames := destination.path_join("frames")
 DirAccess.make_dir_recursive_absolute(frames)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()

 var model = _fresh_room(0)
 model.hunter.archetype = archetype
 model.strategy.archetype = archetype
 model.hunter.boss_policy.enabled = false
 model.hunter.state = HunterState.State.MOVE
 model.hunter.position = ROUTE[0]
 model.hunter.target = model.player_room
 model.time = model.preparation + .1
 model.evolution.evolution_level = level
 model.evolution.final_revealed = level == 10
 model.running = true
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.reset()
 game.presentation.nightmare_visual.reset()
 game.presentation.update(STEP, model)
 game.ui.update_match()
 check(game.ui.hunter_label.text.begins_with("HUNTER EVO %d " % level), "HUD reports the staged evolution")

 for index in range(1, ROUTE.size()):
  var goal: Vector2 = ROUTE[index]
  check(model._visible(model.hunter.position, goal), "route segment %d is fully walkable" % index)
  var guard := 0
  while not model.hunter.position.is_equal_approx(goal) and guard < 45:
   model.hunter.navigate(goal, STEP)
   game.presentation.update(STEP, model)
   await _record(frames, model, archetype, level)
   guard += 1
  check(model.hunter.position.is_equal_approx(goal), "Hunter walked to waypoint %d in normal delta" % index)
  for hold in range(HOLD_FRAMES):
   game.presentation.update(STEP, model)
   await _record(frames, model, archetype, level)

 var combat := {}
 if archetype == "stalker" and level == 10:
  combat = await _record_stalker_cast(frames, model, level)
 if archetype == "witch" and level == 1:
  check(observed_textures.size() == 5, "all five production Witch directions reached the canvas while turning")
 else:
  check(observed_textures.size() > 1 or projection_signs.size() == 2, "Hunter bound multiple authored views or both oblique projections on the route")
 check(missing_view_frames == 0, "no motion frame reverted to the older visual family")
 check(frame_number == frame_records.size() and frame_number > 60, "full continuous 24 Hz sequence captured")
 var json := FileAccess.open(destination.path_join("motion-capture.json"), FileAccess.WRITE)
 check(json != null, "open motion metadata")
 if json != null:
  json.store_string(JSON.stringify({
   "hunter": archetype,
   "level": level,
   "fps": 24,
   "frame_count": frame_number,
   "viewport": [1280, 720],
   "fixture": "Prepared Hunter on a scripted walkable route. The production movement primitive and heading tracker run at fixed steps.",
   "textures": observed_textures,
   "oblique_transform_signs": projection_signs.keys(),
   "combat": combat,
   "frames": frame_records,
  }, "  ") + "\n")
 print("HUNTER_DIRECTION_FRAMES=", frame_number, " DISTINCT_TEXTURES=", observed_textures.size())
 await _finish()

func _record(directory: String, model, archetype: String, level: int) -> void:
 await _render_frame()
 var image := root.get_texture().get_image()
 var heading: Vector2 = game.presentation.identity.heading
 var path := _drawn_path(archetype, level, heading)
 var pose := ""
 if not path.is_empty():
  observed_textures[path] = int(observed_textures.get(path, 0)) + 1
  if archetype != "witch":
   var renderer = game.presentation.nightmare_visual.get(archetype + "_preview")
   var projection: float = signf(renderer.transform.determinant())
   projection_signs[projection] = true
   pose = renderer.pose_name
 else:
  missing_view_frames += 1
 var position: Vector2 = model.hunter.position
 frame_records.append({"frame": frame_number, "heading": [heading.x, heading.y], "position": [position.x, position.y], "texture": path, "pose": pose})
 if image.get_size() != Vector2i(1280, 720) or image.save_png(directory.path_join("%04d.png" % frame_number)) != OK:
  check(false, "save 720p motion frame %d" % frame_number)
 frame_number += 1

func _drawn_path(archetype: String, level: int, heading: Vector2) -> String:
 var renderer = game.presentation.nightmare_visual.get(archetype + "_preview")
 if archetype == "witch":
  var path: String = renderer.ART_PATH % [level, renderer.facing(heading)]
  if not renderer.textures.has(path) or renderer.textures[path] == null:
   path = renderer.ART_PATH % [level, "oblique"]
  return path if renderer.textures.has(path) and renderer.textures[path] != null else ""
 if renderer == null or renderer.texture == null or renderer.pose_name.is_empty():
  return ""
 return renderer.texture.resource_path


func _record_stalker_cast(directory: String, model, level: int) -> Dictionary:
 var door: Vector2 = model.player().door_approach()
 check(model._visible(model.hunter.position, door), "prepared post-route approach is walkable")
 var guard := 0
 while not model.hunter.position.is_equal_approx(door) and guard < 45:
  model.hunter.navigate(door, STEP)
  game.presentation.update(STEP, model)
  await _record(directory, model, "stalker", level)
  guard += 1
 check(model.hunter.position.is_equal_approx(door), "Stalker reached the attack socket through movement")
 model.hunter.state = HunterState.State.ATTACK
 model.hunter.nightmare.cooldown = 0.0
 var starting_hp: float = model.player().door_hp
 var events := {}
 var bound_tell := false
 var bound_release := false
 for step in range(96):
  game._process(STEP)
  await _record(directory, model, "stalker", level)
  for event in model.presentation_events:
   if event.get("skill", "") == "oath" and event.type in ["nightmare_warning", "nightmare_release", "nightmare_impact"]:
    if not events.has(event.type):
     events[event.type] = frame_number - 1
  var renderer = game.presentation.nightmare_visual.stalker_preview
  if model.hunter.nightmare.action == "oath" and renderer.pose_name == "tell":
   bound_tell = true
  if model.hunter.nightmare.effect == "oath" and renderer.pose_name == "strike":
   bound_release = true
  if bound_release and events.size() == 3 and frame_number > int(events.nightmare_release) + 14:
   break
 check(events.size() == 3, "Hollow Oath emitted warning, release and damage impact in model")
 check(bound_tell and bound_release, "Stalker entered tell and strike poses from real Hollow Oath events")
 check(model.player().door_hp < starting_hp, "target door lost real HP")
 return {
  "staging": "Set ATTACK at the reached door approach and set Nightmare cooldown to zero. Normal MatchModel ticks drive the existing cast and damage.",
  "skill": "Hollow Oath",
  "event_frame_indices": events,
  "door_hp_delta": model.player().door_hp - starting_hp,
  "bound_tell": bound_tell,
  "bound_strike": bound_release,
 }
