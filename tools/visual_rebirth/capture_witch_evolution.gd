extends "res://tools/capture_visual_rebirth.gd"
## Render existing evolution states in a prepared, frozen 16-slot room.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --")
  quit(2)
  return
 var destination := args[0]
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 model.hunter.archetype = "witch"
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var preview = game.presentation.nightmare_visual.witch_preview
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var textures_seen := {}
 for level in range(1, 11):
  model.evolution.evolution_level = level
  model.evolution.final_revealed = level == 10
  game.presentation.identity.heading = Vector2(-1, 1).normalized()
  await _render_frame()
  if pilot:
   var sprite: Texture2D = preview.texture_for(level, "oblique")
   check(sprite != null, "Witch level %d exact sprite loaded" % level)
   if sprite != null:
    textures_seen[sprite.resource_path] = true
  await capture("witch-level-%02d-720" % level)
 if pilot:
  check(textures_seen.size() == 10, "ten distinct Witch levels reached production draw")
  _check_evolved_mesh(preview)
 await _finish()

func _check_evolved_mesh(preview):
 var minimum := INF
 var triangles := 0
 for state in ["hover", "tell", "release", "hit", "evolve", "vanish"]:
  for frame in range(17):
   var mesh: ArrayMesh = preview.build_pose(state, float(frame) / 16.0, 1, preview.EVOLVED_WIDTH)
   var arrays := mesh.surface_get_arrays(0)
   var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
   var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
   for index in range(0, indices.size(), 3):
    var a := vertices[indices[index]]
    var b := vertices[indices[index + 1]]
    var c := vertices[indices[index + 2]]
    minimum = minf(minimum, (b - a).cross(c - a) * .5)
    triangles += 1
 print("WITCH_EVOLVED_TRIANGLES=", triangles, " MIN_AREA=", minimum)
 check(minimum > 0, "no flipped triangles in evolved Witch pose samples")
