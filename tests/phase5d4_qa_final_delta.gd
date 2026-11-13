extends "res://tests/phase5d4_qa_ui.gd"
var prefix="user://phase5d4-qa-final-delta-"+str(Time.get_ticks_usec())
func progression(p):return [p.xp,p.rm_cash,p.inventory.duplicate(true),p.pending_spins.duplicate(true),p.achievements.duplicate(true),p.campaign_records.duplicate(true),p.statistics.duplicate(true),p.replay.best_wave,p.replay.milestone_wave,p.replay.pity.duplicate(true),p.replay.cosmetics.duplicate(true)]
func unclaimed():
 var serial=0
 for map in MapCatalog.IDS:
  for mode in ["standard","hard","hell"]:
   serial+=1;var path=prefix+str(serial)+".json";var p=PlayerProfile.new(path);p.xp=777;p.rm_cash=321
   for id in ItemCatalog.IDS:p.inventory[id]=9
   p.item_loadout=[];p.pending_spins=[]
   check(p.save_profile() and p.load_profile() and not p.read_only,"fixture existing collection is normalized before terminal baseline")
   var entry=p.begin_endless(map,mode,251+serial);check(not entry.is_empty(),"real profile transaction begins unclaimed run "+map+mode)
   var m=MatchModel.new();check(m.configure_endless(map,mode,251+serial,entry.run_id,RankCatalog.bonuses(entry.equipped)),"actual unclaimed model matches registered run")
   var before=p._reward_snapshot();var permanent=progression(p);m.result="defeat"
   check(p.settle_endless(m).is_empty() and p._reward_snapshot()==before,"terminal string alone cannot settle an unclaimed run")
   m.result="";m.time=m.preparation+26;m.hunter.position=m.player_position
   m.tick(.001)
   check(m.player_room==-1 and m.player()==null and m.result=="defeat" and m.terminal_recorded and m.eliminations==1,"real lethal exposed contact without claimed room records one terminal elimination")
   check(m.rooms.all(func(r):return r.alive and r.owner!=0) and m.evolution.acquired.is_empty() and m.evolution.credited.is_empty(),"unclaimed contact invents no victim owner, dead room or evolution award")
   check(m.presentation_events.filter(func(ev):return ev.type in ["hunter_evolved","elimination"]).is_empty(),"unclaimed contact emits no fabricated room death/evolution presentation")
   for i in range(4):m.tick(.1)
   check(m.eliminations==1 and m.evolution.credited.is_empty(),"repeated terminal ticks cannot increment contact or farm evolution")
   p.path=prefix+"missing/no-directory.json";before=p._reward_snapshot()
   check(p.settle_endless(m).is_empty() and p._reward_snapshot()==before,"failed final save rolls back unclaimed settlement for safe retry")
   p.path=path;var award=p.settle_endless(m)
   check(not award.is_empty() and award.run_id==entry.run_id and award.completed==0 and award.rm_cash==0 and award.xp==0,"real unclaimed defeat closes exact run with zero payout")
   check(p.active_match.is_empty() and p.replay.checkpoint.is_empty() and p.resume_endless()==null,"unclaimed defeat leaves no stuck active or resumable checkpoint")
   check(progression(p)==permanent,"unclaimed contact grants no XP/cash/items/spins/achievements/records/pity/cosmetics")
   before=p._reward_snapshot();check(p.settle_endless(m).is_empty() and p._reward_snapshot()==before,"repeated same result cannot settle or claim rewards twice")
   var q=PlayerProfile.new(path);var loaded=q.load_profile()
   check(loaded and not q.read_only and q.active_match.is_empty() and Support.numeric_same(progression(q),permanent),"settled unclaimed defeat reloads durably with no payout")
   before=q._reward_snapshot();check(q.settle_endless(m).is_empty() and q._reward_snapshot()==before,"reload cannot replay stale terminal claim")
   var next=q.begin_endless(map,mode,501+serial);check(not next.is_empty() and next.run_id!=entry.run_id,"new run remains available with distinct identity")
   before=q._reward_snapshot();check(q.settle_endless(m).is_empty() and q._reward_snapshot()==before,"old terminal cannot close or pay against a newly registered run")
func preview():
 profile_path=prefix+"-ui.json";var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await settle()
 var disk=FileAccess.get_file_as_bytes(profile_path);var ui=game.ui.replay_ui
 for map in MapCatalog.IDS:
  for mode in ["standard","hard","hell"]:
   for archetype in StrategyCatalog.ARCHETYPE_IDS:
    ui.code_text=ChallengeCode.encode({"map":map,"difficulty":mode,"archetype":archetype,"seed":449,"preset":0,"gear":1})
    var text=ui.code_preview()
    check(text.contains(MapCatalog.map(map).title) and text.contains(StrategyCatalog.ARCHETYPES[archetype].name) and text.contains("55%HP") and not text.contains("55%%"),"actual dynamic preview formats literal percent and exact map/archetype safely")
 ui.show_codes();await settle()
 check(ui.notice_label.is_visible_in_tree() and ui.notice_label.text.contains("55%HP") and ui.notice_label.text.contains("ruleset 3"),"actual Challenge screen label displays formatted55% rules without formatting error")
 check(FileAccess.get_file_as_bytes(profile_path)==disk,"challenge preview never mutates permanent profile")
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
func run():
 unclaimed();await preview();Support.cleanup(prefix)
 print("PHASE5D4_QA_FINAL_DELTA_CHECKS=",checks," CONTACT_SCENARIOS=15 PREVIEW_CONFIGS=45 FAILURES=",failures)
 quit(1 if failures else 0)
