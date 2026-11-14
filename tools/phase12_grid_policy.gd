extends "res://tools/phase12_test_policy.gd"
# Explicit infrastructure-oriented alternative to the principal fixed three policies.
func machine(m,kind):
 if kind!="generator":return super.machine(m,kind)
 var r=m.player();var ids=r.buildings.keys();ids.sort_custom(func(a,b):return r.buildings[a].level<r.buildings[b].level)
 for id in ids:
  var b=r.buildings[id]
  if b.kind!="generator" or b.level>=10:continue
  return m.specialize_building(id,"regulated") if b.level==4 else m.upgrade_building(id)
 return false
func act(m,_strategy):
 var r=m.player()
 if r.door_hp<r.max_hp()*.6 and (structure(m,"door") or m.repair_door()):return
 if count(r,"turret")==0 and build(m,"turret"):return
 if r.bed_level<1 and structure(m,"bed"):return
 if r.door_level<1 and structure(m,"door"):return
 if count(r,"generator")==0:
  build(m,"generator");return
 if m.run_kind=="endless" and r.buildings.size()>=r.tile_count()-1 and r.tile_count()<12 and m.expansion.purchase(m):return
 if count(r,"generator")<3 and build(m,"generator"):return
 if r.electricity<150 and machine(m,"generator"):return
 if count(r,"repair")==0 and build(m,"repair"):return
 if count(r,"economy")==0 and build(m,"economy"):return
 if count(r,"heavy")<2 and build(m,"heavy"):return
 if r.bed_level<9 and structure(m,"bed"):return
 if r.door_level<9 and structure(m,"door"):return
 if machine(m,"turret") or machine(m,"heavy"):return
 if machine(m,"economy"):return
 if machine(m,"repair"):return
