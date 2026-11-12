class_name ArcaneHunter
extends RefCounted
var cooldown=6.0
var warning=0.0
var action=""
var target=-1
var bolt={}
var dash=0.0
var defensive_flash=0.0
var casts={}
func tick(h,model,delta: float) -> bool:
 defensive_flash=maxf(0,defensive_flash-delta);dash=maxf(0,dash-delta)
 if h.hp<=0 or h.state in [HunterState.State.DEAD,HunterState.State.TRANSFORM] or model.wrath.active() or h.phase_guard_remaining>0:
  action="";bolt.clear();warning=0;return false
 cooldown=maxf(0,cooldown-delta)
 if not bolt.is_empty():
  var room=model.rooms[int(bolt.target)];var goal=room.door_approach();var before: Vector2=bolt.point
  bolt.point=before.move_toward(goal,220*delta)
  if not room.alive or room.door_hp<=0 or not model._visible(before,bolt.point):bolt.clear()
  elif bolt.point.distance_to(goal)<2:
   impact(h,model,int(bolt.target),"cursed_projectile");bolt.clear()
 if action!="":
  warning=maxf(0,warning-delta)
  if warning>0:return true
  var chosen=action;action=""
  if target<0 or target>=model.rooms.size() or not model.rooms[target].alive:return false
  var room=model.rooms[target]
  if chosen=="shadow_dash":dash=1.2
  elif chosen=="cursed_projectile":
   if h.position.distance_to(room.door_approach())<=150 and model._visible(h.position,room.door_approach()):bolt={"point":h.position,"target":target}
  elif h.position.distance_to(room.door_approach())<=3:impact(h,model,target,chosen)
  casts[chosen]=int(casts.get(chosen,0))+1
  model.record_event("hunter_ability",target,{"ability":chosen,"duration":1.2 if chosen=="shadow_dash" else 3.0})
 if cooldown>0 or h.target<0 or h.target>=model.rooms.size() or model.tutorial_mode or h.boss_attack!="":return false
 var room=model.rooms[h.target]
 if not room.alive or not room.closed or room.door_hp<=0:return false
 var chosen=""
 if h.transformed:
  if h.state==HunterState.State.MOVE:chosen="shadow_dash"
  elif h.state==HunterState.State.ATTACK:chosen="soul_drain"
 elif h.archetype=="witch" and h.state in [HunterState.State.MOVE,HunterState.State.ATTACK] and h.position.distance_to(room.door_approach())<=140 and model._visible(h.position,room.door_approach()):chosen="cursed_projectile"
 elif h.archetype=="electric" and h.state==HunterState.State.ATTACK:chosen="interference"
 elif h.archetype=="storm" and h.state==HunterState.State.ATTACK:chosen="chain_lightning"
 if chosen=="":return false
 action=chosen;target=h.target;warning=1.1 if chosen!="shadow_dash" else .7;cooldown=22 if h.transformed else 16
 model.record_event("hunter_ability_warning",target,{"ability":chosen,"delay":warning});return true
func impact(h,model,index: int,ability: String):
 var room=model.rooms[index]
 var element="ice" if ability=="cursed_projectile" else "electric" if ability in ["interference","chain_lightning"] else "neutral"
 var amount=model.apply_room_damage(index,h.damage*(.8 if ability=="interference" else 1.15 if ability=="cursed_projectile" else 1.0),ability,1,true,{"type":"magic","element":element})
 if ability=="soul_drain" and h.hp>0:h.hp=minf(h.max_hp,h.hp+minf(h.max_hp*.015,amount*.25))
 if ability=="interference" and room.magic_state.disrupt_guard<=0:
  room.magic_state.disrupt=3.0;room.magic_state.disrupt_guard=18.0
 if ability=="chain_lightning":
  var count=0
  for other in model.rooms:
   if other.index==index or other.owner<0 or not other.alive or other.door_hp<=0:continue
   if room.door_approach().distance_to(other.door_approach())<=240 and model._visible(room.door_approach(),other.door_approach()):
    model.apply_room_damage(other.index,h.damage*.45,"chain_lightning",1,true,{"type":"magic","element":"electric"});count+=1
    if count>=2:break
 model.record_event("arcane_impact",index,{"ability":ability,"amount":amount,"damage_type":"magic","element":element})
