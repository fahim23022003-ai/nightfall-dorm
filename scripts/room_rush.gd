class_name RoomRush
extends RefCounted
## The opening race gives each survivor a body position, not a room reservation.
const BOT_COUNT:=5
const ENTRY_DEPTHS:=[35.0,24.0,18.0,14.0,8.0]
const BED_REACH:=60.0
const RETRY_SECONDS:=.35
const MAX_NEAREST_SECONDS:=12.0
const APPROACH_TRAFFIC_COST:=220.0
const INTENT_CHANGE_COST:=24.0
const STALL_SECONDS:=.55

var attempt_id:=0
var spawn:=Vector2.INF
var runners: Array[Dictionary]=[]
var bed_routes: Dictionary={}
var planned_pacing:=OS.get_environment("NIGHTFALL_PHASE16")=="1"

static func preview_requested() -> bool:
 var value:=OS.get_environment("NIGHTFALL_SURVIVOR_REBIRTH")
 return value=="1" or (value=="" and OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE")=="1")

func start(model, nonce: int) -> bool:
 if nonce<=0 or attempt_id!=0 or model.time>0.0 or model.player_room>=0 or model.bot_claimed>0:
  return false
 # Set the marker only while planning, so the legacy fixed corridor uses its
 # actual navigation graph instead of the historical direct fixture path.
 attempt_id=nonce
 if model.map_id=="legacy":model._build_navigation()
 var candidates:=spawn_candidates(model)
 if candidates.is_empty():
  attempt_id=0
  return false
 var base:=posmod(model.map_seed,candidates.size())
 var first:=posmod(base+posmod(nonce,candidates.size()),candidates.size())
 var routes: Dictionary={}
 for offset in range(candidates.size()):
  var candidate: Vector2=candidates[(first+offset)%candidates.size()]
  routes=routes_to_vacant_rooms(model,candidate)
  if routes.size()==model.rooms.size() and nearest_room_distance(candidate,routes)<=model.SURVIVOR_SPEED*MAX_NEAREST_SECONDS:
   spawn=candidate
   break
 if not spawn.is_finite():
  attempt_id=0
  return false
 model.player_position=spawn
 for id in range(1,BOT_COUNT+1):
  var runner: Dictionary={"owner":id,"position":spawn,"target":-1,"route":[],"retry_at":0.0}
  if not planned_pacing:select_target(model,runner,routes)
  runners.append(runner)
 if planned_pacing:plan_intents(model,routes)
 return true

func spawn_candidates(model) -> Array[Vector2]:
 var candidates: Array[Vector2]=[]
 if model.map_id=="legacy":
  for x in [105.0,200.0,315.0,420.0,500.0,585.0,710.0,830.0,900.0]:
   candidates.append(Vector2(x,410.0))
 else:
  for node: Vector2 in model.map_data.nodes:
   candidates.append(node)
  if not candidates.has(model.map_data.spawn):candidates.append(model.map_data.spawn)
  for lane: Rect2 in model.map_data.corridors:
   var center:=lane.get_center()
   if not candidates.has(center):candidates.append(center)
 var legal: Array[Vector2]=[]
 for candidate in candidates:
  if legal.has(candidate) or not exterior(model,candidate) or not model.can_walk(candidate):
   continue
  legal.append(candidate)
 legal.sort_custom(func(a: Vector2,b: Vector2):return a.y<b.y if a.x==b.x else a.x<b.x)
 return legal

static func exterior(model, point: Vector2) -> bool:
 if not point.is_finite():return false
 for room: RoomState in model.rooms:
  if room.floor_has_point(point):return false
 for hall: Dictionary in model.map_data.get("halls",{}).values():
  if Rect2(hall.bounds).has_point(point):return false
 return true

func can_claim(model, index: int, position: Vector2) -> bool:
 if index<0 or index>=model.rooms.size() or not position.is_finite():
  return false
 var room: RoomState=model.rooms[index]
 return room.owner<0 and not room.closed and room.alive and room.floor_has_point(position) and model.can_walk(position)

func position_for(owner: int) -> Vector2:
 for runner in runners:
  if runner.get("owner",-1)==owner:return runner.position
 return Vector2.INF

func egress_room(model, position: Vector2, owner: int=0) -> int:
 # A loser already inside may walk back out through the actual doorway.
 # Their access ends immediately once they leave the rival's room.
 for room: RoomState in model.rooms:
  if room.owner>=0 and room.owner!=owner and room.floor_has_point(position):
   return room.index
 return -1

func routes_to_vacant_rooms(model, from: Vector2, owner: int=0) -> Dictionary:
 var paths: Dictionary={}
 var access:=egress_room(model,from,owner)
 for room: RoomState in model.rooms:
  if room.owner>=0 or not room.alive or room.closed:continue
  var path:=claim_path(model,room,from,access)
  if not path.is_empty():paths[room.index]=path
 return paths

func claim_path(model, room: RoomState, from: Vector2, access: int) -> Array:
 if can_claim(model,room.index,from):return [from]
 for depth: float in ENTRY_DEPTHS:
  var entry:=room.door_position()-room.door_normal()*depth
  if not can_claim(model,room.index,entry):continue
  var route:=safe_path(model,from,entry,access)
  if not route.is_empty():return route
 return []

func safe_path(model, from: Vector2, to: Vector2, access: int) -> Array:
 var path: Array=model.navigation_path(from,to,true,0,access)
 if path.is_empty() or not Vector2(path.back()).is_equal_approx(to):return []
 var previous:=from
 for point: Vector2 in path:
  if not model._visible(previous,point,true,access):return []
  previous=point
 return path

static func route_length(from: Vector2, path: Array) -> float:
 var previous:=from
 var distance:=0.0
 for point: Vector2 in path:
  distance+=previous.distance_to(point)
  previous=point
 return distance

func nearest_room_distance(from: Vector2, paths: Dictionary) -> float:
 var nearest:=INF
 for path: Array in paths.values():
  nearest=minf(nearest,route_length(from,path))
 return nearest

func select_target(model, runner: Dictionary, paths: Dictionary) -> void:
 var best:=-1
 var score:=INF
 var hunter_spawn: Vector2=model.map_data.get("hunter_spawn",model.hunter.position)
 for index: int in paths:
  var distance:=route_length(runner.position,paths[index])
  var approaching:=0
  for other: Dictionary in runners:
   if other.get("target",-1)==index and other.get("owner",-1)!=runner.owner:
    approaching+=1
  var exposed:=maxf(0.0,330.0-hunter_spawn.distance_to(model.rooms[index].door_approach()))*.25
  var preference:=float(posmod(attempt_id%131*43+int(runner.owner)*67+index*(31+int(runner.owner)*29),131))
  # Disperse obvious queues without treating a destination as occupied.
  # Strong local geometry may still make several competitors choose it.
  var cost:=distance+exposed+preference+APPROACH_TRAFFIC_COST*mini(approaching,2)
  if cost<score or (cost==score and index<best):
   score=cost
   best=index
 runner.target=best
 runner.route=paths[best].duplicate() if best>=0 else []
 runner.retry_at=model.time+RETRY_SECONDS

func needs_intents(model) -> bool:
 for runner: Dictionary in runners:
  var target: int=runner.get("target",-1)
  if target>=0 and model.rooms[target].owner>=0:return true
  if runner.route.is_empty() and model.time>=runner.retry_at:return true
 return false

func plan_intents(model, shared_routes: Dictionary={}) -> void:
 if shared_routes.is_empty() and match_intents(model,shared_routes,true):return
 match_intents(model,shared_routes,false)

func match_intents(model, shared_routes: Dictionary, keep_usable_routes: bool) -> bool:
 var hunter_spawn: Vector2=model.map_data.get("hunter_spawn",model.hunter.position)
 var routes: Array[Dictionary]=[]
 var costs: Array[Dictionary]=[]
 for runner: Dictionary in runners:
  var target: int=runner.target
  var paths:=shared_routes
  if paths.is_empty():
   # A single lost destination need not recalculate every live path.
   if keep_usable_routes and target>=0 and not runner.route.is_empty() and can_continue_intent(model,target):
    paths={target:runner.route}
   else:
    paths=routes_to_vacant_rooms(model,runner.position,runner.owner)
  var avoid: int=runner.get("failed_room",-1)
  if paths.size()>1 and paths.has(avoid):
   paths=paths.duplicate()
   paths.erase(avoid)
  var options: Dictionary={}
  for index: int in paths:
   var room: RoomState=model.rooms[index]
   var distance:=route_length(runner.position,paths[index])
   var exposed:=maxf(0.0,330.0-hunter_spawn.distance_to(room.door_approach()))*.25
   var personal:=float(posmod(attempt_id%131*43+int(runner.owner)*67+index*(31+int(runner.owner)*29),131))
   var desirability: float=(float(room.trait_modifiers.get("door",1.0))-1.0)*90.0+(float(room.trait_modifiers.get("income",1.0))-1.0)*80.0
   var change:=INTENT_CHANGE_COST if runner.target>=0 and runner.target!=index else 0.0
   options[index]=Vector2(distance,distance+exposed+personal-desirability+change)
  routes.append(paths)
  costs.append(options)
 var best: Dictionary={"result":[],"arrival":INF,"cost":INF}
 rank_intents(costs,0,0,[],0.0,0.0,model.SURVIVOR_SPEED*.25,best)
 var assignment: Array=best.result
 if assignment.is_empty() and keep_usable_routes:return false
 for i in range(runners.size()):
  var runner:=runners[i]
  if assignment.is_empty():
   # Unexpected geometry may leave some actors with only overlapping viable
   # routes. They retain the ability to race for a shared destination.
   select_target(model,runner,routes[i])
  else:
   var target: int=assignment[i]
   runner.target=target
   runner.route=routes[i][target].duplicate()
   runner.retry_at=model.time+RETRY_SECONDS
  runner.erase("failed_room")
  runner.stalled=0.0
 return true

func can_continue_intent(model, target: int) -> bool:
 var room: RoomState=model.rooms[target]
 return room.owner<0 and room.alive and not room.closed

func rank_intents(costs: Array[Dictionary], slot: int, chosen_mask: int, selected: Array, distance: float, total: float, eta_band_distance: float, best: Dictionary) -> void:
 # Shorter worst predicted elapsed distance wins, at half-second resolution.
 # Prefer efficient, safe and attractive routes among the same ETA band.
 var arrival:=ceilf(distance/eta_band_distance)
 if arrival>best.arrival:return
 if slot==costs.size():
  if arrival<best.arrival or (arrival==best.arrival and total<best.cost):
   best.result=selected.duplicate()
   best.arrival=arrival
   best.cost=total
  return
 for index: int in costs[slot]:
  var bit:=1<<index
  if chosen_mask&bit:continue
  var option: Vector2=costs[slot][index]
  selected.append(index)
  rank_intents(costs,slot+1,chosen_mask|bit,selected,maxf(distance,option.x),total+option.y,eta_band_distance,best)
  selected.pop_back()

func follow_intent(model, runner: Dictionary, distance: float) -> bool:
 var target: int=runner.target
 if target<0 or model.rooms[target].owner>=0 or runner.route.is_empty():return false
 var before: Vector2=runner.position
 runner.position=advance(model,before,runner.route,distance,egress_room(model,before,runner.owner))
 if runner.route.is_empty():
  if model.try_claim_survivor(target,runner.owner,runner.position):return true
  runner.failed_room=target
  runner.retry_at=0.0
 elif before.distance_to(runner.position)<minf(.25,distance*.25):
  runner.stalled=float(runner.get("stalled",0.0))+distance/(model.SURVIVOR_SPEED*.5)
  if runner.stalled>=STALL_SECONDS:
   runner.route.clear()
   runner.failed_room=target
   runner.retry_at=0.0
 else:
  runner.stalled=0.0
 return false

func tick(model, delta: float) -> void:
 var distance: float=model.SURVIVOR_SPEED*.5*delta
 # Already-owned actors walk first. A newly claimed runner cannot receive a
 # second movement budget in the same simulation tick.
 for room: RoomState in model.rooms:
  if room.owner>0 and room.alive and not room.sleeping:
   approach_bed(model,room,distance)
 if planned_pacing and needs_intents(model):plan_intents(model)
 for index in range(runners.size()):
  var runner:=runners[index]
  var arrived:=follow_intent(model,runner,distance) if planned_pacing else route_runner(model,runner,distance)
  if arrived:
   runners[index]={}
 runners=runners.filter(func(runner):return not runner.is_empty())

func route_runner(model, runner: Dictionary, distance: float) -> bool:
 var target: int=runner.target
 if target>=0 and model.rooms[target].owner>=0:
  runner.target=-1
  runner.route.clear()
  runner.retry_at=0.0
 if runner.route.is_empty():
  if target>=0 and runner.target==target:
   runner.route=claim_path(model,model.rooms[target],runner.position,egress_room(model,runner.position,runner.owner))
  if runner.route.is_empty() and model.time>=runner.retry_at:
   select_target(model,runner,routes_to_vacant_rooms(model,runner.position,runner.owner))
 if runner.target<0 or runner.route.is_empty():
  return false
 var access:=egress_room(model,runner.position,runner.owner)
 runner.position=advance(model,runner.position,runner.route,distance,access)
 return runner.route.is_empty() and model.try_claim_survivor(runner.target,runner.owner,runner.position)

func approach_bed(model, room: RoomState, distance: float) -> void:
 if room.resident_position.distance_to(room.bed_position())<=BED_REACH:
  sleep(room)
  return
 var route: Array=bed_routes.get(room.index,[])
 if route.is_empty():
  route=find_bed_path(model,room)
 room.resident_position=advance(model,room.resident_position,route,distance,room.index)
 bed_routes[room.index]=route
 if room.resident_position.distance_to(room.bed_position())<=BED_REACH:
  sleep(room)

func find_bed_path(model, room: RoomState) -> Array:
 var bed:=room.bed_position()
 var closest: Array=[]
 var distance:=INF
 for side in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
  var goal: Vector2=bed+side*54.0
  if not room.floor_has_point(goal) or not model.can_walk(goal,room.index):continue
  var path:=safe_path(model,room.resident_position,goal,room.index)
  if not path.is_empty() and room.resident_position.distance_squared_to(goal)<distance:
   closest=path
   distance=room.resident_position.distance_squared_to(goal)
 return closest

func sleep(room: RoomState) -> void:
 # Same bed interaction as the player: the body walks to the interaction
 # radius, then the sleeping pose anchors to the bed.
 room.resident_position=room.bed_position()
 room.sleeping=true
 room.closed=true
 bed_routes.erase(room.index)

func advance(model, from: Vector2, route: Array, distance: float, access: int) -> Vector2:
 var at:=from
 var remaining:=distance
 while not route.is_empty():
  var waypoint: Vector2=route.front()
  var length:=at.distance_to(waypoint)
  var next:=at.move_toward(waypoint,remaining)
  if not model.can_walk(next,access):
   route.clear()
   break
  at=next
  if remaining<length:break
  route.pop_front()
  remaining-=length
 return at

func snapshot() -> Dictionary:
 var pending: Array[Dictionary]=[]
 for runner in runners:
  var position: Vector2=runner.position
  pending.append({"owner":runner.owner,"position":[position.x,position.y],"target":runner.target})
 return {"attempt_id":attempt_id,"spawn":[spawn.x,spawn.y],"runners":pending}

func restore(data: Dictionary) -> void:
 attempt_id=int(data.attempt_id)
 spawn=Vector2(data.spawn[0],data.spawn[1])
 runners.clear()
 for saved: Dictionary in data.runners:
  runners.append({"owner":int(saved.owner),"position":Vector2(saved.position[0],saved.position[1]),"target":int(saved.target),"route":[],"retry_at":0.0})
 runners.sort_custom(func(a: Dictionary,b: Dictionary):return a.owner<b.owner)
