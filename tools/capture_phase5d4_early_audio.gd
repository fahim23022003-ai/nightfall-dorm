extends "res://tools/capture_phase5d3_team.gd"
# Actual production model launches/impacts/input, Linux real-time Master PCM.
var recorders={}
var results=[]
var audio_path="res://docs/evidence/phase5d4/early-audio/"
func record_start():
 for bus in ["Master","Effects","Music"]:
  var effect=AudioEffectRecord.new();var index=AudioServer.get_bus_index(bus);AudioServer.add_bus_effect(index,effect);effect.set_recording_active(true);recorders[bus]=effect
func record_stop(label):
 for bus in recorders:
  var effect=recorders[bus];effect.set_recording_active(false);var wav=effect.get_recording()
  check(wav!=null and wav.data.size()>1000,"actual PCM "+label+bus)
  if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path(audio_path+label+"-"+bus.to_lower()+".wav"))==OK,"write PCM "+label+bus)
  var index=AudioServer.get_bus_index(bus);AudioServer.remove_bus_effect(index,AudioServer.get_bus_effect_count(index)-1)
 recorders.clear()
func live(seconds,combat=true):
 var begin=Time.get_ticks_usec();var previous=begin
 while Time.get_ticks_usec()-begin<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now
  if combat:game._process(delta)
  else:
   game.presentation.update(delta,game.model);game.horror.update(delta,game.model);game.audio_system.update_state(delta,game.model,game.mode);game.ui.update_match();game.queue_redraw()
func events_since(before):
 var diff={}
 for name in game.audio_system.event_counts:
  var count=int(game.audio_system.event_counts[name])-int(before.get(name,0))
  if count>0:diff[name]=count
 return diff
func case_setup():
 game.return_menu();game.start_practice("crusher",false,["shield","repair"]);game.set_process(false);game.tutorial_enabled=false
 var m=game.model;var h=m.hunter
 h.boss_policy.enabled=false;h.state=HunterState.State.ATTACK;h.target=m.player_room;h.position=m.player().door_approach();h.cooldown=60;h.tactical_cooldown=60
 game.focus_camera(true);game.audio_system.reset_match(m)
 return m
func weapon_case(kind,music):
 var m=case_setup();var r=m.player();var tile=m.practice_tile;await live(.2,false)
 if kind=="heavy":
  await world_click(r.tile_position(tile));await advance(.15);check(game.ui.context_mode=="upgrade","Arc fixture selects old Needle");await click(game.ui.actions.sell);await advance(.15);check(not r.buildings.has(tile),"Arc fixture real sale clears tile");await world_click(r.tile_position(tile));await advance(.15);check(game.ui.context_mode=="build","Arc fixture opens reusable empty tile");await click(game.ui.actions["build:heavy"]);await advance(.15)
  check(r.buildings.has(tile) and r.buildings[tile].kind=="heavy","actual Arc purchase in temporary Practice")
 game.ui.close_context();game.audio_system.set_mix({"music":music,"effects":.65,"ambient":.5,"muted":false})
 await live(2);var hp=m.hunter.hp;var shots=m.shots;var before=game.audio_system.event_counts.duplicate(true)
 game.audio_system.loops.music_danger.seek(0)
 var label=("needle" if kind=="turret" else "arc")+("-default-mix" if music>0 else "-music-muted")
 record_start();await live(8);record_stop(label)
 var played=events_since(before);var prefix="shot_needle" if kind=="turret" else "shot_arc";var count=0
 for name in played:
  if name.begins_with(prefix):count+=played[name]
 check(count>0 and m.shots>shots and m.hunter.hp<hp,"actual launch/impact damage and sampled shot output "+label)
 results.append({"label":label,"seconds":8,"music":music,"effects":.65,"ambient":.5,"shot_events":count,"model_shots":m.shots-shots,"real_damage":hp-m.hunter.hp,"played":played,"diagnostics":game.audio_system.get_diagnostics(),"fixture":"Actual Practice combat; Hunter at legal own door, attacks/tactics delayed60s to isolate real projectile/impact output. Actual permanent inventory untouched."})
 await capture(label+"-720")
func transaction_case(music):
 var m=case_setup();var r=m.player();var label="build-upgrade"+("-default-mix" if music>0 else "-music-muted")
 game.audio_system.set_mix({"music":music,"effects":.65,"ambient":.5,"muted":false});await live(2,false)
 var before=game.audio_system.event_counts.duplicate(true);await world_click(r.tile_position(0));await advance(.15);check(game.ui.context_mode=="build","transaction fixture opens empty tile")
 record_start();await click(game.ui.actions["build:generator"]);await live(1.8,false)
 check(r.buildings.has(0) and r.buildings[0].kind=="generator","actual paid building transaction")
 await click(game.ui.actions.upgrade);await live(1.8,false);check(r.buildings[0].level==2,"actual paid building upgrade")
 await world_click(r.tile_position(m.practice_tile));await advance(.15);await click(game.ui.actions.upgrade);await advance(.15);await click(game.ui.specialization_items[1]);await advance(.15);await click(game.ui.branch_confirm);await live(2.2,false)
 record_stop(label);var played=events_since(before)
 check(played.get("build",0)>0 and played.get("upgrade",0)>0,"real transaction events produce build and upgrade cues")
 results.append({"label":label,"seconds_approx":6,"music":music,"effects":.65,"played":played,"diagnostics":game.audio_system.get_diagnostics(),"fixture":"Actual mouse BUILD, paid Dynamo L2 upgrade and selected+confirmed Needle branch; audio updates real time while combat model held between transaction actions."})
func run():
 output="res://docs/evidence/phase5d4/";phase="early-audio"
 root.size=Vector2i(1280,720);await setup_game()
 var saved=FileAccess.get_file_as_bytes(game.profile.path)
 for kind in ["turret","heavy"]:
  for music in [.5,0.0]:await weapon_case(kind,music)
 for music in [.5,0.0]:await transaction_case(music)
 check(FileAccess.get_file_as_bytes(game.profile.path)==saved,"Practice render/audio transactions do not change permanent profile")
 var f=FileAccess.open(audio_path+"results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":results,"platform":"Godot4.6.3 Linux Xorg/Mesa; Dummy hardware sink with actual internal engine Master/Effects/Music recording","human_audition":"UNVERIFIED","native_windows":"UNVERIFIED","stem_note":"Effects/Music bus effect recordings may precede final bus volume/mute. Use Master PCM for actual mixed output and music-muted comparisons."}," "))
 print("PHASE5D4_EARLY_AUDIO_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
