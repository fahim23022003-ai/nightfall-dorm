extends RefCounted
# Scripted QA policy; all prices/damage/production are production model calls.
var balance=2
func count(r,kind):return r.buildings.values().filter(func(b):return b.kind==kind).size()
func machine(m,kind):
 var r=m.player();var ids=r.buildings.keys();ids.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 for id in ids:
  var b=r.buildings[id]
  if b.kind!=kind or b.level>=10:continue
  if kind=="repair" and b.level>=4:return false # Deliberate base-stationL4 ceiling; identical to baseline effective behavior.
  if b.level==4:return m.specialize_building(id,"dividend" if kind=="economy" else "regulated" if kind=="generator" else "precision" if kind=="turret" else "focus" if kind=="heavy" else "efficient")
  return m.upgrade_building(id)
 return false
func build(m,kind):
 var r=m.player();var ids=[]
 for id in range(r.tile_count()):
  if not r.buildings.has(id):ids.append(id)
 ids.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 for id in ids:
  if m.buy(kind,id):return true
 return false
func structure(m,kind):
 var r=m.player();var level=r.bed_level if kind=="bed" else r.door_level
 if level==4 and (r.bed_branch if kind=="bed" else r.door_branch)=="":return r.specialize_structure(kind,"lucid" if kind=="bed" else "bulwark")
 return m.upgrade_bed() if kind=="bed" else m.upgrade_door()
func act(m,strategy):
 var r=m.player()
 var urgent=.25 if strategy=="greedy" else .55 if strategy=="balanced" else .78
 if r.door_hp<r.max_hp()*urgent:
  if structure(m,"door") or m.repair_door():return
 if strategy=="greedy" and r.bed_level<2:
  if structure(m,"bed") or structure(m,"door"):return
 if count(r,"turret")==0 and build(m,"turret"):return
 if r.bed_level<1 and structure(m,"bed"):return
 if r.door_level<1 and structure(m,"door"):return
 if count(r,"generator")==0 and build(m,"generator"):return
 if balance==2 and count(r,"generator")==0 and strategy!="greedy":return
 if balance==2 and r.electricity<40 and machine(m,"generator"):return
 if strategy=="defense" and machine(m,"turret"):return
 if r.bed_level<2 and structure(m,"bed"):return
 if r.door_level<2 and structure(m,"door"):return
 if m.run_kind=="endless" and r.buildings.size()>=r.tile_count()-1 and r.tile_count()<16 and m.expansion.purchase(m):return
 var amplification=3 if strategy=="greedy" else 1 if strategy=="balanced" else 0
 if count(r,"economy")<amplification and build(m,"economy"):return
 if strategy!="greedy" and count(r,"repair")==0 and build(m,"repair"):return
 if strategy=="greedy" and machine(m,"economy"):return
 if count(r,"generator")<2 and r.bed_level>=3 and build(m,"generator"):return
 if strategy=="balanced":
  if count(r,"heavy")==0 and build(m,"heavy"):return
  if machine(m,"heavy") or machine(m,"turret"):return
 if structure(m,"bed"):return
 if structure(m,"door"):return
 if machine(m,"generator"):return
 if strategy=="greedy" and count(r,"repair")==0 and build(m,"repair"):return
 if machine(m,"turret") or machine(m,"heavy") or machine(m,"repair"):return
 if count(r,"heavy")<3:build(m,"heavy")
