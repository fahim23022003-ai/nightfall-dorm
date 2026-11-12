class_name ItemCatalog
extends RefCounted
const MAX_STOCK=9999
const SLOTS=2
const TUNING={"global_cooldown":1.0,"repair_fraction":0.25,"gold":150.0,"battery":80.0,"radar_seconds":30.0,"shield_seconds":15.0,"shield_fraction":0.3,"overdrive_seconds":12.0,"overdrive_rate":1.35,"frost_seconds":7.0,"frost_factor":0.6,"reaper_frost_factor":0.75,"trap_seconds":45.0,"trap_damage":220.0,"trap_radius":30.0,"barricade_seconds":20.0,"barricade_factor":0.75,"feather_threshold":0.25,"feather_fraction":0.15,"inferno_seconds":15.0,"burn_seconds":4.0,"burn_dps":12.0,"burn_boss_factor":0.6,"pillow_seconds":25.0,"pillow_factor":1.5,"coupon_factor":0.6,"decoy_seconds":8.0,"boss_decoy_seconds":4.0,"control_refractory":20.0,"rescue_fraction":0.25,"smoke_seconds":6.0,"boss_smoke_seconds":3.0,"legendary_limit":1,"freeze_seconds":3.0,"boss_freeze_seconds":1.5,"seal_recovery":1.25,"heart_fraction":0.15,"heart_shield_fraction":0.2,"heart_shield_seconds":3.0,"fortune_gold":500.0,"curse_seconds":20.0,"curse_damage":1.25,"curse_interval":0.8}
const IDS=["repair","gold","battery","radar","shield","overdrive","frost","trap","barricade","feather","inferno","pillow","coupon","decoy","rescue","smoke","time_freeze","reaper_seal","guardian_heart","cursed_fortune"]
const ITEMS={
 "repair":{"name":"Instant Repair Kit","rarity":"Common","color":"74E5A3","description":"Restore 25% maximum door HP. Intact damaged doors only."},
 "gold":{"name":"Gold Supply Crate","rarity":"Common","color":"FFD368","description":"Gain 150 Gold for this match."},
 "battery":{"name":"Emergency Battery","rarity":"Common","color":"64DFFD","description":"Gain 80 Electricity for this match."},
 "radar":{"name":"Hunter Radar","rarity":"Common","color":"86E0CE","description":"Track the Hunter and target for 30 seconds."},
 "shield":{"name":"Emergency Shield","rarity":"Rare","color":"65B5FF","description":"Shield absorbs 30% max door HP for 15 seconds."},
 "overdrive":{"name":"Turret Overdrive","rarity":"Rare","color":"F5A85E","description":"Your turrets fire 35% faster for 12 seconds."},
 "frost":{"name":"Frost Bomb","rarity":"Rare","color":"A6DBFF","description":"Slow Hunter 40% for 7 seconds. Reaper resists: 25%."},
 "trap":{"name":"Explosive Trap","rarity":"Rare","color":"F78E88","description":"Arm a doorway trap: 220 damage once. Expires in 45s."},
 "barricade":{"name":"Iron Barricade","rarity":"Rare","color":"BAC9DA","description":"Reduce incoming door damage 25% for 20s, before shields."},
 "feather":{"name":"Last Stand Feather","rarity":"Epic","color":"FFD97C","description":"Automatic once per match: crossing 25% intact door HP heals 15%."},
 "inferno":{"name":"Inferno Ammo","rarity":"Epic","color":"FF9255","description":"Owned turret hits ignite one 12 DPS burn for 4s, for 15s. Reaper resists 40%."},
 "pillow":{"name":"Golden Pillow","rarity":"Rare","color":"F9D269","description":"Occupied bed income +50% for 25s."},
 "coupon":{"name":"Construction Coupon","rarity":"Rare","color":"93E3CB","description":"Arm free: next building purchase/upgrade costs 40% less. Spent only on success."},
 "decoy":{"name":"Ghost Decoy Doll","rarity":"Epic","color":"E2AAF2","description":"Distract Hunter at your doorway up to 8s (Reaper 4s). 20s recovery."},
 "rescue":{"name":"Team Rescue Signal","rarity":"Rare","color":"82F1D5","description":"Select a living teammate: restore 25% max intact door HP."},
 "smoke":{"name":"Shadow Smoke","rarity":"Epic","color":"C89AF4","description":"Lower your room priority for 6s (Reaper 3s). Hunter can still attack."},
 "time_freeze":{"name":"Time Freeze","rarity":"Legendary","color":"86DCFF","description":"Stop Hunter actions for 3s (Reaper 1.5s). Economy continues. One Legendary per match."},
 "reaper_seal":{"name":"Reaper Seal","rarity":"Legendary","color":"FFE291","description":"Counter a telegraphed Reaper special. At least 1.25s recovery; invalid use is free."},
 "guardian_heart":{"name":"Guardian Heart","rarity":"Legendary","color":"FFD2A1","description":"Automatic lethal-hit rescue: 15% door HP + 20% HP shield for 3s. One Legendary per match."},
 "cursed_fortune":{"name":"Cursed Fortune","rarity":"Legendary","color":"E6B0FF","description":"Gain 500 Gold; Hunter damage +25%, attack interval -20% for 20s. One Legendary per match."}
}
# Integer weights permit exact quarter-percent drops without rounding or rerolls.
const TABLES={"victory":[100,100,100,100,50,50,50,50,50,40,40,50,50,40,50,40,10,10,10,10],"defeat":[800,800,800,800,80,80,80,80,80,30,30,80,80,30,80,30,10,10,10,10]}
static func probability(result: String,index: int) -> float:
 var weights=TABLES.get(result,TABLES.defeat)
 var total=0.0
 for weight in weights: total+=weight
 return 100.0*weights[index]/total
static func legendary(id: String) -> bool:
 return ITEMS.has(id) and ITEMS[id].rarity=="Legendary"
static func roll(result: String,rng: RandomNumberGenerator) -> String:
 var weights=TABLES.get(result,TABLES.defeat)
 var total=0
 for weight in weights: total+=weight
 var value=rng.randi_range(1,total)
 for i in range(IDS.size()):
  value-=weights[i]
  if value<=0: return IDS[i]
 return IDS[0]
static func reward_eligible(model) -> bool:
 var r=model.player()
 if r==null or not RankCatalog.performance(model).eligible: return false
 if model.result=="victory": return model.hunter.hp<=0 and r.alive
 return model.result=="defeat" and not r.alive and r.occupied_seconds>=60 and (r.damage_dealt>=100 or r.door_damage_taken>=100)
