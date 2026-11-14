extends "res://tools/capture_spatial_construction.gd"
func run():
 output="res://docs/evidence/first-night/";phase="screens";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();var m=fresh();var r=m.player()
 for at in [Vector2(175,151),Vector2(230,151),Vector2(285,151)]:check(m.place_building("turret",at),"paid body")
 await advance(.3)
 for id in r.buildings:check(m.upgrade_building(id),"actual simultaneous upgrade")
 await advance(.3);game.ui.update_match();await capture("16b-readable-upgrade-summary")
 for size in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=size;game.ui.show_match();game.focus_camera(true);await advance(.4);await capture("layout-"+str(size.y))
 root.size=Vector2i(1280,720)
 # Actual canonical earned state; no injected resources, HP or combat shortcuts.
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var hash=FileAccess.get_sha256(source)
 m=ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string(source)));check(m!=null,"canonical earned45 restores")
 game.model=m;game.mode="match";game.watched_room=-1;game.construction.reset();game.ui.show_match();game.focus_camera(true);game.audio_system.reset_match(m);r=m.player()
 for id in r.buildings:
  if r.buildings[id].kind=="repair":
   while r.buildings[id].level<10:check(m.upgrade_building(id),"earned repair upgrade")
 for tile in range(r.tile_count()):
  if r.buildings.has(tile):continue
  var point=r.fixed_tile_position(tile)+Vector2(3,-1)
  if r.spatial.geometry_reason(point)!="":continue
  check(m.place_building("heavy",point),"earned Arc purchase")
  var id=r.spatial.next_id-1
  while r.buildings[id].level<10:check(m.specialize_building(id,"focus") if r.buildings[id].level==4 else m.upgrade_building(id),"earned Arc upgrade")
 check(r.buildings.size()==16,"actual earned16")
 await advance(1);await capture("17-earned-full16")
 check(m.continue_wave("repair"),"normal earned wave46 Continue");game.ui.show_match();game.focus_camera(true)
 var started=Time.get_ticks_usec()
 while m.endless.phase=="combat" and m.result=="" and Time.get_ticks_usec()-started<130000000:await live(.2)
 check(m.endless.phase=="intermission" and m.endless.completed==46,"full-health earned46 clears under normal live processing")
 check(FileAccess.get_sha256(source)==hash,"canonical checkpoint unchanged")
 game.ui.replay_ui.show_intermission();await advance(.3);await capture("15-intermission-decisions")
 await click(find_button("Wave report"));await advance(.4);await capture("11-wave-report-redesign");await capture("12-damage-breakdown")
 await click(find_button("Economy"));await advance(.3);await capture("13-economy-breakdown")
 await click(find_button("Defense"));await advance(.3);await capture("defense-breakdown")
 await click(find_button("Insights"));await advance(.3);await capture("14-strategy-feedback")
 root.size=Vector2i(1920,1080);await click(find_button("Damage"));await advance(.3);await capture("18-wave-report-1080")
 game.ui.show_match();game.focus_camera(true);await advance(.3);await capture("18-gameplay-1080")
 save_data("earned46-report",{"metrics":m.wave_metrics.report(),"checks":checks,"failures":failures,"source_sha256":hash,"conditions":"Canonical earned45 state, actual paid repairs/four Arc10 from original funds, real full-health wave46 via normal live Game._process. No HP/Gold injections; scripted fixture, not human gameplay."})
 print("FIRST_NIGHT_RENDER_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout;quit(1 if failures else 0)
