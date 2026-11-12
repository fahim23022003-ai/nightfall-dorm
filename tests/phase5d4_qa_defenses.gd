extends "res://tests/phase5d4_qa_evolution.gd"
# Nominal fractional prices cross Godot Vector2 float32; allow <0.001 unit
# for nominal sums, while actual sale transfer must equal quoted float64 debit <1e-8.
var prefix="user://phase5d4-qa-defense-"+str(Time.get_ticks_usec())
var serial=0
func paid(kind,branch,discount="none"):
 serial+=1;var p=PlayerProfile.new(prefix+str(serial)+".json");p.inventory.coupon=2;p.item_loadout=["coupon"];var entry=p.begin_match("hell")
 var m=fixture(67);p.bind_items(m,entry.id);var r=m.player();r.gold=1000000;r.electricity=100000;r.bed_level=9;r.bed_branch="lucid";r.door_level=9;r.door_branch="renewal";r.door_hp=r.max_hp()
 var start=[r.gold,r.electricity];var expected_gold=0.0;var expected_power=0.0
 if discount=="base":check(p.activate_item(0,m,entry.id),"real coupon arms for base purchase")
 check(m.buy(kind,0),"actual paid new machine buys "+kind)
 var factor=.6 if discount=="base" else 1.0;expected_gold+=Catalog.BUILDINGS[kind].gold*factor;expected_power+=Catalog.BUILDINGS[kind].power*factor
 for level in range(1,10):
  if discount=="branch" and level==4:check(p.activate_item(0,m,entry.id),"real coupon arms for exclusive branch")
  if discount=="later" and level==7:check(p.activate_item(0,m,entry.id),"real coupon arms for late tier")
  var cost=Catalog.upgrade_cost(kind,level)+(StrategyCatalog.BRANCH_FEE if level==4 else Vector2.ZERO)
  factor=.6 if discount=="branch" and level==4 or discount=="later" and level==7 else 1.0
  expected_gold+=cost.x*factor;expected_power+=cost.y*factor
  check(m.specialize_building(0,branch) if level==4 else m.upgrade_building(0),"new role actual paid advancement "+kind+str(level+1))
 var b=r.buildings[0]
 check(b.level==10 and b.specialization==branch,"new role level10 retains one exclusive branch")
 print("QA_PRICE ",kind," ",branch," ",discount," debit_error=",[start[0]-r.gold-expected_gold,start[1]-r.electricity-expected_power]," ledger_error=",[b.invested_gold-expected_gold,b.invested_power-expected_power]," half_quote_error=",[r.building_refund(0).x-b.invested_gold*.5,r.building_refund(0).y-b.invested_power*.5])
 check(absf(start[0]-r.gold-expected_gold)<.001 and absf(start[1]-r.electricity-expected_power)<.001,"independent summed prices equal actual separate wallet debits")
 check(absf(b.invested_gold-expected_gold)<.001 and absf(b.invested_power-expected_power)<.001,"only real discounted purchase/upgrade/branch investment enters ledger")
 var stock=p.inventory.duplicate(true);var before=[r.gold,r.electricity,b.duplicate(true)]
 check(not m.upgrade_building(0) and not m.specialize_building(0,branch) and [r.gold,r.electricity,b]==before and p.inventory==stock,"level11 and duplicatebranch rejected atomically")
 return {"m":m,"p":p,"entry":entry,"g":expected_gold,"e":expected_power}
func accounting():
 for kind in DefenseEffects.SPECIAL:
  for branch in StrategyCatalog.branches(kind):
   for discount in ["base","branch","later"]:
    var a=paid(kind,branch,discount);var m=a.m;var r=m.player();var before=[r.gold,r.electricity]
    var quote=r.building_refund(0)
    check(is_equal_approx(quote.x,a.g*.5) and is_equal_approx(quote.y,a.e*.5),"sale quote returns50% actual discounted separate Gold/E")
    check(m.sell_building(0) and absf(r.gold-before[0]-quote.x)<.00000001 and absf(r.electricity-before[1]-quote.y)<.00000001,"actual sale transfers exact eligible half investment")
    before=[r.gold,r.electricity]
    check(not m.sell_building(0) and [r.gold,r.electricity]==before,"duplicate sale cannot refund again")
    check(m.buy(kind,0) and r.buildings[0].level==1 and not r.buildings[0].has("specialization"),"sold tile reuses without inherited branch")
    check(a.p.inventory.coupon==1,"exactly one coupon consumed by successful discounted operation")
func operations():
 for kind in ["auto_repair","shield","decoy"]:
  for branch in StrategyCatalog.branches(kind):
   var a=paid(kind,branch);var m=a.m;var r=m.player();var b=r.buildings[0];var s=m.defenses.stats(r,b);r.door_hp=r.max_hp()*.25
   m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.MOVE
   var hp=r.door_hp;var wallet=[r.gold,r.electricity];var ledger=[b.invested_gold,b.invested_power]
   m.defenses.tick(.01,m)
   check(is_equal_approx(wallet[0]-r.gold,s.get("gold",0)) and is_equal_approx(wallet[1]-r.electricity,s.power),"actual support operation spends stated separate resources "+kind+branch)
   check([b.invested_gold,b.invested_power]==ledger,"operating spend never becomes refundable capital "+kind)
   if kind=="auto_repair":check(r.door_hp>hp and is_equal_approx(r.door_hp-hp,s.heal),"paid auto repair produces measurable real healing")
   elif kind=="shield":
    check(r.barrier_hp==s.capacity and r.barrier_remaining==s.duration,"paid shield creates stated finite actual barrier")
    hp=r.door_hp;var actual=m.apply_room_damage(0,s.capacity*.5,"actual shield test",1,true)
    check(actual==0 and r.door_hp==hp and is_equal_approx(r.barrier_hp,s.capacity*.5),"finite barrier absorbs real hit exactly")
   else:
    check(m.defenses.lure_room==0 and is_equal_approx(m.defenses.lure_remaining,s.duration),"paid decoy creates finite legitimate room lure")
    var old=m.hunter.position;m.defenses.lure_tick(.1,m)
    check(m.navigation_walkable(m.hunter.position) and m.hunter.position.distance_to(old)<=m.hunter.speed*.1+.1,"lure respects actual navigation movement budget")
   wallet=[r.gold,r.electricity];hp=r.door_hp;m.defenses.tick(.01,m)
   check([r.gold,r.electricity]==wallet and r.door_hp==hp,"rapid consecutive frame cannot repeat support operation")
   var refund=r.building_refund(0);check(is_equal_approx(refund.x,ledger[0]*.5) and is_equal_approx(refund.y,ledger[1]*.5),"operating spend excluded from actual sale quote")
   check(m.sell_building(0) and m.buy(kind,0),"operated support can sell and rebuild same pad")
   wallet=[r.gold,r.electricity];hp=r.door_hp;m.defenses.tick(.01,m)
   check([r.gold,r.electricity]==wallet and r.door_hp==hp,"sale/rebuild cannot bypass shared repair/shield/lure refractory")
   if kind=="decoy":check(not m.defenses.lure_tick(.1,m),"selling original decoy cancels its stale lure even when samepad rebuilt")
   r.electricity=0;r.gold=0;m.defenses.tick(30,m);hp=r.door_hp;wallet=[r.gold,r.electricity];m.defenses.tick(.1,m)
   check([r.gold,r.electricity]==wallet and r.door_hp==hp,"no resources means no free repairs/barriers/lures "+kind)
func projectiles():
 for kind in ["flame","frost","shock"]:
  for branch in StrategyCatalog.branches(kind):
   var a=paid(kind,branch);var m=a.m;var r=m.player();var b=r.buildings[0]
   m.hunter.position=m.map_data.hunter_spawn;m.hunter.state=HunterState.State.MOVE;m.spawn_undead(3)
   var origin=r.tile_position(0)
   for i in range(3):m.minions[i].position=origin+Vector2(20+i*10,0);m.minions[i].hp=100000;m.minions[i].max_hp=100000
   var stats=BuildingStats.weapon_stats(m,r,b);var boss_hp=m.hunter.hp;var before=[]
   for u in m.minions:before.append(u.hp)
   m._turrets(.01)
   check(m.projectiles.size()==int(stats.targets),"real new weapon branch launches intended target count "+kind+branch)
   var target_ids=[]
   for shot in m.projectiles:target_ids.append(shot.target_id)
   m._advance_projectiles(1)
   var hit_count=0
   for i in range(3):
    if m.minions[i].hp<before[i]:hit_count+=1
   check(hit_count==int(stats.targets) and m.hunter.hp==boss_hp,"actual homing impacts damage correct distinct undead, not unrelated boss "+kind)
   check(r.minion_damage_dealt>0 and r.main_damage_dealt==0,"actual target-specific damage credit recorded")
   if kind=="flame":
    var hp=m.minions[0].hp;m.defenses.tick(.5,m);check(m.minions[0].hp<hp and m.defenses.burns.size()==int(stats.targets),"real flame DoT after projectile impact")
   if kind=="frost":check(m.minions[0].slow_remaining>0 and m.minions[0].slow_factor>=.65 and m.minions[0].slow_factor<1,"actual bounded minion frost slow, no freezechain")
   if kind=="shock":check(m.minions[0].slow_factor>0 and m.minions[0].slow_remaining<=1,"charged shock hit is finite slow and never immobilization")
   b.cooldown=0;m._turrets(.01)
   var stale=m.minions[0].id;m.minions[0].despawn(m);m.spawn_undead(1);var replacement=m.minions.back();var hp=replacement.hp
   m._advance_projectiles(1)
   check(m.target_by_id(stale)==null and replacement.hp==hp and m.hunter.hp==boss_hp,"inflight shots cancel dead identity rather than hitting reusedslot or boss")
func run():
 if "--operations" in OS.get_cmdline_user_args():operations()
 elif "--accounting" in OS.get_cmdline_user_args():accounting()
 else:accounting();operations();projectiles();preload("res://tests/replay_test_support.gd").cleanup(prefix)
 print("PHASE5D4_QA_DEFENSE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
