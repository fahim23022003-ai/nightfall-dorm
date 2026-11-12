extends SceneTree
# Controlled economic reachability: earned bed/generator resources, no injected currency.
# This workshop has no active Hunter; separate full-match combat simulations assess survival.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("HAUNTED ECONOMY: "+label)
func has(r,kind):
 for tile in r.buildings:
  if r.buildings[tile].kind==kind:return tile
 return -1
func act(r,kind):
 var gen=has(r,"generator")
 if gen<0:r.build("generator",0);return
 if r.bed_level<1:r.upgrade_bed();return
 if r.door_level<1:r.upgrade_door();return
 if r.buildings[gen].level<2:r.upgrade_building(gen);return
 if r.bed_level<2:r.upgrade_bed();return
 if r.door_level<2:r.upgrade_door();return
 if r.buildings[gen].level<4:r.upgrade_building(gen);return
 if r.bed_level<3:r.upgrade_bed();return
 if r.door_level<3:r.upgrade_door();return
 if r.bed_level<4:r.upgrade_bed();return
 if r.door_level<4:r.upgrade_door();return
 var target=has(r,kind)
 if target<0:r.build(kind,1);return
 r.upgrade_building(target)
func run():
 var rows=[]
 for kind in ["turret","heavy"]:
  for boosted in [false,true]:
   var r=RoomState.new(0);r.owner=0;r.sleeping=true;r.closed=true
   if boosted:r.apply_boosts(RankCatalog.bonuses(["dreamer","capacitor"]))
   var seconds=0
   while seconds<1800:
    r.tick_economy(.5);act(r,kind)
    var target=has(r,kind)
    check(r.gold>=0 and r.electricity>=0,"nonnegative earned economy")
    check(is_equal_approx(r.gold+r.spent,25+r.income_total),"actual generated Gold conserved")
    seconds+=1
    if target>=0 and r.buildings[target].level==10:break
   var target=has(r,kind)
   check(target>=0 and r.buildings[target].level==10,"earned L10 within suitable extended economy "+kind)
   var row={"kind":kind,"perks":boosted,"seconds":seconds*.5,"gold_generated":r.income_total,"gold_remaining":r.gold,"electricity_remaining":r.electricity,"gold_invested":r.building_refund(target).x*2 if target>=0 else 0,"power_invested":r.building_refund(target).y*2 if target>=0 else 0,"level":r.buildings[target].level if target>=0 else 0}
   rows.append(row);print("HAUNTED_ECONOMY_RUN ",JSON.stringify(row))
 var result={"checks":checks,"failures":failures,"rows":rows,"controlled_no_hunter":true}
 var file=FileAccess.open("res://docs/evidence/haunted/economy-results.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(result," "))
 print("HAUNTED_ECONOMY_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
