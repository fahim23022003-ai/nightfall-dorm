extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func fixture(seed_value=17):
 var m=MatchModel.new();m.reset(seed_value);m.configure_stage("stage_3");m.configure_match("hell");m.configure_strategy(seed_value,"crusher")
 m.preparation=0;m.time=20;m.player_room=0;m.bot_claimed=5
 for i in range(6):
  var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.gold=1e6;r.electricity=1e6;r.bot_timer=1e6;r.door_level=4;r.bed_level=4;r.door_hp=r.max_hp();r.resident_position=r.bed_position()
 m.player_position=m.player().bed_position();m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.rooms[0].door_approach();m.hunter.tick(0,m)
 return m
func run():
 check(Catalog.BUILDINGS.size()==12,"twelve actual placeable types")
 var found={}
 for seed_value in range(1,45):
  var m=fixture(seed_value)
  for i in range(1,6):
   var r=m.rooms[i];r.door_hp=0;m.hunter.position=r.bed_position();m.hunter.state=HunterState.State.BREACH;m.hunter.target=i
   check(m.eliminate_resident(i),"real unique survivor death")
   check(not m.eliminate_resident(i),"repeat victim rejected")
  for id in m.evolution.acquired:found[id]=true
  check(m.evolution.acquired.size()==5 and m.evolution.credited.size()==5,"exactly one buff per unique death")
  check(m.evolution.award(m,0,"Hunter")=="","forged direct award rejected")
 check(found.size()==15,"all fifteen eligible buffs actually awarded across seeded genuine kills")
 for kind in DefenseEffects.SPECIAL:
  for branch in StrategyCatalog.branches(kind):
   var m=fixture();var r=m.player();r.bed_branch="lucid";r.door_branch="bulwark"
   check(r.build(kind,0),"new machine purchase "+kind)
   for level in range(1,10):
    check(r.specialize_building(0,branch) if level==4 else r.upgrade_building(0),"actual upgrade "+kind+str(level))
   check(not r.upgrade_building(0),"level eleven rejected")
   var paid=Vector2(r.buildings[0].invested_gold,r.buildings[0].invested_power);var before=Vector2(r.gold,r.electricity)
   check(r.sell_building(0) and Vector2(r.gold,r.electricity).is_equal_approx(before+paid*.5),"exact eligible half-refund "+kind)
   check(not r.sell_building(0) and r.build(kind,0),"no double sale and tile reusable")
 for id in ReaperWrath.ABILITIES:
  if id=="eternal_sacrifices":continue
  var m=fixture();var h=m.hunter;h.transformed=true;h.boss_policy.enabled=true;h.cooldown=100;m.wrath.recovery=100
  if id in ["enhanced_undead","soul_reaper","phantom_scream","final_judgement","crimson_execution"]:m.wrath.phase=2
  var before_g=m.player().gold;var before_e=m.player().electricity;var before_hp=m.player().door_hp
  check(m.wrath.begin(id,m,0),"actual warning begins "+id)
  var t=0.0
  while m.wrath.active() and t<5:m.wrath.tick(.1,m);t+=.1
  check(m.wrath.counts.get(id,0)==1,"telegraph completes once "+id)
  if id=="soul_reaper":check(is_equal_approx(m.player().gold,before_g*.5) and is_equal_approx(m.player().electricity,before_e*.5),"exact current half drain")
  if id=="scythe_slash":check(m.player().door_hp<before_hp,"real scythe slash damage")
  if id=="assault":check(m.minions.size()==10,"major assault strict ten")
  if id=="rules_judgement":check(m.wrath.rules_remaining>0 and m.items.can_activate("repair",m).contains("locked"),"actual manual item lock")
  if id=="crimson_execution":check(m.wrath.domain_active() and m.minions.is_empty() and not m.wrath.scythe.is_empty(),"one combined final domain and scythe")
  m.wrath.clear(m);check(m.minions.is_empty() and not m.wrath.domain_active() and m.wrath.rules_remaining==0 and m.wrath.production_remaining==0,"terminal clears every transient "+id)
 var m=fixture();m.spawn_undead(30,true);check(m.minions.size()==10,"never more than ten undead")
 var dead_id=m.minions[0].id;m.minions[0].hurt(1e6,m);m.spawn_undead(1);check(m.target_by_id(dead_id)==null and m.minions.size()==10,"dead IDs never recycled")
 m.clear_minions();check(not str(m._navigation_routes.keys()).contains("undead"),"route cache cleanup")
 # Full actual simulation: turrets damage/kill attackable undead and main actor through real homing impacts.
 m=fixture();m.hunter.hp=1e6;m.hunter.max_hp=1e6;var tiles=range(m.player().tile_count());tiles.sort_custom(func(a,b):return m.player().tile_position(a).distance_squared_to(m.player().door_approach())<m.player().tile_position(b).distance_squared_to(m.player().door_approach()))
 m.player().build("flame",tiles[0]);m.player().build("frost",tiles[1]);m.player().build("shock",tiles[2]);m.spawn_undead(3)
 for u in m.minions:u.position=m.player().door_approach();u.target=0
 for tick in range(120):m.tick(.1)
 check(m.shots>0 and m.damage_dealt>0,"new weapons fire real homing projectiles in simulation")
 check(m.player().main_damage_dealt+m.player().minion_damage_dealt>0,"separate real target damage counters")
 m=fixture();m.hunter.state=HunterState.State.MOVE;m.hunter.position=m.player().door_approach();m.player().build("decoy",0)
 m.defenses.tick(.1,m);check(m.defenses.lure_remaining>0,"genuine paid decoy activation")
 m.sell_building(0);m.player().build("decoy",0)
 check(not m.defenses.lure_tick(.1,m) and m.defenses.lure_cooldown>0,"sale and same-tick replacement never rebind old lure")
 print("PHASE5D4_DEV_CORE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
func _initialize():call_deferred("run")
