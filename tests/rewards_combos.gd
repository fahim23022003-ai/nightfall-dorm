extends SceneTree
# Independent deterministic fixtures; direct setup is not natural-match balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://rewards-combo-"
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
 for mode in ["standard","hard","hell"]:
  var p=fresh();prove_mythic(p);p.equipped=["reinforced","first_aid"]
  p.inventory={"guardian_heart":3,"barricade":3};p.item_loadout=["guardian_heart","barricade"]
  var entry=p.begin_match(mode)
  var m=fixture(mode,"stage_5",p.equipped);p.bind_items(m,entry.id)
  m.stage_bonus=RewardCatalog.STAGE_BONUSES.reinforced.duplicate(true)
  var r=m.player();r.door_level=4;r.door_hp=r.max_hp();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach()
  check(p.activate_item(1,m,entry.id),"Barricade withtwo rankperks "+mode)
  r.door_hp=10
  var aid_before=r.rescue_used
  m.hunter._damage_door(r,m,100000)
  check(r.door_hp>0 and is_equal_approx(r.door_hp,r.max_hp()*.15),"Heartstillrescues undercombinedmitigation")
  check(r.rescue_used==aid_before and p.inventory.guardian_heart==2,"noautomaticdoubleheal")
  check(m.items.legendary_used==1 and p.active_match.legendary_used==1,"persistedlimit remains1")
  m.items.tick(21,m);m.hunter._damage_door(r,m,100000)
  check(r.door_hp==0 and p.inventory.guardian_heart==2,"stackeddefensefinite nosecondHeart")
  p=fresh();prove_mythic(p);p.equipped=["marksman","reaper_slayer"]
  p.inventory={"time_freeze":2,"cursed_fortune":2};p.item_loadout=["time_freeze","cursed_fortune"]
  entry=p.begin_match(mode);m=fixture(mode,"stage_5",p.equipped);p.bind_items(m,entry.id)
  m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.boss_policy.enabled=false;m.hunter.transformed=true;m.hunter.cooldown=.1
  var hp=m.player().door_hp
  check(p.activate_item(0,m,entry.id),"MythicoffenseFreeze")
  m.tick(.5)
  check(m.player().door_hp==hp,"Freeze protects temporarilywithrankdamage")
  m.items.cooldown=0
  check(not p.activate_item(1,m,entry.id) and p.inventory.cursed_fortune==2,"tworankperksneveroverrideLegendarylimit")
  m.tick(2)
  check(not m.items.timers.has("time_freeze"),"Reaperfreezeexpires")
 cleanup()
 print("REWARDS_COMBO_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
