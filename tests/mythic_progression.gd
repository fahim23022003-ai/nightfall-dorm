extends SceneTree
# Independent Phase5A fixtures: direct state setup is not gameplay/balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://mythic-qa-"
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("MYTHIC QA: "+label)
func _initialize():
 prefix+=str(Time.get_ticks_usec())+"-"
 call_deferred("run")
func fresh():
 serial+=1
 return PlayerProfile.new(prefix+str(serial)+".json")
func raw(path,data):
 var f=FileAccess.open(path,FileAccess.WRITE)
 check(f!=null,"fixture writable")
 if f: f.store_string(JSON.stringify(data)); f.close()
func legacy(xp=3800):
 return {"version":1,"xp":xp,"next_match_id":8,"equipped":["first_aid"],"settings":{"music":0.23,"effects":0.45,"ambient":0.67,"muted":true,"fullscreen":false,"tutorial":false},"active_match":{},"last_award":{},"campaign":{"selected_stage":"stage_2","difficulty":"hell","records":{"stage_1":{"clears":3,"best_time":150.0,"best_damage":500.0,"best_xp":280,"difficulty":"hard","first_match_id":2}}}}
func model(mode="standard",outcome="victory",stage="",boosts=[]):
 var m=MatchModel.new()
 m.configure_match(mode,RankCatalog.bonuses(boosts))
 if stage!="": m.configure_stage(stage)
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 m.time=m.preparation+120
 m.player().occupied_seconds=120
 m.player().damage_dealt=1500
 m.player().door_damage_taken=500
 if outcome=="victory":
  m.hunter.state=HunterState.State.DEAD
  m.hunter.hp=0
 else:
  m.player().alive=false
 m.result=outcome
 return m
func cleanup():
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")): DirAccess.remove_absolute("user://"+file)
func run():
 check(RankCatalog.NAMES==["Bronze","Silver","Gold","Platinum","Diamond","Master","Mythic"],"seven ordered rank names")
 check(RankCatalog.PERKS.size()==6 and RankCatalog.MAX_EQUIPPED==1,"no new gameplay perks or slots")
 for i in range(RankCatalog.THRESHOLDS.size()):
  if i>0: check(RankCatalog.THRESHOLDS[i]>RankCatalog.THRESHOLDS[i-1],"strict threshold order")
  check(ResourceLoader.exists("res://assets/ranks/"+RankCatalog.NAMES[i].to_lower()+".svg"),"original badge exists")
 for xp in [0,250,700,1400,2400,3800,20000]:
  var p=fresh()
  var old=legacy(xp)
  old.equipped=[] if xp<3800 else ["first_aid"]
  raw(p.path,old)
  check(p.load_profile(),"legacy v1 loads "+str(xp))
  check(p.xp==xp,"migration preserves exact XP")
  check(p.equipped==old.equipped and p.settings.muted and is_equal_approx(p.settings.music,.23),"migration preserves loadout/settings")
  check(p.selected_stage=="stage_2" and p.selected_difficulty=="hell" and p.stage_record("stage_1").clears==3,"migration preserves campaign")
  check(p.rank_index()>=mini(5,RankCatalog.rank_for(xp)),"migration never demotes earned legacy ranks")
  check(p.save_profile(),"migrated save writes")
  var reloaded=PlayerProfile.new(p.path)
  check(reloaded.load_profile() and reloaded.xp==xp and reloaded.equipped==old.equipped,"migrated roundtrip")
  check(reloaded.stage_record("stage_1")==p.stage_record("stage_1"),"stage records stable roundtrip")
 # Fixed independent expected arithmetic:120+36+30+10=196 ordinary victory.
 for mode in ["standard","hard","hell"]:
  var win=model(mode)
  var points=RankCatalog.performance(win)
  var expected={"standard":196,"hard":245,"hell":294}[mode]
  check(points.total==expected,"fixed ordinary victory XP "+mode)
  for outcome in ["victory","defeat"]:
   var m=model(mode,outcome)
   var b=RankCatalog.performance(m)
   var sum=b.victory+b.survival+b.damage+b.defense+b.stage_bonus+b.reaper_bonus+b.difficulty_bonus+b.loss_adjustment+b.ceiling_adjustment
   check(sum==b.total,"breakdown exact integer sum "+mode+outcome)
   check(b.total is int,"integer total")
   if outcome=="defeat": check(b.total==4 and b.difficulty_bonus==0,"loss120seconds earns4, no mode bonus "+mode)
  var boss=model(mode,"victory","stage_5")
  boss.hunter.transformed=true
  var b=RankCatalog.performance(boss)
  check(b.stage_bonus==50 and b.reaper_bonus==40,"real stage and deadReaper bonuses")
  check(b.total=={"standard":286,"hard":357,"hell":429}[mode],"fixed bossstage XP "+mode)
  for seconds in [20,29,30,60,120,900,1800]:
   var loss=model(mode,"defeat")
   loss.time=loss.preparation+seconds
   loss.player().occupied_seconds=seconds
   loss.player().damage_dealt=1000000
   var partial=RankCatalog.performance(loss)
   check(partial.total<=mini(30,int(seconds/30.0)),"loss farm bounded by playedseconds "+mode+str(seconds))
   check(partial.difficulty_bonus==0,"loss never gains Hell multiplier")
 # Real settlement and persistence; no direct duplicate statistics mutation.
 var p=fresh()
 for mode in ["standard","hard","hell"]:
  var start=p.begin_match(mode)
  var m=model(mode)
  m.hunter.transformed=(mode=="hell")
  var previous=p.xp
  var award=p.settle_match(start.id,m)
  check(not award.is_empty() and award.old_xp==previous and award.new_xp==p.xp,"award snapshots exact XP")
  check(p.xp-previous==award.breakdown.total,"settlement delta equals breakdown")
  var stats=p.statistics.duplicate(true)
  check(p.settle_match(start.id,m).is_empty() and p.statistics==stats,"settlement duplicate no XP or stats")
 check(p.statistics.matches==3 and p.statistics.victories==3 and p.statistics.defeats==0,"only completed outcomes counted")
 check(p.statistics.standard==1 and p.statistics.hard==1 and p.statistics.hell==1 and p.statistics.reaper_defeats==1,"mode and Reaper counters exact")
 var began=p.begin_match("hell")
 check(p.statistics.matches==3,"restart/begin is not a completed match")
 var loss=model("hell","defeat")
 p.settle_match(began.id,loss)
 check(p.statistics.matches==4 and p.statistics.defeats==1 and p.statistics.reaper_defeats==1,"loss counts once without Reaper win")
 var reloaded=PlayerProfile.new(p.path)
 check(reloaded.load_profile() and reloaded.statistics==p.statistics,"statistics roundtrip exact")
 var early_profile=fresh()
 var early_id=early_profile.begin_match("hell").id
 var early=model("hell","defeat")
 early.time=early.preparation+5
 early.player().occupied_seconds=5
 var early_award=early_profile.settle_match(early_id,early)
 check(early_award.breakdown.total==0 and early_profile.statistics.defeats==1 and early_profile.statistics.matches==1,"legitimateearlydefeat counts once but yields zeroXP")
 check(early_profile.settle_match(early_id,early).is_empty(),"earlydefeat notdoublecounted")
 # Each Mythic gate independently blocks promotion, then all gates allow it.
 var gate=fresh()
 gate.xp=8000
 gate.campaign_records={"stage_5":{}}
 gate.statistics.hard=3
 gate.statistics.reaper_defeats=3
 check(gate.rank_index()==6,"all configured gates allow Mythic")
 gate.xp=7999
 check(gate.rank_index()==5,"one XP below Mythic blocks promotion")
 gate.xp=8000
 gate.statistics.hard=2
 check(gate.rank_index()==5,"insufficientadvancedwins blocks Mythic")
 gate.statistics.hard=3
 gate.statistics.reaper_defeats=2
 check(gate.rank_index()==5,"insufficientReaperwins blocks Mythic")
 gate.statistics.reaper_defeats=3
 gate.campaign_records={}
 check(gate.rank_index()==5,"missing finalstage blocks Mythic")
 check(RankCatalog.unlocked(8000)==RankCatalog.unlocked(3800),"Mythic introduces noexclusive gameplayperk")
 # XP threshold alone cannot bypass accomplishment gates.
 p=fresh()
 p.xp=8000
 check(p.rank_index()==5,"XPalone remains Master")
 for stage in StageCatalog.STAGES:
  var start=p.begin_match("hard",stage.id)
  var m=model("hard","victory",stage.id)
  m.hunter.transformed=true
  var report=p.settle_match(start.id,m)
  check(not report.is_empty(),"valid stage settlement "+stage.id)
  if stage.number<5: check(p.rank_index()==5,"stage5 gate remains until actualclear")
  else: check(p.rank_index()==6 and report.promoted and report.old_rank==5 and report.new_rank==6,"Mythic promotion once at accomplishment boundary")
 check(p.highest_rank==6 and p.statistics.hard==5 and p.statistics.reaper_defeats==5,"highest rank and accomplishments saved")
 reloaded=PlayerProfile.new(p.path)
 check(reloaded.load_profile() and reloaded.rank_index()==6,"Mythic persists after reload")
 var id=reloaded.begin_match("hard","stage_5").id
 var again=reloaded.settle_match(id,model("hard","victory","stage_5"))
 check(not again.promoted and again.old_rank==6 and again.new_rank==6,"Mythic promotion not repeatedly issued")
 # Failure leaves one in-memory pending generation; retry commits it once.
 p=fresh()
 var actual_path=p.path
 id=p.begin_match("hell").id
 p.path="user://nonexistent-mythic-qa-directory/blocked.json"
 var report=p.settle_match(id,model("hell"))
 check(not p.save_ok and not report.is_empty(),"settlement writefailure visible")
 var saved_xp=p.xp
 var saved_stats=p.statistics.duplicate(true)
 check(p.settle_match(id,model("hell")).is_empty() and p.xp==saved_xp and p.statistics==saved_stats,"retry settlement cannot duplicate pendinggeneration")
 p.path=actual_path
 check(p.save_profile(),"explicit write retry succeeds")
 reloaded=PlayerProfile.new(actual_path)
 check(reloaded.load_profile() and reloaded.xp==saved_xp and reloaded.statistics==saved_stats,"retried generation reloads exactlyonce")
 check(reloaded.settle_match(id,model("hell")).is_empty(),"reload rejects repeatedsettlement")
 # Optional damaged/newer subsection must not erase established legacy progress.
 for extra in [null,{},[1],{"version":99},{"version":1,"statistics":{"matches":-1},"highest_rank":6}]:
  p=fresh()
  var data=legacy()
  data.progression=extra
  raw(p.path,data)
  check(p.load_profile() and p.xp==3800 and p.rank_index()==5,"damaged optionalstats preserves known XP/rank")
  check(p.equipped==["first_aid"] and p.stage_record("stage_1").clears==3,"damaged optionalstats preserves perks/campaign")
 # Transparent diagnostic pacing, not human time estimates.
 print("MYTHIC_PACING ordinary_wins_to_8000=",ceili(8000.0/196)," stage5_normal_boss_wins=",ceili(8000.0/286)," stage5_hell_boss_wins=",ceili(8000.0/429)," loss_xp_per_minute_cap=2")
 cleanup()
 print("MYTHIC_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
