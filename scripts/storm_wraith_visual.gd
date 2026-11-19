extends "res://scripts/stalker_visual_prototype.gd"
## The drowned Hunter trails a delayed mantle and wind-driven hair.

const STORM_TEXTURE = "res://assets/visual_rebirth/storm/level_%02d_oblique.png"
const LANDMARKS = {
 1: [Vector2(114, 147), Vector2(235, 137), Vector2(167, 29), Vector2(174, 81)],
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return STORM_TEXTURE % level

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return Vector2(_draw_size().x * .5, EVOLVED_FLOOR.y)

func _draw_size() -> Vector2:
 return EVOLVED_SIZE if active_level == 1 else Vector2(432, 264)

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = LANDMARKS[active_level][SOCKET_LAYOUT.find(name)]
 return point / _draw_size()

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks: Array = LANDMARKS[active_level]
 var size := _draw_size()
 var pivot := _floor_pivot()
 var near: Vector2 = marks[0] / size
 var far: Vector2 = marks[1] / size
 var mouth: Vector2 = marks[2] / size
 var chest: Vector2 = marks[3] / size
 var phase := progress * TAU
 var positions := PackedVector2Array()
 positions.resize(points.size())
 for i in range(points.size()):
  var uv := points[i]
  var arms := _weight(uv, near - Vector2(0, .07), Vector2(.18, .27)) + _weight(uv, far - Vector2(0, .07), Vector2(.18, .27))
  var head := _weight(uv, mouth - Vector2(0, .056), Vector2(.13, .185))
  var hair := _weight(uv, mouth + Vector2(.13, -.05), Vector2(.27, .19))
  var coat := _weight(uv, chest + Vector2(.1, .28), Vector2(.42, .39))
  var offset := _storm_offset(uv, state, progress, phase, arms, head, hair, coat)
  positions[i] = uv * size - pivot + offset / EVOLVED_SCALE
 return positions

func _storm_offset(uv: Vector2, state: String, progress: float, phase: float, arms: float, head: float, hair: float, coat: float) -> Vector2:
 match state:
  "stalk":
   return Vector2(3.7 * coat * sin(phase - 1.1) + 2.8 * hair * sin(phase - .65) - arms * sin(phase), -1.1 * head * cos(phase))
  "turn":
   return Vector2(2.0 * head - 3.6 * coat + 3.1 * hair, -.85 * head) * progress
  "tell":
   return Vector2((uv.x - .5) * (11.2 * arms + 6.5 * coat) + 2.2 * hair, -7.1 * arms - 1.3 * head) * progress
  "strike":
   return Vector2(-4.8 * arms + 4.3 * coat + 4.0 * hair, 3.7 * arms - 2.75 * coat) * progress
  "guard":
   return Vector2(3.7 * coat + 1.4 * hair, -2.3 * arms - 2.6 * coat) * progress
  "hit":
   return Vector2(4.2 * head + 3.3 * hair, .85 * coat) * progress
  "recover":
   return Vector2(1.9 * hair - 2.5 * coat, 2.75 * head + 1.3 * arms) * progress
  "evolve":
   return Vector2((uv.x - .5) * (13.0 * coat + 6.0 * arms) + 2.4 * hair, -4.2 * coat - 2.8 * head) * sin(progress * PI)
  "vanish":
   return Vector2(7.3 * coat + 3.5 * hair, 6.1 * head + 2.6 * arms) * progress
  _:
   return Vector2(2.8 * coat * sin(phase - 1.2) + 2.1 * hair * sin(phase * 2.0 - .8), -.95 * head * cos(phase))
