extends SceneTree
## Match an idle or actively claiming human across both Room Rush policies.

const STEP:=.25
const LIMIT:=240.0

class CountedMatch extends MatchModel:
 var npc_attempts:=0
 var npc_denied:=0
 var human_denied:=0

 func try_claim_survivor(index: int,owner: int,position: Vector2) -> bool:
  var claimed:=super.try_claim_survivor(index,owner,position)
  if owner>0:
   npc_attempts+=1
   if not claimed:npc_denied+=1
  elif not claimed:
   human_denied+=1
  return claimed

class RushTrace extends RoomRush:
 var active_owner:=0
 var traveled: Dictionary={}
 var peak_budget_error:=0.0
 var plans:=0
 var reassignments:=0
 var max_replan_ms:=0.0
 var timeline:=[]

 func advance(model, from: Vector2, route: Array, distance: float, access: int) -> Vector2:
  if active_owner>0:
   var position:=from
   var measured:=0.0
   for waypoint: Vector2 in route:
    var next:=position.move_toward(waypoint,maxf(0.0,distance-measured))
    if not model.can_walk(next,access):break
    measured+=position.distance_to(next)
    position=next
    if not position.is_equal_approx(waypoint):break
   traveled[active_owner]=float(traveled.get(active_owner,0.0))+measured
   peak_budget_error=maxf(peak_budget_error,measured-distance)
  return super.advance(model,from,route,distance,access)

 func select_target(model, runner: Dictionary, paths: Dictionary) -> void:
  var previous: int=runner.target
  super.select_target(model,runner,paths)
  if previous>=0 and previous!=runner.target and not planned_pacing:
   record_change(model,runner,previous)

 func plan_intents(model, shared_routes: Dictionary={}) -> void:
  plans+=1
  var previous:=runners.map(func(runner):return runner.target)
  var started:=Time.get_ticks_usec()
  super.plan_intents(model,shared_routes)
  max_replan_ms=maxf(max_replan_ms,(Time.get_ticks_usec()-started)/1000.0)
  for index in range(runners.size()):
   if previous[index]>=0 and runners[index].target!=previous[index]:
    record_change(model,runners[index],previous[index])

 func record_change(model,runner: Dictionary, previous: int) -> void:
  reassignments+=1
  timeline.append({
   "type":"redirect","time":model.time,"owner":runner.owner,"from":previous,
   "room":runner.target,"walked":traveled.get(runner.owner,0.0),
  })

 func route_runner(model, runner: Dictionary, distance: float) -> bool:
  var prior: int=runner.target
  active_owner=runner.owner
  var result:=super.route_runner(model,runner,distance)
  active_owner=0
  if prior>=0 and runner.target!=prior and not timeline.any(func(marker):return marker.type=="redirect" and marker.time==model.time and marker.owner==runner.owner):
   record_change(model,runner,prior)
  if result:record_claim(model,runner)
  return result

 func follow_intent(model, runner: Dictionary, distance: float) -> bool:
  active_owner=runner.owner
  var result:=super.follow_intent(model,runner,distance)
  active_owner=0
  if result:record_claim(model,runner)
  return result

 func record_claim(model,runner: Dictionary) -> void:
  timeline.append({"type":"claimed","time":model.time,"owner":runner.owner,"room":runner.target,"walked":traveled.get(runner.owner,0.0)})

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 var failures:=0
 var suite:=OS.get_cmdline_user_args()
 var broad:=not suite.has("--original-only")
 var samples:=35 if not broad else 80
 for i in range(samples):
  var theme: String=MapCatalog.IDS[i%5]
  var seed:=147+i*283
  if i>=30 and i<35:
   while NightmareMacroLayout.family_for(theme,seed)!="spine":seed+=1
  if i>=35:
   var harder: String=["spine","labyrinth","branching"][posmod(i-35,3)]
   while NightmareMacroLayout.family_for(theme,seed)!=harder:seed+=1
  var idle:=measure(theme,seed,11+i,false)
  print("PACING_SAMPLE ",JSON.stringify(idle))
  if not idle.ok:failures+=1
  if broad and i>=35:
   var active:=measure(theme,seed,11+i,true)
   print("PACING_SAMPLE ",JSON.stringify(active))
   if not active.ok:failures+=1
 print("PACING_DONE phase16=",OS.get_environment("NIGHTFALL_PHASE16")," samples=",samples if not broad else 125," failures=",failures)
 quit(int(failures>0))

func measure(theme: String,seed: int,nonce: int,active: bool) -> Dictionary:
 var model:=CountedMatch.new()
 model.procedural_v2_requested=true
 model.reset(seed)
 var ready:=model.configure_map(theme)
 var trace:=RushTrace.new()
 model.room_rush=trace
 var start:=Time.get_ticks_usec()
 var started:=ready and model.begin_room_rush(nonce)
 var setup_ms: float=(Time.get_ticks_usec()-start)/1000.0
 var result: Dictionary={"theme":theme,"seed":seed,"nonce":nonce,"active_human":active,"ok":false}
 if not started:return result
 var origin:=model.room_rush_spawn()
 var available:=trace.routes_to_vacant_rooms(model,origin)
 var direct: Dictionary={}
 var fastest:=INF
 var player_route: Array=[]
 var player_target:=-1
 for index: int in available:
  var distance:=trace.route_length(origin,available[index])
  direct[index]=distance
  if distance<fastest:
   fastest=distance
   player_target=index
   player_route=available[index].duplicate()
 result.origin=[origin.x,origin.y]
 result.family=model.map_data.family
 result.map_hash=JSON.stringify(NightmareMap.pack(model.map_data),"",true,true).sha256_text()
 result.direct=direct
 result.initial=trace.runners.map(func(runner):return runner.target)
 result.setup_ms=setup_ms
 result.nearest_seconds=fastest/model.SURVIVOR_SPEED
 var ownership_clear: bool=model.rooms.all(func(room):return room.owner<0)
 var shared_origin: bool=trace.runners.all(func(runner):return runner.position==origin)
 var human_claim:=-1.0
 var stamps: Array[float]=[]
 while model.time<LIMIT and model.bot_claimed<5:
  model.time+=STEP
  if active and model.player_room<0:
   model.player_position=trace.advance(model,model.player_position,player_route,model.SURVIVOR_SPEED*STEP,-1)
   if player_route.is_empty() and model.claim_room(player_target):human_claim=model.time
  var previous: int=model.bot_claimed
  trace.tick(model,STEP)
  for _claim in range(previous,model.bot_claimed):stamps.append(model.time)
 result.claims=stamps
 result.human_claim=human_claim
 result.walked=trace.traveled
 result.plan_calls=trace.plans
 result.max_replan_ms=trace.max_replan_ms
 result.reassignments=trace.reassignments
 result.claim_attempts={"npc":model.npc_attempts,"npc_denied":model.npc_denied,"human_denied":model.human_denied}
 result.peak_budget_error=trace.peak_budget_error
 result.ok=ownership_clear and shared_origin and available.size()==6 and model.bot_claimed==5 and result.nearest_seconds<=12.0 and trace.peak_budget_error<.002 and (not active or human_claim>=0.0)
 if seed==8649 or (active and nonce%7==0):result.timeline=trace.timeline
 return result
