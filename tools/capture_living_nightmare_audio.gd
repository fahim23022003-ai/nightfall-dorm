extends SceneTree
## Stages the same production audio states and captures the live Master bus.

var director: AudioDirector
var model: MatchModel
var recorder: AudioEffectRecord
var timeline: Array[Dictionary] = []
var started := 0
var directory := ""

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute output folder after --.")
  quit(2)
  return
 directory=args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 director=AudioDirector.new()
 director.soundtrack.rng.seed=3027
 root.add_child(director)
 director.set_mix({"music":.8,"effects":.7,"ambient":.25,"muted":false,"music_mode":"shuffle"})
 model=MatchModel.new()
 model.configure_match("hell")
 model.claim_room(0)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 recorder=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,recorder)
 recorder.set_recording_active(true)
 started=Time.get_ticks_usec()
 await segment("Menu",4.0,"menu")
 model.time=8.0
 director.reset_match(model)
 await segment("Preparation",4.0)
 model.time=model.preparation+2.0
 model.hunter.state=HunterState.State.MOVE
 model.hunter.target=0
 model.hunter.position=model.player().door_approach()+Vector2(115.0,0.0)
 await segment("Approach",4.5)
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.position=model.player().door_approach()
 model.record_event("encounter",0)
 await segment("First direct door siege",6.0)
 model.player().door_hp=model.player().max_hp()*.26
 model.record_event("door_damage",0,{"hp":model.player().door_hp,"max_hp":model.player().max_hp(),"damage":model.player().max_hp()*.74})
 await segment("Desperate defense",5.0)
 model.hunter.state=HunterState.State.RECOVER
 model.record_event("hunter_recovering",-1,{"hall":"north","position":model.hunter.position})
 await segment("Haunted Hall",5.0)
 model.hunter.transformed=true
 model.hunter.state=HunterState.State.TRANSFORM
 model.hunter.hp=100
 model.record_event("boss_transform",0)
 await segment("Reaper transformation",5.0)
 model.wrath.domain_room=0
 model.wrath.domain_remaining=20
 await segment("Crimson",5.0)
 model.result="victory"
 await segment("Victory",5.0,"result")
 model.result="defeat"
 await segment("Defeat",4.0,"result")
 recorder.set_recording_active(false)
 var wav:=recorder.get_recording()
 var status:=wav.save_to_wav(directory.path_join("master.wav"))
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 var receipt:=FileAccess.open(directory.path_join("timeline.json"),FileAccess.WRITE)
 receipt.store_string(JSON.stringify({"driver":AudioServer.get_driver_name(),"sample_count":wav.data.size(),"save_status":status,"staged_states":true,"timeline":timeline},"  "))
 receipt.close()
 print("LIVING_AUDIO_CAPTURE saved=",status," pcm=",wav.data.size())
 director.shutdown()
 director.queue_free()
 director=null
 model=null
 recorder=null
 await create_timer(.5).timeout
 quit(int(status!=OK))

func segment(label: String, duration: float, mode: String="match") -> void:
 var segment_start:=Time.get_ticks_usec()
 var previous:=segment_start
 var next_sample:=segment_start
 while (previous-segment_start)/1e6<duration:
  await process_frame
  var now:=Time.get_ticks_usec()
  director.update_state((now-previous)/1e6,model,mode)
  if now>=next_sample:
   var diagnostics:=director.get_diagnostics()
   var weights: Dictionary={}
   for key in diagnostics.loop_weights:
    if key.begins_with("music") and diagnostics.loop_weights[key]>.001:
     weights[key]=diagnostics.loop_weights[key]
   timeline.append({"time":(now-started)/1e6,"scene":label,"music":weights,"duck":diagnostics.music_duck,"heartbeat":diagnostics.event_counts.get("siege_heartbeat",0),"active_players":director.loops.values().filter(func(player):return player.playing).size()})
   next_sample=now+250000
  previous=now
