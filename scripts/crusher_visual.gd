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
const CARDINAL_VIEWS = {
 1: {
  "front": [Vector2(99, 209), Vector2(245, 205), Vector2(188, 48), Vector2(177, 94)],
  "right": [Vector2(193, 221), Vector2(220, 196), Vector2(242, 43), Vector2(198, 91)],
  "back": [Vector2(102, 200), Vector2(243, 199), Vector2(163, 36), Vector2(175, 95)],
  "left": [Vector2(154, 211), Vector2(111, 197), Vector2(106, 47), Vector2(156, 97)],
 },
 2: {
  "front": [Vector2(203, 107), Vector2(102, 212), Vector2(181, 44), Vector2(177, 87)],
  "right": [Vector2(173, 223), Vector2(216, 106), Vector2(230, 44), Vector2(196, 89)],
  "back": [Vector2(97, 69), Vector2(219, 184), Vector2(136, 33), Vector2(158, 90)],
  "left": [Vector2(112, 108), Vector2(75, 205), Vector2(91, 44), Vector2(128, 86)],
 },
 3: {
  "front": [Vector2(218, 196), Vector2(98, 194), Vector2(164, 52), Vector2(168, 90)],
  "right": [Vector2(251, 186), Vector2(181, 203), Vector2(238, 45), Vector2(208, 80)],
  "back": [Vector2(92, 189), Vector2(238, 198), Vector2(162, 28), Vector2(166, 86)],
  "left": [Vector2(70, 204), Vector2(112, 152), Vector2(83, 51), Vector2(127, 90)],
 },
 4: {
  "front": [Vector2(92, 209), Vector2(229, 191), Vector2(164, 44), Vector2(168, 89)],
  "right": [Vector2(186, 218), Vector2(223, 191), Vector2(232, 43), Vector2(188, 89)],
  "back": [Vector2(240, 203), Vector2(95, 195), Vector2(164, 32), Vector2(168, 90)],
  "left": [Vector2(153, 190), Vector2(110, 193), Vector2(110, 45), Vector2(165, 95)],
 },
 5: {
  "front": [Vector2(81, 223), Vector2(195, 119), Vector2(186, 49), Vector2(172, 97)],
  "right": [Vector2(149, 240), Vector2(210, 120), Vector2(224, 43), Vector2(169, 83)],
  "back": [Vector2(247, 213), Vector2(112, 152), Vector2(143, 33), Vector2(166, 93)],
  "left": [Vector2(80, 222), Vector2(144, 118), Vector2(111, 45), Vector2(131, 84)],
 },
 6: {
  "front": [Vector2(229, 190), Vector2(83, 208), Vector2(182, 50), Vector2(178, 87)],
  "right": [Vector2(236, 151), Vector2(145, 223), Vector2(196, 46), Vector2(180, 88)],
  "back": [Vector2(94, 159), Vector2(255, 198), Vector2(157, 36), Vector2(164, 87)],
  "left": [Vector2(105, 178), Vector2(145, 137), Vector2(128, 42), Vector2(156, 83)],
 },
 7: {
  "front": [Vector2(229, 218), Vector2(104, 205), Vector2(170, 48), Vector2(176, 91)],
  "right": [Vector2(174, 215), Vector2(198, 210), Vector2(211, 48), Vector2(160, 97)],
  "back": [Vector2(101, 208), Vector2(225, 198), Vector2(171, 38), Vector2(163, 93)],
  "left": [Vector2(149, 234), Vector2(117, 194), Vector2(110, 47), Vector2(164, 95)],
 },
 8: {
  "front": [Vector2(163, 246), Vector2(143, 119), Vector2(154, 52), Vector2(157, 91)],
  "right": [Vector2(251, 221), Vector2(175, 124), Vector2(218, 41), Vector2(194, 86)],
  "back": [Vector2(33, 200), Vector2(234, 152), Vector2(164, 35), Vector2(157, 81)],
  "left": [Vector2(103, 243), Vector2(127, 106), Vector2(105, 43), Vector2(147, 84)],
 },
 9: {
  "front": [Vector2(69, 237), Vector2(182, 111), Vector2(188, 53), Vector2(164, 90)],
  "right": [Vector2(115, 240), Vector2(170, 108), Vector2(196, 44), Vector2(158, 89)],
  "back": [Vector2(258, 228), Vector2(117, 112), Vector2(145, 36), Vector2(165, 88)],
  "left": [Vector2(94, 236), Vector2(123, 109), Vector2(111, 46), Vector2(158, 91)],
 },
 10: {
  "front": [Vector2(77, 234), Vector2(194, 137), Vector2(170, 43), Vector2(143, 88)],
  "right": [Vector2(150, 244), Vector2(218, 134), Vector2(247, 52), Vector2(183, 91)],
  "back": [Vector2(244, 237), Vector2(102, 112), Vector2(147, 34), Vector2(154, 90)],
  "left": [Vector2(215, 225), Vector2(102, 138), Vector2(90, 52), Vector2(137, 92)],
 },
}

func _texture_path(level: int) -> String:
 return CRUSHER_TEXTURE % level

func _cardinal_landmarks(level: int) -> Dictionary:
 return CARDINAL_VIEWS.get(level, {})

func _evolved_layout() -> Array:
 return _cardinal_landmarks(active_level)[active_view] if active_view != "" else LANDMARKS[active_level]

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return EVOLVED_FLOOR

func _draw_size() -> Vector2:
 return EVOLVED_SIZE

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = _evolved_layout()[SOCKET_LAYOUT.find(name)]
 return point / EVOLVED_SIZE

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var positions := PackedVector2Array()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks := _evolved_layout()
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
   var planted := absf(cos(pulse))
   var lift := 3.8 * front_foot * maxf(0, step) + 2.1 * back_foot * maxf(0, -step)
   var drag := near_arm * sin(pulse-.53) - far_arm * sin(pulse-.92)
   return Vector2(3.0 * drag + shoulders * cos(pulse) + ragged_hem * sin(pulse - .8), (2.2 * shoulders + head) * planted - lift)
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
