extends SceneTree
# Reproduce a pooled encounter-voice reference reused by a genuine voice stream.
var checks=0
var failures=0
func check(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error("AUDIO REACTION: "+message)
func _initialize():call_deferred("run")
func run():
 var audio
 var args=OS.get_cmdline_user_args()
 if args.size()==1:
  var baseline=GDScript.new();baseline.source_code=FileAccess.get_file_as_string(args[0]).replace("class_name AudioDirector\n","")
  check(baseline.reload()==OK,"frozen baseline source compiles")
  audio=baseline.new()
 else:audio=AudioDirector.new()
 root.add_child(audio);audio.setup();audio.set_mix({"music":0,"effects":.65,"ambient":0,"muted":false})
 check(audio.event("death_scream_1"),"recorded death starts")
 var death_voice=audio.voices.filter(func(v):return v.playing and v.stream==audio.streams.death_scream_1)[0]
 audio._scream_voice=death_voice
 var model={"result":"","player_room":0,"hunter":{"transformed":false},"rooms":[{"door_hp":100},{"door_hp":0}],"presentation_events":[{"id":1,"type":"door_break","room":1,"position":Vector2.ZERO}]}
 audio._observe_presentation(model)
 await physics_frame;await process_frame
 print("POOLED_VOICE_AFTER_BREACH=",audio._voice_names.get(death_voice.get_instance_id(),""))
 check(death_voice.playing and death_voice.stream==audio.streams.death_scream_1,"other-room breach cannot stop/reuse a pooled player now used by a death scream")
 # A first death need not have an existing ordinary encounter-voice reference.
 audio.stop_events(AudioDirector.EFFECT_NAMES);audio._clock+=3;audio._frame_voices=0
 check(audio.event("death_scream_2"),"second recorded death starts")
 audio._scream_voice=null;audio._scream_next=0
 var before=int(audio.event_counts.get("scream_1",0));model.presentation_events=[{"id":2,"type":"encounter","room":0,"position":Vector2.ZERO}]
 audio._observe_presentation(model)
 check(int(audio.event_counts.get("scream_1",0))==before,"ordinary encounter vocal yields to actual playing death scream")
 check(audio.voices.filter(func(v):return v.playing and str(audio._voice_names.get(v.get_instance_id(),"")).begins_with("death_scream")).size()==1,"one recorded death remains audible")
 audio.shutdown();await create_timer(.6).timeout;audio.queue_free();await create_timer(.2).timeout
 print("WRATH_AUDIO_REACTION_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
