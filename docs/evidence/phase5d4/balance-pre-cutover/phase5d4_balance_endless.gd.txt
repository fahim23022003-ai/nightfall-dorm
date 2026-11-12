extends SceneTree
# Live earned-income runs. Seeded progression/finite stock are disclosed test budgets.
# No live HP, resources, positions, clocks or wave indices are injected.
const DT=.1
var failures=0
var cfg_alternative=false
var current_cfg={}
var all_reaches={}
var activation_counts={}
var impact_by_kind={}
var impact10_by_kind={}
var shield_absorbed=0.0
var defense_healed=0.0
var drained_gold=0.0
var max_minions=0
var domains=0
var phase2=0
var max_evolution=0
var earned_profiles=[]
var serial=0
var prefix="user://endless-balance-"+str(Time.get_ticks_usec())+"-"
var exported={}
var export_enabled=false
var resume_checks=0
const Support=preload("res://tests/replay_test_support.gd")
func _initialize():call_deferred("run")
func kinds(r,kind):
 var out=[]
 for tile in r.buildings:
  if r.buildings[tile].kind==kind:out.append(tile)
 return out
func build(m,kind):
 var r=m.player();var options=[]
 for tile in range(r.tile_count()):
  if not r.buildings.has(tile):options.append(tile)
 options.sort_custom(func(a,b):return r.tile_position(a).distance_squared_to(r.door_approach())<r.tile_position(b).distance_squared_to(r.door_approach()))
 if kind not in DefenseEffects.WEAPONS:options.reverse()
 for tile in options:
  if kind not in DefenseEffects.WEAPONS or r.tile_position(tile).distance_to(r.door_approach())<Catalog.BUILDINGS[kind].range:return m.buy(kind,tile)
 return false
func upgrade(m,kind,goal,count,branch=""):
 var r=m.player();var found=kinds(r,kind)
 if found.size()<count:build(m,kind);return false
 for tile in found:
  var b=r.buildings[tile]
  if b.level<goal:
   if b.level==4:m.specialize_building(tile,branch if branch!="" else StrategyCatalog.branches(kind)[int(cfg_alternative)])
   else:m.upgrade_building(tile)
   return false
 return true
func legacy_act(m,cfg,account):
 var r=m.player();var kind=StrategyCatalog.BRANCHES[cfg.branch].kind
 if r.door_hp<r.max_hp()*.65:
  if m.upgrade_door() or m.repair_door():return
 if r.bed_level<1:m.upgrade_bed();return
 if r.door_level<1:m.upgrade_door();return
 if kinds(r,"turret").is_empty() and kinds(r,"heavy").is_empty():build(m,"turret");return
 if kinds(r,"generator").is_empty():build(m,"generator");return
 if r.bed_level<2:m.upgrade_bed();return
 if r.door_level<2:m.upgrade_door();return
 if not upgrade(m,"generator",2,1):return
 if kinds(r,"repair").is_empty():build(m,"repair");return
 if r.bed_level<3:m.upgrade_bed();return
 if r.door_level<3:m.upgrade_door();return
 if cfg.policy=="typical":
  if not upgrade(m,"repair",3,1):return
  if not upgrade(m,kind,4,2):return
  if kinds(r,"enhancer").is_empty():build(m,"enhancer");return
 if not upgrade(m,"generator",4,2):return
 if r.bed_level<4:m.upgrade_bed();return
 if r.door_level<4:m.upgrade_door();return
 var main_max=0
 for tile in kinds(r,kind):main_max=maxi(main_max,r.buildings[tile].level)
 var amps=2 if cfg.policy=="typical" or main_max>=10 else mini(4,r.tile_count()-6)
 if not upgrade(m,"economy",4,amps):return
 if not upgrade(m,"repair",4,1):return
 if kinds(r,kind).is_empty():build(m,kind);return
 if not upgrade(m,kind,10,1,cfg.branch):return
 # Replace the cheap Needle bootstrap through the genuine half-refund transaction.
 if kind=="heavy" and not kinds(r,"turret").is_empty():
  var tile=kinds(r,"turret")[0];var refund=r.building_refund(tile)
  if m.sell_building(tile):account.refunds+=refund.x
  return
 # Free excess economy pads once the main weapon reaches10; all sales have actual ledgers.
 if kinds(r,"economy").size()>2:
  var tile=kinds(r,"economy")[-1];var refund=r.building_refund(tile)
  if m.sell_building(tile):account.refunds+=refund.x
  return
 var support=4 if cfg.get("layout","")=="fortress" and r.tile_count()>=16 else 2
 if not upgrade(m,"repair",4,support):return
 if not upgrade(m,"enhancer",4,support):return
 var count=r.tile_count()-4-2*support
 if not upgrade(m,kind,10,count,cfg.branch):return
func room_target(m,trait_choice):
 var best=-1;var distance=INF
 for r in m.rooms:
  if r.owner>=0 or r.trait_id!=trait_choice:continue
  var route=m.player_navigation_path(m.player_position,r.bed_position()+Vector2(31,49))
  if route.is_empty():continue
  var length=0.0;var previous=m.player_position
  for point in route:length+=previous.distance_to(point);previous=point
  if length<distance:best=r.index;distance=length
 return best
func walk_step(m,route):
 while not route.is_empty() and m.player_position.distance_to(route[0])<2:route.pop_front()
 if route.is_empty():return
 var offset=route[0]-m.player_position
 m.move_player(offset.normalized(),minf(DT,offset.length()/180.0))
func full_layout_ready(m,cfg):
 if m.player()==null:return false
 var r=m.player();var kind=StrategyCatalog.BRANCHES[cfg.branch].kind
 var support=4 if cfg.get("layout","")=="fortress" and r.tile_count()>=16 else 2
 for requirement in [["generator",2,4],["economy",2,4],["repair",support,4],["enhancer",support,4],[kind,r.tile_count()-4-2*support,10]]:
  var found=kinds(r,requirement[0])
  if found.size()!=requirement[1]:return false
  for tile in found:
   if r.buildings[tile].level!=requirement[2]:return false
 return true
func profile(cfg):
 serial+=1
 var p=PlayerProfile.new(prefix+str(serial)+".json");p.reward_rng.seed=cfg.seed+1000
 p.xp=8000 if cfg.get("budget","")=="mythic_control" else 3800
 p.equipped=["marksman","reaper_slayer"] if p.xp==8000 else ["dreamer","first_aid"]
 p.statistics.matches=6;p.statistics.victories=3;p.statistics.defeats=3;p.statistics.hard=3;p.statistics.reaper_defeats=3;p.next_match_id=7
 for stage in StageCatalog.STAGES:p.campaign_records[stage.id]={"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"hard","first_match_id":1}
 p.inventory={"frost":4,"time_freeze":1} if p.xp==8000 else {"shield":4,"guardian_heart":1}
 p.item_loadout=["frost","time_freeze"] if p.xp==8000 else ["shield","guardian_heart"]
 return p
func save_earned(p,m,_kind,_reach,_impact):
 if not p.checkpoint_endless(m):failures+=1;return
 var path="res://docs/evidence/phase5d4/balance-earned-"+str(current_cfg.seed)+current_cfg.mode+".json"
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(FileAccess.get_file_as_string(p.path));f.close()
 var reopened=PlayerProfile.new(path)
 if not reopened.load_profile() or reopened.resume_endless()==null:failures+=1;push_error("Earned checkpoint restore failed")
 else:earned_profiles.append(str(current_cfg.seed)+current_cfg.mode)
func simulate(cfg):
 current_cfg=cfg;all_reaches={};activation_counts={};impact_by_kind={};impact10_by_kind={};shield_absorbed=0;defense_healed=0;drained_gold=0;max_minions=0;domains=0;phase2=0;max_evolution=0;cfg_alternative=cfg.get("alternative",false)
 var p=profile(cfg);var entry=p.begin_endless(cfg.map,cfg.mode,cfg.seed)
 var m=MatchModel.new();var invalid=[]
 if entry.is_empty() or not m.configure_endless(cfg.map,cfg.mode,cfg.seed,entry.get("id",0),RankCatalog.bonuses(p.equipped)):invalid.append("configuration")
 p.bind_items(m,entry.get("id",0))
 var kind=StrategyCatalog.BRANCHES[cfg.branch].kind;var target=room_target(m,cfg.trait_id)
 var route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49)) if target>=0 else []
 var account={"refunds":0.0};var waves=[];var reaches={};var tier10_damage=0.0
 var event_id=0;var combat_id=0;var events={};var wave_events={};var max_projectiles=0;var max_events=0;var max_present=0
 var wave_player_hits=0;var wave_received=0.0;var wave_boss_attacks={}
 var minimum_hp=INF;var sleep_at=0.0;var uses=0;var steps=0;var stop="limit";var passive_from=int(cfg.get("passive_from",1000000))
 var passive_active=false;var passive_since={}
 var wave_hp_start=m.hunter.max_hp;var wave_start=m.time;var wave_damage_start=0.0;var wave_repairs_start=0
 while m.result=="" and steps<300000:
  if m.endless.phase=="intermission":
   var r=m.player()
   var row={"wave":m.endless.wave,"archetype":m.hunter.archetype,"seconds":snappedf(m.time-wave_start,.1),"time":snappedf(m.time,.1),"hunter_start_hp":snappedf(wave_hp_start,.1),"hunter_damage":snappedf(m.hunter.damage,.1),"hunter_speed":snappedf(m.hunter.speed,.1),"hunter_attacks":m.hunter.attacks,"observed_player_hits":wave_player_hits,"observed_player_damage_received":snappedf(wave_received,.1),"boss_attacks":wave_boss_attacks.duplicate(true),"door_hp":snappedf(r.door_hp,.1),"min_door_hp":snappedf(minimum_hp,.1),"gold":snappedf(r.gold,.1),"power":snappedf(r.electricity,.1),"player_damage":snappedf(r.damage_dealt-wave_damage_start,.1),"manual_repairs":r.repair_actions-wave_repairs_start,"passive":passive_active,"transformed":m.hunter.transformed,"events":wave_events.duplicate(true),"alive_team":m.rooms.filter(func(a):return a.owner>=0 and a.alive).size(),"projectiles":m.projectiles.size(),"engine_objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"static_memory":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
   waves.append(row);print("ENDLESS_BALANCE_WAVE ",JSON.stringify(row))
   if DefenseEffects.SPECIAL.all(func(k):return all_reaches.has(k)) and not earned_profiles.has(str(cfg.seed)+cfg.mode):save_earned(p,m,kind,all_reaches,0)
   if not p.checkpoint_endless(m):invalid.append("genuine_intermission_checkpoint_failed");break
   if cfg.get("save_advanced",false) and m.endless.completed==20:
    var advanced=FileAccess.open("res://docs/evidence/phase6/balance-earned-advanced-profile.json",FileAccess.WRITE)
    if advanced:advanced.store_string(FileAccess.get_file_as_string(p.path));advanced.close()
    else:invalid.append("advanced_export_failed")
   if cfg.get("resume",false) and m.endless.completed in [5,20,60]:
    var expected=JSON.stringify(ReplaySnapshot.encode(m,p.active_match.get("use_counts",{})));var original_stock=p.inventory.duplicate(true)
    var reload=PlayerProfile.new(p.path)
    if not reload.load_profile():invalid.append("checkpoint_fresh_profile_load");break
    var resumed=reload.resume_endless()
    if resumed==null:invalid.append("checkpoint_fresh_profile_resume");break
    var restored=JSON.stringify(ReplaySnapshot.encode(resumed,reload.active_match.get("use_counts",{})))
    if not Support.numeric_same(JSON.parse_string(expected),JSON.parse_string(restored)) or not Support.numeric_same(original_stock,reload.inventory):
     print("RESUME_DIFFERENCE_DETECTED");invalid.append("checkpoint_state_or_stock_changed");break
    p=reload;m=resumed;r=m.player();event_id=m.next_presentation_event_id-1;combat_id=m.next_combat_event_id-1
    resume_checks+=1
   if m.endless.completed>=cfg.waves:break
   if not m.continue_wave("repair"):invalid.append("continue_repair");break
   minimum_hp=r.door_hp;wave_start=m.time;wave_hp_start=m.hunter.max_hp;wave_damage_start=r.damage_dealt;wave_repairs_start=r.repair_actions;wave_events={};wave_player_hits=0;wave_received=0;wave_boss_attacks={}
  if m.player_room<0:
   if target<0:invalid.append("trait_access");break
   if m.rooms[target].owner>=0:
    target=room_target(m,cfg.trait_id)
    if target<0:invalid.append("trait_taken");break
    route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49))
   if m.rooms[target].bounds().has_point(m.player_position):m.interact()
   else:walk_step(m,route)
  elif not m.player().sleeping:
   walk_step(m,route)
   if m.player_position.distance_to(m.player().bed_position())<=60 and m.sleep_player():
    sleep_at=m.time
    p.bind_items(m,entry.id)
  else:
   var r=m.player()
   if not passive_active and m.endless.wave>=passive_from and (not cfg.get("wait_for_full",false) or full_layout_ready(m,cfg)):
    passive_active=true;passive_since={"wave":m.endless.wave,"time":snappedf(m.time,.1),"full_layout":full_layout_ready(m,cfg),"buildings":r.buildings.duplicate(true)}
   if not passive_active:
    if steps%(10 if cfg.policy=="typical" else 2)==0:act(m,cfg,account)
    if cfg.get("budget","")=="mythic_control":
     if m.hunter.transformed and float(m.items.timers.get("frost",0))<=0 and p.activate_item(0,m,entry.id):uses+=1
     if m.hunter.transformed and m.hunter.boss_attack!="" and p.activate_item(1,m,entry.id):uses+=1
    elif m.hunter.target==m.player_room and m.hunter.state==HunterState.State.ATTACK and r.door_hp<r.max_hp()*.5 and p.activate_item(0,m,entry.id):uses+=1
  var previous=m.hunter.position;m.tick(DT)
  max_minions=maxi(max_minions,m.minions.filter(func(u):return u.hp>0).size());max_evolution=maxi(max_evolution,m.evolution.acquired.size())
  if max_minions>10 or (m.wrath.domain_active() and m.minions.any(func(u):return u.hp>0)):invalid.append("minion_or_domain_cap");break
  for e in m.presentation_events:
   if e.id<=event_id:continue
   event_id=maxi(event_id,e.id);events[e.type]=int(events.get(e.type,0))+1;wave_events[e.type]=int(wave_events.get(e.type,0))+1
   if e.type in ["boss_resource_drain","soul_drain"] and e.room==m.player_room:drained_gold+=float(e.get("gold",0))
   if e.type=="boss_phase" and e.phase==2:phase2+=1
   if e.type=="boss_ability_activate" and e.ability=="crimson_execution":domains+=1
   if e.type=="defense_activate" and e.room==m.player_room:activation_counts[e.kind]=int(activation_counts.get(e.kind,0))+1
   if e.type=="defense_heal" and e.room==m.player_room:defense_healed+=e.damage
   if e.type=="shield_absorb" and e.room==m.player_room:shield_absorbed+=e.damage
   if e.type=="door_damage" and e.room==m.player_room:wave_player_hits+=1;wave_received+=e.damage
   if e.type=="boss_impact":wave_boss_attacks[e.attack]=int(wave_boss_attacks.get(e.attack,0))+1
   elif e.type=="boss_surge":wave_boss_attacks.surge=int(wave_boss_attacks.get("surge",0))+1
  for e in m.combat_events:
   if e.id<=combat_id:continue
   combat_id=maxi(combat_id,e.id)
   if e.type=="impact" and e.room==m.player_room:
    impact_by_kind[e.kind]=float(impact_by_kind.get(e.kind,0))+e.damage
    if e.level==10:impact10_by_kind[e.kind]=float(impact10_by_kind.get(e.kind,0))+e.damage
    if e.kind==kind and e.level==10:tier10_damage+=e.damage
  if m.player()!=null:
   var r=m.player();minimum_hp=minf(minimum_hp,r.door_hp)
   if absf(r.gold+r.spent+drained_gold-account.refunds-25-r.income_total)>.1:invalid.append("unearned_gold_or_ledger_drift");break
   if not is_finite(r.gold) or not is_finite(r.electricity) or r.gold<-.001 or r.electricity<-.001:invalid.append("wallet");break
   for tile in kinds(r,kind):
    var b=r.buildings[tile]
    for level in [5,10]:
     if b.level>=level and not reaches.has(str(level)):reaches[str(level)]={"wave":m.endless.wave,"time":snappedf(m.time,.1),"income":snappedf(r.income_total,.1),"spent":snappedf(r.spent,.1),"refunds":snappedf(account.refunds,.1),"gold":snappedf(r.gold,.1),"power":snappedf(r.electricity,.1),"tile":tile,"invested_gold":b.invested_gold,"invested_power":b.invested_power}
  for stock in p.inventory.values():
   if stock<0:invalid.append("negative_stock")
  if m.items.legendary_used>1:invalid.append("legendary_limit")
  max_projectiles=maxi(max_projectiles,m.projectiles.size());max_events=maxi(max_events,m.combat_events.size());max_present=maxi(max_present,m.presentation_events.size())
  record_reaches(m)
  if m.time-wave_start>900:stop="wave_timeout";break
  steps+=1
 if m.result=="defeat":
  stop="defeat"
  if p.settle_endless(m).is_empty():invalid.append("defeat_settlement")
 elif m.endless.completed>=cfg.waves:stop="bounded_target_reached"
 elif steps>=300000:stop="time_budget"
 if m.endless.phase=="intermission" and m.endless.completed>=cfg.waves:
  var closed=p.end_endless_here(m)
  if closed.is_empty():invalid.append("safe_exit_failed")
  var cash=p.rm_cash;var xp=p.xp
  if not p.end_endless_here(m).is_empty() or p.rm_cash!=cash or p.xp!=xp:invalid.append("duplicate_safe_exit_reward")
 if not invalid.is_empty():failures+=1
 var r=m.player();var final_buildings=r.buildings.duplicate(true) if r!=null else {}
 for b in final_buildings.values():b.erase("cooldown");b.erase("flash")
 var final_wave={"wave":m.endless.wave,"hunter_hp":m.hunter.hp,"hunter_attacks":m.hunter.attacks,"min_door_hp":minimum_hp,"door_hp":r.door_hp if r!=null else 0,"observed_player_hits":wave_player_hits,"observed_player_damage_received":wave_received,"manual_repairs":r.repair_actions-wave_repairs_start if r!=null else 0,"boss_attacks":wave_boss_attacks,"events":wave_events}
 var row={"config":cfg,"completed":m.endless.completed,"active_wave":m.endless.wave,"stop":stop,"seconds":snappedf(m.time,.1),"sleep_at":snappedf(sleep_at,.1),"passive_since":passive_since,"reaches":reaches,"tier10_impact_damage":snappedf(tier10_damage,.1),"waves":waves,"final_wave":final_wave,"income":snappedf(r.income_total,.1) if r!=null else 0,"spent":snappedf(r.spent,.1) if r!=null else 0,"refunds":account.refunds,"gold":snappedf(r.gold,.1) if r!=null else 0,"power":snappedf(r.electricity,.1) if r!=null else 0,"uses":uses,"legendary_used":m.items.legendary_used,"remaining_stock":p.inventory,"perks":p.equipped,"events":events,"buildings":final_buildings,"peak_projectiles":max_projectiles,"peak_combat_events":max_events,"peak_presentation_events":max_present,"impact_by_kind":impact_by_kind,"impact10_by_kind":impact10_by_kind,"shield_absorbed":shield_absorbed,"room_index":r.index,"tile_count":r.tile_count(),"all_reaches":all_reaches,"defense_activations":activation_counts,"defense_healed":defense_healed,"drained_gold":drained_gold,"max_minions":max_minions,"domains":domains,"phase2":phase2,"max_evolution":max_evolution,"main_damage":r.main_damage_dealt,"minion_damage":r.minion_damage_dealt,"checkpoint_bytes":FileAccess.get_file_as_bytes(p.path).size(),"invalid":invalid}
 print("ENDLESS_BALANCE_RUN ",JSON.stringify(row))
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(p.path+suffix):DirAccess.remove_absolute(p.path+suffix)
 return row
func record_reaches(m):
 var r=m.player()
 if r==null:return
 for kind in ["bed","door"]+Catalog.BUILDINGS.keys():
  var level=r.bed_level+1 if kind=="bed" else r.door_level+1 if kind=="door" else 0
  for tile in kinds(r,kind):level=maxi(level,r.buildings[tile].level)
  if level==10 and not all_reaches.has(kind):all_reaches[kind]={"wave":m.endless.wave,"time":m.time,"income":r.income_total,"spent":r.spent,"gold":r.gold,"power":r.electricity}
func structure(m,kind):
 var r=m.player();var level=r.bed_level if kind=="bed" else r.door_level
 if level>=9:return true
 if level==4:r.specialize_structure(kind,StrategyCatalog.branches(kind)[int(cfg_alternative)])
 elif kind=="bed":m.upgrade_bed()
 else:m.upgrade_door()
 return false
func act(m,cfg,account):
 if cfg.get("old_fortress",false):legacy_act(m,cfg,account);return
 var r=m.player();var main=StrategyCatalog.BRANCHES[cfg.branch].kind
 var ready=false
 for tile in kinds(r,main):ready=ready or r.buildings[tile].level==10
 if not ready:legacy_act(m,cfg,account);return
 if main=="heavy" and not kinds(r,"turret").is_empty():
  var t=kinds(r,"turret")[0];var refund=r.building_refund(t)
  if m.sell_building(t):account.refunds+=refund.x
  return
 if r.door_hp<r.max_hp()*.7:
  if (r.door_level!=4 and m.upgrade_door()) or m.repair_door():return
 # Remove excess amplifier pads via actual 50% refund, retaining two income buildings.
 if kinds(r,"economy").size()>2:
  var t=kinds(r,"economy")[-1];var refund=r.building_refund(t)
  if m.sell_building(t):account.refunds+=refund.x
  return
 if not upgrade(m,"generator",10,2):return
 if r.bed_level<9 or r.door_level<9:
  structure(m,"bed" if r.bed_level<=r.door_level and r.bed_level<9 else "door");return
 if not upgrade(m,"economy",10,2):return
 for kind in ["shock","flame","frost","auto_repair","shield","decoy"]:
  if not upgrade(m,kind,10,1):return
 if r.door_hp<r.max_hp()*.96:m.repair_door()
func run():
 var rows=[];var configs=[]
 if "--new-long" in OS.get_cmdline_user_args():
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":120,"resume":true,"alternative":false,"budget":"mythic_control"})
 elif "--hell-checkpoint" in OS.get_cmdline_user_args():
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":20,"resume":true,"alternative":false,"budget":"mythic_control"})
 elif "--checkpoint" in OS.get_cmdline_user_args():
  configs.append({"map":"cursed_mansion","mode":"standard","trait_id":"fortified","branch":"storm","seed":71,"policy":"optimized","waves":20,"resume":true,"alternative":true})
 elif "--new-final" in OS.get_cmdline_user_args():
  for i in range(2):configs.append({"map":"cursed_mansion","mode":["standard","hell"][i],"trait_id":"fortified","branch":"storm","seed":[71,47][i],"policy":"optimized","waves":40,"resume":true,"alternative":i==0,"budget":"mythic_control" if i==1 else "master"})
 elif "--long" in OS.get_cmdline_user_args():
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":120,"resume":true,"old_fortress":true,"layout":"fortress","budget":"mythic_control"})
 elif "--all-new" in OS.get_cmdline_user_args():
  configs.append({"map":"cursed_mansion","mode":"standard","trait_id":"fortified","branch":"storm","seed":71,"policy":"optimized","waves":30,"resume":true,"alternative":true})
 elif "--fortress" in OS.get_cmdline_user_args():
  for mode in ["standard","hell"]:configs.append({"map":"cursed_mansion","mode":mode,"trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":35,"resume":true,"old_fortress":true,"layout":"fortress","budget":"mythic_control"})
 else:
  for i in range(3):configs.append({"map":"cursed_mansion","mode":["standard","hard","hell"][i],"trait_id":["economy","power","fortified"][i],"branch":"suppression" if i==0 else "storm","seed":[11,37,47][i],"policy":"optimized","waves":40,"resume":true,"alternative":i%2==1,"budget":"mythic_control" if i==2 else "master"})
 for cfg in configs:rows.append(simulate(cfg))
 var out={"scope":"Live earned-currency navigation/claim/sleep/economy/AI/combat. Finite prepared Master/Mythic budgets, 0.2s policy; no live HP/currency/position/clock/wave injections. Genuine checkpoints resumed at5/20. New building branches first/second configured; old fortress separated.","runs":rows,"failures":failures,"resume_checks":resume_checks,"earned_profiles":earned_profiles}
 var f=FileAccess.open("res://docs/evidence/phase5d4/balance-endless"+("-new-long" if "--new-long" in OS.get_cmdline_user_args() else "-hell-checkpoint" if "--hell-checkpoint" in OS.get_cmdline_user_args() else "-checkpoint" if "--checkpoint" in OS.get_cmdline_user_args() else "-new-final" if "--new-final" in OS.get_cmdline_user_args() else "-long" if "--long" in OS.get_cmdline_user_args() else "-fortress" if "--fortress" in OS.get_cmdline_user_args() else "-all-new" if "--all-new" in OS.get_cmdline_user_args() else "")+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(out," "));f.close()
 print("PHASE5D4_EARNED_RUNS=",rows.size()," FAILURES=",failures," RESUMES=",resume_checks)
 quit(1 if failures else 0)
