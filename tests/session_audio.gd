extends SceneTree
var checks=0
var failures=0
func check(ok,why):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var a=AudioDirector.new();root.add_child(a);var m=MatchModel.new();m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var rng=m.random.state;var nodes=a.get_child_count();var starts=a.music_start_count
 for i in range(20):a.update_state(.1,null,"menu")
 check(a.soundtrack.current in Soundtrack.FAMILIES.music_menu,"shuffle routes menu")
 var history=a.soundtrack.history.duplicate(true);a.preview_track("music_dust")
 for i in range(10):a.update_state(.1,null,"menu")
 check(a.soundtrack.history==history,"audition never consumes history");a.stop_preview()
 a.set_mix({"music_mode":"manual","manual_track":"music_siege"});a.reset_match(m)
 for i in range(20):a.update_state(.1,m,"match")
 check(a.loop_weights.music_siege>.7,"manual ordinary gameplay selection")
 m.hunter.transformed=true;m.hunter.hp=100
 for i in range(20):a.update_state(.1,m,"match")
 check(a.loop_weights.music_reaper>.8 and a.loop_weights.music_siege<.01,"boss overrides manual")
 m.wrath.domain_room=0;m.wrath.domain_remaining=15
 for i in range(20):a.update_state(.1,m,"match")
 check(a.loop_weights.music_crimson>.8,"Crimson boss priority")
 a.set_mix({"music_mode":"off"})
 for i in range(20):a.update_state(.1,m,"match")
 var sum=0.0
 for key in a.loops:
  if key.begins_with("music"):sum+=a.loop_weights[key]
 check(sum<.001 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Off silences all music including bosses at the actual bus")
 var off_history=a.soundtrack.history.duplicate(true);a.preview_track("music_dust");a.update_state(.1,null,"menu")
 check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and a.soundtrack.history==off_history,"explicit audition bypasses playlist Off without consuming history")
 a.stop_preview();check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"ending audition restores actual Off bus mute")
 a.set_suspended(true);check(a.loops.music_siege.stream_paused,"pause all music");a.set_suspended(false)
 check(not a.loops.music_siege.stream_paused,"resume existing players")
 check(a.get_child_count()==nodes and a.music_start_count==starts,"stable player lifecycle")
 check(m.random.state==rng,"all soundtrack operations leave combat RNG untouched")
 check(a.streams.music_opening_alt.loop_mode==AudioStreamWAV.LOOP_DISABLED,"cinematic alternate is a genuine one-shot")
 a.set_mix({"music_mode":"manual"});a.begin_cinematic()
 for i in range(20):a.update_state(.1,null,"intro")
 check(a.soundtrack.current in Soundtrack.FAMILIES.music_intro,"manual preserves cinematic identity")
 var n=MatchModel.new();n.configure_endless("abandoned_dorm","standard",71,987);n.claim_room(0);n.player_position=n.player().bed_position();n.sleep_player();n.endless.wave=2;a.reset_match(n);a.set_mix({"music_mode":"shuffle"})
 for i in range(20):a.update_state(.1,n,"match")
 check(a.soundtrack.current in Soundtrack.FAMILIES.music_calm,"even Endless preparation remains calm")
 n.time=n.preparation+1;n.hunter.state=HunterState.State.ATTACK;n.hunter.target=0;n.hunter.position=n.player().door_approach();n.player().door_hp=n.player().max_hp()*.2
 for i in range(20):a.update_state(.1,n,"match")
 check(a.soundtrack.current in Soundtrack.FAMILIES.music_danger,"urgent even Endless siege overrides ordinary wave music")
 m.running=false;a.update_state(.1,m,"menu");var menu_elapsed=a.soundtrack.elapsed;a.update_state(.2,m,"menu")
 check(a.soundtrack.elapsed>menu_elapsed,"old paused/finished model cannot freeze menu playlist")
 a.shutdown();a.update_state(.1,m,"match");check(a.streams.is_empty() and a.get_child_count()==nodes,"shutdown cannot restart players on host drain frame");a.queue_free();await create_timer(.5).timeout;print("SESSION_AUDIO_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
