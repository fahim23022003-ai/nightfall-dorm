extends "res://tests/phase5d4_qa_evolution.gd"
var prefix="user://phase5d4-qa-boss-"+str(Time.get_ticks_usec())
var serial=0
func boss(map_id="abandoned_dorm"):
 var m=fixture(53,map_id);var h=m.hunter
 h.transformed=true;h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=1000
 m.wrath.recovery=1000
 for r in m.rooms:
  r.bed_level=9;r.bed_branch="lucid";r.door_level=9;r.door_branch="renewal";r.door_hp=r.max_hp();r.income_multiplier=0
 return m
func complete_cast(m,id,target=0):
 if not m.wrath.begin(id,m,target):return false
 for i in range(40):
  if m.wrath.ability=="":break
  m.wrath.tick(.1,m)
 return m.wrath.ability=="" and m.wrath.counts.get(id,0)>0
func bind(m,loadout):
 serial+=1;var p=PlayerProfile.new(prefix+str(serial)+".json")
 for id in loadout:p.inventory[id]=3
 p.item_loadout=loadout.duplicate();var entry=p.begin_match("hell");p.bind_items(m,entry.id)
 return {"p":p,"id":entry.id}
func resources():
 var m=boss();var r=m.player();r.gold=103.25;r.electricity=17.75
 check(m.wrath.begin("soul_reaper",m,0),"Soul Reaper accepts genuine eligible target")
 for i in range(34):m.wrath.tick(.1,m)
 check(r.gold==103.25 and r.electricity==17.75 and m.wrath.active(),"50% current-resource channel has full interrupt window")
 # Actual current amount at completion, not stale amount captured on cast.
 r.gold+=2;r.electricity+=.5;m.wrath.tick(.2,m)
 check(is_equal_approx(r.gold,52.625) and is_equal_approx(r.electricity,9.125),"completed Soul Reaper drains exact half current fractional separate resources")
 var wallet=[r.gold,r.electricity]
 for i in range(10):m.wrath.tick(.1,m)
 check([r.gold,r.electricity]==wallet and m.wrath.counts.soul_reaper==1,"channel cannot repeatedly complete on following frames")
 check(not m.wrath.begin("soul_reaper",m,0),"strict Soul Reaper cooldown blocks immediate replay")
 for intervention in ["damage","freeze","displace","target_death"]:
  m=boss();r=m.player();wallet=[r.gold,r.electricity];check(m.wrath.begin("soul_reaper",m,0),"channel starts for "+intervention)
  m.wrath.tick(1,m)
  match intervention:
   "damage":m.apply_target_damage(1,m.hunter.max_hp*.025,0)
   "freeze":m.items.timers.time_freeze=1.5
   "displace":m.hunter.position+=Vector2(60,0)
   "target_death":r.alive=false
  m.wrath.tick(.1,m)
  check(not m.wrath.active() and [r.gold,r.electricity]==wallet and not m.wrath.counts.has("soul_reaper"),"real interrupt avoids all wallet loss "+intervention)
  check(m.wrath.cooldowns.get("soul_reaper",0)>60,"interrupted channel cannot be retried instantly "+intervention)
 m=boss();r=m.player();r.gold=0;r.electricity=.01;check(complete_cast(m,"soul_reaper"),"tiny-wallet channel safely completes")
 check(r.gold==0 and is_equal_approx(r.electricity,.005),"drain never creates negatives or rounding resources")
func victim_items():
 for automatic in ["guardian_heart","feather"]:
  var m=boss();var a=bind(m,[automatic]);var r=m.player();var npc=m.rooms[1]
  m.hunter.target=1
  if automatic=="guardian_heart":
   r.door_hp=10;npc.door_hp=10
   m.apply_room_damage(1,100,"NPC actual damage",1,true)
   check(npc.door_hp==0 and r.door_hp==10 and a.p.inventory[automatic]==3,"NPC lethal damage cannot consume player Guardian")
   m.apply_room_damage(0,100,"player actual damage",1,true)
   check(r.door_hp>0 and a.p.inventory[automatic]==2 and m.items.legendary_used==1,"player-victim lethal damage triggers one Guardian despite Hunter targeting NPC")
   m.items.guardian_shield_hp=0;r.door_hp=10;m.apply_room_damage(0,100,"second lethal",1,true)
   check(r.door_hp==0 and a.p.inventory[automatic]==2,"same player cannot revive twice")
  else:
   r.door_hp=r.max_hp()*.3;npc.door_hp=npc.max_hp()*.3
   m.apply_room_damage(1,npc.max_hp()*.1,"NPC threshold",1,true)
   check(a.p.inventory[automatic]==3 and not m.items.feather_used,"NPC threshold cannot trigger player feather")
   m.apply_room_damage(0,r.max_hp()*.1,"player threshold",1,true)
   check(a.p.inventory[automatic]==2 and m.items.feather_used and is_equal_approx(r.door_hp,r.max_hp()*.35),"player victim feather heals actual15% at crossing")
  var q=PlayerProfile.new(a.p.path);check(q.load_profile() and q.inventory==a.p.inventory,"actual auto-consumption durably saves exact stock")
 for other_target in [true,false]:
  var m=boss();var a=bind(m,["reaper_seal"]);var target=1 if other_target else 0
  check(m.wrath.begin("soul_reaper",m,target),"actual resource warning starts against chosen victim")
  var old=a.p.inventory.reaper_seal
  var accepted=a.p.activate_item(0,m,a.id)
  check(accepted==(not other_target),"Reaper Seal accepts only genuine player-directed new warning")
  check(a.p.inventory.reaper_seal==old-(1 if accepted else 0),"Seal consumes exactly when genuine counter succeeds")
  check(m.wrath.active()==other_target,"unrelated NPC warning not silently cancelled")
func locks():
 var m=boss();var r=m.player();var a=bind(m,["gold","battery"])
 check(complete_cast(m,"rules_judgement"),"Rules Judgement completes after warning")
 check(m.wrath.rules_remaining>0 and m.wrath.rules_remaining<=5,"manual item/turret lock is finite")
 var stocks=a.p.inventory.duplicate(true);var gold=r.gold;var power=r.electricity
 check(not a.p.activate_item(0,m,a.id) and not a.p.activate_item(1,m,a.id) and a.p.inventory==stocks and r.gold==gold and r.electricity==power,"locked manual item fails without stock/resource side effects")
 check(not m.wrath.begin("final_judgement",m,0),"production lock cannot overlap item/turret lock")
 for i in range(51):m.wrath.tick(.1,m)
 check(m.wrath.rules_remaining==0 and a.p.activate_item(0,m,a.id),"manual item works immediately after lock expires")
 m=boss();r=m.player();r.income_multiplier=1;gold=r.gold;power=r.electricity
 check(complete_cast(m,"final_judgement"),"Final Judgement genuine warning completes")
 check(not m.wrath.begin("rules_judgement",m,0),"reverse lock overlap blocked")
 for i in range(5):
  r.production_paused=m.wrath.production_remaining>0;r.tick_economy(.5);m.wrath.tick(.5,m)
 check(r.gold==gold and r.electricity==power,"production lock leaves stored resources untouched and generates nothing")
 for i in range(40):m.wrath.tick(.1,m)
 r.production_paused=false;var expected=r.income_rate()*.25;r.tick_economy(.25)
 check(is_equal_approx(r.gold-gold,expected),"production resumes without banked catch-up earnings")
 m.wrath.rules_remaining=3;m.wrath.production_remaining=3;m.wrath.clear(m)
 check(m.wrath.rules_remaining==0 and m.wrath.production_remaining==0 and not m.wrath.active(),"combat cleanup clears all locks")
func phases():
 var m=boss();var h=m.hunter;h.hp=h.max_hp*.5
 m.spawn_undead(2);var old=m.minions[0];var oldhp=old.hp;var oldmax=old.max_hp;var olddamage=old.damage
 m.apply_target_damage(1,h.max_hp,0)
 check(h.hp>0 and is_equal_approx(h.hp,h.max_hp*.35),"single massive phaseI hit stops at35% without healing")
 m.wrath.tick(.01,m)
 check(m.wrath.phase==2 and event_count(m,"boss_phase")==2,"phaseII starts once with distinct event")
 check(old.enhanced and old.max_hp>oldmax and old.damage>olddamage and old.hp<=oldhp,"phaseII upgrades existing undead without healing/refill")
 h.phase_guard_remaining=0;m.apply_target_damage(1,h.max_hp,0)
 check(is_equal_approx(h.hp,h.max_hp*.1) and h.final_guard_used,"single massive phaseII hit stops at10% for final warning")
 m.wrath.tick(.01,m)
 check(m.wrath.ability=="crimson_execution" and m.wrath.final_used,"final10% starts combined once-only ultimate")
 for i in range(31):m.wrath.tick(.1,m)
 check(m.wrath.domain_active() and not m.wrath.scythe.is_empty() and m.minions.is_empty(),"combined ultimate creates actual domain and giant scythe and clears undead")
 check(m.wrath.counts.get("crimson_execution",0)==1,"single ultimate activation counted")
 var chosen=m.wrath.domain_room;h.phase_guard_remaining=0;h.hp=h.max_hp*.3;h.hp=h.max_hp*.09
 m.wrath.end_domain(m);m.wrath.tick(.1,m)
 check(m.wrath.ability!="crimson_execution" and not m.wrath.begin("crimson_execution",m,chosen),"healing/re-crossing final threshold cannot rearm ultimate")
 # Vulnerability is an actual impact factor, so guards must bound effective damage.
 m=boss();h=m.hunter;h.hp=h.max_hp*.5;h.surge_room=0;h.surge_remaining=3;h.target=0
 m.apply_target_damage(1,h.max_hp,0)
 check(is_equal_approx(h.hp,h.max_hp*.35),"actual surge vulnerability cannot bypass phase guard")
func domain():
 for map_id in MapCatalog.IDS:
  var m=boss(map_id);var h=m.hunter;var old_position=h.position
  check(complete_cast(m,"crimson_execution",1),"combined domain casts against actual NPC room "+map_id)
  check(m.wrath.domain_room==1 and h.position==old_position,"domain selects real NPC without teleporting Hunter "+map_id)
  m.spawn_undead(10);check(m.minions.is_empty(),"domain prohibits extra attacking undead "+map_id)
  var hp=h.hp;check(m.apply_target_damage(1,10,0)==0 and h.hp==hp,"foreign room direct attacks cannot damage domain boss "+map_id)
  check(m.apply_target_damage(1,10,1)>0 and h.hp<hp,"chosen room real defense can hurt boss "+map_id)
  var other=m.rooms[2];hp=other.door_hp
  check(m.apply_room_damage(2,100,"foreign test attack",1,true)==0 and other.door_hp==hp,"domain suppresses attacks against unrelated room "+map_id)
  hp=h.hp;m.defenses.ignite(1,100,3,0);m.defenses.tick(.1,m)
  check(h.hp==hp,"pre-existing foreign machine burn cannot leak into domain "+map_id)
  hp=h.hp;m.items.trap={"position":h.position,"remaining":30.0};m.items.trigger_segment(h.position-Vector2(10,0),h.position+Vector2(10,0),m)
  check(h.hp==hp and not m.items.trap.is_empty(),"foreign armed trap cannot strike NPC domain boss "+map_id)
  for id in ["time_freeze","frost","trap","decoy","smoke","reaper_seal"]:
   var a=bind(m,[id]);var old_stock=a.p.inventory[id]
   check(not a.p.activate_item(0,m,a.id) and a.p.inventory[id]==old_stock,"foreign offensive item cannot interfere with NPC one-on-one or consume stock "+id+map_id)
  hp=h.hp;m.items.burn_remaining=2;m.items.tick(.1,m)
  check(h.hp==hp,"pre-existing foreign player Inferno cannot leak into NPC domain "+map_id)
  var before=m.rooms[1].door_hp;m.wrath.tick(1,m);m.wrath.tick(3,m)
  check(m.rooms[1].door_hp<before,"embedded giant scythe deals real bounded periodic damage "+map_id)
  check(m.wrath.scythe.get("attempts",100)<=3,"destruction attempt budget remains capped "+map_id)
  m.rooms[1].alive=false;m.wrath.tick(.1,m)
  check(not m.wrath.domain_active() and m.wrath.scythe.is_empty() and m.wrath.rules_remaining==0 and m.wrath.production_remaining==0,"domain target death cleans all room state "+map_id)
 for reason in ["timeout","boss_death","terminal"]:
  var m=boss();complete_cast(m,"crimson_execution",0)
  match reason:
   "timeout":m.wrath.tick(31,m)
   "boss_death":m.hunter.hp=0;m.wrath.tick(.1,m)
   "terminal":m.result="defeat";m.wrath.tick(.1,m)
  check(not m.wrath.domain_active() and m.wrath.scythe.is_empty() and m.minions.is_empty(),"domain cleanup on "+reason)
func instant_cleanup():
 for source in ["burn","trap"]:
  var m=boss();m.spawn_undead(10);m.wrath.rules_remaining=3;m.wrath.production_remaining=3;m.hunter.hp=.01
  if source=="burn":m.items.burn_remaining=2;m.items.tick(.1,m)
  else:
   m.items.trap={"position":m.hunter.position,"remaining":30.0};m.items.trigger_segment(m.hunter.position,m.hunter.position,m)
  check(m.hunter.hp==0 and m.hunter.state==HunterState.State.DEAD,"actual existing item lethally damages boss "+source)
  check(m.minions.is_empty() and m.wrath.rules_remaining==0 and m.wrath.production_remaining==0 and not m.wrath.active(),"actual same-frame boss death clears undead/locks before next update "+source)
 var m=boss();complete_cast(m,"crimson_execution",0);m.hunter.hp=.01;m.apply_target_damage(1,1,0)
 check(m.hunter.hp==0 and not m.wrath.domain_active() and m.wrath.scythe.is_empty(),"actual chosen-room lethal hit immediately cleans domain and scythe without extra tick")
 m=boss();complete_cast(m,"crimson_execution",1);m.rooms[1].door_hp=0;m.hunter.position=m.rooms[1].bed_position();m.hunter.target=1;m.hunter.state=HunterState.State.BREACH
 check(m.eliminate_resident(1,1),"actual domain NPC victim dies only through genuine central contact")
 check(not m.wrath.domain_active() and m.wrath.scythe.is_empty() and m.wrath.rules_remaining==0 and m.wrath.production_remaining==0,"actual central domain victim death immediately cleans all ultimate state")
func run():
 resources();victim_items();locks();phases();domain();instant_cleanup()
 preload("res://tests/replay_test_support.gd").cleanup(prefix)
 print("PHASE5D4_QA_BOSS_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
