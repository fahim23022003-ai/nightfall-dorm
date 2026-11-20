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
 check(model.claim_room(0),"claim real room")
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
