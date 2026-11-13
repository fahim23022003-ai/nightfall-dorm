extends SceneTree
# Independent expansion acceptance. Injected budgets isolate geometry/transactions;
# this is not evidence that the full progression is naturally earned.
var checks=0
var failures=0
var cases=[]
func ck(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1;push_error(label)
func _initialize():call_deferred("run")
func fresh(id: String,index=0,legacy=false):
 var m=MatchModel.new()
 ck(m.configure_endless(id,"standard",71,900),"actual Endless configure")
 if legacy:ck(m.expansion.configure(m,true),"legacy static geometry selected")
 ck(m.claim_room(index),"actual room ownership")
 m.player_position=m.player().bed_position();ck(m.sleep_player(),"actual occupied room")
 return m
func rich(r):
 r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=1e6;r.electricity=1e6
func seal(m):
 m.endless.phase="intermission";m.endless.completed=1;m.endless.sealed_wave=1;m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD
 return ReplaySnapshot.encode(m)
func roundtrip(data):return JSON.parse_string(JSON.stringify(data))
func unchanged(r,before):
 return r.gold==before.x and r.electricity==before.y and r.tile_count()==3 and r.expansion_tier==0
func geometry_matrix():
 for id in MapCatalog.IDS:
  var source=MapCatalog.map(id)
  for room_index in range(6):
   var prior=[];var old_area=0.0;var fixed_door=Vector2.ZERO;var fixed_bed=Vector2.ZERO
   for tier in range(8):
    var g=RoomExpansion.geometry(id,room_index,tier)
    ck(g.tiles.size()==[3,6,8,10,11,12,14,16][tier],"exact fresh capacity")
    if tier==0:fixed_door=g.door;fixed_bed=g.bed
    ck(g.door==fixed_door and g.bed==fixed_bed,"front door and occupied bed stable")
    ck(g.bounds.get_area()>old_area,"physical area grows at every paid step")
    for n in range(prior.size()):ck(g.tiles[n]==prior[n],"append-only ID prefix")
    var obstacles=[Rect2(g.bed-Vector2(27,45),Vector2(54,89)),Rect2(g.cabinet+Vector2(-18,5),Vector2(36,20)),Rect2(g.plant+Vector2(-10,7),Vector2(20,14))]
    for n in range(g.tiles.size()):
     var p=g.tiles[n];var footprint=Rect2(p-Vector2(27,27),Vector2(54,54))
     ck(g.bounds.grow(-4).encloses(footprint),"pad fits inside wall clearance")
     for obs in obstacles:ck(not footprint.intersects(obs),"no pad/furniture/resident overlap")
     for j in range(n):ck(p.distance_to(g.tiles[j])>=54,"machine footprints do not overlap")
    var normal: Vector2=g.door_normal
    ck(absf((g.bounds.end.y if normal.y>0 else g.bounds.position.y)-g.door.y)<.001 if absf(normal.y)>0 else absf((g.bounds.end.x if normal.x>0 else g.bounds.position.x)-g.door.x)<.001,"door stays in correct wall")
    for corridor in source.corridors:
     # The authored door connection touches the front wall; grown back-space
     # must not swallow unrelated corridors.
     var overlap=g.bounds.intersection(corridor)
     var historical_overlap=source.rooms[room_index].bounds.intersection(corridor)
     ck(not overlap.has_area() or overlap.get_area()<=historical_overlap.get_area()+.001,"expansion does not newly cover corridor route %s room%d tier%d" % [id,room_index,tier])
    prior=g.tiles;old_area=g.bounds.get_area()
   for other in range(room_index):ck(not gmax(id,room_index).bounds.intersects(gmax(id,other).bounds),"maximum rooms remain disjoint")
func gmax(id,index):return RoomExpansion.geometry(id,index,7)
func navigation_matrix(id):
 var m=MatchModel.new();ck(m.configure_endless(id,"standard",11,901),"navigation matrix actual run")
 for tier in [0,7]:
  ck(m.expansion.configure(m,false,[tier,tier,tier,tier,tier,tier]),"navigation matrix geometry install")
  for r in m.rooms:
   ck(m.navigation_walkable(r.bed_position()),"all actual resident footpoints navigable %s room%d tier%d" % [id,r.index,tier])
   var route=m.navigation_path(r.door_approach(),r.bed_position())
   ck(not route.is_empty(),"all actual door to resident paths valid %s room%d tier%d" % [id,r.index,tier])
func transactions(id):
 var m=fresh(id);var r=m.player();var original=r.layout.duplicate(true)
 var before=Vector2(r.gold,r.electricity)
 ck(not m.expansion.purchase(m) and unchanged(r,before),"low structure level cannot expand or charge")
 r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=119;r.electricity=100
 before=Vector2(r.gold,r.electricity)
 ck(not m.expansion.purchase(m) and unchanged(r,before),"insufficient Gold atomic rejection")
 r.gold=1000;r.electricity=14;before=Vector2(r.gold,r.electricity)
 ck(not m.expansion.purchase(m) and unchanged(r,before),"insufficient Electricity atomic rejection")
 r.electricity=1000;before=Vector2(r.gold,r.electricity)
 ck(not m.expansion.purchase(m,1) and unchanged(r,before),"cannot expand teammate room")
 ck(not m.expansion.purchase(m,999) and unchanged(r,before),"invalid room rejected")
 r.sleeping=false;ck(not m.expansion.purchase(m) and unchanged(r,before),"unoccupied room rejected");r.sleeping=true
 r.alive=false;ck(not m.expansion.purchase(m) and unchanged(r,before),"eliminated room rejected");r.alive=true
 m.running=false;ck(not m.expansion.purchase(m) and unchanged(r,before),"nonrunning rejected");m.running=true
 m.result="defeat";ck(not m.expansion.purchase(m) and unchanged(r,before),"terminal rejected");m.result=""
 rich(r)
 ck(not m.buy("turret",3),"locked next pad not directly buyable")
 ck(m.buy("turret",0),"legitimate machine placed before expansion")
 var invested=r.buildings[0].duplicate(true);var pos=r.tile_position(0);var coupon_calls=[0]
 r.coupon_armed=true;r.coupon_payment=func(_saved):coupon_calls[0]+=1;return true
 for tier in range(1,8):
  r.coupon_armed=true
  var wallet=Vector2(r.gold,r.electricity);var positions=r.layout.tiles.duplicate();var area=r.bounds().get_area();var player=m.player_position
  m._navigation_routes["qa_stale"]={"goal":Vector2.ZERO,"last":Vector2.ZERO,"route":[Vector2.ZERO]}
  ck(m.expansion.purchase(m),"valid paid expansion")
  ck(r.coupon_armed,"expansion leaves machine coupon armed")
  ck(Vector2(r.gold,r.electricity).is_equal_approx(wallet-RoomExpansion.COSTS[tier]),"exact Gold/Electricity debit")
  ck(r.bounds().get_area()>area and r.tile_count()==RoomExpansion.SLOTS[tier],"actual physical area and usable pads grow")
  ck(r.buildings[0]==invested and r.tile_position(0)==pos,"existing machine and actual investment preserved")
  ck(m.player_position==player and r.bed_position()==original.bed and r.door_position()==original.door,"no owner teleport or furniture relocation")
  ck(m._navigation_routes.is_empty(),"stale routes invalidated")
  ck(m.map_data.rooms[r.index].bounds==r.bounds() and m.map_bounds().encloses(r.bounds()),"renderer/navigation/map bounds synchronized")
  for n in range(positions.size()):ck(r.tile_position(n)==positions[n],"live bought pad prefix stable")
  var route=m.navigation_path(r.door_approach(),r.bed_position())
  ck(not route.is_empty() and route[-1].distance_to(r.bed_position())<.01,"actual Hunter route reaches resident after expansion %s tier%d" % [id,tier])
  var from=r.door_approach()
  for p in route:ck(m._visible(from,p),"navigation segment does not cut wall/furniture");from=p
  var last=r.tile_count()-1
  ck(m.buy("turret",last),"last unlocked pad accepts real purchase")
  var eligible=Vector2(r.buildings[last].invested_gold,r.buildings[last].invested_power);var sale_wallet=Vector2(r.gold,r.electricity)
  ck(r.sell_building(last),"real sale from newly unlocked position")
  ck(Vector2(r.gold,r.electricity).is_equal_approx(sale_wallet+eligible*.5),"sale refunds exactly half actual machine spend, never expansion")
  ck(not r.sell_building(last),"no duplicate refund")
 ck(not r.coupon_armed and coupon_calls[0]==7,"only seven successful machine purchases consume seven coupons")
 var wallet=Vector2(r.gold,r.electricity)
 ck(not m.expansion.purchase(m) and wallet==Vector2(r.gold,r.electricity),"ultimate maximum rejection no debit")
 ck(not m.buy("turret",16),"seventeenth slot rejected")
 var data=seal(m);ck(not data.is_empty(),"current checkpoint encodes")
 if data.is_empty():return
 var restored=ReplaySnapshot.restore(roundtrip(data))
 ck(restored!=null,"current checkpoint JSON restores")
 if restored!=null:
  ck(restored.player().layout==r.layout,"physical geometry exact after reload")
  ck(restored.player().buildings[0].invested_gold==invested.invested_gold and restored.player().gold==r.gold and restored.player().electricity==r.electricity,"capital and wallets restored once")
  ck(restored.player().tile_count()==16 and restored.expansion.legacy==false,"final fresh expansion tier persists")
 for bad in [null,{}, {"version":1,"legacy":false,"levels":[0,0,0,0,0]}, {"version":1,"legacy":false,"levels":[8,0,0,0,0,0]}, {"version":1,"legacy":false,"levels":[-1,0,0,0,0,0]}, {"version":1,"legacy":false,"levels":[1.5,0,0,0,0,0]}, {"version":1,"legacy":"yes","levels":[0,0,0,0,0,0]}]:
  var corrupt=data.duplicate(true);corrupt.expansion=bad;ck(not ReplaySnapshot.valid(corrupt) and ReplaySnapshot.restore(corrupt)==null,"malformed geometry rejected safely")
 var missing=data.duplicate(true);missing.erase("expansion");ck(not ReplaySnapshot.valid(missing),"v4 cannot omit geometry header")
 var locked=data.duplicate(true);locked.expansion.levels[0]=0;locked.rooms[0].buildings.append({"tile":15,"kind":"turret","level":1,"specialization":"","invested_gold":20.0,"invested_power":0.0,"cooldown":0.0})
 ck(not ReplaySnapshot.valid(locked),"high-ID building invalid for locked geometry")
 cases.append({"map":id,"current_roundtrip":restored!=null,"slots":r.tile_count()})
func legacy_migration(id):
 for room_index in [0,1,3]:
  var m=fresh(id,room_index,true);var r=m.player();rich(r)
  var last=r.tile_count()-1
  ck(m.buy("turret",last),"legacy high pad building paid")
  var where=r.tile_position(last);var layout=r.layout.duplicate(true);var data=seal(m)
  ck(not data.is_empty(),"legacy-static v4 can encode")
  if data.is_empty():continue
  for rules in [1,2,3]:
   var old=data.duplicate(true);old.version=1;old.ruleset=rules;old.erase("expansion")
   for saved in old.rooms:
    saved.erase("construction")
    for b in saved.buildings:b.erase("position");b.erase("instance_id")
   ck(ReplaySnapshot.valid(old),"historical ruleset remains accepted")
   var restored=ReplaySnapshot.restore(roundtrip(old))
   ck(restored!=null,"historical checkpoint restores")
   if restored==null:continue
   var rr=restored.player()
   ck(rr.tile_count()==r.tile_count() and rr.layout==layout and rr.tile_position(last)==where,"legacy capacity and every world coordinate preserved")
   ck(rr.buildings.has(last) and rr.buildings[last].invested_gold==r.buildings[last].invested_gold,"legacy high-ID capital retained")
   ck(restored.expansion.legacy,"legacy mode explicitly retained")
   var prefix=rr.layout.tiles.duplicate()
   if rr.expansion_tier<7:
    ck(restored.expansion.purchase(restored),"legacy checkpoint can buy next physical room growth")
    for n in range(prefix.size()):ck(rr.tile_position(n)==prefix[n],"legacy upgrade does not shift old columns")
func campaign_unchanged(id):
 var m=MatchModel.new();ck(m.configure_map(id),"campaign configure")
 var capacities=[]
 for i in range(6):
  ck(m.rooms[i].layout==MapCatalog.map(id).rooms[i],"campaign authored geometry unchanged")
  capacities.append(m.rooms[i].tile_count())
 ck(not m.expansion.configure(m) and not m.expansion.purchase(m),"campaign cannot use Endless expansion")
 for i in range(6):ck(m.rooms[i].tile_count()==capacities[i],"failed expansion cannot alter campaign slots")
func run():
 geometry_matrix()
 for id in MapCatalog.IDS:
  navigation_matrix(id);transactions(id);legacy_migration(id);campaign_unchanged(id)
 var receipt={"checks":checks,"failures":failures,"cases":cases,"scope":"Controlled injected-budget actual model purchases, geometry/navigation and JSON checkpoint migration. Not natural earning, rendered quality, native Windows or full integration acceptance."}
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/qa-expansion-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt," "))
 print("OVERHAUL_QA_EXPANSION_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
