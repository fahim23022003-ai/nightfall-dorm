extends "res://tools/capture_visual_rebirth.gd"
## Prepared visual stages, followed by a real evolved combat fixture.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var preview = game.presentation.nightmare_visual.stalker_preview
 var paths := {}
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 for level in range(1, 11):
  model.evolution.evolution_level = level
  model.evolution.final_revealed = level == 10
  model.evolution.rebirth_remaining = 0.0
  game.presentation.identity.heading = Vector2(-1, 1).normalized()
  await _render_frame()
  if pilot:
   check(preview.active_level == level, "actual preview bound Stalker level %d" % level)
   var texture: Texture2D = preview.texture
   check(texture != null, "actual draw supplied Stalker texture %d" % level)
   if texture != null:
    var expected: String = "level_01_left_prototype.png" if level == 1 else "level_%02d_oblique.png" % level
    check(texture.resource_path.ends_with(expected), "exact level texture path was used")
    paths[texture.resource_path] = true
  await capture("stalker-level-%02d-720" % level)
 check(not pilot or paths.size() == 10, "ten distinct Stalker textures reached production")
 if pilot:
  check(not preview.supports(10, Vector2.RIGHT), "unsupported rightward view keeps fallback")
 await _combat_sample(pilot)
 await _finish()

func _combat_sample(pilot: bool):
 var model = _combat_fixture()
 model.evolution.evolution_level = 7
 var room = model.player()
 var start_hp: float = room.door_hp
 var hunter_hp: float = model.hunter.hp
 var seen_poses := {}
 var preview = game.presentation.nightmare_visual.stalker_preview
 for index in range(144):
  game._process(STEP)
  await _render_frame()
  if pilot and preview.active_level == 7 and not preview.pose_name.is_empty() and not seen_poses.has(preview.pose_name):
   seen_poses[preview.pose_name] = index
   await capture("stalker-level-07-" + preview.pose_name + "-combat-720")
 check(model.hunter.attacks > 0 and room.door_hp < start_hp, "actual evolved Stalker damages the door")
 check(model.shots > 0 and model.hunter.hp < hunter_hp, "actual Needle damages the evolved Stalker")
 if pilot:
  check(preview.active_level == 7 and seen_poses.has("tell") and seen_poses.has("strike"), "real tells and strikes reached evolved preview")
 print("STALKER_7 shots=", model.shots, " strikes=", model.hunter.attacks, " door_loss=", start_hp - room.door_hp, " hunter_loss=", hunter_hp - model.hunter.hp, " poses=", seen_poses)
