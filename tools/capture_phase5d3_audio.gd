extends "res://tools/capture_visual_overhaul.gd"
# Actual Linux viewport and internal master-bus output. Prepared state is disclosed.
var samples=[]
var timeline=[]
var recorder
var audio_dir="res://docs/evidence/phase5d3/"
func save_json(name,value):
 var f=FileAccess.open(audio_dir+name+".json",FileAccess.WRITE);f.store_string(JSON.stringify(value," "))
func record_start():
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
func record_stop(name):
 recorder.set_recording_active(false);var wav=recorder.get_recording()
 check(wav!=null and wav.data.size()>1000,"actual Master PCM "+name)
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path(audio_dir+name+".wav"))==OK,"write PCM "+name)
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1);recorder=null
func live(seconds):
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now
  game._process(delta)
func hunt_audio(seconds):
 # Freeze controlled combat model, but real-time audio/render state continues.
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now
  game.presentation.update(delta,game.model);game.horror.update(delta,game.model);game.audio_system.update_state(delta,game.model,game.mode);game.ui.update_match();game.queue_redraw()
func button_any(text,node):
 for child in node.get_children():
  if child is Button and child.text==text and not child.is_queued_for_deletion():return child
  var found=button_any(text,child)
  if found!=null:return found
 return null
func screen(name):
 await capture(name)
func sample(label):
 var d=game.audio_system.get_diagnostics();d.label=label;d.preview=game.audio_system.preview_music;d.loop_db={};d.positions={}
 for name in game.audio_system.loops:d.loop_db[name]=game.audio_system.loops[name].volume_db;d.positions[name]=game.audio_system.loops[name].get_playback_position()
 samples.append(d)
func transition_case():
 game.profile.tutorial_completed=true;game.onboarding.skip();game.tutorial_active=false;game.set_process(false)
 var source="res://docs/evidence/phase5d3/qa-pre5d3-endless-profile.json"
 var dest="user://phase5d3-render-transition-"+str(Time.get_ticks_usec())+".json"
 check(DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(dest))==OK,"isolated genuine old checkpoint copy")
 var p=PlayerProfile.new(dest);check(p.load_profile(),"old checkpoint profile loads")
 print("TRANSITION_PROFILE readonly=",p.read_only," warning=",p.warning)
 if p.read_only:
  game.audio_system.shutdown();await create_timer(.6).timeout;quit(1);return
 p.tutorial_completed=true;check(p.save_profile(),"graduate GUI copy only")
 game.profile=p;check(game.resume_endless(),"actual checkpoint resume")
 game.set_process(false);await click(find_button("Continue · Salvage"))
 var m=game.model;var h=m.hunter;var npc=m.rooms[0 if m.player_room!=0 else 1]
 h.boss_policy.enabled=false;h.transformed=false;h.target=npc.index;h.state=HunterState.State.ATTACK;m.time=m.preparation+.1
 npc.owner=1;npc.alive=true;npc.sleeping=true;npc.closed=true;npc.rescue_used=true;npc.door_hp=1
 h.position=npc.door_approach();h._damage_door(npc,m,2);h.state=HunterState.State.BREACH;h.position=npc.bed_position();h.tick(.01,m)
 print("TRANSITION_DEATH mode=",game.mode," phase=",m.endless.phase," hp=",npc.door_hp," alive=",npc.alive," state=",h.state," target=",h.target)
 check(not npc.alive,"genuine controlled NPC breach/bed contact elimination")
 var before=int(game.audio_system.event_counts.get("hunter_laugh",0));game.audio_system.update_state(.01,m,"match")
 var actual=[]
 for v in game.audio_system.voices:
  if v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"").begins_with("death_scream"):actual.append(v)
 check(not actual.is_empty(),"actual long death scream starts")
 var pending=game.audio_system.pending_laughs.size()
 check(pending>0,"actual breach queues distinct Hunter laugh")
 record_start();h.hurt(h.hp*100+100);m.tick(.01);game._process(.01);await process_frame
 check(m.endless.phase=="intermission","controlled Hunter defeat creates intermission")
 await click(find_button("Continue · Salvage"))
 check(actual.all(func(v):return v.playing),"actual Continue preserves playing long scream")
 await live(10.5)
 check(game.audio_system.event_counts.get("hunter_laugh",0)>before,"queued laugh actually plays after3.47second scream, not silently expires")
 check(game.audio_system.pending_laughs.is_empty() and game.audio_system.pending_deaths.is_empty(),"real sequence drains")
 check(not game.audio_system.voices.any(func(v):return v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"")=="hunter_laugh"),"preserved actual laugh completes")
 record_stop("audio-transition-long-voices")
 save_json("audio-transition-result",{"checks":checks,"failures":failures,"scream_seconds":game.audio_system.streams.death_scream_1.get_length(),"laugh_seconds":game.audio_system.streams.hunter_laugh.get_length(),"queued":pending,"laugh_count_before":before,"diagnostics":game.audio_system.get_diagnostics()})
 print("PHASE5D3_AUDIO_TRANSITION_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
func run():
 output="res://docs/evidence/phase5d3/render-screens/";phase="audio"
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase5d3-render-audio-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 if "transition" in OS.get_cmdline_user_args():
  await transition_case();return
 check(game.mode=="intro" and game.onboarding.phase=="cinematic","genuinely fresh launch starts cinematic")
 check(game.audio_system.loops.size()==11 and game.audio_system.music_start_count==7,"seven score players plus four ambience players")
 var defaults=game.profile.settings.duplicate(true);save_json("audio-saved-default-settings",defaults)
 record_start()
 for segment in [[.8,"opening-immediate"],[4.5,"opening-pursuit"],[4.5,"opening-door"],[3.5,"opening-climax"],[2.4,"opening-title"],[4.2,"opening-end"]]:
  await live(segment[0]);sample(segment[1]);timeline.append({"label":segment[1],"phase":game.onboarding.phase,"elapsed":game.onboarding.elapsed,"event_counts":game.audio_system.event_counts.duplicate(true)})
  if segment[1] in ["opening-immediate","opening-climax","opening-title"]:await screen(segment[1]+"-720")
 record_stop("audio-fresh-cinematic-title")
 check(game.audio_system.event_counts.get("intro_breath",0)>0 and game.audio_system.event_counts.get("intro_shriek",0)>0,"real opening breathing/climax events played")
 check(game.onboarding.phase=="tutorial","fresh 19second opening routes to existing tutorial")
 # Existing-profile replay/skip; only isolated profile graduation is prepared.
 game.profile.tutorial_completed=true;game.profile.save_profile();game.tutorial_active=false;game.onboarding.active=false;game.return_menu();game.set_process(false)
 await live(.8)
 game.onboarding.show_opening();await live(.4)
 check(game.audio_system.loops.music_intro.get_playback_position()<1,"replay score seeks to actual opening start")
 await click(button_any("Skip opening · Space / Enter / Esc",game.onboarding));await live(1.3)
 check(game.mode=="menu" and not game.audio_system.cinematic_music,"real skip returns graduated player to menu")
 check(game.audio_system.loop_weights.music_menu>.8 and game.audio_system.loop_weights.music_intro<.1,"skip crossfades score to menu")
 check(game.audio_system._pending_critical.all(func(c):return not c.name.begins_with("intro_")),"skip leaves no queued cinematic voices")
 for res in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=res;game.ui.show_settings();await live(.2);await screen("settings-audio-entry-"+str(res.y))
  await click(find_button("Audio listening room"));await live(.2);check(game.ui.current_screen=="audio_test","actual settings listening-room button")
  await screen("listening-room-"+str(res.y))
 root.size=Vector2i(1280,720)
 var tracks=["music_intro","music_menu","music_calm","music_approach","music_danger","music_reaper","music_endless"]
 for name in tracks:
  await click(find_button(name.trim_prefix("music_").capitalize()+" · score"));await live(1.1)
  check(game.audio_system.preview_music==name and game.audio_system.loops[name].playing,"actual selected score plays "+name)
  record_start();await live(4.0);record_stop("audio-preview-"+name);sample(name)
  check(game.audio_system.loop_weights[name]>.95,"selected score reaches audible target "+name)
  check(game.audio_system.music_start_count==7,"preview creates no duplicate music player")
 # Actual native WAV loop boundary after explicit seek, not a natural64second wait.
 await click(find_button("Menu · score"));await live(1.2)
 var menu=game.audio_system.loops.music_menu;menu.seek(menu.stream.get_length()-1.5)
 record_start();await live(3.5);record_stop("audio-menu-loop-boundary")
 check(menu.get_playback_position()<5 and menu.playing,"actual64second score loops across last1.5seconds")
 for name in ["death_scream_1","hunter_laugh","reaper_laugh","intro_breath","reaper_charge"]:
  await click(find_button(name.replace("_"," ").capitalize()));await live(.12)
  check(game.audio_system.preview_effect_name==name,"actual recorded voice selection "+name)
  check(game.audio_system.voices.any(func(v):return v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"")==name),"audition voice survives menu cleanup "+name)
  record_start();await live(minf(3,game.audio_system.streams[name].get_length()-.15));record_stop("audio-preview-"+name);sample(name)
 await click(find_button("Stop audition"));await live(.2)
 check(game.audio_system.preview_music=="" and game.audio_system.preview_effect_name=="","actual Stop clears audition")
 # Saved .5 mix and zero/mute semantics; internal output is evaluated from PCM too.
 var saved=game.profile._reward_snapshot();var bytes=FileAccess.get_file_as_bytes(game.profile.path)
 game.audio_system.set_mix({"music":.5,"effects":0,"ambient":0,"muted":false})
 await click(find_button("Menu · score"));await live(1.2)
 record_start();await live(4);record_stop("audio-current-menu-same-volume")
 var stream=game.audio_system.loops.music_menu.stream
 var old=AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(audio_dir+"audio-old-menu-source.wav"))
 check(old!=null,"frozen old baseline music source decoded")
 if old!=null:
  game.audio_system.loops.music_menu.stream=old;game.audio_system.loops.music_menu.play(0)
  # Reconstruction of baseline's steady menu target1 *.85 gain -12dB,
  # same .5 Music bus with -5dB headroom; actual engine PCM, not RMS arithmetic.
  game.set_process(false);await process_frame
  game.audio_system.loops.music_menu.volume_db=linear_to_db(.85)-12
  record_start();await create_timer(4).timeout;record_stop("audio-old-menu-reconstructed-route")
  game.audio_system.loops.music_menu.stream=stream;game.audio_system.loops.music_menu.play(0)
 game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":.5,"muted":true});await live(.4)
 record_start();await live(1);record_stop("audio-muted")
 game.audio_system.set_mix({"music":0,"effects":0,"ambient":0,"muted":false});await live(.4)
 record_start();await live(1);record_stop("audio-zero-volumes")
 check(game.profile._reward_snapshot()==saved and FileAccess.get_file_as_bytes(game.profile.path)==bytes,"audition/mix probes leave saved profile unchanged")
 game.audio_system.set_mix(defaults);await click(find_button("Back to settings"));await live(.3)
 check(game.ui.current_screen=="settings" and game.audio_system.preview_music=="","actual Back exits listening mode")
 # Controlled threat states drive production music routing; no model ticks/injected progression reward claim.
 game.start_practice("crusher",false,["shield","repair"]);game.set_process(false);game.onboarding.active=false
 var m=game.model;var h=m.hunter;h.boss_policy.enabled=false
 var music_times={}
 for state in ["preparation","approach","siege","reaper","endless"]:
  h.transformed=false;h.state=HunterState.State.DORMANT;h.position=m.map_data.spawn
  if state=="approach":h.state=HunterState.State.MOVE;h.position=m.player().door_approach()+Vector2(250,0)
  if state=="siege":h.state=HunterState.State.ATTACK;h.target=m.player_room;h.position=m.player().door_approach()
  if state=="reaper":h.transformed=true;h.state=HunterState.State.ATTACK;h.target=m.player_room;h.position=m.player().door_approach()
  if state=="endless":
   var n=MatchModel.new();check(n.configure_endless("abandoned_dorm","standard",17,123),"controlled Endless audio fixture configured")
   game._adopt_session(n);game.set_process(false);m=game.model;h=m.hunter;m.endless.wave=2;h.boss_policy.enabled=false
  await hunt_audio(1.5);record_start();await hunt_audio(3);record_stop("audio-state-"+state);sample("state-"+state)
  var expected="music_calm" if state=="preparation" else "music_approach" if state=="approach" else "music_danger" if state=="siege" else "music_reaper" if state=="reaper" else "music_endless"
  check(game.audio_system.loop_weights[expected]>.6,"real target state has its appropriate score "+state)
  if state=="siege":
   check(game.audio_system.event("reaper_charge"),"actual warning cue routed for ducking probe")
   await hunt_audio(.25);check(game.audio_system.music_duck<.7,"critical attack voice actually ducks musical playback")
   sample("critical-warning-duck");await hunt_audio(2)
  if music_times.size()>0:
   var prior=float(music_times.values()[-1]);var current=game.audio_system.loops.music_menu.get_playback_position()
   check(fposmod(current-prior,game.audio_system.loops.music_menu.stream.get_length())>3,"minor state transition preserves continuously advancing music timeline")
  check(game.audio_system.music_start_count==7,"threat transition never recreates music players")
  await screen("music-state-"+state+"-720")
  music_times[state]=game.audio_system.loops.music_menu.get_playback_position()
 save_json("audio-route-samples",samples);save_json("audio-cinematic-timeline",timeline)
 save_json("audio-run-result",{"checks":checks,"failures":failures,"platform":"Godot4.6.3 Linux Mesa llvmpipe; Dummy hardware output, actual internal Master PCM","windows":"UNVERIFIED","subjective_audition":"UNVERIFIED","seven_track_preview_seconds":4,"loop_boundary_fixture":"explicit seek to1.5s before64s end","baseline_route_fixture":"actual old source3e6224e; reconstructed old steady menu routing atsame.5Music bus","final_diagnostics":game.audio_system.get_diagnostics()})
 print("PHASE5D3_AUDIO_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.stop_preview();game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
