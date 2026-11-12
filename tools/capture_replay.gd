extends "res://tools/capture_visual_overhaul.gd"
# Isolated prepared production states; no natural-match or human-quality claim.
const REPLAY_BASELINE="d16a82da5baccdf5bcbe566635ee949c086c7a32"
func run():
 phase=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "before"
 output="res://docs/evidence/replay/render-screens/"
 if phase=="before" and FileAccess.file_exists(output+"before/01-menu-720.png"):
  push_error("Preserved replay baseline exists; refusing overwrite.");quit(1);return
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://replay-render-"+phase+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 game.profile.next_match_id=2;game.profile.xp=3800;game.profile.rm_cash=200
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.item_loadout=["barricade","time_freeze"];game.profile.equipped=["dreamer","first_aid"];game.profile.save_profile()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();await advance(.15);await capture("01-menu-"+suffix)
  var m=fixture("stage_1");m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.player().door_hp=m.player().max_hp()*.4
  await advance(.2);game.ui.items_ui.update(0);game.ui.update_match();await capture("02-gameplay-"+suffix)
  m.player().occupied_seconds=100;m.player().damage_dealt=2000;m.hunter.hp=0;m.tick(.01)
  check(m.result=="victory" and m.strategy.verified(m,game.profile.active_match),"prepared terminal sealed through actual model")
  game._process(.01);await advance(1.6);check(not game.profile.pending_spins.is_empty(),"actual saved victory spin")
  game.ui.items_ui.spin();await capture("03-victory-spin-"+suffix)
  check(not game.profile.claim_spin(game.match_id).is_empty(),"claim actual saved spin");game.return_menu()
 print("REPLAY_RENDER_CHECKS=",checks," FAILURES=",failures," BASELINE=",REPLAY_BASELINE)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
