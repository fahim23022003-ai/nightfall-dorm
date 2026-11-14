extends "res://tools/capture_earned_power.gd"
var evidence=[]
func scenario(seed_value,style):
 var m=MatchModel.new();m.reset(seed_value);m.configure_stage("stage_1");m.configure_match("hell");m.configure_strategy(seed_value);m.configure_balance(2);m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 game.model=m;game.mode="match";game.last_progression={};policy=preload("res://tools/phase12b_policy.gd").new();policy.balance=2;policy.style=style;game.ui.show_match();game.audio_system.reset_match(m)
 return m
func run():
 output="res://docs/evidence/fair-difficulty/screens/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));root.size=Vector2i(1280,720)
 var p=PlayerProfile.new("user://phase12b-render-"+str(Time.get_ticks_usec())+".json");p.complete_tutorial();OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();await process_frame
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.size=Vector2(1240,15);label.add_theme_font_size_override("font_size",11);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 for seed_value in [1,2]:
  var m=scenario(seed_value,"bulwark");var decision=0.0;var counter=false;var recovery=false
  while m.time<600 and m.result=="":
   if not recovery and m.hunter.target==0 and m.hunter.recovery_remaining>0:
    await layout();tell("FRESH HELL · seed%d · t=%.1fs · actual charged recovery · accelerated paid-policy QA, not human" % [seed_value,m.time]);await capture("recovery-seed%d-720" % seed_value);root.size=Vector2i(1920,1080);await layout();await capture("recovery-seed%d-1080" % seed_value);root.size=Vector2i(1280,720);recovery=true
   if m.time>=decision:
    var r=m.player();var critical=not counter and r.door_hp>0 and r.door_hp<r.max_hp()*.5 and r.gold>=r.manual_repair_cost()
    if critical:await layout();tell("FRESH HELL · seed%d · t=%.1fs · BEFORE paid response, actual available budget" % [seed_value,m.time]);await capture("counter-seed%d-before" % seed_value)
    var old=[r.gold,r.door_hp];policy.act(m,"balanced");decision+=1
    if critical:
     check(r.door_hp>old[1] and r.gold<old[0],"actual paid response increases door HP");await layout();tell("SAME RUN · t=%.1fs · response +%.1f HP / -%.1fG · whole outcome still determined by combat" % [m.time,r.door_hp-old[1],old[0]-r.gold]);await capture("counter-seed%d-after" % seed_value);counter=true
   m.tick(.1)
  check(m.result==("victory" if seed_value==1 else "defeat"),"actual final expected outcome, no manual kill or damage")
  if m.result=="victory":
   await layout();tell("ACTUAL HELL VICTORY · fresh seed1 · %.1fs · model policy, accelerated; no injected resources/HP" % m.time);await capture("hell-victory-720")
  else:
   check(not m.defeat_facts.report.is_empty() and not m.defeat_facts.report.counter_window.is_empty(),"real defeat has a pre-breach factual window")
   game.ui.replay_ui.show_defeat_analysis();await wait(.4);tell("ACTUAL DEFEAT · fresh Hell seed2 · %.1fs · real recorded window; no claim a single counter guaranteed survival" % m.time);await capture("defeat-analysis-720");root.size=Vector2i(1920,1080);await wait(.4);await capture("defeat-analysis-1080");root.size=Vector2i(1280,720)
  evidence.append({"seed":seed_value,"result":m.result,"time":m.time,"report":m.defeat_facts.report,"flows":m.player().ledger.totals})
 # Prepared inspector-state QA only. Real purchase; budget/HP setup explicitly labelled.
 var m=scenario(1,"bulwark");var r=m.player();r.gold=1000;r.electricity=100;m.buy("repair",9);r.door_hp=r.max_hp()*.6;r.electricity=2;game.selected_tile=9;game.ui.open_context();game.ui.context_mode="upgrade";game.ui.refresh_context();await layout();tell("PREPARED INSPECTOR QA · explicit test budget/HP · insufficient repair reserve · not earned progression");await capture("repair-reserve-inspector-720")
 var f=FileAccess.open("res://docs/evidence/fair-difficulty/render-scenarios.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"scenarios":evidence}," "))
 print("FAIR_RENDER_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
