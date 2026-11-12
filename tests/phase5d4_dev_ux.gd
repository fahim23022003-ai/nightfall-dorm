extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.onboarding.active=false;game.onboarding.cancel_intro_audio();game.profile.tutorial_completed=true
 for map in MapCatalog.IDS:
  game.start_practice("crusher",false,["shield","repair"],map)
  var m=game.model;var r=m.player();game.selected_tile=m.practice_tile
  var camera=game.camera.position;var zoom=game.camera.zoom;var pos=m.player_position
  var gold=r.gold;var power=r.electricity;var rng=m.random.state
  game.ui.open_context();game.ui.refresh_context()
  check(game.ui.context_box.position==BottomContextPanel.BODY.position and game.ui.context_box.size==BottomContextPanel.BODY.size,"fixed bottom region "+map)
  check(game.camera.position==camera and game.camera.zoom==zoom and m.player_position==pos,"opening detail moves no camera or character")
  game.ui.upgrade_selected();game.ui.specialization_items[1].pressed.emit()
  check(r.gold==gold and r.electricity==power and m.random.state==rng,"branch preview spends nothing and consumes no RNG")
  check(game.ui.pending_branch!="" and not game.ui.branch_confirm.disabled,"explicit branch confirm is available")
  game.ui.confirm_specialization()
  check(r.buildings[m.practice_tile].level==5 and r.gold<gold,"only confirm purchases exclusive choice")
  game.ui.open_room_panel("bed")
  check(game.ui.context_box.position==BottomContextPanel.BODY.position and game.camera.position==camera,"bed inspector same region and camera")
  game.ui.open_room_panel("door")
  check(game.ui.context_box.position==BottomContextPanel.BODY.position and game.camera.position==camera,"door inspector same region and camera")
  game.ui.close_context();check(not game.ui.context_box.visible,"idle detail collapses instead of covering world")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 print("PHASE5D4_DEV_UX_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
