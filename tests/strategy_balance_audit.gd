extends SceneTree
# Bounded diagnostic policies. Currency/HP/time/positions are never injected in live matches.
# Prepared progression, finite existing stock and deterministic 0.1s decisions are disclosed.
var failures=0
var serial=0
var prefix="user://strategy-balance-"+str(Time.get_ticks_usec())+"-"
const DT=.1
func _initialize():call_deferred("run")
func tiles(r,kind):
 var out=[]
 for tile in r.buildings:
  if r.buildings[tile].kind==kind:out.append(tile)
 return out
func empty(m,kind):
 var r=m.player();var options=[]
 for tile in range(r.tile_count()):
  if not r.buildings.has(tile):options.append(tile)
 # Weapons get the closest legal pad; supports preserve those pads.
 options.sort_custom(func(a,b):return r.tile_position(a).distance_squared_to(r.door_approach())<r.tile_position(b).distance_squared_to(r.door_approach()))
 if kind not in ["turret","heavy"]:options.reverse()
 for tile in options:
  if kind not in ["turret","heavy"] or r.tile_position(tile).distance_to(r.door_approach())<Catalog.BUILDINGS[kind].range:return m.buy(kind,tile)
 return false
func upgrade_kind(m,kind,goal,count):
 var r=m.player();var found=tiles(r,kind)
 if found.size()<count:return empty(m,kind)
 for tile in found:
  if r.buildings[tile].level<goal:return m.upgrade_building(tile)
 return true
func weapon_cost(kind):
 var cost=Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power)+StrategyCatalog.BRANCH_FEE
 for level in range(1,10):cost+=Catalog.upgrade_cost(kind,level)
 return cost
func act(m,branch,policy,contract):
 var r=m.player();var kind=StrategyCatalog.BRANCHES[branch].kind
 if r.door_hp<r.max_hp()*.65:
  if m.upgrade_door() or (contract!="iron_survivor" and m.repair_door()):return
 if policy=="branch_first":
  if tiles(r,"generator").is_empty():empty(m,"generator");return
  if r.bed_level<1:m.upgrade_bed();return
  if r.door_level<1:m.upgrade_door();return
  if not upgrade_kind(m,"generator",2,1):return
  if r.bed_level<2:m.upgrade_bed();return
  if r.door_level<2:m.upgrade_door();return
  if not upgrade_kind(m,"economy",2,2):return
  if r.bed_level<3:m.upgrade_bed();return
  if r.door_level<3:m.upgrade_door();return
  if not upgrade_kind(m,"generator",4,1):return
  if tiles(r,kind).is_empty():empty(m,kind);return
  if r.buildings[tiles(r,kind)[0]].level<5:return
  if r.bed_level<4:m.upgrade_bed();return
  if r.door_level<4:m.upgrade_door();return
  if not upgrade_kind(m,"generator",4,2):return
  if not upgrade_kind(m,"repair",4,1):return
  if not upgrade_kind(m,"economy",4,4):return
  return
 if tiles(r,"generator").is_empty():empty(m,"generator");return
 if r.bed_level<1:m.upgrade_bed();return
 if r.door_level<1:m.upgrade_door();return
 if policy=="frontline" and tiles(r,kind).is_empty():empty(m,kind);return
 if not upgrade_kind(m,"generator",2,1):return
 if r.bed_level<2:m.upgrade_bed();return
 if r.door_level<2:m.upgrade_door();return
 if r.bed_level<3:m.upgrade_bed();return
 if r.door_level<3:m.upgrade_door();return
 if not upgrade_kind(m,"generator",4,2):return
 if r.bed_level<4:m.upgrade_bed();return
 if r.door_level<4:m.upgrade_door();return
 if not upgrade_kind(m,"economy",4,4):return
 if not upgrade_kind(m,"repair",4,1):return
 if tiles(r,kind).is_empty():
  var reserve=weapon_cost(kind)
  if r.gold>=reserve.x and r.electricity>=reserve.y:empty(m,kind)
  return
 if r.door_hp<r.max_hp()*.95 and contract!="iron_survivor":m.repair_door()
func advance_weapon(m,branch):
 var r=m.player();var kind=StrategyCatalog.BRANCHES[branch].kind
 for tile in tiles(r,kind):
  var b=r.buildings[tile]
  if b.level==4:m.specialize_building(tile,branch)
  elif b.level<10:m.upgrade_building(tile)
func distance_path(m,target):
 var route=m.player_navigation_path(m.player_position,target);var total=0.0;var previous=m.player_position
 if route.is_empty() and previous.distance_to(target)>2:return INF
 for point in route:total+=previous.distance_to(point);previous=point
 return total
func choose_room(m,trait_choice):
 var best=-1;var distance=INF
 for r in m.rooms:
  if r.owner>=0 or r.trait_id!=trait_choice:continue
  var d=distance_path(m,r.bed_position()+Vector2(31,49))
  if d<distance:best=r.index;distance=d
 return best
func walk_step(m,route):
 while not route.is_empty() and m.player_position.distance_to(route[0])<2:route.pop_front()
 if route.is_empty():return
 var offset=route[0]-m.player_position
 m.move_player(offset.normalized(),minf(DT,offset.length()/180.0))
func profile_for(mode,stage,archetype,contract,arm):
 serial+=1
 var p=PlayerProfile.new(prefix+str(serial)+".json")
 p.xp=8000 if arm=="mythic_control" else 3800
 p.equipped=["marksman","reaper_slayer"] if arm=="mythic_control" else ["dreamer","first_aid"]
 # Existing progressed-save budget; history unlocks maps/perks, never match resources.
 p.statistics.matches=6;p.statistics.victories=3;p.statistics.defeats=3;p.statistics.hard=3;p.statistics.reaper_defeats=3;p.next_match_id=7
 for known in StageCatalog.STAGES:p.campaign_records[known.id]={"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"hard","first_match_id":1}
 while p.next_archetype(stage,mode)!=archetype:p.statistics.matches+=1;p.statistics.defeats+=1;p.next_match_id+=1
 p.inventory={"frost":4,"time_freeze":1} if arm=="mythic_control" else {"shield":4,"guardian_heart":1}
 p.item_loadout=["frost","time_freeze"] if arm=="mythic_control" else ["shield","guardian_heart"]
 if contract=="no_legendary":p.item_loadout=["shield"]
 p.selected_contract=contract
 return p
func simulate(archetype,mode,trait_choice,branch,stage,seed_value,policy="frontline",contract="",arm="master_defense"):
 var p=profile_for(mode,stage,archetype,contract,arm)
 p.reward_rng.seed=seed_value+1000
 var entry=p.begin_match(mode,stage,true)
 var m=MatchModel.new();m.reset(seed_value)
 var invalid=[]
 if entry.is_empty():invalid.append("begin_match_failed")
 m.configure_match(mode,RankCatalog.bonuses(p.equipped));m.configure_stage(stage)
 if not m.configure_strategy(seed_value,archetype,contract,entry.get("id",0)):invalid.append("strategy_configuration_failed")
 p.bind_items(m,entry.get("id",0))
 var target=choose_room(m,trait_choice);var initial_target=target
 var route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49)) if target>=0 else []
 var steps=0;var sleep_at=0.0;var maxlevel=0;var reached5=0.0;var reached10=0.0;var damage5=0.0;var damage10=0.0
 var event_id=0;var events={};var legendary=0;var uses=0;var reaper_attacks=0
 var reaper_hp_at=0.0;var reaper_time=0.0;var max_frozen=0.0;var frozen=0.0
 while m.result=="" and steps<9000:
  if m.player_room<0:
   if target<0:invalid.append("trait_room_unavailable");break
   if m.rooms[target].owner>=0:
    target=choose_room(m,trait_choice)
    if target<0:invalid.append("trait_room_taken_during_access");break
    route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49))
   if m.rooms[target].bounds().has_point(m.player_position):m.interact()
   else:walk_step(m,route)
  elif not m.player().sleeping:
   walk_step(m,route)
   if m.player_position.distance_to(m.player().bed_position())<=60 and m.sleep_player():sleep_at=m.time
  else:
   var r=m.player()
   if steps%5==0:act(m,branch,policy,contract)
   # Reserve policy buys the complete tree; frontline upgrades incrementally with earned resources.
   advance_weapon(m,branch)
   if arm=="master_defense":
    if m.hunter.target==m.player_room and m.hunter.state==HunterState.State.ATTACK and r.door_hp<r.max_hp()*.5 and p.activate_item(0,m,entry.id):uses+=1
   elif m.hunter.transformed:
    if float(m.items.timers.get("frost",0))<=0 and p.activate_item(0,m,entry.id):uses+=1
    if m.hunter.boss_attack!="" and p.activate_item(1,m,entry.id):legendary+=1
  var previous=m.hunter.position;var was_reaper=m.hunter.transformed
  m.tick(DT)
  if not was_reaper and m.hunter.transformed:reaper_time=m.time;reaper_hp_at=m.hunter.hp
  frozen=frozen+DT if m.items.frozen_delta>0 else 0.0;max_frozen=maxf(max_frozen,frozen)
  if previous.distance_to(m.hunter.position)>m.hunter.speed*DT+.2:invalid.append("hunter_displacement_exceeds_speed");break
  for e in m.presentation_events:
   if e.id<=event_id:continue
   event_id=maxi(event_id,e.id);events[e.type]=int(events.get(e.type,0))+1
   if e.type=="door_damage" and e.transformed:reaper_attacks+=1
  if m.player()!=null:
   var r=m.player()
   if not is_finite(r.gold) or not is_finite(r.electricity) or r.gold<-.001 or r.electricity<-.001:invalid.append("invalid_wallet");break
   if absf(r.gold+r.spent-25.0-r.income_total)>.01:invalid.append("unearned_gold_or_spend_drift");break
   for tile in tiles(r,StrategyCatalog.BRANCHES[branch].kind):maxlevel=maxi(maxlevel,r.buildings[tile].level)
   if maxlevel>=5:
    if reached5==0:reached5=m.time
    for e in m.combat_events:
     if e.type=="impact" and e.room==m.player_room and e.time>m.time-DT+.001 and e.level>=5:damage5+=e.damage
   if maxlevel==10:
    if reached10==0:reached10=m.time
    for e in m.combat_events:
     if e.type=="impact" and e.room==m.player_room and e.time>m.time-DT+.001 and e.level==10:damage10+=e.damage
  if m.items.legendary_used>1:invalid.append("legendary_limit");break
  for stock in p.inventory.values():
   if stock<0:invalid.append("negative_stock")
  steps+=1
 if m.result=="":invalid.append("nonterminal_or_access_failure")
 var r=m.player();var result=m.result;var eligible=m.strategy.reward_eligible(m,entry)
 legendary=maxi(legendary,m.items.legendary_used)
 var award=p.settle_match(entry.id,m) if result!="" else {}
 if result!="" and award.is_empty():invalid.append("actual_settlement_failed")
 var row={"seed":seed_value,"archetype":archetype,"mode":mode,"stage":stage,"map":m.map_id,"trait":trait_choice,"room":m.player_room,"initial_room":initial_target,"branch":branch,"policy":policy,"arm":arm,"perks":p.equipped,"contract":contract,"contract_eligible":eligible,"contract_failed":m.strategy.failed,"cash":award.get("rm_cash",0),"contract_cash":award.get("contract",{}).get("cash",0),"result":result,"seconds":snappedf(m.time,.1),"sleep_at":snappedf(sleep_at,.1),"level":maxlevel,"reached5":snappedf(reached5,.1),"reached10":snappedf(reached10,.1),"tier5plus_damage":snappedf(damage5,.1),"tier10_damage":snappedf(damage10,.1),"player_damage":snappedf(r.damage_dealt,.1) if r!=null else 0,"income":snappedf(r.income_total,.1) if r!=null else 0,"spent":snappedf(r.spent,.1) if r!=null else 0,"gold":snappedf(r.gold,.1) if r!=null else 0,"power":snappedf(r.electricity,.1) if r!=null else 0,"stock_uses":uses,"legendary_uses":legendary,"transformed":m.hunter.transformed,"reaper_at":snappedf(reaper_time,.1),"reaper_hp_at":snappedf(reaper_hp_at,.1),"reaper_attacks":reaper_attacks,"max_frozen_seconds":snappedf(max_frozen,.1),"retargets":m.hunter.retargets,"events":events,"invalid":invalid}
 if not invalid.is_empty():failures+=1
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(p.path+suffix):DirAccess.remove_absolute(p.path+suffix)
 print("STRATEGY_BALANCE_RUN ",JSON.stringify(row))
 return row
func run():
 var rows=[];var args=OS.get_cmdline_user_args();var pilot="--pilot" in args
 if "--check" in args:
  controlled_combat(true,true)
  return
 if "--controlled" in args:
  controlled_combat("--needle-only" in args)
  return
 if "--arc-first" in args:
  for ai in range(3):
   for mode in ["standard","hard"]:
    for branch in ["focus","storm"]:
     rows.append(simulate(StrategyCatalog.ARCHETYPE_IDS[ai],mode,"economy",branch,"stage_4",47,"branch_first"))
  write_results(rows,"balance-arc-first-results.json")
  return
 for ai in ([] if "--reach-only" in args else range(3)):
  if pilot and ai!=2:continue
  for mi in range(3):
   if pilot and mi!=0:continue
   for ti in range(3):
    if pilot and ti!=2:continue
    var stage=StageCatalog.STAGES[posmod(ai*9+mi*3+ti,5)].id
    for branch in (["precision","suppression"] if "--needle-only" in args else ["precision","suppression","focus","storm"]):
     rows.append(simulate(StrategyCatalog.ARCHETYPE_IDS[ai],["standard","hard","hell"][mi],StrategyCatalog.TRAIT_IDS[ti],branch,stage,11))
 # Paired full-tree reservation probes, plus separate finite Mythic control budget and contracts.
 if not pilot:
  for ai in range(3):
   for branch in (["precision","suppression"] if "--needle-only" in args else ["precision","suppression","focus","storm"]):
    rows.append(simulate(StrategyCatalog.ARCHETYPE_IDS[ai],"standard","economy",branch,StageCatalog.STAGES[ai+1].id,47,"reserve"))
  for ai in ([] if "--reach-only" in args else range(3)):
   for mi in range(3):
    rows.append(simulate(StrategyCatalog.ARCHETYPE_IDS[ai],["standard","hard","hell"][mi],"fortified","suppression","stage_5",47,"frontline","","mythic_control"))
  for ai in ([] if "--reach-only" in args else range(3)):
   for contract in ["no_legendary","limited_defense","iron_survivor"]:
    rows.append(simulate(StrategyCatalog.ARCHETYPE_IDS[ai],"hard","economy","precision","stage_2",47,"frontline",contract))
 var output="balance-needle-results.json" if "--needle-only" in args else "balance-pilot-results.json" if pilot else "balance-reach-pilot-results.json" if "--reach-only" in args else "balance-results.json"
 write_results(rows,output)
func write_results(rows,output):
 var summary={}
 for row in rows:
  var key=row.arm+"_"+row.policy+"_"+row.mode+"_"+row.branch
  if not summary.has(key):summary[key]={"wins":0,"losses":0,"level5":0,"level10":0,"transforms":0}
  summary[key].wins+=int(row.result=="victory");summary[key].losses+=int(row.result!="victory");summary[key].level5+=int(row.level>=5);summary[key].level10+=int(row.level==10);summary[key].transforms+=int(row.transformed)
 var out={"matches":rows.size(),"failures":failures,"scope":"Diagnostic prepared-save policies, actual earned match currency and physical access; not human rates or naturally earned item stock.","master_budget":"Master dreamer+first_aid, 4 Shields+1 automatic Heart; no stage bonus","mythic_budget":"Mythic marksman+reaper_slayer, 4 Frost+1 TimeFreeze, no stage bonus","rows":rows,"summary":summary}
 var file=FileAccess.open("res://docs/evidence/premium-strategy/"+output,FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(out," "))
 print("STRATEGY_BALANCE_MATCHES=",rows.size()," FAILURES=",failures," SUMMARY=",JSON.stringify(summary))
 quit(0 if failures==0 else 1)
func controlled_combat(needle_only=false,check_mode=false):
 # Explicitly synthetic fixed-target projectile fixture. Injected wallet/HP/position/time,
 # no Hunter AI/economy tick. Never pooled with earned-currency matches or win rates.
 var rows=[]
 for reaper in [false,true]:
  for distance in ([180.0,220.0] if needle_only else [180.0,220.0,330.0]):
   for branch in (["precision","suppression"] if needle_only else ["precision","suppression","focus","storm"]):
    var m=MatchModel.new();m.reset(47);m.configure_match("standard");m.configure_stage("stage_5");m.configure_strategy(47,"ravager")
    m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
    var r=m.player();r.gold=100000.0;r.electricity=100000.0
    for i in range(4):r.upgrade_bed();r.upgrade_door()
    var kind=StrategyCatalog.BRANCHES[branch].kind
    if not m.buy(kind,0):failures+=1
    for i in range(3):
     if not m.upgrade_building(0):failures+=1
    if not m.specialize_building(0,branch):failures+=1
    for i in range(5):
     if not m.upgrade_building(0):failures+=1
    m.time=m.preparation+100.0;m.hunter.transformed=reaper;m.hunter.state=HunterState.State.ATTACK
    m.hunter.hp=100000.0;m.hunter.max_hp=100000.0
    m.hunter.position=r.tile_position(0)+Vector2(distance,0)
    var start_hp=m.hunter.hp
    for step in range(400):
     m.time+=.05;m._age_combat_events(.05);m._advance_projectiles(.05);m._turrets(.05)
    var row={"fixture":"CONTROLLED_FIXED_TARGET_L10","branch":branch,"reaper":reaper,"distance":distance,"seconds":20,"level":r.buildings[0].level,"paid_gold":r.buildings[0].invested_gold,"paid_power":r.buildings[0].invested_power,"shots":r.shots,"impacts_damage":snappedf(start_hp-m.hunter.hp,.1),"dps":snappedf((start_hp-m.hunter.hp)/20.0,.1),"remaining_projectiles":m.projectiles.size(),"suppression_strength":m.hunter.suppression_strength}
    rows.append(row);print("STRATEGY_BALANCE_CONTROLLED ",JSON.stringify(row))
 if check_mode:
  for offset in [0,4]:
   if rows[offset].impacts_damage<=rows[offset+1].impacts_damage or rows[offset+1].impacts_damage<=0:failures+=1;push_error("Needle close-range damage tradeoff missing")
   if rows[offset+2].impacts_damage!=0 or rows[offset+3].impacts_damage<=0:failures+=1;push_error("Needle 220px coverage tradeoff missing")
  for row in rows:
   if row.level!=10 or row.paid_gold<=0 or row.paid_power<=0:failures+=1;push_error("Needle paid Level10 fixture invalid")
 var out={"fixtures":rows.size(),"failures":failures,"scope":"CONTROLLED fixed targets: injected wallet/HP/time/positions; actual paid branch transactions and projectile engine, excludes Hunter AI and economy. Not natural balance or win evidence.","rows":rows}
 var output="balance-check-results.json" if check_mode else "balance-controlled-needle-results.json" if needle_only else "balance-controlled-results.json"
 var file=FileAccess.open("res://docs/evidence/premium-strategy/"+output,FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(out," "))
 print("STRATEGY_BALANCE_CONTROLLED_FIXTURES=",rows.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
