class_name MagicDefense
extends RefCounted
const KINDS=["barrier","plasma","antenna"]
static func stats(b: Dictionary) -> Dictionary:
 var level=float(b.level);var branch=str(b.get("specialization",""))
 match b.kind:
  "barrier":return {"reflect":minf(.3,.1+level*.015)*(1.2 if branch=="mirror" else .8 if branch=="ward" else 1.0),"interval":5.0 if branch=="mirror" else 3.0 if branch=="ward" else 4.0}
  "plasma":return {"capacity":90+level*25,"absorb":.2 if branch=="reservoir" else .3 if branch=="converter" else .25,"heal":.35 if branch=="converter" else .2,"expiry":18.0 if branch=="reservoir" else 12.0}
  "antenna":return {"capacity":(30+level*12)*(1.35 if branch=="dome" else .8 if branch=="pulse" else 1.0),"interval":12.0 if branch=="dome" else 7.0 if branch=="pulse" else 10.0,"power":2+level*.5}
 return {}
static func best(room,kind: String) -> Dictionary:
 var selected={}
 for b in room.buildings.values():
  if b.kind==kind and (selected.is_empty() or int(b.level)>int(selected.level)):selected=b
 return selected
static func tick(model,delta: float):
 for room in model.rooms:
  var state=room.magic_state
  for key in ["reflect_cd","shield_cd","storage_time","heal_cd","disrupt","disrupt_guard"]:state[key]=maxf(0,float(state[key])-delta)
  if state.storage_time<=0:state.stored=0.0
  if not room.alive or not room.sleeping:state.shield=0.0;state.stored=0.0;continue
  var antenna=best(room,"antenna");var plasma=best(room,"plasma")
  if not antenna.is_empty():state.shield=minf(state.shield,stats(antenna).capacity)
  if not plasma.is_empty():state.stored=minf(state.stored,stats(plasma).capacity)
  if antenna.is_empty():state.shield=0.0
  elif state.shield_cd<=0 and state.shield<=0 and room.door_hp>0:
   var s=stats(antenna)
   if room.pay(0,s.power):state.shield=s.capacity;state.shield_cd=s.interval;model.record_event("magic_shield",room.index,{"amount":state.shield,"duration":s.interval})
  if plasma.is_empty():state.stored=0.0
  elif state.stored>0 and state.heal_cd<=0 and room.door_hp>0 and room.door_hp<room.max_hp():
   var amount=minf(state.stored,30+10*float(plasma.level));var heal=minf(room.max_hp()-room.door_hp,amount*stats(plasma).heal)
   state.stored-=amount;state.heal_cd=3.0;room.door_hp+=heal;model.record_event("plasma_release",room.index,{"amount":heal})
static func absorb(model,room,amount: float,attacker_id: int,packet: Dictionary) -> float:
 if packet.type!=DamageRules.MAGIC:return amount
 var state=room.magic_state;var shield=minf(amount,float(state.shield));state.shield-=shield;amount-=shield
 if shield>0:model.record_event("magic_absorb",room.index,{"amount":shield,"kind":"antenna"})
 var plasma=best(room,"plasma")
 if not plasma.is_empty():
  var s=stats(plasma);var absorbed=minf(amount*s.absorb,maxf(0,s.capacity-state.stored));state.stored+=absorbed;amount-=absorbed
  if absorbed>0:state.storage_time=s.expiry;model.record_event("magic_absorb",room.index,{"amount":absorbed,"kind":"plasma"})
 var barrier=best(room,"barrier")
 if not barrier.is_empty() and state.reflect_cd<=0 and not packet.get("reflected",false) and amount>0:
  var s=stats(barrier);state.reflect_cd=s.interval
  var reflected=model.apply_target_damage(attacker_id,amount*s.reflect,room.index,{"type":DamageRules.MAGIC,"element":packet.element,"reflected":true})
  model.credit_damage(room.index,reflected,attacker_id);model.record_event("magic_reflect",room.index,{"amount":reflected,"attacker_id":attacker_id})
 return amount

static func removed(room):
 if best(room,"plasma").is_empty():room.magic_state.stored=0.0;room.magic_state.storage_time=0.0
 if best(room,"antenna").is_empty():room.magic_state.shield=0.0
