class_name RewardCatalog
extends RefCounted
const CONDITIONS={"door_damage":1500.0,"income":10000.0,"construction":30,"distinct_items":10}
const STAGE_BONUSES={
 "reinforced":{"name":"Reinforced Start","description":"Next stage only: +5% door maximum HP.","door":1.05},
 "economic":{"name":"Economic Preparation","description":"Next stage only: +25 starting Gold.","gold":25.0},
 "battle":{"name":"Battle Preparation","description":"Next stage only: +8% owned turret damage until 60s after Hunter arrival.","damage":1.08,"seconds":60.0}}
const ACHIEVEMENTS=[
 {"id":"first_victory","name":"First Victory","description":"Win one legitimate match.","xp":15,"item":"repair"},
 {"id":"first_blood","name":"First Blood","description":"Defeat the Hunter in a legitimate victory.","xp":10,"item":"gold"},
 {"id":"night_survivor","name":"Night Survivor","description":"Win Long Night once.","xp":25,"item":"shield"},
 {"id":"hell_survivor","name":"Hell Survivor","description":"Win Hell Mode once. Earn the Hell Survivor title.","xp":40,"item":"inferno"},
 {"id":"reaper_hunter","name":"Reaper Hunter","description":"Win against the transformed Grim Reaper.","xp":30,"item":"overdrive"},
 {"id":"reaper_slayer","name":"Reaper Slayer","description":"Defeat the transformed Reaper three times.","xp":50,"item":"feather"},
 {"id":"perfect_team","name":"Perfect Team","description":"Win with all six occupied rooms surviving.","xp":25,"item":"rescue"},
 {"id":"iron_fortress","name":"Iron Fortress","description":"Survive 1,500 actual door damage across eligible matches.","xp":25,"item":"barricade"},
 {"id":"economy_master","name":"Economy Master","description":"Produce 10,000 Gold in occupied beds across eligible matches.","xp":25,"item":"pillow"},
 {"id":"master_builder","name":"Master Builder","description":"Complete 30 building purchases/upgrades across eligible matches.","xp":25,"item":"coupon"},
 {"id":"item_collector","name":"Item Collector","description":"Own or earn ten distinct consumable types since tracking began.","xp":20,"item":"battery"},
 {"id":"legendary_survivor","name":"Legendary Survivor","description":"Successfully activate a Legendary and finish an eligible match.","xp":35,"item":"smoke"}]
static func achievement(id: String) -> Dictionary:
 for data in ACHIEVEMENTS:
  if data.id==id:return data
 return {}
