extends "res://scripts/stalker_visual_prototype.gd"
## Short crouched gait and a model-driven pounce keep the predatory build
## grounded on the same floor grid as other Hunters.

const RAVAGER_TEXTURE = "res://assets/visual_rebirth/ravager/level_%02d_oblique.png"
const LANDMARKS = {
 1: [Vector2(74, 241), Vector2(195, 249), Vector2(133, 97), Vector2(165, 120)],
 2: [Vector2(93, 244), Vector2(197, 239), Vector2(151, 97), Vector2(167, 122)],
 3: [Vector2(86, 245), Vector2(204, 158), Vector2(149, 93), Vector2(166, 120)],
 4: [Vector2(36, 236), Vector2(180, 237), Vector2(126, 95), Vector2(164, 116)],
 5: [Vector2(68, 239), Vector2(194, 230), Vector2(128, 97), Vector2(158, 120)],
 6: [Vector2(90, 247), Vector2(191, 234), Vector2(169, 92), Vector2(170, 130)],
 7: [Vector2(53, 239), Vector2(166, 246), Vector2(136, 99), Vector2(155, 129)],
 8: [Vector2(61, 243), Vector2(191, 230), Vector2(130, 98), Vector2(167, 131)],
 9: [Vector2(78, 245), Vector2(241, 249), Vector2(159, 92), Vector2(176, 124)],
 10: [Vector2(95, 247), Vector2(203, 235), Vector2(175, 92), Vector2(178, 140)],
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return RAVAGER_TEXTURE % level

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return EVOLVED_FLOOR

func _draw_size() -> Vector2:
 return EVOLVED_SIZE

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = LANDMARKS[active_level][SOCKET_LAYOUT.find(name)]
 return point / EVOLVED_SIZE

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var positions := PackedVector2Array()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks: Array = LANDMARKS[active_level]
 var near: Vector2 = marks[0] / EVOLVED_SIZE
 var far: Vector2 = marks[1] / EVOLVED_SIZE
 var mouth: Vector2 = marks[2] / EVOLVED_SIZE
 var chest: Vector2 = marks[3] / EVOLVED_SIZE
 var wave := progress * TAU
 positions.resize(points.size())
 for i in range(points.size()):
  var uv := points[i]
  var front := _weight(uv, near - Vector2(0, .05), Vector2(.22, .32))
  var rear := _weight(uv, far - Vector2(0, .052), Vector2(.19, .29))
  var head := _weight(uv, mouth - Vector2(0, .045), Vector2(.18, .22))
  var back := _weight(uv, chest, Vector2(.31, .29))
  var stride := _weight(uv, Vector2(.58, .89), Vector2(.37, .2))
  var shift := _ravager_shift(uv, state, progress, wave, front, rear, head, back, stride)
  positions[i] = uv * EVOLVED_SIZE - EVOLVED_FLOOR + shift / EVOLVED_SCALE
 return positions

func _ravager_shift(uv: Vector2, state: String, progress: float, wave: float, front: float, rear: float, head: float, back: float, stride: float) -> Vector2:
 match state:
  "stalk":
   var step := sin(wave)
   return Vector2(-2.3 * head + (front - rear) * 2.9 * step + stride * 2.4 * sin(wave - .75), -1.5 * back * cos(wave) - stride * 2.1 * absf(step))
  "dash":
   var spring := sin(wave * .5)
   return Vector2(-7.1 * head - 6.2 * front + 3.5 * stride, -5.2 * back - 3.4 * stride + 1.4 * rear) * spring
  "turn":
   return Vector2(3.4 * head - 2.5 * back + 2.1 * rear, -1.15 * head) * progress
  "tell":
   return Vector2(3.2 * head + 2.25 * back - 2.3 * front, 3.7 * back - 4.4 * front) * progress
  "strike":
   return Vector2(-5.4 * head - 7.5 * front - 2.6 * rear + 2.4 * stride, 3.6 * front - 1.4 * rear) * progress
  "guard":
   return Vector2(1.5 * head + (uv.x - .5) * back * 10.2, -3.4 * back - 1.8 * rear) * progress
  "hit":
   return Vector2(4.15 * head + 1.45 * back, 2.3 * head - 1.6 * front) * progress
  "recover":
   return Vector2(2.1 * head - 1.7 * back, 3.5 * back + 2.05 * head) * progress
  "evolve":
   return Vector2((uv.x - .5) * (10.6 * back + 4.6 * front), -3.9 * back - 2.0 * head) * sin(progress * PI)
  "vanish":
   return Vector2(3.5 * stride - 2.2 * front, 6.7 * head + 4.6 * back) * progress
  _:
   return Vector2(.65 * head * sin(wave) + 1.1 * front * sin(wave - .6), -.9 * back * cos(wave))
