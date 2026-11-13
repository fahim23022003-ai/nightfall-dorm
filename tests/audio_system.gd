extends SceneTree
var assertions = 0
var failures = 0
var audio: AudioDirector
var model: MatchModel

func check(condition: bool, message: String):
 assertions += 1
 if not condition:
  failures += 1
  push_error("AUDIO FAIL: "+message)

func count(name: String) -> int:
 return int(audio.event_counts.get(name,0))

func idle_voices():
 for voice in audio.voices:
  voice.stop()
 audio._frame_voices = 0

func observe(delta: float = 0.3):
 idle_voices()
 audio.update_state(delta,model,"match")

func _initialize():
 call_deferred("run")

func run():
 audio = AudioDirector.new()
 root.add_child(audio)
 var bus_count = AudioServer.bus_count
 audio.setup()
 check(AudioServer.bus_count==bus_count,"setup is idempotent and does not duplicate buses")
 for name in ["Music","Effects","Ambient"]:
  check(AudioServer.get_bus_index(name)>=0,"dedicated bus exists: "+name)
 check(audio.missing_assets.is_empty() and audio.streams.size()==AudioDirector.LOOP_NAMES.size()+AudioDirector.EFFECT_NAMES.size(),"all declared original audio assets decode")
 for name in audio.streams:
  var stream = audio.streams[name]
  check(stream.get_length()>0.04 and stream.data.size()>100,"nonempty playable asset: "+name)
  var peak = 0
  var pcm=stream.data # Cache PCM once; avoid repeated property reads for large sampled scores.
  if stream.format!=AudioStreamWAV.FORMAT_16_BITS:
   var source=AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(AudioDirector.ROOT+name+".wav"))
   check(source!=null and source.format==AudioStreamWAV.FORMAT_16_BITS,"compressed import retains a real PCM16 source: "+name)
   pcm=source.data if source!=null else PackedByteArray()
  for i in range(0,pcm.size(),2):
   peak = maxi(peak,absi(pcm.decode_s16(i)))
  check(peak>100 and peak<=24575,"non-silent bounded waveform: "+name)
 for name in AudioDirector.LOOP_NAMES:
  check(audio.streams[name].loop_mode==AudioStreamWAV.LOOP_DISABLED if name=="music_intro" else audio.streams[name].loop_mode==AudioStreamWAV.LOOP_FORWARD and audio.streams[name].loop_end>0,"cinematic one-shot or configured score loop: "+name)
  check(name=="music_intro" or audio.loops[name].playing,"permanent score/ambience player is running: "+name)
  var data = audio.streams[name].data
  check(absi(data.decode_s16(0)-data.decode_s16(data.size()-2))<655,"loop boundary has no large PCM discontinuity: "+name)
 check(audio.music_start_count==8,"eight musical scores, including the seven preserved scores and Crimson, initialized once")
 for i in range(30):
  audio.update_state(0.1,null,"menu")
 check(audio.loop_weights.music_menu>0.9 and audio.music_start_count==8,"menu music fades in without restart")
 audio.set_mix({"music":0.2,"effects":0.4,"ambient":0.6,"muted":true})
 for name in ["Music","Effects","Ambient"]:
  check(AudioServer.is_bus_mute(AudioServer.get_bus_index(name)),"mute affects "+name)
 check(is_equal_approx(audio.mix.music,0.2) and is_equal_approx(audio.mix.effects,0.4),"separate volume preferences retained")
 audio.set_mix({"music":2.0,"effects":-2.0,"ambient":0.6,"muted":false})
 check(audio.mix.music==1 and audio.mix.effects==0,"volume values clamp safely")
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"zero effects volume silences effects")
 audio.set_mix({"effects":0.75})
 model = MatchModel.new()
 model.claim_room(1)
 model.player_position = model.player().bed_position()
 model.sleep_player()
 audio.reset_match(model)
 observe(1)
 check(count("match_start")==1,"match transition has start cue")
 check(audio.loop_weights.music_calm>0.5 and audio.loop_weights.music_menu<0.1,"calm gameplay crossfades from menu")
 model.hunter.state = HunterState.State.ATTACK
 model.hunter.target = 1
 model.hunter.position = model.player().door_position()+Vector2(0,22)
 model.player().door_hp = model.player().max_hp()*0.2
 observe(1)
 check(audio.intensity>0.8 and audio.proximity>0.8,"real nearby hunter and damaged door raise intensity")
 check(count("door_hit")>0 and count("door_crack")>0 and count("hunter_spawn")>0,"damage threshold and spawn trigger cues")
 check(audio.loop_weights.music_danger>0.5 and audio.loop_weights.proximity_loop>0.3,"danger and proximity loops become audible")
 model.hunter.position = Vector2(1500,410)
 observe(2)
 check(audio.proximity<0.1 and audio.intensity<0.1,"danger fades when hunter moves away")
 model.player().gold = 100000
 model.player().electricity = 1000
 model.upgrade_bed()
 observe()
 check(count("bed_upgrade")==1,"real bed upgrade has its own cue")
 model.upgrade_door()
 observe()
 check(count("door_upgrade")==1,"real door upgrade has its own cue")
 model.player().door_hp -= 20
 observe()
 model.repair_door()
 observe(1.1)
 check(count("repair")>0,"actual repair has repair cue")
 model.buy("generator",0)
 observe()
 check(count("build")>0 and audio.loop_weights.generator_loop>0,"real generator placement starts persistent operating hum")
 model.player().income_total += 10
 model.player().electricity += 10
 observe(1.2)
 check(count("income")>0 and count("electricity")>0,"gold and electricity have distinct feedback")
 model.hunter.level += 1
 observe()
 check(count("hunter_level")==1,"hunter growth emits warning")
 model.combat_events.append({"id":1,"type":"launch","kind":"turret","position":model.player().center(),"damage":0})
 observe()
 model.combat_events.append({"id":2,"type":"impact","kind":"turret","position":model.player().center(),"damage":9})
 observe()
 var impacts = count("impact")
 observe()
 check(count("shot_needle")==1 and impacts==1 and count("impact")==impacts and count("ghost_hurt")==1,"combat events correlate one launch/impact/hurt without frame repeats")
 model.player().door_hp = 0
 observe(1.2)
 check(count("door_break")==1 and count("breach")==1,"door destruction and sudden breach have distinct cues")
 model.hunter.state = HunterState.State.DEAD
 model.result = "victory"
 idle_voices()
 audio.update_state(1,model,"result")
 check(count("victory")==1 and audio.intensity<0.1,"victory cue and danger fade on ghost death")
 audio.update_state(1,model,"result")
 check(count("victory")==1,"terminal sound does not restart each frame")
 check(count("ghost_defeat")==1,"ghost defeat uses its own cue separate from victory")
 for name in ["button","purchase","failure","rank","reward","defeat","shot_arc","turret_upgrade","danger"]:
  idle_voices()
  audio._cooldowns.clear()
  check(audio.event(name),"explicit functional cue: "+name)
 idle_voices()
 audio._cooldowns.clear()
 var accepted = 0
 for i in range(100):
  if audio.event("button"):
   accepted += 1
 check(accepted==1 and audio.get_diagnostics().voices<=AudioDirector.VOICE_LIMIT,"per-category cooldown and global pool bound sound spam")
 idle_voices()
 audio._cooldowns.clear()
 for name in ["button","purchase","failure","rank","reward","defeat","shot_arc","danger"]:
  audio.event(name)
 check(audio._frame_voices==AudioDirector.FRAME_VOICE_LIMIT,"per-frame voice budget prevents bursts")
 check(not audio.event("hunter_level"),"critical cue defers when frame budget is full")
 check(audio.get_diagnostics().pending_critical>0,"critical cue is queued rather than lost")
 idle_voices()
 audio.update_state(0.6,model,"result")
 check(audio.get_diagnostics().pending_critical==0 and count("hunter_level")>=2,"deferred critical cue plays next update")
 var button_stream = audio.streams.button
 audio.streams.erase("button")
 idle_voices()
 check(not audio.event("button"),"unavailable decoded asset rejects playback safely without crash")
 audio.streams.button = button_stream
 check(audio.streams.button.data != audio.streams.failure.data and audio.streams.bed_upgrade.data != audio.streams.door_upgrade.data,"important categories use distinct original waveforms")
 var starts = audio.music_start_count
 model.reset(5)
 audio.reset_match(model)
 check(audio.music_start_count==starts and audio._last_combat_event==0 and audio.get_diagnostics().voices==0,"restart resets observations and effects without restarting music")
 print("AUDIO_ASSERTIONS=",assertions," FAILURES=",failures," STREAMS=",audio.streams.size()," MUSIC_STARTS=",audio.music_start_count)
 audio.shutdown()
 await create_timer(0.5).timeout
 audio.queue_free()
 await create_timer(0.1).timeout
 quit(1 if failures else 0)
