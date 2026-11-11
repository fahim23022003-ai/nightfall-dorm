extends SceneTree
# Real Linux software-rendered mobile-layout previews, not Android hardware proof.
# Claims, sleep, funds and levels are prepared fixtures for visual inspection.
var game
var output="res://docs/screenshots/android/"
func _initialize(): call_deferred("run")
func capture(name: String):
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var code=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("MOBILE_RENDER ",name," image=",image.get_size()," safe=",game.mobile_layout.safe_rect," scale=",game.mobile_layout.scale_factor," exit=",code)
 if code!=OK: quit(1)
func fixture():
 game.start_match()
 game.model.claim_room(1)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=1000
 room.electricity=200
 game.model.upgrade_bed()
 game.model.upgrade_door()
 game.model.buy("turret",0)
 game.model.buy("generator",1)
 game.focus_camera(true)
 return room
func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://android-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 game.mobile_mode=true
 root.add_child(game)
 root.mode=Window.MODE_WINDOWED
 await process_frame
 for shape in [{"name":"16x9","size":Vector2i(1280,720)},{"name":"19_5x9","size":Vector2i(1560,720)},{"name":"20x9-safe","size":Vector2i(1600,720)}]:
  root.size=shape.size
  await create_timer(0.2).timeout
  game.mobile_layout.safe_override=Rect2(80,18,1500,688) if shape.name=="20x9-safe" else Rect2()
  game.mobile_layout.apply()
  game.return_menu()
  await capture(shape.name+"-menu")
  game.ui.progression.show_loadout()
  await capture(shape.name+"-loadout")
  fixture()
  game.selected_tile=3
  game.ui.open_context()
  game.focus_camera(true)
  await capture(shape.name+"-build")
  game.begin_placement("repair")
  await capture(shape.name+"-confirm")
  game.cancel_placement()
  game.toggle_pause()
  await capture(shape.name+"-pause")
  game.toggle_pause()
 game.return_menu()
 game.ui.show_settings()
 await capture("20x9-safe-settings")
 game.ui.progression.show_ranks()
 var view=game.ui.panel.get_node("MobileScroll")
 view.scroll_vertical=1000
 await capture("20x9-safe-rewards-scrolled")
 var before=game.audio_system.music_start_count
 fixture()
 game.suspend_mobile()
 var paused=game.model.time
 await create_timer(0.1).timeout
 game.resume_mobile()
 print("MOBILE_LIFECYCLE paused=",not game.model.running," frozen=",is_equal_approx(paused,game.model.time)," music_starts=",before,"/",game.audio_system.music_start_count," mobile_voices=",game.audio_system.voices.size())
 await capture("20x9-safe-resumed-paused")
 game.model.result="defeat"
 await process_frame
 await create_timer(1.1).timeout
 await capture("20x9-safe-result-no-xp-fixture")
 print("LINUX_PREVIEW_PROFILE process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," static_memory_bytes=",OS.get_static_memory_usage()," fps=",Engine.get_frames_per_second()," NOTE=software_preview_not_Android_device_performance")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 quit()
