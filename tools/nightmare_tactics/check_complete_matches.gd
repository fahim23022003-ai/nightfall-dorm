extends "res://tests/nightmare_maps_v2_matches.gd"
## Matched before-and-after play with ordinary game actions, income, and NPCs.

const SOURCE_DIR := "res://docs/evidence/nightmare-maps-v2/qa/matches.json"
const TIME_LIMIT := 900.0
const REPETITIONS := 3
const RECORDED_EVENTS := [
 "approach", "encounter", "hunter_reassess", "hunter_commit", "elimination", "door_break",
 "hunter_evolved", "nightmare_level", "boss_transform", "boss_phase", "boss_death",
 "hunter_retreat", "hunter_recovering", "hunter_recovery_ended",
]
var arm := ""
var prior_passive_wins := {}

func apply_plan(model: MatchModel, policy: String):
 if policy == "balanced":
  act(model)
 elif policy == "needle_defense":
  defend_with_needles(model)

func new_statistics() -> Dictionary:
 return {
  "first_encounter": -1.0, "first_player_encounter": -1.0, "first_player_strike": -1.0,
  "blocked_motion_steps": 0, "speed_budget_violations": 0, "max_ledger_error": 0.0,
  "peak_player_buildings": 0, "peak_sleeping_npcs": 0, "npc_sleep_mask": 0, "peak_player_exposure": 0.0,
  "target_seconds": [0., 0., 0., 0., 0., 0.], "attack_seconds": [0., 0., 0., 0., 0., 0.],
  "door_strikes": [0, 0, 0, 0, 0, 0], "event_counts": {}, "events": [], "last_event": 0,
 }

func observe(model: MatchModel, stats: Dictionary, previous: Vector2, wallet: Vector2, prior_evolution: int) -> bool:
 var room := model.player()
 var displacement := previous.distance_to(model.hunter.position)
 if displacement > .005 and not model.navigation_walkable(model.hunter.position):
  stats.blocked_motion_steps += 1
 if displacement > model.hunter.speed * MODEL_STEP + .20:
  stats.speed_budget_violations += 1
 var target: int = model.hunter.target
 if target >= 0:
  stats.target_seconds[target] += MODEL_STEP
  if model.hunter.state in [HunterState.State.ATTACK, HunterState.State.BREACH]:
   stats.attack_seconds[target] += MODEL_STEP
 stats.peak_player_buildings = maxi(stats.peak_player_buildings, room.buildings.size())
 var simultaneously_sleeping := 0
 for other: RoomState in model.rooms:
  if other.owner > 0 and other.sleeping and other.alive:
   stats.npc_sleep_mask |= 1 << (other.owner - 1)
   simultaneously_sleeping += 1
 stats.peak_sleeping_npcs = maxi(stats.peak_sleeping_npcs, simultaneously_sleeping)
 stats.peak_player_exposure = maxf(stats.peak_player_exposure, model.contribution.exposure)
 var flow: Dictionary = room.ledger.totals
 var expected := wallet + Vector2(
  flow.production_g + flow.other_g + flow.refund_g - flow.spent_g - flow.loss_g,
  flow.production_e + flow.other_e + flow.refund_e - flow.spent_e - flow.loss_e
 )
 var drift := Vector2(room.gold, room.electricity) - expected
 stats.max_ledger_error = maxf(stats.max_ledger_error, maxf(absf(drift.x), absf(drift.y)))
 var evolve: int = model.evolution.evolution_level
 if prior_evolution != evolve:
  stats.events.append({"time": snappedf(model.time, .01), "type": "observed_evolution_level", "level": evolve, "room": target + 1})
 for event in model.presentation_events:
  var event_id: int = event.id
  if event_id <= stats.last_event:
   continue
  stats.last_event = event_id
  var kind: String = event.type
  var index: int = event.room
  stats.event_counts[kind] = stats.event_counts.get(kind, 0) + 1
  if kind == "encounter":
   if stats.first_encounter < 0:
    stats.first_encounter = model.time
   if index == model.player_room and stats.first_player_encounter < 0:
    stats.first_player_encounter = model.time
  if kind == "door_damage" and index >= 0:
   stats.door_strikes[index] += 1
   if index == model.player_room and stats.first_player_strike < 0:
    stats.first_player_strike = model.time
  if kind in RECORDED_EVENTS or kind.begins_with("hard_") or kind.begins_with("tactic_"):
   var details := {"time": snappedf(model.time, .01), "type": kind, "room": index + 1}
   for key in ["hall", "next_room", "reason", "healed", "budget", "level", "source", "buff", "ability", "action", "cause", "selected_room", "old_room", "retarget_reason", "pressure"]:
    if event.has(key):
     details[key] = event[key]
   stats.events.append(details)
 return model.hunter.position.is_finite() and is_finite(room.gold) and is_finite(room.electricity) and room.gold >= -.002 and room.electricity >= -.002 and stats.max_ledger_error <= .011

func run_match(stage: String, difficulty: String, seed: int, room_index: int, policy: String, family: String, repetition: int) -> Dictionary:
 cached_candidates.clear()
 var invalid: Array[String] = []
 var model := MatchModel.new()
 model.reset(seed)
 if "hard_tactics_enabled" in model:
  model.set("hard_tactics_enabled", arm == "candidate")
 elif arm == "candidate":
  invalid.append("Candidate model is missing its semantics gate")
 var row := {
  "case": [stage, difficulty, seed, room_index, policy], "family": family, "repetition": repetition,
  "outcome": "", "invalid": invalid,
 }
 if not model.configure_match(difficulty) or not model.configure_stage(stage) or not model.configure_strategy(seed) or not model.configure_balance():
  invalid.append("match configuration failed")
  return row
 if not model.is_procedural() or model.map_data.get("family") != family:
  invalid.append("ordinary V2 family did not match fixture")
  return row
 row.map_sha256 = JSON.stringify(NightmareMap.pack(model.map_data), "", true, true).sha256_text()
 row.prior_passive_win = policy == "passive" and prior_passive_wins.has(fixture_key(row.case))
 if not model.claim_room(room_index):
  invalid.append("room claim failed")
  return row
 var room := model.player()
 model.player_position = room.bed_position()
 if not model.sleep_player():
  invalid.append("bed placement invalid")
  return row
 var wallet := Vector2(room.gold, room.electricity)
 var stats := new_statistics()
 var steps := 0
 while model.result.is_empty() and model.time < TIME_LIMIT:
  if steps % 6 == 0:
   apply_plan(model, policy)
  var previous: Vector2 = model.hunter.position
  var prior_evolution: int = model.evolution.evolution_level
  model.tick(MODEL_STEP)
  steps += 1
  if not observe(model, stats, previous, wallet, prior_evolution):
   invalid.append("position or currency violated simulation invariant")
   break
 if model.result.is_empty():
  invalid.append("match did not reach victory or defeat")
 if policy == "passive" and (stats.peak_player_buildings != 0 or room.construction_actions != 0):
  invalid.append("passive player made an active purchase")
 if policy != "passive" and stats.peak_player_buildings == 0:
  invalid.append("earned strategy never bought a defense")
 if model.hunter.attacks == 0 or stats.npc_sleep_mask != 31:
  invalid.append("Hunter had no attacks or NPCs failed to occupy all five other rooms")
 if stats.blocked_motion_steps != 0 or stats.speed_budget_violations != 0:
  invalid.append("illegal movement or distance beyond movement budget")
 if model.haunt_recovery.attempts > 2 or model.haunt_recovery.visits > model.haunt_recovery.attempts:
  invalid.append("Hall attempts exceeded recovery budget")
 var rooms := []
 var npc_damage := 0.0
 var npc_main_damage := 0.0
 for other: RoomState in model.rooms:
  if other.owner > 0:
   npc_damage += other.damage_dealt
   npc_main_damage += other.main_damage_dealt
  rooms.append({
   "room": other.index + 1, "owner": other.owner, "alive": other.alive, "shape": other.layout.shape, "trait": other.trait_id,
   "target_seconds": snappedf(stats.target_seconds[other.index], .01), "attack_seconds": snappedf(stats.attack_seconds[other.index], .01),
   "door_strikes": stats.door_strikes[other.index], "door_damage": other.door_damage_taken,
   "hunter_damage": other.main_damage_dealt, "enemy_damage": other.damage_dealt, "shots": other.shots,
  })
 row.merge({
  "outcome": model.result, "simulated_seconds": snappedf(model.time, .01), "steps": steps,
  "player_damage": room.damage_dealt, "player_hunter_damage": room.main_damage_dealt,
  "npc_damage": npc_damage, "npc_hunter_damage": npc_main_damage, "player_door_damage": room.door_damage_taken,
  "first_encounter": snappedf(stats.first_encounter, .01), "first_player_encounter": snappedf(stats.first_player_encounter, .01),
  "first_player_strike": snappedf(stats.first_player_strike, .01), "peak_player_exposure": snappedf(stats.peak_player_exposure, .01),
  "hunter_attacks": model.hunter.attacks, "hunter_retargets": model.hunter.retargets,
  "hunter_remaining_hp": model.hunter.hp, "hunter_max_hp": model.hunter.max_hp,
  "hunter_archetype": model.hunter.archetype, "evolution_level": model.evolution.evolution_level,
  "evolution_buffs": model.evolution.acquired.duplicate(), "hunter_transformed": model.hunter.transformed,
  "recovery_attempts": model.haunt_recovery.attempts, "recovery_visits": model.haunt_recovery.visits,
  "eliminations": model.eliminations, "peak_player_buildings": stats.peak_player_buildings,
  "peak_sleeping_npcs": stats.peak_sleeping_npcs, "all_npcs_slept": stats.npc_sleep_mask == 31, "max_ledger_error": stats.max_ledger_error,
  "blocked_motion_steps": stats.blocked_motion_steps, "speed_budget_violations": stats.speed_budget_violations,
  "rooms": rooms, "event_counts": stats.event_counts, "events": stats.events,
 }, true)
 return row

func fixture_key(descriptor: Array) -> String:
 return "%s/%s/%d/%d/%s" % [descriptor[0], descriptor[1], int(descriptor[2]), int(descriptor[3]), descriptor[4]]

func load_prior_wins() -> bool:
 var receipt = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_DIR))
 if not receipt is Dictionary:
  return false
 for row in receipt.cases:
  if row.case[4] == "passive" and row.outcome == "victory":
   prior_passive_wins[fixture_key(row.case)] = true
 return prior_passive_wins.size() == 5

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["baseline", "candidate"] or args[2] not in ["0", "1", "2"]:
  push_error("Use absolute receipt path, baseline or candidate, and repetition 0–2.")
  quit(2)
  return
 arm = args[1]
 var repetition := int(args[2])
 if not load_prior_wins():
  push_error("Could not load five exact prior passive wins")
  quit(2)
  return
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "1")
 grid = true
 var macro: GDScript = load("res://scripts/nightmare_macro_layout.gd")
 var rows := []
 var started := Time.get_ticks_usec()
 for family_index in range(FAMILY_IDS.size()):
  var family: String = FAMILY_IDS[family_index]
  for difficulty_index in range(DIFFICULTIES.size()):
   var difficulty: String = DIFFICULTIES[difficulty_index]
   var theme_index := (family_index + 2 * difficulty_index + repetition * 3) % THEMES.size()
   var stage: String = THEMES[theme_index]
   var theme: String = StageCatalog.stage(stage).map
   var seed := select_seed(theme, family, 2800 + family_index * 1000 + difficulty_index * 266 + repetition * 28913, macro)
   var room_index := (family_index + difficulty_index * 3 + repetition * 2) % 6
   for policy: String in PLANS:
    var row := run_match(stage, difficulty, seed, room_index, policy, family, repetition)
    rows.append(row)
    if not row.invalid.is_empty():
     failures += 1
    print("TACTICS_MATCH ", row.case, " ", row.family, " ", row.outcome, " ", row.invalid)
 var receipt := FileAccess.open(args[0], FileAccess.WRITE)
 if receipt != null:
  receipt.store_string(JSON.stringify({
   "arm": arm, "repetition": repetition, "cases": rows, "failures": failures,
   "tick_seconds": MODEL_STEP, "simulated_time_limit": TIME_LIMIT,
   "wall_seconds": (Time.get_ticks_usec() - started) / 1000000.0,
  }, "  ") + "\n")
 else:
  failures += 1
 print("TACTICS_COMPLETE arm=", arm, " repetition=", repetition, " cases=", rows.size(), " failures=", failures)
 quit(int(failures != 0))
