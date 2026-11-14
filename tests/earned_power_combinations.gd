extends "res://tests/earned_power.gd"
func run():
 var m=MatchModel.new();m.configure_endless("abandoned_dorm","standard",19,19,RankCatalog.bonuses(["dreamer","capacitor"]));m.configure_balance(2);m.claim_room(2);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
 # Prepared maximum compatible configuration; never a fresh-run progression claim.
 r.gold=10000000;r.electricity=10000000;r.bed_level=9;r.door_level=9;r.bed_branch="lucid";r.door_branch="bulwark";r.door_hp=r.max_hp()
 for tier in range(1,8):check(m.expansion.purchase(m),"legal paid capacity")
 var first=-1
 for kind in ["generator","repair","economy","economy","economy","turret"]:
  var id=add(m,kind);check(id>=0,"paid legal composition "+kind)
  if kind=="economy":first=id
  while r.buildings[id].level<10:check(m.specialize_building(id,"dividend" if kind=="economy" else StrategyCatalog.branches(kind)[0]) if r.buildings[id].level==4 else m.upgrade_building(id),"paid full infrastructure ladder")
 var before=[r.gold,r.electricity];check(add(m,"economy")==-1 and before==[r.gold,r.electricity],"fourth amplifier rejected before any charge")
 m.choices.selected=["ledger","workshop","discipline"];m.choices.apply(m)
 var steady=r.income_rate();var amplifier=BuildingStats.amplifier_bonus(r)
 check(amplifier>2 and amplifier<2.3 and steady<500,"strongest compatible income budget bounded, not wallet-dependent")
 var shop_snapshot=m.choices.snapshot();shop_snapshot.offers=[{"id":"pillow","gold":4000,"power":3,"left":1}]
 check(RunChoices.valid(shop_snapshot,0),"late Pillow price up to4000 survives checkpoint validation")
 shop_snapshot.offers[0].gold=4001;check(not RunChoices.valid(shop_snapshot,0),"out-of-bound merchant price safely rejected")
 var original_wallet=r.gold;r.gold*=2;check(r.income_rate()==steady,"production is not interest on wallet")
 r.gold=original_wallet;m.items.apply("pillow",m);m.items.tick(.1,m)
 check(r.temporary_income==1.5 and r.income_rate()<750,"real Pillow combines with perks/traits/branches within bounded rates")
 for i in range(260):m.items.tick(.1,m)
 check(r.temporary_income==1 and absf(r.income_rate()-steady)<.00001,"temporary production cleanly expires")
 var rates=[]
 for step in [.025,.05,.1,.2]:
  var room=RoomState.new();room.balance_version=2;room.sleeping=true
  for i in range(roundi(60/step)):room.tick_economy(step)
  rates.append(room.gold)
 check(absf(rates.max()-rates.min())<.000001,"60s production independent of frame rate/delta")
 var c=m.choices;c.selected=["workshop","mixed"];c.apply(m)
 check(r.run_effects.income==1.08,"actual distinct-support composition earns bounded bonus")
 var magic=add(m,"heavy");c.apply(m)
 check(magic>=0 and r.run_effects.damage==1.08,"actual Physical/Magic composition earns hit bonus")
 c.selected=["grid"];c.used={};c.apply(m)
 for i in range(3):check(add(m,"generator")>=0,"three actual discounted infrastructure purchases")
 check(int(c.used.grid)==3 and r.quote_build("generator")==BalanceRules.price("generator",2),"fourth purchase receives no stale discount")
 c.selected=["discipline"];r.door_hp=r.max_hp();var gold=r.gold;c.paid_wave=0;c.finish(m);var bonus=r.gold-gold;c.finish(m)
 check(bonus>0 and bonus<=80 and r.gold==gold+bonus,"discipline only once per encounter, bounded actual reward")
 var fresh_model=fresh();fresh_model.time=fresh_model.preparation+1;var door=fresh_model.player();fresh_model.hunter.state=HunterState.State.ATTACK;fresh_model.hunter.target=0;fresh_model.hunter.position=door.door_approach();fresh_model.pressure.hits=0
 for i in range(500):fresh_model.pressure.tick(fresh_model,.1)
 check(fresh_model.pressure.stacks==0,"blocked/fake engagement without actual hits grants no pressure")
 fresh_model.pressure.hits=100
 for i in range(600):fresh_model.pressure.tick(fresh_model,.1)
 check(fresh_model.pressure.stacks==2 and fresh_model.pressure.factor(fresh_model)<1.5,"real credited engagement bounded to two telegraphed stacks")
 var before_pressure=fresh_model.pressure.stacks;fresh_model.hunter.transformed=true
 for i in range(400):fresh_model.pressure.tick(fresh_model,.1)
 check(fresh_model.pressure.stacks==before_pressure,"no additional Reaper stacking or recovery loop")
 var f=FileAccess.open("res://docs/evidence/earned-power/strongest-combination.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"steady_gold_per_second":steady,"pillow_max_gold_per_second":steady*1.5,"effective_amplifier":amplifier,"permanent_loadout":["dreamer","capacitor"],"description":"Prepared paid legal Bed10/Lucid, three Dividend amplifiers10, actual Prosperous room, two income run perks, existing Pillow. No claim of fresh affordability. All extra wallet funds explicitly test fixtures."}," "))
 print("EARNED_COMBINATION_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
