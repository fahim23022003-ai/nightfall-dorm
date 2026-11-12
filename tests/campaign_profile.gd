extends SceneTree
var checks=0
var failures=0
var path="user://qa-campaign-profile.json"
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("CAMPAIGN PROFILE: "+label)
func _initialize(): call_deferred("run")
func cleanup():
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
func model_for(entry,win=true):
 var model=MatchModel.new()
 model.configure_match(entry.difficulty,RankCatalog.bonuses(entry.equipped))
 model.configure_stage(entry.stage_id)
 model.claim_room(0)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 model.time=model.preparation+40
 model.player().occupied_seconds=40
 model.player().damage_dealt=500
 model.hunter.hp=0 if win else 100
 model.result="victory" if win else "defeat"
 return model
func run():
 cleanup()
 var p=PlayerProfile.new(path)
 check(p.selected_stage=="stage_1" and p.highest_unlocked_stage()==1,"new profile starts stage1")
 check(not p.stage_unlocked("stage_2") and not p.select_stage("stage_5"),"locked UI choice rejected")
 check(p.begin_match("standard","stage_5").is_empty(),"locked direct match rejected")
 check(not p.equip("marksman"),"locked perk rejected")
 check(p.equip("pocket"),"existing perk equips")
 for definition in StageCatalog.STAGES:
  var id=definition.id
  if not p.pending_stage_bonus.is_empty() and p.pending_stage_bonus.choice=="":check(p.choose_stage_bonus("battle"),"choose earned next-stage reward")
  check(p.stage_unlocked(id),"previous win unlocks current")
  check(p.select_stage(id),"select unlocked stage")
  check(p.select_difficulty("hard"),"difficulty persists separately")
  var entry=p.begin_match("hard",id)
  check(entry.stage_id==id and entry.equipped==["pocket"],"immutable entry snapshot")
  var model=model_for(entry,false)
  var loss=p.settle_match(entry.id,model)
  check(not loss.campaign.cleared and loss.campaign.reward_xp==0,"defeat grants no clear reward")
  if StageCatalog.next_stage(id)!="": check(not p.stage_unlocked(StageCatalog.next_stage(id)),"defeat does not unlock next")
  entry=p.begin_match("standard",id)
  model=model_for(entry)
  check(model.player().gold==30,"loadout applies to actual room")
  var win=p.settle_match(entry.id,model)
  check(win.campaign.first_clear and win.campaign.reward_xp==definition.first_clear_xp,"first victory grants configured reward")
  check(p.stage_record(id).clears==1,"record stored")
  var xp=p.xp
  check(p.settle_match(entry.id,model).is_empty() and p.xp==xp,"duplicate settlement cannot award")
  var recovered=PlayerProfile.new(path)
  check(recovered.load_profile(),"profile restart loads")
  check(recovered.selected_stage==id and recovered.selected_difficulty=="hard","selection and difficulty survive")
  check(recovered.stage_record(id).clears==1 and recovered.xp==p.xp and recovered.equipped==p.equipped,"record XP and loadout survive")
  check(recovered.settle_match(entry.id,model).is_empty(),"duplicate after restart rejected")
  p=recovered
  entry=p.begin_match("standard",id)
  model=model_for(entry)
  var replay=p.settle_match(entry.id,model)
  check(not replay.campaign.first_clear and replay.campaign.reward_xp==0 and p.stage_record(id).clears==2,"replay retains clear but no first reward")
 check(p.highest_unlocked_stage()==5,"campaign stops at stage5")
 # Legacy generation has no campaign field and is migrated additively.
 cleanup()
 var legacy={"version":RankCatalog.VERSION,"xp":700,"equipped":["dreamer"],"next_match_id":1,"settings":{"music":0.2},"active_match":{},"last_award":{}}
 var f=FileAccess.open(path,FileAccess.WRITE)
 f.store_string(JSON.stringify(legacy))
 f.close()
 p=PlayerProfile.new(path)
 check(p.load_profile() and p.xp==700 and p.equipped==["dreamer"],"legacy XP/perks survive migration")
 check(p.selected_stage=="stage_1" and p.campaign_records.is_empty(),"legacy receives default stage1")
 check(p.save_profile(),"migrated generation validates")
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 data.campaign.selected_stage="stage_5"
 f=FileAccess.open(path,FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
 check(p._decode(path).is_empty(),"corrupt locked selected stage rejected")
 data.campaign.selected_stage="stage_1"
 data.campaign.records={"stage_3":{"clears":1,"best_xp":1,"difficulty":"standard","first_match_id":1,"best_time":60,"best_damage":20}}
 f=FileAccess.open(path,FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
 check(p._decode(path).is_empty(),"corrupt disconnected completion rejected")
 cleanup()
 print("CAMPAIGN_PROFILE_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
