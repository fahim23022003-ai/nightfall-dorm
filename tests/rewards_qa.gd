extends SceneTree
# Independent deterministic fixtures; direct setup is not natural-match balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://rewards-qa-"
func _initialize():prefix+=str(Time.get_ticks_usec())+"-";call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REWARDS QA: "+label)
func fresh():
 serial+=1
 return PlayerProfile.new(prefix+str(serial)+".json")
func fixture(mode="standard",stage="",perks=[]):
 var m=MatchModel.new()
 m.configure_match(mode,RankCatalog.bonuses(perks))
 if stage!="":m.configure_stage(stage)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+120;m.bot_claimed=5
 var r=m.player();r.occupied_seconds=120;r.damage_dealt=1500;r.door_damage_taken=500
 return m
func victory(m):m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD;m.result="victory"
func defeat(m):m.player().alive=false;m.player().sleeping=false;m.result="defeat"
func pair(p,mode="standard",stage=""):
 var entry=p.begin_match(mode,stage)
 var m=fixture(mode,stage,p.equipped)
 p.bind_items(m,entry.get("id",0))
 return {"p":p,"entry":entry,"m":m}
func cleanup():
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
func record(id):
 return {"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"hell","first_match_id":1}
func prove_mythic(p):
 p.xp=8000;p.statistics.matches=3;p.statistics.victories=3;p.statistics.hard=3;p.statistics.reaper_defeats=3
 p.next_match_id=4
 for stage in StageCatalog.STAGES:p.campaign_records[stage.id]=record(stage.id)
func run():
 check(RankCatalog.NAMES.size()==7,"seven ranks preserved")
 check(ItemCatalog.IDS.size()==20 and ItemCatalog.SLOTS==2,"20items/two consumables preserved")
 check(RankCatalog.PERKS.size()==7,"six oldperks plus unique Mythic")
 for level in range(7):
  var p=fresh();p.xp=RankCatalog.THRESHOLDS[level]
  if level==6:prove_mythic(p)
  check(p.rank_index()==level,"rank boundary "+str(level))
  check(p.perk_slots()==(2 if level>=5 else 1),"slotlimit "+str(level))
  for perk in RankCatalog.PERKS:
   check((perk.id in p.unlocked())==(perk.rank<=level),"effectiveunlock "+str(level)+perk.id)
   if perk.rank>level:check(not p.equip(perk.id),"locked refused")
  check(p.equip("pocket"),"startingperk")
  if level>=5:
   check(p.equip("reinforced") and p.equipped.size()==2,"secondslot")
   check(not p.equip("dreamer") and p.equipped.size()==2,"thirdslotblocked")
   check(p.equip("pocket") and p.equip("dreamer") and p.equipped==["reinforced","dreamer"],"removeandreplace")
  elif level>=1:check(p.equip("reinforced") and p.equipped==["reinforced"],"single slot replaces")
  check(p.save_profile(),"rank saves")
  var reload=PlayerProfile.new(p.path)
  check(reload.load_profile() and reload.xp==p.xp and reload.equipped==p.equipped,"rank/loadout roundtrip")
 var gate=fresh();gate.xp=8000
 check(gate.rank_index()==5 and not gate.equip("reaper_slayer"),"rawXP cannot unlockMythic")
 # Real derived economy/door/first-aid and projectile effects.
 var plain=fixture();var boosted=fixture("hell","stage_5",["dreamer","reinforced"])
 check(is_equal_approx(boosted.player().max_hp()/plain.player().max_hp(),1.05),"actual doorboost")
 var base=fixture("hell","stage_5");var income0=base.player().income_rate()
 check(is_equal_approx(boosted.player().income_rate()/income0,1.03),"actual incomeboost")
 var damage=[]
 for transformed in [false,true]:
  for owned in [false,true]:
   var m=fixture("hell","stage_5",["marksman","reaper_slayer"])
   m.hunter.hp=1000;m.hunter.max_hp=1000;m.hunter.transformed=transformed;m.hunter.state=HunterState.State.MOVE
   var room=0 if owned else 1
   m.projectiles=[{"id":1,"from":m.hunter.position,"position":m.hunter.position,"target_id":1,"damage":100.0,"speed":200.0,"kind":"turret","room":room,"level":1,"age":0.0}]
   m._advance_projectiles(.1)
   damage.append(1000-m.hunter.hp)
 check(is_equal_approx(damage[0],100) and is_equal_approx(damage[1],100) and is_equal_approx(damage[2],100) and is_equal_approx(damage[3],106),"Reaper6percent only owned actualimpacts")
 # Every catalog reward is deterministic, same inventory, once only and durable.
 check(RewardCatalog.ACHIEVEMENTS.size()>=12,"atleast12achievements")
 for definition in RewardCatalog.ACHIEVEMENTS:
  var p=fresh()
  check(not p.claim_achievement(definition.id),"unearned cannotclaim "+definition.id)
  p.achievements[definition.id]={"claimed":false}
  var xp=p.xp;var quantity=int(p.inventory.get(definition.item,0))
  check(p.claim_achievement(definition.id),"claim "+definition.id)
  check(p.xp==xp+definition.xp and p.inventory[definition.item]==quantity+1,"exact XP/item reward")
  check(not p.claim_achievement(definition.id),"no duplicate claim")
  var reloaded=PlayerProfile.new(p.path)
  check(reloaded.load_profile() and not reloaded.claim_achievement(definition.id) and reloaded.achievements[definition.id].claimed,"reload retains claimed")
  p=fresh();p.achievements[definition.id]={"claimed":false};p.path+="/missing.json"
  check(not p.claim_achievement(definition.id) and p.xp==0 and p.inventory.is_empty() and not p.achievements[definition.id].claimed,"failedsave atomic reward")
 # Reliable old stats migrate; unrelated historical counters are never invented.
 var old=fresh();prove_mythic(old)
 old.inventory={"repair":8,"smoke":2};old.equipped=["first_aid"]
 check(old.save_profile(),"historicalprofilewrites")
 var raw=JSON.parse_string(FileAccess.get_file_as_string(old.path));raw.erase("rewards")
 var file=FileAccess.open(old.path,FileAccess.WRITE);file.store_string(JSON.stringify(raw));file.close()
 var migrated=PlayerProfile.new(old.path)
 check(migrated.load_profile() and migrated.xp==8000 and migrated.inventory==old.inventory,"migrationpreservesXPitems")
 for id in ["first_victory","first_blood","night_survivor","reaper_hunter","reaper_slayer"]:check(migrated.achievements.has(id),"provable retro "+id)
 for id in ["hell_survivor","perfect_team","iron_fortress","economy_master","master_builder","legendary_survivor"]:check(not migrated.achievements.has(id),"no fictional retro "+id)
 # Actual settlement counters, events, same-id idempotence, and failure retry.
 var p=fresh();var a=pair(p,"hell");var m=a.m
 m.hunter.transformed=true;m.player().income_total=10000;m.player().door_damage_taken=1500
 m.player().gold=100000;m.player().electricity=100000
 for i in range(15):
  check(m.player().build("turret",0),"realbuild")
  check(m.player().upgrade_building(0),"realupgrade")
  check(m.player().sell_building(0),"reusetile")
 for room in m.rooms:room.owner=room.index;room.alive=true;room.sleeping=true;room.closed=true
 p.active_match.legendary_used=1
 victory(m)
 var award=p.settle_match(a.entry.id,m)
 check(not award.is_empty(),"eligible real settlement")
 for id in ["first_victory","first_blood","hell_survivor","reaper_hunter","perfect_team","iron_fortress","economy_master","master_builder","legendary_survivor"]:check(p.achievements.has(id),"actualevidence unlock "+id)
 var counters=p.reward_counters.duplicate(true);var stock=p.inventory.duplicate(true);var xp=p.xp
 check(p.settle_match(a.entry.id,m).is_empty() and p.reward_counters==counters and p.inventory==stock and p.xp==xp,"settlement replay no duplication")
 var fail=fresh();a=pair(fail);victory(a.m);var path=fail.path;fail.path+="/missing.json"
 var before=fail._reward_snapshot();var state=fail.reward_rng.state
 check(fail.settle_match(a.entry.id,a.m).is_empty(),"failedsettlement no falseaward")
 check(fail._reward_snapshot()==before and fail.reward_rng.state==state,"fullsettlement rollbackincluding RNG")
 fail.path=path
 check(not fail.settle_match(a.entry.id,a.m).is_empty() and fail.statistics.victories==1,"retry settlesonce")
 # Three independent first-clear choices, targeted-only application and expiry.
 for choice in RewardCatalog.STAGE_BONUSES:
  p=fresh();a=pair(p,"standard","stage_1");victory(a.m)
  check(not p.settle_match(a.entry.id,a.m).is_empty(),"stage1 settlement")
  check(p.pending_stage_bonus.target=="stage_2" and p.pending_stage_bonus.choice=="","firstclear offersnextchoice")
  check(p.begin_match("standard","stage_2").is_empty(),"cannot skipunselectedchoice")
  var pending=p.pending_stage_bonus.duplicate(true);path=p.path;p.path+="/missing.json"
  check(not p.choose_stage_bonus(choice) and p.pending_stage_bonus==pending,"failedchoice no falseconfirmation")
  p.path=path
  check(p.choose_stage_bonus(choice) and not p.choose_stage_bonus("economic"),"exactlyonechoice")
  var reload=PlayerProfile.new(p.path);check(reload.load_profile() and reload.pending_stage_bonus.choice==choice,"choice survivesreload")
  var wrong=p.begin_match("standard","stage_1")
  check(not wrong.has("stage_bonus") and p.pending_stage_bonus.choice==choice,"wrongstage cannotconsume")
  var e=p.begin_match("standard","stage_2")
  check(e.stage_bonus==choice and p.pending_stage_bonus.is_empty(),"intendedtargetconsumesonce")
  m=MatchModel.new();m.configure_stage("stage_2");p.apply_stage_bonus(m,e);m.claim_room(0)
  if choice=="economic":check(m.player().gold==50,"actual25startinggold")
  if choice=="reinforced":check(is_equal_approx(m.player().max_hp(),Catalog.DOOR_HP[0]*1.05),"actual5percentdoor")
  if choice=="battle":check(m.stage_bonus.damage==1.08 and m.stage_bonus.seconds==60,"battlebounded60s")
  check(not m.claim_room(1),"cannot reclaimgainbonus")
  check(not p.begin_match("standard","stage_2").has("stage_bonus"),"secondmatch cannotduplicatebonus")
  var replay=pair(p,"standard","stage_1");victory(replay.m);p.settle_match(replay.entry.id,replay.m)
  check(p.pending_stage_bonus.is_empty(),"replaycannotfarmfirstclearbonus")
 # Additional measured unlocks and exact boundaries.
 var collector=fresh()
 for i in range(9):collector.inventory[ItemCatalog.IDS[i]]=1
 check(not collector.refresh_achievements().has("item_collector"),"nine distinct insufficient")
 collector.inventory[ItemCatalog.IDS[9]]=1;collector.refresh_achievements()
 check(collector.achievements.has("item_collector"),"ten distinct measured")
 collector.inventory.clear();check(collector.save_profile(),"earnedcollectorhistorypersists")
 var cr=PlayerProfile.new(collector.path);check(cr.load_profile() and cr.seen_items.size()==10,"spentstock doesnotresetcollector")
 var hunter=fresh()
 for i in range(3):
  a=pair(hunter,"hard");a.m.hunter.transformed=true;victory(a.m);hunter.settle_match(a.entry.id,a.m)
  check(hunter.achievements.has("night_survivor"),"actualLongNightunlock")
  check(hunter.achievements.has("reaper_slayer")== (i==2),"three actualReapers boundary")
 for field in ["door_damage","income","construction","legendary","perfect_team"]:
  var threshold={"door_damage":1500.0,"income":10000.0,"construction":30,"legendary":1,"perfect_team":1}[field]
  var id={"door_damage":"iron_fortress","income":"economy_master","construction":"master_builder","legendary":"legendary_survivor","perfect_team":"perfect_team"}[field]
  var boundary=fresh();boundary.reward_counters[field]=threshold-1;boundary.refresh_achievements()
  check(not boundary.achievements.has(id),"strictconditionboundary "+id)
  boundary.reward_counters[field]=threshold;boundary.refresh_achievements();check(boundary.achievements.has(id),"exactboundary "+id)
 # Damaged/future optional rewards preserve base progress read-only.
 for malformed in [null,[],{"version":99},{"version":1,"achievements":{},"counters":{"door_damage":-1},"seen_items":[],"stage_bonus":{}}]:
  var corrupt=fresh();corrupt.xp=700;corrupt.inventory={"repair":6};check(corrupt.save_profile(),"corruptfixturebase")
  var data=JSON.parse_string(FileAccess.get_file_as_string(corrupt.path));data.rewards=malformed
  var f=FileAccess.open(corrupt.path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
  var reloaded=PlayerProfile.new(corrupt.path)
  check(reloaded.load_profile() and reloaded.xp==700 and reloaded.inventory.repair==6 and reloaded.read_only,"damagedoptionalpreservesbase")
 # Failed next-stage transition preserves the selected reward and exact match counter.
 var transition=fresh();a=pair(transition,"standard","stage_1");victory(a.m);transition.settle_match(a.entry.id,a.m);transition.choose_stage_bonus("economic")
 var transition_before=transition._reward_snapshot();path=transition.path;transition.path+="/missing.json"
 check(transition.begin_match("standard","stage_2").is_empty() and transition._reward_snapshot()==transition_before,"failedbeginno lostbonus/counter")
 transition.path=path;check(transition.begin_match("standard","stage_2").stage_bonus=="economic","transitionretryonce")
 # A different first clear must not overwrite an unresolved older target reward.
 var collision=fresh();a=pair(collision,"standard","stage_1");victory(a.m);collision.settle_match(a.entry.id,a.m)
 collision.campaign_records.stage_2=record("stage_2")
 var reserved=collision.pending_stage_bonus.duplicate(true)
 a=pair(collision,"standard","stage_3");victory(a.m)
 check(not collision.settle_match(a.entry.id,a.m).is_empty() and collision.pending_stage_bonus==reserved,"differentfirstclear preservesunresolvedbonus")
 check(collision.stage_bonus_queue.size()==1 and collision.stage_bonus_queue[0].target=="stage_4","secondfirstclear queues intendedtarget")
 check(collision.choose_stage_bonus("economic"),"chooseolderqueuedfront")
 var collision_reload=PlayerProfile.new(collision.path)
 var loaded_queue=collision_reload.load_profile()
 print("QUEUE_DIAGNOSTIC ",loaded_queue," warning=",collision_reload.warning," read_only=",collision_reload.read_only," reloaded=",JSON.stringify(collision_reload.stage_bonus_queue)," expected=",JSON.stringify(collision.stage_bonus_queue))
 check(loaded_queue and collision_reload.stage_bonus_queue.size()==1 and collision_reload.stage_bonus_queue[0].source=="stage_3" and collision_reload.stage_bonus_queue[0].target=="stage_4" and collision_reload.stage_bonus_queue[0].choice=="" and int(collision_reload.stage_bonus_queue[0].match_id)==int(collision.stage_bonus_queue[0].match_id),"queue reloadexact values")
 var queued_before=collision._reward_snapshot();var originalpath=collision.path;collision.path+="/missing.json"
 check(collision.begin_match("standard","stage_2").is_empty() and collision._reward_snapshot()==queued_before,"failedqueuepromotionrollsback")
 collision.path=originalpath
 check(collision.begin_match("standard","stage_2").stage_bonus=="economic" and collision.pending_stage_bonus.target=="stage_4" and collision.stage_bonus_queue.is_empty(),"consumeoldpromotesnextonce")
 # Battle bonus affects actual impacts only in its finite next-stage window.
 var battle_damage=[]
 for clock in [89.9,90.0]:
  m=fixture("standard","stage_1");m.time=clock;m.stage_bonus=RewardCatalog.STAGE_BONUSES.battle.duplicate(true)
  m.hunter.hp=1000;m.hunter.state=HunterState.State.MOVE
  m.projectiles=[{"id":1,"from":m.hunter.position,"position":m.hunter.position,"target_id":1,"damage":100.0,"speed":200.0,"kind":"turret","room":0,"level":1,"age":0.0}]
  m._advance_projectiles(.1);battle_damage.append(1000-m.hunter.hp)
 check(is_equal_approx(battle_damage[0],108) and is_equal_approx(battle_damage[1],100),"actualbattle8percent expiry exact")
 # Full inventory cannot silently discard a deterministic achievement item.
 var capped=fresh();capped.achievements.first_victory={"claimed":false};capped.inventory.repair=ItemCatalog.MAX_STOCK
 check(not capped.claim_achievement("first_victory") and not capped.achievements.first_victory.claimed and capped.xp==0,"fullstockclaimno lossornoXPexploit")
 capped.inventory.repair-=1
 check(capped.claim_achievement("first_victory") and capped.inventory.repair==ItemCatalog.MAX_STOCK,"claimafterspaceexactcap")
 cleanup()
 print("REWARDS_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
