extends SceneTree
var checks=0
var failures=0
func check(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error("SAMPLED EXPLOSION: "+message)
func key(code: int,pressed: bool):
 var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=60
 var path="user://phase5d4-sampled-explosion-test.json";var profile=PlayerProfile.new(path);profile.tutorial_completed=true;check(profile.save_profile(),"isolated completed-tutorial profile saved")
 var before=FileAccess.get_file_as_bytes(path);OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 if game.mode=="intro":key(KEY_SPACE,true);await process_frame;key(KEY_SPACE,false);await process_frame
 check(game.start_practice("crusher",false,["trap","repair"]),"real Practice session starts with temporary trap")
 game.audio_system.set_mix({"music":0.0,"effects":.65,"ambient":0.0,"muted":false});await process_frame
 var recorder=AudioEffectRecord.new();var slot=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
 key(KEY_1,true);await process_frame;key(KEY_1,false);await process_frame
 check(int(game.item_wallet().inventory.get("trap",0))==4 and not game.model.items.trap.is_empty(),"actual key input spends one temporary trap and deploys it")
 var hp=game.model.hunter.hp;var time=Time.get_ticks_msec()
 while int(game.audio_system.event_counts.get("item_explosion",0))==0 and Time.get_ticks_msec()-time<25000:await create_timer(.05).timeout
 check(int(game.audio_system.event_counts.get("item_explosion",0))==1,"real Hunter movement triggers trap→ItemInterface→sampled explosion exactly once")
 check(game.model.items.trap.is_empty() and game.model.hunter.hp<hp,"actual consumable is removed and real Hunter HP decreases")
 await create_timer(1.4).timeout
 check(int(game.audio_system.event_counts.get("item_explosion",0))==1,"subsequent frames cannot duplicate explosion")
 recorder.set_recording_active(false);var recording=recorder.get_recording();check(recording.save_to_wav(ProjectSettings.globalize_path("res://docs/evidence/phase5d4/audio-explosion-real-practice.wav"))==OK,"actual internal Master practice recording saved")
 AudioServer.remove_bus_effect(0,slot)
 var data=recording.data;var peak=0.0;var squares=0.0;var fullscale=0
 for i in range(0,data.size(),2):
  var sample=absf(float(data.decode_s16(i))/32768.0);peak=maxf(peak,sample);squares+=sample*sample
  if sample>=.999:fullscale+=1
 check(peak>.02 and squares/maxi(1,data.size()/2)>.000001 and fullscale==0,"actual practice output meaningful with no full-scale samples")
 check(FileAccess.get_file_as_bytes(path)==before,"real practice input/combat cannot change permanent profile bytes")
 var results={"fixture":"real configured Practice, actual key input and Hunter navigation; standard temporary budget, no injected Hunter position/HP","explosion_events":game.audio_system.event_counts.get("item_explosion",0),"hp_before":hp,"hp_after":game.model.hunter.hp,"seconds":recording.get_length(),"peak":peak,"rms":sqrt(squares/maxi(1,data.size()/2)),"fullscale_samples":fullscale,"music":0,"effects":.65,"checks":checks,"failures":failures}
 var file=FileAccess.open("res://docs/evidence/phase5d4/audio-explosion-real-practice.json",FileAccess.WRITE);file.store_string(JSON.stringify(results," "));file.close()
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("SAMPLED_EXPLOSION_GAME_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
