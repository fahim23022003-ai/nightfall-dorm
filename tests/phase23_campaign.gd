extends "res://tools/nightmare_tactics/check_phase16_story_matrix.gd"
## Matched Story previews, with an independent mission-seed set reserved for acceptance.
## Usage: script -- <output.jsonl> <earned-stock.json> <development|held-out|opening> <first> <count>

const LEVELS := [1, 6, 11, 17, 23, 27, 32, 36, 44, 50]
const COHORT_POLICIES := ["passive", "beginner", "average", "defensive", "offensive", "skilled", "item_assisted"]
const CADENCE := {"passive":9.0,"beginner":7.2,"beginner_second":7.2,"average":3.6,"defensive":2.7,"offensive":2.7,"skilled":1.8,"item_assisted":1.8}
var next_action := 0.0
var details := {}
var last_target := -1
var last_observed_event := 0

func new_trial_profile(fixture: Dictionary, stock: String) -> PlayerProfile:
 var profile := super(fixture,stock)
 if profile == null:
  return null
 # Carry the legitimate Silver door perk earned by the stock profile into later
 # chapters. No boosts are injected into the match or its wallet.
 if fixture.level > 10 and not profile.equip("reinforced"):
  return null
 if fixture.policy == "item_assisted" and not profile.equip_item("battery"):
  return null
 details.equipped=profile.equipped.duplicate()
 details.opening_items=profile.item_loadout.duplicate()
 return profile

func skilled_action(model: MatchModel) -> void:
 var room := model.player()
 var danger := room.door_hp < room.max_hp()*.72 and model.hunter.target == room.index
 if danger:
  if model.upgrade_door() or model.route_defense_power() or model.repair_door():
   return
 if room.bed_level < 1:
  model.upgrade_bed()
  return
 var needles := building_ids(room,"turret")
 if needles.is_empty() and build(model,"turret"):
  return
 if room.bed_level < 2:
  model.upgrade_bed()
  return
 if room.door_level < 1 and model.upgrade_door():
  return
 if building_ids(room,"generator").is_empty():
  build(model,"generator")
  return
 if needles.size()<3 and build(model,"turret"):
  return
 if room.bed_level < 3 and model.upgrade_bed():
  return
 if room.door_level < 2 and model.upgrade_door():
  return
 if _upgrade_kind(model,"turret",2):
  return
 if model.hunter.archetype in ["crusher","ravager"] and building_ids(room,"frost").is_empty() and build(model,"frost"):
  return
 if building_ids(room,"heavy").is_empty() and build(model,"heavy"):
  return
 if room.bed_level < 4 and model.upgrade_bed():
  return
 if needles.size()<5 and build(model,"turret"):
  return
 if room.door_level < 3 and model.upgrade_door():
  return
 if _upgrade_kind(model,"turret",4) or _upgrade_kind(model,"heavy",4):
  return
 if building_ids(room,"repair").is_empty() and build(model,"repair"):
  return
 if room.bed_level<5 and model.upgrade_bed():
  return
 if room.door_level<5 and model.upgrade_door():
  return
 for id in needles:
  if room.buildings[id].level==4 and model.specialize_building(id,"precision"):
   return

func use_plan(model: MatchModel, profile: PlayerProfile, policy: String, items_used: Array, match_id: int) -> void:
 if model.time + .001 < next_action:
  return
 next_action = model.time + float(CADENCE[policy])
 if policy == "passive":
  return
 var room := model.player()
 var before := Vector2(room.gold, room.electricity)
 match policy:
  "beginner", "beginner_second":
   if room.door_hp < room.max_hp() * .20 and model.repair_door():
    pass
   elif building_ids(room,"turret").is_empty():
    build(model,"turret")
   elif room.bed_level<1:
    model.upgrade_bed()
   elif room.door_level<1:
    model.upgrade_door()
   elif building_ids(room,"generator").is_empty():
    build(model,"generator")
   else:
    var needles:=building_ids(room,"turret")
    if room.buildings[needles[0]].level<2:
     model.upgrade_building(needles[0])
    elif policy=="beginner_second" and needles.size()==1:
     build(model,"turret")
  "average":
   act(model)
  "defensive":
   apply_plan(model,"door_reserve")
  "offensive":
   defend_with_needles(model)
  "skilled", "item_assisted":
   if policy == "item_assisted" and items_used.is_empty():
    var slot := profile.item_loadout.find("gold")
    if slot >= 0 and profile.activate_item(slot,model,match_id):
     items_used.append({"item":"gold","time":model.time,"remaining":profile.inventory.get("gold",0)})
     return
   skilled_action(model)
 if before == Vector2(room.gold,room.electricity):
  details.wait_or_no_purchase += 1

func observe(model: MatchModel, stats: Dictionary, previous: Vector2, wallet: Vector2, evolution: int) -> bool:
 var valid := super(model,stats,previous,wallet,evolution)
 var hunter := model.hunter
 if not details.has("bots"):
  details.bots=Catalog.BOT_PROFILES.duplicate()
 if hunter.target != last_target:
  details.target_changes.append([snappedf(model.time,.01),last_target+1,hunter.target+1,HunterState.State.keys()[hunter.state]])
  last_target = hunter.target
 if previous.distance_squared_to(hunter.position) > .001:
  details.motion_seconds += MODEL_STEP
 for e in model.presentation_events:
  if e.id <= last_observed_event:
   continue
  last_observed_event = e.id
  if e.type == "hunter_target_choice":
   var decision := [snappedf(model.time,.01),e.room+1,e.get("reason","")]
   if e.has("estimated_cost"):
    decision.append({"selected_cost":e.estimated_cost,"best_cost":e.best_cost,
     "comparable":e.comparable_doors,"reachable":e.reachable_options,"recent":e.recent_selections})
   details.choices.append(decision)
  if e.room == model.player_room and e.type in ["repair","repair_started","bed_upgrade","door_upgrade","build","building_upgrade","emergency_ward","specialization"]:
   details.transactions.append([snappedf(model.time,.01),e.type,e.get("kind",""),e.get("spent_gold",0),e.get("spent_power",0)])
 return valid

func run():
 var args := OS.get_cmdline_user_args()
 var opening := args.size()==5 and args[2]=="opening"
 var case_count := 16 if opening else LEVELS.size()*DIFFICULTIES.size()*COHORT_POLICIES.size()
 if args.size()!=5 or args[2] not in ["development","held-out","opening"] or not args[3].is_valid_int() or not args[4].is_valid_int() or int(args[3])<0 or int(args[3])>=case_count or int(args[4])<1:
  quit(2)
  return
 start_flags()
 for key in ["NIGHTFALL_LIVING_DORM","NIGHTFALL_PHASE16","NIGHTFALL_CLOSE_QUARTERS","NIGHTFALL_BUILDING_SCALE","NIGHTFALL_PLAYER_FIRST","NIGHTFALL_TACTICAL_UI","NIGHTFALL_WEAPON_FEEDBACK","NIGHTFALL_PERFORMANCE_PREVIEW","NIGHTFALL_VISUAL_REBIRTH"]:
  OS.set_environment(key,"1")
 OS.set_environment("NIGHTFALL_MINI_HUNTERS","0")
 variant="v22"
 review_arm="v23"
 var output:=FileAccess.open(args[0],FileAccess.WRITE)
 if output==null:
  quit(2)
  return
 for i in range(int(args[3]),mini(case_count,int(args[3])+int(args[4]))):
  var policy: String=COHORT_POLICIES[i%COHORT_POLICIES.size()]
  @warning_ignore("integer_division")
  var trial: int=i/COHORT_POLICIES.size()
  # Rotate difficulty by chapter for meaningful coverage in small prefixes.
  var chapter:=trial%LEVELS.size()
  @warning_ignore("integer_division")
  var mode: String=DIFFICULTIES[(chapter+trial/LEVELS.size())%3]
  var mission:=StoryCatalog.mission(LEVELS[chapter])
  var seed_base:int=(83173 if args[2]=="development" else 817909)+chapter*331
  var fixture:={"id":"%s-%d" % [args[2],i], "seed_base":seed_base,"level":LEVELS[chapter],"difficulty":mode,
   "policy":policy,"family":mission.topology,"archetype":mission.archetype,"room_preference":(chapter+int(args[2]=="held-out"))%3}
  if opening:
   @warning_ignore("integer_division")
   var pair:=i/2
   var level:=1 if pair%2==0 else 6
   mission=StoryCatalog.mission(level)
   policy="beginner" if i%2==0 else "beginner_second"
   mode="standard"
   @warning_ignore("integer_division")
   fixture={"id":"opening-%d" % i,"seed_base":184313+pair/2*409,"level":level,"difficulty":mode,
    "policy":policy,"family":mission.topology,"archetype":mission.archetype,"room_preference":pair%3}
  details={"motion_seconds":0.0,"target_changes":[],"choices":[],"transactions":[],"wait_or_no_purchase":0}
  next_action=0
  last_target=-1
  last_observed_event=0
  var row:=play_story(fixture,args[1])
  if row.has("terminal_recorded") and row.terminal_recorded and row.peak_buildings==0 and row.hunter_attacks>0 and policy=="passive":
   row.invalid.erase("missing paid player construction or Hunter combat")
  row["trace"]=details
  output.store_line(JSON.stringify(row,"",true,true))
  output.flush()
  print("PHASE23_MATCH ",fixture.id," ",mode," ",policy," ",row.get("outcome","-")," ",row.invalid)
  failures+=int(not row.invalid.is_empty())
 quit(int(failures!=0))
