extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
var checks=0
var failures=0
var path="user://phase5d3-qa-migrate-"+str(Time.get_ticks_usec())+".json"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("MIGRATION QA: "+label)
func run():
 DirAccess.copy_absolute("res://docs/evidence/phase5d3/qa-pre5d3-endless-profile.json",path)
 var p=PlayerProfile.new(path);check(p.load_profile() and not p.read_only,"genuine oldJSONfloat ruleset1 profile safely loads writable")
 var original_inventory=p.inventory.duplicate(true);var original=p.replay.checkpoint.duplicate(true)
 var m=p.resume_endless();check(m!=null,"old betweenwave checkpoint resumes")
 if m==null:quit(1);return
 var r=m.player();var oldroom=original.rooms[int(original.player_room)]
 check(r.bed_level==4 and r.door_level==4 and r.bed_branch=="" and r.door_branch=="","legacy structuralL5 preserved withoutinventedbranches")
 check(r.gold==oldroom.gold and r.electricity==oldroom.electricity and r.income_total==oldroom.income_total,"genuine earned wallet/cumulativeincome preserved")
 for old in oldroom.buildings:
  var b=r.buildings[int(old.tile)]
  check(b.level==old.level and b.kind==old.kind and b.get("specialization","")==old.specialization and b.invested_gold==old.invested_gold and b.invested_power==old.invested_power,"all existing actualinvestment/weapon/supporttiers preserved")
 # The genuine early Arc10 checkpoint has only34.82E. A real50% sale
 # funds the new decisions; do not inject currency or farm frozen intermission.
 check(m.sell_building(6),"actual legacy Arc10 sale supplies legal discounted-investment refund forpreparation")
 check(r.specialize_structure("bed","conductor") and r.specialize_structure("door","renewal"),"legacy L5 structures use realownedcurrency fornewchoices")
 for tile in r.buildings:
  var b=r.buildings[tile]
  if b.kind in ["generator","repair","economy","enhancer"] and b.level==4:
   check(m.specialize_building(tile,StrategyCatalog.branches(b.kind)[0]),"existing support4 advanceswithnewpaidbranch "+b.kind)
 check(p.checkpoint_endless(m),"new branching state saves through realcheckpoint transaction")
 check(p.replay.checkpoint.ruleset==2 and ReplaySnapshot.valid(p.replay.checkpoint),"new savesupgrade onlyruleset markerandvalidbranchdata")
 var after=JSON.parse_string(JSON.stringify(ReplaySnapshot.encode(m,p.active_match.use_counts)))
 var q=PlayerProfile.new(path);check(q.load_profile() and not q.read_only,"newbranch profile reloads writable")
 var restored=q.resume_endless();check(restored!=null,"newstructural/support branches resume")
 if restored!=null:
  var roundtrip=JSON.parse_string(JSON.stringify(ReplaySnapshot.encode(restored,q.active_match.use_counts)))
  check(Support.numeric_same(after,roundtrip),"every persisted numeric/branch/paidstate matches afterreload")
 check(q.inventory==original_inventory,"migration/checkpointneverduplicatesorconsumespermanentstock")
 var valid=q.replay.checkpoint
 for edit in ["invalid_bed","early_bed","level11","wrong_machine","missing_machine","overrefund"]:
  var bad=valid.duplicate(true);var room=bad.rooms[int(bad.player_room)]
  match edit:
   "invalid_bed":room.bed_branch="missing"
   "early_bed":room.bed_level=3
   "level11":room.bed_level=10
   "wrong_machine":room.buildings[0].specialization="precision"
   "missing_machine":room.buildings[0].specialization=""
   "overrefund":room.buildings[0].invested_gold=1000000000
  check(not ReplaySnapshot.valid(bad),"malformedbranch/level/accountingcheckpoint rejected "+edit)
 var body="NF2-1-0-17-1-0-0-0";var oldcode=body+"-"+body.sha256_text().left(8).to_upper()
 check(not ChallengeCode.decode(oldcode).ok and ChallengeCode.decode(oldcode,true).ok,"oldchallenge manifestis archivalonly, never silentlyplayedundernewcombat")
 q.replay.challenge_best[oldcode.sha256_text().left(16)]={"code":oldcode,"time":90.0,"score":123.0,"plays":2,"outcome":"victory"}
 check(q.save_profile(),"oldvalidchallengepersonalrecords remainpreservable")
 var oldrecord=q.replay.challenge_best.duplicate(true);var z=PlayerProfile.new(path)
 check(z.load_profile() and not z.read_only and Support.numeric_same(z.replay.challenge_best,oldrecord),"archivalrecorddoesnotlockorcorruptcurrentprofile")
 # Actual permanent consumable activation combines with the actual door branch.
 var pp=PlayerProfile.new(path+"-combat");pp.inventory.barricade=1;pp.inventory.shield=1;pp.item_loadout=["barricade","shield"]
 var entry=pp.begin_match("standard");var mm=MatchModel.new();mm.configure_match("standard");mm.configure_stage("stage_1");mm.configure_strategy(0,"crusher","",entry.id);mm.claim_room(0);mm.player_position=mm.player().bed_position();mm.sleep_player();mm.time=mm.preparation+1;mm.bot_claimed=5
 var rr=mm.player();rr.gold=100000;rr.electricity=10000;rr.bed_level=4;rr.door_level=4;rr.door_hp=rr.max_hp();pp.bind_items(mm,entry.id)
 check(rr.specialize_structure("door","bulwark") and pp.activate_item(0,mm,entry.id),"actual Bulwark andpaidstockBarricadeactivate")
 var hp=rr.door_hp;mm.hunter.target=0;mm.hunter._damage_door(rr,mm,100)
 check(is_equal_approx(hp-rr.door_hp,67.5) and pp.inventory.barricade==0,"actual combat mitigationstacks multiplicatively, chargesoneitem")
 mm.items.tick(2,mm);check(pp.activate_item(1,mm,entry.id),"actual shieldstockactivatesaftersharedcooldown")
 hp=rr.door_hp;var shield=mm.items.shield_hp;mm.hunter._damage_door(rr,mm,100)
 check(rr.door_hp==hp and is_equal_approx(shield-mm.items.shield_hp,67.5) and pp.inventory.shield==0,"shield absorbsactualmitigateddamagewithfinitecapacityandcorrectstock")
 Support.cleanup(path)
 print("PHASE5D3_MIGRATION_QA_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
