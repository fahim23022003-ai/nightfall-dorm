extends "res://tools/capture_hell_tactics.gd"
## Exact Hell Labyrinth opening with a walked approach and earned fortification.

const SEED := 10358
const PLAYER_ROOM := 1
const CAMPAIGN_STAGE := "stage_2"
const MATCH_STEP := .15
const POLL_TICKS := 6
const EARLY_EVENTS := ["bed_upgrade","door_upgrade","build","building_upgrade","repair","emergency_ward","encounter","door_damage","hunter_commit","hunter_reassess"]
var probe_mode := false
var outcome_only := false
var newest_event := 0
var early_events: Array = []
var points_by_kind: Dictionary = {}
var approach_samples: Array[Vector2] = []
var walked: Array = []

func run():
 var args := OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 directory = args[0]
 outcome_only = "--outcome-only" in args
 probe_mode = "--probe" in args or outcome_only
 DirAccess.make_dir_recursive_absolute(directory)
 root.size = Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://fair-start-capture-only.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 if is_instance_valid(game.onboarding):
  preload("res://tests/onboarding_test_support.gd").skip(game)
  game.onboarding.set_process(false)
 game.profile.settings.graphics_quality="medium"
 var model := MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(SEED)
 verify(model.configure_match("hell") and model.configure_stage(CAMPAIGN_STAGE) and model.configure_strategy(SEED) and model.configure_balance(),"configured Hell Stage 2 with real contemporary rules")
 verify(model.map_data.get("family","")=="labyrinth","fixture is the seeded Labyrinth layout")
 game._adopt_session(model)
 game.set_process(false)
 await capture_opening_map(model)
 var room: RoomState=model.rooms[PLAYER_ROOM]
 var target: Vector2=room.door_position()-room.door_normal()*35.0
 walked.append(arr(model.player_position))
 var walk_frames:=await walk_path(model,model.player_navigation_path(model.player_position,target),0)
 verify(room.floor_has_point(model.player_position),"walked through the real doorway into Room 02")
 await interact(model)
 verify(model.player_room==PLAYER_ROOM and model.player().owner==0,"claimed the chosen room after walking")
 var entry_time: float=model.time
 var path:=model.player_navigation_path(model.player_position,room.bed_position()+room.door_normal()*42.0)
 verify(not path.is_empty(),"found a legal approach within sleep distance of the bed")
 walk_frames=await walk_path(model,path,walk_frames)
 var at_before_sleep: Vector2=model.player_position
 verify(at_before_sleep.distance_to(room.bed_position())<=60.0 and model.can_walk(at_before_sleep),"stood within production sleep range")
 await interact(model)
 verify(room.sleeping and room.closed,"normal sleep closes the real door")
 verify(is_equal_approx(room.gold,BalanceRules.START_GOLD) and room.electricity==0.0,"ordinary opening wallet before purchases")
 if not probe_mode:
  await image("normal-bed-entry")
 receipt.walk={"positions":walked,"claimed_at":entry_time,"slept_at":model.time,"start_gold":room.gold,"start_power":room.electricity,"frames":walk_frames}
 if room.sleeping:
  await capture_battle(model)

 receipt.seed=SEED
 receipt.room=PLAYER_ROOM+1
 receipt.difficulty=model.difficulty
 receipt.stage=CAMPAIGN_STAGE
 receipt.family=model.map_data.get("family","")
 receipt.early_events=early_events
 receipt.errors=errors
 var file:=FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(receipt,"  ")+"\n")
 file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("FAIR_START_CAPTURE_FAILURES=",errors.size())
 quit(1 if not errors.is_empty() else 0)

func capture_opening_map(model: MatchModel):
 if probe_mode:
  game.toggle_map()
 else:
  await key_event(KEY_M)
 game.focus_camera(true)
 var selected: RoomState=model.rooms[PLAYER_ROOM]
 var quote:=model.opening_room_forecast(PLAYER_ROOM)
 var point: Vector2=game.world_to_screen(selected.bed_position())
 if probe_mode:
  game._select_overview_room(point)
 else:
  await mouse_event(MOUSE_BUTTON_LEFT,point)
 verify(model.player_room<0 and selected.owner<0 and game.overview_room==PLAYER_ROOM,"native Room 02 selection remains unclaimed")
 verify(not quote.is_empty() and game.overview_opening==quote,"scout displays quote from actual movement routes")
 verify(quote.get("early_siege_risk",false),"Room 02 carries the fast-approach warning")
 receipt.scout=quote
 if not probe_mode:
  await image("labyrinth-room-02-opening-forecast")
 if probe_mode:
  game.toggle_map()
 else:
  await key_event(KEY_M)
 game.focus_camera(true)

func interact(model: MatchModel):
 if probe_mode:
  model.interact()
 else:
  await key_event(KEY_E)

func walk_path(model: MatchModel, path: Array, first_frame: int) -> int:
 var frames:=first_frame
 for point: Vector2 in path:
  for _tick in range(420):
   var before: Vector2=model.player_position
   var direction: Vector2=(point-before)/(180.0*MATCH_STEP)
   if before.distance_to(point)<=1.0:
    break
   model.move_player(direction,MATCH_STEP)
   var at: Vector2=model.player_position
   verify(model.can_walk(at) and before.distance_to(at)<=180.0*MATCH_STEP+.03,"survivor walks at normal legal speed")
   if at.distance_squared_to(before)<.00001:
    verify(false,"survivor path stalled")
    break
   walked.append(arr(at))
   model.tick(MATCH_STEP)
   if not probe_mode:
    draw_action_state(model)
    await record_frame("entry",frames)
    frames+=1
  verify(model.player_position.distance_to(point)<=1.0,"route waypoint reached without a teleport")
 return frames

func draw_action_state(model: MatchModel):
 game.focus_camera(false,MATCH_STEP)
 game.ui.update_match()
 game.horror.update(MATCH_STEP,model)
 game.presentation.update(MATCH_STEP,model)

func capture_battle(model: MatchModel):
 var room:=model.player()
 var frames:=0
 var ticks:=0
 var first_strike:=-1.0
 var took_early_setup:=false
 var took_bed_three:=false
 var repair_shown:=false
 var captured_close_call:=false
 var latest_bed: int=room.bed_level
 var latest_door: int=room.door_level
 var latest_buildings: int=room.buildings.size()
 var gold_origin: float=room.gold
 var checks:=0
 while model.result.is_empty() and model.time<900.0:
  if ticks%POLL_TICKS==0:
   fortify(model)
  model.tick(MATCH_STEP)
  if not probe_mode and not captured_close_call:
   draw_action_state(model)
  ticks+=1
  if model.time<90.0:
   for event: Dictionary in model.presentation_events:
    if event.id<=newest_event:
     continue
    newest_event=event.id
    if event.room!=PLAYER_ROOM or event.type not in EARLY_EVENTS:
     continue
    var snapshot:=event.duplicate(true)
    snapshot.gold_after_tick=room.gold
    snapshot.power_after_tick=room.electricity
    early_events.append(snapshot)
    if event.type=="door_damage" and first_strike<0.0:
     first_strike=event.time
     if not probe_mode:
      await image("first-live-door-strike")
    if event.type=="repair" and not repair_shown and first_strike>=0.0:
     repair_shown=true
     if not probe_mode:
      await image("first-earned-repair")
  if not took_bed_three and room.bed_level>=2:
   took_bed_three=true
   if not probe_mode:
    await image("earned-bed-three")
  if not took_early_setup and (room.bed_level!=latest_bed or room.door_level!=latest_door or room.buildings.size()!=latest_buildings):
   latest_bed=room.bed_level
   latest_door=room.door_level
   latest_buildings=room.buildings.size()
   if latest_bed>=2 and latest_door>=1 and latest_buildings>=1:
    took_early_setup=true
    if not probe_mode:
     await image("earned-bed-door-and-needle")
  var travel: Dictionary=room.ledger.totals
  var expected: float=gold_origin+travel.production_g+travel.other_g+travel.refund_g-travel.spent_g-travel.loss_g
  verify(absf(room.gold-expected)<=.011 and room.gold>=0.0 and room.electricity>=0.0,"paid strategy follows ordinary ledger")
  checks+=1
  if not probe_mode and not captured_close_call and (model.time>=43.0 or first_strike>=0.0):
   if first_strike<0.0 or model.time<=first_strike+4.3 or not repair_shown:
    await record_frame("combat",frames)
    frames+=1
   else:
    captured_close_call=true
    await image("fortified-door-first-combat")
 verify(first_strike>=0.0 and took_early_setup and took_bed_three and repair_shown,"Bed 3 was earned before early defense and paid repair")
 verify(model.result=="victory","the item-free walked opening survived the full simulated match")
 if not probe_mode or outcome_only:
  game.campaign_mode=true
  game._process(0.0)
  await create_timer(1.25).timeout
  await image("real-run-outcome")
 receipt.battle={"outcome":model.result,"sim_seconds":model.time,"first_player_strike":first_strike,"bed_level":room.bed_level+1,
  "door_level":room.door_level+1,"paid_buildings":room.buildings.size(),"repair_actions":room.repair_actions,"total_door_damage":room.door_damage_taken,
  "item_uses":model.items.inventory_uses.size() if "inventory_uses" in model.items else 0,"frames":frames,"ledger_checks":checks}
 print("FAIR_START outcome=",model.result," time=",model.time," first_strike=",first_strike)

func fortify(model: MatchModel):
 var room:=model.player()
 var hunter:=model.hunter
 var target: bool=hunter.target==room.index
 var defense_live: bool=target and hunter.state==HunterState.State.ATTACK
 var missing: float=room.max_hp()-room.door_hp
 if defense_live and missing>=Catalog.REPAIR_HEAL*room.repair_factor*.90 and model.repair_door():return
 if room.bed_level<1:
  model.upgrade_bed()
  return
 if room.bed_level<2:
  model.upgrade_bed()
  return
 if room.door_level<1:
  model.upgrade_door()
  return
 if ids(room,"turret").is_empty() and buy_at(model,"turret",true):return
 if room.door_level<2 and model.upgrade_door():return
 if ids(room,"generator").is_empty() and buy_at(model,"generator"):return
 if defense_live and hunter.cooldown<=1.4 and room.door_hp<room.max_hp()*.85 and model.route_defense_power():return
 if ids(room,"frost").is_empty() and buy_at(model,"frost"):return
 if ids(room,"repair").is_empty() and buy_at(model,"repair"):return
 if ids(room,"turret").size()<3 and buy_at(model,"turret",true):return
 var danger: bool=target and hunter.position.distance_to(room.door_approach())<150.0
 if danger:
  if room.door_level<2 and room.door_hp<room.max_hp()*.84 and model.upgrade_door():return
  if room.door_hp<room.max_hp()*.58 and model.repair_door():return
  if defense_live and hunter.cooldown<1.4 and room.door_hp<room.max_hp()*.82 and model.route_defense_power():return
 if ids(room,"turret").size()<2 and buy_at(model,"turret"):return
 if ids(room,"turret").size()<3 and buy_at(model,"turret"):return
 if upgrade_kind(model,"turret",3):return
 if ids(room,"heavy").is_empty() and buy_at(model,"heavy"):return
 if room.bed_level<3 and model.upgrade_bed():return
 if room.door_level<3 and model.upgrade_door():return
 if upgrade_kind(model,"heavy",4):return
 upgrade_kind(model,"turret",4)

func ids(room: RoomState, kind: String) -> Array:
 return room.buildings.keys().filter(func(key):return room.buildings[key].kind==kind)

func upgrade_kind(model: MatchModel, kind: String, cap: int) -> bool:
 for id in ids(model.player(),kind):
  if model.player().buildings[id].level<cap:
   return model.upgrade_building(id)
 return false

func buy_at(model: MatchModel, kind: String, prefer_coverage:=false) -> bool:
 var room:=model.player()
 var price: Vector2=room.quote_build(kind)
 if room.gold+.00001<price.x or room.electricity+.00001<price.y:
  return false
 var door:=room.door_approach()
 if not points_by_kind.has(kind):
  var bounds:=room.bounds().grow(-8)
  var unique: Dictionary={}
  var positions: Array[Vector2]=[]
  for y in range(floori(bounds.position.y),ceili(bounds.end.y),16):
   for x in range(floori(bounds.position.x),ceili(bounds.end.x),16):
    var point:=room.spatial.aligned(Vector2(x,y),kind,0)
    if point.is_finite() and not unique.has(point):
     unique[point]=true
     positions.append(point)
  positions.sort_custom(func(a: Vector2,b: Vector2):return a.distance_squared_to(door)<b.distance_squared_to(door))
  if kind not in ["turret","heavy","flame","frost","shock"]:
   positions.reverse()
  points_by_kind[kind]=positions
 if prefer_coverage and approach_samples.is_empty():
  var previous: Vector2=model.map_data.hunter_spawn
  for next: Vector2 in model.navigation_path(previous,door):
   var steps:=maxi(1,ceili(previous.distance_to(next)/24.0))
   for step in range(steps+1):
    var point:=previous.lerp(next,float(step)/steps)
    if point.distance_to(door)<640.0:approach_samples.append(point)
   previous=next
 var best:=Vector2.INF
 var coverage:=-1
 for point: Vector2 in points_by_kind[kind]:
  if room.spatial.purchase_reason(kind,point,0)!="":
   continue
  if not prefer_coverage:return model.place_building(kind,point,0)
  var count:=0
  var sight: float=Catalog.BUILDINGS.turret.range
  for sample in approach_samples:
   count+=int(point.distance_squared_to(sample)<=sight*sight)
  if count>coverage:
   coverage=count
   best=point
 return best.is_finite() and model.place_building(kind,best,0)
