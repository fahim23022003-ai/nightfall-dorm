extends SceneTree
# Independent matched policies: earned currency only; explicit budget of two seeded item types, four units each.
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
 var rows=[]
 var summary={}
 var serial=0
 for stage in StageCatalog.STAGES:
  for mode in ["standard","hard","hell"]:
   for strategy in ["balanced","reactive_economy"]:
    for enabled in [false,true]:
     serial+=1
     var path="user://items-balance-"+str(Time.get_ticks_usec())+"-"+str(serial)+".json"
     var p=PlayerProfile.new(path)
     var budget=["gold","shield"] if strategy=="balanced" else ["battery","repair"]
     if enabled:
      for item in budget:p.inventory[item]=4
      p.item_loadout=budget.duplicate()
     var entry=p.begin_match(mode)
     var m=MatchModel.new()
     m.reset(11)
     m.configure_match(mode)
     m.configure_stage(stage.id)
     m.claim_room(stage.number%6)
     var room=m.player()
     m.player_position=room.bed_position()
     m.sleep_player()
     room.profile="balanced"
     var timer=0.0
     var steps=0
     var activations=[]
     var invalid=false
     while m.result=="" and steps<12000:
      timer-=.1
      if timer<=0:
       act(room,strategy)
       timer=.5
      if enabled:
       for slot in range(2):
        var item=budget[slot]
        var should_use=item in ["gold","battery"] or (room.door_hp<room.max_hp()*.5 and room.door_hp>0)
        if should_use and int(p.inventory.get(item,0))>0 and p.activate_item(slot,m,entry.id):activations.append({"item":item,"time":snappedf(m.time,.1)})
      var previous=m.hunter.position
      m.tick(.1)
      if previous.distance_to(m.hunter.position)>m.hunter.speed*.1+.2:invalid=true
      if room.gold<-.001 or room.electricity<-.001 or not is_finite(room.gold) or not is_finite(room.electricity):invalid=true;break
      for item in p.inventory:
       if p.inventory[item]<0:invalid=true
      steps+=1
     if m.result=="" or invalid:failures+=1
     var key=mode+("_items" if enabled else "_baseline")
     if not summary.has(key):summary[key]={"wins":0,"losses":0,"activations":0,"matches":0}
     summary[key].matches+=1
     summary[key].activations+=activations.size()
     if m.result=="victory":summary[key].wins+=1
     else:summary[key].losses+=1
     var row={"stage":stage.id,"map":m.map_id,"difficulty":mode,"strategy":strategy,"items":enabled,"budget":budget if enabled else [],"result":m.result,"seconds":snappedf(m.time,.1),"gold_generated":snappedf(room.income_total,.1),"gold_remaining":snappedf(room.gold,.1),"power_remaining":snappedf(room.electricity,.1),"damage":snappedf(room.damage_dealt,.1),"door_damage":snappedf(room.door_damage_taken,.1),"transformed":m.hunter.transformed,"activations":activations,"invalid":invalid}
     rows.append(row)
     print("ITEM_BALANCE_RUN ",JSON.stringify(row))
     for suffix in ["",".tmp",".bak"]:
      if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var result={"matches":rows.size(),"summary":summary,"failures":failures,"results":rows}
 var output=FileAccess.open("res://docs/evidence/items/balance-results.json",FileAccess.WRITE)
 if output:output.store_string(JSON.stringify(result," "))
 print("ITEM_BALANCE_MATCHES=",rows.size()," SUMMARY=",JSON.stringify(summary)," FAILURES=",failures)
 quit(0 if failures==0 else 1)
