extends SceneTree
# Real rendered and mouse-input map fixtures; not naturally won matches.
var game
var checks=0
var failures=0
var output="res://docs/evidence/maps/"
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("MAP RENDER: "+label)
func capture(name: String):
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var code=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("MAP_CAPTURE ",name," size=",image.get_size()," code=",code)
 check(code==OK,"image saved "+name)
func click(point: Vector2,double_click=false):
 point=root.get_final_transform()*point
 Input.warp_mouse(point) # keep real X11 cursor and injected events consistent
 var motion=InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 for down in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=down
  event.double_click=down and double_click
  Input.parse_input_event(event)
  await process_frame
 game.focus_camera(true) # frozen process fixture mimics the live settled camera
func fixture(stage: String,index=0):
 game.start_match()
 game.set_process(false)
 check(game.model.configure_stage(stage),"stage map configured "+stage)
 check(game.model.claim_room(index),"claim new map room")
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 check(game.model.sleep_player(),"sleep new map room")
 room.gold=1000
 room.electricity=1000
 game.focus_camera(true)
 game.ui.update_match()
 return room
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://map-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.size=Vector2i(1280,720)
 for stage in StageCatalog.STAGES:
  var room=fixture(stage.id)
  game.full_map=true
  game.focus_camera(true)
  await capture(stage.id+"-overview")
  game.full_map=false
  game.focus_camera(true)
  # Every pad in this representative room is actually clicked, not just projected.
  for tile in range(room.tile_count()):
   var point=game.world_to_screen(room.tile_position(tile))
   check(Rect2(20,80,860,545).has_point(point) if game.ui.context_open else Rect2(20,80,1240,545).has_point(point),"pad within visible usable map area")
   await click(point)
   check(game.selected_tile==tile and game.ui.context_open,"actual pad click selects tile "+str(tile))
   game.ui.update_match()
  check(not game.ui.guide_box.visible,"custom map inspector clears tutorial from bed and door")
  var highest=room.tile_count()-1
  check(game.selected_tile==highest,"highest pad selected")
  await capture(stage.id+"-highest-pad-inspector")
  var card=game.ui.actions["build:turret"].get_global_rect().get_center()
  await click(card)
  await click(card,true)
  var locked=game.preview_position
  var move=InputEventMouseMotion.new()
  move.position=root.get_final_transform()*game.world_to_screen(room.center()+Vector2(0,room.bounds().size.y))
  move.global_position=move.position
  Input.warp_mouse(move.position)
  Input.parse_input_event(move)
  await process_frame
  game.ui.update_match()
  check(game.preview_position==locked and game.placement_reason()=="","preview stays locked while pointer crosses map")
  await click(game.ui.confirm_button.get_global_rect().get_center())
  check(room.buildings.has(highest),"purchase highest pad")
  await click(game.world_to_screen(room.tile_position(highest)))
  game.ui.update_match()
  await capture(stage.id+"-highest-pad-purchased")
  var funds=Vector2(room.gold,room.electricity)
  await click(game.ui.actions.sell.get_global_rect().get_center())
  check(not room.buildings.has(highest),"sale reuses highest pad")
  check(game.ui.guide_box.visible,"tutorial preference restored after inspector closes")
  check(Vector2(room.gold,room.electricity)==funds+Vector2(10,0),"half refund on highest pad")
 # Opposite laboratory door orientation and mansion capacity variation.
 fixture("stage_4",3)
 game.ui.open_context()
 game.focus_camera(true)
 game.ui.update_match()
 await capture("lab-right-side-door")
 root.size=Vector2i(960,600)
 await process_frame
 for index in [0,1]:
  var room=fixture("stage_5",index)
  await click(game.world_to_screen(room.tile_position(room.tile_count()-1)))
  game.ui.update_match()
  await capture("mansion-room"+str(index+1)+"-960x540")
 print("MAP_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
