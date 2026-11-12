extends SceneTree
var failures=0
var checks=0
func _initialize(): call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1; push_error("ITEM FEEDBACK: "+label)
func run():
 var path="user://item-feedback-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.profile.inventory={"repair":1}
 game.profile.item_loadout=["repair"]
 check(game.profile.save_profile(),"fixture save")
 check(game.start_match("standard"),"real match start")
 game.model.claim_room(0)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 check(not game.activate_item(0),"full door rejects repair")
 check(game.ui.feedback_text.contains("damaged door"),"actual banner preserves full-door reason")
 check(game.profile.inventory.repair==1,"invalid repair costs no stock")
 game.profile.inventory.repair=0
 for i in range(2):
  check(not game.activate_item(0),"empty stock rejects repeated use")
  check(game.ui.feedback_text=="No stock remaining.","actual banner preserves repeatable stock reason")
 check(not game.activate_item(1),"empty slot rejects")
 check(game.ui.feedback_text.contains("No item equipped"),"empty slot explains why")
 game.profile.read_only=true
 check(not game.activate_item(0),"read-only rejects")
 check(game.ui.feedback_text.contains("read-only"),"read-only banner explains why")
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("ITEM_FEEDBACK_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
