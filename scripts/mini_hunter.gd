class_name MiniHunter
extends UndeadAgent
## Stalker shadowling. Its lifetime is governed exclusively by real combat.
var seek_delay:=0.0
var heading:=Vector2.RIGHT
var walking:=false
var stride:=0.0

func configure(model, identity: int, index: int, _strong: bool):
 id=identity
 slot=index
 position=model.map_data.hunter_spawn
 var stage: int=clampi(model.evolution.evolution_level-1,0,9)
 max_hp=80.0+stage*9.0
 hp=max_hp
 damage=5.0+stage*.65
 speed=54.0

func route_key() -> String:
 return "shadowling_%d" % id

func valid_room(model, index: int) -> bool:
 if index<0 or index>=model.rooms.size():return false
 if index==model.mini_hunter_excluded_room():return false
 var room: RoomState=model.rooms[index]
 return room.owner>=0 and room.alive and room.sleeping and room.closed and room.door_hp>0.0

func choose_target(model):
 target=-1
 var routes: Dictionary=model.hunter_route_costs(position)
 var best:=INF
 for room in model.rooms:
  if not valid_room(model,room.index):continue
  var distance: float=routes.get(room.index,INF)
  var score: float=distance*(.88+.04*posmod(id*13+room.index*7,7))
  if score<best:
   target=room.index
   best=score

func tick(delta: float,model):
 if hp<=0.0 or delta<=0.0:return
 age+=delta
 walking=false
 cooldown=maxf(0.0,cooldown-delta)
 attack_flash=maxf(0.0,attack_flash-delta)
 hit_flash=maxf(0.0,hit_flash-delta)
 slow_remaining=maxf(0.0,slow_remaining-delta)
 seek_delay=maxf(0.0,seek_delay-delta)
 if model.wrath.domain_active():return
 if not valid_room(model,target):
  if target>=0:
   target=-1
   seek_delay=0.0
   model._navigation_routes.erase(route_key())
  if seek_delay>0.0:return
  choose_target(model)
  seek_delay=.9
  if target<0:return
 var room: RoomState=model.rooms[target]
 var goal:=room.door_approach()
 if position.distance_to(goal)>2.9:
  var previous: Vector2=position
  position=model.step_navigation(position,goal,speed*(slow_factor if slow_remaining>0.0 else 1.0)*delta,route_key())
  var distance: float=previous.distance_to(position)
  walking=distance>.001
  if walking:
   heading=previous.direction_to(position)
   stride+=distance*.28
  elif seek_delay<=0.0:
   target=-1
   seek_delay=.9
   model._navigation_routes.erase(route_key())
  return
 heading=-room.door_normal()
 if cooldown<=0.0:
  var dealt: float=model.apply_room_damage(target,damage,"shadowling strike",id)
  attack_flash=.35
  model.record_event("mini_hunter_attack",target,{"entity_id":id,"entity_position":position,"damage":dealt})
  cooldown=2.5

func hurt(amount: float,model,show_hit: bool=true):
 if hp<=0.0 or not is_finite(amount) or amount<=0.0:return
 if show_hit:hit_flash=.2
 hp=maxf(0.0,hp-amount)
 if hp<=0.0:
  model.record_event("mini_hunter_killed",target,{"entity_id":id,"entity_position":position})
  model._navigation_routes.erase(route_key())

func draw_pose(canvas: CanvasItem, clock: float) -> void:
 var facing:=1.0 if heading.x>=0.0 else -1.0
 var step:=sin(stride) if walking else 0.0
 var reach:=sin(PI*clampf(attack_flash/.35,0.0,1.0))*9.0
 var lift:=sin(clock*2.2+id)*1.2+absf(step)*2.0
 var base: Vector2=position+Vector2(145,40)
 var shoulder:=base+Vector2(facing*reach*.35,-28-lift)
 var hips:=base+Vector2(0,-13-lift)
 var dark:=Color("271E35")
 var tone:=Color("62576F") if hit_flash<=0.0 else Color("DAABBE")
 canvas.draw_line(hips,base+Vector2(step*5-4,0),dark,4)
 canvas.draw_line(hips,base+Vector2(-step*5+4,1),tone,3)
 canvas.draw_line(shoulder,hips,dark,12)
 canvas.draw_line(shoulder+Vector2(-2,0),hips-Vector2(2,1),tone,4)
 canvas.draw_line(shoulder,shoulder+Vector2(facing*(6+reach),13-step*3),tone,3)
 var head:=shoulder+Vector2(facing*2,-5)
 canvas.draw_circle(head,7,dark)
 canvas.draw_circle(head+Vector2(facing*2,-1),4,tone)
 canvas.draw_circle(head+Vector2(facing*4,-1),1,Color("F3C2CE"))
