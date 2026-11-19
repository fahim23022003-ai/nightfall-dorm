extends RefCounted
## One-view Level 1 proof. Independent directional artwork and later levels
## stay on the current renderer until they have passed their own visual checks.

const TEXTURE_PATH = "res://assets/visual_rebirth/stalker/level_01_left_prototype.png"
const DRAW_SIZE = Vector2(48.4, 140.8)
const FLOOR_PIVOT = Vector2(23.5, 140.0)
const GRID = Vector2i(12, 22)
const STEPS = 16
const POSES = ["idle", "stalk", "tell", "strike", "hit", "vanish"]

var enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var texture: Texture2D
var frames: Dictionary = {}

func supports(level: int, heading: Vector2) -> bool:
 var facing_preview := heading.x <= -.55 or (heading.x <= .15 and heading.y > .55)
 return enabled and level == 1 and facing_preview

func draw(canvas: CanvasItem, floor: Vector2, tint: Color, state: String, progress: float, angle: float) -> bool:
 if texture == null:
  texture = load(TEXTURE_PATH) as Texture2D
  if texture == null:
   enabled = false
   return false
 var frame := roundi(clampf(progress, 0.0, 1.0) * STEPS)
 var key := Vector2i(POSES.find(state), frame)
 if not frames.has(key):
  frames[key] = _mesh(state, float(frame) / STEPS)
 canvas.draw_mesh(frames[key], texture, Transform2D(angle, floor), tint)
 return true

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
 var phase := progress * TAU
 match state:
  "stalk":
   var step := sin(phase)
   var next_step := cos(phase)
   return Vector2(-2.0 * upper + 1.4 * hair * next_step + 2.5 * hem * step + 2.4 * (near_hand - far_hand) * step, -1.7 * upper * next_step)
  "tell":
   return Vector2((2.8 * upper - 3.0 * near_hand - 1.6 * far_hand) * progress, (-1.3 * upper - 6.5 * near_hand) * progress)
  "strike":
   return Vector2((-7.0 * upper - 5.0 * near_hand - 3.0 * far_hand + 2.0 * hem) * progress, (-2.0 * upper - 5.0 * near_hand - 2.2 * far_hand) * progress)
  "hit":
   return Vector2((5.0 * upper - 2.3 * hair) * progress, 2.5 * upper * progress)
  "vanish":
   return Vector2((upper * 4.5 - 2.2 * hair - 3.0 * hem) * progress, (upper * 10.0 + 1.5 * hem) * progress)
  _:
   return Vector2(upper * sin(phase) + 1.8 * hair * sin(phase - .7) + 1.2 * hem * sin(phase - 1.0), -1.3 * upper * cos(phase))

func _weight(uv: Vector2, center: Vector2, radius: Vector2) -> float:
 return 1.0 - smoothstep(.1, 1.0, ((uv - center) / radius).length())
