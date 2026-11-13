extends "res://tests/phase5d4_qa_ui.gd"
func run():
 profile_path="user://session-range-ui-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);await settle();preload("res://tests/onboarding_test_support.gd").skip(game)
 check(game.start_practice("stalker",false,["shield","repair"]),"real fixed-pad practice")
 game.set_process(false);var m=game.model;var r=m.player();var id=m.practice_tile
 game.selected_tile=id;game.ui.open_context();await settle();game.construction.refresh()
 check(game.construction.range_button.visible,"range toggle available in fixed-pad mode")
 for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;await settle()
  for zoom in [.5,1.0,1.5]:
   game.camera.zoom=Vector2.ONE*zoom;game.camera.force_update_scroll()
   var world=r.tile_position(id);var screen=game.world_to_screen(world)
   check(game.construction.from_screen(screen).distance_to(world)<.001,"camera range origin roundtrip "+str(size)+" "+str(zoom))
 var b=r.buildings[id];var radius=BuildingStats.weapon_stats(m,r,b).range
 m.hunter.conceal_remaining=3;check(is_equal_approx(BuildingStats.weapon_stats(m,r,b).range,radius*.8),"actual concealment range reduction")
 var old=m.random.state;await key(KEY_O);check(not game.construction.ranges,"keyboard range toggle in fixed-pad mode");await key(KEY_O);check(game.construction.ranges and m.random.state==old,"toggle restores overlay without gameplay RNG")
 print("SESSION_RANGE_UI_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout;quit(1 if failures else 0)
