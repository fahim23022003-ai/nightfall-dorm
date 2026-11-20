extends "res://tests/nightmare_maps_runtime.gd"
## Deterministic family audit. The graph, paths and purchases use the production model.

const FAMILIES := ["ring", "branching", "scattered", "spine", "zigzag", "radial", "twin_wings", "labyrinth", "courtyards", "hybrid"]
const V2_FLAG := "NIGHTFALL_PROCEDURAL_MAPS_V2"
const V1_FLAG := "NIGHTFALL_PROCEDURAL_MAPS"
const COARSE_SIDE := 18
const CARDINALS := {"north": Vector2.UP, "south": Vector2.DOWN, "west": Vector2.LEFT, "east": Vector2.RIGHT}
const TEST_AREA := 1000000.0
var macro: GDScript
var routes_checked := 0
var natural_families := {}
var exact_hashes := {}
var measurements := []
var family_counts := {}
var family_profiles := {}
var family_graphs := {}
var alternate_counts := {}
var greatest_rooms := {}

func room_envelope(data: Dictionary) -> Rect2:
 var extent: Rect2 = data.rooms[0].bounds
 for room in data.rooms:
  extent = extent.merge(room.bounds)
 return extent

func surface_envelope(data: Dictionary) -> Rect2:
 var extent := room_envelope(data)
 for corridor in data.corridors:
  extent = extent.merge(corridor)
 return extent

func vertex_degrees(data: Dictionary) -> PackedInt32Array:
 var degrees := PackedInt32Array()
 degrees.resize(data.nodes.size())
 for link in data.lane_links:
  degrees[int(link[0])] += 1
  degrees[int(link[1])] += 1
 return degrees

func graph_connected(data: Dictionary) -> bool:
 var reached := PackedByteArray()
 reached.resize(data.nodes.size())
 reached[0] = 1
 var pending := [0]
 var cursor := 0
 while cursor < pending.size():
  var node: int = pending[cursor]
  cursor += 1
  for link in data.lane_links:
   var other: int = int(link[1]) if int(link[0]) == node else int(link[0]) if int(link[1]) == node else -1
   if other >= 0 and reached[other] == 0:
    reached[other] = 1
    pending.append(other)
 return pending.size() == data.nodes.size()

func sample_silhouette(data: Dictionary, extent: Rect2) -> String:
 var pixels := PackedByteArray()
 pixels.resize(COARSE_SIDE * COARSE_SIDE)
 var step := extent.size / COARSE_SIDE
 for y in range(COARSE_SIDE):
  for x in range(COARSE_SIDE):
   var point := extent.position + (Vector2(x, y) + Vector2.ONE * .5) * step
   var fill := 0
   for corridor: Rect2 in data.corridors:
    if corridor.has_point(point):
     fill = 1
     break
   for room in data.rooms:
    if room.bounds.has_point(point) and NightmareMap.contains_point(room, point):
     fill = 2
     break
   for hall in data.halls.values():
    if hall.bounds.has_point(point):
     fill = 3
     break
   pixels[y * COARSE_SIDE + x] = 46 if fill == 0 else 48 + fill
 return pixels.get_string_from_ascii()

func bare_graph_signature(data: Dictionary, degrees: PackedInt32Array) -> String:
 var neighbors := []
 var colors := []
 for degree in degrees:
  neighbors.append([])
  colors.append(str(degree))
 for link in data.lane_links:
  var a := int(link[0])
  var b := int(link[1])
  neighbors[a].append(b)
  neighbors[b].append(a)
 for step in range(4):
  var next := []
  for i in range(colors.size()):
   var around: Array = neighbors[i].map(func(node): return colors[node])
   around.sort()
   next.append((colors[i] + "," + ",".join(around)).sha256_text().substr(0, 16))
  colors = next
 colors.sort()
 return str(colors).sha256_text()

func near_similarity(left: String, right: String) -> float:
 var a := left.to_ascii_buffer()
 var b := right.to_ascii_buffer()
 var matching := 0
 var union := 0
 for i in range(a.size()):
  if a[i] == 46 and b[i] == 46:
   continue
  union += 1
  matching += int(a[i] == b[i])
 return float(matching) / maxi(1, union)

func metrics(data: Dictionary, door_paths: Array[float], hall_paths: Array[float]) -> Dictionary:
 var surface := surface_envelope(data)
 var envelope := room_envelope(data)
 var degrees := vertex_degrees(data)
 var branch_degrees := []
 var widths := {}
 var floor_area := []
 var room_centers := []
 var spacing := []
 var center_bands := []
 var closest_face := []
 var facing_histogram := {}
 var strongest := 0
 for degree in degrees:
  if degree >= 3:
   branch_degrees.append(degree)
 branch_degrees.sort()
 for width in data.get("lane_widths", []):
  widths[width] = true
 for i in range(data.rooms.size()):
  var room: Dictionary = data.rooms[i]
  var center: Vector2 = room.bounds.get_center()
  var area := 0.0
  for piece: Rect2 in room.floor:
   area += piece.get_area()
  floor_area.append(area)
  if area > float(floor_area[strongest]):
   strongest = i
  for other: Vector2 in room_centers:
   spacing.append(roundi(center.distance_to(other)))
  room_centers.append(center)
  var scaled := (center - envelope.position) / envelope.size
  center_bands.append(Vector2i(scaled * 6.0))
  var normal: String = str(room.door_normal)
  facing_histogram[normal] = facing_histogram.get(normal, 0) + 1
  var nearest_hall := INF
  for hall in data.halls.values():
   nearest_hall = minf(nearest_hall, room.approach.distance_to(hall.entrance))
  closest_face.append(roundi(nearest_hall))
 spacing.sort()
 center_bands.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or a.y == b.y and a.x < b.x)
 var neighbors := []
 # The nearest one or two neighbors represent proximity adjacency, distinct
 # from graph links, which describe the actual corridors.
 for first in room_centers:
  var near: Array[float] = []
  for second in room_centers:
   if first != second:
    near.append(first.distance_to(second))
  near.sort()
  var local_count := 0
  for distance in near:
   local_count += int(distance <= near[0] * 1.3)
  neighbors.append(local_count)
 neighbors.sort()
 var silhouette := sample_silhouette(data, surface)
 var projections := {}
 for direction: String in CARDINALS:
  var normal: Vector2 = CARDINALS[direction]
  var center: Vector2 = data.halls[direction].center
  projections[direction] = snappedf((center - envelope.get_center()).dot(normal) / (envelope.size.dot(normal.abs()) * .5), .001)
 var reflected := ""
 for y in range(COARSE_SIDE):
  reflected += silhouette.substr(y * COARSE_SIDE, COARSE_SIDE).reverse()
 return {
  "family": data.family, "theme": data.id, "seed": data.seed,
  "aspect_ratio": snappedf(surface.size.x / surface.size.y, .001),
  "footprint_area_million_px": snappedf(surface.get_area() / TEST_AREA, .001),
  "nodes": degrees.size(), "links": data.lane_links.size(), "loop_rank": data.lane_links.size() - degrees.size() + 1,
  "branches": branch_degrees.size(), "branch_degrees": branch_degrees, "lane_widths": widths.keys(),
  "graph_signature": bare_graph_signature(data, degrees),
  "room_centers_6x6": center_bands.map(func(cell: Vector2i): return [cell.x, cell.y]), "nearby_rooms": neighbors, "pairwise_spacing_px": spacing,
  "room_floor_px": floor_area, "largest_room": strongest + 1,
  "hunter_spawn_door_route_px": door_paths, "hunter_spawn_hall_route_px": hall_paths,
  "nearest_hall_entrance_euclidean_px": closest_face, "door_facings": facing_histogram,
  "hall_cardinal_projections": projections,
  "horizontal_symmetry": snappedf(near_similarity(silhouette, reflected), .001),
  "silhouette": silhouette,
 }

func audited_route(model: MatchModel, start: Vector2, finish: Vector2, label: String, player := false) -> Array:
 var path := model.navigation_path(start, finish, player)
 var legal: bool = not path.is_empty() and path.back().distance_to(finish) < .05
 var current := start
 for next: Vector2 in path:
  legal = legal and NightmareNavigation.visible(model, current, next, player)
  current = next
 check(legal, label + " reaches exact destination using collision-legal segments")
 routes_checked += 1
 return path

func check_bed(model: MatchModel, room: RoomState, start: Vector2, label: String):
 var bed := room.bed_position()
 for offset in [Vector2(-42, 0), Vector2(42, 0), Vector2(0, -58), Vector2(0, 58)]:
  var near: Vector2 = bed + offset
  if not model.can_walk(near) or not room.floor_has_point(near):
   continue
  var path := model.navigation_path(start, near, true)
  if not path.is_empty() and legal_path(model, start, near, path, true):
   routes_checked += 1
   check(true, label + " reaches a usable sleep interaction point")
   return
 check(false, label + " reaches a usable sleep interaction point")

func audit_map(theme: String, seed: int, requested: String, audit_alternates: bool = false):
 var label := "%s/%s/%d" % [theme, requested if requested != "" else "automatic", seed]
 var data: Dictionary = macro.generate(theme, seed, requested)
 check(data.get("family") in FAMILIES and data.get("version") == 2, label + " generates a valid V2 family")
 if data.is_empty() or not data.has("family"):
  return
 if requested != "":
  check(data.family == requested, label + " uses the audited family")
 else:
  natural_families[data.family] = natural_families.get(data.family, 0) + 1
 var packed := NightmareMap.pack(data)
 var encoded := JSON.stringify(packed, "", true, true)
 check(not packed.is_empty() and packed == NightmareMap.pack(macro.generate(theme, seed, requested)), label + " generates and serializes deterministically")
 var decoded := NightmareMap.unpack(JSON.parse_string(encoded), theme)
 check(not decoded.is_empty() and NightmareMap.pack(decoded) == packed, label + " retains original geometry exactly after JSON round-trip")
 if decoded.is_empty():
  return
 var shape_payload := packed.duplicate()
 for key in ["seed", "family", "map", "theme", "title"]:
  shape_payload.erase(key)
 var exact := JSON.stringify(shape_payload, "", true, true).sha256_text()
 check(not exact_hashes.has(exact), label + " has a unique exact payload in this sample")
 exact_hashes[exact] = true
 check(data.rooms.size() == 6 and data.halls.size() == 4, label + " has six rooms and four Halls")
 check(graph_connected(data), label + " encoded exterior graph is connected")
 var edges := {}
 for pair in data.lane_links:
  edges["%d/%d" % [mini(pair[0], pair[1]), maxi(pair[0], pair[1])]] = true
 check(edges.size() == data.lane_links.size(), label + " graph has no duplicate edge")
 check(data.lane_widths.size() == data.lane_links.size(), label + " corridor width is encoded for each edge")
 if data.rooms.size() != 6 or data.halls.size() != 4:
  return
 var envelope := room_envelope(data)
 for direction: String in CARDINALS:
  check(data.halls.has(direction), label + " keeps " + direction + " Hall")
  if not data.halls.has(direction):
   return
  var hall: Dictionary = data.halls[direction]
  var point: Vector2 = hall.center
  var entrance: Vector2 = hall.entrance
  var normal: Vector2 = CARDINALS[direction]
  var half_span := envelope.size.dot(normal.abs()) * .5
  var projection := (point - envelope.get_center()).dot(normal) / half_span
  # Recesses still qualify when they sit within the outer 30% of occupied
  # room extent. No rectangular pad is imposed outside the envelope.
  check(projection >= .4, label + " Hall is near the expected cardinal outer sector")
  check((point - entrance).normalized() == normal, label + " Hall entry faces its labeled direction")
  check(data.bounds.encloses(hall.bounds), label + " map overview fits the entire Hall")
  for room in data.rooms:
   check(not hall.bounds.intersects(room.bounds), label + " Hall does not overlap a survivor room")
 for i in range(data.rooms.size()):
  for j in range(i):
   check(not data.rooms[i].bounds.intersects(data.rooms[j].bounds), label + " no room bounds overlap")
  var room: Dictionary = data.rooms[i]
  check(data.bounds.encloses(room.bounds), label + " room fits camera bounds")
  check(NightmareMap.contains_point(room, room.bed) and NightmareMap.contains_point(room, room.cabinet) and NightmareMap.contains_point(room, room.plant), label + " fixtures remain on legal floor")
 for corridor: Rect2 in data.corridors:
  check(data.bounds.encloses(corridor), label + " camera bounds cover complete walkable network")
 var model := MatchModel.new()
 model.reset(seed)
 var configured := model.configure_map(theme, packed)
 check(configured and model.is_procedural(), label + " model restored the submitted V2 geometry")
 if not configured:
  return
 var door_paths: Array[float] = []
 var hall_paths: Array[float] = []
 var spawn: Vector2 = model.map_data.hunter_spawn
 check(model.navigation_walkable(spawn) and model.can_walk(model.map_data.spawn), label + " survivor/Hunter spawn points are walkable")
 for room: RoomState in model.rooms:
  var door := room.door_approach()
  var door_path := audited_route(model, spawn, door, "%s door %d" % [label, room.index + 1])
  door_paths.append(snappedf(route_length(spawn, door_path), .01))
  check_bed(model, room, model.map_data.spawn, "%s room %d" % [label, room.index + 1])
  check(grid_fit(room), "%s room %d has a useful mix of legal building sizes" % [label, room.index + 1])
  if room.index != posmod(seed, model.rooms.size()):
   continue
  room.closed = true
  check(model.navigation_path(spawn, room.bed_position()).is_empty(), label + " Hunter cannot bypass a closed intact door")
  room.door_hp = 0.0
  audited_route(model, door, room.bed_position(), label + " Hunter can enter a breached door")
  room.closed = false
  room.door_hp = room.max_hp()
 for hall in model.map_data.halls.values():
  var hall_path := audited_route(model, spawn, hall.center, label + " " + hall.id + " Hall")
  hall_paths.append(snappedf(route_length(spawn, hall_path), .01))
 grid_checks(model, label)
 if audit_alternates:
  var alternative := alternate_route_checks(model)
  alternate_counts[data.family] = alternate_counts.get(data.family, 0) + int(alternative)
 var record := metrics(data, door_paths, hall_paths)
 var profiles: Dictionary = family_profiles.get(data.family, {})
 var form := str([record.loop_rank, record.branch_degrees, record.nearby_rooms, record.room_centers_6x6, record.silhouette])
 profiles[form.sha256_text()] = true
 family_profiles[data.family] = profiles
 var graphs: Dictionary = family_graphs.get(data.family, {})
 graphs[record.graph_signature] = true
 family_graphs[data.family] = graphs
 family_counts[data.family] = family_counts.get(data.family, 0) + 1
 greatest_rooms[record.largest_room] = greatest_rooms.get(record.largest_room, 0) + 1
 measurements.append(record)

func grid_fit(room: RoomState) -> bool:
 var spatial := SpatialConstruction.new(room)
 spatial.grid = true
 var cells := spatial.grid_bounds()
 var widths := {"turret": false, "heavy": false, "shock": false}
 for kind: String in widths.keys():
  for y in range(int(cells.position.y), ceili(cells.end.y), 32):
   for x in range(int(cells.position.x), ceili(cells.end.x), 32):
    var position := spatial.aligned(Vector2(x, y), kind, 0)
    if spatial.geometry_reason(position, -1, {}, kind, 0).is_empty():
     widths[kind] = true
     break
   if widths[kind]:
    break
  if not widths[kind]:
   return false
 return true

func assert_summary():
 check(exact_hashes.size() == 600, "all 600 planned seed/theme cases yielded exact V2 maps")
 check(natural_families.size() == FAMILIES.size(), "default seed selection exposes all ten families")
 for family in FAMILIES:
  check(int(family_counts.get(family, 0)) >= 50, family + " exercised at least 50 maps across all themes")
  check(family_profiles.get(family, {}).size() >= 45, family + " shows structural variation within the family")
 for family in ["ring", "labyrinth", "hybrid"]:
  check(alternate_counts.get(family, 0) > 0, family + " offers a genuinely different legal path")
 check(greatest_rooms.size() == 6, "largest physical floor occurs in every room number across sample")

func run():
 generator = load("res://scripts/nightmare_map.gd")
 macro = load("res://scripts/nightmare_macro_layout.gd")
 if macro == null or not macro.can_instantiate():
  push_error("Unable to load the V2 generator")
  quit(2)
  return
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment(V1_FLAG, "0")
 var start := Time.get_ticks_usec()
 for theme: String in MapCatalog.IDS:
  for family: String in FAMILIES:
   for i in range(10):
    audit_map(theme, 10000 + i * 977 + FAMILIES.find(family) * 131, family, i == 0)
  for i in range(20):
   audit_map(theme, 67000 + i * 813, "")
  print("NIGHTMARE_V2_THEME theme=", theme, " cumulative_maps=", exact_hashes.size(), " failures=", failures)
 assert_summary()
 var comparisons := 0
 var adjacent_near := 0
 for i in range(1, measurements.size()):
  if measurements[i].theme != measurements[i-1].theme:
   continue
  comparisons += 1
  var previous: Dictionary = measurements[i-1]
  var current: Dictionary = measurements[i]
  if previous.loop_rank == current.loop_rank and near_similarity(previous.silhouette, current.silhouette) >= .82:
   adjacent_near += 1
 var profile_tally := {}
 for family in family_profiles:
  profile_tally[family] = family_profiles[family].size()
 var topology_tally := {}
 for family in family_graphs:
  topology_tally[family] = family_graphs[family].size()
 var receipt := {
  "maps": exact_hashes.size(), "checks": checks, "failures": failures, "routes_checked": routes_checked,
  "elapsed_seconds": (Time.get_ticks_usec() - start) / 1000000.0, "family_counts": family_counts,
  "automatic_family_counts": natural_families, "structural_signatures_per_family": profile_tally,
  "graph_signatures_per_family": topology_tally, "legal_alternates_by_family_in_five_targeted_maps": alternate_counts,
  "largest_floor_room_number": greatest_rooms, "similarity_comparisons": comparisons, "adjacent_near_repetitions": adjacent_near,
  "near_rule": "Same loop rank and >= 0.82 semantic raster Jaccard under same orientation, tight bounds normalized to 18x18.",
  "cases": measurements,
 }
 var args := OS.get_cmdline_user_args()
 if args.size() == 1 and args[0].is_absolute_path():
  var file := FileAccess.open(args[0], FileAccess.WRITE)
  if file != null:
   file.store_string(JSON.stringify(receipt, "  ") + "\n")
  else:
   check(false, "write QA evidence")
 print("NIGHTMARE_V2_DIVERSITY maps=", exact_hashes.size(), " checks=", checks, " failures=", failures, " routes=", routes_checked, " family_counts=", family_counts, " adjacent_near=", adjacent_near, "/", comparisons)
 quit(int(failures != 0))
