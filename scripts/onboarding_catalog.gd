class_name OnboardingCatalog
extends RefCounted
const VERSION=1
const MAX_CASH=100000000
const PRICES={"repair":18,"gold":16,"battery":16,"radar":12}
const RM={"win_min":24,"win_max":32,"performance_cap":12,"hard":10,"hell":20,"loss_min":3,"loss_max":5,"loss_seconds":90.0,"loss_contribution":100.0}
const DEFEAT_BASE_CASH:=6
const DEFEAT_SECONDS_PER_CASH:=45.0
const DEFEAT_DURATION_CAP:=3
const DEFEAT_DAMAGE_PER_CASH:=200.0
const DEFEAT_CONTRIBUTION_CAP:=5

static func cash_reward(model,rng: RandomNumberGenerator) -> int:
 if model.result=="defeat" and OS.get_environment("NIGHTFALL_SURVIVOR_REBIRTH")=="1":
  return _survivor_defeat_reward(model)
 if model.tutorial_mode or model.run_kind!="campaign" or not RankCatalog.performance(model).eligible:return 0
 var r=model.player()
 if r==null:return 0
 if model.result=="victory" and r.alive and model.hunter.hp<=0:
  return rng.randi_range(RM.win_min,RM.win_max)+mini(RM.performance_cap,int(r.damage_dealt/500)+int(r.occupied_seconds/60))+int(RM.get(model.difficulty,0))
 if model.result=="defeat" and not r.alive and r.occupied_seconds>=RM.loss_seconds and (r.damage_dealt>=RM.loss_contribution or r.door_damage_taken>=RM.loss_contribution):
  return rng.randi_range(RM.loss_min,RM.loss_max)+mini(3,int(r.occupied_seconds/120))
 return 0

static func _survivor_defeat_reward(model) -> int:
 if model.tutorial_mode or model.run_kind not in ["campaign","endless"] or not model.terminal_recorded or model.eliminations<=0:
  return 0
 var room: RoomState=model.player()
 if room==null or room.owner!=0 or room.alive or room.occupied_seconds<=0.0 or model.time<model.preparation:
  return 0
 var contribution: float=room.damage_dealt+room.door_damage_taken
 if not is_finite(model.time) or not is_finite(room.occupied_seconds) or not is_finite(contribution):
  return 0
 var duration_units:=clampf(room.occupied_seconds/DEFEAT_SECONDS_PER_CASH,0.0,DEFEAT_DURATION_CAP)
 var contribution_units:=clampf(contribution/DEFEAT_DAMAGE_PER_CASH,0.0,DEFEAT_CONTRIBUTION_CAP)
 return DEFEAT_BASE_CASH+floori(duration_units)+floori(contribution_units)
