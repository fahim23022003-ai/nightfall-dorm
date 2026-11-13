class_name EndlessRun
extends RefCounted
var wave=1
var completed=0
var phase="combat"
var wave_started_at=0.0
var run_id=0
var seed_value=1
var choice_used=false
var _model: WeakRef
var sealed_wave=0
var rescue_used=false
var omen=NightOmens.new()
func configure(model,map: String,mode: String,seed_number: int,id: int,boosts: Dictionary={}) -> bool:
 if map not in MapCatalog.IDS or mode not in RankCatalog.DIFFICULTIES or id<=0:return false
 model.reset(seed_number);model.run_kind="endless";model.configure_map(map);model.configure_match(mode,boosts)
 model.configure_strategy(seed_number,StrategyCatalog.ARCHETYPE_IDS[posmod(seed_number,StrategyCatalog.ARCHETYPE_IDS.size())])
 model.expansion.configure(model)
 model.endless=self;run_id=id;seed_value=seed_number;_model=weakref(model)
 _prepare_hunter(model,false)
 return true
func scaling(at_wave: int=-1) -> Dictionary:
 var value=wave if at_wave<0 else at_wave
 var early=mini(19,value-1);var late=maxi(0,value-20)
 return {"hunter_hp":minf(100,1+.3*early+.9*late),"hunter_damage":minf(9,1+.025*early+.12*late),"hunter_speed":minf(1.25,1+.008*mini(59,value-1))}
func repair_effectiveness(at_wave: int=-1) -> float:
 return 1.0-minf(.65,maxi(0,(wave if at_wave<0 else at_wave)-20)*.01625)
func boss_wave(value: int) -> bool:return value%5==0 or (value>=30 and value%3==0)
func _prepare_hunter(model,new_wave: bool):
 var fresh=HunterState.new();fresh.stage_scaling=scaling();fresh.stage_scaling.hunter_speed*=omen.factor("blood",model.difficulty);fresh.configure(model.difficulty)
 fresh.configure_archetype(StrategyCatalog.ARCHETYPE_IDS[posmod(seed_value+wave-1,StrategyCatalog.ARCHETYPE_IDS.size())])
 fresh.position=model.map_data.hunter_spawn
 fresh.cooldown=1.5
 fresh.boss_policy={"enabled":boss_wave(wave),"opening":0.0,"hp_fraction":1.0,"deadline":0.0,"recovery":1.1}
 model.wrath=ReaperWrath.new();model.defenses.clear(model);model.clear_minions()
 model.hunter=fresh;model.strategy.archetype=fresh.archetype
 if new_wave:model.preparation=model.time+4
 wave_started_at=model.preparation
 model._navigation_routes.clear()
func finish_wave(model):
 if phase!="combat" or model.hunter.hp>0 or model.player()==null or not model.player().alive:return
 omen.finish(model)
 completed=wave;sealed_wave=completed;phase="intermission";choice_used=false
 # These statuses belonged to the defeated entity. Paid room/weapon buffs carry
 # their remaining active-play durations; intermission does not advance them.
 for id in ["frost","time_freeze","decoy","smoke","reaper_seal"]:model.items.timers.erase(id)
 model.items.burn_remaining=0;model.items.frozen_delta=0
 model.wrath.clear(model);model.defenses.clear(model)
 for room in model.rooms:room.production_paused=false
 model.hunter.stop_combat(model);model._cancel_projectiles("wave_complete")
func continue_wave(model,choice: String="repair") -> bool:
 if phase!="intermission" or model.result!="" or not model.running or choice not in ["repair","supply","power"]:return false
 if not choice_used:
  var r=model.player()
  if choice=="repair" and r.door_hp>0:r.door_hp=minf(r.max_hp(),r.door_hp+r.max_hp()*.1)
  elif choice=="supply":r.gold=minf(1e12,r.gold+25)
  elif choice=="power":r.electricity=minf(1e12,r.electricity+5)
  choice_used=true
 model.wave_metrics.reset()
 omen.begin(model)
 model.combat_events.clear();model.presentation_events.clear()
 wave+=1;phase="combat";_prepare_hunter(model,true)
 return true
