extends "res://tools/full_room_grid/check_full_room_match.gd"
## Opt-in or fallback match matrix. Players spend only money earned in the match.

const MODEL_STEP := .15
const LIMIT := 600.0
const POLICIES := ["passive", "balanced"]
const THEMES := ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5"]

func defend_with_needles(model: MatchModel) -> void:
 var room: RoomState = model.player()
 if room.door_hp < room.max_hp() * .62 and model.repair_door():
  return
 var needle_count := building_ids(room, "turret").size()
 if needle_count == 0 and build(model, "turret"):
  return
 if room.bed_level < 1 and model.upgrade_bed():
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if needle_count < 3 and build(model, "turret"):
  return
 if _upgrade_kind(model, "turret", 2):
  return
 if room.bed_level < 2 and model.upgrade_bed():
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if _upgrade_kind(model, "turret", 3):
  return
 if building_ids(room, "generator").is_empty() and build(model, "generator"):
  return
 if building_ids(room, "repair").is_empty() and build(model, "repair"):
  return
 if _upgrade_kind(model, "generator", 2):
  return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if _upgrade_kind(model, "turret", 4):
  return
 if needle_count < 5:
  build(model, "turret")

func simulate(stage: String, difficulty: String, seed: int, room_index: int, policy: String) -> Dictionary:
 cached_candidates.clear()
 var model := MatchModel.new()
 model.reset(seed)
 var invalid: Array[String] = []
 if not model.configure_match(difficulty) or not model.configure_stage(stage) or not model.configure_strategy(seed) or not model.configure_balance():
  return {"case": [stage, difficulty, seed, room_index, policy], "invalid": ["configuration failed"]}
 if not model.claim_room(room_index):
  return {"case": [stage, difficulty, seed, room_index, policy], "invalid": ["claim failed"]}
 var room: RoomState = model.player()
 model.player_position = room.bed_position()
 if not model.sleep_player():
  return {"case": [stage, difficulty, seed, room_index, policy], "invalid": ["bed placement invalid"]}
 var procedural: bool = model.map_data.has("halls")
 var initial_wallet := Vector2(room.gold, room.electricity)
 var peak_buildings := 0
 var max_drift := 0.0
 var blocked_steps := 0
 var speed_violations := 0
 var recoveries := []
 var latest_event := 0
 var npc_peak := 0
 var steps := 0
 var trace: Array=[]
 var room_pressure: Dictionary={}
 var travelled:=0.0
 var track_decisions:=OS.get_environment("NIGHTFALL_TRACE_TARGETING")=="1"
 while model.result.is_empty() and model.time < LIMIT:
  if steps % 6 == 0:
   if policy == "balanced":
    act(model)
   elif policy == "needle_defense":
    defend_with_needles(model)
  var previous: Vector2 = model.hunter.position
  model.tick(MODEL_STEP)
  steps += 1
  if not model.hunter.position.is_finite():
   invalid.append("nonfinite Hunter position")
   break
  var displacement: float = previous.distance_to(model.hunter.position)
  if track_decisions:
   travelled+=displacement
   if model.hunter.state==HunterState.State.ATTACK and model.hunter.target>=0:
    var target: int=model.hunter.target
    room_pressure[target]=room_pressure.get(target,0.0)+MODEL_STEP
  if procedural and displacement > .005 and not model.navigation_walkable(model.hunter.position):
   blocked_steps += 1
  if displacement > model.hunter.speed * MODEL_STEP + .2:
   speed_violations += 1
  if not is_finite(room.gold) or not is_finite(room.electricity) or room.gold < -.002 or room.electricity < -.002:
   invalid.append("wallet became invalid")
   break
  var flow: Dictionary = room.ledger.totals
  var expected := initial_wallet + Vector2(
   flow.production_g + flow.other_g + flow.refund_g - flow.spent_g - flow.loss_g,
   flow.production_e + flow.other_e + flow.refund_e - flow.spent_e - flow.loss_e
  )
  var drift := Vector2(room.gold, room.electricity) - expected
  max_drift = maxf(max_drift, maxf(absf(drift.x), absf(drift.y)))
  if max_drift > .011:
   invalid.append("wallet and economy ledger diverged")
   break
  peak_buildings = maxi(peak_buildings, room.buildings.size())
  npc_peak = maxi(npc_peak, model.rooms.filter(func(resident): return resident.owner > 0 and resident.alive and resident.sleeping).size())
  for event in model.presentation_events:
   if int(event.id) <= latest_event:
    continue
   latest_event = int(event.id)
   if track_decisions and event.type in ["approach","encounter","hunter_target_choice","hunter_commit","hunter_reassess","resident_defeat","elimination"]:
    trace.append({"type":event.type,"room":event.room,"time":event.time,"reason":event.get("reason",""),
     "next":event.get("next_room",-1),"progress":event.get("progress",0.0)})
   if event.type in ["hunter_retreat", "hunter_recovering", "hunter_recovery_ended"]:
    recoveries.append({"event": event.type, "hall": event.get("hall", ""), "time": event.time, "amount": event.get("healed", 0.0), "reason": event.get("reason", "")})
 if model.result.is_empty():
  invalid.append("did not reach normal victory/defeat in ≤600 seconds")
 if policy != "passive" and peak_buildings == 0:
  invalid.append("active policy never made a real purchase")
 if policy == "passive" and (peak_buildings > 0 or room.construction_actions > 0):
  invalid.append("passive policy purchased a machine")
 if model.hunter.attacks == 0:
  invalid.append("Hunter never reached combat")
 if npc_peak < 4:
  invalid.append("NPC survivors did not claim and sleep as expected")
 if blocked_steps > 0:
  invalid.append("Hunter moved to nonwalking surface %d times" % blocked_steps)
 if speed_violations > 0:
  invalid.append("Hunter exceeded movement budget %d times" % speed_violations)
 var recovery = model.get("haunt_recovery")
 var attempts: int = recovery.attempts if recovery != null else 0
 var visits: int = recovery.visits if recovery != null else 0
 if visits > 2 or attempts > 2 or visits > attempts:
  invalid.append("Hall retry or visit budget violated")
 return {
  "case": [stage, difficulty, seed, room_index, policy], "procedural": procedural,
  "map": model.map_id, "shape": room.layout.get("shape", "fixed"),
  "outcome": model.result, "seconds": snappedf(model.time, .01), "steps": steps,
  "npc_peak": npc_peak, "peak_buildings": peak_buildings, "shots": model.shots,
  "player_damage": room.damage_dealt, "door_damage": room.door_damage_taken,
  "hunter_attacks": model.hunter.attacks, "hunter_retargets": model.hunter.retargets,
  "hunter_navigation_recoveries": model.hunter.navigation_recoveries, "recovery_attempts": attempts,
  "recovery_visits": visits, "recovery_events": recoveries, "max_ledger_error": max_drift,
  "targeting_trace":trace,"seconds_by_siege_room":room_pressure,
  "hunter_travel_world_units":travelled,"room_eliminations":model.eliminations,
  "blocked_motion_steps": blocked_steps, "speed_budget_violations": speed_violations, "invalid": invalid
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [1, 2] or not args[0].is_absolute_path() or (args.size() == 2 and args[1] != "needle"):
  push_error("Pass an absolute JSON output path and optional needle matrix argument after --.")
  quit(2)
  return
 grid = OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1"
 var rows := []
 var totals := {}
 var selected_policies := ["needle_defense"] if args.size() == 2 else POLICIES
 for i in range(THEMES.size()):
  for j in range(RankCatalog.DIFFICULTIES.size()):
   var difficulty: String = RankCatalog.DIFFICULTIES.keys()[j]
   var seed := 37 + i * 11 + j * 7
   var room_index := (i + 2 * j) % 6
   for policy in selected_policies:
    var row := simulate(THEMES[i], difficulty, seed, room_index, policy)
    rows.append(row)
    if not row.invalid.is_empty():
     failures += 1
    var key: String = "%s/%s/%s" % [difficulty, policy, row.get("outcome", "invalid")]
    totals[key] = totals.get(key, 0) + 1
    print("NIGHTMARE_MATCH ", JSON.stringify(row))
 var save := FileAccess.open(args[0], FileAccess.WRITE)
 if save == null:
  failures += 1
 else:
  save.store_string(JSON.stringify({
   "cases": rows, "failures": failures, "outcomes": totals, "step": MODEL_STEP, "limit_seconds": LIMIT,
   "fixture": "All themes and difficulty modes, deterministic seed and repeated room/difficulty pair for passive and earned defensive policies. Starts with normal opening wages; survivor is initially staged at the bed before normal sleep interaction."
  }, "  ") + "\n")
 print("NIGHTMARE_MATCHES cases=", rows.size(), " outcomes=", totals, " failures=", failures)
 quit(int(failures != 0))
