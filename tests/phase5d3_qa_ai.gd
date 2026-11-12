extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("TACTICAL QA: "+label)
func _initialize():call_deferred("run")
func worker(args):
 var config={"map":MapCatalog.IDS[int(args[1])],"seed":743,"archetype":StrategyCatalog.ARCHETYPE_IDS[int(args[2])],"difficulty":["standard","hard","hell"][int(args[2])],"preset":0,"gear":0}
 var prefix="user://phase5d3-qa-codeworker-"+str(Time.get_ticks_usec())
 if args.size()>5:config.difficulty=["standard","hard","hell"][int(args[5])]
 var p=PlayerProfile.new(prefix+".json");p.xp=int(args[3]);p.equipped=["marksman","reaper_slayer"] if p.xp>0 else [];p.tutorial_completed=true;p.save_profile()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip()
 var code=ChallengeCode.encode(config)
 if not game.start_challenge(code):quit(1);return
 var m=game.model
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var trace=[]
 for i in range(5400):
  m.tick(ChallengeCode.FIXED_STEP)
  if i%30==0:trace.append([m.time,m.hunter.position.x,m.hunter.position.y,m.hunter.hp,m.hunter.target,m.hunter.state,m.hunter.ability_counts.duplicate(),m.player().gold,m.player().door_hp,str(m.random.state)])
  if m.result!="":break
 var data={"code":code,"boosts":m.match_boosts,"outcome":m.result,"trace":trace}
 var f=FileAccess.open(args[4],FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 preload("res://tests/replay_test_support.gd").cleanup(prefix)
 quit()
func charged_frequency():
 for mode in ["standard","hard","hell"]:
  var m=MatchModel.new();m.configure_stage("stage_1");m.configure_match(mode);m.configure_strategy(9,"crusher","");m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.preparation=0;m.bot_claimed=5
  var r=m.player();r.door_level=9;r.door_branch="bulwark";r.door_hp=r.max_hp()
  var h=m.hunter;h.boss_policy.enabled=false;h.target=0;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0;h.tactical_cooldown=1000
  var expected=3 if mode=="hell" else 4;var warn_time=-1.0;var nth=0;var last_event=0;var hit=false
  for i in range(500):
   var hp=r.door_hp;var attacks=h.encounter_attacks;m.tick(.05)
   for ev in m.presentation_events:
    if ev.id<=last_event:continue
    last_event=ev.id
    if ev.type=="charged_attack" and warn_time<0:warn_time=m.time;nth=h.encounter_attacks+1
   if warn_time>=0 and h.encounter_attacks>attacks:
    var multiplier=maxf(1.35,RankCatalog.pressure(mode).charged_scale)
    check(nth==expected,"CrusherchargedfrequencyNormal4Hard4Hell3 preserved "+mode)
    check(m.time-warn_time>=.899,"chargedattackwaitsactualreadablewindup "+mode)
    check(is_equal_approx(hp-r.door_hp,h.damage*multiplier*.9),"actualchargedhitusescorrectdamageanddoorarmor "+mode)
    hit=true;break
  check(hit,"chargedstrikeactuallylandsafterwarning "+mode)
func run():
 var args=OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="--worker":worker(args);return
 charged_frequency()
 var cases=[]
 for index in range(5):
  for ai in range(3):
   if "--ravager-only" in args and ai!=2:continue
   var archetype=StrategyCatalog.ARCHETYPE_IDS[ai];var mode=["standard","hard","hell"][(index+ai)%3]
   if "--final-ai" in args and not (archetype=="crusher" and mode=="hell"):continue
   var m=MatchModel.new();m.configure_stage("stage_1");m.configure_map(MapCatalog.IDS[index]);m.configure_match(mode);m.configure_strategy(71,archetype,"")
   m.preparation=0;m.hunter.boss_policy.enabled=false;m.bot_claimed=5
   # Declared tactical fixture: paid support and durable doors prevent an early
   # terminal while target changes are observed. This is not balance evidence.
   for r in m.rooms:
    r.owner=r.index;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position();r.strategy_enabled=true;r.bed_level=9;r.bed_branch="lucid";r.door_level=9;r.door_branch="bulwark";r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
    r.build("repair",0)
    for n in range(3):r.upgrade_building(0)
    r.specialize_building(0,"sustain")
    for n in range(5):r.upgrade_building(0)
    r.gold=0;r.income_multiplier=0
   m.player_room=0;m.player_position=m.player().bed_position()
   var h=m.hunter;var seen={};var warned={};var used={};var last_event=0;var charged=false;var combos=false
   for i in range(2000):
    var old=h.position;var old_attacks=h.encounter_attacks;m.tick(.1)
    check(m.hunter==h and m.navigation_walkable(h.position),"single actualHunter remains on legalmap geometry")
    check(h.position.distance_to(old)<=h.speed*.1+5,"no ability teleports beyond actual movement budget")
    if h.target>=0:seen[h.target]=true
    for ev in m.presentation_events:
     if ev.id<=last_event:continue
     last_event=ev.id
     if ev.type=="hunter_ability_warning":warned[ev.ability]=m.time
     if ev.type=="hunter_ability":used[ev.ability]=true;check(ev.ability=="feint" or (warned.has(ev.ability) and m.time-warned[ev.ability]>=.5),"actual activeabilityfollows visiblewindup")
     if ev.type=="charged_attack":charged=true
    if h.encounter_attacks>old_attacks and h.encounter_attacks%3==0 and h.cooldown>=h.interval+.7:combos=true
    if m.result!="":break
   check(seen.size()>1 and h.retargets>0,"fortifiedfailedsiegeschoosevalidalternative "+m.map_id+archetype)
   check(h.ability_counts.pressure>0 and charged if archetype=="crusher" else h.ability_counts.conceal>0 and h.ability_counts.feint>0 if archetype=="stalker" else h.ability_counts.dash>0 and combos,"two actual archetype behaviors execute "+archetype)
   var counts=h.ability_counts.duplicate();h.transformed=true;h.tick(.1,m)
   check(h.tactical_action=="" and h.pressure_remaining==0 and h.conceal_remaining==0 and h.dash_remaining==0 and h.ability_counts==counts,"Reaper clearsnormalabilities withoutduplicateactivation")
   cases.append({"map":m.map_id,"mode":mode,"archetype":archetype,"targets":seen.keys(),"abilities":counts,"attacks":h.attacks,"retargets":h.retargets})
 for index in [0,2,4]:
  var paths=[]
  for progressed in [0,10000]:
   var path=("res://docs/evidence/phase5d3/qa-code2-final-process-%d-%d.json" if "--final-ai" in args else "res://docs/evidence/phase5d3/qa-code2-process-%d-%d.json") % [index,progressed];paths.append(path)
   var output=[];var worker_args=["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/phase5d3_qa_ai.gd","--","--worker",str(index),str(index%3),str(progressed),path]
   if "--final-ai" in args:worker_args.append(str(2 if index==0 else 0 if index==2 else 1))
   var result=OS.execute(OS.get_executable_path(),worker_args,output,true)
   var f=FileAccess.open(path.replace(".json",".log"),FileAccess.WRITE);f.store_string("".join(output));f.close()
   check(result==0 and not "SCRIPT ERROR" in "".join(output) and not "ERROR:" in "".join(output),"freshenginecodedworker exitscleanly")
  check(FileAccess.get_file_as_bytes(paths[0])==FileAccess.get_file_as_bytes(paths[1]),"ruleset2fulltracesreproduceacrossfreshbeginner/progressedprocesses")
 var f=FileAccess.open("res://docs/evidence/phase5d3/qa-ai-final-cases.json" if "--final-ai" in args else "res://docs/evidence/phase5d3/qa-ai-ravager-final-cases.json" if "--ravager-only" in args else "res://docs/evidence/phase5d3/qa-ai-cases.json",FileAccess.WRITE);f.store_string(JSON.stringify(cases," "));f.close()
 print("PHASE5D3_TACTICAL_QA_CHECKS=",checks," MAP_ARCHETYPES=",cases.size()," FRESH_WORKERS=6 FAILURES=",failures)
 quit(1 if failures else 0)
