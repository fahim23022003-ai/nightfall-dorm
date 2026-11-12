class_name MatchStrategy
extends RefCounted
# Match-local rules/evidence; no second Hunter controller or reward transaction.
var enabled=false
var archetype=""
var contract=""
var match_id=0
var failed=false
var failure_reason=""
var max_offense=0
var legendary_uses=0
var manual_repairs=0
var _model: WeakRef
var _sealed: Dictionary={}
var _configuration: Dictionary={}
func configure(model,seed_value: int,id: String="",selected_contract: String="",identity: int=0) -> bool:
 if enabled or model.time>0 or model.player_room>=0 or model.tutorial_mode:return false
 if id=="":id=StrategyCatalog.choose_archetype(seed_value,model.stage_id,model.difficulty)
 if not StrategyCatalog.ARCHETYPES.has(id) or (selected_contract!="" and not StrategyCatalog.CONTRACTS.has(selected_contract)):return false
 enabled=true;archetype=id;contract=selected_contract;match_id=identity;_model=weakref(model)
 _configuration={"archetype":id,"contract":contract,"match_id":identity,"stage":model.stage_id,"difficulty":model.difficulty}
 model.hunter.configure_archetype(id)
 for room in model.rooms:
  room.strategy_enabled=true
  room.apply_trait(StrategyCatalog.trait_for(room.index,model.map_id))
 return true
func observe(model):
 if not enabled or not _sealed.is_empty():return
 var room=model.player()
 if room==null:return
 var offense=0
 for b in room.buildings.values():
  if b.kind in ["turret","heavy"]:offense+=1
 max_offense=maxi(max_offense,offense)
 legendary_uses=maxi(legendary_uses,model.items.legendary_used)
 manual_repairs=maxi(manual_repairs,room.repair_actions)
 if contract=="no_legendary" and legendary_uses>0:fail("A Legendary was triggered.")
 if contract=="limited_defense" and max_offense>2:fail("More than two offensive turrets were owned.")
 if contract=="iron_survivor" and manual_repairs>0:fail("Manual door repair was used.")
func fail(reason: String):
 failed=true
 if failure_reason=="":failure_reason=reason
func event(type: String,room_index: int,model):
 if enabled and room_index==model.player_room and type in ["build","sale","repair","building_upgrade"]:observe(model)
func seal(model):
 if not enabled or not _sealed.is_empty() or model.result not in ["victory","defeat"]:return
 observe(model)
 var room=model.player()
 _sealed=_configuration.duplicate(true)
 _sealed.merge({"result":model.result,"time":model.time,"hunter_hp":model.hunter.hp,"player_alive":room!=null and room.alive,"occupied":room.occupied_seconds if room!=null else 0.0,"failed":failed,"max_offense":max_offense,"legendary":legendary_uses,"repairs":manual_repairs},true)
func verified(model,entry: Dictionary) -> bool:
 if not enabled or _model==null or _model.get_ref()!=model or _sealed.is_empty():return false
 if archetype!=_sealed.archetype or contract!=_sealed.contract or match_id!=_sealed.match_id:return false
 if model.stage_id!=_sealed.stage or model.difficulty!=_sealed.difficulty or model.hunter.archetype!=archetype:return false
 if model.result!=_sealed.result or model.time!=_sealed.time or model.hunter.hp!=_sealed.hunter_hp or model.player()==null or model.player().alive!=_sealed.player_alive:return false
 if failed!=_sealed.failed or max_offense!=_sealed.max_offense or legendary_uses!=_sealed.legendary or manual_repairs!=_sealed.repairs:return false
 if model.items.legendary_used!=_sealed.legendary or model.player().repair_actions!=_sealed.repairs or model.player().occupied_seconds!=_sealed.occupied:return false
 return int(entry.get("id",-1))==match_id and entry.get("archetype","")==archetype and entry.get("contract","")==contract
func reward_eligible(model,entry: Dictionary) -> bool:
 if not verified(model,entry) or contract=="" or failed:return false
 if model.result!="victory" or model.hunter.hp>0 or not model.player().alive:return false
 if _sealed.occupied<RankCatalog.MIN_OCCUPIED_SECONDS or model.time<model.preparation+10:return false
 return contract!="no_legendary" or int(entry.get("legendary_used",0))==0
func status() -> String:
 if contract=="":return "No optional contract"
 return StrategyCatalog.CONTRACTS[contract].name+(" · FAILED: "+failure_reason if failed else " · active")
