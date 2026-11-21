class_name NightmareNavigation
extends RefCounted
## Exterior lanes are a sparse AStar2D graph. A room has one portal and a
## private interior graph, which keeps notches and locked rooms out of shortcuts.

const HUNTER_CLEARANCE := 10.0
const PLAYER_CLEARANCE := 12.0
const MAX_ATTACHMENTS := 6
const MAX_DETOUR_FACTOR := 1.32

class RouteGraph extends AStar2D:
 var penalized_edges: Dictionary = {}
 var variant := 0

 func _compute_cost(from_id: int, to_id: int) -> float:
  var distance := get_point_position(from_id).distance_to(get_point_position(to_id))
  if variant == 0:
   return distance
  return distance * (1.0 + 0.55 * float(penalized_edges.has(Vector2i(mini(from_id, to_id), maxi(from_id, to_id)))))

 func _estimate_cost(from_id: int, to_id: int) -> float:
  return get_point_position(from_id).distance_to(get_point_position(to_id))

var hunter_graph := RouteGraph.new()
var player_graph := RouteGraph.new()
var _exterior: Array[int] = []
var _rooms: Array[Array] = []
var _approaches: Array[int] = []
var _next_id := 0

static func _room_at(model, point: Vector2) -> int:
 for room in model.rooms:
  if NightmareMap.contains_point(room.layout, point):
   return room.index
 return -1

static func _player_allowed(room, access_room: int = -1) -> bool:
 return room.index == access_room or (not room.closed and (room.owner < 0 or room.owner == 0))

static func permits_hunter_entry(model, from: Vector2, to: Vector2) -> bool:
 var target := _room_at(model, to)
 if target < 0:
  return true
 var room = model.rooms[target]
 return not room.closed or room.door_hp <= 0 or _room_at(model, from) == target

static func _walkable(model, point: Vector2, player: bool, static_pass: bool, access_room: int = -1) -> bool:
 var clearance := PLAYER_CLEARANCE if player else HUNTER_CLEARANCE
 for room in model.rooms:
  var layout: Dictionary = room.layout
  var bounds: Rect2 = layout.bounds
  if not bounds.grow(clearance).has_point(point):
   continue
  var relative: Vector2 = point - layout.door
  var normal: Vector2 = layout.door_normal
  var depth := relative.dot(normal)
  if absf(depth) <= clearance and absf(relative.dot(normal.orthogonal())) < NightmareMap.DOOR_HALF_WIDTH - clearance:
   return depth > 0.0 or not player or static_pass or _player_allowed(room, access_room)
  if NightmareMap.contains_point(layout, point, clearance):
   if player and not static_pass and not _player_allowed(room, access_room):
    return false
   return not room.furniture_blocks(point, player)
  for floor: Rect2 in layout.floor:
   if floor.grow(clearance).has_point(point):
    return false
 for corridor: Rect2 in model.map_data.corridors:
  if corridor.grow(-clearance).has_point(point):
   return true
 return false

static func walkable(model, point: Vector2, player: bool = false, access_room: int = -1) -> bool:
 return point.is_finite() and _walkable(model, point, player, false, access_room)

# A point changes walkability only at one of these rectangle boundaries.
# Testing each interval avoids a sampled ray cutting a narrow corridor corner.
static func _collect_segment_cuts(cuts: Array[float], rect: Rect2, from: Vector2, direction: Vector2):
 var near := 0.0
 var far := 1.0
 for axis in range(2):
  var movement: float = direction[axis]
  var position: float = from[axis]
  var low: float = rect.position[axis]
  var high: float = rect.end[axis]
  if is_zero_approx(movement):
   if position < low or position > high:
    return
   continue
  var first := (low - position) / movement
  var second := (high - position) / movement
  near = maxf(near, minf(first, second))
  far = minf(far, maxf(first, second))
  if near > far:
   return
 if near > 0.0 and near < 1.0:
  cuts.append(near)
 if far > 0.0 and far < 1.0:
  cuts.append(far)

static func visible(model, from: Vector2, to: Vector2, player: bool = false, static_pass: bool = false, access_room: int = -1) -> bool:
 if not from.is_finite() or not to.is_finite():
  return false
 if not _walkable(model, from, player, static_pass, access_room) or not _walkable(model, to, player, static_pass, access_room):
  return false
 var clearance := PLAYER_CLEARANCE if player else HUNTER_CLEARANCE
 var direction := to - from
 var ray_bounds := Rect2(from.min(to), direction.abs()).grow(0.01)
 var cuts: Array[float] = [0.0, 1.0]
 for room in model.rooms:
  var layout: Dictionary = room.layout
  var bounds: Rect2 = layout.bounds
  if not bounds.grow(clearance).intersects(ray_bounds):
   continue
  _collect_segment_cuts(cuts, bounds.grow(clearance), from, direction)
  _collect_segment_cuts(cuts, bounds.grow(-clearance), from, direction)
  for floor: Rect2 in layout.floor:
   _collect_segment_cuts(cuts, floor.grow(clearance), from, direction)
  for hole: Rect2 in layout.voids:
   _collect_segment_cuts(cuts, hole.grow(clearance), from, direction)
  var normal: Vector2 = layout.door_normal
  var extent := normal.abs() * clearance + normal.orthogonal().abs() * (NightmareMap.DOOR_HALF_WIDTH - clearance)
  _collect_segment_cuts(cuts, Rect2(layout.door - extent, extent * 2.0), from, direction)
  if player and not static_pass and not _player_allowed(room, access_room):
   var a: Vector2 = layout.door + normal * clearance - normal.orthogonal().abs() * (NightmareMap.DOOR_HALF_WIDTH - clearance)
   var b: Vector2 = layout.door + normal.orthogonal().abs() * (NightmareMap.DOOR_HALF_WIDTH - clearance)
   _collect_segment_cuts(cuts, Rect2(a.min(b), (a - b).abs()), from, direction)
  for kind in ["cabinet", "plant"]:
   _collect_segment_cuts(cuts, room.furniture_bounds(kind), from, direction)
  if player:
   _collect_segment_cuts(cuts, room.furniture_bounds("bed"), from, direction)
 for corridor: Rect2 in model.map_data.corridors:
  var interior := corridor.grow(-clearance)
  if interior.intersects(ray_bounds):
   _collect_segment_cuts(cuts, interior, from, direction)
 cuts.sort()
 for i in range(1, cuts.size()):
  var first := cuts[i - 1]
  var last := cuts[i]
  if first == last:
   continue
  if not _walkable(model, from + direction * ((first + last) * 0.5), player, static_pass, access_room):
   return false
 return true

func rebuild(model):
 hunter_graph.clear()
 player_graph.clear()
 _exterior.clear()
 _rooms.clear()
 _approaches.clear()
 _next_id = 0
 for point: Vector2 in model.map_data.nodes:
  var id := _next_id
  _exterior.append(id)
  hunter_graph.add_point(id, point)
  player_graph.add_point(id, point)
  _next_id += 1
 for pair in model.map_data.lane_links:
  # Lane rectangles were generated for these exact connections. Keep the
  # obstruction check so checkpoint-supplied geometry cannot tunnel a wall.
  var first := int(pair[0])
  var second := int(pair[1])
  if visible(model, player_graph.get_point_position(first), player_graph.get_point_position(second), true, true):
   hunter_graph.connect_points(first, second)
   player_graph.connect_points(first, second)

 for room in model.rooms:
  var approach: int = model.map_data.nodes.find(room.door_approach())
  _approaches.append(approach)
  var candidates: Array = room.layout.interior_nodes.duplicate()
  var bed: Vector2 = room.bed_position()
  var entry: Vector2 = room.door_position() - room.door_normal() * 24.0
  if not candidates.has(entry):
   candidates.append(entry)
  # Candidate points around all sides of the bed keep the player path
  # navigable without allowing it to traverse the bed's physical footprint.
  for offset in [Vector2(-40, -57), Vector2(40, -57), Vector2(-40, 57), Vector2(40, 57),
   Vector2(-42, 0), Vector2(42, 0), Vector2(0, -58), Vector2(0, 58)]:
   if not candidates.has(bed + offset):
    candidates.append(bed + offset)
  candidates.append(bed)
  var interior: Array[int] = []
  var player_ids: Array[int] = []
  var entry_id := -1
  for point: Vector2 in candidates:
   var id := _next_id
   _next_id += 1
   if point == entry:
    entry_id = id
   if _walkable(model, point, false, true):
    hunter_graph.add_point(id, point)
    interior.append(id)
   if _walkable(model, point, true, true):
    player_graph.add_point(id, point)
    player_ids.append(id)
  _join_interior(model, hunter_graph, interior, false)
  _join_interior(model, player_graph, player_ids, true)
  _portal(model, hunter_graph, approach, entry_id, false)
  _portal(model, player_graph, approach, entry_id, true)
  _rooms.append(interior)
  # Interior endpoints can attach near the doorway without introducing an
  # alternate exterior entry into this private room graph.
  interior.append(approach)

func _join_interior(model, graph: RouteGraph, ids: Array[int], player: bool):
 for i in range(ids.size()):
  var first := ids[i]
  var a := graph.get_point_position(first)
  for j in range(i):
   var second := ids[j]
   var b := graph.get_point_position(second)
   if visible(model, a, b, player, true):
    graph.connect_points(first, second)

func _portal(model, graph: RouteGraph, outside: int, inside: int, player: bool):
 if not graph.has_point(outside) or not graph.has_point(inside):
  return
 if visible(model, graph.get_point_position(outside), graph.get_point_position(inside), player, true):
  graph.connect_points(outside, inside)

func _attach(model, graph: RouteGraph, id: int, at: Vector2, room_index: int, player: bool):
 graph.add_point(id, at)
 var candidates: Array = _exterior.duplicate() if room_index < 0 else _rooms[room_index].duplicate()
 candidates.sort_custom(func(a: int, b: int):
  var first := at.distance_squared_to(graph.get_point_position(a)) if graph.has_point(a) else INF
  var second := at.distance_squared_to(graph.get_point_position(b)) if graph.has_point(b) else INF
  return a < b if first == second else first < second)
 var attached := 0
 for other: int in candidates:
  if not graph.has_point(other):
   continue
  var destination := graph.get_point_position(other)
  if not visible(model, at, destination, player, true):
   continue
  graph.connect_points(id, other)
  attached += 1
  if attached >= MAX_ATTACHMENTS or at.is_equal_approx(destination):
   break

static func _length(points: PackedVector2Array) -> float:
 var length := 0.0
 for i in range(1, points.size()):
  length += points[i - 1].distance_to(points[i])
 return length

func costs(model, from: Vector2, paths: Variant=null) -> Dictionary:
 var result: Dictionary = {}
 if walkable(model, from):
  _attach(model, hunter_graph, _next_id, from, _room_at(model, from), false)
  for i in range(_approaches.size()):
   var route := hunter_graph.get_point_path(_next_id, _approaches[i])
   result[i] = INF if route.is_empty() else _length(route)
   if paths!=null:paths[i]=route
  hunter_graph.remove_point(_next_id)
 else:
  for i in range(_approaches.size()):
   result[i] = INF
 return result

func path(model, from: Vector2, to: Vector2, player: bool = false, route_variant: int = 0, access_room: int = -1) -> Array:
 if from.distance_squared_to(to) < 0.01 or not walkable(model, from, player, access_room) or not walkable(model, to, player, access_room):
  return []
 var start_room := _room_at(model, from)
 var finish_room := _room_at(model, to)
 if not player and not permits_hunter_entry(model, from, to):
  return []
 if visible(model, from, to, player, false, access_room):
  return [to]
 var graph := player_graph if player else hunter_graph
 var start := _next_id
 var finish := start + 1
 _attach(model, graph, start, from, start_room, player)
 _attach(model, graph, finish, to, finish_room, player)
 var route := graph.get_point_path(start, finish)
 if route_variant > 0 and not player and route.size() > 3:
  var ids := graph.get_id_path(start, finish)
  for i in range(1, ids.size()):
   var a := ids[i - 1]
   var b := ids[i]
   # Alternate visits can favor a different lane loop. Keep interior edges
   # and the terminal attachments stable, and limit the actual detour.
   if _exterior.has(a) and _exterior.has(b):
    graph.penalized_edges[Vector2i(mini(a, b), maxi(a, b))] = true
  graph.variant = route_variant
  var alternate := graph.get_point_path(start, finish)
  graph.variant = 0
  graph.penalized_edges.clear()
  if not alternate.is_empty() and _length(alternate) <= _length(route) * MAX_DETOUR_FACTOR:
   route = alternate
 graph.remove_point(start)
 graph.remove_point(finish)
 var result: Array = []
 for i in range(1, route.size()):
  if not route[i].is_equal_approx(route[i - 1]):
   result.append(route[i])
 return result
