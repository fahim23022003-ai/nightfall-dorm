extends SceneTree
# Camera-aware positional source placement and real existing mixer/bus state.
var checks=0
var failures=0
var audio
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL AUDIO: "+label)
func voice_for(name):
 for voice in audio.voices:
  if audio._voice_names.get(voice.get_instance_id(),"")==name and voice.playing:return voice
 return null
func fresh():
 audio._frame_voices=0;audio._cooldowns.clear();audio._pending_critical.clear()
 for voice in audio.voices:voice.stop()
func run():
 root.size=Vector2i(1280,720)
 var holder=Node2D.new();root.add_child(holder)
 var camera=Camera2D.new();holder.add_child(camera);camera.make_current()
 audio=load("res://scripts/audio_director.gd").new();holder.add_child(audio)
 await process_frame
 for center in [Vector2(640,360),Vector2(2400,1800),Vector2(-450,900)]:
  for zoom in [.5,1.0,1.5]:
   camera.position=center;camera.zoom=Vector2.ONE*zoom;camera.force_update_scroll();await process_frame
   audio.listener_position=center-Vector2(145,40)
   for side in [-1,1]:
    fresh()
    check(audio.event("footstep",audio.listener_position+Vector2(side*300,0)),"valid positional cue plays")
    var voice=voice_for("footstep")
    check(voice!=null,"real effect voice starts")
    if voice==null:continue
    var on_screen=root.get_canvas_transform()*voice.global_position
    var screen_center=root.get_visible_rect().get_center()
    check((on_screen.x-screen_center.x)*side>50,"source pans on truthful side at any map/focus/zoom")
    check(absf(on_screen.y-screen_center.y)<1,"centered-y source stays centered in listener view")
    check(voice.panning_strength>.35,"footstep direction has enhanced positional strength")
 fresh();audio.listener_position=Vector2.ZERO
 check(not audio.event("footstep",Vector2(5000,0)),"ordinary far sound is distance culled")
 check(audio.event("death_scream_1",Vector2(5000,0)),"distant true death cue retains prominence")
 var death=voice_for("death_scream_1")
 check(death!=null and is_finite(death.volume_db) and death.volume_db<-10,"distant death remains bounded rather than painfully loud")
 var m=MatchModel.new();m.configure_match("hell");m.configure_stage("stage_1");m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.player().door_hp=m.player().max_hp()*.2
 m.time=m.preparation+1;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach()
 audio.reset_match(m);audio.update_state(.1,m,"match");fresh()
 var rng=m.random.state;var hp=m.hunter.hp;var damage=m.hunter.damage
 for i in range(10):
  audio.set_tension("danger",1);audio.update_state(.1,m,"match")
 check(audio.pacing_gain<.8 and audio.ambience_gain<.8,"true danger lowers competing music and ambience")
 var before_pacing=audio.pacing_gain;var before_ambient=audio.ambience_gain
 audio.set_tension("relief",0);audio.update_state(.1,m,"match")
 check(audio.pacing_gain>before_pacing and audio.pacing_gain<1,"music returns gradually during relief")
 check(audio.ambience_gain>before_ambient and audio.ambience_gain<1,"ambience returns gradually during relief")
 check(m.random.state==rng and m.hunter.hp==hp and m.hunter.damage==damage,"audio pacing cannot mutate difficulty/combat/RNG")
 var world=load("res://scripts/haunted_environment.gd").new();world.configure(m)
 fresh();audio.set_tension("danger",1)
 world.emit_weather("weather_thunder",Vector2.ZERO)
 var thunder_count=int(audio.event_counts.get("weather_thunder",0));audio.update_environment(world)
 check(int(audio.event_counts.get("weather_thunder",0))==thunder_count,"immediate danger suppresses competing thunder")
 fresh();audio.set_tension("quiet",0)
 world.emit_weather("weather_thunder",Vector2.ZERO);audio.update_environment(world)
 var thunder=voice_for("weather_thunder")
 check(thunder!=null and thunder.bus=="Ambient","environment uses saved independent ambience bus")
 audio.set_mix({"effects":1.0,"music":1.0,"ambient":0.0,"muted":false})
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"ambience mute preserves important combat effects")
 audio.set_mix({"effects":0.0,"music":.5,"ambient":1.0,"muted":false})
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"SFX preference mutes effect bus")
 audio.reset_match(m)
 check(audio.tension_state=="quiet" and audio.pacing_gain==1 and audio.ambience_gain==1,"match reset cannot inherit stale danger or attenuation")
 check(audio.music_start_count==14,"pacing does not duplicate existing music players")
 audio.shutdown()
 var until=Time.get_ticks_msec()+550
 while Time.get_ticks_msec()<until:await process_frame
 holder.queue_free();await process_frame
 print("VISUAL_AUDIO_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
