extends "res://scripts/stalker_visual_prototype.gd"
## The technician shares the retained pose surface with an electrically
## unsteady gait, wrist snap and secondary motion in the torn work coat.

const ELECTRIC_TEXTURE = "res://assets/visual_rebirth/electric/level_%02d_oblique.png"
# Near and far fingertips, mouth, and chest in the normalized canvas.
const LANDMARKS = {
 1: [Vector2(145, 163), Vector2(225, 133), Vector2(173, 37), Vector2(173, 72)],
 2: [Vector2(104, 180), Vector2(169, 117), Vector2(162, 40), Vector2(165, 78)],
 3: [Vector2(88, 167), Vector2(227, 111), Vector2(168, 40), Vector2(177, 80)],
 4: [Vector2(116, 174), Vector2(232, 124), Vector2(178, 38), Vector2(182, 81)],
 5: [Vector2(95, 171), Vector2(250, 61), Vector2(157, 39), Vector2(166, 87)],
 6: [Vector2(89, 190), Vector2(212, 163), Vector2(167, 38), Vector2(173, 99)],
 7: [Vector2(99, 163), Vector2(224, 148), Vector2(174, 36), Vector2(179, 80)],
 8: [Vector2(75, 175), Vector2(262, 126), Vector2(132, 40), Vector2(128, 92)],
 9: [Vector2(93, 184), Vector2(247, 158), Vector2(167, 44), Vector2(178, 88)],
 10: [Vector2(91, 178), Vector2(262, 115), Vector2(163, 35), Vector2(161, 86)],
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return ELECTRIC_TEXTURE % level

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return EVOLVED_FLOOR

func _draw_size() -> Vector2:
 return EVOLVED_SIZE

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = LANDMARKS.get(active_level, LANDMARKS[1])[SOCKET_LAYOUT.find(name)]
 return point / EVOLVED_SIZE

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var positions := PackedVector2Array()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks: Array = LANDMARKS.get(active_level, LANDMARKS[1])
 var near: Vector2 = marks[0] / EVOLVED_SIZE
 var far: Vector2 = marks[1] / EVOLVED_SIZE
 var mouth: Vector2 = marks[2] / EVOLVED_SIZE
 var chest: Vector2 = marks[3] / EVOLVED_SIZE
 positions.resize(points.size())
 for i in range(points.size()):
  var uv := points[i]
  var near_hand := _weight(uv, near - Vector2(0, .04), Vector2(.19, .29))
  var far_hand := _weight(uv, far - Vector2(0, .04), Vector2(.19, .27))
  var hair := _weight(uv, mouth - Vector2(0, .08), Vector2(.22, .26))
  var torso := _weight(uv, chest, Vector2(.27, .34))
  var shift := _electric_shift(uv, state, progress, near_hand, far_hand, hair, torso, signf(near.x - far.x))
  positions[i] = uv * EVOLVED_SIZE - EVOLVED_FLOOR + shift / EVOLVED_SCALE
 return positions

func _electric_shift(uv: Vector2, state: String, progress: float, near_hand: float, far_hand: float, hair: float, torso: float, hand_side: float) -> Vector2:
 var cycle := progress * TAU
 var coat_tail := smoothstep(.46, .76, uv.y) * (1.0 - smoothstep(.89, .99, uv.y))
 match state:
  "stalk":
   var swing := sin(cycle)
   var stumble := sin(cycle * 2.0 + .38) * torso
   return Vector2(1.5 * torso * swing + 2.4 * (near_hand - far_hand) * swing + 2.3 * coat_tail * sin(cycle - .8), -.85 * stumble - .65 * hair * swing)
  "turn":
   return Vector2(2.3 * hair - 1.65 * torso + 1.1 * coat_tail, -.7 * hair) * progress
  "tell":
   return Vector2(1.4 * hair + 2.5 * hand_side * (near_hand - far_hand), -5.6 * near_hand - 4.1 * far_hand + .9 * torso) * progress
  "strike":
   return Vector2(4.8 * hand_side * near_hand - 3.2 * hand_side * far_hand - 1.9 * hair, -4.1 * near_hand - .9 * far_hand + .85 * torso) * progress
  "guard":
   return Vector2(-1.75 * hand_side * (near_hand - far_hand) + 2.6 * hair, -3.4 * (near_hand + far_hand) + 1.7 * torso) * progress
  "hit":
   return Vector2(3.65 * hair + 2.3 * torso, 1.5 * (near_hand - far_hand)) * progress
  "recover":
   return Vector2(1.5 * hair - 1.3 * torso, 2.4 * hair + 1.35 * torso) * progress
  "evolve":
   return Vector2((uv.x - .5) * (9.5 * torso + 5.5 * coat_tail), -2.9 * hair - 2.1 * torso) * sin(progress * PI)
  "vanish":
   return Vector2(-2.4 * hair + 3.8 * coat_tail, 8.0 * hair + 4.1 * torso) * progress
  _:
   return Vector2(.9 * hair * sin(cycle * 3.0) + 1.15 * coat_tail * sin(cycle - 1.2), -.8 * torso * cos(cycle))
