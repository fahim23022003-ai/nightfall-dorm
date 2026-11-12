extends SceneTree
var checks=0
var failures=0
func check(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func room():
 var r=RoomState.new();r.owner=0;r.sleeping=true;r.closed=true;r.strategy_enabled=true;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=1000000;r.electricity=1000000
 return r
func _initialize():call_deferred("run")
func run():
 for kind in Catalog.BUILDINGS:
  check(Catalog.building_max_level(kind)==10,"every permanent machine max10")
  for branch in StrategyCatalog.branches(kind):
   var r=room();check(r.build(kind,0),"buy "+kind)
   for level in range(1,4):check(r.upgrade_building(0),"early upgrade")
   check(not r.upgrade_building(0),"exclusive branch required")
   check(r.specialize_building(0,branch),"branch advances once")
   check(not r.specialize_building(0,branch),"cannot buy branch twice")
   for level in range(5,10):check(r.upgrade_building(0),"paid late upgrade")
   var before=Vector2(r.gold,r.electricity)
   check(not r.upgrade_building(0) and before==Vector2(r.gold,r.electricity),"no level11 charge")
   var paid=Vector2(1000000,1000000)-before;var refund=r.building_refund(0)
   check(refund.is_equal_approx(paid*.5),"separate actual investment refund")
   check(r.sell_building(0),"validsale")
   before=Vector2(r.gold,r.electricity)
   check(not r.sell_building(0) and before==Vector2(r.gold,r.electricity),"no double refund")
   check(r.build(kind,0) and r.buildings[0].level==1,"sold tile reusable")
 for kind in ["bed","door"]:
  for branch in StrategyCatalog.branches(kind):
   var r=room();check(r.specialize_structure("bed",branch if kind=="bed" else "lucid"),"bed branch advance")
   check(r.specialize_structure("door",branch if kind=="door" else "bulwark"),"door branch advance")
   for i in range(4):
    check(r.upgrade_bed(),"paid bed progression")
    check(r.upgrade_door(),"paid door progression")
   check((r.bed_level if kind=="bed" else r.door_level)==9,"structure max10")
   check(not (r.upgrade_bed() if kind=="bed" else r.upgrade_door()),"structure no11")
   check(not r.specialize_structure(kind,branch),"one structure branch")
 print("PHASE5D3_DEV_BUILDING_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
