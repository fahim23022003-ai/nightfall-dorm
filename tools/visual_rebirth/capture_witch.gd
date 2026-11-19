extends "res://tools/capture_visual_rebirth.gd"

func run():
 var destination := OS.get_cmdline_user_args()[0]
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var dense = _dense_fixture()
 dense.hunter.archetype = "witch"
 for index in range(8):
  game.presentation.update(.125, dense)
  await _render_frame()
 var facings := {"front": Vector2.DOWN, "back": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT, "oblique": Vector2(-1, 1).normalized()}
 var preview = game.presentation.nightmare_visual.witch_preview
 for label in facings:
  game.presentation.identity.heading = facings[label]
  await _render_frame()
  await capture("witch-" + label + "-720")
 if OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1":
  check(preview.textures.size() == 5, "five independently authored directions reached actual draw path")
  for texture in preview.textures.values():
   check(texture.get_size() == Vector2(216, 264), "direction preserves common texture bounds")
  var minimum := INF
  var triangles := 0
  for state in ["hover", "tell", "release", "hit", "vanish"]:
   for frame in range(17):
    for side in [-1, 1]:
     var mesh: ArrayMesh = preview.build_pose(state, float(frame) / 16.0, side)
     var geometry := mesh.surface_get_arrays(0)
     var vertices: PackedVector2Array = geometry[Mesh.ARRAY_VERTEX]
     var indices: PackedInt32Array = geometry[Mesh.ARRAY_INDEX]
     for triangle in range(0, indices.size(), 3):
      var a := vertices[indices[triangle]]
      var b := vertices[indices[triangle + 1]]
      var c := vertices[indices[triangle + 2]]
      minimum = minf(minimum, (b - a).cross(c - a) * .5)
      triangles += 1
  check(minimum > 0, "deformation never folds sampled faces")
  print("WITCH_TRIANGLES=", triangles, " MIN_AREA=", minimum)
 print("WITCH_DIRECTIONS_RENDERED=", preview.textures.size())
 await _finish()
