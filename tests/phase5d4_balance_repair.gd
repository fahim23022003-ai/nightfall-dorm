extends SceneTree
# Controlled fixtures isolate actual economic/healing handlers; no natural-play claim.
var rows=[]
var failures=0
func _initialize():call_deferred("run")
func fixture(kind,branch,level,factor,count=1):
 var m=MatchModel.new();m.reset(107)
 var r=m.rooms[0];m.player_room=0;r.owner=0;r.alive=true;r.sleeping=true;r.closed=true;r.strategy_enabled=true;r.bed_level=9;r.door_level=9;r.door_hp=r.max_hp()*.1;r.gold=5000;r.electricity=5000;r.repair_factor=factor
 for t in range(count):r.buildings[t]={"kind":kind,"level":level,"specialization":branch,"cooldown":0.0,"flash":0.0,"invested_gold":0.0,"invested_power":0.0,"instance_id":t+1}
 var hp=r.door_hp;var g=r.gold;var e=r.electricity;var healed=0.0;var activation=0;var sample=[]
 for i in range(300):
  var before=r.door_hp
  if kind=="repair":r.tick_economy(.1)
  else:m.defenses.tick(.1,m)
  healed+=r.door_hp-before
  if i in [0,9,29,49,99,299]:sample.append({"seconds":(i+1)*.1,"healed":healed,"power_spent":e-r.electricity,"gold_spent":g-r.gold+(r.income_total if kind=="repair" else 0)})
 var expected=BuildingStats.machine_stats(m,r,r.buildings[0])
 if healed<=0 or r.door_hp>r.max_hp() or r.gold<0 or r.electricity<0:failures+=1
 return {"kind":kind,"branch":branch,"level":level,"siege_factor":factor,"station_count":count,"actual_healed30s":healed,"power_spent":e-r.electricity,"gold_spent":g-r.gold+(r.income_total if kind=="repair" else 0),"expected_stats":expected,"samples":sample}
func run():
 for factor in [1.0,.35]:
  for level in [5,10]:
   for data in [["repair","conservation"],["repair","sustain"],["auto_repair","efficient_mending"],["auto_repair","emergency_protocol"]]:rows.append(fixture(data[0],data[1],level,factor))
 var single=fixture("auto_repair","efficient_mending",10,.35);var doubled=fixture("auto_repair","efficient_mending",10,.35,2)
 if absf(single.actual_healed30s-doubled.actual_healed30s)>.01 or absf(single.gold_spent-doubled.gold_spent)>.01:failures+=1
 rows.append(doubled)
 var out={"scope":"Controlled fixtures, prepaid5000G/E, real RoomState.tick_economy vs DefenseEffects.tick only. Starts10% doorHP.30s, no damage, no income for AutoRepair. OldRepair income removed from spending ledger. No natural survival claim.","rows":rows,"failures":failures}
 var f=FileAccess.open("res://docs/evidence/phase5d4/balance-repair-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(out," "));f.close()
 print("PHASE5D4_REPAIR_CASES=",rows.size()," FAILURES=",failures)
 quit(1 if failures else 0)
