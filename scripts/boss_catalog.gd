class_name BossCatalog
extends RefCounted

# Encounter policy is independent of map geometry. Legacy standalone remains unchanged.
# No transformation health grant: current/max HP are carried through exactly.
const TRANSFORM_SECONDS=2.4
const ENCOUNTERS={
 "standard":{"first_stage":3,"opening":90.0,"hp_fraction":0.55,"deadline":210.0,"recovery":1.05},
 "hard":{"first_stage":2,"opening":80.0,"hp_fraction":0.55,"deadline":210.0,"recovery":1.0},
 "hell":{"first_stage":2,"opening":80.0,"hp_fraction":0.55,"deadline":210.0,"recovery":1.1}
}
const ATTACKS={
 "scythe":{"name":"SCYTHE STRIKE","windup":1.0,"damage":1.15,"cooldown":3.0,"recovery":0.85},
 "siege":{"name":"SOUL SIEGE","windup":1.8,"damage":1.6,"cooldown":14.0,"recovery":1.25},
 "surge":{"name":"SHADOW SURGE","windup":1.5,"damage":0.0,"cooldown":20.0,"recovery":1.1}
}
const SURGE_SECONDS=2.5
const SURGE_VULNERABILITY=1.2

static func encounter(stage_id: String, mode: String) -> Dictionary:
 var policy=ENCOUNTERS.get(mode,ENCOUNTERS.standard).duplicate(true)
 policy.enabled=StageCatalog.index_of(stage_id)+1>=int(policy.first_stage)
 return policy
