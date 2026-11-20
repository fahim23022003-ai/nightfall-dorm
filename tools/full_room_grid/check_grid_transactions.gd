extends "check_full_room_match.gd"
## Compare model prices and real wallet mutations across construction modes.

var checks := 0

func expect(condition: bool, label: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(label)

func _wallet(room) -> Array[float]:
 return [room.gold, room.electricity]

func _change(before: Array[float], after: Array[float]) -> Array[float]:
 return [snappedf(after[0] - before[0], .0001), snappedf(after[1] - before[1], .0001)]

func _price(value: Vector2) -> Array[float]:
 return [snappedf(value.x, .0001), snappedf(value.y, .0001)]

func _check_role(mode: String, version: int, kind: String) -> Dictionary:
 cached_candidates.clear()
 var model := MatchModel.new()
 var placed := false
 if mode == "campaign":
  model.reset(11)
  placed = model.configure_stage("stage_1") and model.configure_strategy(11)
 else:
  placed = model.configure_endless("abandoned_dorm", "standard", 11, 1)
 var label := "%s v%d %s" % [mode, version, kind]
 var configured := placed and model.configure_balance(version) and model.claim_room(0)
 expect(configured, label + " configured")
 if not configured:
  return {}
 var room = model.player()
 model.player_position = room.bed_position()
 expect(model.sleep_player(), label + " resident sleeps")
 # This isolated transaction fixture separates prices from earning time.
 room.gold = 10000.0
 room.electricity = 1000.0
 room.bed_level = 8
 room.door_level = 8
 if version == 2 and kind in ["economy", "enhancer"]:
  expect(build(model, "generator"), label + " paid Dynamo prerequisite")
 var ids: Array = room.buildings.keys()
 var price := _price(room.quote_build(kind))
 var starting := _wallet(room)
 var purchased := build(model, kind)
 expect(purchased, label + " real purchase")
 if not purchased:
  return {}
 var build_delta := _change(_wallet(room), starting)
 expect(build_delta == price, label + " quote equals both actual wallet debits")
 var new_ids: Array = room.buildings.keys().filter(func(id): return id not in ids)
 expect(new_ids.size() == 1, label + " exactly one new identity")
 if new_ids.is_empty():
  return {}
 var id: int = new_ids[0]
 var wallet := _wallet(room)
 var snapshot: Dictionary = room.buildings.duplicate(true)
 var overlap := bool(model.call("place_building", kind, room.tile_position(id), 0)) if grid else model.buy(kind, id)
 expect(not overlap and _wallet(room) == wallet and room.buildings == snapshot, label + " overlap rejected transactionally")
 expect(model.upgrade_building(id), label + " paid L2 upgrade")
 var upgrade_delta := _change(_wallet(room), wallet)
 var b: Dictionary = room.buildings[id]
 var invested := _price(Vector2(b.invested_gold, b.invested_power))
 expect(invested == [snappedf(build_delta[0] + upgrade_delta[0], .0001), snappedf(build_delta[1] + upgrade_delta[1], .0001)], label + " investments equal actual debits")
 var refund := _price(room.building_refund(id))
 expect(refund == [snappedf(invested[0] * Catalog.BUILDING_REFUND_FRACTION, .0001), snappedf(invested[1] * Catalog.BUILDING_REFUND_FRACTION, .0001)], label + " refund basis unchanged")
 wallet = _wallet(room)
 expect(model.sell_building(id), label + " actual sale")
 var sale_delta := _change(wallet, _wallet(room))
 expect(sale_delta == refund, label + " both currencies credited exactly")
 wallet = _wallet(room)
 expect(not model.sell_building(id) and _wallet(room) == wallet and not room.buildings.has(id), label + " repeated sale cannot refund")
 return {"mode": mode, "balance_version": version, "kind": kind, "quote": price,
  "build_debit": build_delta, "upgrade_debit": upgrade_delta, "invested": invested,
  "refund_quote": refund, "actual_refund": sale_delta}

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute JSON output path after --.")
  quit(2)
  return
 grid = OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1"
 var rows := []
 for mode in ["campaign", "endless"]:
  for version in [1, 2]:
   for kind in Catalog.BUILDINGS:
    rows.append(_check_role(mode, version, kind))
 var file := FileAccess.open(args[0], FileAccess.WRITE)
 expect(file != null, "transaction output writable")
 if file != null:
  file.store_string(JSON.stringify({"grid": grid, "checks": checks, "failures": failures, "rows": rows}, " ") + "\n")
 print("FULL_GRID_TRANSACTION_CASES=", rows.size(), " CHECKS=", checks, " FAILURES=", failures)
 quit(int(failures != 0))
