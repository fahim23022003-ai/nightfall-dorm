extends RefCounted
## Witch turnaround and evolution sprites share a floor pivot and deformation grid.

const ART_PATH = "res://assets/visual_rebirth/witch/level_%02d_%s.png"
const ART_SCALE = 104.0 / 256.0
const BASE_WIDTH = 216.0
const EVOLVED_WIDTH = 328.0
const ART_HEIGHT = 264.0
const FOOT = 260.0
const GRID = Vector2i(12, 16)
const FRAME_COUNT = 16
const FACING_DEADBAND = .18

var enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var textures: Dictionary = {}
var poses: Dictionary = {}
var projection_sign := 1.0

func supports(level: int) -> bool:
 return enabled and texture_for(level, "oblique") != null

func texture_for(level: int, direction: String) -> Texture2D:
 var path := ART_PATH % [level, direction]
 if not textures.has(path):
  textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
 return textures[path]

func facing(heading: Vector2) -> String:
 if heading.x < -.45 and heading.y > .45:
  return "oblique"
 if absf(heading.x) > absf(heading.y):
  return "left" if heading.x < 0 else "right"
 return "back" if heading.y < 0 else "front"

func draw(canvas: CanvasItem, floor: Vector2, tint: Color, level: int, heading: Vector2, state: String, progress: float, reduced: bool) -> bool:
 var direction := facing(heading)
 var texture := texture_for(level, direction)
 var projection := 1.0
 if texture == null:
  direction = "oblique"
  texture = texture_for(level, direction)
  if absf(heading.x) > FACING_DEADBAND:
   projection_sign = -signf(heading.x)
  projection = projection_sign
 if texture == null:
  return false
 var step := 0 if reduced else roundi(clampf(progress, 0.0, 1.0) * FRAME_COUNT)
 var gesture_side := -1 if direction == "right" else 1
 var width := BASE_WIDTH if level == 1 else EVOLVED_WIDTH
 var key := "%s:%d:%d:%d" % [state, step, gesture_side, int(width)]
 if not poses.has(key):
  poses[key] = build_pose(state, float(step) / FRAME_COUNT, gesture_side, width)
 canvas.draw_mesh(poses[key], texture, Transform2D(0.0, Vector2(projection, 1.0), 0.0, floor), tint)
 return true

func build_pose(state: String, progress: float, gesture_side: int, width: float = BASE_WIDTH) -> ArrayMesh:
 var vertices := PackedVector2Array()
 var uvs := PackedVector2Array()
 var triangles := PackedInt32Array()
 for row in range(GRID.y + 1):
  for column in range(GRID.x + 1):
   var uv := Vector2(float(column) / GRID.x, float(row) / GRID.y)
   uvs.append(uv)
   var anchor := (uv * Vector2(width, ART_HEIGHT) - Vector2(width * .5, FOOT)) * ART_SCALE
   var part_uv := uv if gesture_side > 0 else Vector2(1.0 - uv.x, uv.y)
   var offset := deformation(part_uv, state, progress)
   vertices.append(anchor + Vector2(offset.x * gesture_side, offset.y))
   if column < GRID.x and row < GRID.y:
    var first := row * (GRID.x + 1) + column
    var lower := first + GRID.x + 1
    triangles.append_array([first, first + 1, lower, first + 1, lower + 1, lower])
 var surface := []
 surface.resize(Mesh.ARRAY_MAX)
 surface[Mesh.ARRAY_VERTEX] = vertices
 surface[Mesh.ARRAY_TEX_UV] = uvs
 surface[Mesh.ARRAY_INDEX] = triangles
 var pose := ArrayMesh.new()
 pose.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
 return pose

func deformation(uv: Vector2, state: String, progress: float) -> Vector2:
 var veil := smoothstep(.48, .94, uv.x) * (1.0 - smoothstep(.15, .46, uv.y))
 var skirt := smoothstep(.48, .94, uv.y)
 var gesture := (1.0 - smoothstep(.17, .45, uv.x)) * (1.0 - smoothstep(.05, .27, absf(uv.y - .35)))
 var crown := 1.0 - smoothstep(.08, .62, uv.y)
 var phase := progress * TAU
 match state:
  "tell":
   return Vector2((-4.0 * gesture + 2.0 * veil) * progress, (-5.0 * gesture + skirt) * progress)
  "release":
   var impulse := sin(progress * PI)
   return Vector2((-8.0 * gesture + 2.5 * veil + skirt) * impulse, (-3.0 * crown - 2.0 * gesture) * impulse)
  "hit":
   return Vector2(4.0 * crown * progress, 2.0 * crown * progress)
  "evolve":
   var pulse := sin(progress * PI)
   return Vector2((uv.x - .5) * (2.0 * skirt + 4.0 * veil) * pulse, -4.0 * crown * pulse)
  "vanish":
   return Vector2((uv.x - .5) * -7 * progress, crown * 9.0 * progress)
  _:
   return Vector2(veil * 2.4 * sin(phase - .65) + skirt * 2.0 * sin(phase - 1.3), -crown * .8 * cos(phase))
