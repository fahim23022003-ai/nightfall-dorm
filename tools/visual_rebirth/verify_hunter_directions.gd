extends SceneTree
## Run with NIGHTFALL_VISUAL_REBIRTH=1 after Godot imports the directional textures.

const RENDERERS := {
 "crusher": preload("res://scripts/crusher_visual.gd"),
 "stalker": preload("res://scripts/stalker_visual_prototype.gd"),
 "ravager": preload("res://scripts/ravager_visual.gd"),
 "witch": preload("res://scripts/phantom_witch_visual.gd"),
 "electric": preload("res://scripts/electric_ghost_visual.gd"),
 "storm": preload("res://scripts/storm_wraith_visual.gd"),
}
const HEADINGS := {
 "front": Vector2.DOWN,
 "left": Vector2.LEFT,
 "back": Vector2.UP,
 "right": Vector2.RIGHT,
}
const CAPE_POSES := ["hover", "glide", "turn", "tell", "release", "hit", "recover", "evolve", "vanish"]
const REAPER_FORMS := ["approach", "transformed"]
const LEGACY_HEADING := Vector2(-0.7071068, 0.7071068)

var failed := 0
var triangles := 0
var minimum_area := INF

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 if OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") != "1":
  push_error("Set NIGHTFALL_VISUAL_REBIRTH=1")
  quit(2)
  return
 var coverage := {}
 var complete_states := 0
 for family in RENDERERS:
  var renderer: RefCounted = RENDERERS[family].new()
  var levels: Array[int] = []
  for level in range(1, 11):
   var oblique_available: bool = renderer.supports(level) if family == "witch" else renderer.supports(level, LEGACY_HEADING)
   _require(oblique_available, "%s L%d original oblique available" % [family, level])
   var available := 0
   for view in HEADINGS:
    if ResourceLoader.exists(_ordinary_path(family, level, view), "Texture2D"):
     available += 1
   if available == 0:
    if family != "witch":
     _require(renderer._cardinal_landmarks(level).is_empty(), "%s L%d has marks but no art" % [family, level])
    continue
   _require(available == HEADINGS.size(), "%s L%d incomplete directional art" % [family, level])
   if available != HEADINGS.size():
    continue
   levels.append(level)
   complete_states += 1
   var diagonal: String = renderer.facing(LEGACY_HEADING) if family == "witch" else renderer._cardinal_view(level, LEGACY_HEADING)
   _require(diagonal == ("oblique" if family == "witch" else ""), "%s L%d retains original oblique heading" % [family, level])
   for view in HEADINGS:
    var context := "%s L%d %s" % [family, level, view]
    var path := _ordinary_path(family, level, view)
    var heading: Vector2 = HEADINGS[view]
    var art: Texture2D = renderer.texture_for(level, view)
    _require(art != null and art.resource_path == path, context + " texture path")
    if art == null:
     continue
    if family == "witch":
     _require(renderer.facing(heading) == view, context + " direction routing")
     _require(art.get_size() == Vector2(216 if level == 1 else 328, 264), context + " pivot canvas")
     continue
    _require(renderer._cardinal_view(level, heading) == view, context + " direction routing")
    _require(renderer._cardinal_landmarks(level).has(view), context + " landmarks")
    if not renderer._cardinal_landmarks(level).has(view):
     continue
    renderer._set_geometry_level(level, view)
    _require(art.get_size() == renderer._draw_size(), context + " pivot canvas")
    var marks: Array = renderer._cardinal_landmarks(level)[view]
    _require(marks.size() == 4, context + " marks both hands, head and upper body")
    for mark: Vector2 in marks:
     _require(Rect2(Vector2.ZERO, art.get_size()).has_point(mark), context + " on-canvas landmark")
    _check_ordinary_mesh(renderer, context)
  coverage[family] = levels
 if "--require-complete" in OS.get_cmdline_user_args():
  _require(complete_states == RENDERERS.size() * 10, "all ordinary directional states available")
 _verify_capes()
 print("HUNTER_CARDINAL_COVERAGE=", JSON.stringify(coverage))
 print("HUNTER_DIRECTION_TRIANGLES=", triangles, " MIN_SIGNED_AREA=", minimum_area, " FAILURES=", failed)
 quit(1 if failed > 0 else 0)

func _ordinary_path(family: String, level: int, view: String) -> String:
 return "res://assets/visual_rebirth/%s/level_%02d_%s.png" % [family, level, view]

func _check_ordinary_mesh(renderer: RefCounted, context: String) -> void:
 for pose in renderer.POSES + renderer.EXTRA_POSES:
  for step in range(renderer.STEPS + 1):
   var vertices: PackedVector2Array = renderer._pose_vertices(pose, float(step) / renderer.STEPS)
   _verify_triangles(vertices, renderer.topology[Mesh.ARRAY_INDEX], "%s %s/%d" % [context, pose, step])

func _verify_capes() -> void:
 var witch: RefCounted = RENDERERS.witch.new()
 var reaper: RefCounted = preload("res://scripts/boss_presentation.gd").new()
 for form in REAPER_FORMS:
  var original: Texture2D = reaper.preview_texture(form)
  _require(original != null and original.get_size() == Vector2(224, 264), form + " original oblique available")
  for view in HEADINGS:
   var art: Texture2D = reaper.preview_texture(form + "_" + view)
   _require(art != null and art.get_size() == Vector2(224, 264), "%s %s pivot canvas" % [form, view])
 for width in [216.0, 224.0, 328.0]:
  for side in [-1, 1]:
   for pose in CAPE_POSES:
    for step in range(witch.FRAME_COUNT + 1):
     var mesh: ArrayMesh = witch.build_pose(pose, float(step) / witch.FRAME_COUNT, side, width)
     var arrays := mesh.surface_get_arrays(0)
     _verify_triangles(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX], "cape %d %s/%d" % [width, pose, step])

func _verify_triangles(vertices: PackedVector2Array, indices: PackedInt32Array, context: String) -> void:
 for index in range(0, indices.size(), 3):
  var a := vertices[indices[index]]
  var b := vertices[indices[index + 1]]
  var c := vertices[indices[index + 2]]
  var area := (b - a).cross(c - a) * .5
  triangles += 1
  minimum_area = minf(minimum_area, area)
  if area <= 0.001:
   _require(false, "%s inverted triangle at %d" % [context, index / 3])
   return

func _require(condition: bool, issue: String) -> void:
 if not condition:
  failed += 1
  push_error(issue)
