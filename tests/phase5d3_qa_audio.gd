extends "res://tests/premium_strategy_ui.gd"
const Support=preload("res://tests/replay_test_support.gd")
func advance_intro(seconds):
 var steps=roundi(seconds*10)
 for i in range(steps):
  game.onboarding._process(.1)
  game.audio_system.update_state(.1,game.model,game.mode)
func run():
 profile_path="user://phase5d3-qa-audio-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true
 p.settings.music=.37;p.settings.effects=.41;p.settings.ambient=.22;p.settings.muted=true
 check(p.save_profile(),"prepared saved listening preferences persist")
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 game.set_process(false);game.onboarding.set_process(false);await settle()
 var a=game.audio_system;var before=Support.profile_signature(game.profile);var bytes=FileAccess.get_file_as_bytes(profile_path)
 check(game.onboarding.is_welcome_open(),"returning graduate starts current manual welcome")
 game.onboarding.show_opening();a.update_state(.1,game.model,game.mode)
 check(game.mode=="intro" and a.cinematic_music,"actual app opens cinematic with score enabled")
 check(a.streams.size()==AudioDirector.LOOP_NAMES.size()+AudioDirector.EFFECT_NAMES.size() and a.music_start_count==8,"eight musical players and all declared streams decode once")
 check(a.streams.music_intro.loop_mode==AudioStreamWAV.LOOP_DISABLED and is_equal_approx(a.streams.music_intro.get_length(),19),"cinematic score is19seconds and never loops")
 for name in ["music_menu","music_calm","music_approach","music_danger","music_reaper","music_endless"]:
  check(a.streams[name].get_length()>=48 and a.streams[name].loop_mode==AudioStreamWAV.LOOP_FORWARD,"structured long musical loop "+name)
 for id in ["Music","Effects","Ambient"]:check(AudioServer.is_bus_mute(AudioServer.get_bus_index(id)),"saved mute honored on fresh launch "+id)
 check(is_equal_approx(a.mix.music,.37) and is_equal_approx(a.mix.effects,.41) and is_equal_approx(a.mix.ambient,.22),"saved independent volumes survive setup")
 advance_intro(3.9)
 check(a.loop_weights.music_intro>.9 and a.loop_weights.music_menu<.01,"intro targets score instead of silence/menu")
 check(a.event_counts.get("intro_running",0)==2 and a.event_counts.get("intro_breath",0)==2,"first fourseconds route running and genuine breath cues")
 advance_intro(4)
 check(a.event_counts.get("intro_lightning",0)==1 and a.event_counts.get("intro_whisper",0)==1,"4–8second threat/thunder route exactly once")
 advance_intro(4)
 check(a.event_counts.get("door_break",0)==1 and a.event_counts.get("intro_impact",0)==1,"8–12second door/impact cues route once")
 advance_intro(3.2)
 check(game.onboarding.phase=="title" and not a.cinematic_music and a.loop_weights.music_menu>0,"current manual welcome transitions to audible menu score")
 check(a.event_counts.get("intro_shriek",0)==1 and a.event_counts.get("intro_whisper",0)==1,"climax and creator-title vocals route once")
 advance_intro(4)
 check(game.mode=="menu" and not a.cinematic_music,"19second completion transitions to menu")
 check(game.onboarding.is_welcome_open(),"welcome remains until explicit close")
 game.onboarding.close_welcome();await settle()
 check(a.music_start_count==8,"minor states never instantiate duplicate music players")
 game.ui.show_settings();await settle();await click(find("Audio listening room"));await settle();screen("audio listening room")
 for id in ["intro","menu","calm","approach","danger","reaper","endless","crimson"]:
  await click(find(id.capitalize()+" · score"));a.update_state(.5,game.model,game.mode)
  check(a.preview_music=="music_"+id and a.loop_weights["music_"+id]>.5,"actual track audition button selects "+id)
 check(a.music_start_count==8 and a.get_child_count()==AudioDirector.LOOP_NAMES.size()+AudioDirector.VOICE_LIMIT,"auditions reuse eight music plus ambience and16 voices")
 await click(find("Voices"));await settle()
 for label in ["Death Scream 1","Hunter Laugh","Reaper Laugh","Intro Breath","Reaper Charge"]:
  await click(find(label));a.update_state(.1,game.model,game.mode)
  check(a.preview_effect_name!="" and a.preview_effect_until>a._clock,"actual major vocal audition remains active "+label)
 await click(find("Stop audition"));a.update_state(.2,game.model,game.mode)
 check(a.preview_music=="" and a.preview_effect_name=="","actual Stop clears track/vocal preview")
 # Real event-budget saturation can defer an audition. Stop must cancel the
 # deferred request too, rather than play it unexpectedly on the next update.
 for id in ["achievement_claim","shop_purchase","perk_unlocked","stage_bonus_selected","tutorial_step","mythic_perk"]:a.event(id)
 var death_before=int(a.event_counts.get("death_scream_2",0))
 a.preview_effect("death_scream_2")
 check(a._pending_critical.any(func(c):return c.name=="death_scream_2"),"saturated real event budget defers requested audition")
 a.stop_preview();a.update_state(.3,game.model,game.mode)
 check(int(a.event_counts.get("death_scream_2",0))==death_before and not a._pending_critical.any(func(c):return c.name=="death_scream_2"),"Stop cancels queued audition before it can replay")
 await click(find("Music"));await settle()
 await click(find("Menu · score"));await click(find("Back to settings"));await settle()
 check(game.ui.current_screen=="settings" and a.preview_music=="" and a.preview_effect_name=="","leaving listening room restores ordinary scene music")
 check(Support.profile_signature(game.profile)==before and FileAccess.get_file_as_bytes(profile_path)==bytes,"audition/intro never change stock/progression/settings/save bytes")
 # Replay must seek the nonloop score tozero; skipping must cancel its intro cues.
 game.onboarding.show_opening();a.update_state(.1,game.model,"intro")
 check(a.cinematic_music and a.loops.music_intro.get_playback_position()<1,"replayed opening starts soundtrack from zero")
 game.onboarding.skip();a.update_state(.2,game.model,game.mode)
 check(not a.cinematic_music and a.preview_music=="" and game.mode=="menu" and not game.onboarding.active,"replayed skip after dismissed welcome fully exits cinematic")
 var intro_names=["intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","door_break"]
 check(not a.voices.any(func(v):return v.playing and a._voice_names.get(v.get_instance_id(),"") in intro_names),"skip stops active cinematic effects")
 var player_ids={}
 for id in a.loops:player_ids[id]=a.loops[id].get_instance_id()
 var music_model=MatchModel.new();music_model.claim_room(0);music_model.player_position=music_model.player().bed_position();music_model.sleep_player()
 for i in range(30):a.update_state(.1,music_model,"match")
 check(a.loop_weights.music_calm>.8,"preparation has clearly enabled musical score")
 music_model.hunter.state=HunterState.State.SEEK;music_model.hunter.position=music_model.player().door_position()+Vector2(200,0)
 for i in range(30):a.update_state(.1,music_model,"match")
 check(a.loop_weights.music_approach>.7,"real approach threat crossfades to suspense music")
 music_model.hunter.state=HunterState.State.ATTACK;music_model.hunter.target=0;music_model.hunter.position=music_model.player().door_position();music_model.player().door_hp=music_model.player().max_hp()*.1
 for i in range(30):a.update_state(.1,music_model,"match")
 check(a.loop_weights.music_danger>.7 and a.loop_weights.music_approach<.01,"genuine dangerous siege condition selects intense musical state")
 music_model.hunter.transformed=true
 for i in range(30):a.update_state(.1,music_model,"match")
 check(a.loop_weights.music_reaper>.9 and a.loop_weights.music_danger<.01,"Reaper gets distinct boss music without stacked siege track")
 var endless_model=MatchModel.new();check(endless_model.configure_endless("abandoned_dorm","standard",17,1),"Endless musical fixture configures actual mode")
 endless_model.endless.wave=2
 for i in range(30):a.update_state(.1,endless_model,"match")
 check(a.loop_weights.music_endless>.8,"alternating Endless wave uses musical variation")
 for id in a.loops:check(a.loops[id].get_instance_id()==player_ids[id],"crossfade reuses existing player "+id)
 a.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 Support.cleanup(profile_path)
 # A truly absent profile uses normal non-muted defaults and still starts music.
 profile_path="user://phase5d3-qa-audio-fresh-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);await settle()
 a=game.audio_system;a.update_state(.3,game.model,game.mode)
 check(game.mode=="intro" and not game.profile.tutorial_completed and not a.mix.muted,"genuinely new profile starts scored opening with normal defaults")
 check(a.loop_weights.music_intro>0 and a.loops.music_intro.playing,"fresh cinematic produces actual enabled musical player")
 game.onboarding.skip();check(game.onboarding.is_welcome_open(),"fresh skip preserves current explicit welcome")
 game.onboarding.close_welcome();game.enter_game();a.update_state(.3,game.model,game.mode)
 check(game.tutorial_active and game.mode=="match" and not a.cinematic_music,"fresh skip enters unchanged mandatory tutorial and ends cinematic intent")
 check(a.loop_weights.music_calm>0,"tutorial preparation keeps musical accompaniment")
 print("PHASE5D3_AUDIO_QA_CHECKS=",checks," FAILURES=",failures)
 a.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 Support.cleanup(profile_path);quit(1 if failures else 0)
