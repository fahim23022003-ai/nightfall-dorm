extends SceneTree
# Independent paid-transaction invariants. Injected budgets are not balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://premium-economy-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PREMIUM ECONOMY: "+label)
func state(m,p):
 var r=m.player()
 return [r.gold,r.electricity,r.buildings.duplicate(true),r.coupon_armed,r.construction_actions,p.inventory.duplicate(true)]
func fixture(kind):
 serial+=1
 var p=PlayerProfile.new(prefix+str(serial)+".json")
 p.inventory.coupon=3;p.item_loadout=["coupon"]
 var entry=p.begin_match("standard")
 var m=MatchModel.new();m.configure_match("standard");m.configure_stage("stage_1")
 check(m.configure_strategy(0,"crusher","",entry.id),"strategy fixture configures once")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+1;m.bot_claimed=5
 var r=m.player();r.gold=100000;r.electricity=100000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
 p.bind_items(m,entry.id)
 return {"m":m,"p":p,"id":entry.id,"kind":kind}
func arm(a):
 check(a.p.activate_item(0,a.m,a.id),"coupon arms through actual inventory activation")
 check(a.p.inventory.coupon==3,"arming coupon spends no stock")
func run():
 for kind in Catalog.BUILDINGS:
  for branch in StrategyCatalog.branches(kind):
   for discount in ["none","base","branch","later"]:
    var a=fixture(kind);var m=a.m;var p=a.p;var r=m.player()
    # Wallets are float64 scalars; Vector2 snapshots lose fractional small debits
    # beside 100,000 through float32 cancellation. Keep each actual price separately.
    var starting=[r.gold,r.electricity]
    var payments=[]
    if discount=="base":arm(a)
    check(m.buy(kind,0),"paid purchase "+kind)
    payments.append(Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power)*(.6 if discount=="base" else 1))
    var before=state(m,p)
    check(not m.specialize_building(0,branch) and state(m,p)==before,"cannot specialize before milestone")
    for old_level in range(1,4):
     payments.append(Catalog.upgrade_cost(kind,old_level))
     check(m.upgrade_building(0),"ordinary paid tiers reach level4")
    before=state(m,p)
    check(not m.upgrade_building(0) and state(m,p)==before,"level4 requires an explicit single branch")
    for invalid in ["", "missing", "focus" if kind=="turret" else "precision"]:
     check(not m.specialize_building(0,invalid) and state(m,p)==before,"invalid/wrong-kind branch is atomic")
    if discount=="branch":
     arm(a)
     var saved_path=p.path;p.path=prefix+"missing/never-created.json"
     before=state(m,p)
     check(not m.specialize_building(0,branch) and state(m,p)==before,"failed coupon save cancels branch, stock, wallet and level")
     p.path=saved_path
    var quote=(Catalog.upgrade_cost(kind,4)+StrategyCatalog.BRANCH_FEE)*(.6 if discount=="branch" else 1)
    before=state(m,p);r.electricity=quote.y-.5
    var insufficient=state(m,p)
    check(not m.specialize_building(0,branch) and state(m,p)==insufficient,"insufficient electricity cannot consume or partially debit")
    r.electricity=before[1]
    payments.append(quote)
    check(m.specialize_building(0,branch),"paid choice advances to5 "+branch)
    check(r.buildings[0].level==5 and r.buildings[0].specialization==branch,"exactly one branch installed")
    before=state(m,p)
    for alternative in StrategyCatalog.branches(kind):
     check(not m.specialize_building(0,alternative) and state(m,p)==before,"branch cannot repeat or switch")
    for old_level in range(5,10):
     if discount=="later" and old_level==7:arm(a)
     payments.append(Catalog.upgrade_cost(kind,old_level)*(.6 if discount=="later" and old_level==7 else 1))
     check(m.upgrade_building(0),"specialized tower progresses to10")
    check(r.buildings[0].level==10 and r.buildings[0].specialization==branch,"level10 retains locked branch")
    before=state(m,p)
    check(not m.upgrade_building(0) and state(m,p)==before,"no level11 or maximum-tier debit")
    var gold_paid=0.0;var power_paid=0.0
    for payment in payments:gold_paid+=payment.x;power_paid+=payment.y
    check(absf(starting[0]-r.gold-gold_paid)<.00001 and absf(starting[1]-r.electricity-power_paid)<.00001,"actual Gold/Electricity debits match paid base/tiers/fee")
    check(absf(r.buildings[0].invested_gold-gold_paid)<.00001 and absf(r.buildings[0].invested_power-power_paid)<.00001,"separate ledgers record actual discounted investment")
    var refund=r.building_refund(0)
    check(refund==Vector2(r.buildings[0].invested_gold,r.buildings[0].invested_power)*.5,"exact 50% eligible actual investment quoted")
    var wallet=[r.gold,r.electricity]
    check(m.sell_building(0) and absf(r.gold-wallet[0]-refund.x)<.00001 and absf(r.electricity-wallet[1]-refund.y)<.00001,"one sale transfers exact actual half refund")
    before=state(m,p)
    check(not m.sell_building(0) and state(m,p)==before,"duplicate sale never refunds")
    check(m.buy(kind,0),"sold pad reuses for fresh unspecialized building")
    check(not r.buildings[0].has("specialization"),"reused pad inherits no old branch")
    check(m.sell_building(0) and r.gold<starting[0] and r.electricity<=starting[1],"buy/sell cycle cannot create resources")
    check(p.inventory.coupon==(3 if discount=="none" else 2),"exactly one coupon consumed only by successful discount")
    before=state(m,p);m.running=false
    check(not m.specialize_building(0,branch) and state(m,p)==before,"paused branch action is atomic")
    m.running=true;m.result="defeat"
    check(not m.buy(kind,0) and state(m,p)==before,"terminal purchase is atomic")
 var d=DirAccess.open("user://")
 for file in d.get_files():
  if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
 print("PHASE5D3_ECONOMY_QA_CHECKS=",checks," SCENARIOS=48 FAILURES=",failures)
 quit(0 if failures==0 else 1)
