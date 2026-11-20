extends "res://scripts/stalker_visual_prototype.gd"
## The drowned Hunter trails a delayed mantle and wind-driven hair.

const STORM_TEXTURE = "res://assets/visual_rebirth/storm/level_%02d_oblique.png"
const LANDMARKS = {
 1: [Vector2(114, 147), Vector2(235, 137), Vector2(167, 29), Vector2(174, 81)],
 2: [Vector2(130, 156), Vector2(205, 103), Vector2(208, 31), Vector2(221, 66)],
 3: [Vector2(122, 173), Vector2(288, 163), Vector2(198, 33), Vector2(231, 67)],
 4: [Vector2(134, 58), Vector2(320, 72), Vector2(220, 27), Vector2(231, 66)],
 5: [Vector2(193, 152), Vector2(321, 25), Vector2(191, 27), Vector2(211, 66)],
 6: [Vector2(125, 211), Vector2(297, 142), Vector2(176, 42), Vector2(207, 76)],
 7: [Vector2(139, 149), Vector2(283, 163), Vector2(192, 30), Vector2(207, 61)],
 8: [Vector2(130, 188), Vector2(352, 102), Vector2(190, 32), Vector2(209, 88)],
 9: [Vector2(117, 208), Vector2(313, 111), Vector2(193, 31), Vector2(221, 80)],
 10: [Vector2(152, 164), Vector2(314, 151), Vector2(224, 29), Vector2(234, 62)],
}
const CARDINAL_VIEWS = {
 1: {
  "front": [Vector2(109, 145), Vector2(235, 141), Vector2(172, 30), Vector2(174, 77)],
  "right": [Vector2(162, 144), Vector2(153, 124), Vector2(177, 34), Vector2(163, 76)],
  "back": [Vector2(222, 144), Vector2(96, 143), Vector2(163, 37), Vector2(164, 74)],
  "left": [Vector2(148, 151), Vector2(153, 128), Vector2(145, 28), Vector2(158, 74)],
 },
 2: {
  "front": [Vector2(140, 153), Vector2(210, 107), Vector2(213, 29), Vector2(222, 73)],
  "right": [Vector2(228, 143), Vector2(233, 97), Vector2(226, 28), Vector2(211, 79)],
  "back": [Vector2(298, 144), Vector2(174, 109), Vector2(220, 36), Vector2(212, 80)],
  "left": [Vector2(187, 101), Vector2(150, 148), Vector2(197, 29), Vector2(217, 69)],
 },
 3: {
  "front": [Vector2(129, 157), Vector2(272, 158), Vector2(207, 33), Vector2(219, 78)],
  "right": [Vector2(292, 161), Vector2(151, 143), Vector2(268, 27), Vector2(236, 79)],
  "back": [Vector2(312, 161), Vector2(145, 128), Vector2(226, 38), Vector2(210, 86)],
  "left": [Vector2(222, 155), Vector2(140, 159), Vector2(172, 31), Vector2(194, 78)],
 },
 4: {
  "front": [Vector2(138, 69), Vector2(300, 70), Vector2(216, 31), Vector2(219, 75)],
  "right": [Vector2(271, 69), Vector2(177, 86), Vector2(215, 34), Vector2(206, 74)],
  "back": [Vector2(295, 69), Vector2(136, 71), Vector2(211, 36), Vector2(213, 77)],
  "left": [Vector2(175, 72), Vector2(262, 87), Vector2(223, 34), Vector2(222, 74)],
 },
 5: {
  "front": [Vector2(196, 149), Vector2(320, 26), Vector2(212, 30), Vector2(220, 79)],
  "right": [Vector2(228, 148), Vector2(303, 35), Vector2(218, 25), Vector2(216, 76)],
  "back": [Vector2(252, 146), Vector2(101, 28), Vector2(218, 41), Vector2(220, 81)],
  "left": [Vector2(192, 144), Vector2(128, 45), Vector2(196, 28), Vector2(209, 74)],
 },
 6: {
  "front": [Vector2(145, 190), Vector2(307, 144), Vector2(208, 37), Vector2(220, 83)],
  "right": [Vector2(289, 181), Vector2(150, 136), Vector2(276, 32), Vector2(245, 80)],
  "back": [Vector2(321, 173), Vector2(146, 153), Vector2(244, 35), Vector2(220, 82)],
  "left": [Vector2(252, 161), Vector2(140, 188), Vector2(170, 33), Vector2(197, 89)],
 },
 7: {
  "front": [Vector2(161, 140), Vector2(270, 146), Vector2(221, 34), Vector2(222, 74)],
  "right": [Vector2(223, 137), Vector2(207, 118), Vector2(203, 33), Vector2(183, 76)],
  "back": [Vector2(286, 129), Vector2(144, 128), Vector2(218, 37), Vector2(218, 73)],
  "left": [Vector2(253, 151), Vector2(211, 137), Vector2(244, 33), Vector2(247, 78)],
 },
 8: {
  "front": [Vector2(135, 185), Vector2(328, 114), Vector2(206, 33), Vector2(203, 91)],
  "right": [Vector2(282, 179), Vector2(298, 104), Vector2(268, 32), Vector2(238, 85)],
  "back": [Vector2(331, 163), Vector2(115, 120), Vector2(252, 29), Vector2(236, 83)],
  "left": [Vector2(277, 114), Vector2(120, 185), Vector2(148, 34), Vector2(190, 81)],
 },
 9: {
  "front": [Vector2(130, 190), Vector2(309, 107), Vector2(203, 30), Vector2(217, 80)],
  "right": [Vector2(222, 181), Vector2(289, 102), Vector2(245, 30), Vector2(220, 72)],
  "back": [Vector2(332, 178), Vector2(159, 106), Vector2(235, 31), Vector2(242, 88)],
  "left": [Vector2(282, 119), Vector2(145, 164), Vector2(186, 30), Vector2(209, 79)],
 },
 10: {
  "front": [Vector2(156, 150), Vector2(297, 141), Vector2(221, 31), Vector2(238, 65)],
  "left": [Vector2(201, 153), Vector2(223, 126), Vector2(204, 27), Vector2(219, 68)],
  "back": [Vector2(122, 141), Vector2(288, 141), Vector2(215, 32), Vector2(223, 68)],
  "right": [Vector2(232, 150), Vector2(184, 128), Vector2(228, 29), Vector2(212, 63)],
 },
}

func supports(level: int, heading: Vector2) -> bool:
 return LANDMARKS.has(level) and super.supports(level, heading)

func _texture_path(level: int) -> String:
 return STORM_TEXTURE % level

func _cardinal_landmarks(level: int) -> Dictionary:
 return CARDINAL_VIEWS.get(level, {})

func _evolved_layout() -> Array:
 return _cardinal_landmarks(active_level)[active_view] if active_view != "" else LANDMARKS[active_level]

func _display_scale() -> Vector2:
 return EVOLVED_SCALE

func _floor_pivot() -> Vector2:
 return Vector2(_draw_size().x * .5, EVOLVED_FLOOR.y)

func _draw_size() -> Vector2:
 return EVOLVED_SIZE if active_level == 1 else Vector2(432, 264)

func _socket_uv(name: String) -> Vector2:
 var point: Vector2 = _evolved_layout()[SOCKET_LAYOUT.find(name)]
 return point / _draw_size()

func _pose_vertices(state: String, progress: float) -> PackedVector2Array:
 _prepare_topology()
 var points: PackedVector2Array = topology[Mesh.ARRAY_TEX_UV]
 var marks := _evolved_layout()
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
   var gust := sin(phase - .9 - uv.y * 1.75)
   return Vector2(4.1 * coat * gust + 2.9 * hair * sin(phase - .55 - uv.x) - arms * sin(phase), -1.2 * head * cos(phase) - 1.3 * coat * sin(phase-1.8))
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
