extends RefCounted
## Oblique Stalker sprites share a world-space floor anchor. Other directions
## retain their existing renderer until independently authored views are ready.

const TEXTURE_PATH = "res://assets/visual_rebirth/stalker/level_01_left_prototype.png"
const EVOLVED_TEXTURE_PATH = "res://assets/visual_rebirth/stalker/level_%02d_oblique.png"
const DRAW_SIZE = Vector2(48.4, 140.8)
const FLOOR_PIVOT = Vector2(23.5, 140.0)
## Twice the standing survivor's 52-pixel draw height, with a fuller silhouette.
const DISPLAY_SCALE = Vector2(0.90, 104.0 / DRAW_SIZE.y)
const EVOLVED_SIZE = Vector2(328, 264)
const EVOLVED_FLOOR = Vector2(164, 260)
const EVOLVED_SCALE = Vector2.ONE * (104.0 / 256.0)
# Marked on the assembled pixels: near fingertip, far fingertip, mouth, shoulder.
const EVOLVED_LANDMARKS = {
 2: [Vector2(171, 168), Vector2(83, 143), Vector2(132, 35), Vector2(165, 49)],
 3: [Vector2(177, 171), Vector2(75, 163), Vector2(131, 38), Vector2(171, 46)],
 4: [Vector2(196, 175), Vector2(61, 61), Vector2(170, 39), Vector2(153, 45)],
 5: [Vector2(192, 174), Vector2(77, 155), Vector2(135, 38), Vector2(173, 52)],
 6: [Vector2(157, 239), Vector2(96, 142), Vector2(122, 51), Vector2(163, 43)],
 7: [Vector2(168, 221), Vector2(143, 150), Vector2(129, 47), Vector2(164, 48)],
 8: [Vector2(119, 245), Vector2(168, 188), Vector2(117, 70), Vector2(155, 61)],
 9: [Vector2(182, 185), Vector2(57, 178), Vector2(150, 41), Vector2(177, 52)],
 10: [Vector2(225, 174), Vector2(96, 166), Vector2(169, 27), Vector2(183, 48)],
}
const SOCKET_LAYOUT = ["near_fingertips", "far_fingertips", "mouth"]
const GRID = Vector2i(12, 22)
const STEPS = 16
const POSES = ["idle", "stalk", "turn", "tell", "strike", "hit", "recover", "vanish"]
const SOCKETS = {
 "near_fingertips": Vector2(.55, .602),
 "far_fingertips": Vector2(.282, .628),
 "mouth": Vector2(.252, .094),
}
const TRANSITION_TIME = .13
const STRIKE_TRANSITION_TIME = .06

var enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var texture: Texture2D
var active_level := 1
var available_levels: Dictionary[int, bool] = {}
var frames: Dictionary[Vector2i, PackedVector2Array] = {}
var pose_name: String
var pose_started := 0.0
var current_mesh: ArrayMesh
var current_vertices := PackedVector2Array()
var previous_vertices := PackedVector2Array()
var blend_vertices := PackedVector2Array()
var uploaded_frame := Vector2i(-1, -1)
var uploaded_weight := -1.0
var topology: Array = []
var transform := Transform2D.IDENTITY

func reset_pose() -> void:
 pose_name = ""
 current_vertices = PackedVector2Array()
 previous_vertices = PackedVector2Array()
 uploaded_frame = Vector2i(-1, -1)
 uploaded_weight = -1.0

func supports(level: int, heading: Vector2) -> bool:
 if not enabled or level < 1 or level > 10:
  return false
 # Let the same oblique pose settle before switching at the boundary
 # between it and an orientation handled by the existing renderer.
 var allowance := .1 if not pose_name.is_empty() else 0.0
 if not (heading.x <= -.55 + allowance or (heading.x <= .15 + allowance and heading.y > .55 - allowance)):
  return false
 if not available_levels.has(level):
  available_levels[level] = ResourceLoader.exists(_texture_path(level), "Texture2D")
 return available_levels[level]

func texture_for(level: int) -> Texture2D:
 if level == active_level and texture != null:
  return texture
 var path := _texture_path(level)
 return load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null

func _texture_path(level: int) -> String:
 return TEXTURE_PATH if level == 1 else EVOLVED_TEXTURE_PATH % level

func _set_geometry_level(level: int) -> void:
 if active_level == level:
  return
 active_level = level
 texture = null
 frames.clear()
 current_mesh = null
 reset_pose()

func draw(canvas: CanvasItem, floor: Vector2, tint: Color, state: String, progress: float, angle: float, clock: float, reduced: bool, level := 1) -> bool:
 var next_texture := texture_for(level)
 if next_texture == null:
  available_levels[level] = false
  return false
 _set_geometry_level(level)
 texture = next_texture
 _update_pose(state, progress, clock, reduced)
 transform = Transform2D(angle, _display_scale(), 0.0, floor)
 canvas.draw_mesh(current_mesh, texture, transform, tint)
 return true

func _display_scale() -> Vector2:
 return DISPLAY_SCALE if active_level == 1 else EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return FLOOR_PIVOT if active_level == 1 else EVOLVED_FLOOR

func _draw_size() -> Vector2:
 return DRAW_SIZE if active_level == 1 else EVOLVED_SIZE

func _update_pose(state: String, progress: float, clock: float, reduced: bool) -> void:
 var frame := roundi(clampf(progress, 0.0, 1.0) * STEPS)
 var pose_index := POSES.find(state)
 if state == "evolve":pose_index = POSES.size()
 elif state == "guard":pose_index = POSES.size() + 1
 var key := Vector2i(pose_index, frame)
 if not frames.has(key):
  frames[key] = _pose_vertices(state, float(frame) / STEPS)
 if pose_name != state:
  # A live blend owns a mutable buffer. Snapshot it only if interrupted.
  previous_vertices = PackedVector2Array()
  if not reduced:
   previous_vertices = current_vertices.duplicate() if uploaded_weight < 1.0 else current_vertices
  pose_name = state
  pose_started = clock
 var duration := STRIKE_TRANSITION_TIME if state == "strike" else TRANSITION_TIME
 var weight := smoothstep(0.0, duration, clampf(clock - pose_started, 0.0, duration)) if not previous_vertices.is_empty() else 1.0
 if key == uploaded_frame and weight == uploaded_weight:
  return
 var target := frames[key]
 if weight < 1.0:
  blend_vertices.resize(target.size())
  for i in range(target.size()):
   blend_vertices[i] = previous_vertices[i].lerp(target[i], weight)
  current_vertices = blend_vertices
 else:
  previous_vertices = PackedVector2Array()
  current_vertices = target
 if current_mesh == null:
  current_mesh = _surface(_surface_arrays(current_vertices), true)
  var floor_pivot := _floor_pivot()
  var size := _draw_size()
  current_mesh.custom_aabb = AABB(Vector3(-floor_pivot.x - 22, -floor_pivot.y - 22, 0), Vector3(size.x + 44, size.y + 44, 1))
 else:
  # The dynamic surface uses only 2D float positions in its vertex stream.
  # UVs and indices remain resident while we replace that stream.
  current_mesh.surface_update_vertex_region(0, 0, current_vertices.to_byte_array())
 uploaded_frame = key
 uploaded_weight = weight

func socket_position(name: String) -> Vector2:
 var point: Vector2 = SOCKETS[name] if active_level == 1 else _evolved_socket(name)
 var vertices := current_vertices
 var cell := point * Vector2(GRID)
 var cell_left := floori(cell.x)
 var cell_top := floori(cell.y)
 var fraction := cell - Vector2(cell_left, cell_top)
 var top_left := cell_top * (GRID.x + 1) + cell_left
 var bottom_left := top_left + GRID.x + 1
 var a := vertices[top_left + 1]
 var b := vertices[bottom_left]
 var result: Vector2
 if fraction.x + fraction.y <= 1.0:
  var c := vertices[top_left]
  result = c + (a - c) * fraction.x + (b - c) * fraction.y
 else:
  var c := vertices[bottom_left + 1]
  result = c + (a - c) * (1.0 - fraction.y) + (b - c) * (1.0 - fraction.x)
 return transform * result

func _mesh(state: String, progress: float) -> ArrayMesh:
 return _surface(_surface_arrays(_pose_vertices(state, progress)))

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var vertices := PackedVector2Array()
 var uvs: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 vertices.resize(uvs.size())
 for i in range(uvs.size()):
  var uv := uvs[i]
  if active_level == 1:
   vertices[i] = uv * DRAW_SIZE - FLOOR_PIVOT + _offset(uv, state, progress)
  else:
   vertices[i] = uv * EVOLVED_SIZE - EVOLVED_FLOOR + _evolved_offset(uv, state, progress)
 return vertices

func _prepare_topology() -> void:
 if not topology.is_empty():
  return
 var uvs := PackedVector2Array()
 var indices := PackedInt32Array()
 for y in range(GRID.y + 1):
  for x in range(GRID.x + 1):
   uvs.append(Vector2(float(x) / GRID.x, float(y) / GRID.y))
   if x == GRID.x or y == GRID.y:
    continue
   var top_left := y * (GRID.x + 1) + x
   var bottom_left := top_left + GRID.x + 1
   indices.append_array([top_left, top_left + 1, bottom_left, top_left + 1, bottom_left + 1, bottom_left])
 topology.resize(Mesh.ARRAY_MAX)
 topology[Mesh.ARRAY_TEX_UV] = uvs
 topology[Mesh.ARRAY_INDEX] = indices

func _surface_arrays(vertices: PackedVector2Array) -> Array:
 var arrays := topology.duplicate()
 arrays[Mesh.ARRAY_VERTEX] = vertices
 return arrays

func _surface(surface: Array, dynamic := false) -> ArrayMesh:
 var mesh := ArrayMesh.new()
 var flags := Mesh.ARRAY_FLAG_USE_2D_VERTICES
 if dynamic:
  flags |= Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], {}, flags)
 return mesh

func _offset(uv: Vector2, state: String, progress: float) -> Vector2:
 # Weighted regions follow the painted shape. Both shoulder weights tend
 # smoothly to zero at the arm roots, keeping the neckline joined.
 var upper := 1.0 - smoothstep(.08, .64, uv.y)
 var hem := smoothstep(.62, .9, uv.y) * (1.0 - smoothstep(.93, 1.0, uv.y))
 var hair := (1.0 - smoothstep(.18, .44, uv.x)) * smoothstep(.02, .22, uv.y) * (1.0 - smoothstep(.36, .65, uv.y))
 var near_hand := _weight(uv, Vector2(.55, .545), Vector2(.19, .22))
 var far_hand := _weight(uv, Vector2(.27, .56), Vector2(.14, .20))
 var head := _weight(uv, Vector2(.245, .083), Vector2(.275, .18))
 var exposed_shoulder := _weight(uv, Vector2(.645, .218), Vector2(.255, .22))
 var phase := progress * TAU
 match state:
  "stalk":
   var step := sin(phase)
   var next_step := cos(phase)
   return Vector2(-2.0 * upper + 1.4 * hair * next_step + 2.5 * hem * step + 2.4 * (near_hand - far_hand) * step, -1.7 * upper * next_step)
  "turn":
   return Vector2((3.2 * head - 1.3 * exposed_shoulder + 2.0 * hair - 1.2 * hem) * progress, (-1.1 * head + .8 * exposed_shoulder) * progress)
  "tell":
   return Vector2((2.8 * upper - 3.0 * near_hand - 1.6 * far_hand + 1.1 * head) * progress, (-1.3 * upper - 6.5 * near_hand - .8 * exposed_shoulder) * progress)
  "strike":
   return Vector2((-7.0 * upper - 5.0 * near_hand - 3.0 * far_hand + 2.0 * hem) * progress, (-2.0 * upper - 5.0 * near_hand - 2.2 * far_hand) * progress)
  "hit":
   return Vector2((5.0 * upper - 2.3 * hair) * progress, 2.5 * upper * progress)
  "recover":
   return Vector2((2.2 * head + 1.1 * upper - 1.25 * hair) * progress, (4.0 * head + 1.4 * exposed_shoulder) * progress)
  "vanish":
   return Vector2((upper * 4.5 - 2.2 * hair - 3.0 * hem) * progress, (upper * 10.0 + 1.5 * hem) * progress)
  _:
   return Vector2(upper * sin(phase) + 1.8 * hair * sin(phase - .7) + 1.2 * hem * sin(phase - 1.0), -1.3 * upper * cos(phase) - 1.0 * exposed_shoulder * sin(phase))

func _evolved_socket(name: String) -> Vector2:
 var point: Vector2 = EVOLVED_LANDMARKS[active_level][SOCKET_LAYOUT.find(name)]
 return point / EVOLVED_SIZE

func _evolved_offset(uv: Vector2, state: String, progress: float) -> Vector2:
 # Evolved artwork can widen beyond the starter. Screen-sized deformation
 # regions keep the limbs and face joined across different body silhouettes.
 var marks: Array = EVOLVED_LANDMARKS[active_level]
 var mouth: Vector2 = marks[2] / EVOLVED_SIZE
 var shoulder: Vector2 = marks[3] / EVOLVED_SIZE
 var head := _weight(uv, mouth - Vector2(0, .055), Vector2(.18, .2))
 var shoulders := _weight(uv, shoulder, Vector2(.19, .245))
 var near_hand := _weight(uv, marks[0] / EVOLVED_SIZE - Vector2(0, .045), Vector2(.21, .255))
 var far_hand := _weight(uv, marks[1] / EVOLVED_SIZE - Vector2(0, .055), Vector2(.18, .23))
 var face_lock := _weight(uv, mouth + Vector2(-.035, .23), Vector2(.15, .38))
 var swept_lock := _weight(uv, shoulder + Vector2(.10, .03), Vector2(.29, .29))
 var hair := maxf(face_lock, swept_lock * .8)
 var hem := smoothstep(.52, .88, uv.y) * (1.0 - smoothstep(.93, 1.0, uv.y))
 var upper := maxf(head, shoulders)
 var phase := progress * TAU
 var shift := Vector2.ZERO
 match state:
  "stalk":
   shift = Vector2(-1.7 * upper + 1.4 * hair * cos(phase) + (near_hand - far_hand) * 1.9 * sin(phase) + hem * 1.8 * sin(phase - .7), -1.3 * shoulders * cos(phase))
  "turn":
   shift = Vector2(3.1 * head - 1.2 * shoulders + 1.4 * hair - 1.2 * hem, -1.3 * head) * progress
  "tell":
   shift = Vector2(2.4 * head + 1.6 * shoulders - 2.3 * near_hand - 1.1 * far_hand, -4.3 * near_hand - 1.1 * shoulders) * progress
  "strike":
   shift = Vector2(-3.7 * head - 2.3 * shoulders - 5.3 * near_hand - 2.7 * far_hand + 1.5 * hem, -2.9 * near_hand - 1.2 * far_hand) * progress
  "hit":
   shift = Vector2(2.6 * upper - 1.1 * hair, 1.5 * shoulders) * progress
  "recover":
   shift = Vector2(2.2 * head + shoulders - hair, 3.3 * head + 1.3 * shoulders) * progress
  "evolve":
   var pulse := sin(progress * PI)
   shift = Vector2((uv.x - .5) * (7.6 * hair + 6.2 * hem) - 1.3 * shoulders, -3.5 * head - 2.2 * shoulders) * pulse
  "vanish":
   shift = Vector2(2.1 * upper - 1.2 * hair - 1.6 * hem, 6.9 * upper + 1.2 * hem) * progress
  _:
   shift = Vector2(1.25 * hair * sin(phase - .7) + .9 * hem * sin(phase - 1.1), -.8 * upper * cos(phase) - .55 * shoulders * sin(phase))
 return shift / EVOLVED_SCALE

func _weight(uv: Vector2, center: Vector2, radius: Vector2) -> float:
 return 1.0 - smoothstep(.1, 1.0, ((uv - center) / radius).length())
