class_name EconomyLedger
extends RefCounted
# Exact flow accounting. Residual direct effects are explicitly classified, never production.
var totals={"production_g":0.0,"production_e":0.0,"other_g":0.0,"other_e":0.0,"spent_g":0.0,"spent_e":0.0,"refund_g":0.0,"refund_e":0.0,"loss_g":0.0,"loss_e":0.0,"repair_g":0.0}
var records=[]
var owner: WeakRef
var expected=[25.0,0.0]
var clock=0.0
var wall_started=Time.get_ticks_usec()
var source="unclassified direct transfer (not production)"
func note(group: String,value,label: String):
 var g=float(value[0]) if value is Array else float(value.x)
 var e=float(value[1]) if value is Array else float(value.y)
 if g==0 and e==0:return
 for entry in [["g",g],["e",e]]:totals[group+"_"+entry[0]]+=entry[1]
 var sign_value=-1 if group in ["spent","loss"] else 1
 expected[0]+=g*sign_value;expected[1]+=e*sign_value
 var context={}
 var r=owner.get_ref() if owner!=null else null
 if r!=null and r.balance_version==2:
  var machines={}
  for id in r.buildings:machines[str(id)]={"kind":r.buildings[id].kind,"level":r.buildings[id].level,"branch":r.buildings[id].get("specialization","")}
  context={"bed":r.bed_level+1,"door":r.door_level+1,"machines":machines,"gold_rate":r.income_rate(),"electricity_rate":BuildingStats.room_power_rate(null,r),"trait":r.trait_id,"bed_branch":r.bed_branch,"door_branch":r.door_branch,"permanent_income":r.income_multiplier,"permanent_power":r.power_multiplier,"temporary_income":r.temporary_income,"run_perks":r.run_effects.duplicate(true),"threat_income":r.threat_income_factor,"production_paused":r.production_paused}
 records.append({"context":context,"simulation_time":clock,"wall_seconds":(Time.get_ticks_usec()-wall_started)/1e6,"source":label,"destination":group,"gold":g,"electricity":e})
 if records.size()>128:records.pop_front()
func reconcile(room,time: float):
 clock=time
 var g=room.gold-expected[0];var e=room.electricity-expected[1]
 if g>1e-8 or e>1e-8:note("other",[maxf(0,g),maxf(0,e)],source)
 if g< -1e-8 or e< -1e-8:note("loss",[maxf(0,-g),maxf(0,-e)],source)
 expected=[room.gold,room.electricity]
func snapshot() -> Dictionary:return {"totals":totals.duplicate(true),"expected":expected.duplicate()}
static func valid(data) -> bool:
 if not data is Dictionary or not data.get("totals") is Dictionary or not data.get("expected") is Array or data.expected.size()!=2 or not ReplaySnapshot.number(data.expected[0]) or not ReplaySnapshot.number(data.expected[1]):return false
 var fresh=EconomyLedger.new()
 if data.totals.size()!=fresh.totals.size():return false
 for key in fresh.totals:
  if not ReplaySnapshot.number(data.totals.get(key)):return false
 return true
func restore(data):totals=data.totals.duplicate(true);expected=data.expected.duplicate()
