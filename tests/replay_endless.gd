extends SceneTree
# Prepared budgets/HP exercise transitions and accounting, not natural L10 balance.
const Support=preload("res://tests/replay_test_support.gd")
const Snapshot=preload("res://scripts/replay_snapshot.gd")
var checks=0
var failures=0
var serial=0
var prefix="user://replay-endless-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY ENDLESS: "+label)
func fixture(map="abandoned_dorm",mode="standard",seed_value=71,items=[],perks=null,bind_before_claim=false):
 serial+=1
 var p=Support.profile(prefix+str(serial)+".json");p.pending_spins=[];p.item_loadout=items.duplicate()
 if perks!=null:p.equipped=perks.duplicate()
 var entry=p.begin_endless(map,mode,seed_value)
 check(not entry.is_empty(),"profile starts genuine unique Endless identity")
 var m=MatchModel.new()
 check(m.configure_endless(map,mode,seed_value,entry.run_id,RankCatalog.bonuses(entry.equipped)),"model binds declared map/mode/seed/run")
 if bind_before_claim:p.bind_items(m,entry.id)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 for i in range(1,6):
  var r=m.rooms[i];r.owner=i;r.profile=Catalog.BOT_PROFILES[i-1];r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 m.bot_claimed=5;m.time=m.preparation+.1
 var r=m.player();r.gold=10000;r.electricity=10000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
 if not bind_before_claim:p.bind_items(m,entry.id)
 return {"p":p,"m":m,"id":entry.id,"entry":entry}
func clear_wave(a,hp=1.0):
 var m=a.m;var r=m.player();var h=m.hunter
 if not r.buildings.values().any(func(b):return b.kind=="turret"):
  check(m.buy("turret",Support.nearest_pad(r,r.door_approach())),"wave fixture pays real in-range weapon")
 h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=100;h.hp=hp
 for i in range(400):
  m.tick(.1)
  if m.endless.phase=="intermission" or m.result!="":break
 check(m.result=="" and m.endless.phase=="intermission" and h.hp==0,"actual projectile/DoT terminal becomes intermission, not campaign victory")
 check(m.hunter==h and m.endless.completed==m.endless.wave and m.endless.sealed_wave==m.endless.completed,"one defeated Hunter seals one actual wave")
func transitions():
 var a=fixture("abandoned_dorm","standard",71,["inferno","frost"]);var m=a.m;var p=a.p
 check(m.buy("turret",Support.nearest_pad(m.player(),m.player().door_approach())),"Inferno fixture first pays required real turret")
 m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach()
 check(p.activate_item(0,m,a.id),"real paid Inferno activates")
 m.items.tick(1.01,m)
 check(p.activate_item(1,m,a.id),"real paid Frost activates")
 clear_wave(a,15)
 var before=Support.model_signature(m);var inventory=p.inventory.duplicate(true)
 for i in range(30):m.tick(60)
 check(Support.model_signature(m)==before and p.inventory==inventory,"intermission freezes time/resources/RNG/projectiles/item clocks, no passive farming")
 var saved=Snapshot.encode(m,p.active_match.use_counts)
 check(not saved.is_empty() and Snapshot.valid(saved),"actual intermission with paid effects/ledgers encodes")
 var serialized=JSON.parse_string(JSON.stringify(saved))
 var restored=Snapshot.restore(serialized)
 check(restored!=null and restored.random.state==m.random.state,"snapshot preserves exact64bit RNG through JSON")
 if restored!=null:
  check(Support.numeric_same(Snapshot.encode(restored,saved.use_counts),serialized) and absf(restored.player().gold-m.player().gold)<.000001 and absf(restored.player().electricity-m.player().electricity)<.000001,"restore retains every serialized field/paid ledger/resources, excluding transient flash")
 var gold=m.player().gold;var old_hunter=m.hunter
 check(not m.continue_wave("invalid") and m.endless.phase=="intermission" and m.player().gold==gold,"invalid strategic choice cannot grant or advance")
 m.running=false;check(not m.continue_wave("supply"),"paused transition rejected");m.running=true
 check(m.continue_wave("supply") and m.player().gold==gold+25 and m.endless.wave==2,"one explicit strategic benefit advances one wave")
 check(not m.continue_wave("supply") and m.player().gold==gold+25,"duplicate click cannot grant/advance again")
 check(m.hunter!=old_hunter and m.hunter.hp==m.hunter.max_hp and old_hunter.hp==0,"one intentional fresh Hunter replaces defeated identity")
 check(m.items.burn_remaining==0 and not m.items.timers.has("frost") and not m.items.timers.has("time_freeze") and not m.items.timers.has("decoy"),"dead-target burn/control cannot transfer to fresh Hunter")
 check(p.inventory==inventory,"wave transition cannot restore spent permanent inventory")
 var hp=m.hunter.hp;var door=m.player().door_hp
 m.tick(.1)
 check(m.hunter.hp==hp and m.player().door_hp==door and m.hunter_active_seconds()==0,"fresh-wave preparation has no stale burn or instant door strike")
func invalid_snapshots():
 var a=fixture();clear_wave(a)
 var good=Snapshot.encode(a.m)
 check(not good.is_empty(),"strict snapshot baseline comes from actual cleared wave")
 var edits=[[["version"],2],[["ruleset"],2],[["map"],"future_map"],[["difficulty"],"nightmare"],[["run_id"],0],[["completed"],1.5],[["player_room"],6],[["player_position"],[9999,9999]],[["rng"],"99999999999999999999"],[["rng"],"-9223372036854775809"],[["rng"],"+1"],[["rng"],"01"],[["rng"],"-0"],[["rng"],1],[["bot_claimed"],0],[["shots"],.5],[["rooms",0,"gold"],-1],[["rooms",0,"electricity"],INF],[["rooms",0,"door_hp"],1e9],[["rooms",0,"bed_level"],5],[["rooms",0,"door_level"],5],[["rooms",0,"closed"],false],[["rooms",0,"shots"],.5],[["rooms",0,"repair_actions"],.5],[["rooms",0,"trait"],"power"],[["rooms",1,"owner"],0],[["rooms",1,"position"],[9999,9999]],[["rooms",0,"income_multiplier"],10],[["rooms",0,"door_multiplier"],10],[["rooms",0,"power_multiplier"],10],[["rooms",0,"turret_multiplier"],10],[["rooms",0,"rescue_fraction"],.99],[["rooms",1,"income_multiplier"],10],[["items","legendary_used"],2],[["items","timers"],{"unknown_effect":1}],[["use_counts"],{"coupon":-1}]]
 for edit in edits:
  var data=good.duplicate(true);var at=data;var path=edit[0]
  for i in range(path.size()-1):at=at[path[i]]
  at[path[-1]]=edit[1]
  check(not Snapshot.valid(data) and Snapshot.restore(data)==null,"malformed/incompatible snapshot rejected: "+str(path))
 var data=good.duplicate(true);data.rooms[0].buildings[0].level=11
 check(not Snapshot.valid(data),"snapshot cannot introduce level11")
 data=good.duplicate(true);data.rooms[0].buildings[0].invested_gold=1e9
 check(not Snapshot.valid(data),"snapshot rejects impossible paid ledger above eligible cost ceiling")
 data=good.duplicate(true);data.rooms[0].buildings.append(data.rooms[0].buildings[0].duplicate(true))
 check(not Snapshot.valid(data),"snapshot cannot duplicate a paid tile/refund")
func navigation_and_reaper():
 var approaches=0
 for map in MapCatalog.IDS:
  for mode in ["standard","hard","hell"]:
   for seed_value in [1,2,3]:
    var m=MatchModel.new();m.configure_endless(map,mode,seed_value,500+approaches)
    m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
    m.player().door_level=4;m.player().door_hp=m.player().max_hp();m.time=m.preparation+.1
    var h=m.hunter;var door=m.player().door_hp
    for step in range(1600):
     var previous=h.position;m.tick(.05)
     check(m.hunter==h and m.navigation_walkable(h.position),"one real Endless Hunter remains on authored floor")
     check(h.position.distance_to(previous)<=h.speed*.05+.001,"Endless movement has no teleport or late-growth burst")
     check(not m.player().bounds().grow(-12).has_point(h.position) and m.player().door_hp==door,"approach respects intact door without remote damage")
     if h.state==HunterState.State.ATTACK:break
    check(h.state==HunterState.State.ATTACK and h.position.distance_to(m.player().door_approach())<3,"actual Endless archetype reaches legal contact on all maps/modes")
    check(h.archetype==StrategyCatalog.ARCHETYPE_IDS[posmod(seed_value,3)],"reproducible wave1 archetype matches selected seed")
    approaches+=1
 for mode in ["standard","hard","hell"]:
  var a=fixture("underground_lab",mode,191);var m=a.m
  for wave in range(1,5):
   clear_wave(a)
   check(m.continue_wave("power"),"prepared actual early waves advance to Reaper milestone")
   m.time=m.preparation+.1
  var h=m.hunter;var hp=h.hp
  for i in range(120):
   m.tick(.05)
   if h.transformed and h.state!=HunterState.State.TRANSFORM:break
  check(h.transformed and h.state!=HunterState.State.TRANSFORM and h.hp<=hp,"wave5 real existing Reaper awakens once without accidental healing")
  check(m.presentation_events.filter(func(e):return e.type=="boss_transform").size()==1,"one transformation per fresh milestone encounter")
  h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=0
  var door=m.player().door_hp;var warned=false
  for i in range(160):
   m.tick(.05)
   if h.boss_attack!="":warned=true
   if m.player().door_hp<door:break
  check(warned and m.player().door_hp<door,"milestone Reaper preserves actual telegraphed damaging special")
 print("REPLAY_ENDLESS_APPROACHES=",approaches)
func extreme_pressure():
 for mode in ["standard","hard","hell"]:
  for seed_value in [1,2,3]:
   var a=fixture("abandoned_dorm",mode,seed_value);var m=a.m;var r=m.player()
   for wave in [1,20,21,100,1000000000000]:
    var scale=m.endless.scaling(wave)
    check(scale.hunter_hp<=100 and scale.hunter_damage<=9 and scale.hunter_speed<=1.25,"declared wave stats stay bounded at extreme finite wave")
   m.endless.wave=1000000000000;m.endless._prepare_hunter(m,true)
   m.time=1e12;var h=m.hunter;h.boss_policy.enabled=false
   h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=0
   h.encounter_attacks=maxi(0,int(RankCatalog.pressure(mode).charged_every)-1);h.archetype_primed=true
   m.items.curse_frame_fraction=1.0
   var door=r.door_hp;var warned=false
   for i in range(100):
    h.tick(.05,m)
    if h.windup_remaining>0:warned=true
    if h.attacks>0:break
   check(h.applied_growth<=1 and h.level<=2 and is_finite(h.max_hp) and h.max_hp<=800000 and is_finite(h.speed) and h.speed<=150,"huge finite active time cannot bypass within-wave HP/speed/growth bounds")
   check(is_finite(h.damage) and h.damage<=810.001 and h.interval>=.35,"curse composition preserves bounded actual attack stats")
   check(h.attacks==1 and door-r.door_hp>0 and door-r.door_hp<=1540,"real normal/charged strike under maximal finite pressure remains bounded")
   if mode!="standard":check(warned,"maximal charged hit retains real warning window")
   check(r.repair_factor>=RankCatalog.pressure(mode).repair_floor*.35-.000001,"late siege repair factor stays above declared composed floor")
   r.door_hp=r.max_hp();h.boss_policy={"enabled":true,"opening":0.0,"deadline":0.0,"hp_fraction":1.0,"recovery":1.1}
   h.tick(.01,m);h.tick(BossCatalog.TRANSFORM_SECONDS+.01,m)
   h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=0
   h.boss_cooldowns={"scythe":100.0,"siege":0.0,"surge":100.0};door=r.door_hp;warned=false
   for i in range(100):
    h.tick(.05,m)
    if h.boss_attack=="siege":warned=true
    if r.door_hp<door:break
   check(h.transformed and warned and h.last_boss_attack=="siege" and door-r.door_hp>0 and door-r.door_hp<=1540,"real Reaper warning/special stays bounded after maximal archetype/curse/wave composition")
   check(is_finite(h.max_hp) and is_finite(h.damage) and is_finite(h.speed) and r.door_hp>=0,"extreme encounter cannot produce NaN/infinity/negative HP")
func run():
 transitions();invalid_snapshots();extreme_pressure()
 if "--focused" not in OS.get_cmdline_user_args():navigation_and_reaper()
 Support.cleanup(prefix)
 print("REPLAY_ENDLESS_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
