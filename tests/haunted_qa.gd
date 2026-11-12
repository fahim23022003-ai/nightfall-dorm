extends SceneTree
# Independent direct fixtures; injected currencies here test accounting, not reachability.
var checks=0
var failures=0
var paths=[]
const FACTORS=[1,2,3,5,7,10,14,19,25]
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("HAUNTED QA: "+label)
func fixture(stage="stage_1",mode="standard"):
 var m=MatchModel.new();m.reset(17);m.configure_match(mode);m.configure_stage(stage)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.bot_claimed=5;m.time=m.preparation+60
 m.hunter.boss_policy.enabled=false
 return m
func actor(m,items):
 var path="user://haunted-qa-"+str(Time.get_ticks_usec())+".json";paths.append(path)
 var p=PlayerProfile.new(path)
 for id in items:p.inventory[id]=4
 p.item_loadout=items.duplicate()
 var entry=p.begin_match(m.difficulty);p.bind_items(m,entry.id)
 return {"p":p,"id":entry.id}
func room_snapshot(r):return [r.gold,r.electricity,r.buildings.duplicate(true),r.construction_actions,r.coupon_armed]
func count_event(m,type,index):
 var total=0
 for e in m.presentation_events:
  if e.type==type and e.room==index:total+=1
 return total
func transactions():
 for kind in Catalog.BUILDINGS:
  var cap=10 if kind in ["turret","heavy"] else 4
  check(Catalog.building_max_level(kind)==cap,"eligible cap "+kind)
  var m=fixture();var r=m.player();r.bed_level=4;r.door_level=4;r.gold=100000;r.electricity=100000
  var origin=Vector2(r.gold,r.electricity)
  check(r.build(kind,0),"valid purchase "+kind)
  for old_level in range(1,cap):
   var price=Catalog.upgrade_cost(kind,old_level)
   var expected=Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power+3)*FACTORS[old_level-1]
   check(price.is_equal_approx(expected),"documented upgrade price "+kind+str(old_level))
   var before=Vector2(r.gold,r.electricity)
   check(r.upgrade_building(0),"upgrade succeeds "+kind+str(old_level+1))
   check((before-Vector2(r.gold,r.electricity)).is_equal_approx(expected),"actual separate payment "+kind+str(old_level+1))
   check(r.buildings[0].level==old_level+1,"actuallevel "+kind)
   check(r.building_refund(0).is_equal_approx((origin-Vector2(r.gold,r.electricity))*.5),"actual cumulative refund "+kind+str(old_level))
  var snapshot=room_snapshot(r)
  check(not r.upgrade_building(0) and room_snapshot(r)==snapshot,"cap atomic "+kind)
  var invested=origin-Vector2(r.gold,r.electricity)
  var before=Vector2(r.gold,r.electricity)
  check(r.sell_building(0),"sell maxlevel "+kind)
  check((Vector2(r.gold,r.electricity)-before).is_equal_approx(invested*.5),"half invested both resources maxlevel "+kind)
  before=Vector2(r.gold,r.electricity)
  check(not r.sell_building(0) and Vector2(r.gold,r.electricity)==before,"no double refund "+kind)
  check(r.build(kind,0),"sold tile reusable "+kind)
 for kind in ["turret","heavy"]:
  var m=fixture();var r=m.player();r.bed_level=1;r.gold=100000;r.electricity=100000
  check(r.build(kind,0),"prerequisite fixture builds "+kind)
  for i in range(3):check(r.upgrade_building(0),"old levels preserved "+kind)
  var before=room_snapshot(r)
  check(not r.upgrade_building(0) and room_snapshot(r)==before,"advanced upgrade requires bed and door "+kind)
  r.bed_level=4;r.door_level=4
  for level in range(4,10):
   var cost=Catalog.upgrade_cost(kind,level);r.gold=cost.x;r.electricity=maxf(0,cost.y-1)
   before=room_snapshot(r)
   check(not r.upgrade_building(0) and room_snapshot(r)==before,"insufficient power atomic "+kind+str(level))
   r.gold=100000;r.electricity=100000;check(r.upgrade_building(0),"new upgrade restored "+kind)
  before=room_snapshot(r)
  check(not r.upgrade_building(-1) and not r.upgrade_building(1000) and room_snapshot(r)==before,"invalid upgrade indices atomic")
 # Coupon actual cost across every high-level upgrade; one persisted item per valid payment.
 for level in range(4,10):
  var m=fixture();var r=m.player();r.bed_level=4;r.door_level=4;r.gold=100000;r.electricity=100000
  var a=actor(m,["coupon"]);check(r.build("heavy",0),"coupon builds")
  while r.buildings[0].level<level:check(r.upgrade_building(0),"coupon reaches advanced level")
  var old=Vector2(r.gold,r.electricity);var price=Catalog.upgrade_cost("heavy",level)
  check(a.p.activate_item(0,m,a.id),"coupon arm free")
  check(a.p.inventory.coupon==4,"arm spends no stock")
  check(r.upgrade_building(0),"coupon advanced purchase")
  check((old-Vector2(r.gold,r.electricity)).is_equal_approx(price*.6),"discount exact both currencies")
  check(a.p.inventory.coupon==3 and not r.coupon_armed,"coupon consumed once")
  var refund=r.building_refund(0);old=Vector2(r.gold,r.electricity)
  check(r.sell_building(0) and (Vector2(r.gold,r.electricity)-old).is_equal_approx(refund),"discounted sale actual investment")
func combat():
 for mode in ["standard","hard","hell"]:
  for stage in StageCatalog.STAGES:
   var m=fixture(stage.id,mode);var h=m.hunter;var r=m.rooms[1]
   r.owner=1;r.sleeping=true;r.closed=true;r.door_hp=1;r.resident_position=r.bed_position()
   h.target=1;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0
   h.tick(.01,m)
   check(r.door_hp==0 and r.alive,"door breach does not immediately kill "+stage.id+mode)
   check(count_event(m,"door_break",1)==1,"one genuine break event")
   h._damage_door(r,m,100)
   check(count_event(m,"door_break",1)==1,"broken door cannot emit second breach")
   var steps=0
   while r.alive and steps<600:
    var previous=h.position;h.tick(.1,m)
    check(previous.distance_to(h.position)<=h.speed*.1+.1,"real breach navigation bounded")
    steps+=1
   check(not r.alive and not r.sleeping,"real Hunter reaches and eliminates teammate")
   check(h.position.distance_to(r.bed_position())<12,"elimination at legitimate survivor position")
   check(count_event(m,"elimination",1)==1,"one real elimination event")
   check(m.eliminations==1 and m.result=="" and m.player().alive,"teammate death not player defeat")
   var state=[r.gold,r.electricity,r.construction_actions,r.shots]
   m.tick(.25);m.tick(.25)
   check([r.gold,r.electricity,r.construction_actions,r.shots]==state,"eliminated bot no economy or upgrades or new shots")
   check(count_event(m,"elimination",1)==1,"no repeated elimination callback")
func turret_stats():
 for kind in ["turret","heavy"]:
  for level in [1,4,7,10]:
   for mode in ["standard","hard","hell"]:
    var m=fixture("stage_5",mode);var r=m.player();r.bed_level=4;r.door_level=4;r.gold=100000;r.electricity=100000
    r.turret_multiplier=1.03;m.match_boosts=RankCatalog.bonuses(["marksman","reaper_slayer"])
    m.stage_bonus={"damage":1.08,"seconds":60.0};m.time=m.preparation+1
    check(r.build(kind,0),"stat fixture purchase")
    while r.buildings[0].level<level:check(r.upgrade_building(0),"stat fixture upgrade")
    m.hunter.position=r.tile_position(0)+Vector2(0,50);m.hunter.state=HunterState.State.MOVE;m.hunter.transformed=true
    var hp=m.hunter.hp;m._turrets(.001)
    check(m.projectiles.size()==1,"actual owned shot launches L"+str(level))
    check(is_equal_approx(r.buildings[0].cooldown,Catalog.BUILDINGS[kind].interval/(1+.12*(level-1))-.001),"actual capped attack interval L"+str(level))
    m._advance_projectiles(1.0)
    var expected=Catalog.BUILDINGS[kind].damage*level*1.03*1.06*1.08
    check(is_equal_approx(hp-m.hunter.hp,expected),"actual Reaper/perk/stage impact L"+str(level)+mode)
    check(is_finite(expected) and expected>0 and m.hunter.hp>0,"powerful but finite noninstant victory")
 # Existing Legendary/Overdrive at maximum level; freeze stops Hunter but turrets still fire.
 for mode in ["standard","hard","hell"]:
  var m=fixture("stage_5",mode);var r=m.player();r.bed_level=4;r.door_level=4;r.gold=100000;r.electricity=100000
  r.build("turret",0)
  while r.buildings[0].level<10:r.upgrade_building(0)
  m.hunter.position=r.tile_position(0)+Vector2(0,50);m.hunter.state=HunterState.State.MOVE
  var a=actor(m,["overdrive","time_freeze"])
  check(a.p.activate_item(0,m,a.id),"L10 overdrive actualactivation")
  m.items.cooldown=0
  check(a.p.activate_item(1,m,a.id),"L10 freeze actualactivation")
  var hp=m.hunter.hp;m.tick(.25);m.tick(.25)
  check(m.hunter.hp<hp and r.shots>0,"L10 shoots during finite freeze")
  check(m.items.legendary_used==1 and a.p.inventory.time_freeze==3,"L10 preserves saved Legendary limit")
  m.items.cooldown=0
  check(not a.p.activate_item(1,m,a.id) and a.p.inventory.time_freeze==3,"L10 cannot repeat Legendary")
func environment():
 var themes={}
 for stage in StageCatalog.STAGES:
  var m=fixture(stage.id);var h=m.hunter
  var env=load("res://scripts/haunted_environment.gd").new();env.configure(m)
  check(env.creatures.size()==5 and env.anchors.size()>0,"five bounded creature types "+stage.id)
  themes[env.theme]=true
  var rng=m.random.state
  var before=[m.time,h.position,h.hp,h.target,m.player().gold,m.player().electricity,m.projectiles.duplicate(true),m.presentation_events.duplicate(true)]
  var seen={};var flashes=[];var thunder=[];var previous_flash=0.0
  var origins=[]
  for c in env.creatures:origins.append(c.position)
  for step in range(1400):
   env.update(.1,m,step%2==0)
   check(env.creatures.size()<=5 and env.weather_events.size()<=16,"bounded cosmetic collections")
   for c in env.creatures:
    check(env.is_exterior(c.position,m,26),"whole ambient footprint outside playable union")
    check(not m.navigation_walkable(c.position),"ambient not on survivor/Hunter navigation")
   if env.flash>previous_flash:flashes.append(env.clock)
   previous_flash=env.flash
   for e in env.weather_events:
    if seen.has(e.id):continue
    seen[e.id]=true
    if e.cue=="weather_thunder":thunder.append(e.time)
  var moved=false
  for i in range(env.creatures.size()):moved=moved or env.creatures[i].position!=origins[i]
  check(moved,"ambient animation and respawn positions change")
  check(m.random.state==rng and before==[m.time,h.position,h.hp,h.target,m.player().gold,m.player().electricity,m.projectiles.duplicate(true),m.presentation_events.duplicate(true)],"decoration cannot change model/RNG/economy/events")
  check(flashes.size()>=3 and thunder.size()>=2,"actual controlled lightning/thunder events")
  for i in range(1,flashes.size()):check(flashes[i]-flashes[i-1]>=23.9,"no rapid-strobe intervals")
  for t in thunder:
   var prior=-1.0
   for flash_time in flashes:
    if flash_time<=t:prior=flash_time
   check(prior>=0 and t-prior>=.59 and t-prior<=1.91,"thunder follows actual lightning after delay")
  var ghost=env.creatures[4];ghost.visible=true;ghost.age=3
  env.flash=0;check(env.creature_alpha(ghost)==0,"special apparition truly hidden before lightning")
  env.flash=.5;check(env.creature_alpha(ghost)>.5,"same apparition actually revealed by lightning")
  env.flash=0;check(env.creature_alpha(ghost)==0,"apparition disappears after flash")
  var clock=env.clock;m.running=false;env.update(100,m,true);check(env.clock==clock,"pause stops decorative timeline")
  m.running=true
  for bad in [-1.0,0.0,INF,NAN]:env.update(bad,m,false)
  check(env.clock==clock,"invalid delta cannot corrupt environment")
 check(themes.size()==5,"five distinct environment identities")
func audio_events():
 var audio=load("res://scripts/audio_director.gd").new();root.add_child(audio)
 var m=fixture();audio.reset_match(m);audio.update_state(.01,m,"match")
 for index in [1,2]:
  var r=m.rooms[index];r.owner=index;r.alive=true;r.sleeping=true;r.closed=true;r.door_hp=1;r.resident_position=r.bed_position()
 var h=m.hunter;h.target=1;h.position=m.rooms[1].door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0
 h._damage_door(m.rooms[1],m,100)
 audio.update_state(.1,m,"match");audio.update_state(.3,m,"match")
 check(int(audio.event_counts.get("hunter_laugh",0))==1,"normal real breach laughs once")
 m.record_event("door_break",1);audio.update_state(.5,m,"match")
 check(int(audio.event_counts.get("hunter_laugh",0))==1,"duplicate real broken-door callback no laugh spam")
 for index in [1,2]:
  var r=m.rooms[index]
  h.target=index;h.position=r.door_approach();h.state=HunterState.State.BREACH;r.door_hp=0
  var steps=0
  while r.alive and steps<600:h.tick(.1,m);steps+=1
  check(not r.alive,"audio scenario real elimination")
  audio.update_state(.1,m,"match")
 check(int(audio.event_counts.get("death_scream_1",0))+int(audio.event_counts.get("death_scream_2",0))==1,"batched genuine deaths serialize one active scream")
 m.record_event("elimination",1);m.record_event("elimination",2);m.record_event("elimination",3)
 audio.update_state(.1,m,"match")
 check(audio.death_rooms.size()==2,"duplicate/decorative alive callbacks cannot create deaths")
 var voices=0
 for voice in audio.voices:
  if voice.playing and audio._voice_names.get(voice.get_instance_id(),"").begins_with("death_scream"):voices+=1
 check(voices<=1,"no overlapping scream voices")
 var duration=maxf(audio.streams.death_scream_1.get_length(),audio.streams.death_scream_2.get_length())
 var audio_deadline=Time.get_ticks_usec()+int((duration+1)*1000000)
 while Time.get_ticks_usec()<audio_deadline and int(audio.event_counts.get("death_scream_1",0))+int(audio.event_counts.get("death_scream_2",0))<2:
  await process_frame
  audio.update_state(.01,m,"match")
 check(int(audio.event_counts.get("death_scream_1",0))+int(audio.event_counts.get("death_scream_2",0))==2,"each genuine death eventually sounds exactly once")
 var hf=load("res://scripts/horror_feedback.gd").new();hf.update(.1,m)
 var messages=""
 for n in hf.notifications:messages+=n.text+" "
 check(messages.contains("SURVIVOR ELIMINATED") and messages.contains(m.rooms[1].survivor_name()) and messages.contains("ROOM"),"actual survivor name and room notification")
 var old_count=hf.observed_counts.get("elimination",0);hf.update(.1,m)
 check(hf.observed_counts.get("elimination",0)==old_count,"notification observer stable on unchanged events")
 var boss=fixture("stage_5");audio.reset_match(boss);audio.update_state(.01,boss,"match")
 var r=boss.rooms[1];r.owner=1;r.sleeping=true;r.closed=true;r.door_hp=1
 boss.hunter.target=1;boss.hunter.transformed=true;boss.hunter._damage_door(r,boss,100)
 audio.update_state(.1,boss,"match");audio.update_state(.3,boss,"match")
 check(int(audio.event_counts.get("reaper_laugh",0))==1,"actual Reaper breach distinct laugh")
 audio.update_state(.1,boss,"menu")
 check(audio.pending_deaths.is_empty() and audio.pending_laughs.is_empty(),"menu clears owned pending horror audio")
 audio.shutdown();await create_timer(.5).timeout;audio.queue_free();await process_frame
func run():
 transactions();combat();turret_stats();environment();await audio_events()
 for path in paths:
  for suffix in ["",".tmp",".bak"]:
   if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("HAUNTED_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
