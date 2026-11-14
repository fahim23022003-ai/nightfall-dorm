extends "res://tools/capture_spatial_construction.gd"
func run():
 output="res://docs/evidence/first-night/";phase="screens";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();var m=fresh();var r=m.player()
 for at in [Vector2(175,151),Vector2(230,151),Vector2(285,151)]:check(m.place_building("turret",at),"paid baseline body")
 await advance(.3)
 for id in r.buildings:check(m.upgrade_building(id),"actual simultaneous upgrade")
 await advance(.04);await capture("16a-upgrade-overlap-before")
 print("FIRST_NIGHT_BASELINE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout;quit(1 if failures else 0)
