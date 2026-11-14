extends "res://tools/phase12_strategy_probe.gd"
# Alternative survival-oriented policy: redundant weapons and repairs before economy supports.
func machine(m,kind):
 var r=m.player();var ids=r.buildings.keys();ids.sort_custom(func(a,b):return r.buildings[a].level<r.buildings[b].level)
 for id in ids:
  var b=r.buildings[id]
  if b.kind!=kind or b.level>=10:continue
  return m.specialize_building(id,StrategyCatalog.branches(kind)[0]) if b.level==4 else m.upgrade_building(id)
 return false
func act(m,_strategy):
 var r=m.player()
 if r.door_hp<r.max_hp()*.8 and r.max_hp()-r.door_hp>Catalog.REPAIR_HEAL*r.repair_factor:
  if structure(m,"door") or m.repair_door():return
 if count(r,"turret")==0 and build(m,"turret"):return
 if r.bed_level<1 and structure(m,"bed"):return
 if r.door_level<1 and structure(m,"door"):return
 if count(r,"turret")<3 and build(m,"turret"):return
 if r.door_level<2 and structure(m,"door"):return
 if r.bed_level<2 and structure(m,"bed"):return
 if count(r,"generator")==0:
  build(m,"generator");return
 if count(r,"frost")==0 and build(m,"frost"):return
 if m.endless!=null and r.buildings.size()>=r.tile_count() and r.tile_count()<10 and m.expansion.purchase(m):return
 if r.electricity<30 and machine(m,"generator"):return
 if machine(m,"turret"):return
 if structure(m,"door"):return
 if structure(m,"bed"):return
 if machine(m,"generator"):return
 if machine(m,"frost"):return
