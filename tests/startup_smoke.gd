extends SceneTree
# Start the actual main scene and use its normal graceful quit/audio drain path.
func _initialize(): call_deferred("run")
func run():
 # A fresh-start contract needs an absent isolated profile, not the graduate
 # profile deliberately shared by the preceding regression fixtures.
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://startup-fresh-%d-%d.json" % [OS.get_process_id(),Time.get_ticks_usec()])
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode!="intro" or game.onboarding==null or game.onboarding.phase!="cinematic":
  push_error("Fresh application must start the animated opening")
  quit(1)
  return
 for i in range(120): await process_frame
 print("MAIN_STARTUP=PASS MODE=",game.mode)
 game.request_quit()
