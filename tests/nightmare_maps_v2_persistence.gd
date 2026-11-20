extends "res://tests/nightmare_maps_runtime.gd"
## End-to-end schema and disk profile preservation across generator selections.

const V2_FLAG := "NIGHTFALL_PROCEDURAL_MAPS_V2"
const V1_FLAG := "NIGHTFALL_PROCEDURAL_MAPS"

func set_preview(version: int) -> void:
 OS.set_environment(V2_FLAG, str(int(version == 2)))
 OS.set_environment(V1_FLAG, str(int(version == 1)))
 OS.set_environment(GRID_ENV, "1")

func move_checks(model: MatchModel, bought_id: int):
 var room := model.player()
 var bought: Dictionary = room.buildings[bought_id].duplicate()
 var wallet := Vector2(room.gold, room.electricity)
 var area := room.spatial.grid_bounds()
 var destination := Vector2.INF
 var angle := posmod(int(bought.rotation) + 1, 4)
 for y in range(int(area.position.y), ceili(area.end.y), 16):
  for x in range(int(area.position.x), ceili(area.end.x), 16):
   var at := room.spatial.aligned(Vector2(x, y), bought.kind, angle)
   if at.distance_to(bought.position) > 30.0 and room.spatial.geometry_reason(at, bought_id, {}, bought.kind, angle).is_empty():
    destination = at
    break
  if destination.is_finite():
   break
 check(destination.is_finite() and model.begin_building_move(bought_id), "begin a real movable grid transaction")
 if not destination.is_finite() or room.spatial.moving_id != bought_id:
  return
 var cutout: Rect2 = room.layout.voids[0]
 var blocked := room.spatial.aligned(cutout.get_center(), bought.kind, angle)
 check(not model.move_building(blocked, angle) and room.buildings[bought_id] == bought, "invalid rotated move in room cutout preserves building")
 check(model.move_building(destination, angle), "legal rotated move uses free irregular room floor")
 check(room.buildings[bought_id].instance_id == bought.instance_id and room.tile_position(bought_id) == destination, "move keeps investment identity")
 check(room.spatial.undo(model) and room.buildings[bought_id] == bought, "undo restores exact original machine and footprint")
 check(Vector2(room.gold, room.electricity) == wallet, "rejected move, legal move, and undo preserve both balances")

func disk_checkpoint(source: int, restore_with: int, seed: int):
 set_preview(source)
 var theme := "cursed_mansion"
 var path := "user://nightmare-v2-qa-%s-%s.json" % [source, Time.get_ticks_usec()]
 var profile := PlayerProfile.new(path)
 var entry := profile.begin_endless(theme, "standard", seed)
 check(not entry.is_empty(), "profile started isolated V%d checkpoint fixture" % source)
 if entry.is_empty():
  return
 var model := new_endless(theme, seed, int(entry.run_id), RankCatalog.bonuses(entry.equipped))
 check(model != null and model.map_data.get("version") == source, "normal launch selects V%d" % source)
 if model == null:
  return
 var irregular := model.rooms.filter(func(room): return not room.layout.voids.is_empty())
 check(not irregular.is_empty() and claim_and_sleep(model, irregular[posmod(seed, irregular.size())].index), "normally claim and occupy an irregular room")
 var player := model.player()
 if player == null:
  return
 player.gold = 320.0
 check(buy_fixture_building(model), "paid a real grid building")
 var original_shape := NightmareMap.pack(model.map_data)
 check(not original_shape.is_empty() and player.buildings.size() == 1, "record exact map and single machine")
 if player.buildings.is_empty():
  return
 var bought_id := int(player.buildings.keys()[0])
 move_checks(model, bought_id)
 var bought: Dictionary = player.buildings[bought_id].duplicate()
 model.haunt_recovery.attempts = 1
 model.haunt_recovery.visits = 1
 model.haunt_recovery.available_at = 123.0
 var budget := model.haunt_recovery.snapshot()
 # Procedural saves occur at sealed intermissions. Killing the staged Hunter
 # proves the checkpoint format without relying on a particular build order.
 model.hunter.state = HunterState.State.DEAD
 model.hunter.hp = 0.0
 model.tick(.1)
 check(model.endless.phase == "intermission", "normal wave finish opens save boundary")
 check(profile.checkpoint_endless(model), "write V%d checkpoint through profile" % source)
 var snapshot := ReplaySnapshot.encode(model)
 check(ReplaySnapshot.valid(snapshot), "checkpoint validates")
 if not snapshot.is_empty() and source == 2:
  var malformed := snapshot.duplicate(true)
  malformed.generated_map.family = "unknown-family"
  check(not ReplaySnapshot.valid(malformed), "bad family metadata fails validation")
  malformed = snapshot.duplicate(true)
  malformed.generated_map.halls.erase("east")
  check(not ReplaySnapshot.valid(malformed), "incomplete hall geometry fails validation")
  malformed = snapshot.duplicate(true)
  malformed.generated_map.links[0] = [9999, 9998]
  check(not ReplaySnapshot.valid(malformed), "out-of-bounds graph indices fail validation")
 var original_sha := FileAccess.get_sha256(path)
 set_preview(restore_with)
 var disk := PlayerProfile.new(path)
 check(disk.load_profile() and not disk.read_only, "disk profile reads across generator toggle")
 var resumed: MatchModel = disk.resume_endless()
 check(resumed != null, "regular Resume loads V%d under preview V%d" % [source, restore_with])
 if resumed != null:
  check(NightmareMap.pack(resumed.map_data) == original_shape, "no reroll or geometry conversion across preview toggle")
  check(resumed.map_data.get("version") == source and canonical_equal(resumed.haunt_recovery.snapshot(), budget), "save retains generator version and exact recovery limits")
  var restored: Dictionary = resumed.player().buildings.get(bought_id, {})
  for property in ["kind", "level", "rotation", "position", "invested_gold", "invested_power"]:
   check(canonical_equal(restored.get(property), bought.get(property)), "restored original machine " + property)
  check(resumed.continue_wave("repair") and NightmareMap.pack(resumed.map_data) == original_shape, "next wave keeps saved geometry")
 check(FileAccess.get_sha256(path) == original_sha, "Resume did not rewrite the persisted checkpoint")
 for candidate in [path, path + ".bak"]:
  if FileAccess.file_exists(candidate):
   DirAccess.remove_absolute(candidate)

func extreme_seeds() -> void:
 var macro: GDScript = load("res://scripts/nightmare_macro_layout.gd")
 for seed: int in [-9223372036854775807, -1, 0, 1, 9223372036854775807]:
  var first: Dictionary = macro.generate("underground_lab", seed)
  var packed := NightmareMap.pack(first)
  var decoded := NightmareMap.unpack(JSON.parse_string(JSON.stringify(packed, "", true, true)), "underground_lab")
  check(not decoded.is_empty() and decoded.seed == seed and NightmareMap.pack(decoded) == packed, "edge seed %s round-trips without truncation" % seed)

func run():
 generator = load("res://scripts/nightmare_map.gd")
 disk_checkpoint(1, 2, 122)
 disk_checkpoint(2, 0, 708)
 extreme_seeds()
 var original_hash := FileAccess.get_sha256(LEGACY_EARNED)
 set_preview(2)
 var legacy := ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string(LEGACY_EARNED)))
 check(legacy != null and not legacy.is_procedural(), "fixed checkpoint stays fixed with V2 enabled")
 check(FileAccess.get_sha256(LEGACY_EARNED) == original_hash, "original legacy artifact is untouched")
 print("NIGHTMARE_V2_PERSISTENCE checks=", checks, " failures=", failures)
 quit(int(failures != 0))
