extends SceneTree
## Draw the candidate turnarounds and sample animation deformations at game scale.

const StalkerPreview = preload("res://scripts/stalker_visual_prototype.gd")
const OUTPUT_SIZE := Vector2i(968, 630)
const TILE_SIZE := Vector2(112, 145)
const COLUMN_START := 68.0
const ROW_START := 37.0
const VIEWS := ["front", "rear", "left", "right"]

class Plate extends Node2D:
 var rows: Array[Dictionary] = []

 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO, OUTPUT_SIZE), Color("171922"))
  var font := ThemeDB.fallback_font
  for column in range(StalkerPreview.POSES.size()):
   var name: String = StalkerPreview.POSES[column]
   var at := Vector2(COLUMN_START + TILE_SIZE.x * column, 22.0)
   draw_string(font, at, name.capitalize(), HORIZONTAL_ALIGNMENT_CENTER, TILE_SIZE.x, 14, Color("dad1dc"))
  for row in range(rows.size()):
   var view := rows[row]
   var y := ROW_START + TILE_SIZE.y * row
   draw_string(font, Vector2(9, y + 74), VIEWS[row].capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("dad1dc"))
   for column in range(StalkerPreview.POSES.size()):
    var at := Vector2(COLUMN_START + TILE_SIZE.x * column, y)
    draw_rect(Rect2(at + Vector2(1, 1), TILE_SIZE - Vector2(2, 2)), Color("282933"))
    var floor := at + Vector2(TILE_SIZE.x / 2.0, 126)
    draw_set_transform(floor, 0.0, Vector2(1, .32))
    draw_circle(Vector2.ZERO, 19, Color(.045, .046, .083, .7))
    draw_set_transform(Vector2.ZERO)
    draw_mesh(view.meshes[column], view.texture, Transform2D(0.0, floor))

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size() != 2:
  push_error("Expected a prepared manifest path and a PNG output path after --.")
  quit(2)
  return
 var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 if not parsed is Dictionary or parsed.get("schema_version") != 1:
  push_error("Could not load prepared Stalker turnaround manifest.")
  quit(2)
  return

 var algebra := StalkerPreview.new()
 var template := algebra._mesh("idle", 0.0).surface_get_arrays(0)
 var plate := Plate.new()
 var directory: String = args[0].get_base_dir()
 var canvas := _vector(parsed.source_canvas)
 var scale := _vector(parsed.display_scale)
 var minimum_area := INF
 var triangles := 0
 for name in VIEWS:
  var view: Dictionary = parsed.views[name]
  var image := Image.load_from_file(directory.path_join(view.image))
  if image == null or image.is_empty():
   push_error("Could not load candidate " + name)
   plate.free()
   quit(2)
   return
  var joints := {}
  for joint in view.landmarks:
   joints[joint] = _vector(view.landmarks[joint])
  var projection := {
   "draw_size": canvas * scale,
   "floor_pivot": joints.ground * canvas * scale,
   "joints": joints,
   "forward": _vector(view.screen_forward),
  }
  var meshes: Array[ArrayMesh] = []
  for pose in StalkerPreview.POSES:
   for frame in range(StalkerPreview.STEPS + 1):
    var mesh := _retarget_mesh(algebra, template, pose, float(frame) / StalkerPreview.STEPS, projection)
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    for triangle in range(0, indices.size(), 3):
     var a := vertices[indices[triangle]]
     var b := vertices[indices[triangle + 1]]
     var c := vertices[indices[triangle + 2]]
     minimum_area = minf(minimum_area, (b - a).cross(c - a) * .5)
     triangles += 1
    if frame == (StalkerPreview.STEPS if pose in ["turn", "tell", "strike", "hit", "recover"] else StalkerPreview.STEPS / 2):
     meshes.append(mesh)
  plate.rows.append({"meshes": meshes, "texture": ImageTexture.create_from_image(image)})

 print("Candidate turnarounds: %d pose triangles, minimum area %.3f px²." % [triangles, minimum_area])
 if triangles == 0 or minimum_area <= 0:
  push_error("Candidate contains folded animation geometry.")
  plate.free()
  quit(1)
  return
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 root.size = OUTPUT_SIZE
 root.add_child(plate)
 await process_frame
 await RenderingServer.frame_post_draw
 var result := root.get_texture().get_image().save_png(args[1])
 if result != OK:
  push_error("Could not save the candidate plate.")
 quit(0 if result == OK else 2)

func _vector(value: Array) -> Vector2:
 return Vector2(value[0], value[1])


func _retarget_mesh(algebra, template: Array, pose: String, progress: float, projection: Dictionary) -> ArrayMesh:
 var draw_size: Vector2 = projection.draw_size
 var floor_pivot: Vector2 = projection.floor_pivot
 var uvs: PackedVector2Array = template[Mesh.ARRAY_TEX_UV]
 var points := PackedVector2Array()
 for uv in uvs:
  points.append(uv * draw_size - floor_pivot + _projected_offset(uv, pose, progress, projection))
 var arrays := template.duplicate()
 arrays[Mesh.ARRAY_VERTEX] = points
 return algebra._surface(arrays)

func _projected_offset(uv: Vector2, state: String, progress: float, projection: Dictionary) -> Vector2:
 # The camera positions are independent. Screen joints come from the same
 # anatomy projected into each image, with no mirrored crossover.
 var draw_size: Vector2 = projection["draw_size"]
 var joints: Dictionary = projection["joints"]
 var head: float = _projected_weight(uv, joints["head"], draw_size, Vector2(13, 22))
 var left_shoulder: float = _projected_weight(uv, joints["left_shoulder"], draw_size, Vector2(14, 30))
 var right_shoulder: float = _projected_weight(uv, joints["right_shoulder"], draw_size, Vector2(14, 30))
 var left_hand: float = _projected_weight(uv, joints["left_hand"], draw_size, Vector2(15, 27))
 var right_hand: float = _projected_weight(uv, joints["right_hand"], draw_size, Vector2(15, 27))
 var hem: float = _projected_weight(uv, joints["hem"], draw_size, Vector2(23, 18))
 var torso := maxf(left_shoulder, right_shoulder)
 var hands := maxf(left_hand, right_hand)
 var forward: Vector2 = projection["forward"]
 var step := progress * TAU
 match state:
  "stalk":
   return forward * (1.3 * torso + (left_hand-right_hand) * 1.6 * sin(step)) + Vector2(1.1 * hem * sin(step - .7), -1.6 * torso * cos(step))
  "turn":
   return Vector2(head * 3.5 - torso * 1.1 - hem * .7, -head * 1.2) * progress
  "tell":
   return (-forward * (head * 2.4 + torso * 1.1) + forward * hands * 2.8 + Vector2(0, -5.6 * hands)) * progress
  "strike":
   return (forward * (head * 3.2 + torso * 2.1 + hands * 8.6) + Vector2(0, hands * -3.3)) * progress
  "hit":
   return (-forward * (2.3 * torso + 1.35 * head) + Vector2(0, torso * 1.05)) * progress
  "recover":
   return (-forward * (2.1 * torso + .9 * head) + Vector2(0, head * 5.0 + torso * 2.2)) * progress
  "vanish":
   return Vector2(head * .8 - hem * 1.3, head * 4.4 + torso * 2.2) * progress
  _:
   return Vector2(head * .7 * sin(step - .6) + hem * .65 * sin(step - 1.1), -1.0 * torso * cos(step))

func _projected_weight(uv: Vector2, center: Vector2, scale: Vector2, radius: Vector2) -> float:
 return 1.0 - smoothstep(.1, 1.0, ((uv - center) * scale / radius).length())
