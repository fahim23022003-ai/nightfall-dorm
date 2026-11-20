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
const CARDINAL_VIEWS = {
 1: {
  "front": [Vector2(128, 144), Vector2(217, 132), Vector2(159, 36), Vector2(164, 73)],
  "right": [Vector2(195, 141), Vector2(208, 124), Vector2(197, 35), Vector2(171, 77)],
  "back": [Vector2(102, 133), Vector2(211, 136), Vector2(171, 34), Vector2(162, 76)],
  "left": [Vector2(143, 147), Vector2(111, 129), Vector2(131, 35), Vector2(160, 81)],
 },
 2: {
  "front": [Vector2(115, 180), Vector2(174, 117), Vector2(159, 38), Vector2(164, 76)],
  "right": [Vector2(211, 172), Vector2(207, 117), Vector2(213, 37), Vector2(187, 66)],
  "back": [Vector2(215, 165), Vector2(119, 98), Vector2(171, 27), Vector2(160, 67)],
  "left": [Vector2(110, 175), Vector2(128, 118), Vector2(112, 39), Vector2(155, 78)],
 },
 3: {
  "front": [Vector2(75, 165), Vector2(219, 115), Vector2(168, 37), Vector2(170, 77)],
  "right": [Vector2(226, 166), Vector2(215, 109), Vector2(210, 36), Vector2(183, 76)],
  "back": [Vector2(252, 151), Vector2(115, 110), Vector2(172, 24), Vector2(164, 70)],
  "left": [Vector2(56, 162), Vector2(137, 119), Vector2(121, 35), Vector2(148, 74)],
 },
 4: {
  "front": [Vector2(109, 159), Vector2(229, 132), Vector2(171, 37), Vector2(173, 79)],
  "right": [Vector2(209, 144), Vector2(230, 124), Vector2(212, 36), Vector2(185, 82)],
  "back": [Vector2(231, 144), Vector2(96, 129), Vector2(167, 36), Vector2(162, 77)],
  "left": [Vector2(133, 143), Vector2(108, 130), Vector2(132, 39), Vector2(153, 80)],
 },
 5: {
  "front": [Vector2(102, 180), Vector2(263, 56), Vector2(162, 38), Vector2(164, 78)],
  "right": [Vector2(186, 181), Vector2(256, 61), Vector2(202, 32), Vector2(183, 71)],
  "back": [Vector2(233, 175), Vector2(64, 53), Vector2(177, 28), Vector2(164, 66)],
  "left": [Vector2(83, 180), Vector2(225, 65), Vector2(114, 32), Vector2(146, 77)],
 },
 6: {
  "front": [Vector2(92, 186), Vector2(214, 161), Vector2(169, 36), Vector2(168, 77)],
  "right": [Vector2(132, 186), Vector2(144, 169), Vector2(182, 35), Vector2(157, 72)],
  "back": [Vector2(231, 181), Vector2(105, 170), Vector2(169, 29), Vector2(163, 72)],
  "left": [Vector2(167, 174), Vector2(163, 164), Vector2(139, 37), Vector2(163, 76)],
 },
 7: {
  "front": [Vector2(101, 151), Vector2(231, 153), Vector2(167, 35), Vector2(166, 83)],
  "right": [Vector2(211, 153), Vector2(204, 136), Vector2(203, 34), Vector2(182, 81)],
  "back": [Vector2(228, 147), Vector2(100, 146), Vector2(163, 35), Vector2(160, 75)],
  "left": [Vector2(143, 145), Vector2(151, 132), Vector2(154, 36), Vector2(170, 83)],
 },
 8: {
  "front": [Vector2(155, 175), Vector2(340, 122), Vector2(222, 40), Vector2(221, 81)],
  "right": [Vector2(219, 174), Vector2(314, 118), Vector2(262, 37), Vector2(235, 78)],
  "back": [Vector2(281, 169), Vector2(99, 117), Vector2(234, 30), Vector2(223, 69)],
  "left": [Vector2(257, 125), Vector2(171, 160), Vector2(177, 39), Vector2(209, 78)],
 },
 9: {
  "front": [Vector2(90, 166), Vector2(243, 163), Vector2(172, 32), Vector2(170, 74)],
  "right": [Vector2(195, 157), Vector2(187, 150), Vector2(185, 36), Vector2(165, 75)],
  "back": [Vector2(240, 163), Vector2(96, 163), Vector2(178, 28), Vector2(166, 69)],
  "left": [Vector2(147, 158), Vector2(124, 162), Vector2(140, 35), Vector2(160, 78)],
 },
 10: {
  "front": [Vector2(84, 151), Vector2(249, 120), Vector2(166, 38), Vector2(170, 80)],
  "right": [Vector2(237, 116), Vector2(120, 110), Vector2(194, 39), Vector2(180, 81)],
  "back": [Vector2(239, 140), Vector2(79, 123), Vector2(165, 39), Vector2(170, 77)],
  "left": [Vector2(179, 137), Vector2(104, 108), Vector2(147, 42), Vector2(155, 76)],
 },
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return ELECTRIC_TEXTURE % level

func _cardinal_landmarks(level: int) -> Dictionary:
 return CARDINAL_VIEWS.get(level, {})

func _evolved_layout() -> Array:
 return _cardinal_landmarks(active_level)[active_view] if active_view != "" else LANDMARKS[active_level]

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return Vector2(_draw_size().x * .5, EVOLVED_FLOOR.y)

func _draw_size() -> Vector2:
 if active_level == 8 and active_view != "":
  return Vector2(432, EVOLVED_SIZE.y)
 return EVOLVED_SIZE

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = _evolved_layout()[SOCKET_LAYOUT.find(name)]
 return point / _draw_size()

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var positions := PackedVector2Array()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks := _evolved_layout()
 var size := _draw_size()
 var pivot := _floor_pivot()
 var near: Vector2 = marks[0] / size
 var far: Vector2 = marks[1] / size
 var mouth: Vector2 = marks[2] / size
 var chest: Vector2 = marks[3] / size
 positions.resize(points.size())
 for i in range(points.size()):
  var uv := points[i]
  var near_hand := _weight(uv, near - Vector2(0, .04), Vector2(.19, .29))
  var far_hand := _weight(uv, far - Vector2(0, .04), Vector2(.19, .27))
  var hair := _weight(uv, mouth - Vector2(0, .08), Vector2(.22, .26))
  var torso := _weight(uv, chest, Vector2(.27, .34))
  var shift := _electric_shift(uv, state, progress, near_hand, far_hand, hair, torso, signf(near.x - far.x))
  positions[i] = uv * size - pivot + shift / EVOLVED_SCALE
 return positions

func _electric_shift(uv: Vector2, state: String, progress: float, near_hand: float, far_hand: float, hair: float, torso: float, hand_side: float) -> Vector2:
 var cycle := progress * TAU
 var coat_tail := smoothstep(.46, .76, uv.y) * (1.0 - smoothstep(.89, .99, uv.y))
 match state:
  "stalk":
   var swing := sin(cycle)
   var stumble := sin(cycle * 2.0 + .38) * torso
   var twitch := sin(cycle*3.0+.38) * pow(maxf(0.0,swing),2.0)
   return Vector2(1.5 * torso * swing + 2.4 * (near_hand - far_hand) * swing + 2.6 * coat_tail * sin(cycle - 1.15), -.85 * stumble - .65 * hair * swing - 2.3 * near_hand * twitch + far_hand * twitch)
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
