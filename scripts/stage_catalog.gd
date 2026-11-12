class_name StageCatalog
extends RefCounted

# Stage identity/progression is separate from Night watch / Long night difficulty.
# All use the original map until Phase3B; modifiers compose with difficulty.
const STAGES=[
 {"id":"stage_1","number":1,"title":"First Encounter","requires":"","map":"dorm_original","objective":"Defeat the hunter and survive.","first_clear_xp":40,"preparation":30.0,"hunter_hp":1.0,"hunter_damage":1.0,"hunter_speed":1.0},
 {"id":"stage_2","number":2,"title":"Dark Awakening","requires":"stage_1","map":"dorm_original","objective":"Defeat the hunter and survive.","first_clear_xp":50,"preparation":29.0,"hunter_hp":1.03,"hunter_damage":1.02,"hunter_speed":1.01},
 {"id":"stage_3","number":3,"title":"Midnight Siege","requires":"stage_2","map":"dorm_original","objective":"Defeat the hunter and survive.","first_clear_xp":60,"preparation":28.0,"hunter_hp":1.06,"hunter_damage":1.04,"hunter_speed":1.02},
 {"id":"stage_4","number":4,"title":"Endless Shadows","requires":"stage_3","map":"dorm_original","objective":"Defeat the hunter and survive.","first_clear_xp":70,"preparation":27.0,"hunter_hp":1.09,"hunter_damage":1.06,"hunter_speed":1.03},
 {"id":"stage_5","number":5,"title":"Final Nightmare","requires":"stage_4","map":"dorm_original","objective":"Defeat the hunter and survive.","first_clear_xp":80,"preparation":26.0,"hunter_hp":1.12,"hunter_damage":1.08,"hunter_speed":1.04}
]
static func stage(id: String) -> Dictionary:
 for item in STAGES:
  if item.id==id: return item.duplicate(true)
 return {}
static func index_of(id: String) -> int:
 for i in range(STAGES.size()):
  if STAGES[i].id==id: return i
 return -1
static func next_stage(id: String) -> String:
 var index=index_of(id)
 return STAGES[index+1].id if index>=0 and index+1<STAGES.size() else ""
