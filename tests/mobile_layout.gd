extends SceneTree
var checks=0
var failures=0
var game
var profile_path=""
func check(value: bool,label: String):
 checks+=1
 if not value:
  failures+=1
  push_error("MOBILE LAYOUT QA: "+label)

func visible_buttons(node: Node,out: Array):
 if node is Button and node.is_visible_in_tree() and not node.is_queued_for_deletion(): out.append(node)
 for child in node.get_children(): visible_buttons(child,out)

func _initialize(): call_deferred("run")
func run():
 for size in [Vector2(1280,720),Vector2(1560,720),Vector2(1600,720),Vector2(2400,1080)]:
  for margins in [Vector2.ZERO,Vector2(90,20),Vector2(0,40)]:
   var safe=Rect2(margins, size-margins-Vector2(20,10))
   var result=DormMobileLayout.fit(size,safe)
   var box=Rect2(result.origin,Vector2(1280,720)*result.scale)
   check(safe.grow(0.01).encloses(box),"design canvas fits safe area "+str(size)+str(margins))
   check(is_equal_approx(box.size.x/box.size.y,1280.0/720.0),"safe scaling preserves aspect")
   check(result.scale>0,"safe scale remains positive")
   check(box.get_center().distance_to(safe.get_center())<0.01,"canvas centered inside asymmetric safe inset")
 var invalid=DormMobileLayout.fit(Vector2(1280,720),Rect2(-9000,-9000,2,2))
 check(invalid.origin==Vector2.ZERO and invalid.scale==1,"invalid offscreen safe area falls back to viewport")
 profile_path="user://qa-mobile-layout-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate()
 game.mobile_mode=true
 root.add_child(game)
 await process_frame
 game.set_process(false)
 for page in ["menu","settings","help","ranks","loadout"]:
  if page=="menu": game.ui.show_menu()
  elif page=="settings": game.ui.show_settings()
  elif page=="help": game.ui.show_help()
  elif page=="ranks": game.ui.progression.show_ranks()
  else: game.ui.progression.show_loadout()
  await process_frame
  var buttons=[]
  visible_buttons(game.ui.panel,buttons)
  check(not buttons.is_empty(),"mobile page has actionable buttons "+page)
  for button in buttons:
   # Scroll contents can be clipped deliberately; each target remains finger sized.
   check(button.size.y>=60,"mobile finger target >=60logicalpx "+page+" "+button.text)
   check(button.size.x>=100,"mobile button has useful finger width")
 for index in range(6):
  game.start_match()
  game.model.claim_room(index)
  var room=game.model.player()
  game.model.player_position=room.bed_position()
  game.model.sleep_player()
  game.focus_camera(true)
  for tile in range(6):
   var point=game.world_to_screen(room.tile_position(tile))
   var local=game.ui.panel.get_global_transform().affine_inverse()*point
   check(Rect2(20,90,1240,514).has_point(local),"all room pads visible outside fixedHUD "+str(index)+" "+str(tile))
  game.selected_tile=1
  game.ui.open_context()
  game.focus_camera(true)
  for tile in range(6):
   var point=game.world_to_screen(room.tile_position(tile))
   check(not game.ui.context_box.get_global_rect().has_point(point),"focused pads not covered by mobile build drawer")
  game.ui.close_context()
 game.start_match()
 game.toggle_pause()
 await process_frame
 for node in game.ui.pause_items:
  if node is Button:
   check(node.size.y>=60,"pause actions are finger sized")
   check(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(node.get_rect()),"pause actions remain inside design area")
 game.toggle_pause()
 game.model.result="defeat"
 game._process(0.01)
 await process_frame
 var result_buttons=[]
 visible_buttons(game.ui.panel,result_buttons)
 check(result_buttons.size()>=3,"mobile result exposes all navigation actions")
 for button in result_buttons:
  check(button.size.y>=60,"result navigation is finger sized")
  check(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(button.get_rect()),"result navigation fits screen")
 game.mobile_layout.safe_override=Rect2(90,20,1100,680)
 game.mobile_layout.apply()
 var transformed=Rect2(game.ui.panel.position,game.ui.panel.size*game.ui.panel.scale)
 check(game.mobile_layout.safe_override.grow(0.01).encloses(transformed),"actual CanvasLayer panel respects asymmetric safe insets")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await create_timer(0.1).timeout
 var dir=DirAccess.open("user://")
 for name in dir.get_files():
  if name.begins_with(profile_path.trim_prefix("user://")): DirAccess.remove_absolute("user://"+name)
 print("MOBILE_LAYOUT_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
