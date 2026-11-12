class_name UndeadAgent
extends RefCounted
var id=0
var slot=0
var position=Vector2.ZERO
var hp=120.0
var max_hp=120.0
var damage=10.0
var speed=58.0
var target=-1
var cooldown=1.0
var enhanced=false
var attack_flash=0.0
var hit_flash=0.0
var age=0.0
var lifetime=55.0
var slow_remaining=0.0
var slow_factor=1.0
func configure(model,identity: int,index: int,strong: bool):
 id=identity;slot=index;enhanced=strong;position=model.hunter.position
 var scale=1.15 if model.evolution.has("undead_commander") else 1.0
 max_hp=(190.0 if strong else 120.0)*scale;hp=max_hp
 damage=(17.0 if strong else 11.0)*scale
 speed=66.0 if strong else 55.0
 choose_target(model)
func choose_target(model):
 var valid=[]
 for room in model.rooms:
  if room.owner>=0 and room.alive and room.sleeping and not model.navigation_path(position,room.door_approach()).is_empty():valid.append(room.index)
 if not valid.is_empty():target=valid[model.random.randi_range(0,valid.size()-1)]
func tick(delta: float,model):
 if hp<=0:return
 attack_flash=maxf(0,attack_flash-delta);hit_flash=maxf(0,hit_flash-delta)
 age+=delta;cooldown=maxf(0,cooldown-delta);slow_remaining=maxf(0,slow_remaining-delta)
 if age>=lifetime:despawn(model);return
 if target<0 or not model.rooms[target].alive or not model.rooms[target].sleeping:choose_target(model)
 if target<0:return
 var room=model.rooms[target];var breach=room.door_hp<=0 or not room.closed
 var goal=room.bed_position() if breach else room.door_approach()
 position=model.step_navigation(position,goal,speed*(slow_factor if slow_remaining>0 else 1.0)*delta,"undead_slot%d" % slot)
 if position.distance_to(goal)>3:return
 if breach:
  if model.eliminate_resident(target,id):despawn(model)
 elif cooldown<=0:
  attack_flash=.35
  model.apply_room_damage(target,damage,"undead strike",id)
  model.record_event("undead_attack",target,{"entity_id":id,"entity_position":position,"enhanced":enhanced})
  cooldown=1.7 if enhanced else 2.0
func hurt(amount: float,model):
 if hp<=0 or not is_finite(amount) or amount<=0:return
 hit_flash=.2;hp=maxf(0,hp-amount)
 if hp<=0:
  model.record_event("undead_death",target,{"entity_id":id,"entity_position":position,"enhanced":enhanced})
  model._navigation_routes.erase("undead_slot%d" % slot)
func suppress(strength: float):
 slow_remaining=1.0;slow_factor=1.0-clampf(strength,0,.35)
func despawn(model):
 hp=0;model._navigation_routes.erase("undead_slot%d" % slot)
