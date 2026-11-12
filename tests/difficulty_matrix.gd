extends SceneTree
# Diagnostic production-model policies, earned resources only. Not human win rates.
var failures=0
func _initialize(): call_deferred("run")
func empty(room,kind):
 for tile in range(room.tile_count()):
  if not room.buildings.has(tile): return room.build(kind,tile)
 return false
func count(room,kind):
 var n=0
 for b in room.buildings.values():
  if b.kind==kind: n+=1
 return n
func adaptive(room):
 if room.door_hp<room.max_hp()*0.5:
  if room.upgrade_door() or room.repair_door(): return
 if room.bed_level<1: room.upgrade_bed(); return
 if not BotAI.has_kind(room,"turret"): empty(room,"turret"); return
 if room.door_level<2: room.upgrade_door(); return
 if not BotAI.has_kind(room,"generator"): empty(room,"generator"); return
 if room.bed_level<2: room.upgrade_bed(); return
 if not BotAI.has_kind(room,"repair"): empty(room,"repair"); return
 if room.bed_level<3: room.upgrade_bed(); return
 if room.door_level<3: room.upgrade_door(); return
 if count(room,"turret")<2: empty(room,"turret"); return
 if not BotAI.has_kind(room,"heavy"): empty(room,"heavy"); return
 for tile in room.buildings:
  if room.buildings[tile].kind=="generator" and room.buildings[tile].level<2: room.upgrade_building(tile); return
 if room.bed_level<4: room.upgrade_bed(); return
 if room.door_level<4: room.upgrade_door(); return
 if not BotAI.has_kind(room,"enhancer"): empty(room,"enhancer"); return
 for tile in room.buildings:
  if room.buildings[tile].kind in ["turret","heavy"] and room.buildings[tile].level<3: room.upgrade_building(tile); return
 if room.buildings.size()<room.tile_count(): empty(room,"turret"); return
func act(room,strategy):
 if strategy=="adaptive": adaptive(room); return
 if strategy=="minimal":
  if room.occupied_seconds<65: return
  BotAI.tick(room,0.5)
  return
 if strategy=="balanced":
  BotAI.tick(room,0.5)
  return
 if room.door_hp<room.max_hp()*(0.75 if strategy=="reactive_economy" else 0.4) and (room.upgrade_door() or room.repair_door()): return
 if room.bed_level<1: room.upgrade_bed(); return
 if room.door_level<1: room.upgrade_door(); return
 if strategy=="turret" and count(room,"turret")<5: empty(room,"turret"); return
 if strategy=="door" and room.door_level<2: room.upgrade_door(); return
 if not BotAI.has_kind(room,"generator"): empty(room,"generator"); return
 if room.bed_level<2: room.upgrade_bed(); return
 if room.door_level<2: room.upgrade_door(); return
 if strategy=="door" and room.door_level<4:
  if room.bed_level<room.door_level-1: room.upgrade_bed()
  else: room.upgrade_door()
  return
 if strategy in ["economy","reactive_economy"] and count(room,"economy")<4: empty(room,"economy"); return
 if not BotAI.has_kind(room,"repair"): empty(room,"repair"); return
 if room.buildings.size()<room.tile_count(): empty(room,"turret"); return
 for tile in room.buildings:
  if room.buildings[tile].level<4: room.upgrade_building(tile); return
func run():
 var results=[]
 var wins={}
 var losses={}
 var strategies=["balanced","turret","door","economy","minimal","adaptive"]
 var perks=[[],["marksman"],["reinforced"],["dreamer"],["first_aid"],["pocket"]]
 var quick="--quick" in OS.get_cmdline_user_args()
 var adaptive_only="--adaptive-only" in OS.get_cmdline_user_args()
 var reactive_rooms="--reactive-hell-rooms" in OS.get_cmdline_user_args()
 var hell_rooms="--hell-rooms" in OS.get_cmdline_user_args() or reactive_rooms
 if adaptive_only:
  strategies=["adaptive"]
  perks=[["pocket"]]
 if hell_rooms:
  strategies=["reactive_economy" if reactive_rooms else "economy"]
  perks=[["dreamer"]]
 var total=0
 for stage in StageCatalog.STAGES:
  if reactive_rooms and stage.id!="stage_5": continue
  for difficulty in ["standard","hard","hell"]:
   if (adaptive_only or hell_rooms) and difficulty!="hell": continue
   if not RankCatalog.DIFFICULTIES.has(difficulty):
    push_error("DIFFICULTY MATRIX missing profile "+difficulty)
    quit(1)
    return
   for strategy_index in range(1 if quick else strategies.size()):
    var strategy=strategies[strategy_index]
    for room_index in (range(6) if hell_rooms else [stage.number%6]):
     var model=MatchModel.new()
     model.reset(11)
     model.configure_match(difficulty,RankCatalog.bonuses(perks[strategy_index]))
     model.configure_stage(stage.id)
     model.claim_room(room_index)
     var room=model.player()
     model.player_position=room.bed_position()
     model.sleep_player()
     room.profile="balanced"
     var timer=0.0
     var steps=0
     var max_tick_us=0
     var max_buildings=0
     var last_attacks=0
     var bad_motion=false
     while model.result=="" and steps<12000:
      timer-=0.1
      if timer<=0:
       act(room,strategy)
       timer=0.5
      var old=model.hunter.position
      var before=Time.get_ticks_usec()
      model.tick(0.1)
      max_tick_us=maxi(max_tick_us,Time.get_ticks_usec()-before)
      max_buildings=maxi(max_buildings,room.buildings.size())
      if old.distance_to(model.hunter.position)>model.hunter.speed*0.1+0.2: bad_motion=true
      if model.hunter.attacks>last_attacks:
       var target=model.hunter.target
       if target<0 or target>=6 or model.hunter.position.distance_to(model.rooms[target].door_approach())>5: failures+=1
      last_attacks=model.hunter.attacks
      if room.gold< -0.001 or room.electricity< -0.001 or not is_finite(room.gold) or not is_finite(room.electricity): failures+=1; break
      steps+=1
     if model.result=="" or bad_motion: failures+=1
     if model.result=="victory": wins[difficulty]=wins.get(difficulty,0)+1
     elif model.result=="defeat": losses[difficulty]=losses.get(difficulty,0)+1
     total+=1
     var row={"stage":stage.id,"room":room_index+1,"map":model.map_id,"difficulty":difficulty,"strategy":strategy,"perk":perks[strategy_index],"result":model.result,"seconds":snappedf(model.time,0.1),"hunter_level":model.hunter.level,"hunter_hp":snappedf(model.hunter.hp,0.1),"player_damage":snappedf(room.damage_dealt,0.1),"door_damage":snappedf(room.door_damage_taken,0.1),"gold_generated":snappedf(room.income_total,0.1),"gold_spent":snappedf(room.spent,0.1),"gold":snappedf(room.gold,0.1),"power":snappedf(room.electricity,0.1),"buildings":max_buildings,"attacks":model.hunter.attacks,"retargets":model.hunter.retargets,"recoveries":model.hunter.navigation_recoveries,"peak_tick_us":max_tick_us}
     results.append(row)
     print("DIFFICULTY_RUN ",JSON.stringify(row))
 DirAccess.make_dir_recursive_absolute("res://artifacts")
 var file=FileAccess.open("res://artifacts/difficulty_reactive_hell.json" if reactive_rooms else "res://artifacts/difficulty_hell_rooms.json" if hell_rooms else "res://artifacts/difficulty_matrix.json",FileAccess.WRITE)
 if file: file.store_string(JSON.stringify({"results":results,"wins":wins,"losses":losses,"failures":failures}," "))
 print("DIFFICULTY_MATRIX_MATCHES=",total," WINS=",JSON.stringify(wins)," LOSSES=",JSON.stringify(losses)," FAILURES=",failures)
 quit(0 if failures==0 else 1)
