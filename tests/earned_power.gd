extends SceneTree
var checks=0
var failures=0
func check(ok,text):
 checks+=1
 if not ok:failures+=1;push_error("EARNED POWER: "+text)
func _initialize():call_deferred("run")
func fresh(version=2):
 var m=MatchModel.new();m.configure_endless("abandoned_dorm","standard",71,71);check(m.configure_balance(version),"explicit run version")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();return m
func prepared():
 var m=fresh();var r=m.player();r.gold=200000;r.electricity=200000;r.bed_level=9;r.door_level=9;r.bed_branch="lucid";r.door_branch="bulwark";r.door_hp=r.max_hp();r.ledger.reconcile(r,0);return m
func add(m,kind):
 var r=m.player()
 for i in range(r.tile_count()):
  if not r.buildings.has(i) and m.buy(kind,i):return i
 return -1
func clear(m):
 var r=m.player();var id=r.buildings.keys().filter(func(k):return r.buildings[k].kind=="turret")[0] if r.buildings.values().any(func(v):return v.kind=="turret") else add(m,"turret");check(id>=0,"paid real weapon to clear fixture")
 m.time=m.preparation+.1;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=99;m.hunter.hp=1;m.hunter.boss_policy.enabled=false
 for i in range(100):
  m.tick(.1)
  if m.endless.phase=="intermission":break
 check(m.endless.phase=="intermission","actual projectile clears prepared test encounter")
func run():
 var a=fresh(1);var b=fresh(2)
 check(a.player().gold==b.player().gold and b.player().gold==25,"opening money unchanged; no injection")
 check(a.player().income_rate()>b.player().income_rate() and BalanceRules.price("generator",2)==Vector2(120,0),"actual new income/infrastructure prices")
 var r=b.player();var before=[r.gold,r.electricity,r.buildings.duplicate(true)]
 check(add(b,"generator")==-1 and before==[r.gold,r.electricity,r.buildings],"failed unaffordable building atomic")
 for i in range(100):b.tick(.1)
 check(r.income_total>0 and r.gold<100,"delta scaled fresh actual income")
 var frozen=[b.time,r.gold,r.electricity];b.running=false;b.tick(20);check([b.time,r.gold,r.electricity]==frozen,"pause cannot farm")
 b.running=true
 var m=prepared();r=m.player();var generator=add(m,"generator");check(generator>=0,"Dynamo purchased")
 var amp=add(m,"economy");check(amp>=0,"amplifier with actual Dynamo prerequisite")
 var id=add(m,"turret");r.bed_level=0;r.door_level=0;var paid=r.gold
 check(not m.upgrade_building(id) or r.buildings[id].level==2,"accessible L2 weapon")
 check(not m.upgrade_building(id) and r.gold<=paid,"new high-tier prerequisite rejects")
 r.bed_level=9;r.door_level=9
 for target in [generator,amp,id]:
  while r.buildings[target].level<10:
   var entry=r.buildings[target];check(m.specialize_building(target,StrategyCatalog.branches(entry.kind)[0]) if entry.level==4 else m.upgrade_building(target),"paid ten-tier path")
 check(not m.upgrade_building(id),"no Level11")
 var raw=BalanceRules.output("economy",10,2)*1.3*3
 check(is_equal_approx(BalanceRules.amplifier(3*2.45*1.3,1),10.555),"baseline reported amplifier shortcut reproduced")
 check(BalanceRules.amplifier(raw,2)<3 and BalanceRules.amplifier(raw+.01,2)>BalanceRules.amplifier(raw,2),"bounded but strictly useful marginal amplification")
 var invested=Vector2(r.buildings[amp].invested_gold,r.buildings[amp].invested_power);var wallet=Vector2(r.gold,r.electricity)
 check(m.sell_building(amp) and (Vector2(r.gold,r.electricity)-wallet).distance_to(invested*.5)<.05,"refund exactly half actual paid investment")
 check(not m.sell_building(amp),"no duplicate refund")
 check(RunChoices.CATALOG.size()==12,"twelve distinct curated run perks")
 # Real mechanics in prepared test fixtures, not balance/playability evidence.
 m=prepared();r=m.player();add(m,"generator");id=add(m,"turret")
 var c=m.choices
 c.selected=["ledger","cadence","rhythm"];c.apply(m)
 var stats=BuildingStats.weapon_stats(m,r,r.buildings[id]);check(stats.hit>Catalog.BUILDINGS.turret.damage and stats.interval>Catalog.BUILDINGS.turret.interval,"damage/rate tradeoffs resolved in real shots")
 check(r.run_effects.income==1.12 and r.run_effects.power==.95,"income drawback and repair infrastructure drawback")
 r.door_hp=r.max_hp()*.4;check(r.manual_repair_cost()<30,"conditional manual repair discount")
 c.selected=["grid"];c.apply(m);var q=r.quote_build("generator");check(q==Vector2(96,0),"limited infrastructure discount quote")
 add(m,"generator");check(int(c.used.get("grid",0))==1,"only successful purchase spends discount count")
 c.selected=["mercy","beat"];c.apply(m);var old=r.door_hp
 for i in range(6):c.impact(m,100)
 check(r.door_hp>old and r.door_hp-old<=6.001 and m.hunter.suppression_remaining>0,"real hit healing budget and Sixth Beat API")
 var healed=r.door_hp
 for i in range(20):c.impact(m,100)
 check(r.door_hp==healed,"burst heal budget cannot loop instantly")
 c.selected=["latch"];c.payment=func(_id,_value):return false
 check(c.incoming(m,1e6)==1e6 and not c.used.has("latch"),"failed charge-save grants no effect or consumption")
 c.payment=Callable();check(c.incoming(m,1e6)<r.door_hp and c.used.latch==1 and c.incoming(m,1e6)==1e6,"one emergency protection charge only")
 c.selected=["reserve"];r.door_hp=r.max_hp()*.3;old=r.electricity
 check(c.activate(m,"reserve") and r.electricity==old+20 and not c.activate(m,"reserve"),"limited emergency Electricity not repeatable")
 c.selected=["thorns"];var hp=m.hunter.hp;m.hunter.state=HunterState.State.ATTACK;c.retaliate(m,1000);c.retaliate(m,1000)
 check(hp-m.hunter.hp<=12.001,"retaliation burst budget bounded")
 clear(m);c.prepare(m);var offered=c.snapshot();c.prepare(m);check(c.snapshot()==offered,"no draft/shop reroll on reopen")
 var funds=Vector2(r.gold,r.electricity);var offer=c.offers[0];check(c.buy(m,offer.id),"real merchant purchase")
 check(not c.buy(m,offer.id) and Vector2(r.gold,r.electricity).distance_to(funds-Vector2(offer.gold,offer.power))<.05,"one stock, correct charge, double-buy rejected")
 var snapshot=ReplaySnapshot.encode(m);check(not snapshot.is_empty(),"new2 checkpoint validates with balance/choices/ledger")
 var serialized=JSON.parse_string(JSON.stringify(snapshot));var loaded=ReplaySnapshot.restore(serialized)
 check(loaded!=null and loaded.balance_version==2 and loaded.choices.selected==c.selected and loaded.choices.draft==c.draft and int(loaded.choices.stock[offer.id])==int(c.stock[offer.id]) and absf(loaded.choices.heal_tokens-c.heal_tokens)<1e-8,"new2 JSON reload retains generated choices/stock and bounded float clocks")
 var signature=[m.time,r.gold,r.electricity,c.snapshot()];m.tick(.2);check(signature==[m.time,r.gold,r.electricity,c.snapshot()],"intermission freezes resources and perk token clocks")
 if not c.draft.is_empty():
  var choice=c.draft[0];check(c.choose(m,choice) and not c.choose(m,choice),"one draft selection cannot duplicate")
 var hash=FileAccess.get_sha256("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json")
 var legacy=ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json")))
 check(legacy!=null and legacy.balance_version==1 and legacy.player().buildings.size()>0 and legacy.player().gold>100000,"earned45 legacy path retains wealth/buildings")
 check(FileAccess.get_sha256("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json")==hash,"earned evidence byte preserved")
 print("EARNED_POWER_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
