extends SceneTree
## Scoped V2 encounter decisions with fixed maps, owned rooms and real path costs.
var failures := 0
var checks := 0

func _initialize():
 call_deferred("run")

func check(condition: bool, label: String):
 checks+=1
 if not condition:
  failures+=1
  push_error(label)

func run():
 var model:=MatchModel.new()
 model.procedural_v2_requested=true
 check(model.configure_match("hell") and model.configure_stage("stage_2"),"configure V2 Hell")
 check(model.configure_strategy(54) and model.configure_balance(),"configure normal match rules")
 var forecast:=model.opening_room_forecast(0)
 check(forecast.get("hunter_seconds",0)>0 and forecast.get("entry_seconds",0)>0,"unclaimed Hard/Hell room shows legal opening estimates")
 var short_start:=MatchModel.new()
 short_start.procedural_v2_requested=true
 short_start.reset(10358)
 short_start.configure_match("hell")
 short_start.configure_stage("stage_2")
 short_start.configure_strategy(10358)
 short_start.configure_balance()
 var short_forecast:=short_start.opening_room_forecast(1)
 check(short_forecast.get("early_siege_risk",false),"Labyrinth Room 2 warns before claim")
 short_start.starting_room_review_enabled=false
 check(not short_start.opening_room_forecast(1).has("early_siege_risk"),"comparison retains V2.2 travel estimates")
 model.difficulty="standard"
 check(model.opening_room_forecast(0).is_empty(),"Standard presentation remains identical")
 model.difficulty="hell"
 check(model.claim_room(0),"claim real room")
 check(model.opening_room_forecast(0).is_empty(),"scouting estimate applies before claiming")
 var room: RoomState=model.player()
 model.player_position=room.bed_position()
 check(model.sleep_player(),"lock owned door")
 var other: RoomState=model.rooms[1]
 other.owner=1
 other.sleeping=true
 other.closed=true
 model.time=model.preparation+60.0
 var hunter:=model.hunter
 check(model.uses_tactical_sieges(),"V2 Hell Campaign uses the candidate")
 model.hard_tactics_enabled=false
 check(not model.uses_tactical_sieges(),"reproducible prior decision mode")
 model.hard_tactics_enabled=true
 for pair in [["standard","campaign",false],["hard","endless",false],["hard","campaign",true]]:
  model.difficulty=pair[0]
  model.run_kind=pair[1]
  check(model.uses_tactical_sieges()==pair[2],"scope "+str(pair))
 model.difficulty="hell"
 hunter.transformed=true
 check(not model.uses_tactical_sieges(),"Reaper uses existing rules")
 hunter.transformed=false
 hunter.position=room.door_approach()
 hunter.target=room.index
 hunter.state=HunterState.State.ATTACK
 hunter.damage=20.0
 hunter.interval=1.0
 hunter.speed=100.0
 hunter.siege_start_hp=room.door_hp
 room.door_hp-=25.0
 hunter._reassess_tactical_siege(room,model)
 check(hunter.target==room.index and hunter.state==HunterState.State.ATTACK,"productive siege stays on its door")
 check(model.presentation_events.back().type=="hunter_commit","productive decision emits real warning event")
 var recorded: int=model.next_presentation_event_id
 room.door_hp-=25.0
 hunter._reassess_tactical_siege(room,model)
 check(model.next_presentation_event_id==recorded,"same encounter warning is not repeated")
 # A heavily repaired door holds the hunter. Leave it only for a materially
 # faster breach which the actual AStar graph says is attainable.
 room.door_hp=room.max_hp()
 other.door_hp=1.0
 hunter.siege_start_hp=room.door_hp
 hunter.damage=10.0
 hunter.speed=1000.0
 var choice:=HunterSiegeStrategy.assess(model,hunter)
 check(choice.has(room.index) and choice.has(other.index),"both real doors have finite costs")
 check(HunterSiegeStrategy.worth_switching(choice[room.index],choice[other.index]),"reachable weak door compensates travel cost")
 hunter._reassess_tactical_siege(room,model)
 check(hunter.target==other.index and hunter.state==HunterState.State.MOVE,"switch starts a normal approach toward exact scored door")
 check(model.presentation_events[-2].type=="hunter_reassess" or model.presentation_events[-3].type=="hunter_reassess","actual switch is recorded")
 check(room.repair_factor==1.0,"abandoned door exits siege repair pressure")
 check(not HunterSiegeStrategy.worth_switching(22.0,19.0),"small savings cannot cause churn")
 check(not HunterSiegeStrategy.worth_switching(60.0,49.0),"longer sieges require proportionate improvement")
 var before_coverage: float=HunterSiegeStrategy.assess(model,hunter)[room.index]
 room.gold=500.0
 var gun:=Vector2.INF
 var area: Rect2=room.spatial.grid_bounds()
 for x in range(int(area.position.x),int(area.end.x),16):
  for y in range(int(area.position.y),int(area.end.y),16):
   var at: Vector2=room.spatial.aligned(Vector2(x,y),"turret",0)
   if at.distance_to(room.door_approach())<180 and room.spatial.purchase_reason("turret",at,0)=="":
    gun=at
    break
  if gun.is_finite():break
 check(gun.is_finite() and model.place_building("turret",gun),"a legal paid machine covers the approach")
 check(HunterSiegeStrategy.assess(model,hunter)[room.index]>before_coverage,"the actual firing lane increases estimated exposure")
 hunter.target=room.index
 hunter.state=HunterState.State.ATTACK
 hunter.position=room.door_approach()
 hunter.damage=10.0
 hunter._damage_door(room,model,10.0)
 check(hunter.siege_landed_damage>0.0,"real landed strike contributes to reassessment window")
 hunter.siege_start_hp=room.door_hp+15.0
 hunter.siege_landed_damage=75.0
 hunter.reassess_seconds=12.0
 model.fair_siege_enabled=false
 hunter._reassess_tactical_siege(room,model)
 check(hunter.target==room.index,"prior productive behavior stays even through heavy mitigation")
 hunter.siege_start_hp=room.door_hp+15.0
 hunter.siege_landed_damage=75.0
 hunter.reassess_seconds=12.0
 model.fair_siege_enabled=true
 hunter._reassess_tactical_siege(room,model)
 check(hunter.target==other.index and hunter.siege_notice_defender==room.index,"measured repairs can earn visible relief when another route is worth it")
 check(hunter.last_defended_door==room.index and hunter.last_defended_breach==55.0,"real defense-aware departure records the observed breach estimate")
 hunter.position=other.door_approach()
 hunter.state=HunterState.State.ATTACK
 other.door_hp=125.0
 hunter.siege_start_hp=140.0
 hunter.siege_landed_damage=75.0
 hunter.reassess_seconds=12.0
 var ordinary_cost: float=HunterSiegeStrategy.assess(model,hunter)[room.index]
 var defended_cost: float=HunterSiegeStrategy.assess(model,hunter,room.index,hunter.last_defended_breach)[room.index]
 check(HunterSiegeStrategy.worth_switching(55.0,ordinary_cost) and defended_cost>55.0,"observed siege plus travel rejects the optimistic return")
 hunter._reassess_tactical_siege(other,model)
 check(hunter.target==other.index,"real next siege avoids immediate return to intact defense")
 room.door_hp=1.0
 hunter.siege_start_hp=140.0
 hunter.siege_landed_damage=75.0
 hunter.reassess_seconds=12.0
 hunter._reassess_tactical_siege(other,model)
 check(hunter.target==room.index,"materially weakened previous door is eligible again")
 check(HunterSiegeStrategy.defended_breach_estimate(100.0,18.0,30.0,10.0,12.0)==0.0,"small repairs cannot force new reassessment")
 check(HunterSiegeStrategy.defended_breach_estimate(100.0,18.0,45.0,10.0,12.0)==55.0,"observed delay remains bounded")
 var fixed:=MatchModel.new()
 fixed.procedural_v2_requested=false
 fixed.procedural_requested=false
 fixed.configure_match("hell")
 fixed.configure_stage("stage_2")
 check(not fixed.uses_tactical_sieges(),"fixed Hell stays on previous rules")
 var first:=MatchModel.new()
 first.procedural_v2_requested=false
 first.procedural_requested=true
 first.configure_match("hell")
 first.configure_stage("stage_2")
 check(not first.uses_tactical_sieges(),"V1 Hell stays on previous rules")
 print("TACTICAL_SIEGE_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
