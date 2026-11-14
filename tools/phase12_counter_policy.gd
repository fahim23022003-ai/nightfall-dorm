extends "res://tools/phase12_grid_policy.gd"
# Defensive opening: weapon count/door durability before costly power, real sale later.
func act(m,strategy):
 var r=m.player()
 if r.door_hp<r.max_hp()*.65 and (structure(m,"door") or m.repair_door()):return
 if count(r,"turret")==0 and build(m,"turret"):return
 if r.bed_level<1 and structure(m,"bed"):return
 if r.door_level<1 and structure(m,"door"):return
 if count(r,"generator")==0 and m.endless!=null:
  if count(r,"turret")<3 and r.buildings.size()<r.tile_count() and build(m,"turret"):return
  if r.door_level<2 and structure(m,"door"):return
  if r.bed_level<2 and structure(m,"bed"):return
  if r.gold<BalanceRules.price("generator",2).x:return
  if r.buildings.size()>=r.tile_count():
   for id in r.buildings:
    if r.buildings[id].kind=="turret":m.sell_building(id);return
  build(m,"generator");return
 super.act(m,strategy)
