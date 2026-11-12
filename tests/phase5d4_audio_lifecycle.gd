extends SceneTree
# Dispatch/lifecycle unit fixture. Actual terminal combat is independently captured.
var checks=0
var failures=0
func check(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error("AUDIO LIFECYCLE: "+message)
func _initialize():call_deferred("run")
func playing(audio,name: String) -> bool:return audio.voices.any(func(v):return v.playing and v.stream==audio.streams[name])
func run():
 var audio=AudioDirector.new();root.add_child(audio);audio.setup()
 var model=MatchModel.new();model.reset(17);model.hunter.state=HunterState.State.SEEK
 audio.reset_match(model);audio.update_state(.1,model,"match")
 model.wrath.domain_room=0;model.wrath.domain_remaining=30
 audio.update_state(.1,model,"match")
 check(audio._domain_music_active and audio.crimson_music_starts==1,"active match starts Crimson once")
 audio.update_state(.1,model,"match")
 check(audio.crimson_music_starts==1,"minor match updates do not restart Crimson")
 audio.event("wrath_warning_soul_reaper");await physics_frame
 check(playing(audio,"wrath_warning_soul_reaper"),"real battle warning player is active")
 model.rooms[0].alive=false;model.result="defeat"
 model.record_event("elimination",0,{"survivor_position":model.rooms[0].bed_position()})
 model.record_event("hunter_evolved",0,{"buff_id":"iron_skin","victim_room":0})
 audio.update_state(.1,model,"result");await physics_frame
 check(not playing(audio,"wrath_warning_soul_reaper"),"terminal result cancels obsolete attack warning")
 check(not audio._domain_music_active and audio.crimson_music_starts==1,"terminal result cannot restart retained domain")
 check(audio.death_rooms.has(0) and audio._evolved_rooms.has(0),"terminal presentation ledger consumes final kill and evolution")
 check(playing(audio,"death_scream_1") and audio.pending_evolutions.size()==1,"terminal recorded death remains audible before queued evolution")
 var final_id=audio._last_presentation_event
 audio.update_state(.1,model,"result")
 check(audio._last_presentation_event==final_id and audio.death_sequence==1,"terminal records consume exactly once")
 audio.update_state(.1,model,"menu");await physics_frame
 check(not playing(audio,"death_scream_1") and audio.pending_evolutions.is_empty() and audio.pending_deaths.is_empty(),"explicit menu clears death and evolution context")
 check(not audio._domain_music_active and audio.crimson_music_starts==1,"retained model cannot activate domain in menu")
 audio.preview_effect("wrath_warning_final_judgement");await physics_frame
 check(playing(audio,"wrath_warning_final_judgement"),"Listening Room can preview battle sound")
 audio.update_state(.1,model,"menu");await physics_frame
 check(playing(audio,"wrath_warning_final_judgement"),"menu cleanup does not stop selected Listening Room preview")
 audio.stop_preview();audio.reset_match(model)
 check(audio._pending_critical.is_empty() and audio.pending_evolutions.is_empty() and audio.pending_deaths.is_empty(),"new run has no stale combat queues")
 audio.shutdown();await create_timer(.6).timeout;audio.queue_free();await create_timer(.2).timeout
 print("WRATH_AUDIO_LIFECYCLE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
