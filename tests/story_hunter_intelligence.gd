extends SceneTree
## Controlled decisions on an actual Story map. Complete earned matches use phase23_campaign.gd.
var checks:=0
var failures:=0

func expect(ok:bool,message:String):
 checks+=1
 if not ok:
  failures+=1
  push_error(message)

func _initialize():
 var m:=MatchModel.new()
 m.hunter_intelligence_requested=true
 m.procedural_v2_requested=true
 m.close_quarters_requested=true
 m.living_dorm_requested=true
 m.player_first_requested=true
 m.reset(StoryProgress.seed_for(StoryProgress.fresh(48031),1))
 m.configure_match("standard")
 m.configure_stage("stage_1")
 m.configure_balance()
 m.story_level=1
 m.configure_strategy(m.map_seed,"crusher")
 StoryCatalog.apply_encounter(m)
 expect(m.uses_story_intelligence() and not m.uses_tactical_sieges(),"live Normal Living Dorm decision path")
 var h:=m.hunter
 var r: RoomState=m.rooms[0]
 var from_door:=m.hunter_route_costs(r.door_approach())
 var nearby:=HunterSiegeStrategy.best_room(from_door,r.index)
 var other: RoomState=m.rooms[nearby]
 for room: RoomState in [r,other]:
  room.owner=room.index
  room.sleeping=true
  room.closed=true
 m.player_room=r.index
 h.target=r.index
 h.position=r.door_approach()
 h.state=HunterState.State.ATTACK
 m.time=m.preparation+1.0
 var hp: float=r.door_hp
 h._damage_door(r,m,20.0)
 expect(h.siege_landed_damage>0 and is_equal_approx(h.siege_landed_damage,hp-r.door_hp),"Normal counts exactly the applied HP")
 var first: float=h.siege_landed_damage
 m.apply_room_damage(nearby,12.0,"curse",1,true)
 expect(h.siege_landed_damage==first,"secondary room damage cannot inflate the siege observation")
 var rng:int=m.random.state
 var paths:={}
 var distances:=m.hunter_route_costs(h.position,paths)
 expect(paths.size()==6 and paths[nearby] is PackedVector2Array and is_finite(distances[nearby]),"navigation supplies actual reachable graph paths in the existing query")
 var corners:=PackedVector2Array([Vector2.ZERO,Vector2(100,0),Vector2(100,100)])
 expect(is_equal_approx(HunterSiegeStrategy.covered_distance(corners,Vector2(50,0),100),20.0),"crossing a firing lane before a safe door counts actual intersecting distance")
 expect(is_zero_approx(HunterSiegeStrategy.covered_distance(corners,Vector2(50,50),100)),"a weapon across the corner contributes zero")
 var station={"kind":"repair","level":1,"specialization":""}
 r.buildings[0]=station
 r.electricity=100
 r.door_hp=r.max_hp()
 var funded: float=HunterSiegeStrategy.assess(m,h)[0]
 r.door_hp-=0.01
 expect(absf(HunterSiegeStrategy.assess(m,h)[0]-funded)<0.02,"first scratch does not suddenly activate funded repair in forecast")
 r.electricity=0
 expect(HunterSiegeStrategy.assess(m,h)[0]<funded,"unfunded station cannot earn deterrence")
 r.buildings.clear()
 r.door_hp=r.max_hp()
 h.siege_start_hp=r.door_hp
 h.siege_landed_damage=40
 h.reassess_seconds=16
 other.door_hp=4
 h._reassess_tactical_siege(r,m)
 expect(h.target==nearby and h.state==HunterState.State.MOVE and h.last_defended_door==0,"fully erased hits can earn a real switch to the attainable door")
 expect(m.presentation_events.any(func(e):return e.type=="hunter_reassess" and e.get("reason")=="defense_delays_breach" and e.room==0 and e.next_room==nearby),"decision trace explains the actual move")
 expect(m.random.state==rng,"Hunter decisions leave combat and settlement RNG untouched")
 h.target=0
 h.state=HunterState.State.ATTACK
 r.door_hp=7
 h.siege_start_hp=30
 h.siege_landed_damage=100
 h.reassess_seconds=16
 h._reassess_tactical_siege(r,m)
 expect(h.target==0 and h.state==HunterState.State.ATTACK,"finish near-breached door with positive progress")
 h.siege_landed_damage=0
 var previous:float=r.door_hp
 m.difficulty="hell"
 h._damage_door(r,m,10)
 expect(is_equal_approx(h.siege_landed_damage,previous-r.door_hp),"overlapping Hell and Story gates count overkill-limited damage once")
 other.sleeping=false
 expect(not HunterSiegeStrategy.assess(m,h).has(nearby),"awake or vacant room is not an eligible target")
 for mode:String in ["endless","campaign"]:
  m.run_kind=mode
  h.transformed=true
  expect(not m.uses_story_intelligence(),"transformed Reaper excluded")
  h.transformed=false
  expect(m.uses_story_intelligence()==(mode=="campaign"),"Endless stays on its checkpoint rules")
 m.tutorial_mode=true
 expect(not m.uses_story_intelligence(),"Practice preserves existing pacing")
 m.tutorial_mode=false
 m.hunter_intelligence_requested=false
 expect(not m.uses_story_intelligence(),"fallback launcher keeps its original decisions")
 print("STORY_HUNTER_DECISIONS=",checks," FAILURES=",failures)
 quit(int(failures>0))
