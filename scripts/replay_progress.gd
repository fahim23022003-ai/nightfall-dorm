class_name ReplayProgress
extends RefCounted
static func defaults() -> Dictionary:
 return {"version":1,"run_serial":0,"best_wave":0,"milestone_wave":0,"checkpoint":{},"pity":{"epic_dry":0,"legendary_dry":0},"cosmetics":{"door":"","turret":"","bed":"","badge":""},"challenge_best":{},"last_award":{}}
static func valid(data) -> bool:
 if not data is Dictionary or data.get("version")!=1:return false
 for key in ["run_serial","best_wave","milestone_wave"]:
  if not ReplaySnapshot.whole(data.get(key),0):return false
 if int(data.milestone_wave) not in [0,5,10,15,20] or data.milestone_wave>data.best_wave:return false
 if not data.get("checkpoint") is Dictionary or (not data.checkpoint.is_empty() and not ReplaySnapshot.valid(data.checkpoint)):return false
 if not data.get("pity") is Dictionary or not ReplaySnapshot.whole(data.pity.get("epic_dry"),0,7) or not ReplaySnapshot.whole(data.pity.get("legendary_dry"),0,39):return false
 if not data.get("cosmetics") is Dictionary or data.cosmetics.size()!=4:return false
 for slot in ["door","turret","bed","badge"]:
  var id=data.cosmetics.get(slot)
  if not id is String or (id!="" and (not CosmeticCatalog.ITEMS.has(id) or CosmeticCatalog.ITEMS[id].slot!=slot)):return false
 if not data.get("last_award") is Dictionary or not data.get("challenge_best") is Dictionary or data.challenge_best.size()>32:return false
 for key in data.challenge_best:
  var entry=data.challenge_best[key]
  if not key is String or key.length()>32 or not entry is Dictionary or not entry.get("code") is String or not ChallengeCode.decode(entry.code,true).ok or not ReplaySnapshot.number(entry.get("time"),0,1e9) or not ReplaySnapshot.number(entry.get("score"),0,1e12) or not ReplaySnapshot.whole(entry.get("plays"),1):return false
 return true
static func valid_active(entry: Dictionary) -> bool:
 if not ReplaySnapshot.whole(entry.get("legendary_used"),0,1):return false
 if not ReplaySnapshot.whole(entry.get("run_id"),1) or entry.get("run_id")!=entry.get("id") or entry.get("map","") not in MapCatalog.IDS or not ReplaySnapshot.whole(entry.get("seed"),1,999999) or not entry.get("feather_used") is bool or not entry.get("rescue_used") is bool or not entry.get("use_counts") is Dictionary or entry.use_counts.size()>20:return false
 for key in entry.use_counts:
  if key not in ItemCatalog.IDS or not ReplaySnapshot.whole(entry.use_counts[key],0,ItemCatalog.MAX_STOCK):return false
 return true
static func begin_endless(profile,map: String,mode: String,seed_value: int) -> Dictionary:
 if profile.read_only or map not in MapCatalog.IDS or mode not in RankCatalog.DIFFICULTIES or seed_value<1 or seed_value>999999 or profile.next_match_id>=1000000000000:return {}
 var before=profile._reward_snapshot();var id=profile.next_match_id
 profile.active_match={"id":id,"run_id":id,"run_kind":"endless","difficulty":mode,"equipped":profile.equipped.duplicate(),"items":profile.item_loadout.duplicate(),"archetype":StrategyCatalog.ARCHETYPE_IDS[posmod(seed_value,3)],"contract":"","map":map,"seed":seed_value,"legendary_used":0,"feather_used":false,"rescue_used":false,"use_counts":{}}
 profile.next_match_id+=1;profile.replay.run_serial+=1;profile.replay.checkpoint={}
 if not profile.save_profile():profile._restore_rewards(before);return {}
 return profile.active_match.duplicate(true)
static func matches(profile,model) -> bool:
 var entry=profile.active_match
 if not (model.run_kind=="endless" and model.endless!=null and model.endless._model!=null and model.endless._model.get_ref()==model and not entry.is_empty() and entry.get("run_kind","")=="endless" and int(entry.get("run_id",-1))==model.endless.run_id and int(entry.id)==model.endless.run_id and entry.get("map","")==model.map_id and entry.get("difficulty","")==model.difficulty and entry.get("seed",0)==model.endless.seed_value):return false
 var expected=RankCatalog.bonuses(entry.get("equipped",[]));var neutral=RankCatalog.bonuses([])
 for key in expected:
  if model.match_boosts.get(key,neutral[key])!=expected[key]:return false
 return true
static func checkpoint(profile,model) -> bool:
 if profile.read_only or not matches(profile,model):return false
 var snapshot=ReplaySnapshot.encode(model,profile.active_match.get("use_counts",{}))
 if snapshot.is_empty():return false
 var before=profile._reward_snapshot()
 profile.replay.checkpoint=snapshot
 profile.replay.best_wave=maxi(int(profile.replay.best_wave),model.endless.completed)
 var cash=0;var points=0
 for milestone in [5,10,15,20]:
  if model.endless.completed>=milestone and int(profile.replay.milestone_wave)<milestone and profile.rm_cash+8<=OnboardingCatalog.MAX_CASH:
   profile.rm_cash+=8;cash+=8
   var award=mini(20,RankCatalog.MAX_XP-profile.xp);profile.xp+=award;points+=award
   profile.replay.milestone_wave=milestone
 profile.highest_rank=maxi(profile.highest_rank,profile.rank_index())
 profile.replay.last_award={"run_id":model.endless.run_id,"completed":model.endless.completed,"rm_cash":cash,"xp":points}
 if not profile.save_profile():profile._restore_rewards(before);return false
 return true
static func resume(profile):
 if profile.read_only or profile.replay.checkpoint.is_empty():return null
 var model=ReplaySnapshot.restore(profile.replay.checkpoint)
 if model==null or not matches(profile,model):return null
 model.items.legendary_used=maxi(model.items.legendary_used,int(profile.active_match.get("legendary_used",0)))
 model.items.feather_used=model.items.feather_used or profile.active_match.get("feather_used",false)
 model.player().rescue_used=model.player().rescue_used or profile.active_match.get("rescue_used",false)
 var old=profile.replay.checkpoint.get("use_counts",{})
 if int(profile.active_match.get("use_counts",{}).get("coupon",0))>int(old.get("coupon",0)):model.player().coupon_armed=false
 profile.bind_items(model,int(profile.active_match.id))
 return model
static func finish(profile,model) -> Dictionary:
 if profile.read_only or not matches(profile,model) or model.result!="defeat" or not model.terminal_recorded or model.eliminations<=0 or (model.player()!=null and model.player().alive):return {}
 var before=profile._reward_snapshot()
 var report={"run_id":model.endless.run_id,"completed":model.endless.completed,"best":profile.replay.best_wave,"rm_cash":0,"xp":0}
 profile.active_match={};profile.replay.checkpoint={};profile.replay.last_award=report
 if not profile.save_profile():profile._restore_rewards(before);return {}
 return report
static func finish_cleared(profile,model) -> Dictionary:
 if not matches(profile,model) or model.endless.phase!="intermission" or not checkpoint(profile,model):return {}
 var before=profile._reward_snapshot()
 var report={"run_id":model.endless.run_id,"completed":model.endless.completed,"best":profile.replay.best_wave,"rm_cash":0,"xp":0,"safe_end":true}
 profile.active_match={};profile.replay.checkpoint={};profile.replay.last_award=report
 if not profile.save_profile():profile._restore_rewards(before);return {}
 return report
static func mark_rescue(profile,id: int) -> bool:
 if profile.active_match.get("run_kind","")!="endless" or int(profile.active_match.get("id",-1))!=id or profile.active_match.get("rescue_used",false):return false
 var before=profile.active_match.duplicate(true);profile.active_match.rescue_used=true
 if not profile.save_profile():profile.active_match=before;return false
 return true
