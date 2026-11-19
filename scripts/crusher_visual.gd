extends "res://scripts/stalker_visual_prototype.gd"
## Crusher uses the same retained mesh and authoring canvas with its own
## weight map for the oversized forearms, feet, torn mantle and heavy gait.

const CRUSHER_TEXTURE = "res://assets/visual_rebirth/crusher/level_%02d_oblique.png"
# Foreground and off-hand contact, jaw and chest marked in canvas pixels.
const LANDMARKS = {
 1: [Vector2(248, 204), Vector2(88, 194), Vector2(201, 37), Vector2(177, 105)],
 2: [Vector2(207, 115), Vector2(100, 216), Vector2(183, 39), Vector2(182, 112)],
 3: [Vector2(222, 200), Vector2(107, 199), Vector2(174, 45), Vector2(188, 115)],
 4: [Vector2(240, 162), Vector2(103, 201), Vector2(196, 36), Vector2(174, 97)],
 5: [Vector2(85, 228), Vector2(188, 116), Vector2(194, 38), Vector2(154, 94)],
 6: [Vector2(249, 186), Vector2(79, 211), Vector2(193, 35), Vector2(176, 93)],
 7: [Vector2(224, 237), Vector2(98, 191), Vector2(170, 46), Vector2(177, 111)],
 8: [Vector2(159, 243), Vector2(141, 113), Vector2(161, 40), Vector2(158, 91)],
 9: [Vector2(66, 239), Vector2(184, 112), Vector2(196, 49), Vector2(157, 100)],
 10: [Vector2(80, 233), Vector2(204, 124), Vector2(188, 51), Vector2(160, 100)],
}

func _texture_path(level: int) -> String:
 return CRUSHER_TEXTURE % level

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
 var front_contact: Vector2 = marks[0] / EVOLVED_SIZE
 var other_contact: Vector2 = marks[1] / EVOLVED_SIZE
 var jaw: Vector2 = marks[2] / EVOLVED_SIZE
 var chest: Vector2 = marks[3] / EVOLVED_SIZE
 positions.resize(points.size())
 for i in range(points.size()):
  var uv := points[i]
  var near_arm := _weight(uv, front_contact - Vector2(0, .09), Vector2(.24, .40))
  var far_arm := _weight(uv, other_contact - Vector2(0, .08), Vector2(.21, .36))
  var head := _weight(uv, jaw - Vector2(0, .06), Vector2(.16, .23))
  var shoulders := _weight(uv, chest - Vector2(0, .2), Vector2(.38, .35))
  var shift := _crusher_shift(uv, state, progress, near_arm, far_arm, head, shoulders, signf(chest.x - front_contact.x))
  positions[i] = uv * EVOLVED_SIZE - EVOLVED_FLOOR + shift / EVOLVED_SCALE
 return positions

func _crusher_shift(uv: Vector2, state: String, progress: float, near_arm: float, far_arm: float, head: float, shoulders: float, inward: float) -> Vector2:
 var pulse := progress * TAU
 var back_foot := _weight(uv, Vector2(.61, .93), Vector2(.2, .19))
 var front_foot := _weight(uv, Vector2(.37, .94), Vector2(.2, .2))
 var ragged_hem := smoothstep(.55, .85, uv.y) * (1.0 - smoothstep(.9, 1.0, uv.y))
 match state:
  "stalk":
   var step := sin(pulse)
   var lift := 3.1 * (front_foot * maxf(0, step) + back_foot * maxf(0, -step))
   return Vector2((near_arm - far_arm) * 2.4 * step + ragged_hem * sin(pulse - .8), (1.7 * shoulders + head) * absf(step) - lift)
  "turn":
   return Vector2(3.0 * head - 1.2 * shoulders + (near_arm - far_arm) * 1.9, .8 * shoulders) * progress
  "tell":
   return Vector2(2.4 * shoulders - 2.8 * near_arm * inward + far_arm * inward, -8.2 * near_arm - 3.1 * far_arm - 2.3 * shoulders) * progress
  "strike":
   return Vector2(-3.0 * head - 3.8 * shoulders + 6.6 * near_arm * inward - 2.8 * far_arm * inward, 5.4 * near_arm + 3.8 * shoulders - 1.3 * far_arm) * progress
  "hit":
   return Vector2(4.2 * head + 2.9 * shoulders, -1.1 * shoulders + 1.3 * far_arm) * progress
  "recover":
   return Vector2(-1.9 * head + .8 * shoulders, 4.5 * shoulders + 1.6 * near_arm) * progress
  "guard":
   return Vector2(4.3 * inward * near_arm - 3.8 * inward * far_arm, -5.6 * near_arm - 4.3 * far_arm + 2.3 * shoulders) * progress
  "evolve":
   return Vector2((uv.x - .5) * (9.0 * shoulders + 4.5 * ragged_hem), -4.1 * head - 3.1 * shoulders) * sin(progress * PI)
  "vanish":
   return Vector2((-3.5 * shoulders - 4.0 * head), 9.5 * head + 6.1 * shoulders) * progress
  _:
   return Vector2(.9 * shoulders * sin(pulse) + .8 * ragged_hem * sin(pulse - .6), -1.3 * shoulders * cos(pulse) - .45 * near_arm * sin(pulse))
