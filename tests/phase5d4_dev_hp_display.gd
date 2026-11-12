extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var path="user://phase5d4-hp-display-"+str(Time.get_ticks_usec())+".json"
 var profile=PlayerProfile.new(path);profile.tutorial_completed=true;profile.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_process(false);game.onboarding.active=false;game.onboarding.cancel_intro_audio();game.start_practice("crusher",false,["shield","repair"],MapCatalog.IDS[0]);await process_frame
 var r=game.model.player()
 for branch in ["renewal","bulwark"]:
  r.door_level=9;r.door_branch=branch;r.door_multiplier=1.0;r.trait_modifiers=StrategyCatalog.TRAITS.fortified.duplicate(true)
  r.door_hp=float(roundi(r.max_hp()))
  var hp=r.door_hp;var maximum=r.max_hp();var rng=game.model.random.state
  game.model.hunter.target=r.index;game.model.hunter.state=HunterState.State.ATTACK
  game.ui.update_match()
  var expected="%d/%d" % [roundi(hp),roundi(maximum)]
  check(game.ui.room_door_summary.text.contains(expected),"integer own-door label rounds both HP values consistently: "+expected)
  check(game.ui.warning_label.text.contains(expected),"integer danger warning uses the same rounded pair")
  check(r.door_hp==hp and r.max_hp()==maximum and game.model.random.state==rng,"display rounding changes neither HP math nor RNG")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("PHASE5D4_HP_DISPLAY_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
