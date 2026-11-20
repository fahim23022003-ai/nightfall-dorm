extends "res://tools/nightmare_tactics/check_starting_rooms.gd"
## Earned defense benchmark, no artificial wallet, damage, inventory or terminal results.

const SEED_BASE := 91737
const MODES := ["standard","hard","hell"]
const ROUTE_CASES := [[0,"balanced"],[2,"early_bed"],[4,"early_crossfire"]]
var decision_steps := 6

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [2,3] or not args[0].is_absolute_path() or args[1].to_int() not in [1,50] or (args.size()==3 and args[2] not in ["--hell-openings","--hell-room-three"]):
  push_error("Pass an absolute receipt path, Story level 1 or 50, and optionally --hell-openings or --hell-room-three.")
  quit(2)
  return
 OS.set_environment(V2_FLAG,"1")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","1")
 grid=true
 variant="v22"
 review_arm="v23"
 var selected_level:=int(args[1])
 var rows:= []
 if "--hell-openings" in args:
  for room_index in range(6):
   rows.append(play(selected_level,"hell",room_index,"needle_defense"))
 elif "--hell-room-three" in args:
  decision_steps=2
  for policy: String in ["needle_defense","early_bed","early_crossfire"]:
   rows.append(play(selected_level,"hell",2,policy))
 else:
  for mode: String in MODES:
   for fixture: Array in ROUTE_CASES:
    rows.append(play(selected_level,mode,int(fixture[0]),str(fixture[1])))
 var file := FileAccess.open(args[0],FileAccess.WRITE)
 if file == null:
  push_error("Could not write Story match receipt.")
  quit(2)
  return
 file.store_string(JSON.stringify({"level":selected_level,"rows":rows,"seed_base":SEED_BASE},"  ")+"\n")
 file.close()
 var invalid:=rows.filter(func(row):return not row.get("audit_ok",false)).size()
 print("LIVING_STORY_BATTLES_MATCHES=",rows.size()," FAILURES=",invalid)
 quit(int(invalid!=0))

func play(level: int, mode: String, index: int, policy: String) -> Dictionary:
 var model:=MatchModel.new()
 model.procedural_v2_requested=true
 var mission:=StoryCatalog.mission(level)
 var seed:=StoryProgress.seed_for(StoryProgress.fresh(SEED_BASE),level)
 model.reset(seed)
 if not model.configure_match(mode,RankCatalog.bonuses([])) or not model.configure_stage(mission.stage_id) or not model.configure_balance():
  return {"invalid":"setup rejected","mode":mode}
 model.story_level=level
 model.preparation=maxf(model.preparation,mission.preparation)
 if not model.configure_strategy(seed,mission.archetype) or model.map_data.family!=mission.topology:
  return {"invalid":"wrong strategy or topology","mode":mode}
 var room: RoomState=model.rooms[index]
 if not model.claim_room(index):
  return {"invalid":"could not claim room","mode":mode}
 model.player_position=room.bed_position()
 if not model.sleep_player():
  return {"invalid":"could not occupy room","mode":mode}
 var funds: float=room.gold
 var step_count:=0
 var guard:=true
 approach_samples.clear()
 cached_candidates.clear()
 var last_state:=0
 while model.result.is_empty() and model.time<900.0:
  if step_count%decision_steps==0:
   apply_plan(model,policy)
  model.tick(MODEL_STEP)
  step_count+=1
  guard=guard and is_finite(room.gold) and room.gold>=0.0 and room.electricity>=0.0
  if model.hunter.transformed:
   last_state=maxi(last_state,model.wrath.phase+1)
 var result := {"level":level,"title":mission.title,"difficulty":mode,"room":index+1,"seed":seed,"topology":model.map_data.family,
  "plan":policy,"initial_gold":funds,"decision_step":MODEL_STEP*decision_steps,"time":snappedf(model.time,.05),"result":model.result,
  "terminal_recorded":model.terminal_recorded,"reaper":model.hunter.transformed,"boss_state_max":last_state,
  "hunter_hp":model.hunter.hp,"dealt":room.damage_dealt,"attacks":model.hunter.attacks,"hall_visits":model.haunt_recovery.visits,
  "audit_ok":guard and model.terminal_recorded and funds==25.0 and opening_power==0.0}
 print("STORY_EARNED ",JSON.stringify(result))
 return result
