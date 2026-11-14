extends "res://tools/capture_earned_power.gd"
func run():
 output="res://docs/evidence/earned-power/screens/";root.size=Vector2i(1280,720)
 var p=PlayerProfile.new("user://phase12-pressure-render-"+str(Time.get_ticks_usec())+".json");p.complete_tutorial();OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();await process_frame
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.size=Vector2(1240,15);label.add_theme_font_size_override("font_size",11);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 game.start_endless("abandoned_dorm","hell",1);var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();policy=preload("res://tools/phase12_counter_policy.gd").new();policy.balance=2
 var decision=0.0;var recorded=false;var before={};var after={}
 while m.time<600 and m.result=="":
  if m.endless.phase=="intermission":m.continue_wave("repair")
  var r=m.player()
  if not recorded and m.hunter.state==HunterState.State.ATTACK and m.hunter.target==r.index and r.door_hp<r.max_hp()*.65 and r.gold>=r.manual_repair_cost() and r.door_hp>0:
   before={"time":m.time,"gold":r.gold,"hp":r.door_hp,"max_hp":r.max_hp(),"hunter_hp":m.hunter.hp,"flows":r.ledger.totals.duplicate(true)}
   game.ui.show_match();await layout();tell("FRESH HELL · seed1 · t=%ds · paid defensive model policy; no injected funds/HP · BEFORE manual repair" % roundi(m.time));await capture("pressure-before-counter")
   check(m.repair_door(),"actual paid repair succeeds under genuine attack");check(r.door_hp>before.hp and r.gold<before.gold,"repair restores HP and spends actual Gold")
   after={"time":m.time,"gold":r.gold,"hp":r.door_hp,"max_hp":r.max_hp(),"flows":r.ledger.totals.duplicate(true)}
   await layout();tell("SAME FRESH RUN · t=%ds · real manual repair: +%.1f HP / -%.1f Gold · fast simulation, not human playtest" % [roundi(m.time),r.door_hp-before.hp,before.gold-r.gold]);await capture("pressure-successful-counter");recorded=true;break
  if m.time>=decision:policy.act(m,"defense");decision+=1
  m.tick(.1)
 check(recorded,"fresh Hell encountered meaningful attack and affordable repair")
 var f=FileAccess.open("res://docs/evidence/earned-power/pressure-counter.json",FileAccess.WRITE);f.store_string(JSON.stringify({"before":before,"after":after,"checks":checks,"failures":failures,"scenario":"Actual fresh Hell seed1, 25G/0E, production-code defensive policy at 1 decision/s, accelerated model ticks/frozen rendered frames; no wallet/HP/position edits except ordinary automatic room claim/sleep at t0. Not human play."}," "))
 print("EARNED_PRESSURE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
