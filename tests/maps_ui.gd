extends SceneTree
var checks=0
var failures=0
var game
func check(ok,label):
 checks+=1
 if not ok:
  failures+=1
  push_error("MAP UI: "+label)
func _initialize(): call_deferred("run")
func settle_drawer():
 await process_frame
 if game!=null and is_instance_valid(game) and game.mode=="match" and game.ui.bottom_context!=null:
  var deadline=Time.get_ticks_msec()+1500
  while game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()<deadline:await process_frame
 await process_frame
func click(point,double_click=false):
 await settle_drawer()
 point=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 for pressed in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=pressed
  e.double_click=pressed and double_click
  Input.parse_input_event(e)
  await process_frame
 await settle_drawer()
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://maps-ui-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.set_process(false)
 # Grant stage access only; no gameplay/economy claim is made by this input fixture.
 for known in StageCatalog.STAGES:
  game.profile.campaign_records[known.id]={"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"standard","first_match_id":1}
 game.profile.next_match_id=maxi(2,game.profile.next_match_id)
 var cases=StageCatalog.STAGES.duplicate()
 cases.append({"id":"legacy","map":"legacy"})
 for stage in cases:
  for index in range(6):
   check(game.start_match() if stage.id=="legacy" else game.start_stage(stage.id),"actual game start succeeds "+stage.id)
   check(game.model.map_id==stage.map,"input test uses the intended map, never silently falls back to legacy")
   game.model.claim_room(index)
   var room=game.model.player()
   game.model.player_position=room.bed_position()
   check(game.model.sleep_player(),"sleep "+stage.id+str(index))
   room.gold=10000
   room.electricity=10000
   room.bed_level=4
   game.focus_camera(true)
   game.ui.update_match()
   var last=room.tile_count()-1
   await click(game.world_to_screen(room.tile_position(last)))
   check(game.selected_tile==last and game.ui.context_open,"actual highest expanded pad selected")
   game.focus_camera(true)
   game.ui.update_match()
   game.ui.close_context();await settle_drawer()
   check(not game.ui.context_box.is_visible_in_tree(),"closed compact toolbar leaves the gameplay area clear")
   for tile in range(room.tile_count()):
    var screen=game.world_to_screen(room.tile_position(tile))
    check(Rect2(60,135,1160,470).has_point(screen),"all pads visible in compact closed focused gameplay area")
    check(not game.ui.context_box.get_global_rect().has_point(screen),"closed drawer clears every pad: %s room%d tile%d at%s panel%s" % [stage.id,index,tile,screen,game.ui.context_box.get_global_rect()])
   await click(game.world_to_screen(room.tile_position(last)))
   var before=Vector2(room.gold,room.electricity)
   var card=game.ui.actions["build:repair"].get_global_rect().get_center()
   await click(card)
   await click(card,true)
   check(room.buildings.has(last) and room.buildings.size()==1,"direct BUILD plus duplicate click buys highest pad once")
   check(Vector2(room.gold,room.electricity)==before-Vector2(40,5),"highest pad charge exact")
   game.ui.close_context();await settle_drawer()
   await click(game.world_to_screen(room.tile_position(last)))
   game.ui.update_match()
   await click(game.ui.actions.sell.get_global_rect().get_center())
   check(room.buildings.is_empty(),"actual highest-pad sell frees pad")
   check(Vector2(room.gold,room.electricity)==before-Vector2(20,2.5),"highest-pad half refund exact")
   check(room.build("generator",last),"sold highest pad reusable")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("MAP_UI_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
