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
 # One paid tier adds capacity once. The same landed strikes still made
 # progress against the larger door, with no evidence of recurring healing.
 h.siege_start_hp=r.max_hp()-50
 r.door_hp=h.siege_start_hp
 h.siege_start_capacity=r.max_hp()
 r.gold=200
 expect(r.upgrade_door(),"fixture buys an ordinary door tier")
 r.door_hp-=40
 h.siege_landed_damage=40
 h.reassess_seconds=17
 h._reassess_tactical_siege(r,m)
 expect(h.target==0 and h.state==HunterState.State.ATTACK,"one-off capacity is not sustained repair")
 h.siege_landed_damage=0
 var previous:float=r.door_hp
 m.difficulty="hell"
 h._damage_door(r,m,10)
 expect(is_equal_approx(h.siege_landed_damage,previous-r.door_hp),"overlapping Hell and Story gates count overkill-limited damage once")
 # Start a legitimate Hall visit in transit. Complete the existing channel
 # and verify that the interrupted room can compete in the next assessment.
 h.target=nearby
 h.state=HunterState.State.MOVE
 m.time=m.preparation+70
 h.hp=h.max_hp*.3
 h.boss_policy.enabled=false
 h.position=m.map_data.halls.west.entrance
 m.haunt_recovery.available_at=0
 expect(m.haunt_recovery.try_retreat(h,m),"a wounded ordinary Hunter takes a reachable Hall")
 for step in range(260):
  if not m.haunt_recovery.is_active():break
  m.haunt_recovery.tick(.1,h,m)
 expect(m.haunt_recovery.visits==1 and h.state==HunterState.State.SEEK and h.avoid_target==-1,"return from actual recovery keeps the interrupted approach eligible")
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
 compare_archetypes()
 print("STORY_HUNTER_DECISIONS=",checks," FAILURES=",failures)
 quit(int(failures>0))

func compare_archetypes() -> void:
 var unique_costs:={}
 for archetype: String in StrategyCatalog.ARCHETYPE_IDS:
  var m:=MatchModel.new()
  m.hunter_intelligence_requested=true
  m.living_dorm_requested=true
  m.player_first_requested=true
  m.procedural_v2_requested=true
  m.close_quarters_requested=true
  m.reset(452733)
  m.configure_match("hard")
  m.configure_stage("stage_1")
  m.configure_balance()
  m.story_level=1
  m.configure_strategy(m.map_seed,archetype)
  # Same geometry, wallets and gear in every controlled comparison.
  # Owner swap below uses equal door tiers and an inactive inventory.
  for r: RoomState in m.rooms:
   r.owner=r.index
   r.sleeping=true
   r.closed=true
   r.gold=200
  m.player_room=0
  m.time=m.preparation+1
  var h:=m.hunter
  h._model_ref=weakref(m)
  var with_paths:={}
  m.hunter_route_costs(h.position,with_paths)
  var before:=HunterSiegeStrategy.assess(m,h)
  var crossed:=-1
  var supplier:=-1
  var reached:=-1
  var radius:float=Catalog.BUILDINGS.turret.range
  for destination: int in with_paths:
   for room: RoomState in m.rooms:
    for tile in range(room.tile_count()):
     var at:=room.tile_position(tile)
     if at.distance_to(m.rooms[destination].door_approach())>radius and HunterSiegeStrategy.covered_distance(with_paths[destination],at,radius*radius)>50:
      if room.build("turret",tile):
       crossed=destination
       supplier=room.index
       reached=tile
       break
    if crossed>=0:break
   if crossed>=0:break
  expect(crossed>=0,"paid Needle covers an actual route outside the destination door range")
  if crossed<0:continue
  var after:=HunterSiegeStrategy.assess(m,h)
  expect(after[crossed]>before[crossed],"transit-only crossfire increases forecast for "+archetype)
  var first_choice:=h.choose_target(m.rooms)
  m.player_room=1
  m.rooms[0].owner=1
  m.rooms[1].owner=0
  expect(after==HunterSiegeStrategy.assess(m,h) and h.choose_target(m.rooms)==first_choice,"swapping human/NPC identity preserves identical risks and seeded choice")
  var comparable:={0:25.0,1:25.0}
  var neutral_visits:=0
  var repeat_visits:=0
  var initial_rng: int=m.random.state
  for sequence in range(96):
   h.living_choices=sequence
   h.recent_living_rooms.clear()
   neutral_visits+=int(h._living_choice(m,comparable)==0)
   h.recent_living_rooms.assign([0,0,0])
   repeat_visits+=int(h._living_choice(m,comparable)==0)
  expect(repeat_visits<neutral_visits and neutral_visits>0,"recent history discourages repeating a comparable door")
  expect(h._living_choice(m,{0:2.0,1:50.0})==0,"obvious weak door stays eligible despite three recent selections")
  expect(m.random.state==initial_rng,"seeded memory comparison never advances the shared RNG")
  var profile:=Array(after.values())
  unique_costs[str(profile)]=true
  print("MATCHED_ARCHETYPE ",JSON.stringify({"archetype":archetype,"map_seed":m.map_seed,"first_choice":first_choice+1,"compared_room":crossed+1,"gun_room":supplier+1,"tile":reached,"recent_visits_same_cost":repeat_visits,"neutral_visits_same_cost":neutral_visits,"before_cost":before[crossed],"covered_cost":after[crossed],"commit_seconds":RankCatalog.pressure("hard").commit*StrategyCatalog.ARCHETYPES[archetype].commit,"affinity":DamageRules.affinity(archetype)}))
 expect(unique_costs.size()==6,"six different tactical cost profiles on identical terrain")
