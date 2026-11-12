extends SceneTree
var checks=0
var failures=0
func check(value,label):
 checks+=1
 if not value:failures+=1;push_error("BASIC WARNING AUDIO "+label)
func _initialize():call_deferred("run")
func run():
 preload("res://tests/onboarding_test_support.gd").prepare()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.skip();await process_frame
 var audio=game.audio_system
 var selected_mix={"music":.2,"effects":.42,"ambient":.1,"muted":false}
 for id in StrategyCatalog.ARCHETYPE_IDS:
  game.start_practice(id,false,["shield","repair"],"abandoned_dorm");await process_frame
  var m=game.model;var h=m.hunter;var r=m.player()
  h.target=r.index;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.boss_policy.enabled=false;h.cooldown=0;h.arcane.cooldown=6;m.time=m.preparation+.1
  audio.stop_events(AudioDirector.EFFECT_NAMES);audio.update_state(.8,null,"unit");audio.set_mix(selected_mix);audio.reset_match(m)
  var identity={"witch":"stalker","electric":"ravager","storm":"crusher"}.get(id,id);var cue="hunter_"+identity+"_warning";var prior=int(audio.event_counts.get(cue,0));var hp=r.door_hp
  h.tick(.01,m);audio.update_state(.01,m,"match")
  check(r.door_hp==hp and h.archetype_primed,"real harmless first warning "+id)
  check(int(audio.event_counts.get(cue,0))==prior+1,"actual recorded warning route "+id)
  check(audio.voices.any(func(v):return v.playing and audio._voice_names.get(v.get_instance_id(),"")==cue),"actual stream started "+id)
  check(audio.streams[cue].get_length()>0 and not audio.streams[cue].data.is_empty(),"nonempty recorded stream "+id)
  check(is_equal_approx(float(audio.mix.effects),.42),"SFX setting retained "+id)
  audio.update_state(.01,m,"menu")
  check(not audio.voices.any(func(v):return v.playing and audio._voice_names.get(v.get_instance_id(),"")==cue),"menu stops battle warning "+id)
 audio.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 print("OVERHAUL_BASIC_WARNING_AUDIO_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
