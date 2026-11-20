extends SceneTree
## Check generation, tactics eligibility, and paid placement from the embedded Windows PCK.

var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(condition: bool, message: String):
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func run():
 var expected_map := 2 if OS.get_environment("NIGHTFALL_PROCEDURAL_MAPS_V2") == "1" else 1 if OS.get_environment("NIGHTFALL_PROCEDURAL_MAPS") == "1" else 0
 if expected_map==2 and OS.get_environment("NIGHTFALL_CLOSE_QUARTERS")=="1":expected_map=NightmareMap.CLOSE_QUARTERS_VERSION
 for difficulty in ["standard", "hard", "hell"]:
  var model := MatchModel.new()
  model.reset(73)
  check(model.configure_match(difficulty), "packaged Campaign difficulty " + difficulty)
  check(model.configure_stage("stage_5"), "packaged Stage 5 setup")
  check(model.configure_balance(), "current packaged balance")
  check(model.configure_strategy(73, "crusher"), "packaged Crusher configured")
  check(model.map_data.get("version", 0) == expected_map, "launcher selects the expected generator")
  check(model.rooms.size() == 6, "six actual packaged campaign rooms")
  check(model.uses_tactical_sieges() == (expected_map >= 2 and difficulty != "standard"), "packaged tactics gating")
  if expected_map > 0:
   check(model.map_data.halls.size() == 4, "generated packed map has four Halls")
   for hall: Dictionary in model.map_data.halls.values():
    var path := model.navigation_path(model.map_data.hunter_spawn, hall.center)
    check(not path.is_empty() and path.back() == hall.center, "reachable packed " + str(hall.name))
   var encoded := NightmareMap.pack(model.map_data)
   var decoded := NightmareMap.unpack(JSON.parse_string(JSON.stringify(encoded, "", true, true)), model.map_id)
   check(not decoded.is_empty() and NightmareMap.pack(decoded) == encoded, "packed map geometry roundtrip")
  check(model.claim_room(0), "claim first room in the package")
  var room := model.player()
  if room != null:
   model.player_position = room.bed_position()
   check(model.sleep_player(), "occupy the room")
   var expected_grid := OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1" or expected_map > 0
   check((room.spatial != null and room.spatial.grid) == expected_grid, "construction follows launcher")
   if expected_grid:
    check(place_machine(model, room), "a paid machine fits in the packaged grid")
  var endless := MatchModel.new()
  check(endless.configure_endless("cursed_mansion", difficulty, 73, 1), "launch packed Endless")
  check(not endless.uses_tactical_sieges(), "Endless retains its reviewed rules")
 if OS.get_environment("NIGHTFALL_CHECK_FAIR_START")=="1":
  var opening:=MatchModel.new()
  opening.reset(10358)
  check(opening.configure_match("hell") and opening.configure_stage("stage_2"),"configure packaged Hell Labyrinth start")
  check(opening.configure_strategy(10358) and opening.configure_balance(),"configure ordinary opening without a loadout")
  check(opening.opening_room_forecast(1).get("early_siege_risk",false),"packaged Room 2 reports the fast Hunter route")
  check(opening.claim_room(1) and opening.player().gold==25.0 and opening.player().electricity==0.0,"packaged ordinary starting wallet")
  print("FAIR_START_PACK_CHECKED=true")
 print("HELL_TACTICS_WINDOWS_PACK_CHECKS=", checks, " FAILURES=", failures, " MAP_VERSION=", expected_map, " NATIVE_WINDOWS=UNVERIFIED")
 quit(1 if failures else 0)

func place_machine(model: MatchModel, room: RoomState) -> bool:
 var bounds: Rect2 = room.bounds()
 for y in range(16, int(bounds.size.y), 16):
  for x in range(16, int(bounds.size.x), 16):
   var point := room.spatial.aligned(bounds.position + Vector2(x, y), "turret")
   if room.spatial.purchase_reason("turret", point) == "":
    return model.place_building("turret", point)
 return false
