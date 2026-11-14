extends "res://tests/earned_power.gd"
func run():
 for kind in Catalog.BUILDINGS:
  var m=prepared();var r=m.player()
  if kind in ["economy","enhancer"]:check(add(m,"generator")>=0,"owned Dynamo prerequisite")
  r.coupon_armed=true;r.coupon_payment=func(_saved):return true
  var price=r.quote_build(kind);var wallet=[r.gold,r.electricity];var id=add(m,kind)
  check(id>=0 and absf(r.gold-(wallet[0]-price.x))<.00001 and absf(r.electricity-(wallet[1]-price.y))<.00001,"discounted actual purchase "+kind)
  check(not r.coupon_armed,"coupon only spent after success "+kind)
  while r.buildings[id].level<10:
   var b=r.buildings[id];check(m.specialize_building(id,StrategyCatalog.branches(kind)[0]) if b.level==4 else m.upgrade_building(id),"actual upgrade accounting "+kind)
  check(not m.upgrade_building(id),"Level11 impossible "+kind)
  var invested=[r.buildings[id].invested_gold,r.buildings[id].invested_power];wallet=[r.gold,r.electricity]
  check(m.sell_building(id),"sale valid "+kind)
  check(absf((r.gold-wallet[0])-invested[0]*.5)<.001 and absf((r.electricity-wallet[1])-invested[1]*.5)<.001,"exact actual-spend refund Gold/E separately "+kind)
  var after=[r.gold,r.electricity];check(not m.sell_building(id) and after==[r.gold,r.electricity],"no duplicate sale "+kind)
  r.ledger.reconcile(r,m.time);var f=r.ledger.totals
  check(absf(r.gold-25-(f.production_g+f.other_g+f.refund_g-f.spent_g-f.loss_g))<.001,"full source flow reconciles wallet "+kind)
 var m=prepared();var r=m.player();var id=add(m,"turret");var investment=r.buildings[id].invested_gold;var wallet=[r.gold,r.electricity]
 check(m.begin_building_move(id) and m.move_building(r.fixed_tile_position(1)),"paid instance relocates")
 check(r.spatial.undo(m) and r.buildings[id].invested_gold==investment and wallet==[r.gold,r.electricity],"move/undo cannot duplicate income/investment")
 var serial=m.random.state;m.choices.prepare(m);check(m.random.state==serial,"reward generation independent of combat/audio random stream")
 print("EARNED_ACCOUNTING_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
