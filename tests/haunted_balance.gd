extends SceneTree
# Full live matches: earned resources, finite seeded defensive stock, paired cap-4/cap-10 policies.
# Diagnostic automated policies, not naturally earned stock or human win rates.
var failures=0
func _initialize():call_deferred("run")
func tiles(r,kind):
 var out=[]
 for tile in r.buildings:
  if r.buildings[tile].kind==kind:out.append(tile)
 return out
func empty(r,kind):
 var candidates=[]
 for tile in range(r.tile_count()):
  if not r.buildings.has(tile):candidates.append(tile)
 if candidates.is_empty():return false
 # A weapon must be in real range of its own door approach.
 for tile in candidates:
  if kind not in ["turret","heavy"] or r.tile_position(tile).distance_to(r.door_approach())<Catalog.BUILDINGS[kind].range:return r.build(kind,tile)
 return false
func upgrade_kind(r,kind,goal,count):
 var found=tiles(r,kind)
 if found.size()<count:return empty(r,kind)
 for tile in found:
  if r.buildings[tile].level<goal:return r.upgrade_building(tile)
 return true
func total_cost(kind,cap):
 var cost=Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power)
 for level in range(1,cap):cost+=Catalog.upgrade_cost(kind,level)
 return cost
func act(r,kind,cap):
 if r.door_hp<r.max_hp()*.65:
  if r.upgrade_door() or r.repair_door():return
 if tiles(r,"generator").is_empty():empty(r,"generator");return
 if r.bed_level<1:r.upgrade_bed();return
 if r.door_level<1:r.upgrade_door();return
 if not upgrade_kind(r,"generator",2,1):return
 if r.bed_level<2:r.upgrade_bed();return
 if r.door_level<2:r.upgrade_door();return
 if r.bed_level<3:r.upgrade_bed();return
 if r.door_level<3:r.upgrade_door();return
 if not upgrade_kind(r,"generator",4,2):return
 if r.bed_level<4:r.upgrade_bed();return
 if r.door_level<4:r.upgrade_door();return
 if not upgrade_kind(r,"economy",4,4):return
 if not upgrade_kind(r,"repair",4,1):return
 var target=tiles(r,kind)
 if target.is_empty():
  var reserve=total_cost(kind,cap)
  if r.gold>=reserve.x and r.electricity>=reserve.y:empty(r,kind)
  return
 if r.buildings[target[0]].level<cap:return
 if r.door_hp<r.max_hp()*.95:r.repair_door()
func run():
 var rows=[];var summary={};var serial=0
 for stage in StageCatalog.STAGES:
  for mode in ["standard","hard","hell"]:
   for kind in ["turret","heavy"]:
    for cap in [4,10]:
     serial+=1
     var path="user://haunted-balance-"+str(Time.get_ticks_usec())+"-"+str(serial)+".json"
     var p=PlayerProfile.new(path);p.xp=3800;p.equipped=["dreamer","first_aid"]
     p.inventory={"shield":4,"guardian_heart":1};p.item_loadout=["shield","guardian_heart"]
     var entry=p.begin_match(mode)
     var m=MatchModel.new();m.reset(11);m.configure_match(mode,RankCatalog.bonuses(entry.equipped));m.configure_stage(stage.id)
     m.claim_room(stage.number%6);m.player_position=m.player().bed_position();m.sleep_player();p.bind_items(m,entry.id)
     var r=m.player();var decision=0.0;var steps=0;var reached_at=0.0;var maxlevel=0;var invalid=false;var shields=0
     while m.result=="" and steps<10000:
      decision-=.1
      if decision<=0:act(r,kind,cap);decision=.5
      var active_target=tiles(r,kind)
      if not active_target.is_empty() and r.buildings[active_target[0]].level<cap:r.upgrade_building(active_target[0])
      if m.hunter.target==m.player_room and m.hunter.state==HunterState.State.ATTACK and r.door_hp<r.max_hp()*.5:
       if p.activate_item(0,m,entry.id):shields+=1
      var previous=m.hunter.position;m.tick(.1)
      if previous.distance_to(m.hunter.position)>m.hunter.speed*.1+.2:invalid=true
      for tile in tiles(r,kind):maxlevel=maxi(maxlevel,r.buildings[tile].level)
      if maxlevel==10 and reached_at<=0:reached_at=m.time
      if not is_finite(r.gold) or not is_finite(r.electricity) or r.gold<-.001 or r.electricity<-.001 or m.items.legendary_used>1:invalid=true
      for stock in p.inventory.values():if stock<0:invalid=true
      steps+=1
     if m.result=="" or invalid:failures+=1
     var key=mode+"_"+kind+"_cap"+str(cap)
     if not summary.has(key):summary[key]={"wins":0,"losses":0,"reached10":0,"maxlevel":0}
     summary[key].wins+=int(m.result=="victory");summary[key].losses+=int(m.result!="victory");summary[key].reached10+=int(maxlevel==10);summary[key].maxlevel=maxi(summary[key].maxlevel,maxlevel)
     var row={"stage":stage.id,"mode":mode,"kind":kind,"cap":cap,"result":m.result,"seconds":snappedf(m.time,.1),"level":maxlevel,"reached_at":snappedf(reached_at,.1),"gold_generated":snappedf(r.income_total,.1),"gold_remaining":snappedf(r.gold,.1),"power_remaining":snappedf(r.electricity,.1),"shield_uses":shields,"legendary_uses":m.items.legendary_used,"transformed":m.hunter.transformed,"invalid":invalid}
     rows.append(row);print("HAUNTED_BALANCE_RUN ",JSON.stringify(row))
     for suffix in ["",".bak",".tmp"]:
      if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var result={"matches":rows.size(),"failures":failures,"summary":summary,"rows":rows,"stock_budget":"4 Shields +1 Guardian Heart; paired Master dreamer+first_aid; earned currency"}
 var file=FileAccess.open("res://docs/evidence/haunted/balance-results.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(result," "))
 print("HAUNTED_BALANCE_MATCHES=",rows.size()," SUMMARY=",JSON.stringify(summary)," FAILURES=",failures)
 quit(0 if failures==0 else 1)
