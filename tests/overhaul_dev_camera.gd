extends SceneTree
var checks=0
var failures=0
func check(value,label):
 checks+=1
 if not value:failures+=1;push_error("CAMERA "+label)
func _initialize():call_deferred("run")
func run():
 preload("res://tests/onboarding_test_support.gd").prepare()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.skip();await process_frame
 for map in MapCatalog.IDS:
  game.start_practice("witch",false,["shield","repair"],map);await process_frame
  var m=game.model;var room=m.player();var h=m.hunter
  h.target=-1;game.focus_camera(true);var baseline=game.camera.position;var zoom=game.camera.zoom
  h.target=room.index;h.state=HunterState.State.MOVE;h.position=room.door_approach()+room.door_normal()*65;game.focus_camera(true)
  for corner in [Vector2(-50,-105),Vector2(50,45)]:
   var point=game.world_to_screen(h.position+corner)
   check(point.x>=59 and point.x<=1221 and point.y>=149 and point.y<=621,"local full body inside fixed safe area "+map)
  var position=game.camera.position;var scale=game.camera.zoom
  game.ui.open_context();game.focus_camera(true);check(position.is_equal_approx(game.camera.position) and scale.is_equal_approx(game.camera.zoom),"open drawer does not reframe "+map)
  game.ui.close_context();game.focus_camera(true);check(position.is_equal_approx(game.camera.position),"close drawer does not reframe "+map)
  h.position=room.door_approach()+room.door_normal()*300;game.focus_camera(true);check(baseline.is_equal_approx(game.camera.position) and zoom.is_equal_approx(game.camera.zoom),"distant Hunter does not expand view "+map)
  h.position=room.door_approach()+room.door_normal()*65;h.target=(room.index+1)%6;game.focus_camera(true);check(baseline.is_equal_approx(game.camera.position),"other room target does not expand view "+map)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 print("OVERHAUL_CAMERA_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
