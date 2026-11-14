extends SceneTree
var checks=0
var failures=0
func check(ok,text):
 checks+=1
 if not ok:failures+=1;push_error(text)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome()
 check(game.new_balance_version==2,"exported actual Game defaults to new economy")
 check(RunChoices.CATALOG.size()==12,"all twelve new perks packaged")
 check(BalanceRules.price("generator",2)==Vector2(120,0) and BalanceRules.output("generator",1,2)==.6,"new power price/output packaged")
 check(BalanceRules.AMPLIFIER_LIMIT==3,"support budget packaged")
 check(game.start_endless("abandoned_dorm","standard",71),"actual exported Endless launches")
 var m=game.model;check(m.balance_version==2,"actual run uses balance2");check(m.claim_room(0),"actual room claim");m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
 check(r.gold==25 and r.electricity==0,"ordinary opening wallet")
 check(not m.buy("generator",0) and r.gold==25,"insufficient funds atomic")
 check(m.buy("turret",0) and r.gold==5,"ordinary exported Needle purchase")
 for i in range(600):m.tick(.1)
 check(r.alive and r.gold>80 and r.income_total>80,"actual delta-scaled ordinary production")
 check(m.choices.enabled(m),"run choice architecture integrated")
 check(BalanceRules.requirement("turret",9,3,3,2)!="","advanced infrastructure prerequisite packaged")
 check(BalanceRules.title(1).contains("LEGACY"),"legacy continuation label packaged")
 game.return_menu();check(game.start_practice("witch",false,["shield","repair"]),"preserved exported Practice")
 check(game.model.balance_version==2 and game.model.run_kind=="practice","Practice uses new economy with existing isolation")
 check(not game.model.choices.enabled(game.model),"merchant disabled outside Endless")
 game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout
 print("EARNED_EXPORTED_PACK_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED");quit(1 if failures else 0)
