extends SceneTree
var checks=0
var failures=0
var execution=[]
func ck(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func near(a,b,label):ck(absf(float(a)-float(b))<.0001,label+" actual="+str(a)+" expected="+str(b))
func _initialize():call_deferred("run")
func fixture(kind="stalker",map="abandoned_dorm"):
 var m=MatchModel.new();m.configure_map(map);m.configure_match("standard",{});m.configure_strategy(101,kind)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5;m.time=40
 var r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
 var h=m.hunter;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.boss_policy={"enabled":false};h._model_ref=weakref(m);h.arcane.cooldown=100
 return m
func event_count(m,type):return m.presentation_events.filter(func(e):return e.type==type).size()
func buy(m,kind,tile=0):ck(m.buy(kind,tile),"actual purchase "+kind)
func numeric():
 var p={"type":"physical","element":"neutral"};var magic={"type":"magic","element":"neutral"}
 var m=fixture();var r=m.player();var h=m.hunter
 near(m.apply_room_damage(0,100,"door strike"),100,"physical basic exact")
 near(m.apply_room_damage(0,100,"curse"),100,"magic unshielded exact")
 for invalid in [{"type":"invalid","element":"neutral"},{"type":"magic","element":"void"}]:
  var hp=r.door_hp;near(m.apply_room_damage(0,50,"curse",1,true,invalid),0,"invalid door packet rejected");near(r.door_hp,hp,"invalid packet unchanged door")
  near(m.apply_target_damage(1,50,0,invalid),0,"invalid target packet rejected")
 for amount in [-5.0,NAN,INF]:near(m.apply_room_damage(0,amount,"curse"),0,"invalid incoming amount rejected")
 r.door_branch="bulwark";r.door_hp=r.max_hp();m.evolution.acquired=["door_crusher","savage_strike"]
 near(m.apply_room_damage(0,100,"curse",1,true),100*1.15*1.12*.9,"evolution special and door armor once")
 m.evolution.acquired=[];r.door_branch="";r.door_hp=r.max_hp()
 for element in DamageRules.ELEMENTS:
  for defender in DamageRules.ELEMENTS:
   ck(DamageRules.multiplier(element,defender)>=.9 and DamageRules.multiplier(element,defender)<=1.15,"bounded element factors")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  m=fixture(kind);h=m.hunter;h.hp=h.max_hp;h.state=HunterState.State.ATTACK;h.boss_policy={"enabled":false}
  for element in DamageRules.ELEMENTS:
   var affinity=DamageRules.affinity(kind);var expected=100.0
   if {"fire":"ice","ice":"earth","earth":"electric","electric":"fire"}.get(element,"")==affinity:expected=115.0
   elif {"fire":"ice","ice":"earth","earth":"electric","electric":"fire"}.get(affinity,"")==element:expected=90.0
   near(m.apply_target_damage(1,100,0,{"type":"magic","element":element}),expected,"actual elemental target calculation "+kind+"/"+element)
 ck(DamageRules.weapon("turret").type=="physical" and DamageRules.weapon("trap").type=="physical","Needle/trap Physical")
 for weapon in ["heavy","flame","frost","shock","inferno"]:ck(DamageRules.weapon(weapon).type=="magic","elemental weapon Magic "+weapon)
 for source in ["door strike","charged heavy strike","undead strike","Scythe Slash","Embedded Scythe","scythe"]:ck(DamageRules.source(source).type=="physical","physical actual source "+source)
 for source in ["siege","surge","Phantom Scream","Shadow Surge","Dread Aura","curse","cursed_projectile","interference","chain_lightning","soul_drain"]:ck(DamageRules.source(source).type=="magic","magic actual source "+source)
func reflection():
 var m=fixture();var r=m.player();var h=m.hunter;buy(m,"barrier")
 var hp=h.hp;near(m.apply_room_damage(0,100,"curse"),100,"reflection does not make door invulnerable");near(hp-h.hp,11.5,"level1 actual reflection")
 var cd=r.magic_state.reflect_cd;hp=h.hp;m.apply_room_damage(0,100,"curse");near(h.hp,hp,"second hit no cooldown reflection");near(r.magic_state.reflect_cd,cd,"second hit cannot reset refractory")
 var wallet=Vector2(r.gold,r.electricity);ck(r.sell_building(0),"sell mirror");buy(m,"barrier")
 near(r.magic_state.reflect_cd,cd,"sell rebuild retains room reflection cooldown")
 MagicDefense.tick(m,4.1);hp=h.hp;m.apply_room_damage(0,100,"door strike");near(h.hp,hp,"physical cannot reflect")
 m.apply_room_damage(0,100,"curse",1,true,{"type":"magic","element":"neutral","reflected":true});near(h.hp,hp,"nonrecursive reflected packet")
 m.spawn_undead(1);ck(m.minions.size()==1,"real undead registered for identity test")
 if m.minions.size()==1:
  var u=m.minions[0];u.position=r.door_approach();u.target=0;var uh=u.hp;hp=h.hp
  m.apply_room_damage(0,40,"curse",u.id,false,{"type":"magic","element":"neutral"})
  near(uh-u.hp,4.6,"reflection hits actual undead identity");near(h.hp,hp,"undead reflection never redirects to boss")
  var n=event_count(m,"magic_reflect");u.hp=0
  near(m.apply_room_damage(0,40,"curse",u.id),0,"stale dead identity cannot cause hit");ck(event_count(m,"magic_reflect")==n,"stale attacker no reflection credit")
 m=fixture("witch");r=m.player();h=m.hunter;buy(m,"barrier");hp=h.hp
 m.apply_room_damage(0,100,"curse",1,true,{"type":"magic","element":"fire"});near(hp-h.hp,11.5*1.15,"reflection affinity applies once to actual attacker")
func storage_and_shield():
 var m=fixture();var r=m.player();buy(m,"plasma")
 near(m.apply_room_damage(0,100,"curse"),75,"Plasma absorbs25percent real damage");near(r.magic_state.stored,25,"Plasma stores actual absorption")
 var before=r.door_hp;MagicDefense.tick(m,.1);near(r.door_hp-before,5,"Plasma release converts stored energy to actual bounded healing");near(r.magic_state.stored,0,"Plasma release spends storage")
 r.magic_state.heal_cd=30;r.door_hp=r.max_hp()
 for i in range(6):m.apply_room_damage(0,100,"curse")
 near(r.magic_state.stored,115,"finite level1 capacity")
 var stored=r.magic_state.stored;m.apply_room_damage(0,20,"door strike");near(r.magic_state.stored,stored,"Physical never fills Plasma")
 MagicDefense.tick(m,12.1);near(r.magic_state.stored,0,"temporary Plasma expires")
 r.magic_state.stored=100;r.magic_state.storage_time=5;var cd=r.magic_state.heal_cd
 ck(r.sell_building(0),"sell Plasma");near(r.magic_state.stored,0,"sale clears temporary energy");near(r.magic_state.heal_cd,cd,"sale retains heal room cooldown")
 buy(m,"plasma");near(r.magic_state.stored,0,"rebuild never mints stored energy")
 ck(r.sell_building(0),"clear Plasma before shield")
 buy(m,"antenna");var e=r.electricity;MagicDefense.tick(m,.1)
 near(e-r.electricity,2.5,"Antenna actual paid Electricity");near(r.magic_state.shield,42,"Antenna finite level1 durability")
 near(m.apply_room_damage(0,30,"door strike"),30,"magic shield does not block Physical");near(r.magic_state.shield,42,"Physical leaves magic durability untouched")
 near(m.apply_room_damage(0,100,"curse"),58,"magic overflow reaches door");near(r.magic_state.shield,0,"Antenna durability spent")
 e=r.electricity;MagicDefense.tick(m,1);near(r.magic_state.shield,0,"shield cannot recharge during shared cooldown");near(r.electricity,e,"no invisible repeated power purchase")
 buy(m,"antenna",1);MagicDefense.tick(m,.1);near(r.magic_state.shield,0,"second Antenna cannot bypass cooldown")
 var cd2=r.magic_state.shield_cd;ck(r.sell_building(0),"sell first Antenna");ck(r.sell_building(1),"sell second Antenna");buy(m,"antenna")
 near(r.magic_state.shield_cd,cd2,"sell rebuild cannot reset shared shield recharge")
 MagicDefense.tick(m,10);near(r.magic_state.shield,42,"eventual paid regeneration restored")
 e=r.electricity;MagicDefense.tick(m,100);near(r.electricity,e,"full shield does not repeatedly consume resources")
 m=fixture();r=m.player();buy(m,"antenna");r.electricity=0;MagicDefense.tick(m,1);near(r.magic_state.shield,0,"no free shield without power")
 for kind in MagicDefense.KINDS:ck(MagicDefense.best(r,kind).is_empty() if kind!="antenna" else not MagicDefense.best(r,kind).is_empty(),"best only registered actual machine")
func economy():
 for kind in MagicDefense.KINDS:
  for branch in StrategyCatalog.branches(kind):
   var m=fixture();var r=m.player();var start=Vector2(r.gold,r.electricity);var coupons=[0]
   r.coupon_armed=true;r.coupon_payment=func(_saved):coupons[0]+=1;return true
   buy(m,kind);var paid=Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power)*.6
   near(r.buildings[0].invested_gold,paid.x,"discounted base ledger Gold");near(r.buildings[0].invested_power,paid.y,"discounted base ledger Electricity")
   ck(not m.buy(kind,0),"duplicate same pad purchase rejected")
   for level in range(1,10):
    var cost=Catalog.upgrade_cost(kind,level);var before=Vector2(r.gold,r.electricity)
    if level==4:
     cost+=StrategyCatalog.BRANCH_FEE;r.coupon_armed=true;cost*=.6
     ck(r.specialize_building(0,branch),"real exclusive branch paid "+branch)
    else:ck(r.upgrade_building(0),"real next level "+kind)
    paid+=cost
    ck(Vector2(r.gold,r.electricity).is_equal_approx(before-cost),"exact upgrade resources once")
   ck(r.buildings[0].level==10 and not r.upgrade_building(0),"L10 cap and L11 rejection")
   ck(r.buildings[0].specialization==branch and not r.specialize_building(0,StrategyCatalog.branches(kind)[0]),"exclusive branch cannot replace")
   near(r.buildings[0].invested_gold,paid.x,"total actual Gold capital");near(r.buildings[0].invested_power,paid.y,"total actual Electricity capital")
   var before=Vector2(r.gold,r.electricity);ck(r.sell_building(0),"L10 sale succeeds")
   ck(Vector2(r.gold,r.electricity).is_equal_approx(before+paid*.5),"exact50percent actual separate capital refund")
   ck(not r.sell_building(0) and Vector2(r.gold,r.electricity).is_equal_approx(before+paid*.5),"no double sale/refund")
   ck(coupons[0]==2,"exact successful coupon consumption")
   execution.append({"kind":kind,"branch":branch,"paid":str(paid)})
  var bad=fixture();var rr=bad.player();rr.gold=0;rr.electricity=0;rr.coupon_armed=true;var used=[0];rr.coupon_payment=func(_saved):used[0]+=1;return true
  ck(not bad.buy(kind,0) and rr.coupon_armed and used[0]==0,"failed purchase consumes no coupon")
func items():
 ck(ItemCatalog.IDS.size()==20,"all20 existing items remain registered")
 var m=fixture("witch");var r=m.player();var hp=m.hunter.hp;m.items.burn_remaining=1
 m.items.tick(.5,m);near(hp-m.hunter.hp,12*.5*1.15,"Inferno actual typed fire damage reaches affinity")
 hp=m.hunter.hp;m.items.trap={"position":m.hunter.position,"remaining":20.0}
 m.items.trigger_segment(m.hunter.position,m.hunter.position,m);near(hp-m.hunter.hp,220*.9,"actual trap Physical Earth is resisted by Ice")
 hp=m.hunter.hp;m.items.trigger_segment(m.hunter.position,m.hunter.position,m);near(hp,m.hunter.hp,"trap cannot retrigger")
 for kind in MagicDefense.KINDS:
  m=fixture();r=m.player();buy(m,kind);var wallet=TemporaryLoadout.new("practice",["repair","shield"]);m.run_kind="practice";wallet.bind_items(m,1)
  r.door_hp-=100;var stock=wallet.inventory.repair;ck(wallet.activate_item(0,m,1),"existing repair with "+kind);ck(wallet.inventory.repair==stock-1,"successful repair stock once")
  stock=wallet.inventory.shield;m.items.cooldown=0;m.wrath.rules_remaining=2
  ck(not wallet.activate_item(1,m,1) and wallet.inventory.shield==stock,"Rules lock failed activation keeps stock")
func source_save():
 var m=MatchModel.new();ck(m.configure_endless("abandoned_dorm","standard",11,990),"save current run")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
 for i in range(3):buy(m,MagicDefense.KINDS[i],i)
 r.magic_state={"stored":70.0,"shield":20.0,"reflect_cd":3.0,"shield_cd":8.0,"storage_time":7.0,"heal_cd":2.0,"disrupt":2.0,"disrupt_guard":16.0}
 m.endless.phase="intermission";m.endless.completed=1;m.endless.sealed_wave=1;m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD
 var data=ReplaySnapshot.encode(m);ck(not data.is_empty(),"actual magic state checkpoint")
 if data.is_empty():return
 var copy=JSON.parse_string(JSON.stringify(data));var restored=ReplaySnapshot.restore(copy)
 ck(restored!=null,"new state JSON restores")
 if restored!=null:
  ck(restored.player().magic_state==r.magic_state,"stored/shield/sharedcooldowns survive atomically")
  var hp=restored.player().door_hp;MagicDefense.tick(restored,1);near(restored.player().door_hp,hp,"resume cannot bypass heal cooldown")
 for key in r.magic_state:
  for invalid in [-1.0,INF,NAN,1000000.0]:
   var bad=data.duplicate(true);bad.rooms[0].magic_state[key]=invalid;ck(not ReplaySnapshot.valid(bad),"invalid magic state rejects "+key)
 var bad=data.duplicate(true);bad.rooms[0].magic_state.stored=116;ck(not ReplaySnapshot.valid(bad),"storage above actual machine cap rejects")
 bad=data.duplicate(true);bad.rooms[0].magic_state.shield=43;ck(not ReplaySnapshot.valid(bad),"shield above actual machine cap rejects")
 bad=data.duplicate(true);bad.rooms[0].erase("magic_state");ck(not ReplaySnapshot.valid(bad),"magic machine requires state header")
 var old=data.duplicate(true);old.rooms[0].buildings=[];old.rooms[0].erase("magic_state");ck(ReplaySnapshot.valid(old),"old room without new machines safely defaults missing state")
func ability_actual():
 for kind in ["witch","electric","storm"]:
  for map in MapCatalog.IDS:
   var m=fixture(kind,map);var h=m.hunter;var r=m.player();h.arcane.cooldown=0;h.cooldown=100;m.wrath.recovery=100
   var before=r.door_hp;h.tick(.05,m)
   ck(h.arcane.action!="" and h.arcane.warning>0,"actual Hunter pipeline starts warning "+kind)
   near(r.door_hp,before,"warning has no early damage")
   for i in range(35):m.tick(.05)
   ck(not h.arcane.casts.is_empty() and r.door_hp<before,"actual model ticks execute typed ability "+kind+"/"+map)
   ck(h.arcane.cooldown>10,"ability has finite cooldown")
   if kind=="electric":
    ck(r.magic_state.disrupt>0,"actual electric disruption active")
    r.magic_state.disrupt_guard=0;MagicDefense.tick(m,3.1);near(r.magic_state.disrupt,0,"electric disruption automatically expires")
   var ev=m.presentation_events.filter(func(e):return e.type=="arcane_impact")
   ck(not ev.is_empty() and ev[-1].damage_type=="magic","actual impact has explicit Magic type")
 var m=fixture("witch");var r=m.player();var h=m.hunter
 h.arcane.cooldown=0;h.tick(.05,m);h.position=r.door_approach()+Vector2(500,0)
 for i in range(40):h.arcane.tick(h,m,.05)
 near(r.door_hp,r.max_hp(),"Witch cannot resolve out-of-range illegal projectile")
 m=fixture();h=m.hunter;r=m.player();h.transformed=true;h.hp=h.max_hp*.6;h.arcane.cooldown=0;h.cooldown=100;m.wrath.recovery=100
 var hp=h.hp;var door=r.door_hp;h.tick(.05,m)
 for i in range(35):m.tick(.05)
 ck(r.door_hp<door and h.hp>hp,"actual transformed Reaper SoulDrain damage and healing")
 ck(h.hp-hp<=h.max_hp*.015+.0001,"bounded Reaper drain heal")
 h.arcane.cooldown=0;h.state=HunterState.State.MOVE;h.position=r.door_approach()+r.door_normal()*60;h.tick(.05,m)
 ck(h.arcane.action=="shadow_dash","actual Reaper MOVE warns dash")
 var start=h.position
 for i in range(20):m.tick(.05)
 ck(h.arcane.dash>0 and h.position.distance_to(start)>0,"warned dash actually moves through model navigation")
 ck(m.navigation_walkable(h.position),"dash cannot cross wall")
 for pose in ["idle","walk","attack","hurt","defend","special","death"]:
  for kind in StrategyCatalog.ARCHETYPE_IDS:ck(ResourceLoader.exists("res://assets/hunters/%s_%s.svg" % [kind,pose]),"state-bound original asset exists")
 for i in range(4):ck(ResourceLoader.exists("res://assets/boss/reaper_%d.svg" % i),"existing Reaper animated robe retained")
func run():
 numeric();reflection();storage_and_shield();economy();items();source_save();ability_actual()
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/qa-combat-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"economy_cases":execution}," "))
 print("OVERHAUL_QA_COMBAT_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
