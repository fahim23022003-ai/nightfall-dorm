class_name HunterState
extends RefCounted

enum State {DORMANT, SEEK, MOVE, ATTACK, BREACH, EXIT, DEAD, TRANSFORM}
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
var stage_scaling={"hunter_hp":1.0,"hunter_damage":1.0,"hunter_speed":1.0}
var applied_growth=0.0
var stalled_seconds=0.0
var navigation_recoveries=0
var retargets=0
var siege_start_hp=0.0
var siege_seconds=0.0
var reassess_seconds=0.0
var encounter_attacks=0
var charged_ready=false
var windup_remaining=0.0
var _previous_siege_room=-1
var _model_ref: WeakRef
var decision_count=0
var _route_costs: Dictionary={}
# One entity, one identity, and one irreversible transformation per match.
var boss_policy: Dictionary={"enabled":false}
var transformed=false
var transform_remaining=0.0
var boss_attack=""
var boss_attack_target=-1
var boss_cooldowns={"scythe":0.0,"siege":0.0,"surge":0.0}
var surge_remaining=0.0
var surge_room=-1
var boss_action_age=0.0
var last_boss_attack=""
var _transform_exit_room=-1

func configure_encounter(stage_id: String):
 boss_policy=BossCatalog.encounter(stage_id,difficulty)

func cancel_boss_attack():
 var interrupted=boss_attack!=""
 boss_attack=""
 boss_attack_target=-1
 windup_remaining=0.0
 charged_ready=false
 if interrupted: cooldown=maxf(cooldown,0.5)

func request_exit(room_index: int):
 if state==State.DEAD: return
 if state==State.TRANSFORM:
  _transform_exit_room=room_index
  return
 target=room_index
 state=State.EXIT
 exit_corridor=false
 cancel_boss_attack()
 surge_remaining=0

func shadow_active(room_index: int) -> bool:
 return state==State.ATTACK and hp>0 and target==surge_room and room_index==surge_room and surge_remaining>0

func _begin_transformation(model):
 transformed=true
 transform_remaining=BossCatalog.TRANSFORM_SECONDS
 state=State.TRANSFORM
 cancel_boss_attack()
 siege_seconds=0
 reassess_seconds=0
 if target>=0 and target<model.rooms.size(): model.rooms[target].repair_factor=1.0
 model.record_event("boss_transform",target,{"position":position,"duration":transform_remaining})

func _boss_tick(delta: float, model) -> bool:
 boss_action_age+=delta
 surge_remaining=maxf(0,surge_remaining-delta)
 for key in boss_cooldowns: boss_cooldowns[key]=maxf(0,boss_cooldowns[key]-delta)
 if state!=State.ATTACK or target!=surge_room: surge_remaining=0
 if boss_attack!="" and (state!=State.ATTACK or target!=boss_attack_target): cancel_boss_attack()
 if state==State.TRANSFORM:
  transform_remaining=maxf(0,transform_remaining-delta)
  if transform_remaining<=0:
   state=State.SEEK # Revalidate living/sleeping targets and physical route.
   if _transform_exit_room>=0 and _transform_exit_room<model.rooms.size():
    request_exit(_transform_exit_room)
   _transform_exit_room=-1
   cooldown=1.0
   model.record_event("boss_awakened",target,{"position":position})
  return true
 if hp>0 and not transformed and boss_policy.get("enabled",false) and state not in [State.DORMANT,State.DEAD,State.BREACH,State.EXIT]:
  var active=model.time-model.preparation
  if active>=boss_policy.opening and (hp/maxf(1,max_hp)<=boss_policy.hp_fraction or active>=boss_policy.deadline):
   _begin_transformation(model)
   return true
 return false

func _choose_boss_attack(room) -> String:
 var defenses=0
 for tile in room.buildings:
  var b=room.buildings[tile]
  if b.kind in ["turret","heavy"] and room.tile_position(tile).distance_to(position)<=Catalog.BUILDINGS[b.kind].range: defenses+=1
 if defenses>=2 and room.door_hp>damage*2 and boss_cooldowns.surge<=0: return "surge"
 if room.door_hp>damage*2 and boss_cooldowns.siege<=0: return "siege"
 return "scythe" if boss_cooldowns.scythe<=0 else ""

func _boss_strike(room, model):
 if boss_attack=="":
  var selected=_choose_boss_attack(room)
  if selected=="": return
  boss_attack=selected
  boss_attack_target=target
  var data=BossCatalog.ATTACKS[selected]
  boss_cooldowns[selected]=data.cooldown
  cooldown=data.windup
  windup_remaining=cooldown
  boss_action_age=0
  model.record_event("boss_warning",target,{"attack":selected,"delay":cooldown})
  return
 var attack=boss_attack
 var data=BossCatalog.ATTACKS[attack]
 cancel_boss_attack()
 last_boss_attack=attack
 boss_action_age=0
 boss_cooldowns[attack]=data.cooldown
 if attack=="surge":
  surge_room=target
  surge_remaining=BossCatalog.SURGE_SECONDS
  model.record_event("boss_surge",target,{"duration":surge_remaining})
 else:
  _damage_door(room,model,damage*data.damage)
  model.record_event("boss_impact",target,{"attack":attack})
 cooldown=interval*data.recovery*float(boss_policy.get("recovery",1.0))

func _damage_door(room, model, amount: float):
 var old_hp=room.door_hp
 amount=model.items.absorb(amount,model)
 var rescued=room.index==model.player_room and model.items.guardian_intercept(amount,model)
 if not rescued: room.door_hp=maxf(0,room.door_hp-amount)
 room.door_damage_taken+=maxf(0,old_hp-room.door_hp)
 model.record_event("door_damage",target,{"damage":maxf(0,old_hp-room.door_hp),"hp":room.door_hp,"max_hp":room.max_hp()})
 if old_hp>0 and room.door_hp<=0: model.record_event("door_break",target)
 if room.index==model.player_room and not rescued: model.items.feather_cross(old_hp,model)
 if not rescued: room.try_rescue()
 room.damage_flash=0.25
 attacks+=1


func stop_combat(model):
 _transform_exit_room=-1
 cancel_boss_attack()
 surge_remaining=0
 transform_remaining=0
 if state==State.TRANSFORM: state=State.SEEK
 for room in model.rooms: room.repair_factor=1.0

func configure(mode: String):
 difficulty=mode if RankCatalog.DIFFICULTIES.has(mode) else "standard"
 var tuning=_tuning()
 max_hp=Catalog.HUNTER.hp*tuning.hp
 hp=max_hp
 damage=Catalog.HUNTER.damage*tuning.damage
 speed=Catalog.HUNTER.speed*tuning.speed

func _tuning() -> Dictionary:
 var base=RankCatalog.DIFFICULTIES[difficulty]
 return {"hp":base.hp*stage_scaling.hunter_hp,"damage":base.damage*stage_scaling.hunter_damage,"speed":base.speed*stage_scaling.hunter_speed}

func growth_at(active_seconds: float) -> float:
 var profile=RankCatalog.pressure(difficulty)
 if active_seconds<profile.opening: return 0.0
 var since=active_seconds-profile.opening
 var cycles=1+int(since/profile.growth_seconds)
 return cycles-1+smoothstep(0.0,Catalog.HUNTER_ESCALATION.ramp_seconds,fmod(since,profile.growth_seconds))

func target_score(room: RoomState) -> float:
 var approach=room.door_approach()
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
 if (difficulty!="standard" or transformed) and _model_ref!=null and _model_ref.get_ref()!=null:
  for other in _model_ref.get_ref().rooms:
   if other==room or not other.alive: continue
   for tile in other.buildings:
    var b=other.buildings[tile]
    if b.kind in ["turret","heavy"]:
     var data=Catalog.BUILDINGS[b.kind]
     if other.tile_position(tile).distance_to(approach)<=data.range:
      dps+=data.damage*b.level*other.turret_multiplier/data.interval
 var smoke_penalty=0.0
 if _model_ref!=null and _model_ref.get_ref()!=null:
  var m=_model_ref.get_ref()
  if room.index==m.player_room and float(m.items.timers.get("smoke",0))>0: smoke_penalty=5000.0
 var caution=1.0+clampf(1.0-hp/maxf(1,max_hp),0,1)*0.5
 return smoke_penalty+position.distance_to(room.door_position())+room.door_hp*(0.35 if transformed else RankCatalog.pressure(difficulty).door_weight)+minf(Catalog.HUNTER_ESCALATION.dps_penalty_cap,dps*Catalog.HUNTER_ESCALATION.dps_weight*caution)+minf(Catalog.HUNTER_ESCALATION.repair_penalty_cap,repair)

func navigate(goal: Vector2,delta: float):
 var previous=position
 position=position.move_toward(goal,speed*delta)
 if _model_ref!=null and _model_ref.get_ref()!=null: _model_ref.get_ref().items.trigger_segment(previous,position,_model_ref.get_ref())
 if hp<=0: return
 if delta>0 and previous.distance_to(position)<0.01 and position.distance_to(goal)>3:
  stalled_seconds+=delta
 else: stalled_seconds=0
 if stalled_seconds>=Catalog.HUNTER_ESCALATION.stuck_seconds and state==State.MOVE:
  navigation_recoveries+=1
  avoid_target=target
  target_time=0
  state=State.SEEK
  stalled_seconds=0

func _advance_custom(goal: Vector2,delta: float,model,key: String):
 var previous=position
 position=model.step_navigation(position,goal,speed*delta,key)
 model.items.trigger_segment(previous,position,model)
 if hp<=0: return
 if delta>0 and previous.distance_to(position)<0.01 and position.distance_to(goal)>3:
  stalled_seconds+=delta
 else: stalled_seconds=0
 if stalled_seconds>=Catalog.HUNTER_ESCALATION.stuck_seconds:
  navigation_recoveries+=1
  avoid_target=target
  state=State.SEEK
  target_time=0
  siege_seconds=0
  charged_ready=false
  windup_remaining=0
  stalled_seconds=0

func tick(delta: float, match_state):
 if not is_finite(delta) or delta<0: return
 if match_state.result!="":
  stop_combat(match_state)
  return
 delta=maxf(0,delta-match_state.items.frozen_delta)
 if delta<=0 and match_state.items.frozen_delta>0: return
 hit_flash = maxf(0,hit_flash-delta)
 _model_ref=weakref(match_state)
 var profile=RankCatalog.pressure(difficulty)
 if _previous_siege_room>=0: match_state.rooms[_previous_siege_room].repair_factor=1.0
 _previous_siege_room=-1
 if state==State.ATTACK and target>=0 and target<match_state.rooms.size():
  siege_seconds+=delta
  reassess_seconds+=delta
  match_state.rooms[target].repair_factor=lerpf(1.0,profile.repair_floor,clampf(minf(siege_seconds,maxf(0,match_state.time-match_state.preparation-profile.opening))/profile.siege_ramp,0,1))
  _previous_siege_room=target
 windup_remaining=maxf(0,cooldown-delta) if charged_ready or boss_attack!="" else 0.0
 if state == State.DEAD or match_state.time < match_state.preparation:
  return
 if _boss_tick(delta,match_state): return
 var active_seconds=maxf(0,match_state.time-match_state.preparation)
 var next_level=1 if active_seconds<profile.opening else 2+int((active_seconds-profile.opening)/profile.growth_seconds)
 level=maxi(level,next_level)
 var growth=growth_at(active_seconds)
 var tuning=_tuning()
 if growth>applied_growth:
  var added=(growth-applied_growth)*Catalog.HUNTER.hp_growth*tuning.hp
  max_hp+=added
  if hp>0: hp=minf(max_hp,hp+added)
  applied_growth=growth
 damage=(Catalog.HUNTER.damage+growth*profile.damage_growth)*tuning.damage*lerpf(1.0,ItemCatalog.TUNING.curse_damage,match_state.items.curse_frame_fraction)
 interval=maxf(Catalog.HUNTER.min_interval,(Catalog.HUNTER.interval-growth*Catalog.HUNTER.interval_growth)*profile.interval_scale)*lerpf(1.0,ItemCatalog.TUNING.curse_interval,match_state.items.curse_frame_fraction)
 speed=(Catalog.HUNTER.speed+minf(Catalog.HUNTER_ESCALATION.speed_bonus_cap,growth*Catalog.HUNTER_ESCALATION.speed_growth))*tuning.speed*match_state.items.speed_factor(self)
 if match_state.items.decoy_tick(delta,match_state): return
 cooldown = maxf(-delta,cooldown-delta)
 target_time += delta
 if state == State.EXIT:
  if match_state.map_id!="legacy":
   _advance_custom(match_state.rooms[target].corridor_anchor(),delta,match_state,"hunter_exit")
   if hp<=0: return
   if position.distance_to(match_state.rooms[target].corridor_anchor())<3: state=State.SEEK
   return
  var exit_door = match_state.rooms[target].door_position()
  if position.distance_to(exit_door)<3:
   exit_corridor = true
  var exit_goal = Vector2(exit_door.x,410) if exit_corridor else exit_door
  navigate(exit_goal,delta)
  if hp<=0: return
  if absf(position.y-410)<3:
   state = State.SEEK
  return
 if target < 0 or target>=match_state.rooms.size() or not match_state.rooms[target].alive or not match_state.rooms[target].sleeping:
  cancel_boss_attack()
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
 var approach = room.door_position()+Vector2(0,22 if target < 3 else -22) if match_state.map_id=="legacy" else room.door_approach()
 if state == State.MOVE:
  var waypoint = approach
  if absf(position.x-approach.x)>2 and absf(position.y-410)>2:
   waypoint = Vector2(position.x,410)
  elif absf(position.x-approach.x)>2:
   waypoint = Vector2(approach.x,410)
  if match_state.map_id=="legacy": navigate(waypoint,delta)
  else: _advance_custom(approach,delta,match_state,"hunter_move")
  if hp<=0: return
  if position.distance_to(approach)<3:
   state = State.ATTACK if room.closed and room.door_hp > 0 else State.BREACH
   siege_seconds=0
   reassess_seconds=0
   encounter_attacks=0
   charged_ready=false
   if delta>0: match_state.record_event("encounter",target)
 elif state == State.ATTACK:
  if position.distance_to(approach)>3:
   state=State.MOVE
   surge_remaining=0
   cancel_boss_attack()
   charged_ready=false
   windup_remaining=0
   room.repair_factor=1.0
   return
  if room.door_hp <= 0 or not room.closed:
   cancel_boss_attack()
   surge_remaining=0
   state = State.BREACH
  elif cooldown <= 0:
   if transformed:
    _boss_strike(room,match_state)
   else:
    if active_seconds>=profile.opening and profile.charged_every>0 and (encounter_attacks+1)%int(profile.charged_every)==0 and not charged_ready:
     charged_ready=true
     cooldown=profile.windup
     windup_remaining=cooldown
     match_state.record_event("charged_attack",target,{"delay":cooldown,"multiplier":profile.charged_scale})
     return
    var strike_scale=profile.charged_scale if charged_ready else 1.0
    charged_ready=false
    windup_remaining=0
    encounter_attacks+=1
    _damage_door(room,match_state,damage*strike_scale)
    cooldown += interval
  if boss_attack=="" and (target_time if difficulty=="standard" and not transformed else reassess_seconds)>maxf(profile.commit,Catalog.HUNTER_ESCALATION.minimum_commitment) and room.door_hp>damage*2:
   var alternative=choose_target(match_state.rooms,target)
   var stalled=room.door_hp>=siege_start_hp-damage*2
   if alternative>=0 and alternative!=target and (stalled or target_score(match_state.rooms[alternative])<target_score(room)*(1-Catalog.HUNTER_ESCALATION.retarget_improvement)):
    cancel_boss_attack()
    surge_remaining=0
    avoid_target=target
    retargets+=1
    charged_ready=false
    windup_remaining=0
    room.repair_factor=1.0
    state=State.SEEK
   else:
    # Reassess later; do not churn targets on every frame.
    target_time=0
    reassess_seconds=0
    siege_start_hp=room.door_hp
 elif state == State.BREACH:
  if match_state.map_id=="legacy": navigate(room.bed_position(),delta)
  else: _advance_custom(room.bed_position(),delta,match_state,"hunter_breach")
  if hp<=0: return
  if position.distance_to(room.bed_position()) < 12:
   room.alive = false
   room.sleeping = false
   match_state.eliminations += 1
   match_state.record_event("elimination",target)
   exit_corridor = false
   state = State.EXIT

func choose_target(rooms: Array, excluded: int = -1) -> int:
 decision_count+=1
 _route_costs.clear()
 if (difficulty!="standard" or transformed) and _model_ref!=null and _model_ref.get_ref()!=null:
  var model=_model_ref.get_ref()
  if model.map_id!="legacy": _route_costs=model.hunter_route_costs(position)
 var best = -1
 var score = INF
 for room in rooms:
  if room.owner >= 0 and room.alive and room.sleeping and room.index != excluded:
   var value = target_score(room)
   if not _route_costs.is_empty():
    var travel=float(_route_costs.get(room.index,INF))
    if not is_finite(travel): continue
    value+=travel-position.distance_to(room.door_position())
   if value < score:
    best = room.index
    score = value
 if best < 0 and excluded >= 0:
  return choose_target(rooms)
 return best

func hurt(amount: float):
 if not is_finite(amount) or amount<=0 or state == State.DORMANT or state == State.DEAD:
  return
 hp = maxf(0,hp-amount*(BossCatalog.SURGE_VULNERABILITY if shadow_active(surge_room) else 1.0))
 hit_flash = 0.15
 if hp <= 0:
  state = State.DEAD
  transform_remaining=0
  _transform_exit_room=-1
  surge_remaining=0
  cancel_boss_attack()
  if _model_ref!=null and _model_ref.get_ref()!=null:
   var model=_model_ref.get_ref()
   if _previous_siege_room>=0: model.rooms[_previous_siege_room].repair_factor=1.0
   if transformed: model.record_event("boss_death",target,{"position":position})
