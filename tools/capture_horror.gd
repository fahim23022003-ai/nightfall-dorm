extends SceneTree
# Prepared fixtures using production hunter tick/events, not natural match proof.
var game
var record: AudioEffectRecord
var output="res://docs/evidence/horror/"
func _initialize(): call_deferred("run")
func advance(seconds: float):
 var start=Time.get_ticks_msec()
 var previous=start
 game.horror.update(0,game.model)
 game.audio_system.update_state(0,game.model,"match")
 while Time.get_ticks_msec()-start<seconds*1000:
  await process_frame
  var now=Time.get_ticks_msec()
  var delta=(now-previous)/1000.0
  previous=now
  game.horror.update(delta,game.model)
  game.audio_system.update_state(delta,game.model,"match")
  game.presentation.update(delta,game.model)
  game.queue_redraw()
  if is_instance_valid(game.ui.horror_layer): game.ui.horror_layer.queue_redraw()
func capture(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var result=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("HORROR_CAPTURE ",name," size=",image.get_size()," code=",result)
 if result!=OK: quit(1)
func fixture():
 game.start_match()
 game.set_process(false)
 game.model.claim_room(1)
 var player=game.model.player()
 game.model.player_position=player.bed_position()
 game.model.sleep_player()
 player.gold=1000
 player.electricity=1000
 game.selected_tile=0
 game.ui.open_context()
 game.ui.update_match()
 game.focus_camera(true)
 game.model.time=game.model.preparation+1
 var teammate=game.model.rooms[4]
 teammate.owner=2
 teammate.sleeping=true
 teammate.closed=true
 teammate.door_hp=55
 game.model.hunter.state=HunterState.State.MOVE
 game.model.hunter.target=4
 game.model.hunter.position=teammate.door_position()+Vector2(0,-22)
 game.model.record_event("approach",4)
 game.model.hunter.tick(0.01,game.model)
 game.model.hunter.tick(0.01,game.model)
 return teammate
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://horror-render-fixture.json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.size=Vector2i(1280,720)
 await process_frame
 record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 var teammate=fixture()
 await advance(0.28)
 await capture("01-remote-alert-build-inspector")
 # Focus room 5 only for prepared inspection of damage and low-HP cracks.
 game.full_map=true
 game.focus_camera(true)
 await advance(0.05)
 await capture("02-map-danger")
 game.full_map=false
 var player=game.model.player()
 player.door_hp=55
 game.model.hunter.state=HunterState.State.MOVE
 game.model.hunter.target=1
 game.model.hunter.position=player.door_position()+Vector2(0,22)
 game.model.hunter.cooldown=0
 game.model.hunter.tick(0.01,game.model)
 game.model.hunter.tick(0.01,game.model)
 game.focus_camera(true)
 game.ui.update_match()
 await advance(0.14)
 await capture("03-player-impact-cracks")
 game.model.hunter.cooldown=0
 game.model.hunter.tick(0.01,game.model)
 game.model.hunter.cooldown=0
 game.model.hunter.tick(0.01,game.model)
 game.ui.update_match()
 await advance(0.25)
 await capture("04-door-destruction")
 root.size=Vector2i(960,600)
 await process_frame
 fixture()
 await advance(0.28)
 await capture("05-remote-alert-960x540")
 await advance(1.2)
 record.set_recording_active(false)
 var mixed=record.get_recording()
 if mixed==null or mixed.data.is_empty():
  push_error("No engine audio mix captured")
  quit(1)
 var result=mixed.save_to_wav(ProjectSettings.globalize_path(output+"engine-mix.wav"))
 print("HORROR_MIX_BYTES=",mixed.data.size()," SAVE=",result)
 print("HORROR_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 game.audio_system.shutdown()
 await create_timer(0.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if result==OK else 1)
