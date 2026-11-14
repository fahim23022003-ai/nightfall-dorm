extends "res://tools/capture_first_night.gd"
var policy=preload("res://tools/phase12_test_policy.gd").new()
func layout():
 game.focus_camera(true);game.ui.update_match();game.guidance.refresh(game);game.presentation.reset()
 for i in range(10):game.presentation.update(.05,game.model)
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
func run():
 output="res://docs/evidence/earned-power/screens/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));root.size=Vector2i(1280,720)
 var p=PlayerProfile.new("user://phase12-render-"+str(Time.get_ticks_usec())+".json");p.complete_tutorial();OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();await process_frame
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.size=Vector2(1240,15);label.add_theme_font_size_override("font_size",11);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 for version in [1,2]:
  game.new_balance_version=version;game.return_menu();check(game.start_endless("abandoned_dorm","standard",71),"actual versioned run")
  var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();policy.balance=version
  var decision=0.0
  for target in [0,60,180,300]:
   while m.time+.00001<target and m.result=="":
    if m.endless.phase=="intermission":m.continue_wave("repair")
    if m.time>=decision:policy.act(m,"balanced");decision+=1
    m.tick(.1)
   game.ui.show_match();await layout();tell("MATCHED QA · seed71 · "+BalanceRules.title(version)+" · t="+str(roundi(m.time))+"s · fresh25G /0E, paid scripted policy")
   await capture(("before" if version==1 else "after")+"-fresh-"+str(target))
   if version==2 and target==60:
    await key(KEY_B);await wait(.4);game.ui.update_match();await capture("new-economy-decision");await key(KEY_ESCAPE);await wait(.3)
  if version==2:
   # Restart the same fresh seed and stop at the FIRST draft; no skipped milestone.
   game.return_menu();game.start_endless("abandoned_dorm","standard",71);m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();decision=0
   while m.endless.phase=="combat" and m.result=="" and m.time<600:
    if m.time>=decision:policy.act(m,"balanced");decision+=1
    m.tick(.1)
   if m.endless.phase=="intermission":
    game.ui.show_match();await layout();tell("ACTUAL FIRST CLEAR · fresh v2 seed71 · t=%ds · paid policy, no injected resources" % roundi(m.time));check(game.profile.checkpoint_endless(m),"actual run choice checkpoint")
    game.ui.replay_ui.intermission_saved=true;game.ui.replay_ui.show_intermission();await wait(.3);await capture("intermission-v2")
    await click(find_button("Run perks / merchant"));await wait(.4);await capture("perk-and-merchant-720")
    root.size=Vector2i(1920,1080);await wait(.4);await capture("perk-and-merchant-1080");root.size=Vector2i(1280,720)
    if not m.choices.draft.is_empty():
     var choice=m.choices.draft[0];await click(find_button("Choose · "+RunChoices.CATALOG[choice].name));await wait(.3);await capture("perk-selected")
 # Prepared high-tier composition tests visual bounds only; never progression evidence.
 game.return_menu();game.new_balance_version=2;game.start_endless("abandoned_dorm","standard",71);var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
 r.gold=1000000;r.electricity=1000000;r.bed_level=9;r.door_level=9;r.bed_branch="lucid";r.door_branch="bulwark";r.door_hp=r.max_hp()
 for tier in range(1,8):check(m.expansion.purchase(m),"paid prepared geometry expansion")
 var kinds=Catalog.BUILDINGS.keys();kinds.append("turret")
 for kind in kinds:
  var i=r.buildings.size();check(m.place_building(kind,r.fixed_tile_position(i)+Vector2(3,-1)),"prepared paid "+kind);var id=r.spatial.next_id-1
  while r.buildings[id].level<10:check(m.specialize_building(id,StrategyCatalog.branches(kind)[0]) if r.buildings[id].level==4 else m.upgrade_building(id),"prepared paid machine tier")
 m.choices.selected=["ledger","cadence","mixed","workshop"];m.choices.apply(m);game.ui.show_match();await layout();tell("PREPARED UI STRESS · newv2 /16 paid L10 buildings · test budget, NOT fresh progression evidence")
 await capture("crowded-16-720");await key(KEY_K);await wait(.3);await capture("active-perks-supplies");await key(KEY_K)
 root.size=Vector2i(1920,1080);await layout();await capture("crowded-16-1080")
 print("EARNED_POWER_RENDER_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
