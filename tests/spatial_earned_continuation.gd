extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("SPATIAL EARNED: "+label)
func _initialize():call_deferred("run")
func run():
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var hash=FileAccess.get_sha256(source)
 var m=ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string(source)));check(m!=null,"actual earned45 restores")
 if m==null:quit(1);return
 var r=m.player();var initial_gold=r.gold;var initial_power=r.electricity;var relocated=-1
 for id in r.buildings:
  if r.buildings[id].kind!="turret":continue
  var before=r.buildings[id].duplicate(true)
  for offset in [Vector2(4,-2),Vector2(-4,2),Vector2(0,6)]:
   var to=r.tile_position(id)+offset
   if r.spatial.geometry_reason(to,id)=="":
    check(m.begin_building_move(id) and m.move_building(to),"earned L10 turret relocates legally")
    before.position=to;check(r.buildings[id]==before,"earned turret retains every other field");relocated=id;break
  if relocated>=0:break
 check(relocated>=0 and r.gold==initial_gold and r.electricity==initial_power,"relocation grants no resources")
 for id in r.buildings:
  if r.buildings[id].kind=="repair":
   while r.buildings[id].level<10:check(m.upgrade_building(id),"earned funds pay repair upgrades")
 for tile in range(r.tile_count()):
  if r.buildings.has(tile):continue
  var point=r.fixed_tile_position(tile)+Vector2(3,-1)
  if r.spatial.geometry_reason(point)!="":continue
  check(m.place_building("heavy",point),"earned funds buy actual off-pad Arc")
  var id=r.spatial.next_id-1
  while r.buildings[id].level<10:
   check(m.specialize_building(id,"focus") if r.buildings[id].level==4 else m.upgrade_building(id),"actual paid Arc upgrade/branch")
  if r.buildings.size()==16:break
 check(r.buildings.size()==16,"earned full16 without injected money")
 var before={"gold":r.gold,"electricity":r.electricity,"door_hp":r.door_hp};check(m.continue_wave("repair"),"normal wave46 Continue")
 var start=m.time;var max_hp=m.hunter.max_hp;var launches=0;var max_projectiles=0;var max_events=0;var observed={}
 for i in range(6000):
  m.tick(.1);max_projectiles=maxi(max_projectiles,m.projectiles.size());max_events=maxi(max_events,m.presentation_events.size())
  for shot in m.projectiles:
   if shot.room==r.index and not observed.has(shot.id):
    observed[shot.id]=true
    if shot.from==r.tile_position(relocated):launches+=1
  if m.result!="" or m.endless.phase=="intermission":break
 check(launches>0,"actual earned relocated turret fires")
 check(m.endless.phase=="intermission" and m.endless.completed==46 and r.alive,"real full-health Hell46 defeated with earned funds")
 check(max_projectiles<=256 and max_events<=128,"real advanced combat bounded collections")
 check(FileAccess.get_sha256(source)==hash,"canonical source untouched")
 var result={"checks":checks,"failures":failures,"source_sha256":hash,"starting_gold":initial_gold,"starting_electricity":initial_power,"before_wave":before,"final_gold":r.gold,"final_electricity":r.electricity,"final_door_hp":r.door_hp,"hunter_max_hp":max_hp,"hunter_hp":m.hunter.hp,"elapsed_sim_seconds":m.time-start,"relocated_selector":relocated,"relocated_launches":launches,"max_projectiles":max_projectiles,"max_events":max_events,"completed":m.endless.completed,"setup":"Canonical earned45, paid repair and four Arc10 investments from original funds, legal same-instance off-pad relocation, normal Reinforce/Continue, .1s actual ticks. No free resources or Hunter HP edits, automated strategy not natural1→46/human playtest."}
 var f=FileAccess.open("res://docs/evidence/freedom-to-build/earned46.json",FileAccess.WRITE);f.store_string(JSON.stringify(result," "))
 print("SPATIAL_EARNED_CHECKS=",checks," FAILURES=",failures," RESULT=",result);quit(1 if failures else 0)
