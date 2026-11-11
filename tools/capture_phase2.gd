extends SceneTree
# New screen/audio verification fixture, not a naturally earned ranked promotion.
var game
var root_path="res://docs/screenshots/phase2/"
var frames=0
var record: AudioEffectRecord

func _initialize(): call_deferred("run")
func capture(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var result=image.save_png(ProjectSettings.globalize_path(root_path+name+".png"))
 print("PHASE2_RENDER ",name," size=",image.get_size()," code=",result)
 if result!=OK: quit(1)

func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path))
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase2-render-fixture-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.mode=Window.MODE_FULLSCREEN
 record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 await create_timer(0.3).timeout
 await capture("01-menu-rank")
 game.ui.show_settings()
 await capture("02-audio-settings")
 game.ui.progression.show_ranks()
 await capture("03-bronze-rewards")
 game.profile.xp=695
 game.profile.equip("reinforced")
 game.ui.progression.show_loadout()
 await capture("04-loadout-fixture")
 game.start_match("hard")
 game.model.claim_room(1)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 game.focus_camera(true)
 # Prepared hunter position/time triggers actual strike, proximity and growth.
 game.model.time=game.model.preparation+Catalog.HUNTER.growth_seconds+4
 game.model.hunter.state=HunterState.State.ATTACK
 game.model.hunter.target=1
 game.model.hunter.position=game.model.player().door_position()+Vector2(0,22)
 game.model.player().door_level=4
 game.model.player().door_hp=game.model.player().max_hp()
 for i in range(90): await process_frame
 await capture("05-threat-warning-fixture")
 game.model.player().occupied_seconds=60
 game.model.player().damage_dealt=600
 game.model.hunter.hurt(game.model.hunter.hp)
 await create_timer(0.1).timeout
 await create_timer(1.2).timeout
 await capture("06-promotion-summary-fixture")
 game.return_menu()
 game.ui.progression.show_ranks()
 await capture("07-unlocked-gold-fixture")
 await create_timer(1.0).timeout
 record.set_recording_active(false)
 var mixed=record.get_recording()
 if mixed!=null:
  var err=mixed.save_to_wav(ProjectSettings.globalize_path("res://artifacts/phase2-mixed-audio.wav"))
  print("MIX_RECORDING bytes=",mixed.data.size()," save=",err)
 print("PHASE2_AUDIO ",JSON.stringify(game.audio_system.get_diagnostics()))
 game.audio_system.shutdown()
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 quit()
