extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var path="user://overhaul-hud-"+str(Time.get_ticks_usec())+".json";var p=PlayerProfile.new(path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.skip();game.onboarding.close_welcome();await process_frame
 for map in MapCatalog.IDS:
  game.start_practice("crusher",false,["shield","repair"],map);await process_frame;game.focus_camera(true)
  var ui=game.ui;var room=game.model.player();var tile=0
  while room.buildings.has(tile):tile+=1
  game.selected_tile=tile
  var camera=game.camera.position;var position=game.model.player_position;var stock=room.gold;var power=room.electricity
  check(ui.room_dock.position.y==650 and ui.quick_repair.position.y>=650 and ui.room_bed_summary.position.y>=650 and ui.room_door_summary.position.y>=650 and ui.room_selected_summary.position.y>=650,"all primary controls are in compact bottom toolbar "+map)
  check(not ui.context_box.visible,"default gameplay leaves contextual drawer hidden")
  ui.open_context();check(ui.bottom_context.is_transitioning(),"opening creates real transition")
  ui.actions["build:turret"].pressed.emit();check(room.gold==stock and room.electricity==power and not room.buildings.has(tile),"moving controls cannot charge resources")
  await create_timer(.31).timeout
  check(ui.context_box.position.is_equal_approx(BottomContextPanel.BODY.position) and ui.context_box.visible and not ui.bottom_context.is_transitioning(),"drawer reaches final lower-middle location")
  check(game.camera.position==camera and game.model.player_position==position,"drawer animation changes neither camera nor character")
  for id in Catalog.BUILDINGS:
   var button=ui.actions["build:"+id];check(button.get_rect().end.y<=BottomContextPanel.BODY.size.y and button.get_rect().end.x<=BottomContextPanel.BODY.size.x,"all registered cards remain inside accessible drawer "+id)
  ui.actions["build:turret"].pressed.emit();check(room.buildings.has(tile) and room.gold<stock,"settled drawer executes real purchase once")
  ui.close_context();check(ui.context_box.visible and ui.bottom_context.is_transitioning(),"close slides existing drawer downward")
  await create_timer(.31).timeout;check(not ui.context_box.visible and ui.room_dock.visible,"compact toolbar restored after slide")
  for i in range(5):ui.open_context();ui.close_context()
  await create_timer(.31).timeout;check(not ui.context_box.visible and not ui.bottom_context.is_transitioning(),"rapid repeated open/close leaves no stranded drawer")
  check(game.camera.position==camera and game.model.player_position==position,"closing still preserves camera/player")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("OVERHAUL_DEV_HUD_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
