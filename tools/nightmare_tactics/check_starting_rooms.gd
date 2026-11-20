extends "res://tools/nightmare_tactics/check_fair_counterplay.gd"
## Matched ordinary and earned-item Campaign openings. Uses real transactions.

var review_arm := ""
var walk_seconds := 0.0

func configure_once(model: MatchModel, plan: String):
 super(model, plan)
 if "starting_room_review_enabled" in model:
  model.set("starting_room_review_enabled", review_arm == "v23")

func occupy_player_room(model: MatchModel, room_index: int, policy: String) -> bool:
 if not policy.begins_with("walk_"):
  return super(model,room_index,policy)
 var room: RoomState=model.rooms[room_index]
 var entry:=room.door_position()-room.door_normal()*35.0
 if not walk_to(model,entry):
  return false
 model.interact()
 if model.player_room!=room_index or not walk_to(model,room.bed_position()+room.door_normal()*42.0):
  print("WALK_CLAIM ",model.player_room," occupied=",room.owner," t=",model.time)
  return false
 model.interact()
 walk_seconds=model.time
 return room.sleeping

func walk_to(model: MatchModel, destination: Vector2) -> bool:
 var path:=model.player_navigation_path(model.player_position,destination)
 if path.is_empty() or not Vector2(path.back()).is_equal_approx(destination):
  print("WALK_PATH ",model.player_position," destination=",destination," path=",path)
  return false
 for point: Vector2 in path:
  var steps:=0
  while model.player_position.distance_to(point)>1.0 and steps<420:
   model.move_player((point-model.player_position)/(180.0*MODEL_STEP),MODEL_STEP)
   model.tick(MODEL_STEP)
   steps+=1
  if steps==420:
   print("WALK_BLOCKED ",model.player_position," waypoint=",point," destination=",destination)
   return false
 return true

func apply_plan(model: MatchModel, policy: String):
 policy=policy.trim_prefix("walk_")
 if not policy.begins_with("early_"):
  super(model, policy)
  return
 configure_once(model, policy)
 var room := model.player()
 var target: bool = model.hunter.target == room.index
 var defense_live: bool = target and model.hunter.state == HunterState.State.ATTACK
 var missing: float = room.max_hp()-room.door_hp
 if defense_live and missing>=Catalog.REPAIR_HEAL*room.repair_factor*.90 and model.repair_door():
  return
 if room.bed_level<1:
  model.upgrade_bed()
  return
 if policy=="early_bed" and room.bed_level<2:
  model.upgrade_bed()
  return
 if policy=="early_dynamo" and building_ids(room,"generator").is_empty():
  build(model,"generator")
  return
 if policy=="early_crossfire" and model.time<model.preparation and building_ids(room,"turret").size()<4:
  build_toward_approach(model)
  return
 if room.door_level<1:
  model.upgrade_door()
  return
 if policy=="early_fortify" and room.door_level<2:
  model.upgrade_door()
  return
 if building_ids(room,"turret").is_empty() and build_toward_approach(model):
  return
 if room.bed_level<2 and model.upgrade_bed():
  return
 if room.door_level<2 and model.upgrade_door():
  return
 if building_ids(room,"generator").is_empty() and build(model,"generator"):
  return
 if model.hunter.state == HunterState.State.ATTACK and target and model.hunter.cooldown<=1.4 and room.door_hp<room.max_hp()*.85 and model.route_defense_power():
  return
 if building_ids(room,"frost").is_empty() and build(model,"frost"):
  return
 if building_ids(room,"repair").is_empty() and build(model,"repair"):
  return
 if building_ids(room,"turret").size()<3 and build_toward_approach(model):
  return
 super(model,"survival_transition")

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=3 or args[1] not in ["v22","v23"]:
  quit(2)
  return
 review_arm=args[1]
 variant="v22"
 arm="candidate"
 if not load_prior_wins():
  quit(2)
  return
 OS.set_environment(V2_FLAG,"1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS","0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","1")
 grid=true
 var cases = JSON.parse_string(FileAccess.get_file_as_string(args[2]))
 if not cases is Array or not earn_inventory(true):
  quit(2)
  return
 var rows := []
 for case in cases:
  walk_seconds=0.0
  additions=[]
  item_log=[]
  strategy_actions=[]
  approach_samples=[]
  tactical_breaks=[]
  control_hits=0
  item_profile=null
  var row := run_match(case[0],case[1],int(case[2]),int(case[3]),case[4],case[5],-1)
  row.walk_seconds=walk_seconds
  row.opening_wallet=[opening_gold,opening_power]
  row.decision_timeline=additions
  row.strategy_actions=strategy_actions
  row.tactical_breaks=tactical_breaks
  row.item_uses=item_log
  row.control_hits=control_hits
  if row.opening_wallet!=[BalanceRules.START_GOLD,0.0]:
   row.invalid.append("opening wallet changed")
  if case[4].trim_prefix("walk_")!="earned_control" and not item_log.is_empty():
   row.invalid.append("item-free opening used an item")
  rows.append(row)
  failures+=int(not row.invalid.is_empty())
  print("OPENING_MATCH ",row.case," ",row.outcome," ",row.invalid)
 var output:=FileAccess.open(args[0],FileAccess.WRITE)
 if output==null:
  quit(2)
  return
 output.store_string(JSON.stringify({"arm":review_arm,"cases":rows,"failures":failures,"earned_inventory":warmup_receipt},"  ")+"\n")
 output.close()
 print("OPENING_MATCH_COMPLETE ",rows.size()," failures=",failures)
 quit(int(failures!=0))
