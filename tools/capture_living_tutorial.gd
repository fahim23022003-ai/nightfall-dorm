extends "res://tools/capture_onboarding.gd"
## Native Godot InputEvents and real purchases in an isolated profile. The
## movement helper follows game navigation, with no position or wallet edits.

const Guide = preload("res://scripts/living_tutorial.gd")
var practice
var completed_rooms: Dictionary={}
var lesson_trace: Array[Dictionary]=[]
var record_walkthrough := false

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()<1 or not args[0].is_absolute_path() or DisplayServer.get_name()=="headless":
  push_error("Pass an absolute output directory and use a graphical display")
  quit(2)
  return
 record_walkthrough="record" in args
 var replay_result: bool="replay" in args
 output=args[0].trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(output)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://living-tutorial-capture-"+str(Time.get_ticks_usec())+".json")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 game=load("res://scenes/main.tscn").instantiate()
 root.size=Vector2i(1280,720)
 root.add_child(game)
 await process_frame
 if record_walkthrough:
  DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
  await wait(1.8)
 await key(KEY_SPACE)
 await click(game.onboarding.welcome_close)
 await click(game.ui.menu_start)
 check(game.tutorial_active and game.model.tutorial_mode and game.onboarding.course!=null,"fresh Story opens isolated 19-step tutorial")
 if failures>0:
  await finish()
  return
 practice=game.onboarding.course
 var before: Dictionary=game.profile._reward_snapshot()
 var model: MatchModel=game.model
 var room: RoomState=model.rooms[0]
 await lesson(Guide.Lesson.OBJECTIVE,"01-objective")
 await click(practice.proceed)
 await lesson(Guide.Lesson.MOVE,"02-movement")
 await move_to(room.door_approach())
 await lesson(Guide.Lesson.SHARED_SPAWN,"03-shared-spawn")
 await click(practice.proceed)
 await lesson(Guide.Lesson.FIND_ROOM,"04-find-room")
 await move_to(room.door_position()-room.door_normal()*43.0)
 await lesson(Guide.Lesson.CLAIM_ROOM,"05-claim")
 await key(KEY_E)
 await lesson(Guide.Lesson.REACH_BED,"06-reach-bed")
 check(model.player()==room and room.owner==0 and room.spatial!=null and room.spatial.grid,"actual interaction claims room and opens training grid")
 if failures>0:
  await finish()
  return
 await move_to(room.bed_position()+room.door_normal()*50.0)
 await lesson(Guide.Lesson.SLEEP,"07-sleep")
 var income_before: float=room.income_total
 await key(KEY_E)
 await lesson(Guide.Lesson.OPEN_BUILD,"08-open-build")
 check(room.sleeping and room.income_total>income_before,"real sleep locks room and earns Gold")
 check(button_is_highlighted(game.ui.room_selected_summary),"Build cue encloses the actual clickable control")
 await click(game.ui.room_selected_summary)
 await lesson(Guide.Lesson.SELECT_NEEDLE,"09-select-needle")
 check(button_is_highlighted(game.ui.actions["build:turret"]),"Needle cue encloses the real catalogue card")
 await click(game.ui.actions["build:turret"])
 await motion_to_current_cell()
 await lesson(Guide.Lesson.PLACE_NEEDLE,"10-place-needle")
 var wallet: Vector2=Vector2(room.gold,room.electricity)
 await world_click(room.door_position()-room.door_normal()*17.0)
 check(room.buildings.is_empty() and room.electricity==wallet.y,"blocked doorway placement spends nothing")
 check(practice.stage==Guide.Lesson.PLACE_NEEDLE,"failed placement cannot advance the tutorial")
 await click_current_cell()
 await lesson(Guide.Lesson.CANCEL_PREVIEW,"11-explicit-cancel")
 var needle: int=practice.needle_id
 check(room.buildings.size()==1 and room.buildings.has(needle) and game.construction.kind=="turret","paid Needle exists and its current placement tool is still selected")
 check(button_is_highlighted(game.ui.grid_placement_cancel_button),"cancel highlight is the real grid control")
 var needle_before: Dictionary=room.buildings[needle].duplicate(true)
 if replay_result:
  var right:=InputEventMouseButton.new()
  right.button_index=MOUSE_BUTTON_RIGHT
  right.pressed=true
  Input.parse_input_event(right)
  await process_frame
  right.pressed=false
  Input.parse_input_event(right)
  await process_frame
  check(practice.stage==Guide.Lesson.CANCEL_PREVIEW and game.construction.kind=="turret","right-click cannot acknowledge explicit cancel")
  await key(KEY_B)
  await settled_drawer()
  check(practice.stage==Guide.Lesson.CANCEL_PREVIEW and button_is_highlighted(game.ui.actions["build:turret"]),"implicit placement clear stays on lesson and guides reselection")
  await click(game.ui.actions["build:turret"])
  await key(KEY_ESCAPE)
 else:
  await click(game.ui.grid_placement_cancel_button)
 await lesson(Guide.Lesson.REOPEN_BUILD,"12-reopen-build")
 check(room.buildings.size()==1 and room.buildings.has(needle) and room.buildings[needle].instance_id==needle_before.instance_id and room.buildings[needle].level==needle_before.level and room.buildings[needle].position==needle_before.position and not game.construction.active(),"explicit cancel clears only the placement tool")
 await key(KEY_B)
 await lesson(Guide.Lesson.SELECT_DYNAMO,"13-select-dynamo")
 check(button_is_highlighted(game.ui.actions["build:generator"]),"Dynamo cue encloses the real catalogue card")
 await click(game.ui.actions["build:generator"])
 await motion_to_current_cell()
 await lesson(Guide.Lesson.PLACE_DYNAMO,"14-place-dynamo")
 await click_current_cell()
 await lesson(Guide.Lesson.UPGRADE,"15-upgrade")
 var dynamo: int=practice.dynamo_id
 check(room.buildings.size()==2 and room.buildings.has(dynamo) and dynamo!=needle,"distinct Dynamo was purchased")
 await world_click(room.tile_position(needle))
 var charge_deadline:=Time.get_ticks_msec()+19000
 while game.ui.actions.upgrade.disabled and Time.get_ticks_msec()<charge_deadline:
  await process_frame
 await capture("15a-upgrade-action")
 check(button_is_highlighted(game.ui.actions.upgrade),"Upgrade cue encloses actual selected building action")
 check(game.ui.actions.sell.disabled,"practice prevents selling the two required machines")
 var old_level: int=room.buildings[needle].level
 await click(game.ui.actions.upgrade)
 await lesson(Guide.Lesson.REPAIR,"16-repair")
 check(room.buildings[needle].level==old_level+1,"actual Needle upgrade")
 check(practice.repair_damage>0 and room.door_hp<room.max_hp(),"repair fixture applied a real damage transaction")
 check(button_is_highlighted(game.ui.quick_repair),"Repair cue encloses actual repair button")
 var old_hp: float=room.door_hp
 var old_repairs: int=room.repair_actions
 await click(game.ui.quick_repair)
 await lesson(Guide.Lesson.CLOSE_PANEL,"17-close-panel")
 check(room.door_hp>old_hp and room.repair_actions==old_repairs+1,"successful repair restored actual door HP")
 check(button_is_highlighted(game.ui.build_cancel_button),"close cue encloses actual Cancel control")
 if replay_result:
  await click(game.ui.room_bed_summary)
  await settled_drawer()
  check(practice.stage==Guide.Lesson.CLOSE_PANEL and game.ui.context_open,"switching panels cannot acknowledge explicit close")
  await key(KEY_ESCAPE)
 else:
  await click(game.ui.build_cancel_button)
 await lesson(Guide.Lesson.HUNTER_DANGER,"18-hunter-danger")
 await lesson(Guide.Lesson.COMPLETE,"19-complete",28.0)
 check(model.hunter.attacks>0 and room.shots>0 and room.electricity>0,"actual combat attacks and Dynamo production")
 check(is_instance_valid(practice.repeat) and practice.repeat.is_visible_in_tree(),"Replay Tutorial shown on completion")
 check(no_permanent_changes(before),"tutorial leaves XP, Cash, inventory, spins and active-match ledger unchanged")
 check(receipts_match(),"exact successful tutorial transactions")
 var receipt: Dictionary={"lessons":lesson_trace,"transactions":practice.receipt,"viewport":[root.get_visible_rect().size.x,root.get_visible_rect().size.y]}
 FileAccess.open(output+"tutorial-receipt.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"  ")+"\n")
 if replay_result:
  await click(practice.repeat)
  check(game.tutorial_active and game.model!=model and game.onboarding.step==0 and game.profile.tutorial_completed,"actual Replay starts a fresh practice model")
  check(no_permanent_changes(before),"replay does not grant or spend persistent resources")
  await capture("20-replay-objective")
 else:
  await click(practice.proceed)
  check(game.profile.tutorial_completed and not game.tutorial_active and game.ui.current_screen=="story_prepare","actual Continue Story saves completion and opens Story")
  check(no_permanent_changes(before),"Continue Story opens the menu without spending or settling a match")
  await capture("20-story-preparation")
 var persisted:=PlayerProfile.new(game.profile.path)
 check(persisted.load_profile(true) and persisted.tutorial_completed,"completion flag survives profile reload")
 if record_walkthrough:await wait(1.8)
 await finish()

func lesson(step: int,name: String,seconds: float=7.0):
 var deadline:=Time.get_ticks_msec()+int(seconds*1000)
 while game.onboarding.step<step and Time.get_ticks_msec()<deadline:
  await process_frame
 check(game.onboarding.step==step,"expected exact lesson "+str(step+1))
 if game.onboarding.step!=step:
  print("LIVING_TUTORIAL_INPUT_CHECKS=",checks," FAILURES=",failures)
  game.audio_system.shutdown()
  game.queue_free()
  quit(1)
  await create_timer(30.0).timeout
  return
 await settled_drawer()
 await capture(name)
 lesson_trace.append({"step":step+1,"name":Guide.TITLES[step]})
 if record_walkthrough:await wait(1.1)

func settled_drawer():
 var deadline:=Time.get_ticks_msec()+2500
 while game.ui.bottom_context!=null and game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()<deadline:
  await process_frame
 await process_frame

func button_is_highlighted(button) -> bool:
 if not is_instance_valid(button) or not button.is_visible_in_tree():return false
 var at: Vector2=button.get_global_transform_with_canvas()*(button.size*.5)
 var local: Vector2=game.onboarding.get_global_transform_with_canvas().affine_inverse()*at
 var actual: Rect2=practice.focus_target()
 return actual.has_area() and actual.get_center().distance_to(local)<1.0

func click_point(point):
 if record_walkthrough:
  Input.warp_mouse(point)
  await wait(.18)
 await super.click_point(point)

func motion_to_current_cell():
 practice.focus_target()
 if not practice.target_position.is_finite():return
 var event:=InputEventMouseMotion.new()
 event.position=root.get_final_transform()*game.world_to_screen(practice.target_position)
 event.global_position=event.position
 Input.parse_input_event(event)
 await process_frame
 await process_frame

func click_current_cell():
 practice.focus_target()
 check(practice.target_position.is_finite(),"practice points at a valid clickable world cell")
 if not practice.target_position.is_finite():return
 var target: Vector2=practice.target_position
 var at: Vector2=game.world_to_screen(target)
 var local: Vector2=game.onboarding.get_global_transform_with_canvas().affine_inverse()*at
 check(practice.focus_target().get_center().distance_to(local)<1.0,"world highlight is exactly centered on actual legal placement")
 await world_click(target)

func receipts_match() -> bool:
 var kinds: Array=[]
 for note in practice.receipt:kinds.append(note.event)
 return kinds==["build","explicit_placement_cancel","build","building_upgrade","repair","panel_closed","practice_combat"] and practice.receipt[0].kind=="turret" and practice.receipt[2].kind=="generator"

func no_permanent_changes(before: Dictionary) -> bool:
 var after: Dictionary=game.profile._reward_snapshot()
 for key in ["xp","rm_cash","inventory","pending_spins","active_match"]:
  if before[key]!=after[key]:return false
 return true

func finish():
 game.audio_system.shutdown()
 await wait(.2)
 game.queue_free()
 await process_frame
 print("LIVING_TUTORIAL_INPUT_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures!=0))
