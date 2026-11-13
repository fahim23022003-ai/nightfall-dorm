extends "res://tools/capture_overhaul_combat.gd"
# Continuous normal wall-time playback in explicitly controlled integration scenes.
# No frame sampling, speed-up, hit-stop, AI rewrite or edited progression claim.
var timeline=[]
func run():
 output="/workspace/cinematic-nightmare/";phase="after";root.size=Vector2i(1280,720)
 await setup_game();game.onboarding.close_welcome();game.profile.settings.music=.45;game.profile.settings.effects=.75;game.profile.settings.ambient=.3;game.profile.settings.graphics_quality="medium";game.audio_system.set_mix(game.profile.settings)
 var caption=Label.new();caption.position=Vector2(355,145);caption.add_theme_font_size_override("font_size",15);caption.add_theme_color_override("font_color",Color("E6D2B4"));caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var overlay=CanvasLayer.new();overlay.layer=90;root.add_child(overlay);overlay.add_child(caption)
 var first=fixture_kind("crusher");caption.text="CONTINUOUS ENGINE CAPTURE · controlled combat scenes"
 await advance(.2);print("VIDEO_READY")
 while not FileAccess.file_exists("/tmp/cinematic-record-go"):await process_frame
 pcm_start();var recording_start=Time.get_ticks_usec()
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var m=fixture_kind(kind);var h=m.hunter;var r=m.player()
  m.run_kind="campaign";m.stage_id="stage_1";m.time=m.preparation+.1;m.tutorial_mode=false;m.evolution.evolution_level=4;m.evolution.final_revealed=true
  h.position=r.corridor_anchor();h.state=HunterState.State.MOVE;h.target=r.index;h.target_time=20;h.cooldown=1;h.nightmare.cooldown=0;h.arcane.cooldown=60;h.tactical_cooldown=60
  if kind=="storm":m.stage_id="stage_5";m.difficulty="hell";m.time=m.preparation+301;m.evolution.evolution_level=9;m.evolution.final_revealed=false
  caption.text=StrategyCatalog.ARCHETYPES[kind].name+" · controlled live combat"+(" · real Level10 transition" if kind=="storm" else " · evolved skill")
  game.ui.show_match();game.focus_camera(true);game.audio_system.reset_match(m)
  timeline.append({"kind":kind,"start_wall_seconds":(Time.get_ticks_usec()-recording_start)/1e6})
  var start=Time.get_ticks_usec();var previous=start;var hurt=false;var frames=0;var elapsed=0.0;var simulation_start=m.time;var duck_min=1.0;var max_voices=0
  while elapsed<(17 if kind=="storm" else 12):
   await process_frame;var now=Time.get_ticks_usec();var delta=(now-previous)/1e6;previous=now;elapsed=(now-start)/1e6
   game._process(delta);frames+=1;duck_min=minf(duck_min,game.audio_system.music_duck);max_voices=maxi(max_voices,game.audio_system.voices.filter(func(v):return v.playing).size())
   if elapsed>7 and not hurt:m.apply_target_damage(1,10,r.index,{"type":"physical","element":"neutral"});hurt=true
  timeline[-1].sim_seconds=m.time-simulation_start;timeline[-1].duck_min=duck_min;timeline[-1].max_voices=max_voices;timeline[-1].audio_events=game.audio_system.event_counts.duplicate();timeline[-1].frames=frames;timeline[-1].wall_seconds=elapsed;timeline[-1].attacks=h.attacks;timeline[-1].casts=h.nightmare.casts.duplicate();timeline[-1].revealed=m.evolution.final_revealed
 pcm_finish("continuous-combat-master")
 var f=FileAccess.open(output+"continuous-timeline.json",FileAccess.WRITE);f.store_string(JSON.stringify({"segments":timeline,"wall_seconds":(Time.get_ticks_usec()-recording_start)/1e6,"setup":"Uncut X11 screen capture, normal wall-time engine updates. Isolated fixtures pose movement/contact, optional temporary wallets, starting cooldowns and a campaign threshold for transformation. No human or naturally earned progression claim."}," "))
 print("VIDEO_COMPLETE");overlay.queue_free();game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
