extends "res://tools/nightmare_tactics/check_complete_matches.gd"
## Focused replays capture order and cost of decisions around first contact.

const PURCHASES := ["build", "building_upgrade", "bed_upgrade", "door_upgrade", "repair", "emergency_ward"]
var additions := []

func apply_plan(model: MatchModel, policy: String):
 if policy != "survival_transition":
  super(model, policy)
  return
 var room := model.player()
 var hunter := model.hunter
 var danger := hunter.target == room.index and hunter.position.distance_to(room.door_approach()) < 150.0
 if danger:
  if room.door_level < 2 and room.door_hp < room.max_hp() * .84 and model.upgrade_door():
   return
  if room.door_hp < room.max_hp() * .58 and model.repair_door():
   return
  if hunter.state == HunterState.State.ATTACK and hunter.cooldown < 1.4 and room.door_hp < room.max_hp() * .82 and model.route_defense_power():
   return
 if room.bed_level < 1 and model.upgrade_bed():
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if building_ids(room, "turret").size() < 2 and build(model, "turret"):
  return
 if not danger and room.bed_level < 2 and model.upgrade_bed():
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if building_ids(room, "turret").size() < 3 and build(model, "turret"):
  return
 if building_ids(room, "generator").is_empty() and build(model, "generator"):
  return
 if building_ids(room, "frost").is_empty() and build(model, "frost"):
  return
 if building_ids(room, "repair").is_empty() and build(model, "repair"):
  return
 if _upgrade_kind(model, "turret", 3):
  return
 if building_ids(room, "heavy").is_empty() and build(model, "heavy"):
  return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if _upgrade_kind(model, "heavy", 4):
  return
 _upgrade_kind(model, "turret", 4)

func observe(model: MatchModel, stats: Dictionary, previous: Vector2, wallet: Vector2, prior_evolution: int) -> bool:
 var last: int = stats.last_event
 var valid := super(model, stats, previous, wallet, prior_evolution)
 for event in model.presentation_events:
  if event.id <= last:
   continue
  if event.room != model.player_room or not (event.type in PURCHASES or event.type == "door_damage"):
   continue
  var action := {
   "time": snappedf(model.time, .01), "type": event.type,
   "gold_after_tick": model.player().gold, "power_after_tick": model.player().electricity,
  }
  for key in ["damage", "source", "hp", "kind", "level", "spent_gold", "spent_power", "attacker_id"]:
   if event.has(key):
    action[key] = event[key]
  additions.append(action)
 return valid

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["baseline", "candidate"] or not args[2].is_absolute_path():
  push_error("Use absolute output path, arm and absolute audit fixture manifest.")
  quit(2)
  return
 arm = args[1]
 if not load_prior_wins():
  quit(2)
  return
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "1")
 grid = true
 var cases = JSON.parse_string(FileAccess.get_file_as_string(args[2]))
 if not cases is Array:
  quit(2)
  return
 var rows := []
 for receipt in cases:
  var case: Array = receipt.case
  additions = []
  var row := run_match(case[0], case[1], int(case[2]), int(case[3]), case[4], receipt.family, int(receipt.repetition))
  row.preparation = StageCatalog.stage(case[0]).preparation if BalanceRules.CURRENT != 2 else maxf(StageCatalog.stage(case[0]).preparation, BalanceRules.PREPARATION)
  row.decision_timeline = additions
  row.context = receipt.context
  rows.append(row)
  failures += int(not row.invalid.is_empty())
  print("TACTICAL_AUDIT ", row.case, " ", row.outcome, " ", row.invalid)
 var output := FileAccess.open(args[0], FileAccess.WRITE)
 if output != null:
  output.store_string(JSON.stringify({"arm":arm,"cases":rows,"failures":failures}, "  ") + "\n")
 else:
  failures += 1
 print("TACTICAL_AUDIT_COMPLETE arm=", arm, " cases=", rows.size(), " failures=", failures)
 quit(int(failures != 0))
