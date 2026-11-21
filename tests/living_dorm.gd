extends SceneTree

var checks:=0
var failures:=0

func _initialize() -> void:
 run.call_deferred()

func check(ok: bool, detail: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(detail)

func fresh(seed_value: int) -> MatchModel:
 var model:=MatchModel.new()
 model.reset(seed_value)
 model.procedural_v2_requested=true
 model.close_quarters_requested=true
 model.living_dorm_requested=true
 model.mini_hunters_requested=true
 model.full_grid_requested=true
 model.substantial_grid_requested=true
 check(model.configure_stage("stage_2") and model.configure_strategy(seed_value,"stalker") and model.configure_balance(),"prepare opted-in Campaign")
 check(model.claim_room(0),"claim an available room")
 model.player_position=model.player().bed_position()
 check(model.sleep_player(),"enter the bed")
 for index in [1,2]:
  var room: RoomState=model.rooms[index]
  room.owner=index
  room.sleeping=true
  room.closed=true
 return model

func run() -> void:
 var model:=fresh(10358)
 var hunter:=model.hunter
 var timeline: Array[int]=[]
 for index in range(9):
  var selected: int=hunter.choose_target(model.rooms)
  check(selected in [0,1,2] and not model.navigation_path(hunter.position,model.rooms[selected].door_approach()).is_empty(),"a legal sleeping room was sampled")
  timeline.append(selected)
  hunter._remember_living_target(model,selected,"test")
 var repeat:=fresh(10358)
 for expected in timeline:
  var selected: int=repeat.hunter.choose_target(repeat.rooms)
  check(selected==expected,"same seed repeats target sequence")
  repeat.hunter._remember_living_target(repeat,selected,"test")
 var varied: Dictionary={}
 for seed_value in range(50):
  varied[hunter._living_choice(fresh(seed_value),{0:18.0,1:20.0,2:21.0,3:600.0})]=true
 check(varied.size()==3 and not varied.has(3),"different seeds choose each viable room and omit an expensive door")
 hunter.target=0
 hunter.state=HunterState.State.ATTACK
 hunter.position=model.rooms[0].door_approach()
 hunter.siege_start_hp=model.rooms[0].door_hp+50.0
 hunter.siege_landed_damage=50.0
 hunter.reassess_seconds=18.0
 hunter._reassess_tactical_siege(model.rooms[0],model)
 check(hunter.target==0 and hunter.state==HunterState.State.ATTACK,"productive siege stays")
 var closed_door: RoomState=model.rooms[0]
 var open_target: RoomState=model.rooms[1]
 var original_hp: float=closed_door.door_hp
 var alternate_hp: float=open_target.door_hp
 closed_door.door_hp=closed_door.max_hp()*4.0
 open_target.door_hp=1.0
 hunter.damage=5.0
 hunter.speed=90.0
 hunter.siege_start_hp=closed_door.door_hp
 hunter.siege_landed_damage=0.0
 hunter.reassess_seconds=24.0
 hunter._reassess_tactical_siege(closed_door,model)
 check(hunter.target!=0 and hunter.state==HunterState.State.MOVE,"a stalled siege chooses a meaningfully cheaper reachable alternative")
 check(model.presentation_events.any(func(event):return event.type=="hunter_target_choice" and event.get("reason")=="stalled"),"stalled siege samples and records its decision")
 closed_door.door_hp=original_hp
 open_target.door_hp=alternate_hp
 hunter.target=0
 hunter.state=HunterState.State.ATTACK
 hunter.position=closed_door.door_approach()
 model.time=model.preparation+58.5
 model._tick_mini_hunters(.05)
 check(model.mini_hunter_telegraph and model.mini_hunters.is_empty(),"telegraph precedes spawn")
 model.time=model.preparation+60.0
 model._tick_mini_hunters(.05)
 check(model.mini_hunters.size()==1,"first Shadowling spawns")
 check(model.presentation_events.any(func(event):return event.type=="mini_hunter_warning"),"world telegraph emitted without a room")
 check(model.presentation_events.any(func(event):return event.type=="mini_hunter_spawn"),"physical spawn event registered")
 if not model.mini_hunters.is_empty():
  var mini:=model.mini_hunters[0]
  check(mini.position==model.map_data.hunter_spawn and model.navigation_walkable(mini.position),"physical exterior spawn")
  var occupied: bool=model.rooms.any(func(room):return NightmareMap.contains_point(room.layout,mini.position))
  check(not occupied,"spawn is outside every room")
  var reached:=false
  var travelled:=0.0
  for step in range(1200):
   var old:=Vector2(mini.position)
   mini.tick(.05,model)
   var distance: float=old.distance_to(mini.position)
   travelled+=distance
   if distance>mini.speed*.05+.01:
    check(false,"shadowling used an invalid movement step")
    break
   if mini.attack_flash>0.0:
    reached=true
    break
  check(reached and travelled>20.0 and mini.target!=0,"walks to and threatens a different room")
  if reached:
   check(model.rooms[mini.target].door_hp<model.rooms[mini.target].max_hp(),"actual NPC door lost HP")
   hunter.target=mini.target
   check(model.apply_room_damage(mini.target,100.0,"shadowling strike",mini.id)==0.0,"main Hunter exclusion enforced at damage boundary")
   mini.tick(.05,model)
   check(mini.target!=hunter.target,"invasion reroutes")
  mini.age=300.0
  mini.tick(.05,model)
  check(model.target_by_id(mini.id)==mini,"no timer despawn")
  check(model.attackable_targets().any(func(entry):return entry.id==mini.id),"normal weapons can acquire the Shadowling")
  var hp:=float(mini.hp)
  check(is_equal_approx(model.apply_target_damage(mini.id,hp,0),hp),"actual combat applies lethal HP damage")
  check(model.target_by_id(mini.id)==null,"dead Shadowling can no longer be targeted")
  model._tick_mini_hunters(.05)
  check(model.mini_hunters.is_empty(),"only killed pilot actor was removed")
 var player:=model.player()
 player.gold=1000.0
 var needle_placed:=false
 var grid:=player.spatial.grid_bounds()
 for y in range(0,int(grid.size.y),16):
  for x in range(0,int(grid.size.x),16):
   var point:=player.spatial.aligned(grid.position+Vector2(x,y),"turret")
   if point.distance_to(player.door_approach())>Catalog.BUILDINGS.turret.range:continue
   if model.place_building("turret",point):
    needle_placed=true
    break
  if needle_placed:break
 check(needle_placed,"ordinary paid Needle can cover this doorway")
 var shot_target:=MiniHunter.new()
 shot_target.configure(model,model.next_entity_id,0,false)
 model.next_entity_id+=1
 shot_target.hp=1.0
 shot_target.target=0
 shot_target.position=player.door_approach()
 model.mini_hunters.append(shot_target)
 hunter.target=1
 hunter.position=model.rooms[1].door_approach()
 model.weapon_feedback.enabled=true
 model._turrets(.05)
 for step in range(50):model._advance_projectiles(.05)
 check(shot_target.hp==0.0 and model.combat_events.any(func(event):return event.type=="impact" and event.target_id==shot_target.id and is_equal_approx(event.damage,1.0)),"real Needle projectile kills and records exact effective damage")
 model._tick_mini_hunters(.05)
 for index in range(MatchModel.MINI_HUNTER_CAP):
  var extra:=MiniHunter.new()
  extra.configure(model,model.next_entity_id,index,false)
  model.next_entity_id+=1
  model.mini_hunters.append(extra)
 model.mini_hunter_ready=0.0
 model._tick_mini_hunters(.05)
 check(model.mini_hunters.size()==MatchModel.MINI_HUNTER_CAP and not model.mini_hunter_telegraph,"cap blocks more calls without removing living minis")
 var original:=NightmareMap.pack(model.map_data)
 var restored:=MatchModel.new()
 restored.reset(model.map_seed)
 restored.living_dorm_requested=false
 check(restored.configure_map(model.map_id,original) and NightmareMap.pack(restored.map_data)==original,"persisted new furniture round trips without opt-in")
 print("LIVING_DORM_CHECKS=",checks," FAILURES=",failures," seeded_choices=",timeline)
 quit(int(failures>0))
