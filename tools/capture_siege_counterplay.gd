extends "res://tools/capture_hell_tactics.gd"
## Matched prepared siege fixtures. Both run the real strikes and decision code.
const MAX_WARMUP_TICKS := 145
const HITS := 6
var probe_mode := false

func run():
 var args:=OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 directory=args[0]
 probe_mode="--probe" in args
 DirAccess.make_dir_recursive_absolute(directory)
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://counterplay-capture-only.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 if is_instance_valid(game.onboarding):
  preload("res://tests/onboarding_test_support.gd").skip(game)
  game.onboarding.set_process(false)
 game.profile.settings.graphics_quality="medium"
 var opening: Array=[]
 for difficulty: String in ["hard","hell"]:
  opening.append(await capture_opening(difficulty))
 receipt.opening=opening
 var ordinary:=await capture_counter(false)
 var defending:=await capture_counter(true)
 receipt.ordinary=ordinary
 receipt.defending=defending
 if not ordinary.is_empty() and not defending.is_empty():
  verify(is_equal_approx(ordinary.gross_strike_hp,defending.gross_strike_hp) and is_equal_approx(ordinary.starting_door_hp,defending.starting_door_hp),"the two siege windows began at matching HP and took matching real damage")
 receipt.errors=errors
 var file:=FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(receipt,"  ")+"\n")
 file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("SIEGE_COUNTERPLAY_CAPTURE_FAILURES=",errors.size())
 quit(1 if not errors.is_empty() else 0)

func capture_opening(difficulty: String) -> Dictionary:
 var model:=MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(MATCH_SEED)
 verify(model.configure_match(difficulty) and model.configure_stage(STAGE) and model.configure_strategy(MATCH_SEED,"stalker") and model.configure_balance(),"opening encounter configured in "+difficulty)
 game._adopt_session(model)
 game.set_process(false)
 if probe_mode:
  game.toggle_map()
 else:
  await key_event(KEY_M)
 game.focus_camera(true)
 verify(game.full_map and model.player_room<0,"opening map is visible before any room selection")
 var inspected: int=-1
 var quote: Dictionary={}
 for room: RoomState in model.rooms:
  quote=model.opening_room_forecast(room.index)
  if not quote.is_empty():
   inspected=room.index
   break
 verify(inspected>=0 and not quote.is_empty(),"selected vacant room has both path estimates")
 if inspected<0:return {}
 var point: Vector2=game.world_to_screen(model.rooms[inspected].bed_position())
 if probe_mode:
  game._select_overview_room(point)
 else:
  await mouse_event(MOUSE_BUTTON_LEFT,point)
 verify(game.overview_room==inspected and game.overview_opening==quote,"overview selection receives the actual path estimates")
 verify(model.player_room<0 and model.time==0.0,"inspecting a room preserves unclaimed opening state")
 if not probe_mode:
  await image("vacant-room-opening-"+difficulty)
 return {"difficulty":difficulty,"room":inspected+1,"seed":MATCH_SEED,"forecast":quote}

func capture_counter(paid: bool) -> Dictionary:
 var model:=siege_fixture(true)
 var room:=model.player()
 var hunter:=model.hunter
 var chapter: String="paid-defense" if paid else "ordinary-siege"
 # Both arms use the same opening room, weapons, target and start clock.
 # Remove the fixture's automatic repair via the ordinary sell transaction.
 for key in room.buildings.keys():
  if room.buildings[key].kind=="repair":
   verify(model.sell_building(key),"same repair station removed in both arms")
 var alternate: RoomState
 for candidate: RoomState in model.rooms:
  if candidate.owner>0:
   alternate=candidate
   break
 if alternate==null:return {}
 alternate.door_hp=30.0
 hunter.siege_seconds=0.0
 hunter.reassess_seconds=0.0
 hunter.target_time=0.0
 hunter.siege_start_hp=room.door_hp
 hunter.siege_landed_damage=0.0
 hunter.cooldown=.15
 var start_hp: float=room.door_hp
 var frames:=0
 for tick in range(MAX_WARMUP_TICKS):
  game._process(STEP)
  if not probe_mode and hunter.attacks>=HITS-1:
   await record_frame(chapter,frames)
   frames+=1
  if hunter.attacks>=HITS:
   break
 verify(hunter.attacks==HITS,"six real strikes landed before the scripted reassessment time")
 verify(get_event(model,"hunter_commit",room.index).is_empty() and get_event(model,"hunter_reassess",room.index).is_empty(),"the normal siege has not yet been reassessed")
 var landed: float=hunter.siege_landed_damage
 var strike: float=hunter.damage
 var damage_hp: float=room.door_hp
 var initial_net: float=start_hp-damage_hp
 var gold_spent:=0.0
 var hp_added:=0.0
 var action_count:=0
 if paid:
  for _i in range(3):
   if landed-(start_hp-room.door_hp)>=maxf(strike,landed*.5):
    break
   var before_gold: float=room.gold
   var before_hp: float=room.door_hp
   if probe_mode:
    verify(model.repair_door(),"probe made a regular paid repair")
   else:
    await key_event(KEY_R)
   gold_spent+=before_gold-room.gold
   hp_added+=room.door_hp-before_hp
   action_count+=1
  verify(gold_spent>0.0 and hp_added>0.0,"the defender paid actual gold for door healing")
  if not probe_mode:
   await image("paid-repair")
 for sample in range(10):
  if not probe_mode:
   await record_frame(chapter,frames)
   frames+=1
 var loss: float=start_hp-room.door_hp
 var projected: float=HunterSiegeStrategy.defended_breach_estimate(room.door_hp,loss,landed,strike,20.0)
 print("COUNTERPLAY_STAGED paid=",paid," strikes=",hunter.attacks," landed=",landed," initial_net=",initial_net," net=",loss," regular_strike=",strike," added=",hp_added," projected=",projected)
 verify(HunterSiegeStrategy.productive_progress(start_hp,room.door_hp,strike),"net loss still counts as productive")
 verify((projected>0.0)==paid,"only the paid repair crosses the sustained-defense threshold")
 # Set the elapsed window boundary. Normal Hunter ticks make the decision.
 hunter.reassess_seconds=20.0
 var choice: Dictionary={}
 var warning:=""
 var event_name: String="hunter_reassess" if paid else "hunter_commit"
 var expected_reason: String="defense_delays_breach" if paid else "breach_progress"
 var expected_warning: String="DEFENSE HELD" if paid else "HUNTER COMMITS"
 for tick in range(21):
  game._process(STEP)
  if choice.is_empty():
   choice=get_event(model,event_name,room.index)
  if warning.is_empty() and not choice.is_empty() and expected_warning in warning_visible():
   warning=warning_visible()
   if not probe_mode:
    await image("paid-defense-reroute-tell" if paid else "ordinary-siege-commit-tell")
  if not probe_mode:
   await record_frame(chapter,frames)
   frames+=1
 verify(choice.get("reason","")==expected_reason and not warning.is_empty(),"production decision and visible cue: "+expected_reason)
 var result:={"event":choice,"warning":warning,"starting_door_hp":start_hp,"gross_strike_hp":landed,
  "net_loss_before_repair":initial_net,"net_loss_after_repair":loss,"manual_repair_hp":hp_added,
  "manual_repair_gold":gold_spent,"manual_repair_count":action_count,"actual_predecision_strikes":HITS,"frames":frames}
 if paid and not choice.is_empty():
  verify(int(choice.get("next_room",-1))==alternate.index,"paid defense switches to the fixture's alternative room")
  result.route=await capture_counter_route(model,room.door_approach(),alternate.door_approach())
 return result

func capture_counter_route(model: MatchModel, start: Vector2, finish: Vector2) -> Dictionary:
 if probe_mode:
  game.toggle_map()
 else:
  await key_event(KEY_M)
 game.focus_camera(true)
 var trail:=Line2D.new()
 trail.default_color=Color("E7C886")
 trail.width=2.4/game.camera.zoom.x
 trail.antialiased=true
 trail.z_index=3
 game.add_child(trail)
 # Only live positions after opening the map are plotted.
 var samples: Array=[]
 var distance:=0.0
 var frames:=0
 var target_index: int=model.hunter.target
 trail.add_point(model.hunter.position+game.MAP_OFFSET)
 for f in range(ceili(float(MAX_APPROACH_TICKS)/5.0)):
  for _step in range(5):
   var previous: Vector2=model.hunter.position
   game._process(STEP)
   var at: Vector2=model.hunter.position
   var traveled:=at.distance_to(previous)
   verify(model.navigation_walkable(at) and traveled<=model.hunter.speed*STEP+.03,"actual reroute uses legal movement and pace")
   if traveled>.01:
    samples.append(arr(at))
    distance+=traveled
    trail.add_point(at+game.MAP_OFFSET)
   if at.distance_to(finish)<3:
    break
  if not probe_mode:
   await record_frame("reroute",frames)
   frames+=1
  if model.hunter.position.distance_to(finish)<3:
   break
 verify(model.hunter.position.distance_to(finish)<3 and model.hunter.target==target_index and model.hunter.state==HunterState.State.ATTACK,"Hunter physically reaches the alternate door and starts attacking it")
 if not probe_mode:
  await image("alternate-door-arrival")
 trail.queue_free()
 await process_frame
 return {"origin_door":arr(start),"target_door":arr(finish),"points_from_map_open":samples,
  "units_traveled_from_map_open":distance,"target_room":target_index+1,"arrival_state":model.hunter.state,"frames":frames}
