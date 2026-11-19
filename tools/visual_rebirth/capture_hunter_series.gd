extends "res://tools/capture_visual_rebirth.gd"
## Actual production view of level art and an independent seeded combat fixture.

var hunter_kind: String
var preview

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in StrategyCatalog.ARCHETYPE_IDS:
  push_error("Pass an absolute evidence directory and an ordinary Hunter ID")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 hunter_kind = args[1]
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 preview = game.presentation.nightmare_visual.get(hunter_kind + "_preview")
 check(preview != null, "actual renderer registers requested Hunter")
 var model = _dense_fixture()
 model.hunter.archetype = hunter_kind
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var paths := {}
 for level in range(1, 11):
  model.evolution.evolution_level = level
  model.evolution.final_revealed = level == 10
  model.evolution.rebirth_remaining = 0.0
  game.presentation.identity.heading = Vector2(-1, 1).normalized()
  await _render_frame()
  if pilot:
   check(preview.active_level == level, "real art path bound required level %d" % level)
   var texture: Texture2D = preview.texture
   check(texture != null and texture.resource_path.ends_with("level_%02d_oblique.png" % level), "exact declared level sprite reached canvas")
   if texture != null:
    paths[texture.resource_path] = true
  await capture("%s-level-%02d-720" % [hunter_kind, level])
 check(not pilot or paths.size() == 10, "ten unique production textures bound")
 await _live_combat(pilot)
 await _finish()

func _live_combat(pilot: bool):
 game.new_balance_version = 1
 game.return_menu()
 var seed_value := 66 + StrategyCatalog.ARCHETYPE_IDS.find(hunter_kind)
 check(game.start_endless("abandoned_dorm", "standard", seed_value), "actual deterministic Endless archetype session")
 game.set_process(false)
 game.tutorial_enabled = false
 var model = game.model
 check(model.hunter.archetype == hunter_kind and model.claim_room(3), "real Hunter identity and room initialized")
 var room = model.player()
 model.player_position = room.bed_position()
 model.sleep_player()
 room.door_hp = room.max_hp()
 var door: Vector2 = room.door_approach()
 var at: Vector2 = candidate(room)
 var nearest := INF
 var bounds: Rect2 = room.bounds().grow(-32)
 for y in range(int(bounds.position.y), int(bounds.end.y), 9):
  for x in range(int(bounds.position.x), int(bounds.end.x), 9):
   var point := Vector2(x, y)
   var separation := point.distance_squared_to(door)
   if separation < nearest and room.spatial.geometry_reason(point) == "":
    at = point
    nearest = separation
 check(model.place_building("turret", at), "actual paid Needle near encounter")
 model.hunter.position = door + Vector2(0, -17)
 model.hunter.target = room.index
 model.hunter.state = HunterState.State.MOVE
 model.hunter.cooldown = .5
 model.time = model.preparation + .1
 model.evolution.evolution_level = 7
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.heading = Vector2.LEFT
 var before_door: float = room.door_hp
 var before_hunter: float = model.hunter.hp
 var poses := {}
 for frame in range(192):
  game._process(STEP)
  await _render_frame()
  if pilot and preview.active_level == 7 and not preview.pose_name.is_empty() and not poses.has(preview.pose_name):
   poses[preview.pose_name] = frame
   await capture("%s-level-07-%s-combat-720" % [hunter_kind, preview.pose_name])
 check(model.hunter.attacks > 0 and room.door_hp < before_door, "actual evolved Hunter attacks the door")
 check(model.shots > 0 and model.hunter.hp < before_hunter, "actual paid Needle lands damage")
 if pilot:
  check(poses.has("tell") and poses.has("strike"), "actual evolved Hunter animation binds tell and strike")
 print("HUNTER_SERIES ", hunter_kind, " shots=", model.shots, " strikes=", model.hunter.attacks, " door_loss=", before_door - room.door_hp, " hunter_loss=", before_hunter - model.hunter.hp, " poses=", poses)
