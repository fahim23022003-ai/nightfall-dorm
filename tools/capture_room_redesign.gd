extends SceneTree
# Phase-A art/interaction fixture; resource preparation is explicitly disclosed.
var game

func capture(name: String):
 await process_frame
 game.presentation.all_rooms=false
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var path="res://docs/screenshots/redesign/"+name+".png"
 var code=image.save_png(ProjectSettings.globalize_path(path))
 print("PHASE_A_CAPTURE ",name," size=",image.get_size()," exit=",code)
 if code!=OK: quit(1)

func _initialize(): call_deferred("run")

func run():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.mode=Window.MODE_FULLSCREEN
 game.start_match()
 game.model.reset(71)
 game.model.claim_room(1)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=200
 room.electricity=50
 game.model.upgrade_bed()
 game.model.upgrade_door()
 game.model.buy("turret",0)
 game.model.buy("generator",1)
 game.model.buy("repair",2)
 game.model.time=15
 game.model.running=true
 game.sound_volume=0
 game.tutorial_enabled=false
 game.focus_camera(true)
 await create_timer(0.2).timeout
 await capture("phase-a-focused-room")
 game.selected_tile=3
 game.ui.open_context()
 await capture("phase-a-build-menu")
 game.queue_free()
 await process_frame
 quit()
