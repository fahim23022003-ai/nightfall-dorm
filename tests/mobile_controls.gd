extends SceneTree
var checks=0
var failures=0
var game
var save_path=""

func check(value: bool,label: String):
 checks+=1
 if not value:
  failures+=1
  push_error("MOBILE QA: "+label)

func find_button(text: String,node: Node=null):
 if node==null: node=game.ui.panel
 if node is Button and not node.is_queued_for_deletion() and node.is_visible_in_tree() and node.text==text: return node
 for child in node.get_children():
  var found=find_button(text,child)
  if found!=null: return found
 return null

func finger(point: Vector2,pressed: bool,index=0):
 var event=InputEventScreenTouch.new()
 event.position=root.get_final_transform()*point
 event.pressed=pressed
 event.index=index
 Input.parse_input_event(event)
 await process_frame

func tap(point: Vector2,index=0):
 await finger(point,true,index)
 await finger(point,false,index)
 await process_frame

func drag(point: Vector2,relative: Vector2,index=0):
 var event=InputEventScreenDrag.new()
 event.position=root.get_final_transform()*point
 event.relative=relative*root.get_final_transform().get_scale()
 event.index=index
 Input.parse_input_event(event)
 await process_frame

func press_button(label: String):
 var button=find_button(label)
 check(button!=null,"button exists: "+label)
 if button!=null: await tap(button.get_global_rect().get_center())

func walk_route(max_steps=1200):
 for i in range(max_steps):
  var direction=game.touch.movement(0.02)
  game.model.move_player(direction,0.02)
  if game.touch.route.is_empty(): return

func _initialize():
 save_path="user://qa-mobile-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",save_path)
 call_deferred("run")

func run():
 Input.emulate_mouse_from_touch=true
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 game.mobile_mode=true
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.set_process(false)
 check(game.profile.path==save_path,"isolated profile used")
 check(game.ui.current_screen=="menu","mobile main menu starts")
 check(game.audio_system.voices.size()==10,"mobile has bounded ten effect voices")
 await press_button("Start Game")
 check(game.ui.current_screen=="loadout","raw touch opens pre-match loadout")
 await press_button("Start Night")
 check(game.mode=="match" and game.model.running,"raw touch starts real match")
 if game.mode!="match":
  game.audio_system.shutdown()
  await create_timer(0.5).timeout
  game.queue_free()
  await process_frame
  print("MOBILE_CONTROLS_CHECKS=",checks," FAILURES=",failures)
  quit(1)
  return
 game.focus_camera(true)
 var start=game.model.player_position
 var center=game.mobile_layout.screen_point(DormTouchControls.STICK)
 await finger(center+Vector2(45,0),true,0)
 check(game.touch.joystick_finger==0 and game.touch.direction.x>0.5,"touch joystick captures first finger")
 game.model.move_player(game.touch.movement(0.1),0.1)
 check(game.model.player_position.x>start.x,"joystick moves production player")
 await finger(game.mobile_layout.screen_point(Vector2(1190,120)),true,1)
 await finger(game.mobile_layout.screen_point(Vector2(1190,120)),false,1)
 check(game.touch.joystick_finger==0,"second touch does not release joystick finger")
 await finger(center+Vector2(45,0),false,0)
 check(game.touch.joystick_finger==-1 and game.touch.direction==Vector2.ZERO,"release clears movement")
 game.touch.reset()
 game.model.player_position=Vector2(500,410)
 game.focus_camera(true)
 await tap(game.world_to_screen(game.model.rooms[1].center()+Vector2(0,60)))
 check(not game.touch.route.is_empty() and game.model.player_room==-1,"room tap schedules walking, not teleport/instant claim")
 walk_route()
 check(game.model.player_room==1 and game.model.rooms[1].bounds().has_point(game.model.player_position),"real movement route enters and claims tapped room")
 game.focus_camera(true)
 var room=game.model.player()
 if room==null:
  game.audio_system.shutdown()
  await create_timer(0.5).timeout
  game.queue_free()
  await process_frame
  print("MOBILE_CONTROLS_CHECKS=",checks," FAILURES=",failures)
  quit(1)
  return
 check(room.income_rate()==0,"claimed awake room still has no income")
 await tap(game.world_to_screen(room.bed_position()))
 walk_route()
 check(room.sleeping and room.closed,"bed tap route sleeps and locks door")
 game.focus_camera(true)
 room.gold=1000
 room.electricity=100
 await tap(game.world_to_screen(room.tile_position(0)))
 check(game.ui.context_open and game.selected_tile==0,"raw floor tap opens correct build panel")
 var gold=room.gold
 var card=game.ui.actions["build:generator"]
 await tap(card.get_global_rect().get_center())
 check(game.pending_build=="generator" and room.gold==gold and not room.buildings.has(0),"card tap previews without charging")
 await tap(game.ui.confirm_button.get_global_rect().get_center())
 check(room.buildings.has(0) and room.buildings[0].kind=="generator","confirm tap builds actual selected generator")
 check(is_equal_approx(room.gold,gold-Catalog.BUILDINGS.generator.gold),"single tap deducts exactly one purchase")
 var spent=room.spent
 await tap(game.ui.confirm_button.get_global_rect().get_center())
 check(room.spent==spent,"repeated stale confirmation cannot charge twice")
 game.ui.close_context()
 game.focus_camera(true)
 await tap(game.world_to_screen(room.tile_position(1)))
 await tap(game.ui.actions["build:turret"].get_global_rect().get_center())
 check(game.pending_build=="turret","second card preview works")
 gold=room.gold
 game.mobile_back()
 check(game.pending_build=="" and room.gold==gold and not room.buildings.has(1),"Android Back cancels preview without spending")
 game.ui.close_context()
 game.focus_camera(true)
 var tile_before=game.selected_tile
 var dock=game.ui.room_door_summary.get_global_rect().get_center()
 await tap(dock)
 check(game.ui.context_mode=="door" and game.selected_tile==tile_before,"door HUD touch does not leak into floor selection")
 var before_hp=room.max_hp()
 await tap(game.ui.door_button.get_global_rect().get_center())
 check(room.max_hp()>before_hp,"mobile door upgrade changes actual durability")
 room.door_hp-=80
 game.ui.update_match()
 await tap(game.ui.actions.repair.get_global_rect().get_center())
 check(room.door_hp>room.max_hp()-80,"mobile repair restores real door HP")
 game.ui.close_context()
 game.focus_camera(true)
 var saved_gold=room.gold
 room.gold=0
 game.ui.update_match()
 await tap(game.world_to_screen(room.tile_position(2)))
 await tap(game.ui.actions["build:heavy"].get_global_rect().get_center())
 check(game.pending_build=="heavy" and game.ui.confirm_button.disabled,"unavailable card exposes blocked preview instead of relying on hover")
 check(not game.ui.confirmation_details.text.is_empty() and room.gold==0 and not room.buildings.has(2),"blocked touch preview gives visible reason without charging")
 game.mobile_back()
 room.gold=saved_gold
 game.ui.close_context()
 var starts=game.audio_system.music_start_count
 var time_before=game.model.time
 var gold_before=room.gold
 game.suspend_mobile()
 check(game.in_background and not game.model.running and game.audio_system.suspended,"background pauses model and audio")
 game._process(5)
 check(game.model.time==time_before and room.gold==gold_before,"background has no economy/combat catch-up")
 check(game.touch.direction==Vector2.ZERO and game.touch.route.is_empty(),"background clears all touch movement")
 for loop in game.audio_system.loops.values(): check(loop.stream_paused,"every looping stream paused in background")
 game.resume_mobile()
 check(not game.in_background and not game.model.running,"resume requires explicit player continuation")
 check(game.audio_system.music_start_count==starts and not game.audio_system.suspended,"resume keeps existing music positions, no restart")
 await press_button("Resume")
 check(game.model.running,"touch resumes paused match")
 game.change_setting("battery_saver",true)
 check(Engine.max_fps==30,"battery saver caps requested frame rate at30")
 game.change_setting("battery_saver",false)
 check(Engine.max_fps==60,"normal mobile mode requests60 cap")
 var reloaded=PlayerProfile.new(save_path)
 check(reloaded.load_profile() and not reloaded.settings.battery_saver,"mobile setting persists to disk")
 game.return_menu()
 await press_button("Ranks & rewards")
 var scroll=game.ui.panel.get_node_or_null("MobileScroll")
 check(scroll is ScrollContainer,"rewards use actual scrolling container")
 if scroll!=null:
  var before=game.profile.equipped.duplicate()
  var p=scroll.get_global_rect().position+Vector2(550,250)
  await finger(p,true)
  for i in range(1,6): await drag(p-Vector2(0,i*32),Vector2(0,-32))
  await finger(p-Vector2(0,160),false)
  check(scroll.scroll_vertical>0,"raw touch drag scrolls reward list")
  check(game.profile.equipped==before,"scroll drag does not equip or purchase")
  scroll.scroll_vertical=0
  await process_frame
  var equip=find_button("Equip")
  check(equip!=null,"unlocked reward remains available after scrolling")
  if equip!=null:
   var begin=equip.get_global_rect().get_center()
   await finger(begin,true)
   for i in range(1,6): await drag(begin-Vector2(0,i*30),Vector2(0,-30))
   await finger(begin-Vector2(0,150),false)
   check(game.profile.equipped==before,"drag beginning on Equip cancels child button activation")

 # Enable the documented touchscreen emulation hint so Godot's native scroll
 # handler is active alongside the explicit cross-platform adapter.
 if scroll!=null:
  Input.emulate_touch_from_mouse=true
  check(DisplayServer.is_touchscreen_available(),"touchscreen-aware native GUI handler enabled for compatibility check")
  scroll.scroll_vertical=0
  await process_frame
  var p=scroll.get_global_rect().position+Vector2(550,250)
  await finger(p,true)
  for i in range(1,6): await drag(p-Vector2(0,i*32),Vector2(0,-32))
  await finger(p-Vector2(0,160),false)
  check(scroll.scroll_vertical>=128 and scroll.scroll_vertical<=190,"native touchscreen and adapter produce one bounded drag distance")
  check(game.profile.equipped.is_empty(),"touchscreen-aware drag still cannot equip")
  Input.emulate_touch_from_mouse=false
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await create_timer(0.1).timeout
 var dir=DirAccess.open("user://")
 for name in dir.get_files():
  if name.begins_with(save_path.trim_prefix("user://")): DirAccess.remove_absolute("user://"+name)
 print("MOBILE_CONTROLS_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
