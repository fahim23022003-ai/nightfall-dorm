class_name MatchModel
extends RefCounted

signal feedback(message: String)
var items=ItemEffects.new()
var rooms: Array = []
var hunter: HunterState
var player_room = -1
var player_position = Vector2(500,410)
var tutorial_mode=false
var preparation = Catalog.PREPARATION
var time = 0.0
var result = ""
var running = true
var eliminations = 0
var shots = 0
var damage_dealt = 0.0
var bot_claimed = 0
var random = RandomNumberGenerator.new()
# Presentation reads these model-owned records; damage occurs only on impact.
var projectiles: Array = []
var combat_events: Array = []
var presentation_events: Array = []
var next_presentation_event_id=1
var next_projectile_id = 1
var next_combat_event_id = 1
var map_id="legacy"
var map_data: Dictionary={}
var _navigation=AStar2D.new()
var _player_navigation=AStar2D.new()
var _navigation_routes: Dictionary={}
var stage_id=""
var difficulty="standard"
var match_boosts: Dictionary={}
var stage_bonus: Dictionary={}
var strategy=MatchStrategy.new()
func configure_strategy(seed_value: int,archetype: String="",contract: String="",identity: int=0) -> bool:
 return strategy.configure(self,seed_value,archetype,contract,identity)

func configure_match(mode: String="standard", boosts: Dictionary={}):
 # Called once on a fresh match; loadout changes never alter an active room.
 if time>0 or player_room>=0 or strategy.enabled: return false
 difficulty=mode if RankCatalog.DIFFICULTIES.has(mode) else "standard"
 match_boosts=boosts.duplicate(true)
 hunter.configure(difficulty)
 hunter.configure_encounter(stage_id)
 return true

func configure_stage(id: String) -> bool:
 if time>0 or player_room>=0 or strategy.enabled: return false
 var stage=StageCatalog.stage(id)
 if stage.is_empty(): return false
 if not configure_map(stage.map): return false
 stage_id=id
 preparation=float(stage.preparation)
 hunter.stage_scaling={"hunter_hp":stage.hunter_hp,"hunter_damage":stage.hunter_damage,"hunter_speed":stage.hunter_speed}
 hunter.configure(difficulty)
 hunter.configure_encounter(stage_id)
 return true

func _init():
 reset()

func reset(seed_value: int = 1):
 items=ItemEffects.new()
 strategy=MatchStrategy.new()
 random.seed = seed_value
 rooms.clear()
 map_id="legacy"
 map_data={}
 _navigation.clear()
 _player_navigation.clear()
 _navigation_routes.clear()
 for i in range(6):
  var room=RoomState.new(i)
  var receiver=weakref(self)
  var room_index=i
  room.presentation_action.connect(func(type, data):
   var model=receiver.get_ref()
   if model!=null: model.record_event(type,room_index,data))
  rooms.append(room)
 hunter = HunterState.new()
 difficulty="standard"
 stage_id=""
 preparation=Catalog.PREPARATION
 match_boosts={}
 stage_bonus={}
 player_room = -1
 player_position = Vector2(500,410)
 time = 0
 result = ""
 running = true
 eliminations = 0
 shots = 0
 damage_dealt = 0
 bot_claimed = 0
 projectiles.clear()
 combat_events.clear()
 presentation_events.clear()
 next_presentation_event_id=1
 next_projectile_id = 1
 next_combat_event_id = 1

func map_bounds() -> Rect2:
 return map_data.bounds if not map_data.is_empty() else Rect2(35,100,900,620)

func configure_map(id: String) -> bool:
 if time>0 or player_room>=0: return false
 var data=MapCatalog.map(id)
 if data.is_empty(): return false
 map_id=id
 map_data=data
 _navigation_routes.clear()
 for i in range(rooms.size()): rooms[i].layout=data.rooms[i].duplicate(true)
 player_position=data.spawn
 hunter.position=data.hunter_spawn
 _build_navigation()
 return true

func navigation_walkable(point: Vector2) -> bool:
 if map_id=="legacy":
  if Rect2(35,320,930,180).has_point(point): return true
  for room in rooms:
   if room.bounds().has_point(point): return true
  return false
 for room in rooms:
  if room.bounds().has_point(point):
   if room.bounds().grow(-10).has_point(point):
    if point.distance_to(room.bed_position())<58: return true
    return not room.furniture_blocks(point)
   var offset=point-room.door_position()
   return absf(offset.x)<26 and absf(offset.y)<14 if absf(room.door_normal().y)>0 else absf(offset.y)<26 and absf(offset.x)<14
 for corridor in map_data.corridors:
  if corridor.grow(-8).has_point(point): return true
 return false

func _visible(a: Vector2,b: Vector2,player: bool=false) -> bool:
 var count=maxi(1,ceili(a.distance_to(b)/2.0))
 for i in range(count+1):
  var point=a.lerp(b,float(i)/count)
  if not (can_walk(point) if player else navigation_walkable(point)): return false
 return true

func _build_navigation():
 _navigation.clear()
 _player_navigation.clear()
 var points: Array=map_data.nodes.duplicate()
 for room in rooms:
  points.append(room.door_approach())
  points.append(room.door_position())
  points.append(room.door_position()-room.door_normal()*35)
  points.append(room.bed_position())
  points.append(room.bed_position()+Vector2(40,40))
  # Bottom corners let player paths approach either side of the bed without
  # treating the blocking bed footprint as walkable.
  points.append(room.bed_position()+Vector2(-31,49))
  points.append(room.bed_position()+Vector2(31,49))
  # Reserved access lane along the furniture strip, away from all build pads.
  if absf(room.door_normal().y)>0:
   points.append(Vector2(room.door_position().x,room.bed_position().y))
  else: points.append(Vector2(room.bed_position().x,room.door_position().y))
 for i in range(points.size()):
  _navigation.add_point(i,points[i])
  _player_navigation.add_point(i,points[i])
 for i in range(points.size()):
  for j in range(i):
   if _visible(points[i],points[j]): _navigation.connect_points(i,j)
   if _visible(points[i],points[j],true): _player_navigation.connect_points(i,j)

func player_navigation_path(from: Vector2,to: Vector2) -> Array:
 return navigation_path(from,to,true)

# Static corridor graph estimates for all candidate rooms in one decision.
# Only the nearest visible start needs testing; doorway endpoints already exist.
func hunter_route_costs(from: Vector2) -> Dictionary:
 var ids=Array(_navigation.get_point_ids())
 ids.sort_custom(func(a,b): return from.distance_squared_to(_navigation.get_point_position(a))<from.distance_squared_to(_navigation.get_point_position(b)))
 var start=-1
 for id in ids:
  if _visible(from,_navigation.get_point_position(id)):
   start=id
   break
 var result={}
 if start<0:
  for room in rooms: result[room.index]=INF
  return result
 for room in rooms:
  var end=_navigation.get_closest_point(room.door_approach())
  var points=_navigation.get_point_path(start,end)
  if points.is_empty(): result[room.index]=INF; continue
  var length=from.distance_to(points[0])
  for i in range(1,points.size()): length+=points[i-1].distance_to(points[i])
  result[room.index]=length
 return result

func navigation_path(from: Vector2,to: Vector2,player: bool=false) -> Array:
 if from.distance_to(to)<0.1: return []
 if _visible(from,to,player): return [to]
 if map_id=="legacy": return [to]
 var graph=_player_navigation if player else _navigation
 var start=9000
 var end=9001
 graph.add_point(start,from)
 graph.add_point(end,to)
 for id in graph.get_point_ids():
  if id>=start: continue
  var point=graph.get_point_position(id)
  if _visible(from,point,player): graph.connect_points(start,id)
  if _visible(to,point,player): graph.connect_points(end,id)
 var points=graph.get_point_path(start,end)
 graph.remove_point(start)
 graph.remove_point(end)
 var path: Array=[]
 for i in range(1,points.size()): path.append(points[i])
 return path

func step_navigation(from: Vector2,to: Vector2,distance: float,key: String="") -> Vector2:
 var route: Array=[]
 if key!="" and _navigation_routes.has(key):
  var saved=_navigation_routes[key]
  if saved.goal==to and saved.last.distance_to(from)<1: route=saved.route
 if route.is_empty(): route=navigation_path(from,to)
 var point=from
 var remaining=distance
 while not route.is_empty():
  var goal: Vector2=route[0]
  var length=point.distance_to(goal)
  if length>remaining:
   point=point.move_toward(goal,remaining)
   break
  point=goal
  remaining-=length
  route.pop_front()
 if key!="": _navigation_routes[key]={"goal":to,"last":point,"route":route}
 return point

func record_event(type: String, room_index: int, data: Dictionary={}):
 var global_event=type in ["boss_transform","boss_awakened","boss_death"]
 if (room_index<0 or room_index>=rooms.size()) and not global_event: return
 var event_position=hunter.position if global_event else rooms[room_index].door_position()
 var entry=data.duplicate(true)
 entry.merge({"id":next_presentation_event_id,"type":type,"room":room_index,
  "position":event_position,"time":time,"damage":data.get("damage",0.0),"transformed":hunter.transformed},true)
 next_presentation_event_id+=1
 presentation_events.append(entry)
 if presentation_events.size()>128: presentation_events.pop_front()
 strategy.event(type,room_index,self)

func claim_room(index: int) -> bool:
 if not running or result != "" or index < 0 or index >= rooms.size() or player_room >= 0 or rooms[index].owner >= 0:
  return false
 rooms[index].owner = 0
 rooms[index].apply_boosts(match_boosts)
 if not stage_bonus.is_empty():
  rooms[index].gold+=stage_bonus.get("gold",0.0)
  var old_max=rooms[index].max_hp()
  rooms[index].door_multiplier*=stage_bonus.get("door",1.0)
  rooms[index].door_hp+=rooms[index].max_hp()-old_max
 player_room = index
 feedback.emit("Room claimed. Approach the bed and press E to sleep.")
 return true

func sleep_player() -> bool:
 if not running or result != "" or player_room < 0:
  return false
 var room = rooms[player_room]
 if hunter.state != HunterState.State.DORMANT and room.bounds().has_point(hunter.position):
  feedback.emit("The hunter is already inside. You cannot lock it out now.")
  return false
 if not room.alive:
  feedback.emit("Your resident has been eliminated.")
  return false
 if player_position.distance_to(room.bed_position()) > 60:
  feedback.emit("Move closer to your bed, then press E.")
  return false
 for occupied in rooms:
  if hunter.state != HunterState.State.DORMANT and occupied.bounds().has_point(hunter.position):
   hunter.request_exit(occupied.index)
 room.closed = true
 room.sleeping = true
 player_position = room.bed_position()
 feedback.emit("Door locked. Build defenses on the marked floor pads.")
 return true

func player() -> RoomState:
 return rooms[player_room] if player_room >= 0 else null

func buy(kind: String, tile: int) -> bool:
 return player().build(kind,tile) if _can_purchase() else false

func upgrade_bed() -> bool:
 return player().upgrade_bed() if _can_purchase() else false

func upgrade_door() -> bool:
 return player().upgrade_door() if _can_purchase() else false

func repair_door() -> bool:
 return player().repair_door() if _can_purchase() else false

func upgrade_building(tile: int) -> bool:
 return player().upgrade_building(tile) if _can_purchase() else false

func specialize_building(tile: int,branch: String) -> bool:
 return player().specialize_building(tile,branch) if _can_purchase() else false

func sell_building(tile: int) -> bool:
 return player().sell_building(tile) if _can_purchase() else false

func _can_purchase() -> bool:
 return running and result == "" and player() != null and player().alive

func purchase_error() -> String:
 if result != "":
  return "The match has ended. Restart to play again."
 if not running:
  return "Match paused. Resume before purchasing."
 if player() == null:
  return "Enter a free room and press E to claim it first."
 return player().last_error

func move_player(direction: Vector2, delta: float):
 if not running or result != "" or (player() != null and player().sleeping):
  return
 if not is_finite(delta):
  return
 var remaining = clampf(delta,0,0.25)
 while remaining > 0:
  var step = minf(remaining,0.02)
  var destination = player_position + direction.limit_length()*180.0*step
  if can_walk(Vector2(destination.x,player_position.y)):
   player_position.x = destination.x
  if can_walk(Vector2(player_position.x,destination.y)):
   player_position.y = destination.y
  remaining -= step

func can_walk(point: Vector2) -> bool:
 if map_id!="legacy":
  for room in rooms:
   if room.bounds().has_point(point):
    if room.closed or (room.owner>=0 and room.owner!=0): return false
    if room.furniture_blocks(point): return false
    if room.bounds().grow(-12).has_point(point): return true
    if absf(room.door_normal().y)>0:
     return absf(point.x-room.door_position().x)<26
    return absf(point.y-room.door_position().y)<26
  for corridor in map_data.corridors:
   if corridor.grow(-10).has_point(point): return true
  return false
 if Rect2(35,335,900,150).has_point(point):
  return true
 for room in rooms:
  if room.bounds().grow(-12).has_point(point) and (room.owner < 0 or room.owner == 0) and not room.closed:
   return not room.furniture_blocks(point)
  if absf(point.x-room.center().x)<26 and point.y>300 and point.y<520 and not room.closed and (room.owner < 0 or room.owner == 0):
   return true
 return false

func interact():
 if player_room < 0:
  for room in rooms:
   if room.bounds().has_point(player_position):
    claim_room(room.index)
    return
  feedback.emit("Enter an unclaimed room, then press E.")
 else:
  sleep_player()

func tick(delta: float):
 if not running or result != "" or not is_finite(delta) or delta <= 0:
  return
 _age_combat_events(delta)
 time += delta
 items.tick(delta,self)
 strategy.observe(self)
 if bot_claimed < 5 and time > 6+bot_claimed*1.7:
  var options: Array = []
  for room in rooms:
   if room.owner < 0 and not room.bounds().has_point(player_position):
    options.append(room)
  var physically_reserved = false
  for candidate in rooms:
   if candidate.owner < 0 and candidate.bounds().has_point(player_position):
    physically_reserved = true
  if not options.is_empty() and (options.size()>1 or player_room>=0 or physically_reserved):
   var room = options[random.randi_range(0,options.size()-1)]
   room.owner = bot_claimed+1
   room.profile = Catalog.BOT_PROFILES[bot_claimed]
   room.resident_position = room.door_position()+Vector2(0,22 if room.index<3 else -22) if map_id=="legacy" else map_data.spawn
   bot_claimed += 1
 for room in rooms:
  if room.owner > 0 and room.alive and not room.sleeping:
   room.resident_position = room.resident_position.move_toward(room.bed_position(),120*delta) if map_id=="legacy" else step_navigation(room.resident_position,room.bed_position(),120*delta,"bot_"+str(room.index))
   if room.resident_position.distance_to(room.bed_position())<2:
    room.sleeping = true
    room.closed = true
  room.tick_economy(delta)
  if room.owner > 0:
   BotAI.tick(room,delta)
 var exposed = time > preparation+25 and (player() == null or not player().sleeping)
 if exposed:
  hunter.tick(delta if hunter.state==HunterState.State.TRANSFORM else 0.0,self)
  if hunter.state not in [HunterState.State.TRANSFORM,HunterState.State.DEAD] and delta>items.frozen_delta:
   hunter.cancel_boss_attack()
   hunter.state = HunterState.State.MOVE
   var previous=hunter.position
   _pursue_exposed_player(maxf(0,delta-items.frozen_delta))
   items.trigger_segment(previous,hunter.position,self)
 else:
  hunter.tick(delta,self)
 # A breach resolves before pending teammate shots can revive a lost match.
 if player_room >= 0 and not rooms[player_room].alive:
  result = "defeat"
  items.clear(self)
  hunter.stop_combat(self)
  _cancel_projectiles("terminal")
  strategy.seal(self)
  return
 # Contact with an exposed survivor has the same priority as a room breach.
 if exposed and hunter.state!=HunterState.State.TRANSFORM and hunter.hp > 0 and hunter.position.distance_to(player_position)<15:
  if player() != null:
   player().eliminated_position=player_position
   player().alive = false
   player().sleeping = false
   record_event("elimination",player_room,{"survivor_position":player_position})
  eliminations += 1
  result = "defeat"
  items.clear(self)
  hunter.stop_combat(self)
  _cancel_projectiles("terminal")
  strategy.seal(self)
  return
 _advance_projectiles(delta)
 _turrets(delta)
 if player_room >= 0 and not rooms[player_room].alive:
  result = "defeat"
 elif hunter.hp <= 0:
  result = "victory"
 if result != "":
  items.clear(self)
  hunter.stop_combat(self)
  _cancel_projectiles("terminal")
  strategy.seal(self)

func _turrets(delta: float):
 if not running or result != "":
  return
 for room in rooms:
  if not room.alive:
   continue
  var multiplier = 1.0
  for b in room.buildings.values():
   if b.kind == "enhancer":
    multiplier += Catalog.BUILDINGS.enhancer.rate*b.level
  for tile in room.buildings:
   var b = room.buildings[tile]
   if b.kind != "turret" and b.kind != "heavy":
    continue
   b.cooldown = maxf(-delta,b.cooldown-delta)
   var data = Catalog.BUILDINGS[b.kind]
   var branch=StrategyCatalog.weapon(b)
   if not hunter.shadow_active(room.index) and hunter.hp > 0 and hunter.state != HunterState.State.DORMANT and hunter.state != HunterState.State.DEAD and room.tile_position(tile).distance_to(hunter.position)<=data.range*branch.range and b.cooldown <= 0:
    var amount = Catalog.turret_damage(b.kind,b.level)*multiplier*room.turret_multiplier*branch.damage
    if projectiles.size() >= Catalog.PROJECTILES.max_active:
     continue
    var origin = room.tile_position(tile)
    var shot = {"id":next_projectile_id,"from":origin,"position":origin,"target_id":1,"damage":amount,"speed":Catalog.PROJECTILES[b.kind]*branch.speed,"kind":b.kind,"room":room.index,"level":b.level,"age":0.0,"specialization":b.get("specialization",""),"slow":branch.slow}
    next_projectile_id += 1
    projectiles.append(shot)
    _combat_event("launch",shot,origin,0.0)
    shots += 1
    room.shots += 1
    b.flash = 0.15
    b.cooldown += Catalog.turret_interval(b.kind,b.level)*branch.interval/(ItemCatalog.TUNING.overdrive_rate if room.owner==0 and float(items.timers.get("overdrive",0))>0 else 1.0)

func _advance_projectiles(delta: float):
 if not running or result != "" or not is_finite(delta) or delta <= 0:
  return
 var survivors: Array = []
 for shot in projectiles:
  if hunter.hp <= 0 or hunter.state in [HunterState.State.DORMANT,HunterState.State.DEAD] or shot.target_id != 1:
   _combat_event("cancel",shot,shot.position,0.0,"invalid_target")
   continue
  shot.age += delta
  if shot.age > Catalog.PROJECTILES.max_age:
   _combat_event("cancel",shot,shot.position,0.0,"expired")
   continue
  var travel = shot.speed*delta
  if shot.position.distance_to(hunter.position) <= travel:
   shot.position = hunter.position
   var previous_hp = hunter.hp
   var hit=shot.damage
   if shot.room==player_room:
    if hunter.transformed:hit*=match_boosts.get("reaper",1.0)
    if time<preparation+stage_bonus.get("seconds",0.0):hit*=stage_bonus.get("damage",1.0)
   hunter.hurt(hit)
   if float(shot.get("slow",0))>0:hunter.apply_suppression(float(shot.slow))
   items.ignite(self,shot.room)
   var applied_damage = previous_hp-hunter.hp
   damage_dealt += applied_damage
   rooms[shot.room].damage_dealt += applied_damage
   _combat_event("impact",shot,shot.position,applied_damage)
  else:
   shot.position = shot.position.move_toward(hunter.position,travel)
   survivors.append(shot)
 projectiles = survivors

func _combat_event(type: String, shot: Dictionary, position: Vector2, damage: float, reason: String = ""):
 combat_events.append({"id":next_combat_event_id,"type":type,"projectile_id":shot.id,"position":position,"room":shot.room,"kind":shot.kind,"level":shot.level,"specialization":shot.get("specialization",""),"damage":damage,"time":time,"remaining":Catalog.PROJECTILES.event_lifetime,"reason":reason})
 next_combat_event_id += 1
 if combat_events.size() > Catalog.PROJECTILES.max_events:
  combat_events.pop_front()

func _age_combat_events(delta: float):
 for event in combat_events:
  event.remaining -= delta
 combat_events = combat_events.filter(func(event): return event.remaining > 0)

func _cancel_projectiles(reason: String):
 for shot in projectiles:
  _combat_event("cancel",shot,shot.position,0.0,reason)
 projectiles.clear()

func _pursue_exposed_player(delta: float):
 if map_id!="legacy":
  hunter.position=step_navigation(hunter.position,player_position,hunter.speed*delta,"pursue")
  return
 var current_room = null
 var destination_room = null
 for room in rooms:
  if room.bounds().has_point(hunter.position):
   current_room = room
  if room.bounds().has_point(player_position):
   destination_room = room
 var waypoint = player_position
 if current_room != null and current_room != destination_room:
  waypoint = current_room.door_position()+Vector2(0,22 if current_room.index<3 else -22)
 elif destination_room != null and current_room != destination_room:
  var entry = destination_room.door_position()
  if absf(hunter.position.x-entry.x)>3:
   waypoint = Vector2(hunter.position.x,410) if absf(hunter.position.y-410)>3 else Vector2(entry.x,410)
  else:
   waypoint = entry+Vector2(0,-20 if destination_room.index<3 else 20)
 elif destination_room == null and current_room == null:
  if absf(hunter.position.y-410)>3 and absf(hunter.position.x-player_position.x)>3:
   waypoint = Vector2(hunter.position.x,410)
 hunter.position = hunter.position.move_toward(waypoint,hunter.speed*delta)
