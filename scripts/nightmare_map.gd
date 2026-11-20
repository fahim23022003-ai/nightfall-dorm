class_name NightmareMap
extends RefCounted
## Stable seeded geometry. Checkpoints store the generated topology and
## coordinates so a resumed match never depends on the generator's RNG.
const VERSION := 1
const MACRO_VERSION := 2
const CLOSE_QUARTERS_VERSION := 3
const MAX_MACRO_NODES := 160
const MAX_MACRO_LANES := 224
const DOOR_HALF_WIDTH := 36.0
const SHAPES := ["rectangle", "long", "l", "u", "zigzag"]
const MASKS := [511, 511, 7 | (7 << 3) | (1 << 6), 5 | (7 << 3) | (7 << 6), 3 | (7 << 3) | (6 << 6)]
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const HALL_IDS := ["north", "south", "west", "east"]
const ROOM_COUNT := 6
const LANE_WIDTH := 96.0
const LIMIT := 8192.0

static func generate(id: String, seed: int) -> Dictionary:
 var theme := MapCatalog.map(id)
 if theme.is_empty():
  return {}
 var rng := RandomNumberGenerator.new()
 rng.seed = seed ^ hash(id)
 var shapes := [0, 1, 2, 3, 4, rng.randi_range(0, 4)]
 for i in range(5, 0, -1):
  var j := rng.randi_range(0, i)
  var old: int = shapes[i]
  shapes[i] = shapes[j]
  shapes[j] = old
 var xs := [0.0]
 var ys := [0.0]
 for i in range(3):
  xs.append(xs.back() + 16.0 * rng.randi_range(35, 40))
 for j in range(2):
  ys.append(ys.back() + 16.0 * rng.randi_range(35, 40))
 var data := {
  "version": VERSION, "seed": seed, "id": id, "title": theme.title, "theme": theme.theme,
  "rooms": [], "nodes": [], "lane_links": [], "corridors": [], "halls": {}
 }
 for y in ys:
  for x in xs:
   _node(data, Vector2(x, y))
 for j in range(3):
  for i in range(4):
   var index := j * 4 + i
   if i < 3:
    _link(data, index, index + 1)
   if j < 2:
    _link(data, index, index + 4)

 # Lots are shuffled independently of shapes, so an ID doesn't inherit a
 # permanent flank, range to Hunter spawn, or corner location.
 var lots := [0, 1, 2, 3, 4, 5]
 for i in range(5, 0, -1):
  var j := rng.randi_range(0, i)
  var old: int = lots[i]
  lots[i] = lots[j]
  lots[j] = old
 for index in range(ROOM_COUNT):
  var lot_id: int = lots[index]
  var col := lot_id % 3
  var row := int(lot_id / 3.0)
  var lot := Rect2(xs[col], ys[row], xs[col + 1] - xs[col], ys[row + 1] - ys[row])
  var layout := _room(rng, shapes[index], lot)
  data.rooms.append(layout)
  var side: Vector2 = layout.door_normal
  var end: Vector2 = layout.anchor
  var along_start := row * 4 + col
  if side == Vector2.RIGHT:
   along_start += 1
  elif side == Vector2.DOWN:
   along_start += 4
  var along_end := along_start + (1 if side.x == 0.0 else 4)
  var anchor_node := _node(data, end)
  _link(data, along_start, anchor_node)
  _link(data, anchor_node, along_end)
  _link(data, anchor_node, _node(data, layout.approach))

 var east: float = xs.back()
 var south: float = ys.back()
 _hall(data, "north", Vector2(east * 0.5, ys[0]), Vector2.UP, 2, 1)
 _hall(data, "south", Vector2(east * 0.5, ys[2]), Vector2.DOWN, 9, 10)
 _hall(data, "west", Vector2(xs[0], ys[1]), Vector2.LEFT, 4)
 _hall(data, "east", Vector2(xs[3], ys[1]), Vector2.RIGHT, 7)
 # Use central junctions rather than a point tied to a room ID or trait.
 var upper: Vector2 = data.nodes[5]
 var lower: Vector2 = data.nodes[6]
 data.spawn = upper if rng.randi_range(0, 1) == 0 else lower
 data.hunter_spawn = Vector2(east, 0) if data.spawn == upper else Vector2(0, south)
 data.bounds = Rect2(-282.0, -282.0, east + 564.0, south + 564.0)
 return data

static func _room(rng: RandomNumberGenerator, shape_index: int, lot: Rect2, facing: int=-1) -> Dictionary:
 var mask: int = MASKS[shape_index]
 var turn := rng.randi_range(0, 3)
 for i in range(turn):
  var next := 0
  for y in range(3):
   for x in range(3):
    if _occupied(mask, x, y):
     next |= 1 << (x * 3 + 2 - y)
  mask = next
 var w := [16.0 * rng.randi_range(7, 9), 16.0 * rng.randi_range(7, 9), 16.0 * rng.randi_range(7, 9)]
 var h := [16.0 * rng.randi_range(7, 9), 16.0 * rng.randi_range(7, 9), 16.0 * rng.randi_range(7, 9)]
 if shape_index == 1:
  w = [144.0, 144.0, 144.0]
  h = [80.0, 112.0, 80.0]
  if turn % 2 == 1:
   var swap := w
   w = h
   h = swap
 var size := Vector2(w[0] + w[1] + w[2], h[0] + h[1] + h[2])
 # Keep visible circulation on all four sides while moving the room off the
 # lot center. Every door faces an exterior lane, including recess layouts.
 var slack := Vector2i((lot.size - size - Vector2.ONE * 128.0) / 16.0)
 var start := lot.position + Vector2.ONE * 64.0 + Vector2(
   rng.randi_range(0, maxi(0, slack.x)), rng.randi_range(0, maxi(0, slack.y))) * 16.0
 var bounds := Rect2(start, size)
 var xs := [start.x, start.x + w[0], start.x + w[0] + w[1], bounds.end.x]
 var ys := [start.y, start.y + h[0], start.y + h[0] + h[1], bounds.end.y]
 var normal: Vector2i = DIRECTIONS[rng.randi_range(0, 3) if facing<0 else facing]
 var choices: Array[Vector2i] = []
 for y in range(3):
  for x in range(3):
   if _occupied(mask, x, y) and not _bounded_cell(x + normal.x, y + normal.y):
    choices.append(Vector2i(x, y))
 var door_cell: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
 var door_strip := _band_cell(xs, ys, door_cell.x, door_cell.y)
 var door := door_strip.get_center() + Vector2(normal) * door_strip.size * 0.5
 var approach := door + Vector2(normal) * 24.0
 var anchor := door
 if normal.x != 0:
  anchor.x = lot.position.x if normal.x < 0 else lot.end.x
 else:
  anchor.y = lot.position.y if normal.y < 0 else lot.end.y
 var bed := _band_cell(xs, ys, 1, 1).get_center()
 var path := _access_cells(mask, door_cell)
 var spare: Array[Vector2i] = []
 var interior: Array[Vector2] = [door - Vector2(normal) * 24.0]
 for y in range(3):
  for x in range(3):
   if not _occupied(mask, x, y):
    continue
   var tile := Vector2i(x, y)
   if not path.has(tile):
    spare.append(tile)
   var center := _band_cell(xs, ys, x, y).get_center()
   if tile != Vector2i.ONE:
    interior.append(center)
 # The two furnishing cells are away from the reserved approach. Anchors
 # remain inside each cell even at the shortest band length.
 var cabinet_cell := _band_cell(xs, ys, spare[0].x, spare[0].y)
 var plant_cell := _band_cell(xs, ys, spare.back().x, spare.back().y)
 var cabinet := cabinet_cell.get_center() + Vector2(-20, -32)
 var plant := plant_cell.get_center() + Vector2(20, -29)
 var via: Array[Vector2] = [door - Vector2(normal) * 35.0]
 for cell in path:
  via.append(_band_cell(xs, ys, cell.x, cell.y).get_center())
 var near_bed := bed + (via[-2] - bed).normalized() * 58.0
 via[-1] = near_bed
 interior.append(near_bed)
 var route: Array[Rect2] = []
 for i in range(1, via.size()):
  route.append(_segment(via[i - 1], via[i], 28.0))
 var layout := {
  "bounds": bounds, "shape": SHAPES[shape_index], "bands_x": w, "bands_y": h, "mask": mask,
  "door": door, "door_normal": Vector2(normal), "approach": approach, "bed": bed,
  "cabinet": cabinet, "plant": plant, "anchor": anchor, "access_route": route,
  "interior_nodes": interior, "tiles": []
 }
 _derive(layout)
 _add_pads(layout)
 return layout

static func _add_pads(layout: Dictionary):
 # NPCs still buy existing defenses on legal pads. Spread these over
 # occupied floor while reserving fixtures and the route used by the grid.
 var blocked: Array = layout.access_route.duplicate()
 blocked.append_array([
  Rect2(layout.bed - Vector2(31, 49), Vector2(62, 98)),
  Rect2(layout.cabinet + Vector2(-22, 1), Vector2(44, 28)),
  Rect2(layout.plant + Vector2(-14, 3), Vector2(28, 22)),
  _segment(layout.door, layout.door - layout.door_normal * 54.0, 55.0),
 ])
 var choices: Array[Vector2] = []
 var bounds: Rect2 = layout.bounds
 for y in range(32, int(bounds.size.y) - 24, 48):
  for x in range(32, int(bounds.size.x) - 24, 48):
   var at := bounds.position + Vector2(x, y)
   var footprint := Rect2(at - Vector2.ONE * 20.0, Vector2.ONE * 40.0)
   if not contains_rect(layout, footprint, 8.0):
    continue
   if blocked.any(func(rect: Rect2): return rect.intersects(footprint)):
    continue
   choices.append(at)
 # Keep the existing NPC pad order near the door for actionable ranges.
 choices.sort_custom(func(a: Vector2, b: Vector2):
  var first := a.distance_squared_to(layout.door)
  var second := b.distance_squared_to(layout.door)
  return (a.y < b.y or a.y == b.y and a.x < b.x) if first == second else first < second)
 layout.tiles = choices.slice(0, mini(12, choices.size()))

static func _bounded_cell(x: int, y: int) -> bool:
 return x >= 0 and x < 3 and y >= 0 and y < 3

static func _occupied(mask: int, x: int, y: int) -> bool:
 return _bounded_cell(x, y) and (mask & (1 << (y * 3 + x))) != 0

static func _band_cell(xs: Array, ys: Array, x: int, y: int) -> Rect2:
 return Rect2(xs[x], ys[y], xs[x + 1] - xs[x], ys[y + 1] - ys[y])

static func _access_cells(mask: int, start: Vector2i) -> Array[Vector2i]:
 var path: Array[Vector2i] = []
 var pending: Array[Vector2i] = [start]
 var previous := {start: start}
 var cursor := 0
 while cursor < pending.size():
  var from := pending[cursor]
  cursor += 1
  if from == Vector2i.ONE:
   while from != start:
    path.push_front(from)
    from = previous[from]
   path.push_front(start)
   break
  for normal in DIRECTIONS:
   var next: Vector2i = from + normal
   if _occupied(mask, next.x, next.y) and not previous.has(next):
    pending.append(next)
    previous[next] = from
 return path

static func _derive(layout: Dictionary):
 var start: Vector2 = layout.bounds.position
 var xs := [start.x]
 var ys := [start.y]
 for width in layout.bands_x:
  xs.append(xs.back() + width)
 for height in layout.bands_y:
  ys.append(ys.back() + height)
 var mask: int = layout.mask
 var floor_rects: Array[Rect2] = []
 var void_rects: Array[Rect2] = []
 var walls: Array[PackedVector2Array] = []
 var door: Vector2 = layout.door
 var facing: Vector2 = layout.door_normal
 for y in range(3):
  for x in range(3):
   var cell := _band_cell(xs, ys, x, y)
   if not _occupied(mask, x, y):
    void_rects.append(cell)
    continue
   floor_rects.append(cell)
   for direction in DIRECTIONS:
    if _occupied(mask, x + direction.x, y + direction.y):
     continue
    var normal := Vector2(direction)
    var center := cell.get_center() + normal * cell.size * 0.5
    var tangent := normal.orthogonal()
    var extent := (tangent.abs() * cell.size).length() * 0.5
    var a := center - tangent * extent
    var b := center + tangent * extent
    if normal == facing and center == door:
     walls.append(PackedVector2Array([a, door - tangent * DOOR_HALF_WIDTH]))
     walls.append(PackedVector2Array([door + tangent * DOOR_HALF_WIDTH, b]))
    else:
     walls.append(PackedVector2Array([a, b]))
 layout.floor = floor_rects
 layout.voids = void_rects
 layout.walls = walls

static func contains_point(layout: Dictionary, point: Vector2, margin: float = 0.0) -> bool:
 if margin > 0.0:
  return contains_rect(layout, Rect2(point, Vector2.ZERO), margin)
 if not layout.bounds.has_point(point):
  return false
 for hole in layout.get("voids", []):
  if hole.has_point(point):
   return false
 return true

static func contains_rect(layout: Dictionary, rect: Rect2, margin: float = 0.0) -> bool:
 var test := rect.grow(margin)
 if not layout.bounds.encloses(test):
  return false
 for hole in layout.get("voids", []):
  if hole.intersects(test):
   return false
 return true

static func _node(data: Dictionary, at: Vector2) -> int:
 var existing: int = data.nodes.find(at)
 if existing >= 0:
  return existing
 data.nodes.append(at)
 return data.nodes.size() - 1

static func _segment(a: Vector2, b: Vector2, width: float) -> Rect2:
 return Rect2(a.min(b), (a - b).abs()).grow(width * 0.5)

static func _link(data: Dictionary, first: int, second: int):
 if first == second:
  return
 data.lane_links.append([first, second])
 data.corridors.append(_segment(data.nodes[first], data.nodes[second], LANE_WIDTH))

static func _hall(data: Dictionary, id: String, from: Vector2, normal: Vector2, source: int, other_side: int = -1):
 var center := from + normal * 172.0
 var size := Vector2(210, 176) if normal.y != 0.0 else Vector2(176, 210)
 var rect := Rect2(center - size * 0.5, size)
 var entrance := center - normal * 88.0
 var frontier := _node(data, from)
 _link(data, source, frontier)
 if other_side >= 0:
  _link(data, other_side, frontier)
 var entrance_node := _node(data, entrance)
 _link(data, frontier, entrance_node)
 _link(data, entrance_node, _node(data, center))
 data.corridors.append(rect)
 data.halls[id] = {
  "id": id, "name": id.capitalize() + " Haunted Hall",
  "bounds": rect, "entrance": entrance, "center": center,
 }

static func pack(data: Dictionary) -> Dictionary:
 var version: int = data.get("version", 0)
 if version not in [VERSION, MACRO_VERSION, CLOSE_QUARTERS_VERSION]:
  return {}
 var rooms: Array = []
 for room in data.rooms:
  rooms.append({
   "shape": room.shape, "bands_x": room.bands_x.duplicate(), "bands_y": room.bands_y.duplicate(),
   "mask": room.mask, "bounds": _rect_data(room.bounds), "door": _point_data(room.door),
   "normal": _point_data(room.door_normal), "bed": _point_data(room.bed),
   "cabinet": _point_data(room.cabinet), "plant": _point_data(room.plant),
   "anchor": _point_data(room.anchor), "nodes": _encode_points(room.interior_nodes),
   "tiles": _encode_points(room.tiles), "route": _encode_rects(room.access_route),
  })
 var halls: Dictionary = {}
 for id in HALL_IDS:
  var hall: Dictionary = data.halls[id]
  halls[id] = {
   "bounds": _rect_data(hall.bounds), "center": _point_data(hall.center),
   "entrance": _point_data(hall.entrance),
  }
 var saved := {
  "version": version, "seed": str(data.seed), "map": data.id,
  "bounds": _rect_data(data.bounds), "rooms": rooms, "halls": halls,
  "spawn": _point_data(data.spawn), "hunter_spawn": _point_data(data.hunter_spawn),
  "nodes": _encode_points(data.nodes), "links": data.lane_links.duplicate(true),
  "corridors": _encode_rects(data.corridors),
 }
 if version in [MACRO_VERSION, CLOSE_QUARTERS_VERSION]:
  saved.family = data.family
  saved.lane_widths = data.lane_widths.duplicate()
 if version==CLOSE_QUARTERS_VERSION:saved.staging_points=_encode_points(data.staging_points)
 return saved

static func unpack(saved: Variant, expected_id: String) -> Dictionary:
 if not saved is Dictionary or saved.get("map") != expected_id:
  return {}
 # Godot's JSON reader returns numbers as floats. Compare numerical values
 # directly so checkpoint versions survive the wire format.
 var raw_version = saved.get("version")
 if raw_version != VERSION and raw_version != MACRO_VERSION and raw_version != CLOSE_QUARTERS_VERSION:
  return {}
 var macro: bool = saved.version != VERSION
 var close_quarters: bool = saved.version == CLOSE_QUARTERS_VERSION
 var lane_cap:=MAX_MACRO_LANES+96 if close_quarters else MAX_MACRO_LANES
 if macro and saved.get("family") not in NightmareMacroLayout.FAMILY_IDS:
  return {}
 var theme := MapCatalog.map(expected_id)
 var seed = saved.get("seed")
 if theme.is_empty() or not seed is String or seed.length() > 20 or not seed.is_valid_int() or str(int(seed)) != seed:
  return {}
 var bounds := _decode_rect(saved.get("bounds"))
 var spawn := _decode_point(saved.get("spawn"))
 var hunter_spawn := _decode_point(saved.get("hunter_spawn"))
 if not bounds.has_area() or not bounds.has_point(spawn) or not bounds.has_point(hunter_spawn):
  return {}
 var nodes := _decode_points(saved.get("nodes"), MAX_MACRO_NODES+72 if close_quarters else MAX_MACRO_NODES if macro else 64)
 var corridors := _decode_rects(saved.get("corridors"), lane_cap + HALL_IDS.size() if macro else 96)
 if nodes.size() < 8 or corridors.is_empty() or not nodes.has(spawn) or not nodes.has(hunter_spawn):
  return {}
 var link_data = saved.get("links")
 var widths: Array = []
 if macro:
  var encoded = saved.get("lane_widths")
  if not encoded is Array or not link_data is Array or encoded.size() != link_data.size() or encoded.size() > lane_cap:
   return {}
  for width in encoded:
   if not _numeric(width, 224.0) or width < 64.0:
    return {}
   widths.append(float(width))
 var links := _decode_links(link_data, nodes, corridors, widths, lane_cap)
 if links.is_empty() or not _connected(links, nodes.size()):
  return {}
 for corridor in corridors:
  if not bounds.encloses(corridor):
   return {}
 var room_data = saved.get("rooms")
 if not room_data is Array or room_data.size() != ROOM_COUNT:
  return {}
 var rooms: Array = []
 for entry in room_data:
  var room := _decode_room(entry)
  if room.is_empty() or not bounds.encloses(room.bounds) or not nodes.has(room.anchor) or not nodes.has(room.approach):
   return {}
  for other in rooms:
   if other.bounds.intersects(room.bounds):
    return {}
  rooms.append(room)
 var halls := _decode_halls(saved.get("halls"), bounds, nodes, corridors)
 if halls.is_empty():
  return {}
 for room in rooms:
  for hall in halls.values():
   if hall.bounds.intersects(room.bounds):
    return {}
 var result := {
  "version": int(saved.version), "seed": int(seed), "id": expected_id, "title": theme.title, "theme": theme.theme,
  "bounds": bounds, "spawn": spawn, "hunter_spawn": hunter_spawn,
  "rooms": rooms, "nodes": nodes, "lane_links": links, "corridors": corridors, "halls": halls,
 }
 if macro:
  # Only links and the four hall interiors grant exterior walkability.
  # Reject save entries that add walkable shortcuts outside this topology.
  var used_corridors: Dictionary = {}
  for i in range(links.size()):
   var link: Array = links[i]
   used_corridors[_segment(nodes[link[0]], nodes[link[1]], widths[i])] = true
  for hall in halls.values():
   used_corridors[hall.bounds] = true
  for corridor in corridors:
   if not used_corridors.has(corridor):
    return {}
  result.family = saved.family
  result.lane_widths = widths
 if close_quarters:
  var staging:=_decode_points(saved.get("staging_points"),MAX_MACRO_NODES+MAX_MACRO_LANES+HALL_IDS.size())
  if staging.is_empty() or not staging.has(spawn):return {}
  for point in staging:
   if not bounds.has_point(point) or not corridors.any(func(rect: Rect2):return rect.has_point(point)):
    return {}
  result.staging_points=staging
 return result

static func _decode_room(entry: Variant) -> Dictionary:
 if not entry is Dictionary or entry.get("shape") not in SHAPES:
  return {}
 var w := _decode_bands(entry.get("bands_x"))
 var h := _decode_bands(entry.get("bands_y"))
 var bounds := _decode_rect(entry.get("bounds"))
 var mask_raw = entry.get("mask")
 if w.is_empty() or h.is_empty() or not bounds.has_area() or not _numeric(mask_raw, 511.0):
  return {}
 var mask := int(mask_raw)
 if float(mask) != float(mask_raw) or not _occupied(mask, 1, 1) or mask < 0:
  return {}
 var canonical: int = MASKS[SHAPES.find(entry.shape)]
 if mask not in _mask_rotations(canonical):
  return {}
 if bounds.size != Vector2(w[0] + w[1] + w[2], h[0] + h[1] + h[2]):
  return {}
 var door := _decode_point(entry.get("door"))
 var normal := _decode_point(entry.get("normal"))
 var bed := _decode_point(entry.get("bed"))
 var cabinet := _decode_point(entry.get("cabinet"))
 var plant := _decode_point(entry.get("plant"))
 var anchor := _decode_point(entry.get("anchor"))
 var tiles := _decode_points(entry.get("tiles"), 16)
 var internal := _decode_points(entry.get("nodes"), 16)
 var route := _decode_rects(entry.get("route"), 10)
 if normal not in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
  return {}
 if not door.is_finite() or not anchor.is_finite() or (anchor - door).normalized() != normal:
  return {}
 var room := {
  "bounds": bounds, "shape": entry.shape, "bands_x": w, "bands_y": h, "mask": mask,
  "door": door, "door_normal": normal, "approach": door + normal * 24.0, "bed": bed,
  "cabinet": cabinet, "plant": plant, "anchor": anchor, "tiles": tiles,
  "access_route": route, "interior_nodes": internal,
 }
 _derive(room)
 if room.walls.size() == _wall_edge_count(mask):
  return {}
 if route.is_empty() or internal.is_empty() or tiles.size() < 3:
  return {}
 for position in [bed, cabinet, plant, door - normal * 24.0]:
  if not contains_point(room, position, 8.0):
   return {}
 if contains_point(room, room.approach):
  return {}
 for position in internal:
  if not contains_point(room, position, 8.0):
   return {}
 for position in tiles:
  if not contains_rect(room, Rect2(position - Vector2.ONE * 20.0, Vector2.ONE * 40.0), 8.0):
   return {}
 for rectangle in route:
  if not contains_rect(room, rectangle, 8.0):
   return {}
 return room

static func _wall_edge_count(mask: int) -> int:
 var count := 0
 for y in range(3):
  for x in range(3):
   if not _occupied(mask, x, y):
    continue
   for normal in DIRECTIONS:
    if not _occupied(mask, x + normal.x, y + normal.y):
     count += 1
 return count

static func _mask_rotations(mask: int) -> Array[int]:
 var result: Array[int] = [mask]
 for turn in range(3):
  var next := 0
  for y in range(3):
   for x in range(3):
    if _occupied(mask, x, y):
     next |= 1 << (x * 3 + 2 - y)
  mask = next
  result.append(mask)
 return result

static func _decode_halls(saved: Variant, bounds: Rect2, nodes: Array, corridors: Array) -> Dictionary:
 if not saved is Dictionary or saved.size() != HALL_IDS.size():
  return {}
 var decoded := {}
 for id in HALL_IDS:
  var entry = saved.get(id)
  if not entry is Dictionary:
   return {}
  var rect := _decode_rect(entry.get("bounds"))
  var center := _decode_point(entry.get("center"))
  var entrance := _decode_point(entry.get("entrance"))
  if not rect.has_area() or not bounds.encloses(rect) or rect.get_center() != center or not rect.has_point(entrance) and not rect.grow(0.01).has_point(entrance):
   return {}
  if not nodes.has(center) or not nodes.has(entrance) or not corridors.has(rect):
   return {}
  for other in decoded.values():
   if other.bounds.intersects(rect):
    return {}
  decoded[id] = {
   "id": id, "name": id.capitalize() + " Haunted Hall",
   "bounds": rect, "center": center, "entrance": entrance,
  }
 return decoded

static func _decode_links(raw: Variant, nodes: Array, corridors: Array, widths: Array = [], lane_cap: int = MAX_MACRO_LANES) -> Array:
 if not raw is Array or raw.is_empty() or raw.size() > (96 if widths.is_empty() else lane_cap):
  return []
 var links: Array = []
 for pair in raw:
  if not pair is Array or pair.size() != 2:
   return []
  if not _numeric(pair[0], nodes.size() - 1) or not _numeric(pair[1], nodes.size() - 1):
   return []
  var first := int(pair[0])
  var second := int(pair[1])
  if first < 0 or second < 0 or first == second or float(first) != float(pair[0]) or float(second) != float(pair[1]):
   return []
  var start: Vector2 = nodes[first]
  var finish: Vector2 = nodes[second]
  if start.x != finish.x and start.y != finish.y:
   return []
  var width: float = LANE_WIDTH if widths.is_empty() else widths[links.size()]
  if not corridors.has(_segment(start, finish, width)):
   return []
  links.append([first, second])
 return links

static func _connected(links: Array, count: int) -> bool:
 var reached := {0: true}
 var pending := [0]
 var at := 0
 while at < pending.size():
  var node: int = pending[at]
  at += 1
  for link in links:
   var other: int = link[1] if link[0] == node else link[0] if link[1] == node else -1
   if other >= 0 and not reached.has(other):
    reached[other] = true
    pending.append(other)
 return reached.size() == count

static func _decode_bands(raw: Variant) -> Array:
 if not raw is Array or raw.size() != 3:
  return []
 var decoded: Array = []
 for value in raw:
  if not _numeric(value, 160.0) or value < 80.0 or fmod(float(value), 16.0) != 0.0:
   return []
  decoded.append(float(value))
 return decoded

static func _numeric(value: Variant, bound: float) -> bool:
 return (value is float or value is int) and is_finite(float(value)) and absf(float(value)) <= bound

static func _point_data(point: Vector2) -> Array:
 return [point.x, point.y]

static func _rect_data(rect: Rect2) -> Array:
 return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func _encode_points(points: Array) -> Array:
 return points.map(_point_data)

static func _encode_rects(rects: Array) -> Array:
 return rects.map(_rect_data)

static func _decode_point(raw: Variant) -> Vector2:
 if not raw is Array or raw.size() != 2 or not _numeric(raw[0], LIMIT) or not _numeric(raw[1], LIMIT):
  return Vector2.INF
 return Vector2(raw[0], raw[1])

static func _decode_rect(raw: Variant) -> Rect2:
 if not raw is Array or raw.size() != 4:
  return Rect2()
 for value in raw:
  if not _numeric(value, LIMIT):
   return Rect2()
 if raw[2] <= 0.0 or raw[3] <= 0.0:
  return Rect2()
 return Rect2(raw[0], raw[1], raw[2], raw[3])

static func _decode_points(raw: Variant, cap: int) -> Array[Vector2]:
 var points: Array[Vector2] = []
 if not raw is Array or raw.size() > cap:
  return points
 for item in raw:
  var point := _decode_point(item)
  if not point.is_finite():
   return []
  points.append(point)
 return points

static func _decode_rects(raw: Variant, cap: int) -> Array[Rect2]:
 var rects: Array[Rect2] = []
 if not raw is Array or raw.size() > cap:
  return rects
 for item in raw:
  var rect := _decode_rect(item)
  if not rect.has_area():
   return []
  rects.append(rect)
 return rects
