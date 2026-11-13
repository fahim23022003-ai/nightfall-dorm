extends "res://tools/capture_spatial_construction.gd"
var frame_times=[]
var combat_captured=false
func run():
 output="res://docs/evidence/every-night/";phase="screens";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();game.return_menu()
 if "listening" in OS.get_cmdline_user_args():
  game.ui.show_audio_test();await advance(.5);await capture("B2-listening-all14")
  game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout;quit(1 if failures else 0);return
 SessionInterface.settings(game.ui);await advance(.5);SessionInterface.refresh(game.ui);await capture("A-shuffle-settings-720")
 var m=fresh();var r=m.player();game.construction.snap=false
 await key(KEY_B);await advance(.3);await click(game.ui.actions["build:turret"]);await point_mouse(Vector2(175,151));await capture("D-live-range-placement-720");await world_click(Vector2(175,151));await advance(.3)
 var id=game.selected_tile;var original=r.tile_position(id);await world_click(original);await advance(.3);await click(game.construction.move_button);await point_mouse(Vector2(180,88));await world_click(Vector2(180,88));await advance(.5);await world_click(r.tile_position(id));await advance(.3);await capture("H1-move-undo-available")
 await click(game.construction.undo_button);check(r.tile_position(id)==original,"actual GUI undo restores position");await advance(.4);await capture("H2-undo-restored")
 for level in range(2,11):
  check(m.specialize_building(id,StrategyCatalog.branches("turret")[0]) if r.buildings[id].level==4 else m.upgrade_building(id),"paid upgrade for range")
 await advance(.4);await capture("E-specialized-L10-range")
 game.ui.close_context();await advance(.3);await buy("generator",Vector2(278,178));await world_click(r.tile_position(game.selected_tile));await advance(.4);await capture("F-room-wide-support")
 game.ui.close_context();await advance(.3)
 for tier in range(1,8):check(m.expansion.purchase(m),"paid expansion")
 game.focus_camera(true)
 for kind in ["flame","frost","shock","auto_repair","shield","decoy","repair","economy","enhancer","heavy","barrier","plasma","antenna","turret"]:
  check(m.place_building(kind,candidate(r,true)),"paid full room placement")
 check(r.buildings.size()==16,"actual full 16")
 for b_id in r.buildings:
  while r.buildings[b_id].level<10:
   check(m.specialize_building(b_id,StrategyCatalog.branches(r.buildings[b_id].kind)[0]) if r.buildings[b_id].level==4 else m.upgrade_building(b_id),"paid prestige full16")
 var selected=[]
 for b_id in r.buildings:
  # Select the rendered core, not decorative crowns or a neighbour's hitbox.
  game.ui.close_context();await advance(.23);await world_click(r.tile_position(b_id)+Vector2(0,-12));await advance(.23)
  check(game.selected_tile==b_id,"dense core select "+str(b_id));selected.append(game.selected_tile)
 var full_id=game.selected_tile;var full_position=r.tile_position(full_id)
 check(m.begin_building_move(full_id) and m.move_building(candidate(r)),"move at full prestige capacity")
 check(r.spatial.undo(m) and r.tile_position(full_id)==full_position,"undo at full prestige capacity")
 await capture("I-full16-selected")
 var before_wallet=Vector2(r.gold,r.electricity);var next_id=r.buildings.keys()[-1]
 check(not m.upgrade_building(next_id),"Level11 rejected at full capacity");check(m.sell_building(next_id),"sale at full capacity");check(m.place_building("turret",candidate(r,true)),"reuse sold floor at full capacity");check(m.upgrade_building(r.spatial.next_id-1),"upgrade replacement at full capacity")
 game.ui.close_context();game.focus_camera(true)
 var env=game.presentation.environment;env.night_seed=10;env.configure(m);await advance(.5);await capture("J1-night-seed10")
 env.night_seed=20;env.configure(m);await advance(.5);await capture("J2-night-seed20")
 var h=m.hunter;h.boss_policy.enabled=false;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=1;m.time=m.preparation+.1
 var hp=h.hp;var before_income=r.income_total;var before_power=r.generated_power
 pcm_start();var started=Time.get_ticks_usec();var previous=started
 while m.endless.phase=="combat" and m.running and Time.get_ticks_usec()-started<60000000:
  await process_frame;var now=Time.get_ticks_usec();var d=minf(.05,(now-previous)/1e6);frame_times.append((now-previous)/1000.0);previous=now;game._process(d)
  if h.hp<hp and not combat_captured:await capture("K-live-combat-720");combat_captured=true
 pcm_finish("N-live-combat-master")
 check(m.endless.phase=="intermission","actual full HP wave cleared by real shots")
 var data=m.wave_metrics.report();var damage=0.0
 for row in data.buildings.values():damage+=row.damage
 var reconciliation={"hunter_start_hp":hp,"hunter_end_hp":h.hp,"player_damage":data.total,"allied_damage":data.allied,"building_damage":damage,"other":data.other,"gold_income_delta":r.income_total-before_income,"gold_report":data.gold,"power_generated_delta":r.generated_power-before_power,"power_report":data.power,"selected_ids":selected,"metrics":data,"conditions":"Production Linux runtime; scripted input, prepared isolated wallet, paid full16 buildings, posed full-health Hunter; real wall-time ticks until normal wave clear."}
 check(absf(hp-h.hp-data.total-data.allied)<.001,"wave report reconciles all actual HP loss")
 check(absf(data.total-damage-data.other)<.001,"building attribution reconciles")
 save_data("reconciliation",reconciliation)
 if m.endless.phase=="intermission":
  game.ui.replay_ui.show_intermission();await advance(.5);await capture("G1-intermission-report-link")
  save_data("prepared-wave1-checkpoint",ReplaySnapshot.encode(m))
  SessionInterface.wave_report(game.ui);await advance(.5);await capture("G2-actual-wave-report")
 root.size=Vector2i(1920,1080);SessionInterface.settings(game.ui);await advance(.4);await capture("A-settings-1080")
 game.ui.show_match();game.focus_camera(true);await advance(.4);await capture("L-full16-gameplay-1080")
 if m.endless.phase=="intermission":
  check(m.continue_wave("power"),"actual next-wave transition for1080 combat");game.ui.show_match();game.focus_camera(true)
  m.time=m.preparation+.01;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=1
  await live(.8);await capture("L2-next-wave-live-1080")
 frame_times.sort();save_data("render-observations",{"checks":checks,"failures":failures,"linux_frame_ms_median":frame_times[frame_times.size()/2] if not frame_times.is_empty() else 0,"frames":frame_times.size(),"conditions":"Mesa llvmpipe Linux shared executor; wall-frame measurements include capture overhead; not native Windows benchmarks."})
 print("SESSION_RENDER_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
