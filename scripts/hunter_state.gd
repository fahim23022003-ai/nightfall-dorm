class_name HunterState
extends RefCounted

enum State {DORMANT, SEEK, MOVE, ATTACK, BREACH, EXIT, DEAD}
var state = State.DORMANT
var position = Vector2(960,410)
var hp = Catalog.HUNTER.hp
var max_hp = Catalog.HUNTER.hp
var level = 1
var target = -1
var cooldown = 0.0
var target_time = 0.0
var hit_flash = 0.0
var attacks = 0
var exit_corridor = false
var damage = Catalog.HUNTER.damage
var interval = Catalog.HUNTER.interval
var speed = Catalog.HUNTER.speed

func tick(delta: float, match_state):
 hit_flash = maxf(0,hit_flash-delta)
 if state == State.DEAD or match_state.time < match_state.preparation:
  return
 var next_level = 1 + int((match_state.time-match_state.preparation)/Catalog.HUNTER.growth_seconds)
 if next_level > level:
  hp += Catalog.HUNTER.hp_growth*(next_level-level)
  max_hp += Catalog.HUNTER.hp_growth*(next_level-level)
  level = next_level
 damage = Catalog.HUNTER.damage + (level-1)*Catalog.HUNTER.damage_growth
 interval = maxf(Catalog.HUNTER.min_interval,Catalog.HUNTER.interval-(level-1)*Catalog.HUNTER.interval_growth)
 cooldown -= delta
 target_time += delta
 if state == State.EXIT:
  var exit_door = match_state.rooms[target].door_position()
  if position.distance_to(exit_door)<3:
   exit_corridor = true
  var exit_goal = Vector2(exit_door.x,410) if exit_corridor else exit_door
  position = position.move_toward(exit_goal,speed*delta)
  if absf(position.y-410)<3:
   state = State.SEEK
  return
 if target < 0 or not match_state.rooms[target].alive or not match_state.rooms[target].sleeping:
  state = State.SEEK
 if state == State.DORMANT:
  state = State.SEEK
 if state == State.SEEK:
  target = choose_target(match_state.rooms)
  target_time = 0
  if target < 0:
   return
  state = State.MOVE
 var room = match_state.rooms[target]
 var approach = room.door_position()+Vector2(0,22 if target < 3 else -22)
 if state == State.MOVE:
  var waypoint = approach
  if absf(position.x-approach.x)>2 and absf(position.y-410)>2:
   waypoint = Vector2(position.x,410)
  elif absf(position.x-approach.x)>2:
   waypoint = Vector2(approach.x,410)
  position = position.move_toward(waypoint,speed*delta)
  if position.distance_to(approach)<3:
   state = State.ATTACK if room.closed and room.door_hp > 0 else State.BREACH
 elif state == State.ATTACK:
  if room.door_hp <= 0 or not room.closed:
   state = State.BREACH
  elif cooldown <= 0:
   room.door_hp = maxf(0,room.door_hp-damage)
   room.damage_flash = 0.25
   attacks += 1
   cooldown = interval
  if target_time > 32 and room.door_hp > room.max_hp()*0.8:
   state = State.SEEK
 elif state == State.BREACH:
  position = position.move_toward(room.bed_position(),speed*delta)
  if position.distance_to(room.bed_position()) < 12:
   room.alive = false
   room.sleeping = false
   match_state.eliminations += 1
   exit_corridor = false
   state = State.EXIT

func choose_target(rooms: Array) -> int:
 var best = -1
 var score = INF
 for room in rooms:
  if room.owner >= 0 and room.alive and room.sleeping:
   var value = position.distance_to(room.door_position()) + room.door_hp*0.12
   if value < score:
    best = room.index
    score = value
 return best

func hurt(amount: float):
 if state == State.DORMANT or state == State.DEAD:
  return
 hp = maxf(0,hp-amount)
 hit_flash = 0.15
 if hp <= 0:
  state = State.DEAD
