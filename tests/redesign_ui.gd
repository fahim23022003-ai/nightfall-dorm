extends SceneTree
var assertions=0
var failures=0
var game

func check(ok: bool,label: String):
 assertions+=1
 if not ok:
  failures+=1
  push_error("REDESIGN_UI_FAIL: "+label)

func click(point: Vector2,double_click: bool=false):
 var physical=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new()
 motion.position=physical
 motion.global_position=physical
 Input.parse_input_event(motion)
 await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=physical
  event.global_position=physical
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  event.double_click=double_click and pressed
  Input.parse_input_event(event)
  await process_frame

func key(code):
 var event=InputEventKey.new()
 event.keycode=code
 event.pressed=true
 Input.parse_input_event(event)
 await process_frame
 event=InputEventKey.new()
 event.keycode=code
 event.pressed=false
 Input.parse_input_event(event)
 await process_frame

func fixture(index):
 game.start_match()
 game.set_process(false)
 game.model.claim_room(index)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 game.model.player().gold=1000
 game.model.player().electricity=100
 game.tutorial_enabled=false
 game.focus_camera(true)
 game.ui.update_match()

func _initialize(): call_deferred("run")

func run():
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.sound_volume=0
 for index in range(6):
  fixture(index)
  await process_frame
  var room=game.model.player()
  var focus_zoom=game.camera.zoom.x
  check(focus_zoom>1.5,"room-focused zoom for room "+str(index))
  for tile in range(6):
   var screen=game.world_to_screen(room.tile_position(tile))
   check(Rect2(0,76,900,562).has_point(screen),"floor tile projects into usable map area room="+str(index)+" tile="+str(tile))
  await click(game.world_to_screen(room.tile_position(1)))
  check(game.selected_tile==1 and game.ui.context_open,"actual click selects second tile in room "+str(index))
  check(game.ui.context_mode=="build","empty tile opens building palette")
  var initial_gold=room.gold
  await click(game.ui.actions["build:generator"].get_global_rect().get_center())
  check(game.pending_build=="generator" and room.buildings.is_empty() and room.gold==initial_gold,"card begins preview without purchase room "+str(index))
  check(game.placement_reason()=="" and not game.ui.confirm_button.disabled,"valid preview enables confirmation")
  await click(game.ui.confirm_button.get_global_rect().get_center())
  check(room.buildings.has(1) and room.buildings[1].kind=="generator","actual confirmation builds on selected tile")
  check(is_equal_approx(room.gold,initial_gold-Catalog.BUILDINGS.generator.gold),"confirmation charges exactly once")
  check(game.pending_build=="" and not game.confirm_placement(),"duplicate confirmation cannot charge twice")
  game.begin_placement("turret")
  check(game.placement_reason()!="" and not game.confirm_placement(),"occupied tile rejects preview and confirmation")
  game.cancel_placement()
  var after_build=room.gold
  await click(game.world_to_screen(room.tile_position(2)))
  await click(game.ui.actions["build:turret"].get_global_rect().get_center())
  await key(KEY_ESCAPE)
  check(game.pending_build=="" and room.gold==after_build and not room.buildings.has(2),"Escape cancels without charge")
  check(game.model.running,"cancel placement does not unexpectedly pause")
  game.begin_placement("turret")
  await click(game.world_to_screen(room.center()+Vector2(-80,160 if index<3 else -160)))
  check(not game.placement_on_tile and game.placement_reason()!="" and game.ui.confirm_button.disabled,"out-of-room click gives invalid preview")
  check(not game.confirm_placement() and room.gold==after_build,"invalid preview never charges")
  game.toggle_map()
  game.focus_camera(true)
  check(game.full_map and game.pending_build=="" and game.camera.zoom.x<focus_zoom,"strategic map cancels preview and zooms out")
  for other in game.model.rooms:
   check(Rect2(0,76,1280,562).has_point(game.world_to_screen(other.center())),"strategic overview contains every room center")
  game.toggle_map()
  game.focus_camera(true)
  check(not game.full_map and is_equal_approx(game.camera.zoom.x,focus_zoom),"focus restores correct room zoom")
 # Reproduce the PC report: move from a double-clicked card across the map
 # before reaching Confirm. Mere mouse motion must never relocate the preview.
 for kind in Catalog.BUILDINGS:
  fixture(0)
  var resident=game.model.player()
  resident.bed_level=4
  game.ui.update_match()
  await click(game.world_to_screen(resident.tile_position(2)))
  var card=game.ui.actions["build:"+kind].get_global_rect().get_center()
  await click(card)
  await click(card,true)
  var locked=resident.tile_position(2)
  var funds=Vector2(resident.gold,resident.electricity)
  for point in [resident.center()+Vector2(0,140),resident.tile_position(4)]:
   var motion=InputEventMouseMotion.new()
   motion.position=root.get_final_transform()*game.world_to_screen(point)
   motion.global_position=motion.position
   Input.parse_input_event(motion)
   await process_frame
   game.ui.update_match()
   check(game.preview_position==locked and game.selected_tile==2 and game.placement_on_tile,"mouse travel leaves preview locked: "+kind)
   check(game.placement_reason()=="" and not game.ui.confirm_button.disabled,"mouse travel leaves Confirm enabled: "+kind)
  await click(game.ui.confirm_button.get_global_rect().get_center())
  check(resident.buildings.has(2) and game.pending_build=="","pointer travel then Confirm purchases chosen pad: "+kind)
  check(Vector2(resident.gold,resident.electricity)==funds-Vector2(Catalog.BUILDINGS[kind].gold,Catalog.BUILDINGS[kind].power),"pointer travel purchase charges once: "+kind)
  var paid=Vector2(resident.gold,resident.electricity)
  await click(game.world_to_screen(resident.tile_position(1)))
  game.ui.update_match() # fixture freezes processing; refresh newly selected pad actions
  await click(game.ui.actions["build:"+kind].get_global_rect().get_center())
  var travel=InputEventMouseMotion.new()
  travel.position=root.get_final_transform()*game.world_to_screen(resident.center()+Vector2(0,140))
  travel.global_position=travel.position
  Input.parse_input_event(travel)
  await process_frame
  var cancel_button: Button
  for item in game.ui.confirmation_items:
   if item is Button and item!=game.ui.confirm_button: cancel_button=item
  await click(cancel_button.get_global_rect().get_center())
  check(game.pending_build=="" and not game.ui.context_open and not resident.buildings.has(1),"mouse travel then Cancel clears placement: "+kind)
  check(Vector2(resident.gold,resident.electricity)==paid,"mouse travel then Cancel never charges: "+kind)
 fixture(0)
 await process_frame
 var room=game.model.player()
 await key(KEY_M)
 game.focus_camera(true)
 check(game.full_map,"M key opens strategic overview")
 await click(game.world_to_screen(room.tile_position(4)))
 check(game.selected_tile==4 and not game.full_map and game.ui.context_mode=="build","clicking owned tile in overview refocuses room and selects correct tile")
 var previous_tutorial=game.tutorial_enabled
 await key(KEY_G)
 check(game.tutorial_enabled!=previous_tutorial,"G key toggles contextual tutorial")
 game.begin_placement("generator")
 var gold_before_preview_move=room.gold
 await click(game.world_to_screen(room.tile_position(3)))
 check(game.selected_tile==3 and game.pending_build=="generator" and room.gold==gold_before_preview_move,"preview relocates to a different valid tile without charging")
 await click(game.ui.confirm_button.get_global_rect().get_center())
 check(room.buildings.has(3) and room.buildings[3].kind=="generator","confirmation commits the relocated preview tile")
 game.selected_tile=0
 room.gold=0
 game.begin_placement("turret")
 check(game.placement_reason()!="" and not game.confirm_placement() and room.gold==0,"insufficient funds blocks final charge")
 room.gold=1000
 room.electricity=0
 game.begin_placement("heavy")
 check(game.placement_reason()!="" and not game.confirm_placement(),"advanced prerequisite and power block placement")
 game.begin_placement("generator")
 game.toggle_pause()
 check(game.pending_build=="" and not game.model.running,"pause clears pending placement")
 game.begin_placement("generator")
 check(game.placement_reason()!="" and not game.confirm_placement(),"paused confirmation rejected")
 game.cancel_placement()
 game.toggle_pause()
 game.start_match()
 game.set_process(false)
 check(game.pending_build=="" and not game.full_map and game.model.player_room==-1,"restart clears camera/placement ownership state")
 game.return_menu()
 check(game.mode=="menu" and game.camera.zoom==Vector2.ONE and game.pending_build=="","menu restores neutral camera and clears preview")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await create_timer(0.2).timeout
 print("REDESIGN_UI_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
