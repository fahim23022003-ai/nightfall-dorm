extends SceneTree
func _initialize():call_deferred("run")
func run():
 var a=AudioDirector.new();root.add_child(a);a.begin_cinematic();a.update_state(.2,null,"intro")
 var opening=a.soundtrack.current;a.update_state(.2,null,"menu")
 print("SESSION_SELECTION ",JSON.stringify({"pid":OS.get_process_id(),"opening":opening,"menu":a.soundtrack.current,"music_players":a.music_start_count}))
 a.shutdown();a.queue_free();await create_timer(.05).timeout;quit()
