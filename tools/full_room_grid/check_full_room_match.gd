extends SceneTree
## Earned-only model cases for matched player-grid vs existing room behavior.

const STEP := .2
const LIMIT_SECONDS := 320.0
const CASES := [
 ["campaign", "stage_1", "standard", 11, 0],
 ["campaign", "stage_2", "hard", 23, 1],
 ["campaign", "stage_5", "hell", 47, 2],
 ["endless", "abandoned_dorm", "standard", 11, 0],
 ["endless", "haunted_hospital", "hard", 23, 1],
 ["endless", "cursed_mansion", "hell", 47, 2],
]

var failures := 0
var cached_candidates := {}
var grid := false

func _initialize():
 call_deferred("run")

func building_ids(room, kind: String) -> Array:
 return room.buildings.keys().filter(func(id): return room.buildings[id].kind == kind)

func _candidate_points(room, kind: String) -> Array:
 var key := str(room.bounds()) + kind
 if cached_candidates.has(key):
  return cached_candidates[key]
 var bounds: Rect2 = room.bounds().grow(-8)
 var sample: Array[Vector2] = []
 var unique := {}
 for y in range(floori(bounds.position.y), ceili(bounds.end.y), 16):
  for x in range(floori(bounds.position.x), ceili(bounds.end.x), 16):
   var point: Vector2 = room.spatial.aligned(Vector2(x, y), kind, 0)
   if point.is_finite() and not unique.has(point):
    sample.append(point)
    unique[point] = true
 var door: Vector2 = room.door_approach()
 sample.sort_custom(func(a, b): return a.distance_squared_to(door) < b.distance_squared_to(door))
 if kind not in ["turret", "heavy", "flame", "frost", "shock"]:
  sample.reverse()
 cached_candidates[key] = sample
 return sample

func build(model, kind: String) -> bool:
 var room = model.player()
 var price: Vector2 = room.quote_build(kind)
 if room.gold + .00001 < price.x or room.electricity + .00001 < price.y:
  return false
 if grid:
  for point in _candidate_points(room, kind):
   if room.spatial.purchase_reason(kind, point, 0) == "":
    return model.call("place_building", kind, point, 0)
  return false
 var options := []
 for index in range(room.tile_count()):
  if not room.buildings.has(index):
   options.append(index)
 var door: Vector2 = room.door_approach()
 options.sort_custom(func(a, b): return room.fixed_tile_position(a).distance_squared_to(door) < room.fixed_tile_position(b).distance_squared_to(door))
 if kind not in ["turret", "heavy", "flame", "frost", "shock"]:
  options.reverse()
 for index in options:
  if model.buy(kind, index):
   return true
 return false

func _upgrade_kind(model, kind: String, cap: int) -> bool:
 for id in building_ids(model.player(), kind):
  if model.player().buildings[id].level < cap:
   return model.upgrade_building(id)
 return false

func act(model):
 var room = model.player()
 if room.door_hp < room.max_hp() * .6:
  if model.upgrade_door() or model.repair_door():
   return
 if room.bed_level < 1 and model.upgrade_bed():
  return
 if building_ids(room, "turret").is_empty() and build(model, "turret"):
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if building_ids(room, "generator").is_empty() and build(model, "generator"):
  return
 if room.bed_level < 2 and model.upgrade_bed():
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if _upgrade_kind(model, "generator", 2):
  return
 if building_ids(room, "repair").is_empty() and build(model, "repair"):
  return
 if building_ids(room, "turret").size() < 2 and build(model, "turret"):
  return
 if _upgrade_kind(model, "turret", 4):
  return
 if building_ids(room, "heavy").is_empty() and build(model, "heavy"):
  return
 if not grid and model.run_kind == "endless" and room.tile_count() < 10 and room.buildings.size() >= room.tile_count():
  if model.expansion.purchase(model):
   return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if building_ids(room, "economy").is_empty() and build(model, "economy"):
  return
 if building_ids(room, "enhancer").is_empty() and build(model, "enhancer"):
  return
 _upgrade_kind(model, "heavy", 4)

func run_case(config: Array) -> Dictionary:
 var mode: String = config[0]
 var identifier: String = config[1]
 var difficulty: String = config[2]
 var seed: int = config[3]
 var room_index: int = config[4]
 var model := MatchModel.new()
 var invalid: Array[String] = []
 cached_candidates.clear()
 var configured := false
 if mode == "endless":
  configured = model.configure_endless(identifier, difficulty, seed, 1)
 else:
  model.reset(seed)
  configured = model.configure_match(difficulty) and model.configure_stage(identifier) and model.configure_strategy(seed)
 if not configured or not model.configure_balance():
  return {"case": config, "invalid": ["model configuration failed"]}
 if not model.claim_room(room_index):
  return {"case": config, "invalid": ["claim failed"]}
 var room = model.player()
 model.player_position = room.bed_position()
 if not model.sleep_player():
  return {"case": config, "invalid": ["sleep failed"]}
 if grid and (room.spatial == null or not room.spatial.get("grid")):
  return {"case": config, "invalid": ["grid not active in player room"]}
 var opening := Vector2(room.gold, room.electricity)
 if opening != Vector2(25, 0):
  invalid.append("opening wallet changed")
 var lowest := opening
 var peak_buildings := 0
 var selected_rooms_attacked := 0
 var own_attack_events := 0
 var last_event := 0
 var steps := 0
 var max_account_difference := 0.0
 var tick_usec: Array[int] = []
 while model.result == "" and steps < roundi(LIMIT_SECONDS / STEP):
  if mode == "endless" and model.endless.phase == "intermission":
   break
  if steps % 5 == 0:
   act(model)
  var start := Time.get_ticks_usec()
  model.tick(STEP)
  tick_usec.append(Time.get_ticks_usec() - start)
  peak_buildings = maxi(peak_buildings, room.buildings.size())
  var wallet := Vector2(room.gold, room.electricity)
  if not wallet.is_finite() or wallet.x < -.001 or wallet.y < -.001:
   invalid.append("non-finite or negative wallet")
   break
  lowest = lowest.min(wallet)
  var flow: Dictionary = room.ledger.totals
  var expected_g: float = opening.x + flow.production_g + flow.other_g + flow.refund_g - flow.spent_g - flow.loss_g
  var expected_e: float = opening.y + flow.production_e + flow.other_e + flow.refund_e - flow.spent_e - flow.loss_e
  var drift := maxf(absf(room.gold - expected_g), absf(room.electricity - expected_e))
  max_account_difference = maxf(max_account_difference, drift)
  if drift > .011:
   invalid.append("gold/electricity ledger drift")
   break
  for event in model.presentation_events:
   if int(event.id) <= last_event:
    continue
   last_event = int(event.id)
   if event.type == "door_damage":
    selected_rooms_attacked += 1
    own_attack_events += int(event.room == room_index)
  steps += 1
 if peak_buildings == 0 or room.ledger.totals.spent_g <= 0:
  invalid.append("no actual paid building action")
 for other in model.rooms:
  if other != room and other.spatial != null:
   invalid.append("NPC room routing changed")
 if tick_usec.is_empty():
  tick_usec.append(0)
 tick_usec.sort()
 var stop: String = model.result
 if stop.is_empty():
  stop = "wave_cleared" if mode == "endless" and model.endless.phase == "intermission" else "time_cap"
 return {
  "case": config, "stop": stop, "seconds": model.time, "steps": steps,
  "construction": "full_grid" if grid else ("spatial" if room.spatial != null else "legacy"),
  "building_cap_reported": room.tile_count(), "peak_buildings": peak_buildings,
  "remaining_buildings": room.buildings.size(), "shots": room.shots, "damage_dealt": room.damage_dealt,
  "door_damage_taken": room.door_damage_taken, "player_door_damage_events": own_attack_events,
  "team_door_damage_events": selected_rooms_attacked, "hunter_hp": model.hunter.hp,
  "hunter_attacks": model.hunter.attacks, "hunter_retargets": model.hunter.retargets,
  "hunter_navigation_recoveries": model.hunter.navigation_recoveries,
  "gold": room.gold, "electricity": room.electricity, "ledger": room.ledger.totals,
  "lowest_gold": lowest.x, "lowest_electricity": lowest.y, "max_ledger_error": max_account_difference,
  "tick_median_us": tick_usec[tick_usec.size() / 2],
  "tick_p95_us": tick_usec[ceili(.95 * tick_usec.size()) - 1],
  "invalid": invalid,
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute JSON output path after --.")
  quit(2)
  return
 grid = OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1"
 var rows := []
 for config in CASES:
  var row := run_case(config)
  failures += int(not row.invalid.is_empty())
  rows.append(row)
  print("FULL_ROOM_MATCH ", JSON.stringify(row))
 var save := FileAccess.open(args[0], FileAccess.WRITE)
 if save == null:
  failures += 1
 else:
  save.store_string(JSON.stringify({"grid": grid, "step": STEP, "limit_seconds": LIMIT_SECONDS,
   "fixture": "Selected room claimed and resident staged at bed; current balance, real earned wallet, no perks or inventory; identical purchase priorities and one bounded wave.",
   "runs": rows, "failures": failures}, "  ") + "\n")
 print("FULL_ROOM_MATCH_CASES=", rows.size(), " FAILURES=", failures)
 quit(1 if failures else 0)
