extends SceneTree
# Sound asset/dispatch/pool tests. Actual gameplay capture is a separate D gate.
var checks=0
var failures=0
var audio
var results={}
func check(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error("WRATH AUDIO: "+message)
func read_json(path: String):return JSON.parse_string(FileAccess.get_file_as_string(path))
func _initialize():call_deferred("run")
func run():
 var protected=read_json("res://assets/audio/wrath-protected-score-hashes.json")
 check(protected.size()==7,"seven prior score hashes protected")
 for name in protected:check(FileAccess.get_sha256("res://assets/audio/"+name+".wav")==protected[name],"unchanged existing score "+name)
 var sources=read_json("res://tools/audio/source/wrath_sfx/SOURCES.json")
 for row in sources:
  check(row.license_identifier=="CC0-1.0" and row.license.contains("CC0"),"explicit declared CC0 "+row.id)
  check(FileAccess.get_sha256("res://tools/audio/source/wrath_sfx/"+row.file)==row.sha256,"source bytes match pinned manifest "+row.id)
  check(str(row.download_url).contains(row.mirror_commit),"immutable mirror commit "+row.id)
 var derivatives=read_json("res://assets/audio/wrath-sfx-derivatives.json")
 check(derivatives.size()==122,"complete declared cue recipes")
 for row in derivatives:
  check(FileAccess.get_sha256("res://assets/audio/"+row.event+".wav")==row.sha256,"rendered cue bytes "+row.event)
  check(row.layers.size()>0 and row.seconds>.02 and row.seconds<5,"finite sourced recipe "+row.event)
  check(row.rms>.0005 and row.peak<=.59,"nonempty controlled source headroom "+row.event)
 audio=AudioDirector.new();root.add_child(audio);audio.setup()
 check(audio.missing_assets.is_empty(),"all registered audio decodes")
 check(audio.streams.size()==AudioDirector.LOOP_NAMES.size()+AudioDirector.EFFECT_NAMES.size(),"all stream identifiers unique")
 check(audio.voices.size()==16 and audio.loops.size()==12,"fixed pool plus eight scores/four ambience streams")
 check(audio.music_start_count==8,"eight music players created once")
 check(is_equal_approx(audio.streams.music_crimson.get_length(),48.0),"dedicated48-second score")
 var children=audio.get_child_count()
 for group in audio.sfx_preview_groups().values():
  check(group.size()==6,"compact six-cue listening group")
  for name in group:check(name in AudioDirector.EFFECT_NAMES,"preview uses a real cue "+name)
 for row in derivatives:
  audio.stop_events(AudioDirector.EFFECT_NAMES);audio.update_state(.7,null,"unit")
  check(audio.event(row.event),"actual stream-player start "+row.event)
  check(audio.voices.any(func(v):return v.playing and v.stream==audio.streams[row.event]),"valid active source player "+row.event)
 check(audio.get_child_count()==children,"no per-cue player accumulation")
 for entry in [["turret","precision"],["turret","suppression"],["heavy","focus"],["heavy","storm"],["flame","searing"],["flame","wildfire"],["frost","deep_chill"],["frost","rime_field"],["shock","capacitor_burst"],["shock","rapid_discharge"]]:
  var low=audio.WrathAudio.shot_event(entry[0],5,entry[1]);var high=audio.WrathAudio.shot_event(entry[0],10,entry[1])
  check(low!=high and low in audio.streams and high in audio.streams,"branch/high-tier samples "+str(entry))
  check(audio.streams[low].data!=audio.streams[high].data,"branch/high tier is actual different audio "+str(entry))
 audio.stop_events(AudioDirector.EFFECT_NAMES);audio._frame_voices=AudioDirector.FRAME_VOICE_LIMIT
 var before=int(audio.event_counts.get("wrath_warning_soul_reaper",0));audio.event("wrath_warning_soul_reaper",Vector2.INF,{"expires_in":.05})
 check(audio._pending_critical.size()==1,"saturated telegraph is queued")
 audio.update_state(.2,null,"unit")
 check(audio._pending_critical.is_empty() and int(audio.event_counts.get("wrath_warning_soul_reaper",0))==before and audio.expired_events>0,"expired telegraph cannot play late")
 audio._frame_voices=AudioDirector.FRAME_VOICE_LIMIT
 for name in AudioDirector.CRITICAL_EVENTS:audio.event(name)
 check(audio._pending_critical.size()<=24,"critical queue bounded")
 audio.stop_events(AudioDirector.EFFECT_NAMES)
 check(audio._pending_critical.is_empty(),"owned stop clears queued effects")
 for volume in [.65,1.0]:results[str(volume)]=await capture_unit(volume)
 results.reactions=await reaction_queue_unit()
 audio.set_mix({"music":0,"effects":0,"ambient":0,"muted":false})
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"saved zero Effects remains authoritative")
 audio.set_mix({"effects":1,"music":1,"ambient":1,"muted":true})
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"saved mute authoritative")
 results.note="Actual AudioDirector cue-unit playback, not a full gameplay/10-minion stress claim. Human audition unverified."
 results.checks=checks;results.failures=failures;results.streams=audio.streams.size();results.children=children
 var file=FileAccess.open("res://docs/evidence/phase5d4/audio-unit-metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(results," "));file.close()
 audio.shutdown();await create_timer(.6).timeout;audio.queue_free();await create_timer(.2).timeout
 print("WRATH_AUDIO_UNIT_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
func capture_unit(volume: float) -> Dictionary:
 audio.stop_events(AudioDirector.EFFECT_NAMES);audio.set_mix({"music":0.0,"effects":volume,"ambient":0.0,"muted":false})
 var recorder=AudioEffectRecord.new();var slot=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
 for name in ["shot_needle","shot_arc","shot_flame","shot_frost","shot_shock","build","branch_select","repair","hunter_evolve","wrath_warning_summon","wrath_activate_scythe_slash","item_explosion"]:
  audio.update_state(.28,null,"unit");audio.event(name);await create_timer(.28).timeout
 await create_timer(1.3).timeout;recorder.set_recording_active(false)
 var recording=recorder.get_recording();var path="res://docs/evidence/phase5d4/audio-unit-"+str(volume)+".wav"
 check(recording.save_to_wav(ProjectSettings.globalize_path(path))==OK,"actual unit recording saved")
 var data=recording.data;var peak=0.0;var squares=0.0;var fullscale=0
 for i in range(0,data.size(),2):
  var sample=absf(float(data.decode_s16(i))/32768.0);peak=maxf(peak,sample);squares+=sample*sample
  if sample>=.999:fullscale+=1
 var rms=sqrt(squares/maxi(1,data.size()/2))
 check(peak>.02 and rms>.002,"meaningful engine signal at Effects "+str(volume))
 check(fullscale==0,"unit mix has headroom at Effects "+str(volume))
 AudioServer.remove_bus_effect(0,slot)
 return {"effects":volume,"music":0,"seconds":recording.get_length(),"peak":peak,"rms":rms,"fullscale_samples":fullscale,"fixture":"direct event unit playback; not gameplay"}

func reaction_queue_unit() -> Dictionary:
 audio.stop_events(AudioDirector.EFFECT_NAMES);audio.set_mix({"music":0.0,"effects":.65,"ambient":0.0,"muted":false})
 var context={"player_room":0};var before=audio.evolution_cues_played
 for room in [0,1]:
  audio.pending_deaths.append({"name":"death_scream_"+str(room+1),"position":Vector2.INF,"room":room})
  audio._wrath_presentation("hunter_evolved",{"room":room,"buff_id":"blood_frenzy" if room==0 else "iron_skin"},context,Vector2.INF)
 audio._wrath_presentation("hunter_evolved",{"room":0,"buff_id":"blood_frenzy"},context,Vector2.INF)
 check(audio.pending_evolutions.size()==2,"one durable queued reaction per unique victim, duplicate ignored")
 var recorder=AudioEffectRecord.new();var slot=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
 var sequence=[];var seen_deaths=0;var seen_evolutions=0;var overlap=false;var started=audio._clock
 var first_count=int(audio.event_counts.get("death_scream_1",0));var second_count=int(audio.event_counts.get("death_scream_2",0))
 while audio._clock-started<17:
  audio.update_state(.05,null,"unit");audio._play_death_queue()
  var death_count=int(audio.event_counts.get("death_scream_1",0))-first_count+int(audio.event_counts.get("death_scream_2",0))-second_count
  var evolved=audio.evolution_cues_played-before
  if death_count>seen_deaths:sequence.append({"type":"death","time":audio._clock-started});seen_deaths=death_count
  if evolved>seen_evolutions:sequence.append({"type":"evolution","time":audio._clock-started});seen_evolutions=evolved
  var death_playing=audio.voices.any(func(v):return v.playing and str(audio._voice_names.get(v.get_instance_id(),"")).begins_with("death_scream"))
  var evolve_playing=audio.voices.any(func(v):return v.playing and (audio._voice_names.get(v.get_instance_id(),"")=="hunter_evolve" or str(audio._voice_names.get(v.get_instance_id(),"")).begins_with("buff_")))
  if death_playing and evolve_playing:overlap=true
  if audio.pending_deaths.is_empty() and audio.pending_evolutions.is_empty() and not death_playing and not evolve_playing and audio._clock>=audio._evolution_busy_until:break
  await create_timer(.05).timeout
 recorder.set_recording_active(false);var recording=recorder.get_recording()
 check(recording.save_to_wav(ProjectSettings.globalize_path("res://docs/evidence/phase5d4/audio-unit-reactions.wav"))==OK,"actual temporal reaction unit PCM saved")
 AudioServer.remove_bus_effect(0,slot)
 check(seen_deaths==2 and seen_evolutions==2,"both actual death clips and both evolution pairs play despite long vocals")
 check(not overlap,"actual playing death and evolution voices never overlap")
 check(sequence.map(func(e):return e.type)==["death","evolution","death","evolution"],"death→evolution→death→evolution order")
 check(audio.pending_deaths.is_empty() and audio.pending_evolutions.is_empty(),"bounded reaction queues drain")
 audio.pending_evolutions.append({"room":2,"category":"armor","position":Vector2.INF});audio.update_state(.1,null,"menu")
 check(audio.pending_evolutions.is_empty(),"menu exit cancels owned pending reactions")
 return {"fixture":"two synthetic routing records with actual recorded voice players, not gameplay kill proof","sequence":sequence,"sequence_time_basis":"unit-fed AudioDirector delta, not wall-clock; raw PCM duration is measured","overlap":overlap,"played_deaths":seen_deaths,"played_evolutions":seen_evolutions,"seconds":recording.get_length()}
