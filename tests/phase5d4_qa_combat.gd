extends "res://tests/phase5d4_qa_boss.gd"
# Prepared threshold fixture; all hits are genuine purchased-weapon homing shots.
# This is transition integration evidence, not naturally earned balance evidence.
func volley(m):
 m._cancel_projectiles("QA isolate next actual volley")
 for b in m.player().buildings.values():b.cooldown=0
 m._turrets(.01);check(m.projectiles.size()>=3,"multiple real owned weapons launch in the same combat batch")
 m._advance_projectiles(2)
func rapid_phases():
 var evidence=[]
 for map in MapCatalog.IDS:
  var m=fixture(407,map);var h=m.hunter;var r=m.player();r.gold=10000;r.electricity=10000
  for room in m.rooms:room.door_level=9;room.door_branch="bulwark";room.door_hp=room.max_hp();room.bot_timer=100000
  var tiles=range(r.tile_count());tiles.sort_custom(func(a,b):return r.tile_position(a).distance_squared_to(r.door_approach())<r.tile_position(b).distance_squared_to(r.door_approach()))
  for i in range(3):check(m.buy("turret",tiles[i]),"actual paid multishot fixture owns Needle "+map)
  h.target=0;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=100;h.hp=h.max_hp*.55+1
  var hp=h.hp;var original_max=h.max_hp;volley(m)
  check(h.hp<=hp and is_equal_approx(h.hp,minf(original_max*.55,h.max_hp)) and h.state==HunterState.State.TRANSFORM and h.transformed,"actual same-batch extra projectile cannot skip first readable transformation "+map)
  check(event_count(m,"boss_transform")==1,"one true transformation event from actual projectiles "+map)
  for i in range(26):m.tick(.1)
  check(h.state!=HunterState.State.TRANSFORM and h.hp>0 and event_count(m,"boss_phase")==1,"full model tick finishes transformation and announces phaseI "+map)
  h.cancel_boss_attack();h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.hp=h.max_hp*.35+1;m.wrath.interrupt(m,"QA isolate phase threshold")
  hp=h.hp;volley(m);check(h.hp<=hp and is_equal_approx(h.hp,h.max_hp*.35),"actual multishot phaseII guard keeps precise35% without refill "+map)
  m.tick(.1);check(m.wrath.phase==2 and event_count(m,"boss_phase")==2,"actual integrated tick enters phaseII exactly once "+map)
  for i in range(13):m.tick(.1)
  h.cancel_boss_attack();h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.hp=h.max_hp*.1+1;m.wrath.interrupt(m,"QA isolate final threshold");h.phase_guard_remaining=0
  hp=h.hp;volley(m);check(h.hp<=hp and is_equal_approx(h.hp,h.max_hp*.1),"actual multishot final guard keeps10% until ultimate warning "+map)
  for i in range(32):m.tick(.1)
  check(m.wrath.final_used and m.wrath.domain_active() and m.wrath.counts.get("crimson_execution",0)==1 and not m.wrath.scythe.is_empty(),"real model loop reaches combined final domain before multishot can kill promised encounter "+map)
  var chosen=m.wrath.domain_room;var other=(chosen+1)%6;var chosen_hp=m.rooms[chosen].door_hp;var other_hp=m.rooms[other].door_hp;var old=h.position;var traversed=0.0
  for i in range(250):
   var prev=h.position;m.tick(.1);traversed+=h.position.distance_to(prev)
   check(m.navigation_walkable(h.position) and h.position.distance_to(prev)<=h.speed*.1+3,"actual final boss moves along valid bounded navigation "+map)
   check(m.minions.is_empty(),"actual final domain never adds minion attackers "+map)
   if not m.wrath.domain_active():break
  check(m.rooms[other].door_hp==other_hp,"full domain simulation deals no unrelated-room damage "+map)
  check(m.rooms[chosen].door_hp<chosen_hp,"full domain simulation deals genuine chosen-room pressure "+map)
  check(event_count(m,"boss_transform")==1 and event_count(m,"boss_phase")==2 and m.wrath.counts.get("crimson_execution",0)==1,"full combat loop never refills/retransforms/restarts ultimate "+map)
  evidence.append({"map":map,"target":chosen,"start":str(old),"traversed":traversed,"domain_pressure":chosen_hp-m.rooms[chosen].door_hp,"phase":m.wrath.phase,"transformations":event_count(m,"boss_transform"),"ultimates":m.wrath.counts.get("crimson_execution",0),"domain_still_active":m.wrath.domain_active(),"hp":h.hp})
 var f=FileAccess.open("res://docs/evidence/phase5d4/qa-integrated-phases.json",FileAccess.WRITE);f.store_string(JSON.stringify(evidence," "));f.close()
func run():
 rapid_phases();print("PHASE5D4_QA_INTEGRATED_COMBAT_CHECKS=",checks," MAPS=5 FAILURES=",failures);quit(1 if failures else 0)
