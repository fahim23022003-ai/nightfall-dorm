extends "res://tools/capture_overhaul_combat.gd"
# Production-rendered fixtures with prepared wallets/levels, not natural earning.
var observations=[]
func advance(seconds):
 # Frozen model fixtures still advance the production move presentation timer.
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1e6:
  await process_frame;var now=Time.get_ticks_usec();var delta=(now-previous)/1e6;previous=now
  if not game.construction.active():game.construction.update(delta)
  if game.mode=="match":game.focus_camera(false,delta)
  game.presentation.update(delta,game.model);game.horror.update(delta,game.model);game.audio_system.update_state(delta,game.model,game.mode);game.ui.items_ui.update(delta)
  if game.mode=="match":game.ui.update_match()
  game.queue_redraw()
func point_mouse(world: Vector2):
 var e=InputEventMouseMotion.new();e.position=root.get_final_transform()*game.world_to_screen(world);e.global_position=e.position;Input.parse_input_event(e);await process_frame;await advance(.08)
func fresh():
 # Historical fixed-price fixture, explicitly legacy. New balance has separate evidence.
 game.new_balance_version=1
 game.return_menu();check(game.start_endless("abandoned_dorm","standard",71),"actual Endless session")
 game.set_process(false);game.tutorial_enabled=false;var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
 for i in range(1,6):
  var other=m.rooms[i];other.owner=i;other.sleeping=true;other.closed=true;other.resident_position=other.bed_position();other.bot_timer=10000
 var r=m.player();r.gold=500000;r.electricity=500000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();game.ui.show_match();game.focus_camera(true);game.audio_system.reset_match(m);return m
func candidate(r,far=false):
 var rect=r.bounds().grow(-32);var candidates=[]
 for y in range(int(rect.position.y),int(rect.end.y),51):
  for x in range(int(rect.position.x),int(rect.end.x),53):
   var p=Vector2(x+3.375,y+1.625)
   if r.spatial.geometry_reason(p)=="":candidates.append(p)
 if candidates.is_empty():return Vector2.INF
 return candidates.back() if far else candidates.front()
func buy(kind,at):
 await key(KEY_B);await advance(.28);await click(game.ui.actions["build:"+kind]);await advance(.28);await point_mouse(at);await world_click(at);await advance(.25)
func run():
 output="/workspace/freedom-to-build/";phase="after";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome()
 var m=fresh();var r=m.player();await advance(.4)
 await key(KEY_B);await advance(.3);await click(game.ui.actions["build:turret"]);await advance(.3)
 await point_mouse(Vector2(175,151));await capture("02-free-preview");await capture("03-valid-green")
 await world_click(Vector2(175,151));await advance(.3);check(r.buildings.size()==1,"real click free position")
 await key(KEY_B);await advance(.3);await click(game.ui.actions["build:generator"]);await advance(.3);await point_mouse(r.tile_position(16));await capture("04-invalid-overlap")
 var gold=r.gold;await world_click(r.tile_position(16));check(r.buildings.size()==1 and r.gold==gold,"red click no purchase or spending");await key(KEY_ESCAPE)
 await buy("heavy",Vector2(266,116));await buy("generator",Vector2(278,178));check(r.buildings.size()==3,"three actual custom purchases");await capture("05-three-flexible")
 await world_click(r.tile_position(16));await advance(.3);await capture("10a-original-position");await click(game.construction.move_button);await advance(.3);await point_mouse(Vector2(180,88));await capture("09-moving-building");await world_click(Vector2(180,88));await advance(.3);await capture("10b-moved-position")
 var pos=r.tile_position(16);await world_click(pos);await advance(.3);await click(game.construction.move_button);await point_mouse(Vector2(310,140));await key(KEY_ESCAPE);check(r.tile_position(16)==pos,"actual Esc move cancellation")
 await key(KEY_B);await advance(.3);await click(game.ui.expansion_ui.shortcut);await advance(.3);await click(game.ui.expansion_ui.purchase_button);await advance(.5);await capture("06-expansion-unlocked")
 game.ui.close_context();await advance(.3)
 for kind in ["barrier","plasma","antenna"]:
  var at=candidate(r);game.construction.snap=false;await buy(kind,at)
 check(r.buildings.size()==6,"six actual free buildings");await capture("07-six-custom")
 for tier in range(2,5):check(m.expansion.purchase(m),"actual paid expansion "+str(tier))
 game.focus_camera(true)
 for kind in ["flame","frost","shock","auto_repair","shield"]:
  var at=candidate(r);check(m.place_building(kind,at),"mid layout "+kind)
 await advance(.4);await capture("08-midgame-layout")
 for tier in range(5,8):check(m.expansion.purchase(m),"actual late expansion "+str(tier))
 game.focus_camera(true);game.construction.planning=true;await advance(.4);await capture("11-sixteen-capacity")
 for kind in ["decoy","repair","economy","enhancer","turret"]:
  var at=candidate(r,true);check(m.place_building(kind,at),"late layout "+kind)
 check(r.buildings.size()==16,"full capacity uses real non-overlapping structures")
 for id in r.buildings:
  for level in range(2,11):
   var b=r.buildings[id];var ok=m.specialize_building(id,StrategyCatalog.branches(b.kind)[0]) if b.level==4 else m.upgrade_building(id)
   check(ok,"actual paid late upgrade")
 game.construction.planning=false;await advance(1.6);await capture("12-sixteen-custom-L10")
 game.selected_tile=16;game.ui.open_context();await advance(.4);await capture("13-selected-L10")
 game.ui.close_context();game.construction.planning=true;await advance(.4);await capture("18-planning-overlay");game.construction.planning=false
 var ids=r.buildings.keys();observations.append({"layout":"prepared full16 all levels paid","buildings":r.buildings.duplicate(true),"capacity":r.tile_count()})
 # Real ongoing ticks, normal combat rules and unmodified full-health wave Hunter.
 m.time=m.preparation+.1;var h=m.hunter;h.boss_policy.enabled=false;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=1
 await drive(.1);await capture("14-relocated-live-combat")
 root.size=Vector2i(1920,1080);game.focus_camera(true);await drive(.1);await capture("15-late-layout-1080")
 root.size=Vector2i(1280,720);game.return_menu()
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var canonical=JSON.parse_string(FileAccess.get_file_as_string(source));var loaded=ReplaySnapshot.restore(canonical)
 check(loaded!=null,"earned45 actual migration")
 if loaded!=null:
  game.model=loaded;game.mode="match";game.watched_room=-1;game.construction.reset();game.ui.show_match();game.ui.replay_ui.preparing=true;game.focus_camera(true);game.audio_system.reset_match(loaded);await advance(.5);await capture("16-old-earned45-migrated")
  observations.append({"layout":"canonical earned45 unchanged source","source_sha256":FileAccess.get_sha256(source),"relocations":loaded.player().spatial.relocations,"capacity":loaded.player().tile_count(),"buildings":loaded.player().buildings.size()})
 game.return_menu();check(game.start_practice("crusher",false,["shield","repair"]),"fixed practice launch");game.set_process(false);game.focus_camera(true);await advance(.4);await capture("17-practice-fixed-pads")
 var f=FileAccess.open(output+"after/observations.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"conditions":"Real production Godot Linux rendered fixtures, scripted actual InputEvent clicks; prepared budgets/levels/encounter position explicitly not human/natural progression.","observations":observations}," "))
 print("SPATIAL_RENDER_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
