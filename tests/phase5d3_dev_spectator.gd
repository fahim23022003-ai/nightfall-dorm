extends SceneTree
var checks=0
var failures=0
func check(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.onboarding.cancel_intro_audio();game.onboarding.active=false;game.profile.tutorial_completed=true
 for map in MapCatalog.IDS:
  game.start_practice("crusher",false,["shield","repair"],map)
  var m=game.model;var own=m.player();var other=m.rooms[(own.index+1)%6]
  other.owner=1;other.sleeping=true;other.closed=true
  var before=m.player_position;var owner=own.owner;var count=own.buildings.size()
  check(game.spectate_room(other.index),"valid teammate watch")
  for i in range(20):game.focus_camera(false,.05)
  check(game.watched_room==other.index and m.player_position==before and own.owner==owner and own.buildings.size()==count,"spectator is camera only "+map)
  game.ui.update_match();game.audio_system.update_state(.1,m,"match")
  check(game.audio_system.listener_position==own.bed_position(),"critical own-room audio listener preserved")
  other.alive=false;other.sleeping=false;game.ui.teammates.update()
  check(game.ui.teammates.watching.text.contains("ELIMINATED"),"eliminated teammate has stable visible state")
  game.return_to_my_room();check(game.watched_room==-1 and m.player_position==before,"home restores own camera")
  check(not game.spectate_room(own.index) and not game.spectate_room(999),"own/invalid selections rejected")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 print("PHASE5D3_DEV_SPECTATOR_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
