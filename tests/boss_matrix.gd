extends SceneTree
# Independent matched encounter comparison. Earned resources only, not human win rates.
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
 var summary={}
 var hell_rooms="--hell-rooms" in OS.get_cmdline_user_args()
 for stage in StageCatalog.STAGES:
  for mode in (["hell"] if hell_rooms else ["standard","hard","hell"]):
   for strategy in (["reactive_economy"] if hell_rooms else ["balanced","reactive_economy"]):
    for room_index in (range(6) if hell_rooms else [stage.number%6]):
     for enabled in ([true] if hell_rooms else [false,true]):
      var model=MatchModel.new()
      model.reset(11)
      var perks=["dreamer"] if strategy=="reactive_economy" else []
      model.configure_match(mode,RankCatalog.bonuses(perks))
      model.configure_stage(stage.id)
      var configured=model.hunter.boss_policy.enabled
      if not enabled: model.hunter.boss_policy.enabled=false
      model.claim_room(room_index)
      var room=model.player()
      model.player_position=room.bed_position()
      model.sleep_player()
      room.profile="balanced"
      var timer=0.0
      var steps=0
      var seen=0
      var event_counts={}
      var transformed_at=0.0
      var last_attacks=0
      var invalid=false
      while model.result=="" and steps<12000:
       timer-=0.1
       if timer<=0:
        act(room,strategy)
        timer=0.5
       var previous=model.hunter.position
       model.tick(0.1)
       if previous.distance_to(model.hunter.position)>model.hunter.speed*0.1+0.1: invalid=true
       if model.hunter.attacks>last_attacks:
        var target=model.hunter.target
        if target<0 or target>=6 or model.hunter.position.distance_to(model.rooms[target].door_approach())>5: invalid=true
       last_attacks=model.hunter.attacks
       for event in model.presentation_events:
        if event.id<=seen: continue
        seen=event.id
        var key=event.type+(":"+event.get("attack","") if event.has("attack") else "")
        event_counts[key]=event_counts.get(key,0)+1
        if event.type=="boss_transform": transformed_at=model.time
       if room.gold< -0.001 or room.electricity< -0.001 or not is_finite(room.gold) or not is_finite(room.electricity): invalid=true; break
       steps+=1
      if model.result=="" or invalid or event_counts.get("boss_transform",0)>1: failures+=1
      var key=mode+("_boss" if enabled else "_baseline")
      if not summary.has(key): summary[key]={"wins":0,"losses":0,"transformed":0,"boss_wins":0,"seconds":0.0}
      summary[key].wins+=int(model.result=="victory")
      summary[key].losses+=int(model.result=="defeat")
      summary[key].transformed+=int(model.hunter.transformed)
      summary[key].boss_wins+=int(model.hunter.transformed and model.result=="victory")
      summary[key].seconds+=model.time
      var row={"stage":stage.id,"map":model.map_id,"room":room_index+1,"difficulty":mode,"strategy":strategy,"perks":perks,"boss_enabled":enabled and configured,"comparison_arm":("boss" if enabled else "baseline"),"result":model.result,"seconds":snappedf(model.time,0.1),"transformed_at":snappedf(transformed_at,0.1),"events":event_counts,"player_damage":snappedf(room.damage_dealt,0.1),"door_damage":snappedf(room.door_damage_taken,0.1),"gold_generated":snappedf(room.income_total,0.1),"gold_spent":snappedf(room.spent,0.1),"gold":snappedf(room.gold,0.1),"electricity":snappedf(room.electricity,0.1),"retargets":model.hunter.retargets,"recoveries":model.hunter.navigation_recoveries,"invalid":invalid}
      results.append(row)
      print("BOSS_MATRIX_RUN ",JSON.stringify(row))
 var output="res://docs/evidence/boss/matrix-hell.json" if hell_rooms else "res://docs/evidence/boss/matrix-matched.json"
 var file=FileAccess.open(output,FileAccess.WRITE)
 if file: file.store_string(JSON.stringify({"results":results,"summary":summary,"failures":failures}," "))
 print("BOSS_MATRIX_MATCHES=",results.size()," SUMMARY=",JSON.stringify(summary)," FAILURES=",failures)
 quit(0 if failures==0 else 1)
