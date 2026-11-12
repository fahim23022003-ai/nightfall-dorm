extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("STRUCTURE QA: "+label)
func _initialize():call_deferred("run")
func room():
 var r=RoomState.new();r.owner=0;r.sleeping=true;r.closed=true;r.strategy_enabled=true;r.gold=100000;r.electricity=100000;r.door_hp=r.max_hp();return r
func signature(r):return [r.gold,r.electricity,r.bed_level,r.door_level,r.bed_branch,r.door_branch,r.door_hp,r.buildings.duplicate(true)]
func run():
 for bed in ["lucid","conductor"]:
  for door in ["bulwark","renewal"]:
   var r=room();var gold=r.gold;var power=r.electricity;var g=0.0;var e=0.0
   for level in range(4):
    g+=Catalog.BED_COST[level]+Catalog.DOOR_COST[level];e+=Catalog.BED_POWER[level]+Catalog.DOOR_POWER[level]
    check(r.upgrade_bed() and r.upgrade_door(),"original firstfive structural levels preserve ordinary paid progression")
   var before=signature(r)
   check(not r.upgrade_bed() and not r.upgrade_door() and signature(r)==before,"owned legacyL5 requires explicit late branch without charging")
   for kind in ["bed","door"]:
    check(not r.specialize_structure(kind,"missing") and not r.specialize_structure(kind,"precision") and signature(r)==before,"invalid wrong-role structure branch is atomic")
   r.gold=0;var broke=signature(r)
   check(not r.specialize_structure("bed",bed) and signature(r)==broke,"failed bed payment rolls back branch and wallet")
   check(not r.specialize_structure("door",door) and signature(r)==broke,"failed door payment rolls back branch/HP and wallet")
   r.gold=before[0]
   check(r.specialize_structure("bed",bed) and r.specialize_structure("door",door),"real branch choice advances5to6 exactlyonce")
   g+=Catalog.BED_COST[4]+Catalog.DOOR_COST[4];e+=Catalog.BED_POWER[4]+Catalog.DOOR_POWER[4]
   before=signature(r)
   check(not r.specialize_structure("bed",bed) and not r.specialize_structure("door",door) and signature(r)==before,"paid structural branch cannotrepeat/switch")
   for level in range(5,9):
    check(r.upgrade_bed() and r.upgrade_door(),"all late structural levels buyvalidstats")
    g+=Catalog.BED_COST[level]+Catalog.DOOR_COST[level];e+=Catalog.BED_POWER[level]+Catalog.DOOR_POWER[level]
   check(r.bed_level==9 and r.door_level==9 and r.bed_branch==bed and r.door_branch==door,"both actual structures retainchosenbranch atLevel10")
   check(absf(gold-r.gold-g)<.00001 and absf(power-r.electricity-e)<.00001,"complete structural Gold/E costs match all nine actual paid tiers")
   before=signature(r)
   check(not r.upgrade_bed() and not r.upgrade_door() and signature(r)==before,"no structuralLevel11 or maximumcharge")
   var base_income=135.0;var rate=r.income_rate()
   check(is_equal_approx(rate,base_income*(1.25 if bed=="lucid" else .85)),"bed branch modifies realoccupied income")
   var old_power=r.electricity;r.tick_economy(1)
   check(is_equal_approx(r.electricity-old_power,5.4 if bed=="conductor" else 0.0),"Conductor addsactualoccupied electricity conversion")
   r.sleeping=false;old_power=r.electricity;var old_gold=r.gold;r.tick_economy(1)
   check(r.electricity==old_power and r.gold==old_gold,"bedbranch never producesresources from unoccupiedbed")
   r.sleeping=true;r.door_hp=r.max_hp()/2;var hp=r.door_hp;old_gold=r.gold
   check(r.repair_door() and is_equal_approx(r.door_hp-hp,56 if door=="bulwark" else 105) and r.gold==old_gold-12,"actual manualrepair reflects defensive tradeoff and spending")
   r.door_hp=0;before=signature(r)
   check(not r.repair_door() and not r.upgrade_door() and signature(r)==before,"specialized destroyed doors cannotrevive throughrepair/upgrade")
 # Support effects are independently checked through real tick calculations.
 var r=room();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.build("generator",0)
 for i in range(3):r.upgrade_building(0)
 check(r.specialize_building(0,"overcharge"),"realovercharge purchased")
 var income=r.income_rate();var power=r.electricity;r.tick_economy(1)
 check(is_equal_approx(income,20.8) and is_equal_approx(r.electricity-power,12),"Overcharge trades20% income foractual60% greaterLevel5power")
 for i in range(1,6):
  r.build("economy",i)
  for n in range(3):r.upgrade_building(i)
  r.specialize_building(i,"capacitive")
 check(r.special_factor("power",.55,1.5)==1.5,"multiple capacitor branches reachexplicitpowercap ratherthanmultiplyunbounded")
 r=room();r.door_level=4;r.bed_level=4;r.door_hp=500;r.build("repair",0)
 for n in range(3):r.upgrade_building(0)
 r.specialize_building(0,"sustain");r.electricity=0;var hp=r.door_hp;r.tick_economy(1)
 check(r.door_hp==hp and r.electricity==0,"powered healing stopswithoutElectricity")
 r.electricity=2;hp=r.door_hp;r.tick_economy(1)
 check(is_equal_approx(r.door_hp-hp,47.25) and is_equal_approx(r.electricity,.75),"Suturesactualhealingdebited1.25Electricity")
 r.door_hp=0;r.tick_economy(1);check(r.door_hp==0,"support branch cannot resurrectdestroyeddoor")
 r=room();r.bed_level=4;r.door_level=4
 for i in range(4):
  r.build("repair",i)
  for n in range(3):r.upgrade_building(i)
  r.specialize_building(i,"conservation")
 check(is_equal_approx(r.manual_repair_cost(),7.2),"stackedrepairdiscountbounded40percent")
 print("PHASE5D3_STRUCTURAL_QA_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
