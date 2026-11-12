extends SceneTree
# Matched policies: earned currency only; one Legendary activation budget plus four olditem units; rank perks paired equally.
# This is a diagnostic comparison, not human win rates or naturally earned inventory.
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
 var rows=[];var summary={};var serial=0
 var challenge="--challenge" in OS.get_cmdline_user_args()
 var builds=[{"name":"bronze","xp":0,"perks":["pocket"]},{"name":"gold","xp":700,"perks":["dreamer"]},{"name":"diamond","xp":2400,"perks":["marksman"]},{"name":"mythic","xp":8000,"perks":["marksman","reaper_slayer"]}]
 for stage in StageCatalog.STAGES:
  for mode in (["hell"] if challenge else ["standard","hard","hell"]):
   for build in builds:
    for enabled in [false,true]:
     serial+=1
     var path="user://rewards-balance-"+str(Time.get_ticks_usec())+"-"+str(serial)+".json"
     var p=PlayerProfile.new(path);p.xp=build.xp
     if build.name=="mythic":
      p.statistics.matches=3;p.statistics.victories=3;p.statistics.hard=3;p.statistics.reaper_defeats=3;p.next_match_id=4
      for known in StageCatalog.STAGES:p.campaign_records[known.id]={"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"hard","first_match_id":1}
     p.equipped=build.perks.duplicate()
     if enabled:p.inventory={"guardian_heart":4,"shield":4};p.item_loadout=["guardian_heart","shield"]
     var entry=p.begin_match(mode)
     if entry.is_empty():failures+=1;continue
     var m=MatchModel.new();m.reset(47 if challenge else 11);m.configure_match(mode,RankCatalog.bonuses(p.equipped));m.configure_stage(stage.id)
     if enabled:m.stage_bonus=RewardCatalog.STAGE_BONUSES.economic.duplicate(true)
     p.bind_items(m,entry.id);m.claim_room(stage.number%6)
     var room=m.player();m.player_position=room.bed_position();m.sleep_player();room.profile="balanced"
     var timer=0.0;var steps=0;var activations=0;var invalid=false
     while m.result=="" and steps<12000:
      timer-=.1
      if timer<=0:act(room,"reactive_economy" if challenge else "balanced");timer=.5
      if enabled and room.door_hp<room.max_hp()*.6 and p.activate_item(1,m,entry.id):activations+=1
      var previous=m.hunter.position;m.tick(.1)
      if previous.distance_to(m.hunter.position)>m.hunter.speed*.1+.2:invalid=true
      if room.gold<-.001 or room.electricity<-.001 or not is_finite(room.gold) or not is_finite(room.electricity):invalid=true;break
      for id in p.inventory:
       if p.inventory[id]<0:invalid=true
      if m.items.legendary_used>1:invalid=true
      steps+=1
     if m.result=="" or invalid:failures+=1
     var key=build.name+"_"+mode+("_prepared" if enabled else "_perks")
     if not summary.has(key):summary[key]={"wins":0,"losses":0,"legendary":0}
     summary[key]["wins" if m.result=="victory" else "losses"]+=1;summary[key].legendary+=m.items.legendary_used
     var row={"seed":47 if challenge else 11,"strategy":"reactive_economy" if challenge else "balanced","rank":build.name,"xp":build.xp,"perks":build.perks,"mode":mode,"stage":stage.id,"prepared":enabled,"result":m.result,"seconds":snappedf(m.time,.1),"shield_uses":activations,"legendary_uses":m.items.legendary_used,"invalid":invalid,"transformed":m.hunter.transformed}
     rows.append(row);print("REWARDS_BALANCE_RUN ",JSON.stringify(row))
     for suffix in ["",".tmp",".bak"]:
      if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var result={"matches":rows.size(),"summary":summary,"failures":failures,"rows":rows}
 var file=FileAccess.open("res://docs/evidence/rewards/balance-challenge-results.json" if challenge else "res://docs/evidence/rewards/balance-results.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(result," "))
 print("REWARDS_BALANCE_MATCHES=",rows.size()," SUMMARY=",JSON.stringify(summary)," FAILURES=",failures)
 quit(0 if failures==0 else 1)
