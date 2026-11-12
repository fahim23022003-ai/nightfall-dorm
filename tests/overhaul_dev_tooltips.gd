extends SceneTree
var checks=0
var failures=0
func check(value,label):
 checks+=1
 if not value:failures+=1;push_error("TOOLTIP "+label)
func _initialize():call_deferred("run")
func run():
 preload("res://tests/onboarding_test_support.gd").prepare()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.skip();await process_frame
 game.start_practice("witch",false,["shield","repair"],"abandoned_dorm");await process_frame
 for enabled in [true,false]:
  game.model.strategy.enabled=enabled;game.model.evolution.acquired.clear();game.ui.update_match()
  var initial=game.ui.hunter_label.tooltip_text
  for i in range(1000):
   game.ui.update_match();check(game.ui.hunter_label.tooltip_text==initial,"bounded text with strategy "+str(enabled))
  check(initial.length()<1200 and initial.count("Damage: Physical")==1,"one rules explanation")
 var code=ChallengeCode.encode({"map":"abandoned_dorm","seed":17,"archetype":"witch","difficulty":"standard","preset":0,"gear":0})
 game.ui.replay_ui.code_text=code;var preview=game.ui.replay_ui.code_preview()
 check(("ruleset %d" % ChallengeCode.RULESET) in preview and "55%HP" in preview,"actual current ruleset and percentage")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await process_frame
 print("OVERHAUL_TOOLTIP_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
