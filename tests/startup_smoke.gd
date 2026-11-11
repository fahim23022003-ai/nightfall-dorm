extends SceneTree
# Start the actual main scene and use its normal graceful quit/audio drain path.
func _initialize(): call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 for i in range(120): await process_frame
 print("MAIN_STARTUP=PASS MODE=",game.mode)
 game.request_quit()
