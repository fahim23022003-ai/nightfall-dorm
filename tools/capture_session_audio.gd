extends SceneTree
var a
var recorder
var timeline=[]
var started=0
func _initialize():call_deferred("run")
func segment(label,seconds,model=null,mode="menu"):
 var until=Time.get_ticks_usec()+int(seconds*1e6);var last=Time.get_ticks_usec()
 while Time.get_ticks_usec()<until:
  await process_frame;var now=Time.get_ticks_usec();a.update_state(minf(.05,(now-last)/1e6),model,mode);last=now
  var gains={};var sum=0.0
  for key in a.loops:
   if key.begins_with("music"):
    var value=db_to_linear(a.loops[key].volume_db);sum+=value
    if value>.001:gains[key]=value
  timeline.append({"seconds":(now-started)/1e6,"segment":label,"gains":gains,"sum_gain":sum})
func run():
 a=AudioDirector.new();root.add_child(a);a.set_mix({"music":.8,"effects":.7,"ambient":0,"muted":false,"music_mode":"manual","manual_track":"music_lantern"})
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);started=Time.get_ticks_usec()
 await segment("menu shuffle family",4)
 var m=MatchModel.new();m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();a.reset_match(m)
 await segment("manual lantern calm",4,m,"match")
 a.set_mix({"manual_track":"music_siege"});await segment("crossfade into Broken Vespers",4,m,"match")
 m.hunter.transformed=true;m.hunter.hp=100;await segment("Reaper overrides manual",4,m,"match")
 m.wrath.domain_room=0;m.wrath.domain_remaining=30;await segment("Crimson priority",4,m,"match")
 a.set_suspended(true);await segment("suspended",1,m,"match");a.set_suspended(false)
 m.result="victory";await segment("settle after victory",4,m,"result")
 recorder.set_recording_active(false);var wav=recorder.get_recording();var code=wav.save_to_wav("res://docs/evidence/every-night/audio/engine-crossfade-master.wav")
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 var f=FileAccess.open("res://docs/evidence/every-night/audio/crossfade-timeline.json",FileAccess.WRITE);f.store_string(JSON.stringify({"frames":timeline,"wav_save":code,"conditions":"Real Godot AudioEffectRecord Master PCM, Dummy driver with mixing active, 25s wall time, original streams; no human audition."}))
 print("ENGINE_AUDIO_CAPTURE frames=",timeline.size()," save=",code);a.shutdown();a.queue_free();await create_timer(.2).timeout;quit(code)
