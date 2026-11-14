class_name HunterPressure
extends RefCounted
# Genuine sustained siege only, capped per encounter; not tied to wallets/upgrades.
var contact=0.0
var stacks=0
var warning=0.0
var warned=false
var hits=0
func tick(m,delta):
 if m.balance_version!=2:return
 if warning>0:
  warning=maxf(0,warning-delta)
  if warning==0:stacks=mini(2,stacks+1);warned=false
 var h=m.hunter
 if h.transformed or m.wrath.domain_active() or h.hp<=0 or h.state!=HunterState.State.ATTACK or h.target<0:return
 var r=m.rooms[h.target]
 if r.alive and r.door_hp>0 and h.position.distance_to(r.door_approach())<=180:contact+=delta
 if stacks<2 and not warned and contact>=20*(stacks+1) and hits>=(stacks+1)*3:
  warned=true;warning=2.5;m.record_event("hunter_ability_warning",h.target,{"ability":"siege_resolve","delay":2.5})
func factor(m) -> float:
 if m.balance_version!=2:return 1.0
 var elapsed=m.time
 var opening=.72 if m.difficulty=="standard" else .78 if m.difficulty=="hard" else .65
 var mature=1.0 if m.difficulty=="standard" else 1.08 if m.difficulty=="hard" else 1.05
 return lerpf(opening,mature,clampf(elapsed/(300.0 if m.difficulty=="standard" else 450.0 if m.difficulty=="hard" else 600.0),0,1))*(1+stacks*.08)

static func growth_clock(m,active: float) -> float:
 if m.balance_version!=2 or m.run_kind!="campaign" or m.tutorial_mode or m.difficulty=="standard":return active
 var opening=RankCatalog.pressure(m.difficulty).opening
 return minf(active,opening)+maxf(0,active-opening)*BalanceRules.CAMPAIGN_GROWTH_CLOCK
