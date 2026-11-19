extends RefCounted
## One-view Level 1 proof. Independent directional artwork and later levels
## stay on the current renderer until they have passed their own visual checks.

const TEXTURE_PATH = "res://assets/visual_rebirth/stalker/level_01_left_prototype.png"
const DRAW_SIZE = Vector2(48.4, 140.8)
const FLOOR_PIVOT = Vector2(23.5, 140.0)
## Twice the standing survivor's 52-pixel draw height, with a fuller silhouette.
const DISPLAY_SCALE = Vector2(0.90, 104.0 / DRAW_SIZE.y)
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
var frames: Dictionary = {}
var pose_name: String
var pose_started := 0.0
var current_mesh: ArrayMesh
var previous_vertices := PackedVector2Array()
var transform := Transform2D.IDENTITY

func reset_pose() -> void:
 pose_name = ""
 current_mesh = null
 previous_vertices.clear()

func supports(level: int, heading: Vector2) -> bool:
 if not enabled or level != 1:
  return false
 # Let the same oblique pose settle before switching at the boundary
 # between it and an orientation handled by the existing renderer.
 var allowance := .1 if not pose_name.is_empty() else 0.0
 return heading.x <= -.55 + allowance or (heading.x <= .15 + allowance and heading.y > .55 - allowance)

func draw(canvas: CanvasItem, floor: Vector2, tint: Color, state: String, progress: float, angle: float, clock: float, reduced: bool) -> bool:
 if texture == null:
  texture = load(TEXTURE_PATH) as Texture2D
  if texture == null:
   enabled = false
   return false
 var frame := roundi(clampf(progress, 0.0, 1.0) * STEPS)
 var key := Vector2i(POSES.find(state), frame)
 if not frames.has(key):
  frames[key] = _mesh(state, float(frame) / STEPS)
 var target: ArrayMesh = frames[key]
 if pose_name != state:
  previous_vertices = _vertices(current_mesh) if current_mesh != null and not reduced else PackedVector2Array()
  pose_name = state
  pose_started = clock
 var duration := STRIKE_TRANSITION_TIME if state == "strike" else TRANSITION_TIME
 var weight := smoothstep(0.0, duration, clampf(clock - pose_started, 0.0, duration))
 current_mesh = target
 if not previous_vertices.is_empty() and weight < 1.0:
  current_mesh = _blend_mesh(previous_vertices, target.surface_get_arrays(0), weight)
 else:
  previous_vertices.clear()
 transform = Transform2D(angle, DISPLAY_SCALE, 0.0, floor)
 canvas.draw_mesh(current_mesh, texture, transform, tint)
 return true

func socket_position(name: String) -> Vector2:
 var point: Vector2 = SOCKETS[name]
 var vertices := _vertices(current_mesh)
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

func _vertices(mesh: ArrayMesh) -> PackedVector2Array:
 return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _blend_mesh(from: PackedVector2Array, to: Array, weight: float) -> ArrayMesh:
 var destination: PackedVector2Array = to[Mesh.ARRAY_VERTEX]
 for vertex in range(destination.size()):
  destination[vertex] = from[vertex].lerp(destination[vertex], weight)
 to[Mesh.ARRAY_VERTEX] = destination
 return _surface(to)

func _mesh(state: String, progress: float) -> ArrayMesh:
 var vertices := PackedVector2Array()
 var uvs := PackedVector2Array()
 var indices := PackedInt32Array()
 for y in range(GRID.y + 1):
  for x in range(GRID.x + 1):
   var uv := Vector2(float(x) / GRID.x, float(y) / GRID.y)
   uvs.append(uv)
   vertices.append(uv * DRAW_SIZE - FLOOR_PIVOT + _offset(uv, state, progress))
   if x == GRID.x or y == GRID.y:
    continue
   var top_left := y * (GRID.x + 1) + x
   var bottom_left := top_left + GRID.x + 1
   indices.append_array([top_left, top_left + 1, bottom_left, top_left + 1, bottom_left + 1, bottom_left])
 var surface := []
 surface.resize(Mesh.ARRAY_MAX)
 surface[Mesh.ARRAY_VERTEX] = vertices
 surface[Mesh.ARRAY_TEX_UV] = uvs
 surface[Mesh.ARRAY_INDEX] = indices
 return _surface(surface)

func _surface(surface: Array) -> ArrayMesh:
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
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

func _weight(uv: Vector2, center: Vector2, radius: Vector2) -> float:
 return 1.0 - smoothstep(.1, 1.0, ((uv - center) / radius).length())
