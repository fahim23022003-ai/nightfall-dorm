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
const CARDINAL_VIEWS = {
 1: {
  "front": [Vector2(68, 241), Vector2(193, 246), Vector2(131, 94), Vector2(137, 126)],
  "right": [Vector2(272, 252), Vector2(214, 234), Vector2(290, 95), Vector2(196, 125)],
  "back": [Vector2(226, 233), Vector2(69, 233), Vector2(184, 91), Vector2(172, 133)],
  "left": [Vector2(68, 247), Vector2(128, 229), Vector2(61, 99), Vector2(147, 132)],
 },
 2: {
  "front": [Vector2(103, 242), Vector2(184, 226), Vector2(143, 88), Vector2(164, 118)],
  "left": [Vector2(26, 235), Vector2(132, 244), Vector2(101, 86), Vector2(149, 125)],
  "back": [Vector2(268, 224), Vector2(107, 172), Vector2(202, 71), Vector2(167, 111)],
  "right": [Vector2(234, 240), Vector2(175, 225), Vector2(213, 87), Vector2(178, 126)],
 },
 3: {
  "front": [Vector2(87, 241), Vector2(201, 152), Vector2(145, 82), Vector2(168, 119)],
  "left": [Vector2(78, 241), Vector2(151, 151), Vector2(112, 86), Vector2(162, 122)],
  "back": [Vector2(246, 230), Vector2(104, 163), Vector2(192, 78), Vector2(163, 112)],
  "right": [Vector2(218, 246), Vector2(207, 151), Vector2(209, 84), Vector2(173, 129)],
 },
 4: {
  "front": [Vector2(92, 247), Vector2(190, 251), Vector2(163, 96), Vector2(163, 133)],
  "right": [Vector2(307, 253), Vector2(246, 230), Vector2(264, 95), Vector2(220, 132)],
  "back": [Vector2(278, 215), Vector2(101, 217), Vector2(192, 83), Vector2(166, 130)],
  "left": [Vector2(32, 242), Vector2(103, 245), Vector2(75, 100), Vector2(142, 133)],
 },
 5: {
  "front": [Vector2(82, 236), Vector2(189, 225), Vector2(126, 88), Vector2(157, 117)],
  "left": [Vector2(94, 245), Vector2(62, 219), Vector2(78, 88), Vector2(126, 121)],
  "back": [Vector2(273, 213), Vector2(106, 133), Vector2(196, 73), Vector2(190, 115)],
  "right": [Vector2(271, 239), Vector2(223, 211), Vector2(251, 86), Vector2(191, 125)],
 },
 6: {
  "front": [Vector2(99, 241), Vector2(193, 237), Vector2(172, 83), Vector2(178, 116)],
  "left": [Vector2(53, 235), Vector2(143, 244), Vector2(106, 83), Vector2(160, 122)],
  "back": [Vector2(247, 215), Vector2(123, 191), Vector2(171, 76), Vector2(165, 111)],
  "right": [Vector2(230, 245), Vector2(174, 226), Vector2(202, 79), Vector2(169, 118)],
 },
 7: {
  "front": [Vector2(92, 247), Vector2(188, 248), Vector2(141, 96), Vector2(142, 132)],
  "right": [Vector2(281, 250), Vector2(278, 231), Vector2(268, 94), Vector2(199, 121)],
  "back": [Vector2(254, 218), Vector2(60, 211), Vector2(159, 81), Vector2(163, 131)],
  "left": [Vector2(51, 243), Vector2(23, 219), Vector2(56, 98), Vector2(112, 129)],
 },
 8: {
  "front": [Vector2(72, 237), Vector2(190, 229), Vector2(133, 96), Vector2(158, 134)],
  "left": [Vector2(27, 230), Vector2(112, 243), Vector2(62, 95), Vector2(132, 130)],
  "back": [Vector2(274, 207), Vector2(111, 146), Vector2(190, 76), Vector2(184, 118)],
  "right": [Vector2(280, 244), Vector2(215, 221), Vector2(252, 91), Vector2(195, 126)],
 },
 9: {
  "front": [Vector2(86, 242), Vector2(239, 240), Vector2(157, 82), Vector2(165, 118)],
  "left": [Vector2(83, 241), Vector2(65, 217), Vector2(94, 86), Vector2(136, 119)],
  "back": [Vector2(260, 220), Vector2(69, 219), Vector2(185, 76), Vector2(175, 111)],
  "right": [Vector2(232, 245), Vector2(257, 216), Vector2(241, 84), Vector2(191, 120)],
 },
 10: {
  "front": [Vector2(77, 251), Vector2(197, 243), Vector2(169, 88), Vector2(170, 126)],
  "right": [Vector2(262, 250), Vector2(202, 229), Vector2(246, 87), Vector2(200, 126)],
  "back": [Vector2(224, 242), Vector2(110, 239), Vector2(164, 89), Vector2(169, 130)],
  "left": [Vector2(84, 247), Vector2(134, 248), Vector2(108, 87), Vector2(154, 130)],
 },
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return RAVAGER_TEXTURE % level

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
  if state in ["tell","strike","dash"]:
   if active_view == "right":shift.x = -shift.x
   elif active_view in ["front","back"]:shift.x *= .55
  positions[i] = uv * EVOLVED_SIZE - EVOLVED_FLOOR + shift / EVOLVED_SCALE
 return positions

func _ravager_shift(uv: Vector2, state: String, progress: float, wave: float, front: float, rear: float, head: float, back: float, stride: float) -> Vector2:
 match state:
  "stalk":
   var step := sin(wave)
   var reach := front * maxf(0.0, step) + rear * maxf(0.0, -step)
   var hind_step := sin(wave - .85)
   return Vector2(-2.0 * head + (front - rear) * 3.5 * step + stride * 2.8 * hind_step, -1.15 * back * cos(wave) - 3.1 * reach - stride * 2.3 * maxf(0.0,hind_step))
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
