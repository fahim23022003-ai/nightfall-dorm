class_name HunterState
extends RefCounted

enum State {DORMANT, SEEK, MOVE, ATTACK, BREACH, EXIT, DEAD}
var state = State.DORMANT
var position = Vector2(960,410)
var hp = Catalog.HUNTER.hp
var max_hp = Catalog.HUNTER.hp
var level = 1
var target = -1
var avoid_target = -1
var cooldown = 0.0
var target_time = 0.0
var hit_flash = 0.0
var attacks = 0
var exit_corridor = false
var damage = Catalog.HUNTER.damage
var interval = Catalog.HUNTER.interval
var speed = Catalog.HUNTER.speed
var difficulty="standard"
var applied_growth=0.0
var stalled_seconds=0.0
var navigation_recoveries=0
var retargets=0
var siege_start_hp=0.0

func configure(mode: String):
 difficulty=mode if RankCatalog.DIFFICULTIES.has(mode) else "standard"
 var tuning=RankCatalog.DIFFICULTIES[difficulty]
 max_hp=Catalog.HUNTER.hp*tuning.hp
 hp=max_hp
 damage=Catalog.HUNTER.damage*tuning.damage
 speed=Catalog.HUNTER.speed*tuning.speed

func growth_at(active_seconds: float) -> float:
 var cycles=int(maxf(0,active_seconds)/Catalog.HUNTER.growth_seconds)
 if cycles==0: return 0.0
 var phase=fmod(maxf(0,active_seconds),Catalog.HUNTER.growth_seconds)
 return cycles-1+smoothstep(0.0,Catalog.HUNTER_ESCALATION.ramp_seconds,phase)

func target_score(room: RoomState) -> float:
 var approach=room.door_position()+Vector2(0,22 if room.index<3 else -22)
 var dps=0.0
 var repair=0.0
 var relay=1.0
 for building in room.buildings.values():
  if building.kind=="enhancer": relay+=Catalog.BUILDINGS.enhancer.rate*building.level
 for tile in room.buildings:
  var b=room.buildings[tile]
  if b.kind in ["turret","heavy"]:
   var data=Catalog.BUILDINGS[b.kind]
   if room.tile_position(tile).distance_to(approach)<=data.range:
    dps+=data.damage*b.level*relay*room.turret_multiplier/(data.interval/(1+(b.level-1)*0.12))
  elif b.kind=="repair": repair+=Catalog.BUILDINGS.repair.rate*b.level
 var caution=1.0+clampf(1.0-hp/maxf(1,max_hp),0,1)*0.5
 return position.distance_to(room.door_position())+room.door_hp*Catalog.HUNTER.door_weight+minf(Catalog.HUNTER_ESCALATION.dps_penalty_cap,dps*Catalog.HUNTER_ESCALATION.dps_weight*caution)+minf(Catalog.HUNTER_ESCALATION.repair_penalty_cap,repair)

func navigate(goal: Vector2,delta: float):
 var previous=position
 position=position.move_toward(goal,speed*delta)
 if delta>0 and previous.distance_to(position)<0.01 and position.distance_to(goal)>3:
  stalled_seconds+=delta
 else: stalled_seconds=0
 if stalled_seconds>=Catalog.HUNTER_ESCALATION.stuck_seconds and state==State.MOVE:
  navigation_recoveries+=1
  avoid_target=target
  target_time=0
  state=State.SEEK
  stalled_seconds=0

func tick(delta: float, match_state):
 hit_flash = maxf(0,hit_flash-delta)
 if state == State.DEAD or match_state.time < match_state.preparation:
  return
 var active_seconds=maxf(0,match_state.time-match_state.preparation)
 var next_level=1+int(active_seconds/Catalog.HUNTER.growth_seconds)
 level=maxi(level,next_level)
 var growth=growth_at(active_seconds)
 var tuning=RankCatalog.DIFFICULTIES[difficulty]
 if growth>applied_growth:
  var added=(growth-applied_growth)*Catalog.HUNTER.hp_growth*tuning.hp
  max_hp+=added
  if hp>0: hp=minf(max_hp,hp+added)
  applied_growth=growth
 damage=(Catalog.HUNTER.damage+growth*Catalog.HUNTER.damage_growth)*tuning.damage
 interval=maxf(Catalog.HUNTER.min_interval,Catalog.HUNTER.interval-growth*Catalog.HUNTER.interval_growth)
 speed=(Catalog.HUNTER.speed+minf(Catalog.HUNTER_ESCALATION.speed_bonus_cap,growth*Catalog.HUNTER_ESCALATION.speed_growth))*tuning.speed
 cooldown = maxf(-delta,cooldown-delta)
 target_time += delta
 if state == State.EXIT:
  var exit_door = match_state.rooms[target].door_position()
  if position.distance_to(exit_door)<3:
   exit_corridor = true
  var exit_goal = Vector2(exit_door.x,410) if exit_corridor else exit_door
  navigate(exit_goal,delta)
  if absf(position.y-410)<3:
   state = State.SEEK
  return
 if target < 0 or not match_state.rooms[target].alive or not match_state.rooms[target].sleeping:
  state = State.SEEK
 if state == State.DORMANT:
  state = State.SEEK
 if state == State.SEEK:
  target = choose_target(match_state.rooms,avoid_target)
  avoid_target = -1
  target_time = 0
  if target>=0: siege_start_hp=match_state.rooms[target].door_hp
  if target < 0:
   return
  state = State.MOVE
  if delta>0: match_state.record_event("approach",target)
 var room = match_state.rooms[target]
 var approach = room.door_position()+Vector2(0,22 if target < 3 else -22)
 if state == State.MOVE:
  var waypoint = approach
  if absf(position.x-approach.x)>2 and absf(position.y-410)>2:
   waypoint = Vector2(position.x,410)
  elif absf(position.x-approach.x)>2:
   waypoint = Vector2(approach.x,410)
  navigate(waypoint,delta)
  if position.distance_to(approach)<3:
   state = State.ATTACK if room.closed and room.door_hp > 0 else State.BREACH
   if delta>0: match_state.record_event("encounter",target)
 elif state == State.ATTACK:
  if room.door_hp <= 0 or not room.closed:
   state = State.BREACH
  elif cooldown <= 0:
   var old_hp=room.door_hp
   room.door_hp = maxf(0,room.door_hp-damage)
   room.door_damage_taken+=old_hp-room.door_hp
   match_state.record_event("door_damage",target,{"damage":old_hp-room.door_hp,"hp":room.door_hp,"max_hp":room.max_hp()})
   if old_hp>0 and room.door_hp<=0: match_state.record_event("door_break",target)
   room.try_rescue()
   room.damage_flash = 0.25
   attacks += 1
   cooldown += interval
  if target_time>maxf(Catalog.HUNTER.retarget_seconds,Catalog.HUNTER_ESCALATION.minimum_commitment) and room.door_hp>damage*2:
   var alternative=choose_target(match_state.rooms,target)
   var stalled=room.door_hp>=siege_start_hp-damage*2
   if alternative>=0 and alternative!=target and (stalled or target_score(match_state.rooms[alternative])<target_score(room)*(1-Catalog.HUNTER_ESCALATION.retarget_improvement)):
    avoid_target=target
    retargets+=1
    state=State.SEEK
   else:
    # Reassess later; do not churn targets on every frame.
    target_time=0
    siege_start_hp=room.door_hp
 elif state == State.BREACH:
  navigate(room.bed_position(),delta)
  if position.distance_to(room.bed_position()) < 12:
   room.alive = false
   room.sleeping = false
   match_state.eliminations += 1
   match_state.record_event("elimination",target)
   exit_corridor = false
   state = State.EXIT

func choose_target(rooms: Array, excluded: int = -1) -> int:
 var best = -1
 var score = INF
 for room in rooms:
  if room.owner >= 0 and room.alive and room.sleeping and room.index != excluded:
   var value = target_score(room)
   if value < score:
    best = room.index
    score = value
 if best < 0 and excluded >= 0:
  return choose_target(rooms)
 return best

func hurt(amount: float):
 if state == State.DORMANT or state == State.DEAD:
  return
 hp = maxf(0,hp-amount)
 hit_flash = 0.15
 if hp <= 0:
  state = State.DEAD
