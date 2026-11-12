extends SceneTree
# Prepared combat fixtures verify actual movement/impacts. A owns earned-balance runs.
var checks=0
var failures=0
var approaches=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PREMIUM MECHANICS: "+label)
func fixture(stage="stage_1",mode="standard",archetype="crusher"):
 var m=MatchModel.new();m.reset(503);m.configure_match(mode);m.configure_stage(stage)
 check(m.configure_strategy(0,archetype),"explicit deterministic archetype configures")
 for r in m.rooms:r.owner=r.index;r.sleeping=true;r.closed=true;r.alive=true
 m.player_room=0;m.player_position=m.player().bed_position()
 m.time=m.preparation+.1;m.bot_claimed=5;m.hunter.boss_policy.enabled=false
 return m
func navigation():
 for stage in StageCatalog.STAGES:
  for mode in ["standard","hard","hell"]:
   for id in StrategyCatalog.ARCHETYPE_IDS:
    for index in range(6):
     var m=fixture(stage.id,mode,id);var h=m.hunter;var r=m.rooms[index]
     h.state=HunterState.State.MOVE;h.target=index
     var hp=r.door_hp
     for step in range(2000):
      var before=h.position;m.time+=.05;h.tick(.05,m)
      check(m.navigation_walkable(h.position),"actual archetype movement stays on valid floor")
      check(h.position.distance_to(before)<=h.speed*.05+.001,"archetype movement never teleports")
      check(not r.bounds().grow(-12).has_point(h.position),"intact target door blocks room entry")
      check(r.door_hp==hp,"approach cannot damage door")
      if h.state==HunterState.State.ATTACK:break
     approaches+=1
     check(h.state==HunterState.State.ATTACK and h.position.distance_to(r.door_approach())<3,"all archetypes reach actual doors "+stage.id+mode+id+str(index))
     h.position=r.corridor_anchor();h.state=HunterState.State.ATTACK;h.cooldown=0
     h.tick(.05,m)
     check(h.state==HunterState.State.MOVE and r.door_hp==hp,"out-of-contact strike rejected")
     h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0
     for step in range(100):
      h.tick(.05,m)
      if r.door_hp<hp:break
     check(r.door_hp<hp and r.door_hp>0,"telegraphed contact eventually deals real damage")
     check(m.presentation_events.any(func(e):return e.type=="archetype_warning"),"actual archetype attack emits fair warning")
     r.door_hp=0;h.state=HunterState.State.ATTACK;h.tick(.05,m)
     check(h.state==HunterState.State.BREACH,"real broken door permits breach")
     for step in range(900):
      var before=h.position;h.tick(.05,m)
      check(m.navigation_walkable(h.position),"breach retains legal floor")
      check(h.position.distance_to(before)<=h.speed*.05+.001,"breach retains bounded speed")
      if not r.alive:break
     check(not r.alive and h.state==HunterState.State.EXIT,"actual bed contact eliminates and exits")
     check(h.position.distance_to(r.bed_position())<12,"no remote elimination")
func identities():
 for mode in ["standard","hard","hell"]:
  var stats={}
  for id in StrategyCatalog.ARCHETYPE_IDS:
   var m=fixture("stage_1",mode,id);var h=m.hunter
   var rng=m.random.state
   check(not m.configure_strategy(99,"ravager") and h.archetype==id and m.random.state==rng,"active choice cannot reroll or consume gameplay RNG")
   h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=0
   var hp=m.player().door_hp;h.tick(.01,m)
   check(h.attacks==0 and m.player().door_hp==hp and h.windup_remaining>0,"first strike has actual harmless wind-up")
   var warning=h.windup_remaining
   h.tick(warning*.5,m)
   check(h.attacks==0 and m.player().door_hp==hp,"wind-up cannot deal premature damage")
   h.tick(warning*.5+.02,m)
   check(h.attacks==1 and m.player().door_hp<hp,"strike happens after warning")
   stats[id]=[h.speed,h.damage,h.max_hp]
   if id=="ravager":
    h.encounter_attacks=2;h.cooldown=0;h.tick(.01,m)
    check(h.encounter_attacks==3 and h.cooldown>h.interval+.7,"third Ravager strike creates measurable recovery")
  check(stats.crusher[0]<stats.stalker[0] and stats.stalker[0]<stats.ravager[0],"actual movement speed tradeoffs")
  check(stats.crusher[1]>stats.ravager[1] and stats.ravager[1]>stats.stalker[1],"actual door damage tradeoffs")
  check(stats.crusher[2]>stats.stalker[2] and stats.stalker[2]>stats.ravager[2],"actual durability tradeoffs")
 for stage in StageCatalog.STAGES:
  var m=fixture(stage.id);var counts={}
  for r in m.rooms:
   counts[r.trait_id]=counts.get(r.trait_id,0)+1
   var trait_data=StrategyCatalog.TRAITS[r.trait_id]
   check(is_equal_approx(r.max_hp(),Catalog.DOOR_HP[0]*trait_data.door),"room trait changes actual door maximum")
   check(is_equal_approx(r.door_hp,r.max_hp()),"initial door starts at trait-adjusted maximum")
   var income=r.gold;r.tick_economy(2)
   check(is_equal_approx(r.gold-income,Catalog.BED_INCOME[0]*trait_data.income*2),"occupied bed pays actual trait income")
   r.gold=1000;r.electricity=0;check(r.build("generator",0),"trait room can actually build")
   r.tick_economy(2)
   check(is_equal_approx(r.electricity,3*trait_data.power),"generator pays actual trait electricity")
   var old=r.max_hp();check(not r.apply_trait(r.trait_id) and r.max_hp()==old,"traits cannot apply twice")
   r.sleeping=false;var wallet=[r.gold,r.electricity];r.tick_economy(1)
   check(r.gold==wallet[0] and r.electricity==wallet[1],"inactive bed and generator earn nothing")
  check(m.rooms.size()==6 and counts=={"fortified":2,"power":2,"economy":2},"all maps retain six rooms with balanced trait availability")
 # Existing bots must physically reach each authored bed and still buy defenses.
 for stage in StageCatalog.STAGES:
  var m=MatchModel.new();m.configure_stage(stage.id);m.configure_strategy(0,"stalker")
  m.preparation=10000
  for i in range(2600):m.tick(.1)
  check(m.bot_claimed==5,"all five bots claim trait rooms "+stage.id)
  for r in m.rooms:
   if r.owner<=0:continue
   check(r.sleeping and r.closed and r.resident_position.distance_to(r.bed_position())<2,"bot navigates to actual bed")
   check(r.income_total>0 and r.buildings.values().any(func(b):return b.kind=="turret"),"trait bot economy supports real defenses")
   check(r.buildings.values().all(func(b):return b.level<=4),"autonomous budgets retain cap4")
func weapons():
 for branch in StrategyCatalog.BRANCHES:
  var data=StrategyCatalog.BRANCHES[branch]
  # This matrix checks projectile branches; support/structural roles have new independent suites.
  if data.kind not in ["turret","heavy"]:continue
  for level in [5,10]:
   for boss in [false,true]:
    for overdrive in [false,true]:
     var m=fixture();var r=m.player();var h=m.hunter
     r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
     var tile=0
     for i in range(r.tile_count()):
      if r.tile_position(i).distance_to(r.door_approach())<r.tile_position(tile).distance_to(r.door_approach()):tile=i
     check(m.buy(data.kind,tile),"weapon fixture pays actual base")
     for i in range(3):check(m.upgrade_building(tile),"weapon fixture pays early tiers")
     check(m.specialize_building(tile,branch),"weapon fixture pays branch")
     while r.buildings[tile].level<level:check(m.upgrade_building(tile),"weapon fixture pays prestige tiers")
     h.transformed=boss;h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.hp=100000;h.max_hp=100000
     if overdrive:m.items.timers.overdrive=10
     m._turrets(.01)
     check(m.projectiles.size()==1,"specialized weapon emits one actual projectile")
     var shot=m.projectiles[0]
     check(is_equal_approx(shot.damage,Catalog.turret_damage(data.kind,level)*data.damage),"branch affects actual projectile damage")
     check(is_equal_approx(shot.speed,Catalog.PROJECTILES[data.kind]*data.speed),"branch affects actual projectile speed")
     check(is_equal_approx(r.buildings[tile].cooldown+.01,Catalog.turret_interval(data.kind,level)*data.interval/(1.35 if overdrive else 1)),"branch and Overdrive affect actual firing interval once, carrying elapsed timestep")
     var hp=h.hp;m._advance_projectiles(2)
     check(m.projectiles.is_empty() and is_equal_approx(hp-h.hp,shot.damage),"real impact deals measurable branch damage")
     if branch=="suppression":
      check(h.suppression_remaining>0,"suppression exists only after real impact")
      h.tick(.01,m)
      var nominal=Catalog.HUNTER.speed*StrategyCatalog.ARCHETYPES.crusher.speed if not boss else Catalog.HUNTER.speed*h.archetype_factor("speed")
      check(is_equal_approx(h.speed,nominal*(.925 if boss else .85)),"real speed applies bounded normal/Reaper suppression")
      m.items.timers.frost=5;h.tick(.01,m)
      check(is_equal_approx(h.speed,nominal*(.75 if boss else .6)),"Frost and suppression choose strongest rather than multiply")
      var remaining=h.suppression_remaining;var position=h.position;m.items.frozen_delta=.2;h.tick(.2,m)
      check(h.suppression_remaining==remaining and h.position==position,"Time Freeze holds control clock and movement")
      m.items.frozen_delta=0;m.items.timers.erase("frost");h.tick(1.1,m)
      check(h.suppression_remaining==0 and h.suppression_strength==0 and is_equal_approx(h.speed,nominal),"suppression expires cleanly without permanent disable")
func reaper():
 for mode in ["standard","hard","hell"]:
  for id in StrategyCatalog.ARCHETYPE_IDS:
   var m=fixture("stage_5",mode,id);var h=m.hunter;var r=m.player()
   h.boss_policy={"enabled":true,"opening":0.0,"deadline":0.0,"hp_fraction":1.0}
   h.state=HunterState.State.MOVE;h.target=0;h.hp*=.6
   var hp=h.hp;h.tick(.01,m)
   check(h.transformed and h.state==HunterState.State.TRANSFORM and h.hp<=hp,"actual one-entity transformation never heals")
   var hp_max=h.max_hp
   h.tick(BossCatalog.TRANSFORM_SECONDS+.01,m)
   h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=100;h.tick(.01,m)
   for stat in ["hp","damage","speed"]:check(h.archetype_factor(stat)>=.9 and h.archetype_factor(stat)<=1.1,"Reaper replaces extreme archetype modifiers with bounded tuning")
   check(m.presentation_events.filter(func(e):return e.type=="boss_transform").size()==1 and h.max_hp==hp_max,"transformation cannot repeat or compound stats")
   r.door_level=4;r.door_hp=r.max_hp()
   for attack in ["scythe","siege","surge"]:
    r.door_hp=r.max_hp();h.state=HunterState.State.ATTACK;h.position=r.door_approach();h.target=0
    h.cancel_boss_attack();h.cooldown=0
    r.buildings.clear()
    if attack=="surge":
     for i in range(r.tile_count()):r.buildings[i]={"kind":"heavy","level":1,"cooldown":100.0,"flash":0.0}
    for key in h.boss_cooldowns:h.boss_cooldowns[key]=0 if key==attack else 100
    var door=r.door_hp;h.tick(.01,m)
    check(h.boss_attack==attack and r.door_hp==door and h.windup_remaining>0,"Reaper special warning preserved: "+attack)
    h.tick(BossCatalog.ATTACKS[attack].windup+.02,m)
    check(h.last_boss_attack==attack,"actual Reaper special completes: "+attack)
    check((h.surge_remaining>0 and h.shadow_active(0)) if attack=="surge" else r.door_hp<door,"real special effect remains functional")
func extended_range():
 var m=fixture("stage_1","hell","stalker");var r=m.player();var h=m.hunter;var target=m.rooms[3]
 r.gold=100000;r.electricity=100000;r.bed_level=4;r.door_level=4
 var tile=-1
 for i in range(r.tile_count()):
  var distance=r.tile_position(i).distance_to(target.door_approach())
  if distance>Catalog.BUILDINGS.heavy.range and distance<Catalog.BUILDINGS.heavy.range*1.2:tile=i;break
 check(tile>=0,"authored allied firing lane exists only inside extended range")
 if tile<0:return
 check(m.buy("heavy",tile),"range fixture pays real Arc")
 for i in range(3):check(m.upgrade_building(tile),"range fixture pays early tiers")
 check(m.specialize_building(tile,"storm"),"range fixture pays Storm branch")
 h._model_ref=weakref(m);h.position=target.door_approach();h.target=3;h.state=HunterState.State.ATTACK
 var storm_score=h.target_score(target)
 m._turrets(.01)
 check(m.projectiles.size()==1,"Storm actually fires across legal extended allied lane")
 # Counterfactual same paid fixture: only branch identity differs for the comparison.
 r.buildings[tile].specialization="focus";r.buildings[tile].cooldown=0;m.projectiles.clear()
 var focus_score=h.target_score(target);m._turrets(.01)
 check(m.projectiles.is_empty(),"Focused Arc cannot fire outside its ordinary range")
 check(storm_score>focus_score,"real Hunter threat estimate includes specialized allied firing range")
 m=fixture();r=m.player();h=m.hunter;r.gold=100000;r.electricity=100000;r.bed_level=4;r.door_level=4;tile=-1
 for i in range(r.tile_count()):
  var distance=r.tile_position(i).distance_to(r.door_approach())
  if distance>204 and distance<240:tile=i;break
 check(tile>=0,"authored Needle lane distinguishes204 and240 range")
 if tile<0:return
 check(m.buy("turret",tile),"Needle range fixture pays base")
 for i in range(3):check(m.upgrade_building(tile),"Needle range fixture pays tiers")
 check(m.specialize_building(tile,"precision"),"Needle range fixture pays Precision")
 h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK
 m._turrets(.01)
 check(m.projectiles.is_empty(),"Precision cannot shoot real door beyond204px")
 r.buildings[tile].specialization="suppression";r.buildings[tile].cooldown=0
 m._turrets(.01)
 check(m.projectiles.size()==1,"Suppression can shoot same real door within240px")
func run():
 identities();weapons();reaper();extended_range()
 if "--focused" not in OS.get_cmdline_user_args():navigation()
 print("PREMIUM_MECHANICS_CHECKS=",checks," APPROACHES=",approaches," FAILURES=",failures)
 quit(0 if failures==0 else 1)
