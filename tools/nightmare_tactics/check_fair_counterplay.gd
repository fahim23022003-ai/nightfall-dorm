extends "res://tools/nightmare_tactics/audit_siege_pressure.gd"
## V2.1/V2.2 comparison. No match resources are granted by the harness.

const EXACT := [
 ["stage_2", "hell", 10358, 1, "labyrinth"],
 ["stage_4", "hell", 12336, 3, "hybrid"],
]
const STRATEGIES := [
 "passive", "balanced", "needle_defense", "survival_transition", "economic_rush",
 "door_reserve", "frost_arc", "precision_layout", "earned_repair",
]
const LATE_FIXTURES := [
 ["stage_5", "standard", 37719, 2, "twin_wings"],
 ["stage_2", "hard", 63906, 4, "spine"],
 ["stage_4", "hard", 60899, 1, "ring"],
 ["stage_3", "hell", 37278, 1, "radial"],
 ["stage_5", "hell", 70169, 1, "hybrid"],
]
const ALTERNATE_STARTS := [
 ["stage_2", "hell", 10358, 0, "needle_defense", "labyrinth"],
 ["stage_2", "hell", 10358, 3, "balanced", "labyrinth"],
 ["stage_4", "hell", 12336, 2, "survival_transition", "hybrid"],
]
const PREPARED_CAPITAL := Vector2(2250.0,210.0)
var variant := ""
var configured_model_id := 0
var item_profile: PlayerProfile
var earned_profile_file := ""
var item_log := []
var moved := false
var specialized := 0
var control_hits := 0
var approach_samples := []
var strategy_actions := []
var tactical_breaks := []
var opening_gold := -1.0
var opening_power := -1.0
var warmup_receipt := {}

func configure_once(model: MatchModel, plan: String):
 if configured_model_id == model.get_instance_id():
  return
 configured_model_id = model.get_instance_id()
 if "fair_siege_enabled" in model:
  model.set("fair_siege_enabled", variant == "v22")
 opening_gold = model.player().gold
 opening_power = model.player().electricity
 if plan in ["staged_precision","staged_suppression"]:
  var room := model.player()
  room.gold += PREPARED_CAPITAL.x
  room.electricity += PREPARED_CAPITAL.y
  room.ledger.note("other",[PREPARED_CAPITAL.x,PREPARED_CAPITAL.y],"staged specialization treasury")
 if plan in ["earned_repair","earned_control"] and not earned_profile_file.is_empty():
  var target_path := "user://fair-trial-item-" + str(model.get_instance_id()) + ".json"
  DirAccess.copy_absolute(earned_profile_file, target_path)
  item_profile = PlayerProfile.new(target_path)
  if item_profile.load_profile():
   item_profile.begin_match(model.difficulty, "", false)
   item_profile.bind_items(model, int(item_profile.active_match.get("id", 0)))

func apply_plan(model: MatchModel, policy: String):
 configure_once(model, policy)
 if policy in ["staged_precision","staged_suppression"]:
  use_prepared_specialization(model,"precision" if policy == "staged_precision" else "suppression")
  return
 if policy in ["passive", "balanced", "needle_defense", "survival_transition"]:
  super(model, policy)
  return
 var room := model.player()
 var hunter := model.hunter
 var threat := hunter.target == room.index and hunter.position.distance_to(room.door_approach()) <= 150.0
 if policy == "earned_repair":
  if threat and room.door_hp < room.max_hp() * .63 and use_earned(model, 0, "repair"):
   return
  super(model, "survival_transition")
  return
 if policy == "earned_control":
  if use_earned(model, 0, "gold") or use_earned(model, 1, "battery"):
   return
  if room.bed_level >= 1 and room.door_level >= 1 and building_ids(room, "frost").is_empty() and build(model,"frost"):
   return
  policy = "frost_arc"
 if policy == "branch_focus":
  specialize_one(model,threat)
  return
 if policy == "approach_fire":
  if room.bed_level < 1 and model.upgrade_bed():
   return
  if room.door_level < 1 and model.upgrade_door():
   return
  if threat and room.door_hp < room.max_hp() * .56 and model.repair_door():
   return
  if building_ids(room, "turret").size() < 5 and build_toward_approach(model):
   return
  policy = "frost_arc"
 if threat and room.door_hp < room.max_hp() * .82:
  if room.door_level < 3 and model.upgrade_door():
   return
  if hunter.state == HunterState.State.ATTACK and hunter.cooldown <= 1.4 and model.route_defense_power():
   return
  if room.door_hp < room.max_hp() * .56 and model.repair_door():
   return
 if room.bed_level < 1 and model.upgrade_bed():
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if policy == "economic_rush" and room.bed_level < 2 and model.upgrade_bed():
  return
 var needles := building_ids(room, "turret")
 if needles.is_empty() and build_first(model, policy):
  return
 if policy == "precision_layout" and not moved and model.time >= 25.0 and model.time < model.preparation and not needles.is_empty():
  if reposition_first(model, int(needles[0])):
   return
 if policy == "door_reserve" and room.door_level < 2 and model.upgrade_door():
  return
 if policy == "door_reserve" and needles.size() < 3 and build(model, "turret"):
  return
 if building_ids(room, "generator").is_empty() and build(model, "generator"):
  return
 if policy == "frost_arc" and building_ids(room, "frost").is_empty() and build(model, "frost"):
  return
 if policy == "frost_arc" and building_ids(room, "shock").is_empty() and build(model, "shock"):
  return
 if room.bed_level < 2 and model.upgrade_bed():
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if room.gold > 100.0 and building_ids(room, "repair").is_empty() and build(model, "repair"):
  return
 if needles.size() < 3 and build(model, "turret"):
  return
 if policy in ["economic_rush","frost_arc"] and building_ids(room, "heavy").is_empty() and build(model, "heavy"):
  return
 if _upgrade_kind(model, "turret", 3):
  return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if _upgrade_kind(model, "turret", 4):
  return
 if room.bed_level < 4 and model.upgrade_bed():
  return
 if room.door_level < 4 and model.upgrade_door():
  return
 for selector in needles:
  if room.buildings[selector].level == 4 and model.specialize_building(selector, "suppression" if policy == "frost_arc" else "precision"):
   specialized += 1
   strategy_actions.append({"type":"specialized","time":model.time,"kind":"turret","id":selector,"branch":room.buildings[selector].specialization})
   return
 if building_ids(room, "heavy").is_empty() and build(model, "heavy"):
  return
 _upgrade_kind(model, "heavy", 4)

func use_prepared_specialization(model: MatchModel, branch: String):
 var room := model.player()
 if room.bed_level < 4 or room.door_level < 4:
  if room.bed_level <= room.door_level and room.bed_level < 4:
   model.upgrade_bed()
  else:
   model.upgrade_door()
  return
 var guns := building_ids(room,"turret")
 if guns.is_empty():
  build(model,"turret")
  return
 var selector: int = guns[0]
 if room.buildings[selector].level < 4:
  model.upgrade_building(selector)
  return
 if room.buildings[selector].level == 4:
  var before := Vector2(room.gold,room.electricity)
  if model.specialize_building(selector,branch):
   specialized += 1
   var spent := before - Vector2(room.gold,room.electricity)
   strategy_actions.append({
    "type":"specialized","time":model.time,"id":selector,"branch":branch,
    "level":room.buildings[selector].level,"paid_gold":spent.x,"paid_power":spent.y,
   })
  return
 super.apply_plan(model,"survival_transition")

func specialize_one(model: MatchModel, threat: bool):
 var room := model.player()
 if threat and room.door_hp < room.max_hp() * .58:
  if model.upgrade_door() or model.repair_door():
   return
 if room.bed_level < 1 and model.upgrade_bed():
  return
 var guns := building_ids(room, "turret")
 if guns.is_empty() and build(model,"turret"):
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if room.bed_level < 2 and model.upgrade_bed():
  return
 if building_ids(room,"generator").is_empty() and build(model,"generator"):
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if room.bed_level < 4 and model.upgrade_bed():
  return
 if room.door_level < 4 and model.upgrade_door():
  return
 if _upgrade_kind(model,"turret",4):
  return
 for selector in guns:
  if room.buildings[selector].level != 4 or not model.specialize_building(selector,"precision"):
   continue
  specialized += 1
  strategy_actions.append({"type":"specialized","time":model.time,"kind":"turret","id":selector,"branch":"precision"})
  return
 if building_ids(room,"frost").is_empty() and build(model,"frost"):
  return
 if guns.size() < 3 and build(model,"turret"):
  return
 _upgrade_kind(model,"turret",5)

func use_earned(model: MatchModel, slot: int, id: String) -> bool:
 if item_profile == null or int(item_profile.inventory.get(id,0)) <= 0:
  return false
 var match_id := int(item_profile.active_match.get("id",0))
 if not item_profile.activate_item(slot, model, match_id):
  return false
 item_log.append({"item":id,"time":model.time,"inventory_left":item_profile.inventory.get(id,0)})
 return true

func build_toward_approach(model: MatchModel) -> bool:
 var room := model.player()
 if approach_samples.is_empty():
  var door := room.door_approach()
  var path := model.navigation_path(model.map_data.hunter_spawn,door)
  var previous: Vector2 = model.map_data.hunter_spawn
  for point: Vector2 in path:
   var count := maxi(1,ceili(previous.distance_to(point)/24.0))
   for i in range(count+1):
    var sample := previous.lerp(point,i/float(count))
    if sample.distance_to(door) < 640.0:
     approach_samples.append(sample)
   previous = point
 var sight: float = Catalog.BUILDINGS.turret.range
 var best := Vector2.INF
 var coverage := -1
 for point: Vector2 in _candidate_points(room, "turret"):
  if not room.spatial.purchase_reason("turret",point,0).is_empty():
   continue
  var score := 0
  for sample: Vector2 in approach_samples:
   score += int(point.distance_squared_to(sample) <= sight*sight)
  if score > coverage:
   best = point
   coverage = score
 if best.is_finite() and model.place_building("turret",best,0):
  strategy_actions.append({"type":"approach_coverage","time":model.time,"route_samples_in_range":coverage,"route_samples":approach_samples.size()})
  return true
 return false

func build_first(model: MatchModel, policy: String) -> bool:
 if policy != "precision_layout":
  return build(model, "turret")
 # Install near a probable exit initially. Late prep can move onto the
 # actual doorway arc while preserving the machine identity and payment.
 var room := model.player()
 var points := _candidate_points(room, "turret")
 var door := room.door_approach()
 for point: Vector2 in points:
  var distance := point.distance_to(door)
  if distance >= 135.0 and distance <= 205.0 and room.spatial.purchase_reason("turret", point, 0).is_empty():
   return model.place_building("turret", point, 0)
 return build(model, "turret")

func reposition_first(model: MatchModel, id: int) -> bool:
 if not model.begin_building_move(id):
  return false
 var room := model.player()
 var before := room.tile_position(id)
 var stored := Vector2(room.gold, room.electricity)
 var identity: int = room.buildings[id].instance_id
 var points := _candidate_points(room, "turret")
 for point: Vector2 in points:
  if point.distance_squared_to(before) < 1024.0:
   continue
  if point.distance_to(room.door_approach()) > before.distance_to(room.door_approach()) - 20.0:
   break
  if model.move_building(room.spatial.aligned(point, "turret", 1), 1):
   moved = true
   strategy_actions.append({
    "type":"reposition","time":model.time,"id":id,
    "range_distance_before":before.distance_to(room.door_approach()),
    "range_distance_after":room.tile_position(id).distance_to(room.door_approach()),
    "preserved_investment":identity == room.buildings[id].instance_id and stored == Vector2(room.gold, room.electricity),
   })
   return true
 model.cancel_building_move()
 return false

func observe(model: MatchModel, stats: Dictionary, previous: Vector2, wallet: Vector2, prior_evolution: int) -> bool:
 var last: int = stats.last_event
 var valid := super(model, stats, previous, wallet, prior_evolution)
 control_hits = int(model.contribution.control_hits)
 for event in model.presentation_events:
  if event.id <= last:
   continue
  if (event.get("reason","") == "defense_delays_breach") or event.type in ["hunter_yield","hunter_disengage","hunter_pressure_break","hunter_defensive_break"]:
   var details := {"type":event.type,"time":event.time,"room":int(event.room)+1}
   for key in ["reason","progress","damage","lost_hp","pressure","exposure","next_room","current_cost","alternative_cost"]:
    if event.has(key):
     details[key] = event[key]
   tactical_breaks.append(details)
 return valid

func earn_inventory(stocked_control: bool = false) -> bool:
 var path := "user://fair-earned-profile-" + variant + ("-control" if stocked_control else "-repair") + ".json"
 var profile := PlayerProfile.new(path)
 profile.reward_rng.seed = 904
 var entry := profile.begin_match("standard", "stage_1", false)
 var model := MatchModel.new()
 model.reset(2800)
 if entry.is_empty() or not model.configure_match("standard") or not model.configure_stage("stage_1") or not model.configure_strategy(2800) or not model.configure_balance():
  return false
 if not model.claim_room(0):
  return false
 model.player_position = model.player().bed_position()
 if not model.sleep_player():
  return false
 cached_candidates.clear()
 var steps := 0
 while model.result.is_empty() and model.time < 900.0:
  if steps % 6 == 0:
   act(model)
  model.tick(MODEL_STEP)
  steps += 1
 if model.result != "victory" or profile.settle_match(int(entry.id), model).is_empty():
  return false
 var balance: int = profile.rm_cash
 if stocked_control:
  if not profile.claim_achievement("first_blood") or not profile.equip_item("gold"):
   return false
  if not profile.buy_common("battery",profile.purchase_serial+1) or not profile.equip_item("battery"):
   return false
 else:
  if not profile.claim_achievement("first_victory") or not profile.equip_item("repair"):
   return false
 warmup_receipt = {
  "seed":2800,"result":model.result,"seconds":model.time,
  "source":"first_blood achievement plus RM battery purchase" if stocked_control else "first_victory achievement",
  "loadout":profile.item_loadout.duplicate(),"rank_cash_earned":balance,"rank_cash_remaining":profile.rm_cash,
 }
 earned_profile_file = ProjectSettings.globalize_path(path)
 return true

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["v21", "v22"] or args[2] not in ["exact","probes","late","alternate","staged","0","1","2"]:
  push_error("Use absolute output path, v21 or v22, and exact, probes, late, alternate, staged or repetition 0–2.")
  quit(2)
  return
 arm = "candidate" # Both of these arms keep the V2.1 tactics gate enabled.
 variant = args[1]
 if not load_prior_wins():
  quit(2)
  return
 if variant == "v22" and not "fair_siege_enabled" in MatchModel.new():
  push_error("V2.2 comparison requires fair_siege_enabled.")
  quit(2)
  return
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "1")
 grid = true
 var exact := args[2] in ["exact","probes","late","alternate","staged"]
 var rows := []
 var cases := []
 if args[2] == "staged":
  cases.assign([
   ["stage_5","hell",70169,1,"staged_precision","hybrid"],
   ["stage_5","hell",70169,1,"staged_suppression","hybrid"],
  ])
 elif args[2] == "alternate":
  cases.assign(ALTERNATE_STARTS)
 elif exact:
  var fixtures: Array = LATE_FIXTURES if args[2] == "late" else EXACT
  var plans: Array = ["frost_arc","branch_focus"] if args[2] == "late" else ["approach_fire","earned_control"] if args[2] == "probes" else STRATEGIES
  if args[2] != "late" and not earn_inventory(args[2] == "probes"):
   push_error("Could not earn the finite loadout in a legitimate warmup victory")
   quit(2)
   return
  for fixture in fixtures:
   for strategy: String in plans:
    cases.append([fixture[0],fixture[1],fixture[2],fixture[3],strategy,fixture[4]])
 else:
  var repetition := int(args[2])
  var macro: GDScript = load("res://scripts/nightmare_macro_layout.gd")
  for family_index in range(FAMILY_IDS.size()):
   var family: String = FAMILY_IDS[family_index]
   for difficulty_index in range(DIFFICULTIES.size()):
    var difficulty: String = DIFFICULTIES[difficulty_index]
    var stage: String = THEMES[(family_index + 2 * difficulty_index + repetition * 3) % THEMES.size()]
    var theme: String = StageCatalog.stage(stage).map
    var seed := select_seed(theme, family, 2800 + family_index * 1000 + difficulty_index * 266 + repetition * 28913, macro)
    var room := (family_index + difficulty_index * 3 + repetition * 2) % 6
    for strategy: String in PLANS:
     cases.append([stage,difficulty,seed,room,strategy,family])
 var started := Time.get_ticks_usec()
 for case in cases:
  additions = []
  item_log = []
  strategy_actions = []
  tactical_breaks = []
  item_profile = null
  opening_gold = -1.0
  opening_power = -1.0
  configured_model_id = 0
  moved = false
  specialized = 0
  control_hits = 0
  approach_samples = []
  var row := run_match(case[0],case[1],int(case[2]),int(case[3]),case[4],case[5],-1 if exact else int(args[2]))
  row.opening_wallet = [opening_gold,opening_power]
  row.tactical_breaks = tactical_breaks
  if exact:
   row.decision_timeline = additions
   row.strategy_actions = strategy_actions
   row.item_uses = item_log
   row.specialized = specialized
   row.control_hits = control_hits
  if args[2] == "staged":
   row.prepared_capital = [PREPARED_CAPITAL.x, PREPARED_CAPITAL.y]
   if specialized != 1:
    row.invalid.append("staged fixture did not complete its real paid L5 specialization")
  if opening_gold != BalanceRules.START_GOLD or opening_power != 0.0:
   row.invalid.append("opening wallet did not match the ordinary economy")
  rows.append(row)
  failures += int(not row.invalid.is_empty())
  print("FAIR_MATCH ", row.case, " ", row.outcome, " breaks=", tactical_breaks.size(), " invalid=", row.invalid)
 var output := FileAccess.open(args[0], FileAccess.WRITE)
 if output != null:
  output.store_string(JSON.stringify({
   "arm":variant,"cohort":args[2],"cases":rows,"failures":failures,
   "earned_inventory":warmup_receipt,"wall_seconds":(Time.get_ticks_usec()-started)/1000000.0,
  }, "  ") + "\n")
 else:
  failures += 1
 print("FAIR_MATCH_COMPLETE arm=",variant," cohort=",args[2]," runs=", rows.size(), " failures=",failures)
 quit(int(failures != 0))
