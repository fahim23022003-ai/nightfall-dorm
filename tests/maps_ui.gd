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
func click(point,double_click=false):
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
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://maps-ui-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for stage in StageCatalog.STAGES:
  for index in range(6):
   game.start_match()
   game.model.configure_stage(stage.id)
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
   for tile in range(room.tile_count()):
    var screen=game.world_to_screen(room.tile_position(tile))
    check(Rect2(20,80,860,540).has_point(screen),"all pads visible in focused build area")
    check(not game.ui.context_box.get_global_rect().has_point(screen),"inspector clears every pad")
   var before=Vector2(room.gold,room.electricity)
   var card=game.ui.actions["build:repair"].get_global_rect().get_center()
   await click(card)
   await click(card,true)
   await click(game.ui.confirm_button.get_global_rect().get_center())
   check(room.buildings.has(last) and room.buildings.size()==1,"double card click then confirm buys highest pad once")
   check(Vector2(room.gold,room.electricity)==before-Vector2(40,5),"highest pad charge exact")
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
