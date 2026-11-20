extends SceneTree
## Independent audit of the procedural payload without a running match.

const SEEDS := [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597]
const SHAPES := ["rectangle", "long", "l", "u", "zigzag"]
const HALLS := ["north", "south", "west", "east"]
var checks := 0
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(description)

func room_checks(generator: GDScript, room: Dictionary, description: String) -> void:
 var bounds: Rect2 = room.bounds
 var area := 0.0
 for strip in room.floor:
  check(bounds.encloses(strip) and strip.has_area(), description + " floor strip is bounded")
  check(generator.contains_rect(room, strip), description + " strip is full floor")
  area += strip.get_area()
 for i in range(room.floor.size()):
  for j in range(i):
   check(not room.floor[i].intersects(room.floor[j]), description + " floor strips do not overlap")
 check(area > 0.0 and area <= bounds.get_area(), description + " floor area is bounded")
 if room.shape in ["l", "u", "zigzag"]:
  check(area < bounds.get_area() and not room.voids.is_empty(), description + " irregular room has genuine cutouts")
 for gap in room.voids:
  check(not generator.contains_point(room, gap.get_center()), description + " cutout excludes floor")
  check(not generator.contains_rect(room, gap.grow(-1.0)), description + " cutout excludes rectangular construction")
 for fixture in ["bed", "cabinet", "plant"]:
  check(generator.contains_point(room, room[fixture]), description + " usable " + fixture + " anchor")
 for slot in room.tiles:
  check(generator.contains_point(room, slot), description + " NPC legacy tile lies inside room")
 check(room.door_normal in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN], description + " cardinal door")
 check(generator.contains_point(room, room.door - room.door_normal * 15.0), description + " door leads inside")
 check(not generator.contains_point(room, room.door + room.door_normal * 15.0), description + " door faces exterior")

func run() -> void:
 var source: GDScript = load("res://scripts/nightmare_map.gd")
 if source == null or not source.can_instantiate():
  push_error("Procedural generator failed to load")
  quit(2)
  return
 var signatures := {}
 var best_slots := {}
 var orientations := {}
 var shape_histogram := {}
 for theme in MapCatalog.IDS:
  var theme_shapes := {}
  var theme_choices := {}
  var previous := ""
  for seed in SEEDS:
   var label := "%s/%d" % [theme, seed]
   var first: Dictionary = source.generate(theme, seed)
   if first.is_empty():
    check(false, label + " generates")
    continue
   var packed: Dictionary = source.pack(first)
   check(not packed.is_empty(), label + " encodes geometry")
   check(packed == source.pack(source.generate(theme, seed)), label + " same seed is deterministic")
   var serialized := JSON.stringify(packed)
   var restored: Dictionary = source.unpack(JSON.parse_string(serialized), theme)
   check(not restored.is_empty() and source.pack(restored) == packed, label + " exact JSON geometry roundtrip")
   check(source.unpack(JSON.parse_string(serialized), MapCatalog.IDS[(MapCatalog.IDS.find(theme) + 1) % MapCatalog.IDS.size()]).is_empty(), label + " rejects cross-theme substitution")
   if seed == SEEDS[0]:
    var broken := packed.duplicate(true)
    broken.halls.erase("north")
    check(source.unpack(broken, theme).is_empty(), label + " rejects incomplete Hall set")
    broken = packed.duplicate(true)
    broken.links.clear()
    check(source.unpack(broken, theme).is_empty(), label + " rejects disconnected exterior evidence")
    broken = packed.duplicate(true)
    broken.rooms[0].mask = 0
    check(source.unpack(broken, theme).is_empty(), label + " rejects invalid room floor mask")
   var signature := JSON.stringify(first.rooms).sha256_text()
   check(previous.is_empty() or signature != previous, label + " geometry differs from previous seed")
   check(not signatures.has(label.split("/")[0] + signature), label + " room geometry is unique within sample")
   signatures[theme + signature] = true
   previous = signature
   check(first.theme == MapCatalog.map(theme).theme and first.id == theme and first.seed == seed, label + " theme identity")
   check(first.rooms.size() == 6, label + " six selectable rooms")
   if first.rooms.size() != 6:
    continue
   var largest_slots := []
   var largest_area := -1.0
   for i in range(first.rooms.size()):
    var room: Dictionary = first.rooms[i]
    room_checks(source, room, "%s room %d" % [label, i + 1])
    theme_shapes[room.shape] = true
    orientations[room.door_normal] = true
    shape_histogram[room.shape] = shape_histogram.get(room.shape, 0) + 1
    var area := 0.0
    for strip in room.floor:
     area += strip.get_area()
    if area > largest_area:
     largest_area = area
     largest_slots = [i]
    elif area == largest_area:
     largest_slots.append(i)
    for j in range(i):
     check(not room.bounds.intersects(first.rooms[j].bounds), label + " room envelopes do not overlap")
   for index in largest_slots:
    theme_choices[index] = theme_choices.get(index, 0) + 1
   check(first.halls.size() == 4, label + " has exactly four halls")
   var room_extent: Rect2 = first.rooms[0].bounds
   for room in first.rooms:
    room_extent = room_extent.merge(room.bounds)
   for direction in HALLS:
    check(first.halls.has(direction), label + " has a " + direction + " hall")
    if not first.halls.has(direction):
     continue
    var hall: Dictionary = first.halls[direction]
    check(hall.id == direction and hall.bounds.has_point(hall.center) and first.bounds.encloses(hall.bounds), label + " valid hall identity and extent")
    match direction:
     "north": check(hall.center.y < room_extent.position.y, label + " north Hall lies beyond rooms")
     "south": check(hall.center.y > room_extent.end.y, label + " south Hall lies beyond rooms")
     "west": check(hall.center.x < room_extent.position.x, label + " west Hall lies beyond rooms")
     "east": check(hall.center.x > room_extent.end.x, label + " east Hall lies beyond rooms")
   check(first.bounds.has_point(first.spawn) and first.bounds.has_point(first.hunter_spawn), label + " spawn points fit map")
  for shape in SHAPES:
   check(theme_shapes.has(shape), theme + " generates shape " + shape)
  check(theme_choices.size() >= 3, theme + " largest room rotates across room numbers")
  best_slots[theme] = theme_choices
 check(orientations.size() == 4, "all four door orientations are represented")
 print("NIGHTMARE_GEOMETRY maps=", signatures.size(), " checks=", checks, " failures=", failures, " shapes=", shape_histogram, " largest_floor_histogram=", best_slots)
 quit(1 if failures else 0)
