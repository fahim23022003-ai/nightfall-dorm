extends "res://tests/phase5d4_qa_evolution.gd"
const Support=preload("res://tests/replay_test_support.gd")
var prefix="user://phase5d4-qa-save-"+str(Time.get_ticks_usec())
func frozen():
 for name in ["qa-frozen-5d3-normal.json","qa-frozen-5d3-hell.json","qa-frozen-5d2.json"]:
  var path=prefix+name;DirAccess.copy_absolute("res://docs/evidence/phase5d4/"+name,path)
  var p=PlayerProfile.new(path);check(p.load_profile() and not p.read_only,"frozen old published profile loads writable "+name)
  var old=p.replay.checkpoint.duplicate(true);var stock=p.inventory.duplicate(true);var m=p.resume_endless()
  check(m!=null,"genuine old betweenwave save resumes "+name)
  if m==null:continue
  for i in range(6):
   var r=m.rooms[i];var prior=old.rooms[i]
   check(r.owner==prior.owner and r.alive==prior.alive and r.bed_level==prior.bed_level and r.door_level==prior.door_level and r.bed_branch==prior.get("bed_branch","") and r.door_branch==prior.get("door_branch",""),"old ownership/life/tier/exclusivebranch preserved")
   check(r.gold==prior.gold and r.electricity==prior.electricity,"old genuinely earned separate currencies preserved")
   for b in prior.buildings:
    var actual=r.buildings[int(b.tile)]
    check(actual.kind==b.kind and actual.level==b.level and actual.get("specialization","")==b.specialization and actual.invested_gold==b.invested_gold and actual.invested_power==b.invested_power,"old individual machine actualspend and branch preserved")
  check(m.evolution.acquired.is_empty() and m.evolution.credited.is_empty(),"old save gains no invented evolution/death credits")
  check(p.checkpoint_endless(m) and p.replay.checkpoint.ruleset==ChallengeCode.RULESET and ReplaySnapshot.valid(p.replay.checkpoint),"old migration writes valid advertised current ruleset through real transaction")
  var q=PlayerProfile.new(path);check(q.load_profile() and not q.read_only and q.inventory==stock and q.resume_endless()!=null,"migrated old save reload preserves inventory and resume "+name)
func replay_atomicity():
 var path=prefix+"-atomic.json";DirAccess.copy_absolute("res://docs/evidence/phase5d4/qa-frozen-5d3-hell.json",path)
 var p=PlayerProfile.new(path);p.load_profile();var m=p.resume_endless();check(m!=null,"atomicity old checkpoint starts")
 if m==null:return
 check(p.checkpoint_endless(m),"initial migrated checkpoint seals empty evolution ledger")
 var victim=-1
 for r in m.rooms:
  if r.owner>0 and r.alive:victim=r.index;break
 check(victim>=0,"genuine old checkpoint contains living teammate for replay test")
 if victim<0:return
 var old=p.replay.checkpoint.duplicate(true);var inventory=p.inventory.duplicate(true)
 check(m.continue_wave("repair"),"actual resumed run starts next combat wave")
 m.hunter.state=HunterState.State.MOVE;m.hunter.tick(0,m)
 check(kill(m,victim),"actual contact living-to-dead transition earns evolution midwave")
 check(m.evolution.credited.size()==1 and not m.rooms[victim].alive,"midwave death and buff are coupled in runtime")
 check(not p.checkpoint_endless(m) and Support.numeric_same(p.replay.checkpoint,old),"unsafe midwave checkpoint cannot bank buff independently")
 var q=PlayerProfile.new(path);check(q.load_profile(),"interrupted midwave profile reloads")
 var replay=q.resume_endless();check(replay!=null and replay.rooms[victim].alive and replay.evolution.credited.is_empty(),"midwave reload rewinds victim and evolution together")
 if replay!=null:
  check(replay.continue_wave("repair"),"replayed checkpoint continues once")
  replay.hunter.state=HunterState.State.MOVE;replay.hunter.tick(0,replay);check(kill(replay,victim),"replayed genuine kill can happen again")
  check(replay.evolution.acquired.size()==1 and replay.evolution.credited.size()==1,"replayed kill earns one buff rather than two banked rewards")
 # Controlled defeated-Hunter fixture exercises only between-wave atomic save,
 # not the legitimacy or difficulty of the wave victory itself.
 m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD;m.endless.finish_wave(m)
 check(p.checkpoint_endless(m),"completed checkpoint atomically saves dead victim and award")
 q=PlayerProfile.new(path);check(q.load_profile(),"completed profile reloads")
 replay=q.resume_endless()
 check(replay!=null and not replay.rooms[victim].alive and replay.evolution.credited.size()==1 and replay.evolution.acquired==m.evolution.acquired,"completed checkpoint preserves matching death/ledger/buff exactly")
 check(q.inventory==inventory,"death/evolution checkpoint replay never changes permanent items")
 var valid=q.replay.checkpoint
 for corruption in ["missing_ledger","alive_victim","wrong_owner","extra_buff"]:
  var bad=valid.duplicate(true)
  match corruption:
   "missing_ledger":bad.erase("evolution")
   "alive_victim":bad.rooms[victim].alive=true
   "wrong_owner":bad.evolution.credited={"owner:0":victim}
   "extra_buff":bad.evolution.acquired.append("blood_frenzy")
  check(not ReplaySnapshot.valid(bad),"current ruleset rejects stripping/mismatching kill ledger "+corruption)
func live_refractory():
 var p=PlayerProfile.new(prefix+"-cooldowns.json");var entry=p.begin_endless("cursed_mansion","hell",557)
 var m=MatchModel.new();check(m.configure_endless("cursed_mansion","hell",557,entry.id),"new current run configures")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5;m.time=50
 for r in m.rooms:
  if r.index==0:continue
  r.owner=r.index;r.profile=Catalog.BOT_PROFILES[r.index-1];r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 var r=m.player();r.gold=1000000;r.electricity=100000;r.bed_level=9;r.bed_branch="lucid";r.door_level=9;r.door_branch="renewal";r.door_hp=r.max_hp()*.3
 # A fresh Endless run now starts with three pads. Pay for the six-pad
 # tier before exercising all six old new-role machines; retain actual spend.
 var expansion_wallet=Vector2(r.gold,r.electricity)
 check(m.expansion.purchase(m) and r.tile_count()==6,"actual paid six-pad expansion permits six-machine checkpoint fixture")
 check(Vector2(r.gold,r.electricity).is_equal_approx(expansion_wallet-RoomExpansion.COSTS[1]),"fixture expansion deducts exact separate actual resources")
 p.bind_items(m,entry.id)
 var tile=0
 for kind in DefenseEffects.SPECIAL:
  check(m.buy(kind,tile),"actual new machine purchased "+kind)
  for i in range(3):check(m.upgrade_building(tile),"paid upgrade toward newbranch")
  check(m.specialize_building(tile,StrategyCatalog.branches(kind)[0]),"new role paid branch saves "+kind)
  for i in range(5):check(m.upgrade_building(tile),"paid new role advances to10")
  tile+=1
 m.hunter.state=HunterState.State.MOVE;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.tick(0,m);m.hunter.state=HunterState.State.MOVE
 m.defenses.tick(.01,m)
 print("QA_REAL_REFRACTORY shield=",m.defenses.shield_cooldowns," lure=",m.defenses.lure_cooldown," repair=",m.defenses.repair_cooldowns," hunter=",m.hunter.state," target=",m.hunter.target," health=",r.door_hp)
 check(is_equal_approx(m.defenses.shield_cooldowns.get("0",0),12) and is_equal_approx(m.defenses.lure_cooldown,19.5) and is_equal_approx(m.defenses.repair_cooldowns.get("0",0),3),"real operations establish shared shield/lure/repair refractory")
 var paid=[]
 for b in r.buildings.values():paid.append([b.kind,b.level,b.get("specialization",""),b.invested_gold,b.invested_power,b.cooldown])
 # Actual between-wave clear retains paid-operation refractory; long cooldowns
 # must serialize rather than disabling resume or resetting charge on rebuild.
 m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD;m.endless.finish_wave(m)
 var expected=[m.defenses.shield_cooldowns.duplicate(true),m.defenses.repair_cooldowns.duplicate(true),m.defenses.lure_cooldown]
 check(p.checkpoint_endless(m),"new L10 machines with actual12/24s cooldowns can checkpoint")
 var q=PlayerProfile.new(p.path);check(q.load_profile() and not q.read_only,"new machine profile reloads writable")
 var restored=q.resume_endless();check(restored!=null,"all new role saves resume")
 if restored!=null:
  var after=[]
  for b in restored.player().buildings.values():after.append([b.kind,b.level,b.get("specialization",""),b.invested_gold,b.invested_power,b.cooldown])
  check(Support.numeric_same(paid,after),"all six L10 branches actual investment and live cooldowns survive JSON")
  check(Support.numeric_same(expected,[restored.defenses.shield_cooldowns,restored.defenses.repair_cooldowns,restored.defenses.lure_cooldown]),"shared operation refractory persists exactly and cannot be reset by reload")
func archives():
 for ruleset in [1,2,3]:
  var body="NF2-%d-0-17-1-0-0-0" % ruleset;var code=body+"-"+body.sha256_text().left(8).to_upper()
  check(not ChallengeCode.decode(code).ok and ChallengeCode.decode(code,true).ok,"old challenge ruleset archived not silently played "+str(ruleset))
  var p=PlayerProfile.new(prefix+"-archive"+str(ruleset));p.replay.challenge_best[code.sha256_text().left(16)]={"code":code,"time":90.0,"score":123.0,"plays":2,"outcome":"victory"}
  check(p.save_profile(),"old code result remains savable")
  var q=PlayerProfile.new(p.path);check(q.load_profile() and not q.read_only and Support.numeric_same(p.replay.challenge_best,q.replay.challenge_best),"old historical result preserved writable")
func run():
 frozen();replay_atomicity();live_refractory();archives();Support.cleanup(prefix)
 print("PHASE5D4_QA_SAVE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
