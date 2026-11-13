extends "res://tools/capture_spatial_construction.gd"
# Actual InputEvents through production Game, GUI, camera and model at both sizes.
func run():
 root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var m=fresh();var r=m.player();await advance(.35)
  var gold=r.gold
  await key(KEY_B);await advance(.3);await click(game.ui.actions["build:turret"]);await advance(.3)
  check(game.construction.active() and r.gold==gold,"card starts preview without charging")
  await point_mouse(Vector2(175,151));check(game.construction.reason()=="","world position under camera/viewport is valid")
  await world_click(Vector2(175,151));await advance(.15)
  check(r.buildings.size()==1 and r.tile_position(16)==game.construction.aligned(Vector2(175,151)),"real mouse click stores camera-correct free position at "+str(resolution))
  # Repeated second double-click press/release must not open/rebuy.
  var screen=root.get_final_transform()*game.world_to_screen(Vector2(175,151))
  for pressed in [true,false]:
   var e=InputEventMouseButton.new();e.position=screen;e.global_position=screen;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.double_click=pressed;Input.parse_input_event(e);await process_frame
  check(r.buildings.size()==1 and r.gold==gold-20 and not game.construction.active(),"second double-click cannot duplicate payment or leave ghost")
  await key(KEY_B);await advance(.3);await click(game.ui.actions["build:generator"]);await advance(.3);gold=r.gold
  await world_click(r.tile_position(16));check(r.gold==gold and r.buildings.size()==1,"invalid overlap click no spend")
  await key(KEY_ESCAPE);check(not game.construction.active() and r.gold==gold,"Esc cancels no charge")
  await world_click(r.tile_position(16));await advance(.3)
  var quote=Catalog.upgrade_cost("turret",1);var upgrade_wallet=Vector2(r.gold,r.electricity)
  await click(game.ui.actions.upgrade);await advance(.2)
  check(r.buildings[16].level==2 and Vector2(r.gold,r.electricity).is_equal_approx(upgrade_wallet-quote),"actual inspector upgrades opaque ID16 and spends exact two resources")
  await click(game.construction.move_button);await advance(.3)
  var before=r.buildings[16].duplicate(true);await point_mouse(Vector2(270,117));await key(KEY_ESCAPE)
  check(r.buildings[16]==before and r.spatial.moving_id==-1,"real move cancel restores same state")
  await world_click(r.tile_position(16));await advance(.3);await click(game.construction.move_button);await advance(.3);await world_click(Vector2(270,117));await advance(.3)
  before.position=game.construction.aligned(Vector2(270,117));check(r.buildings[16]==before,"mouse confirms same identity with unchanged ledger/cooldown")
  game.ui.close_context();await advance(.3);await key(KEY_P);check(game.construction.planning,"planning shortcut opens footprints")
  await key(KEY_F);check(not game.construction.snap,"snap toggle works");await key(KEY_F);await key(KEY_ESCAPE)
  check(not game.construction.planning,"Esc closes plan")
  var full=game.full_map;await key(KEY_M);check(game.full_map!=full,"M still controls map; no shortcut conflict");await key(KEY_M)
  m.time=m.preparation+1;await world_click(r.tile_position(16));await advance(.3)
  check(game.construction.move_button.disabled and game.construction.move_button.tooltip_text.contains("preparation"),"combat move disabled with explanation")
  check(not game.ui.actions.upgrade.disabled,"combat upgrades remain legal")
  var refund=r.building_refund(16);var sell_wallet=Vector2(r.gold,r.electricity)
  await click(game.ui.actions.sell);await advance(.2)
  check(r.buildings.is_empty() and Vector2(r.gold,r.electricity).is_equal_approx(sell_wallet+refund),"actual inspector sells moved opaque ID16 with exact investment refund")
  game.return_menu();check(r.spatial.moving_id==-1 and not game.construction.active(),"scene exit cleans reservation")
 # Actual click coordinates in all four door-normal orientations, including zoom.
 for spec in [["abandoned_dorm",3],["underground_lab",0],["underground_lab",3]]:
  root.size=Vector2i(1280,720);game.return_menu();check(game.start_endless(spec[0],"standard",71),"orientation launch")
  var m=game.model;m.claim_room(spec[1]);var r=m.player();m.player_position=r.bed_position();m.sleep_player();r.gold=2000;r.electricity=500
  game.zoom_factor=1.15;game.ui.show_match();game.focus_camera(true);game.construction.snap=false;await advance(.35)
  var at=candidate(r);await buy("turret",at)
  check(r.buildings.size()==1 and r.tile_position(16).distance_to(at)<.01,"actual free mouse purchase under oriented camera "+str(spec))
  await world_click(r.tile_position(16));await advance(.3);await click(game.construction.move_button);await advance(.3);var to=candidate(r,true);await world_click(to);await advance(.3)
  check(r.buildings.size()==1 and r.tile_position(16).distance_to(to)<.01,"actual move/selection under oriented zoom "+str(spec))
  game.zoom_factor=1.0
 print("SPATIAL_UI_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
