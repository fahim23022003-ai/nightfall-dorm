class_name OnboardingCatalog
extends RefCounted
const VERSION=1
const MAX_CASH=100000000
const PRICES={"repair":18,"gold":16,"battery":16,"radar":12}
const RM={"win_min":24,"win_max":32,"performance_cap":12,"hard":10,"hell":20,"loss_min":3,"loss_max":5,"loss_seconds":90.0,"loss_contribution":100.0}
static func cash_reward(model,rng: RandomNumberGenerator) -> int:
 if model.tutorial_mode or not RankCatalog.performance(model).eligible:return 0
 var r=model.player()
 if r==null:return 0
 if model.result=="victory" and r.alive and model.hunter.hp<=0:
  return rng.randi_range(RM.win_min,RM.win_max)+mini(RM.performance_cap,int(r.damage_dealt/500)+int(r.occupied_seconds/60))+int(RM.get(model.difficulty,0))
 if model.result=="defeat" and not r.alive and r.occupied_seconds>=RM.loss_seconds and (r.damage_dealt>=RM.loss_contribution or r.door_damage_taken>=RM.loss_contribution):
  return rng.randi_range(RM.loss_min,RM.loss_max)+mini(3,int(r.occupied_seconds/120))
 return 0
