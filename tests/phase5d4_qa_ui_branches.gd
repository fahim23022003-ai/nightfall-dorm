extends "res://tests/phase5d4_qa_ui.gd"
func run():
 profile_path="user://phase5d4-qa-ui-branches-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip();await settle()
 var permanent=Support.profile_signature(game.profile);var disk=FileAccess.get_file_as_bytes(profile_path);var scenarios=0
 for map in MapCatalog.IDS:
  game.start_practice("crusher",false,["repair","shield"],map);await settle();game.focus_camera(true)
  var r=game.model.player();r.gold=1000000;r.electricity=100000
  for kind in DefenseEffects.SPECIAL:
   for choice in range(2):
    var tile=next_pad();await pad(tile);await settle();game.ui.update_match();var card=game.ui.actions["build:"+kind]
    var gold=r.gold;var power=r.electricity;await click(card)
    check(r.buildings.has(tile) and r.buildings[tile].kind==kind,"actual newcard BUILD buys correctkind "+map+kind)
    check(is_equal_approx(gold-r.gold,Catalog.BUILDINGS[kind].gold) and is_equal_approx(power-r.electricity,Catalog.BUILDINGS[kind].power),"actual newcard charges correctseparatebasecost")
    for level in range(3):check(game.model.upgrade_building(tile),"paid branchfixture advances toL4")
    game.ui.refresh_context();game.ui.update_match();await settle();await click(game.ui.actions.upgrade);await settle()
    check(game.ui.context_mode=="specialize" and game.ui.branch_confirm.disabled,"newrole exclusive choice requires confirmation "+kind)
    var prior=state();var cam=camera();var branch_id=StrategyCatalog.branches(kind)[choice];var option=game.ui.specialization_items[choice+1]
    await click(option);await settle()
    check(state()==prior and camera()==cam,"newrole preview leaves allmodel/RNG/position/camera unchanged")
    check(game.ui.pending_branch==branch_id and option.icon!=null and option.text.contains("SELECTED"),"newrole chosenbranch has actual correctidentity/icon/selectedstate")
    check(option.text.contains("→") and not game.ui.branch_confirm.disabled,"newrole preview displays computed actualnumericchange")
    var untouched=state();var confirm_point=game.ui.branch_confirm.get_global_rect().get_center()
    await pointer(confirm_point,true);await key(KEY_ESCAPE);await pointer(confirm_point,false);await settle()
    check(state()==untouched and not game.ui.context_open,"held exclusive Confirm then Escape cancels without hidden paid branch "+kind+branch_id)
    await pad(tile);await click(game.ui.actions.upgrade);await click(game.ui.specialization_items[choice+1]);await settle()
    check(game.ui.pending_branch==branch_id and not game.ui.branch_confirm.disabled,"cancelled exclusive Confirm reopens cleanly without stuck input latch")
    var quote=Catalog.upgrade_cost(kind,4)+StrategyCatalog.BRANCH_FEE;gold=r.gold;power=r.electricity
    var at=game.ui.branch_confirm.get_global_rect().get_center();await point_click(at);await point_click(at,true);await settle()
    check(r.buildings[tile].level==5 and r.buildings[tile].specialization==branch_id,"doubleclick confirmednewbranch advancesexactlyonetier "+kind+branch_id)
    check(is_equal_approx(gold-r.gold,quote.x) and is_equal_approx(power-r.electricity,quote.y),"newbranch confirmed charged once includingfee")
    for level in range(5):check(game.model.upgrade_building(tile),"actual newbranch paid latelevel")
    game.ui.refresh_context();game.ui.update_match();await settle()
    check(game.ui.selected_details.text.contains("LEVEL 10") and game.ui.actions.upgrade.disabled,"actual newrole inspector displays correctL10 maximum")
    var refund=r.building_refund(tile);gold=r.gold;power=r.electricity;await click(game.ui.actions.sell);await settle()
    check(not r.buildings.has(tile) and is_equal_approx(r.gold-gold,refund.x) and is_equal_approx(r.electricity-power,refund.y),"actual newrole UI sell transfers50% eligibleinvestment and freespad")
    game.ui.close_context();await pad(tile);check(game.ui.context_mode=="build","same UI pad reopens reusableafternewrole sale")
    game.ui.close_context();scenarios+=1
  game.return_menu();await settle()
  check(Support.profile_signature(game.profile)==permanent and FileAccess.get_file_as_bytes(profile_path)==disk,"allnewrole UIactions preserve realpermanentprofile "+map)
 print("PHASE5D4_QA_NEWBRANCH_UI_CHECKS=",checks," SCENARIOS=",scenarios," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;Support.cleanup(profile_path);quit(1 if failures else 0)
