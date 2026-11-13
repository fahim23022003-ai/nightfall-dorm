extends SceneTree
var checks=0
var failures=0
func check(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error("WRATH AUDIO TARGET: "+message)
func _initialize():call_deferred("run")
func run():
 var model=MatchModel.new();model.reset(17)
 # Dispatch-only fixture: dormant actors are correctly not attackable.
 model.hunter.state=HunterState.State.SEEK
 check(model.target_by_id(1)==model.hunter and model.next_entity_id>=2,"producer identity is Hunter1; Undead begin2")
 var audio=AudioDirector.new();root.add_child(audio);audio.setup();audio.set_mix({"music":0,"effects":.65,"ambient":0,"muted":false});audio.reset_match(model)
 for entry in [[1,false,"ghost_hurt"],[2,false,"undead_hurt"],[1,true,"reaper_hurt"]]:
  audio.stop_events(AudioDirector.EFFECT_NAMES);audio.update_state(.6,null,"unit");model.hunter.transformed=entry[1]
  var before=int(audio.event_counts.get(entry[2],0));var id=audio._last_combat_event+1
  model.combat_events=[{"id":id,"type":"impact","position":audio.listener_position,"kind":"turret","target_id":entry[0],"damage":5.0}]
  audio._observe(model)
  check(int(audio.event_counts.get(entry[2],0))==before+1,"correct actual stream dispatch for "+str(entry))
 check(audio.streams.bed_upgrade.data!=audio.streams.door_upgrade.data,"bed and door important interaction cues are distinct")
 for name in AudioDirector.LOOP_NAMES+AudioDirector.EFFECT_NAMES:
  var expected=AudioStreamWAV.FORMAT_QOA if name.begins_with("cinematic_") or name.begins_with("nightmare_") else AudioStreamWAV.FORMAT_16_BITS
  check(audio.streams[name].format==expected and audio.streams[name].get_length()>0,"declared original/Phase8 QOA import and nonempty playback "+name)
 audio.shutdown();await create_timer(.6).timeout;audio.queue_free();await create_timer(.2).timeout
 print("WRATH_AUDIO_TARGET_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
