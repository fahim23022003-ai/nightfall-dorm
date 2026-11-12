extends SceneTree
# Independent boundary/integration QA. Declared state fixtures isolate attribution;
# they are not earned-economy or difficulty-balance evidence.
var checks=0
var failures=0
var cases=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("5D4 EVOLUTION QA: "+label)
func fixture(seed_value=31,map_id="abandoned_dorm"):
 var m=MatchModel.new();m.reset(seed_value);m.configure_stage("stage_3");m.configure_map(map_id);m.configure_match("hell");m.configure_strategy(seed_value,"crusher","")
 m.preparation=0;m.time=20;m.bot_claimed=5;m.player_room=0
 for r in m.rooms:
  r.owner=r.index;r.profile="player" if r.index==0 else Catalog.BOT_PROFILES[r.index-1];r.sleeping=true;r.closed=true;r.resident_position=r.bed_position();r.door_hp=r.max_hp();r.gold=100;r.electricity=50
 m.player_position=m.player().bed_position()
 m.hunter.state=HunterState.State.MOVE;m.hunter.target=1;m.hunter.position=m.rooms[1].door_approach();m.hunter.tick(0,m)
 return m
func event_count(m,type):return m.presentation_events.filter(func(ev):return ev.type==type).size()
func kill(m,index,id=1):
 var actor=m.target_by_id(id)
 if actor==null:return false
 var r=m.rooms[index];r.door_hp=0;actor.position=r.bed_position();actor.target=index
 if id==1:actor.state=HunterState.State.BREACH
 return m.eliminate_resident(index,id)
func attribution():
 for map_id in MapCatalog.IDS:
  var m=fixture(31,map_id);var r=m.rooms[1];var h=m.hunter
  var initial_rng=m.random.state
  m.record_event("elimination",1,{"attacker_id":1});m.record_event("survivor_attack",1,{"attacker_id":1})
  check(m.evolution.acquired.is_empty() and m.evolution.credited.is_empty(),"fake presentation events cannot award buff "+map_id)
  check(not m.eliminate_resident(1,9999) and r.alive,"unregistered attacker cannot kill "+map_id)
  h.position=r.bed_position()
  check(not m.eliminate_resident(1,1) and r.alive,"intact closed door prevents direct resident kill "+map_id)
  var separate=fixture(31,map_id);separate.hunter.position=separate.rooms[1].bed_position()
  check(not separate.eliminate_resident(1,1,true) and separate.rooms[1].alive,"exposed flag cannot bypass NPC intact door "+map_id)
  r.door_hp=0;h.position=r.door_approach()
  check(not m.eliminate_resident(1,1) and r.alive,"breach alone does not remotely kill resident "+map_id)
  check(m.random.state==initial_rng,"failed kills and fake events consume no choice RNG "+map_id)
  check(kill(m,1),"genuine main contact kills living victim "+map_id)
  check(not r.alive and m.evolution.acquired.size()==1 and m.evolution.credited=={"owner:1":1},"genuine kill records one canonical victim and buff "+map_id)
  var after=m.evolution.snapshot();var rng=m.random.state
  check(not m.eliminate_resident(1,1) and m.evolution.snapshot()==after and m.random.state==rng,"repeat same kill is fully atomic "+map_id)
  m.spawn_undead(2)
  check(m.minions.size()==2,"real registered minions spawned "+map_id)
  if m.minions.size()==2:
   var a=m.minions[0];var b=m.minions[1];r=m.rooms[2];r.door_hp=0;a.position=r.bed_position();b.position=r.bed_position();a.target=2;b.target=2
   check(m.eliminate_resident(2,a.id) and not m.eliminate_resident(2,b.id),"two actual minions competing for one living victim get one kill "+map_id)
   check(m.evolution.acquired.size()==2 and m.evolution.credited.size()==2 and m.evolution.credited.has("owner:2"),"minion attribution shares global unique ledger "+map_id)
  for i in [3,4,5,0]:check(kill(m,i),"remaining genuine identity earns at most one buff "+map_id)
  check(m.evolution.acquired.size()==6 and m.evolution.credited.size()==6,"six actual survivors cap awards even though fifteen choices exist "+map_id)
  var unique={}
  for id in m.evolution.acquired:unique[id]=true
  check(unique.size()==6 and event_count(m,"hunter_evolved")==6,"each awarded buff unique with one real notification "+map_id)
  var saved=JSON.parse_string(JSON.stringify(m.evolution.snapshot()))
  var rooms=[]
  for room in m.rooms:rooms.append({"owner":room.owner,"alive":room.alive})
  check(HunterEvolution.valid(saved,rooms),"JSON canonical ledger validates against actual dead identities "+map_id)
  for corruption in ["numeric_key","duplicate_buff","live_victim","unknown_buff","wrong_owner"]:
   var bad=saved.duplicate(true);var rs=rooms.duplicate(true)
   match corruption:
    "numeric_key":bad.credited["1"]=bad.credited["owner:1"];bad.credited.erase("owner:1")
    "duplicate_buff":bad.acquired[1]=bad.acquired[0]
    "live_victim":rs[1].alive=true
    "unknown_buff":bad.acquired[0]="unimplemented"
    "wrong_owner":rs[1].owner=5
   check(not HunterEvolution.valid(bad,rs),"tampered ledger rejected "+corruption+map_id)
  cases.append({"map":map_id,"buffs":m.evolution.acquired.duplicate(),"credit":m.evolution.credited.duplicate()})
  m.reset(31);check(m.evolution.acquired.is_empty() and m.evolution.credited.is_empty() and m.minions.is_empty(),"new match resets evolution and minions "+map_id)
func exposed_terminal():
 var m=fixture();var r=m.player();r.sleeping=false;r.closed=false;m.time=m.preparation+26;m.hunter.position=m.player_position;m.hunter.speed=0
 m.tick(.001)
 check(m.result=="defeat" and not r.alive,"genuine exposed player contact ends game")
 check(m.evolution.credited.has("owner:0") and m.evolution.acquired.size()==1 and event_count(m,"hunter_evolved")==1,"terminal player death earns buff before cleanup")
func seeded_pool():
 var seen={}
 for seed_value in range(45):
  var a=fixture(seed_value);var b=fixture(seed_value)
  for index in [1,2,3,4,5]:
   kill(a,index);kill(b,index)
  check(a.evolution.acquired==b.evolution.acquired and a.random.state==b.random.state,"same actual seeded kill sequence reproduces choices")
  for id in a.evolution.acquired:seen[id]=true
 check(seen.size()==15 and HunterEvolution.BUFFS.size()==15,"all fifteen distinct eligible choices reachable through genuine kills")
func actor_identity():
 var m=fixture();m.spawn_undead(100);check(m.minions.size()==10,"live undead hard cap ten")
 var ids={}
 for u in m.minions:
  check(u.id>=2 and not ids.has(u.id) and m.target_by_id(u.id)==u,"registered actual undead has unique stable identity")
  ids[u.id]=true
 var old=m.minions[0];var old_id=old.id;var boss_hp=m.hunter.hp;var other_hp=m.minions[1].hp
 var actual=m.apply_target_damage(old_id,17,0)
 check(is_equal_approx(actual,17) and old.hp==old.max_hp-17 and m.hunter.hp==boss_hp and m.minions[1].hp==other_hp,"actual damage is routed only to selected undead")
 old.despawn(m);m.spawn_undead(1)
 var replacement=m.minions.back();var replacement_hp=replacement.hp
 check(replacement.id>old_id and replacement.slot==old.slot,"reused bounded slot gets fresh monotonic identity")
 check(m.target_by_id(old_id)==null and m.apply_target_damage(old_id,500,0)==0 and replacement.hp==replacement_hp and m.hunter.hp==boss_hp,"stale target identity never damages replacement or boss")
 var max_routes=0;var last_id=replacement.id
 for cycle in range(40):
  for u in m.minions:
   u.tick(.1,m)
   check(m.navigation_walkable(u.position),"summoned actor follows valid actual navigation")
  max_routes=maxi(max_routes,m._navigation_routes.size())
  m.clear_minions();m.spawn_undead(10,cycle%2==0)
  check(m.minions.size()==10 and m.minions[0].id>last_id,"repeated summons preserve hard cap and never reuse identities")
  last_id=m.minions[0].id
 check(max_routes<=12,"forty summon cycles have bounded slot route cache")
 m.clear_minions()
 for key in m._navigation_routes:check(not str(key).begins_with("undead_slot"),"cleared actor routes cannot accumulate")
func buff_mechanics():
 var m=fixture();var h=m.hunter;var e=m.evolution;var r=m.rooms[1]
 e.acquired=["blood_frenzy"];check(is_equal_approx(e.interval_factor(h),.9),"Blood Frenzy actual attack interval factor")
 e.acquired=["iron_skin"];var hp=h.hp;m.apply_target_damage(1,100,0);check(is_equal_approx(hp-h.hp,90),"Iron Skin actual hit mitigation")
 e.acquired=["predator_rush"];check(is_equal_approx(e.move_factor(h),1.12),"Predator Rush actual movement factor")
 e.acquired=["door_crusher"];hp=r.door_hp;m.apply_room_damage(1,20,"QA genuine strike",1);check(is_equal_approx(hp-r.door_hp,23),"Door Crusher actual door damage")
 e.acquired=["rapid_recovery"];m.wrath.cooldowns.summon=20;m.wrath.recovery=100;m.wrath.tick(1,m);check(is_equal_approx(m.wrath.cooldowns.summon,20-1/.88),"Rapid Recovery actual selected ability cooldown")
 e.acquired=["shadow_step"];h.state=HunterState.State.MOVE;e.tick(.1,m);check(h.conceal_remaining>=1.5 and e.shadow_cooldown==12,"Shadow Step actually conceals approach with finite cooldown")
 e.acquired=["ruthless_pursuit"];h.target_time=8;check(is_equal_approx(e.move_factor(h),1.1),"Ruthless Pursuit sustained pursuit benefit");h.target_time=0;check(e.move_factor(h)==1,"Ruthless Pursuit no instant free speed")
 e.acquired=["savage_strike"];hp=r.door_hp;m.apply_room_damage(1,20,"QA special",1,true);check(is_equal_approx(hp-r.door_hp,22.4),"Savage Strike only actual telegraphed-special damage multiplier")
 e.acquired=["dread_aura"];h.target=1;h.state=HunterState.State.ATTACK;e.tick(.1,m);check(r.threat_income_factor==.88 and r.threat_power_factor==.88 and m.player().threat_income_factor==1,"Dread Aura affects besieged room and no unrelated room")
 e.acquired=["undead_commander"];m.spawn_undead(1);check(is_equal_approx(m.minions[0].max_hp,138) and is_equal_approx(m.minions[0].damage,12.65),"Undead Commander actual HP and damage");m.clear_minions()
 e.acquired=["soul_drain"];r.gold=3.25;r.electricity=.75;e.tick(20,m);check(r.gold==0 and r.electricity==0 and event_count(m,"soul_drain")==1,"Soul Drain actual bounded nonnegative wallet drain")
 e.acquired=["relentless_siege"];h.siege_seconds=8;check(is_equal_approx(e.interval_factor(h),.92),"Relentless Siege actual sustained contact factor")
 for id in ["soul_hunger","cursed_armor","deaths_momentum"]:
  m=fixture(77);h=m.hunter;e=m.evolution;e.acquired=[id];h.hp=h.max_hp*.5
  hp=h.hp;kill(m,1)
  if id=="soul_hunger":check(h.hp>=hp+h.max_hp*.04-.001 and h.hp<=h.max_hp,"Soul Hunger genuine kill heals bounded actual HP")
  if id=="cursed_armor":
   check(e.shield>0 and e.shield_remaining==8,"Cursed Armor genuine kill creates finite shield")
   var shield=e.shield;hp=h.hp;m.apply_target_damage(1,shield*.5,0);check(h.hp==hp and e.shield<shield,"Cursed Armor shield absorbs real damage")
   e.tick(8.1,m);check(e.shield==0 and e.shield_remaining==0,"Cursed Armor expires cleanly")
  if id=="deaths_momentum":
   check(e.momentum==8 and e.move_factor(h)>=1.15 and e.interval_factor(h)<=.9,"Death Momentum genuine kill grants temporary offensive speed")
   e.tick(8.1,m);check(e.momentum==0,"Death Momentum cannot persist after duration")
func run():
 attribution();exposed_terminal();seeded_pool();actor_identity();buff_mechanics()
 var f=FileAccess.open("res://docs/evidence/phase5d4/qa-evolution-cases.json",FileAccess.WRITE);f.store_string(JSON.stringify(cases," "));f.close()
 print("PHASE5D4_QA_EVOLUTION_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
