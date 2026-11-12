class_name CosmeticCatalog
extends RefCounted
const ITEMS={
 "iron_gate":{"name":"Iron Reliquary Door","slot":"door","description":"Arched iron ribs, riveted central lock and carved lintel.","condition":"Win one campaign match."},
 "coil_crown":{"name":"Cathedral Coil Turret","slot":"turret","description":"Twin spires, a metal halo and engraved weapon casing.","condition":"Clear Endless wave 3."},
 "canopy":{"name":"Midnight Canopy Bed","slot":"bed","description":"Four sculpted posts and a torn velvet canopy.","condition":"Clear Endless wave 5."},
 "reaper_crest":{"name":"Reaper Watch Crest","slot":"badge","description":"An engraved scythe crest beside your HUD name.","condition":"Win a campaign Reaper encounter."}}
static func earned(profile,id: String) -> bool:
 match id:
  "iron_gate":return profile.statistics.victories>0
  "coil_crown":return int(profile.replay.best_wave)>=3
  "canopy":return int(profile.replay.best_wave)>=5
  "reaper_crest":return profile.statistics.reaper_defeats>0
 return false
