extends SceneTree
# Live earned-income runs. Seeded progression/finite stock are disclosed test budgets.
# No live HP, resources, positions, clocks or wave indices are injected.
const DT=.1
var failures=0
var serial=0
var prefix="user://endless-balance-"+str(Time.get_ticks_usec())+"-"
var exported={}
var export_enabled=false
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
 if kind not in ["turret","heavy"]:options.reverse()
 for tile in options:
  if kind not in ["turret","heavy"] or r.tile_position(tile).distance_to(r.door_approach())<Catalog.BUILDINGS[kind].range:return m.buy(kind,tile)
 return false
func upgrade(m,kind,goal,count,branch=""):
 var r=m.player();var found=kinds(r,kind)
 if found.size()<count:build(m,kind);return false
 for tile in found:
  var b=r.buildings[tile]
  if b.level<goal:
   if b.level==4 and kind in ["turret","heavy"]:m.specialize_building(tile,branch)
   else:m.upgrade_building(tile)
   return false
 return true
func act(m,cfg,account):
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
func save_earned(p,m,kind,reach,impact):
 if not export_enabled or exported.has(kind) or impact<=0:return
 if not p.checkpoint_endless(m):failures+=1;push_error("Earned checkpoint save failed");return
 var dest="res://docs/evidence/replay/balance-earned-"+kind+"-profile.json"
 var from=FileAccess.open(p.path,FileAccess.READ);var file=FileAccess.open(dest,FileAccess.WRITE)
 if not from or not file:failures+=1;return
 file.store_string(from.get_as_text());file.close();from.close()
 var reopened=PlayerProfile.new(dest)
 var valid=reopened.load_profile();var resumed=reopened.resume_endless() if valid else null
 if resumed==null:failures+=1;push_error("Earned checkpoint did not reopen");return
 var r=resumed.player();var towers=[]
 for tile in kinds(r,kind):
  var b=r.buildings[tile]
  towers.append({"tile":tile,"level":b.level,"branch":b.get("specialization",""),"invested_gold":b.invested_gold,"invested_power":b.invested_power})
 exported[kind]={"profile":dest,"completed":m.endless.completed,"seconds":snappedf(m.time,.1),"reached":reach,"level10_impact_damage":snappedf(impact,.1),"income":snappedf(r.income_total,.1),"spent":snappedf(r.spent,.1),"gold":snappedf(r.gold,.1),"power":snappedf(r.electricity,.1),"towers":towers}
 print("ENDLESS_BALANCE_EARNED ",JSON.stringify(exported[kind]))
func simulate(cfg):
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
   if reaches.has("10"):save_earned(p,m,kind,reaches["10"],tier10_damage)
   if not p.checkpoint_endless(m):invalid.append("genuine_intermission_checkpoint_failed");break
   if cfg.get("save_advanced",false) and m.endless.completed==20:
    var advanced=FileAccess.open("res://docs/evidence/replay/balance-earned-advanced-profile.json",FileAccess.WRITE)
    if advanced:advanced.store_string(FileAccess.get_file_as_string(p.path));advanced.close()
    else:invalid.append("advanced_export_failed")
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
  if previous.distance_to(m.hunter.position)>m.hunter.speed*DT+.2:invalid.append("hunter_displacement");break
  for e in m.presentation_events:
   if e.id<=event_id:continue
   event_id=maxi(event_id,e.id);events[e.type]=int(events.get(e.type,0))+1;wave_events[e.type]=int(wave_events.get(e.type,0))+1
   if e.type=="door_damage" and e.room==m.player_room:wave_player_hits+=1;wave_received+=e.damage
   if e.type=="boss_impact":wave_boss_attacks[e.attack]=int(wave_boss_attacks.get(e.attack,0))+1
   elif e.type=="boss_surge":wave_boss_attacks.surge=int(wave_boss_attacks.get("surge",0))+1
  for e in m.combat_events:
   if e.id<=combat_id:continue
   combat_id=maxi(combat_id,e.id)
   if e.type=="impact" and e.room==m.player_room and e.kind==kind and e.level==10:tier10_damage+=e.damage
  if m.player()!=null:
   var r=m.player();minimum_hp=minf(minimum_hp,r.door_hp)
   if absf(r.gold+r.spent-account.refunds-25-r.income_total)>.1:invalid.append("unearned_gold_or_ledger_drift");break
   if not is_finite(r.gold) or not is_finite(r.electricity) or r.gold<-.001 or r.electricity<-.001:invalid.append("wallet");break
   for tile in kinds(r,kind):
    var b=r.buildings[tile]
    for level in [5,10]:
     if b.level>=level and not reaches.has(str(level)):reaches[str(level)]={"wave":m.endless.wave,"time":snappedf(m.time,.1),"income":snappedf(r.income_total,.1),"spent":snappedf(r.spent,.1),"refunds":snappedf(account.refunds,.1),"gold":snappedf(r.gold,.1),"power":snappedf(r.electricity,.1),"tile":tile,"invested_gold":b.invested_gold,"invested_power":b.invested_power}
  for stock in p.inventory.values():
   if stock<0:invalid.append("negative_stock")
  if m.items.legendary_used>1:invalid.append("legendary_limit")
  max_projectiles=maxi(max_projectiles,m.projectiles.size());max_events=maxi(max_events,m.combat_events.size());max_present=maxi(max_present,m.presentation_events.size())
  if m.time-wave_start>900:stop="wave_timeout";break
  steps+=1
 if m.result=="defeat":
  stop="defeat"
  if p.settle_endless(m).is_empty():invalid.append("defeat_settlement")
 elif m.endless.completed>=cfg.waves:stop="bounded_target_reached"
 elif steps>=300000:stop="time_budget"
 if not invalid.is_empty():failures+=1
 var r=m.player();var final_buildings=r.buildings.duplicate(true) if r!=null else {}
 for b in final_buildings.values():b.erase("cooldown");b.erase("flash")
 var final_wave={"wave":m.endless.wave,"hunter_hp":m.hunter.hp,"hunter_attacks":m.hunter.attacks,"min_door_hp":minimum_hp,"door_hp":r.door_hp if r!=null else 0,"observed_player_hits":wave_player_hits,"observed_player_damage_received":wave_received,"manual_repairs":r.repair_actions-wave_repairs_start if r!=null else 0,"boss_attacks":wave_boss_attacks,"events":wave_events}
 var row={"config":cfg,"completed":m.endless.completed,"active_wave":m.endless.wave,"stop":stop,"seconds":snappedf(m.time,.1),"sleep_at":snappedf(sleep_at,.1),"passive_since":passive_since,"reaches":reaches,"tier10_impact_damage":snappedf(tier10_damage,.1),"waves":waves,"final_wave":final_wave,"income":snappedf(r.income_total,.1) if r!=null else 0,"spent":snappedf(r.spent,.1) if r!=null else 0,"refunds":account.refunds,"gold":snappedf(r.gold,.1) if r!=null else 0,"power":snappedf(r.electricity,.1) if r!=null else 0,"uses":uses,"legendary_used":m.items.legendary_used,"remaining_stock":p.inventory,"perks":p.equipped,"events":events,"buildings":final_buildings,"peak_projectiles":max_projectiles,"peak_combat_events":max_events,"peak_presentation_events":max_present,"checkpoint_bytes":FileAccess.get_file_as_bytes(p.path).size(),"invalid":invalid}
 print("ENDLESS_BALANCE_RUN ",JSON.stringify(row))
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(p.path+suffix):DirAccess.remove_absolute(p.path+suffix)
 return row
func run():
 var args=OS.get_cmdline_user_args();var rows=[]
 export_enabled="--export-earned" in args or "--pilot" in args or "--earned-only" in args
 if "--pity" in args:
  pity_audit()
  return
 if "--damage-bound" in args or "--check" in args:
  damage_bounds()
  return
 if "--max-layout" in args:
  rows.append(simulate({"map":"cursed_mansion","mode":"standard","trait_id":"fortified","branch":"focus","seed":11,"policy":"optimized","waves":130,"passive_from":20,"layout":"fortress","wait_for_full":true,"save_advanced":true}))
 elif "--earned-only" in args:
  for branch in ["suppression","storm"]:rows.append(simulate({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":branch,"seed":11,"policy":"optimized","waves":6}))
 elif "--pilot" in args:
  for branch in ["suppression","storm"]:rows.append(simulate({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":branch,"seed":11,"policy":"optimized","waves":70,"passive_from":20}))
 elif "--advanced" in args:
  for passive in [20,1000000]:rows.append(simulate({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":"storm","seed":11,"policy":"optimized","waves":75,"passive_from":passive}))
  rows.append(simulate({"map":"abandoned_dorm","mode":"standard","trait_id":"economy","branch":"storm","seed":11,"policy":"optimized","waves":75,"passive_from":20}))
  for passive in [20,1000000]:rows.append(simulate({"map":"cursed_mansion","mode":"standard","trait_id":"fortified","branch":"focus","seed":11,"policy":"optimized","waves":130,"passive_from":passive,"layout":"fortress"}))
  for layout in ["fortress","guns"]:
   for passive in [20,1000000]:rows.append(simulate({"map":"cursed_mansion","mode":"standard","trait_id":"power","branch":"storm","seed":11,"policy":"optimized","waves":130 if layout=="fortress" else 75,"passive_from":passive,"layout":layout}))
  rows.append(simulate({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":"suppression","seed":11,"policy":"optimized","waves":75,"passive_from":20}))
  for mode in ["hard","hell"]:
   rows.append(simulate({"map":"cursed_mansion","mode":mode,"trait_id":"power","branch":"storm","seed":47,"policy":"optimized","waves":75,"layout":"fortress","budget":"mythic_control"}))
 else:
  for policy in ["typical","optimized"]:
   for i in range(12):
    rows.append(simulate({"map":MapCatalog.IDS[i%5],"mode":["standard","hard","hell"][i%3],"trait_id":StrategyCatalog.TRAIT_IDS[(i/3)%3],"branch":["precision","suppression","focus","storm"][i%4],"seed":11+i%3,"policy":policy,"waves":12}))
 var output="balance-max-layout-results.json" if "--max-layout" in args else "balance-earned-results.json" if "--earned-only" in args else "balance-pilot-results.json" if "--pilot" in args else "balance-advanced-results.json" if "--advanced" in args else "balance-results.json"
 var out={"scope":"Actual earned income, walking/claim/sleep, paid upgrades, repair-only intermission; seeded progressed Master/Mythic profile and finite existing stock, not human rates.","runs":rows,"failures":failures,"earned_profiles":exported}
 var file=FileAccess.open("res://docs/evidence/replay/"+output,FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(out," "))
 print("ENDLESS_BALANCE_RUNS=",rows.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
func candidate_roll(rng,state,epic_limit,legendary_limit):
 var table=ItemCatalog.TABLES.victory.duplicate();var total=0
 for i in range(table.size()):
  var rarity=ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity
  if state.legendary_dry>=legendary_limit-1 and rarity!="Legendary":table[i]=0
  elif state.legendary_dry<legendary_limit-1 and state.epic_dry>=epic_limit-1 and rarity not in ["Epic","Legendary"]:table[i]=0
  total+=table[i]
 var value=rng.randi_range(1,total);var id=ItemCatalog.IDS[0]
 for i in range(table.size()):
  value-=table[i]
  if value<=0:id=ItemCatalog.IDS[i];break
 var rarity=ItemCatalog.ITEMS[id].rarity
 state.epic_dry=0 if rarity in ["Epic","Legendary"] else state.epic_dry+1
 state.legendary_dry=0 if rarity=="Legendary" else state.legendary_dry+1
 return id
func gap_stats(values):
 values.sort()
 var sum=0.0
 for value in values:sum+=value
 return {"samples":values.size(),"mean":snappedf(sum/maxi(1,values.size()),.001),"p50":values[int((values.size()-1)*.5)],"p95":values[int((values.size()-1)*.95)],"p99":values[int((values.size()-1)*.99)],"max":values[-1]}
func pity_audit():
 var rows=[];var sample=100000
 for config in [{"name":"base_victory","epic":1000000,"legendary":1000000},{"name":"candidate_6_30","epic":6,"legendary":30},{"name":"production_8_40","epic":SpinPity.EPIC_LIMIT,"legendary":SpinPity.LEGENDARY_LIMIT},{"name":"candidate_10_50","epic":10,"legendary":50},{"name":"base_consolation","epic":0,"legendary":0}]:
  var rng=RandomNumberGenerator.new();rng.seed=7331
  var counts={"Common":0,"Rare":0,"Epic":0,"Legendary":0};var state={"epic_dry":0,"legendary_dry":0}
  var epic_gaps=[];var legendary_gaps=[];var epic_gap=0;var legendary_gap=0;var boundary_epic=0;var boundary_legend=0
  for i in range(sample):
   var id=""
   if config.name=="base_consolation":id=SpinPity.roll("defeat",rng,state)
   elif config.name=="production_8_40":
    boundary_epic+=int(state.epic_dry==SpinPity.EPIC_LIMIT-1);boundary_legend+=int(state.legendary_dry==SpinPity.LEGENDARY_LIMIT-1)
    id=SpinPity.roll("victory",rng,state)
   else:id=candidate_roll(rng,state,config.epic,config.legendary)
   var rarity=ItemCatalog.ITEMS[id].rarity;counts[rarity]+=1;epic_gap+=1;legendary_gap+=1
   if rarity in ["Epic","Legendary"]:epic_gaps.append(epic_gap);epic_gap=0
   if rarity=="Legendary":legendary_gaps.append(legendary_gap);legendary_gap=0
  var rates={}
  for rarity in counts:rates[rarity]=snappedf(100.0*counts[rarity]/sample,.001)
  var row={"config":config,"seed":7331,"draws":sample,"counts":counts,"observed_percent":rates,"epic_plus_gap":gap_stats(epic_gaps),"legendary_gap":gap_stats(legendary_gaps),"epic_boundary_draws":boundary_epic,"legendary_boundary_draws":boundary_legend}
  if config.name=="production_8_40" and (row.epic_plus_gap.max>8 or row.legendary_gap.max>40):failures+=1
  rows.append(row);print("PITY_BALANCE ",JSON.stringify(row))
 var prod=rows[2];var loss=rows[4]
 var comparison={"assumed_victory_seconds":180,"fastest_eligible_consolation_seconds":60,"quick_losses_below60_have_spins":0,"victory_mean_seconds_per_legendary_drop":snappedf(prod.legendary_gap.mean*180,.1),"consolation_mean_seconds_per_legendary_drop":snappedf(loss.legendary_gap.mean*60,.1),"victory_item_units_per_drop":4,"consolation_item_units_per_drop":1,"caveat":"Wall-clock comparison is a declared pacing assumption, not measured human speed; eligible Consolation also needs100 damage dealt or taken. Quick ineligible losses do not roll or progress Victory pity."}
 var out={"rows":rows,"comparison":comparison,"conditional_odds":{"base_victory":SpinPity.odds("victory",{"epic_dry":0,"legendary_dry":0}),"epic_boundary":SpinPity.odds("victory",{"epic_dry":7,"legendary_dry":0}),"legendary_boundary":SpinPity.odds("victory",{"epic_dry":0,"legendary_dry":39}),"consolation":SpinPity.odds("defeat",{"epic_dry":7,"legendary_dry":39})},"failures":failures,"scope":"Seeded actual registered item tables; production path uses SpinPity.roll. Alternative thresholds use same table filtering/renormalization; no paid gambling."}
 var file=FileAccess.open("res://docs/evidence/replay/pity-balance-results.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(out," "))
 print("PITY_BALANCE_DRAWS=",sample*rows.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
func damage_bounds():
 # Explicitly CONTROLLED high-wave compositions, not natural reachability.
 var rows=[]
 for boss in [false,true]:
  serial+=1
  var p=PlayerProfile.new(prefix+"damage-"+str(serial)+".json")
  p.inventory={"cursed_fortune":1};p.item_loadout=["cursed_fortune"]
  var seed_number=2 if boss else 3
  var entry=p.begin_endless("cursed_mansion","hell",seed_number)
  var m=MatchModel.new();m.configure_endless("cursed_mansion","hell",seed_number,entry.id,RankCatalog.bonuses([]))
  m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();p.bind_items(m,entry.id)
  var r=m.player();r.gold=100000;r.electricity=100000
  for i in range(4):m.upgrade_bed();m.upgrade_door()
  m.bot_claimed=5;m.endless.wave=125 if boss else 124;m.endless._prepare_hunter(m,false)
  m.time=m.preparation+120;m.hunter.position=r.door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
  if not boss:m.hunter.encounter_attacks=2
  var full_hp=r.door_hp
  if not p.activate_item(0,m,entry.id):failures+=1;push_error("Controlled Curse could not activate")
  var warnings=[];var last_event=0;var raw=0.0
  for step in range(150):
   m.tick(.05)
   for e in m.presentation_events:
    if e.id<=last_event:continue
    last_event=maxi(last_event,e.id)
    if e.type in ["archetype_warning","charged_attack","boss_warning"]:warnings.append(e.duplicate(true))
    if e.type=="door_damage" and e.room==0:raw=e.damage
   if raw>0:break
  var expected=(22.0+18.0)*1.5*9.0*(1.07 if boss else 1.2)*1.25*(1.6 if boss else 1.9)
  if not is_equal_approx(raw,expected) or raw>=full_hp or m.items.legendary_used!=1:failures+=1;push_error("Controlled actual damage composition/bound changed")
  var row={"scope":"CONTROLLED wave/time/position/wallet fixture; actual Hell+Crusher+Curse+growth1 charged/SoulSiege path; not natural reachability","wave":m.endless.wave,"reaper":m.hunter.transformed,"attack":"Soul Siege" if boss else "Charged Crusher","base_damage":m.hunter.damage,"observed_hit":raw,"expected_from_registered_factors":expected,"full_power_door_hp":full_hp,"door_remaining":r.door_hp,"warnings":warnings,"stock_remaining":p.inventory,"legendary_used":m.items.legendary_used,"growth":m.hunter.applied_growth,"level":m.hunter.level,"scaling":m.endless.scaling()}
  rows.append(row);print("ENDLESS_BALANCE_DAMAGE_BOUND ",JSON.stringify(row))
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(p.path+suffix):DirAccess.remove_absolute(p.path+suffix)
 var file=FileAccess.open("res://docs/evidence/replay/balance-damage-bound-results.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify({"rows":rows,"failures":failures}," "))
 print("ENDLESS_BALANCE_DAMAGE_FIXTURES=2 FAILURES=",failures)
 quit(0 if failures==0 else 1)
