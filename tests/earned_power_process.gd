extends "res://tests/onboarding_flow.gd"
var path="user://phase12-process-journal.json"
func run():
 var args=OS.get_cmdline_user_args();var stage=args[0] if not args.is_empty() else "read"
 if stage=="cleanup":
  for suffix in ["",".bak",".tmp"]:if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
  print("EARNED_PROCESS_CLEANUP");quit();return
 if stage=="write":
  var p=PlayerProfile.new(path);p.complete_tutorial();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
  game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();await process_frame
  game.start_endless("abandoned_dorm","standard",71);var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
  r.gold=10000;r.electricity=1000;m.buy("turret",0);m.time=m.preparation+.1;m.hunter.hp=1;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=99;m.hunter.boss_policy.enabled=false
  for i in range(100):
   m.tick(.1)
   if m.endless.phase=="intermission":break
  check(game.profile.checkpoint_endless(m),"real safe checkpoint")
  var row=m.choices.offers.filter(func(o):return o.id in ["shield","barricade","pillow"])[0]
  check(game.run_transaction("buy",row.id),"saved limited offer paid")
  check(game.continue_endless("repair"),"real continue")
  check(game.use_run_stock(row.id),"actual existing effect after durable stock debit")
  check(int(game.profile.active_match.temporary_used[row.id])==1,"durable activation journal")
  await dispose()
 else:
  var p=PlayerProfile.new(path);check(p.load_profile(),"separate process reads persisted profile")
  var m=p.resume_endless();check(m!=null and m.balance_version==2,"separate process resumes versioned checkpoint")
  if m!=null:
   for id in p.active_match.temporary_used:check(int(m.choices.stock.get(id,0))==0 and int(m.choices.used[id])==1,"process restart cannot duplicate consumed supply")
   check(p.inventory.is_empty() and p.xp==0 and p.rm_cash==0,"temporary merchant has no permanent rewards")
 print("EARNED_PROCESS_",stage," CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
