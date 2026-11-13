extends "res://tests/phase5d4_qa_evolution.gd"
const Support=preload("res://tests/replay_test_support.gd")
func policy(m):
 var r=m.player()
 if r==null or not r.alive:return
 if r.door_hp>0 and r.door_hp<r.max_hp()*.65:m.repair_door()
 if r.bed_level<3 and m.upgrade_bed():return
 if r.door_level<3 and m.upgrade_door():return
 var have={}
 for b in r.buildings.values():have[b.kind]=true
 for kind in ["generator","turret","flame","frost","shock","repair"]:
  if have.has(kind):continue
  for tile in range(r.tile_count()):
   if not r.buildings.has(tile) and m.buy(kind,tile):return
 for tile in r.buildings:
  var b=r.buildings[tile]
  if b.level<4 and m.upgrade_building(tile):return
 if r.bed_level<4:m.upgrade_bed()
 if r.door_level<4:m.upgrade_door()
func worker(args):
 var index=int(args[1]);var progressed=int(args[2]);var path=args[3]
 var config={"map":MapCatalog.IDS[index],"seed":713+index,"archetype":StrategyCatalog.ARCHETYPE_IDS[index%3],"difficulty":"hell","preset":0,"gear":1}
 var prefix="user://phase5d4-qa-challenge-worker-"+str(Time.get_ticks_usec())
 var p=PlayerProfile.new(prefix+".json");p.xp=progressed;p.rm_cash=900 if progressed>0 else 0;p.equipped=["marksman","reaper_slayer"] if progressed>0 else [];p.tutorial_completed=true
 for id in ItemCatalog.IDS:p.inventory[id]=900 if progressed>0 else 1
 p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip()
 var code=ChallengeCode.encode(config)
 if not game.start_challenge(code):quit(1);return
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var trace=[];var seen={};var types={};var last_event=0;var elapsed=0;var max_routes=0;var max_minions=0
 for i in range(9000):
  if i%15==0:policy(m)
  m.tick(ChallengeCode.FIXED_STEP);elapsed=i
  max_routes=maxi(max_routes,m._navigation_routes.size());max_minions=maxi(max_minions,m.minions.size())
  for ev in m.presentation_events:
   if ev.id<=last_event:continue
   last_event=ev.id;types[ev.type]=int(types.get(ev.type,0))+1
   if ev.type=="boss_ability_activate":seen[ev.ability]=int(seen.get(ev.ability,0))+1
  if i%30==0:
   var undead=[]
   for u in m.minions:undead.append([u.id,u.slot,u.hp,u.position.x,u.position.y,u.target])
   trace.append([m.time,m.hunter.position.x,m.hunter.position.y,m.hunter.hp,m.hunter.target,m.hunter.state,m.hunter.transformed,m.wrath.phase,m.wrath.ability,m.wrath.domain_room,m.wrath.domain_remaining,m.evolution.snapshot(),undead,m.player().gold,m.player().electricity,m.player().door_hp,str(m.random.state)])
  if m.result!="":break
 var data={"code":code,"boosts":m.match_boosts,"gear":game.temporary_loadout.item_loadout,"outcome":m.result,"elapsed_frames":elapsed,"events":types,"abilities":seen,"max_minions":max_minions,"max_routes":max_routes,"trace":trace}
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;Support.cleanup(prefix);quit()
func run():
 var args=OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="--worker":worker(args);return
 check(ChallengeCode.RULESET==4,"actual typed combat advertises ruleset4")
 var runs=[]
 for index in [0,2,4]:
  var paths=[]
  for progressed in [0,20000]:
   var path="res://docs/evidence/gameplay-overhaul/final-affected/qa-code-current-%d-%d.json" % [index,progressed];paths.append(path)
   var output=[];var result=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/phase5d4_qa_challenge.gd","--","--worker",str(index),str(progressed),path],output,true)
   var f=FileAccess.open(path.replace(".json",".log"),FileAccess.WRITE);f.store_string("".join(output));f.close()
   check(result==0 and not "SCRIPT ERROR" in "".join(output) and not "ERROR:" in "".join(output),"fresh actual scene challenge worker exits cleanly")
  check(FileAccess.get_file_as_bytes(paths[0])==FileAccess.get_file_as_bytes(paths[1]),"current-ruleset full engine traces identical across fresh beginner/progressed profiles")
  var data=JSON.parse_string(FileAccess.get_file_as_string(paths[0]));runs.append({"map":MapCatalog.IDS[index],"outcome":data.outcome,"events":data.events,"abilities":data.abilities,"frames":data.elapsed_frames,"max_minions":data.max_minions,"max_routes":data.max_routes})
  check(data.code.begins_with("NF2-%d-" % ChallengeCode.RULESET) and data.trace.size()>10,"test uses actual current-ruleset extended gameplay, not seed-only function")
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/final-affected/qa-code-current-summary.json",FileAccess.WRITE);f.store_string(JSON.stringify(runs," "));f.close()
 print("PHASE5D4_QA_CHALLENGE_CHECKS=",checks," FRESH_WORKERS=6 FAILURES=",failures)
 quit(1 if failures else 0)
