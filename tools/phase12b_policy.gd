extends "res://tools/phase12_test_policy.gd"
var style="bulwark"
var allow_repair=true
func machine(m,kind):
 var r=m.player();var ids=r.buildings.keys();ids.sort_custom(func(a,b):return r.buildings[a].level<r.buildings[b].level)
 for id in ids:
  var b=r.buildings[id]
  if b.kind!=kind or b.level>=10:continue
  return m.specialize_building(id,StrategyCatalog.branches(kind)[0]) if b.level==4 else m.upgrade_building(id)
 return false
func act(m,_strategy):
 var r=m.player()
 if r.door_hp<=0:return
 # React at a one-second decision cadence, preserving a fundable upgrade before
 # falling back to repairs. Stop spending on secondary goals while saving.
 if r.door_hp<r.max_hp()*.50:
  if structure(m,"door"):return
  if allow_repair and r.max_hp()-r.door_hp>=Catalog.REPAIR_HEAL*r.repair_factor and m.repair_door():return
 if count(r,"turret")==0:
  build(m,"turret");return
 if r.bed_level<1:structure(m,"bed");return
 if r.door_level<1:structure(m,"door");return
 if style=="assault" and count(r,"turret")<2:build(m,"turret");return
 if r.bed_level<2:structure(m,"bed");return
 if r.door_level<2:structure(m,"door");return
 if count(r,"generator")==0:build(m,"generator");return
 if style=="bulwark":
  for b in r.buildings.values():
   if b.kind=="turret" and b.level<2:machine(m,"turret");return
  if r.door_level<3:structure(m,"door");return
  if count(r,"auto_repair")==0:build(m,"auto_repair");return
  if count(r,"frost")==0:build(m,"frost");return
 else:
  if count(r,"frost")==0:build(m,"frost");return
  if count(r,"turret")<3:build(m,"turret");return
  var need=false
  for b in r.buildings.values():
   if b.kind=="turret" and b.level<2:need=true
  if need:machine(m,"turret");return
  if count(r,"frost")==0:build(m,"frost");return
  if r.door_level<3:structure(m,"door");return
 if r.bed_level<3:structure(m,"bed");return
 if r.door_level<4:structure(m,"door");return
 if count(r,"flame")==0:build(m,"flame");return
 if machine(m,"generator"):return
 if machine(m,"turret") or machine(m,"frost") or machine(m,"auto_repair") or machine(m,"flame"):return
 if structure(m,"door"):return
 structure(m,"bed")
