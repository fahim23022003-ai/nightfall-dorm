extends "res://tools/capture_overhaul_combat.gd"
const Support=preload("res://tests/replay_test_support.gd")
var captures=[]
func capture(name):
 await super.capture(name);captures.append(name)
func posed(kind: String,level: int):
 var m=fixture_kind(kind);var r=m.player();m.evolution.evolution_level=level;m.evolution.final_revealed=true
 m.hunter.state=HunterState.State.ATTACK;m.hunter.target=r.index;m.hunter.position=r.door_approach();m.hunter.cooldown=.8;m.hunter.tactical_cooldown=60;m.hunter.arcane.cooldown=60
 return m
func gallery(mode: String,kinds: Array,level: int,name: String):
 var g=preload("res://tools/nightmare_gallery.gd").new();g.game=game;g.profile=game.profile;g.mode=mode;g.kinds=kinds;g.level=level
 game.visible=false;game.ui.panel.visible=false
 if is_instance_valid(game.ui.horror_layer):game.ui.horror_layer.visible=false
 var layer=CanvasLayer.new();layer.layer=100;root.add_child(layer);layer.add_child(g)
 await process_frame;await process_frame;await capture(name);layer.queue_free();game.visible=true;game.ui.panel.visible=true;
 if is_instance_valid(game.ui.horror_layer):game.ui.horror_layer.visible=true
 await process_frame
func run():
 output="/workspace/cinematic-nightmare/";phase="after";root.size=Vector2i(1280,720)
 await setup_game();game.onboarding.close_welcome()
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for level in [1,4,7,10]:
   posed(kind,level);await advance(.15);await capture("%s-E%d" % [kind,level])
  # Actual evolved and signature releases in a controlled campaign sandbox.
  for level in [4,10]:
   var m=posed(kind,level);m.run_kind="campaign";m.stage_id="stage_1";m.tutorial_mode=false;game.ui.show_match();game.focus_camera(true)
   var n=m.hunter.nightmare;n.cooldown=0
   await drive(.05);check(n.action!="","real high-level warning "+kind+str(level));await capture("skill-%s-E%d-warning" % [kind,level])
   for i in range(75):
    await drive(.05)
    if n.action=="" and n.remaining>0:break
   check(n.casts.size()==1,"actual ability released "+kind+str(level));await drive(.65);await capture("skill-%s-E%d-release" % [kind,level]);await drive(1.3);await capture("skill-%s-E%d-aftermath" % [kind,level])
  # Preserve original arcane/tactical skill and capture its actual release.
  if kind in ["witch","electric","storm"]:
   var m=posed(kind,1);m.hunter.arcane.cooldown=0;m.hunter.cooldown=60
   if kind=="witch":m.hunter.position=m.player().corridor_anchor();m.hunter.state=HunterState.State.MOVE
   await drive(.05);await capture("original-%s-warning" % kind)
   await drive(1.4);await capture("original-%s-impact" % kind)
 var sheet=preload("res://tools/nightmare_hunter_gallery.gd").new();sheet.game=game;sheet.profile=game.profile
 var sheet_layer=CanvasLayer.new();sheet_layer.layer=100;root.add_child(sheet_layer);sheet_layer.add_child(sheet);await advance(.1);await capture("hunter-forms-contact-sheet");root.size=Vector2i(1920,1080);await advance(.1);await capture("hunter-forms-contact-sheet-1080");root.size=Vector2i(1280,720);sheet_layer.queue_free();await process_frame
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var layer=CanvasLayer.new();layer.layer=100;root.add_child(layer)
  var bg=ColorRect.new();bg.color=Color("101822");bg.size=Vector2(1280,720);layer.add_child(bg)
  for column in range(2):
   var portrait=preload("res://tools/cinematic_hunter_portrait.gd").new();portrait.game=game;portrait.profile=game.profile;portrait.model=MatchModel.new();portrait.model.hunter.configure_archetype(kind);portrait.model.hunter.state=HunterState.State.ATTACK;portrait.model.hunter.cooldown=.8;portrait.model.evolution.evolution_level=1 if column==0 else 10;portrait.model.evolution.final_revealed=true;portrait.model.hunter.position=Vector2.ZERO;portrait.scale=Vector2.ONE*2.4;portrait.position=Vector2(340+column*600,480)-Vector2(145,40)*2.4;layer.add_child(portrait)
   var title=Label.new();title.position=Vector2(170+column*600,85);title.text=StrategyCatalog.ARCHETYPES[kind].name+" · LEVEL "+str(1 if column==0 else 10);title.add_theme_font_size_override("font_size",26);layer.add_child(title)
  var caption=Label.new();caption.position=Vector2(150,640);caption.text="PRODUCTION RIG CLOSE-UP INSPECTION · two comparison poses, not simultaneous combat";layer.add_child(caption)
  await advance(.1);await capture("closeup-"+kind);layer.queue_free();await process_frame
 # Real legal locomotion: no sprite-only sliding demonstration.
 var m=posed("ravager",8);var r=m.player();m.hunter.position=r.corridor_anchor();m.hunter.state=HunterState.State.MOVE
 for i in range(8):await drive(.12);await capture("motion-%02d" % i)
 # Actual time-based level transition, finite once-only reveal and Master audio.
 m=posed("crusher",9);m.run_kind="campaign";m.stage_id="stage_5";m.difficulty="hell";m.evolution.final_revealed=false;m.time=m.preparation+301
 game.profile.settings.music=0;game.profile.settings.ambient=0;game.profile.settings.effects=.7;game.profile.settings.muted=false;game.audio_system.set_mix(game.profile.settings)
 pcm_start();await drive(.05);check(m.evolution.evolution_level==10 and m.evolution.rebirth_remaining>0,"real campaign curve triggers rebirth")
 for i in range(13):await drive(.27);await capture("rebirth-%02d" % i)
 await advance(3.5);pcm_finish("rebirth-master")
 pcm_start();m.hunter.hurt(m.hunter.hp*2);await drive(.05);await capture("true-form-defeat");await advance(3.3);pcm_finish("true-form-defeat-master")
 check(game.audio_system.streams.has("nightmare_defeat"),"distinct final-form defeat stream exists")
 game.profile.settings.muted=true;game.audio_system.set_mix(game.profile.settings)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"saved mute silences evolved audio")
 game.profile.settings.muted=false;game.audio_system.set_mix(game.profile.settings)
 var kinds=Catalog.BUILDINGS.keys();kinds.append_array(["bed","door"])
 for level in [1,5,10]:await gallery("all",kinds,level,"buildings-all-L%d" % level)
 await gallery("levels",["turret","generator","door"],1,"progression-closeup-1-10")
 root.size=Vector2i(1920,1080);await gallery("matrix",kinds,1,"all-seventeen-all-ten-levels-1080");root.size=Vector2i(1280,720)
 # Genuine earned checkpoint comparison: preserve every canonical byte.
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var hash_before=FileAccess.get_sha256(source);var data=JSON.parse_string(FileAccess.get_file_as_string(source))
 game.return_menu();var p=PlayerProfile.new("user://nightmare-earned-after-"+str(Time.get_ticks_usec())+".json");p.tutorial_completed=true;p.next_match_id=int(data.run_id);p.begin_endless(data.map,data.difficulty,int(data.seed));p.replay.checkpoint=data.duplicate(true);p.save_profile();game.profile=p;check(game.resume_endless(),"genuine unchanged wave45 resume")
 game.set_process(false);await click(find_button("Prepare defenses · frozen economy"));await advance(.2);await capture("earned-wave45-matched")
 check(FileAccess.get_sha256(source)==hash_before,"canonical checkpoint remains untouched")
 # Real paid final upgrade and component reveal on an observed upper pad.
 game.return_menu();check(game.start_endless("abandoned_dorm","standard",71),"paid-building demo uses actual Endless")
 game.set_process(false);m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();r=m.player();r.gold=1e7;r.electricity=1e7;r.bed_level=9;r.door_level=9;r.bed_branch=StrategyCatalog.branches("bed")[0];r.door_branch=StrategyCatalog.branches("door")[0];r.door_hp=r.max_hp()
 check(m.buy("turret",0),"actual paid machine")
 for i in range(8):
  if r.buildings[0].level==4:check(m.specialize_building(0,StrategyCatalog.branches("turret")[0]),"paid exclusive branch")
  else:check(m.upgrade_building(0),"actual upgrade payment")
 check(r.buildings[0].level==9,"prepared actual paid L9")
 game.ui.close_context();game.focus_camera(true);game.presentation.update(.01,m);await advance(.1);await world_click(r.tile_position(0));await advance(.3)
 var old=r.gold;check(m.upgrade_building(0),"actual L10 upgrade succeeds");game.presentation.update(.05,m);game.ui.update_match();check(r.gold<old and r.buildings[0].level==10,"L10 actually charges and caps")
 await capture("paid-L10-upgrade-reveal");check(not m.upgrade_building(0),"L11 remains impossible")
 var result={"checks":checks,"failures":failures,"captures":captures,"setup":"Real Godot4.6.3 Linux runtime; isolated temporary budgets/levels and controlled encounter positions/time. Six-form portraits use posed Practice; evolved ability releases use converted isolated campaign sandbox states. Final audio cue and runtime inspection galleries use production code. Gallery is explicitly labeled production-renderer art inspection, not a match. Wave45 uses unchanged legitimate checkpoint. Paid final upgrade uses real price/branch/cap logic. Actual accepted Omen combat is captured separately with Phase6A GUI routes. Not human, natural-progression, or Windows evidence."}
 var f=FileAccess.open(output+"capture-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result," "))
 game.return_menu();game.ui.show_settings();await advance(.2);await capture("quality-settings");game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
