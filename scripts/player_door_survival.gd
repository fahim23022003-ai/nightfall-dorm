class_name PlayerDoorSurvival
extends RefCounted
## Campaign-only survival rules. Existing Story progression has no active
## combat snapshot. Sealed Endless replay checkpoints retain their old rules.

const ACTIVE_SECONDS:=25.0
const COOLDOWN_SECONDS:=60.0
const REPAIR_BUDGET:=Catalog.REPAIR_HEAL*2.0
const ARMOR_CAP:=.22

var remaining:=0.0
var ready_at:=0.0
var restored:=0.0

static func armor(door_level: int) -> float:
 return clampf(float(door_level)/9.0,0.0,1.0)*ARMOR_CAP

static func under_siege(model, room: RoomState) -> bool:
 return room!=null and room.sleeping and room.alive and room.closed and room.door_hp>0.0 and model.hunter.hp>0.0 and model.time>=model.preparation and model.hunter.target==room.index and model.hunter.state==HunterState.State.ATTACK and model.hunter.position.distance_squared_to(room.door_approach())<=9.0

func price(room: RoomState) -> float:
 return room.manual_repair_cost()*2.0

func reason(model, room: RoomState) -> String:
 if not model.running or not model.result.is_empty():return "Resume the match first."
 if room==null or not room.alive:return "Claim a room first."
 if room.door_hp<=0.0:return "Door destroyed."
 if remaining>0.0:return "Repairing · %ds" % ceili(remaining)
 if model.time<ready_at:return "Repair cooldown · %ds" % ceili(ready_at-model.time)
 if room.door_hp>=room.max_hp():return "Door at full health."
 if room.gold+.00001<price(room):return "Need %.0f more Gold" % ceilf(price(room)-room.gold)
 return ""

func activate(model, room: RoomState) -> bool:
 var denied:=reason(model,room)
 if denied!="":
  if room!=null:room.reject(denied)
  return false
 var cost:=price(room)
 if not room.pay(cost,0.0,"continuous door repair"):return false
 room.ledger.totals.repair_g+=cost
 remaining=ACTIVE_SECONDS
 ready_at=model.time+COOLDOWN_SECONDS
 restored=0.0
 room.repair_actions+=1
 model.record_event("repair_started",room.index,{"spent_gold":cost,"spent_power":0.0})
 return true

func tick(delta: float, model, room: RoomState) -> void:
 if remaining<=0.0:return
 if room==null or not room.alive or room.door_hp<=0.0:
  remaining=0.0
  return
 var step:=minf(delta,remaining)
 remaining=maxf(0.0,remaining-step)
 var factor: float=clampf(room.repair_factor*StrategyCatalog.BRANCHES.get(room.door_branch,{}).get("repair",1.0),0.0,1.0)
 var applied:=minf(maxf(0.0,room.max_hp()-room.door_hp),REPAIR_BUDGET*step/ACTIVE_SECONDS*factor)
 room.door_hp+=applied
 restored+=applied
 model.contribution.repair_hp+=applied
 if remaining<=0.0:model.record_event("repair_finished",room.index,{"amount":restored})
