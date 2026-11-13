extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var path="user://overhaul-exp-ui-"+str(Time.get_ticks_usec())+".json";var p=PlayerProfile.new(path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await process_frame
 check(game.start_endless(MapCatalog.IDS[0],"standard",17),"actual Game starts new expandable Endless")
 var m=game.model;m.player_position=m.rooms[0].center();m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var r=m.player();r.bed_level=4;r.door_level=4;r.gold=1e5;r.electricity=1e5
 game.ui.update_match();game.ui.expansion_ui.open();await create_timer(.31).timeout
 var before=r.gold;var electric=r.electricity;var origin=m.player_position;var door=r.door_position();var bed=r.bed_position()
 check(game.ui.context_mode=="expansion" and game.ui.expansion_ui.purchase_button.visible and not game.ui.expansion_ui.purchase_button.disabled,"real contextual paid expansion control is accessible")
 game.ui.expansion_ui.purchase_button.pressed.emit();check(r.tile_count()==6 and r.gold==before-120 and r.electricity==electric-15,"real expansion button spends once and creates capacity six and usable floor")
 check(m.player_position==origin and r.bed_position()==bed and r.door_position()==door,"UI expansion never teleports player/door/bed")
 game.ui.close_context();await create_timer(.31).timeout;check(not game.ui.context_box.visible,"expansion drawer closes back to compact toolbar")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 print("OVERHAUL_EXPANSION_UI_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
