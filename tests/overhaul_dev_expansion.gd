extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 for id in MapCatalog.IDS:
  for legacy in [false,true]:
   var maximum=[]
   for i in range(6):
    var base=MapCatalog.map(id).rooms[i];var old=[];var old_bounds=Rect2();var bed=Vector2.ZERO;var door=Vector2.ZERO
    var first=RoomExpansion.legacy_tier(base.tiles.size()) if legacy else 0
    for tier in range(first,8):
     var data=RoomExpansion.geometry(id,i,tier,legacy)
     check(data.tiles.size()==RoomExpansion.SLOTS[tier],"exact registered slot tier")
     if tier==first:
      bed=data.bed;door=data.door
      if legacy:check(data.tiles==base.tiles and data.bounds==base.bounds and bed==base.bed and door==base.door,"old checkpoint geometry unchanged")
     else:
      check(data.bed==bed and data.door==door,"growth never moves occupied bed or doorway")
      check(data.bounds.get_area()>old_bounds.get_area(),"purchased expansion physically enlarges room")
     for j in range(old.size()):check(data.tiles[j]==old[j],"all prior pad coordinates retain exact positions")
     var obstacles=[Rect2(data.bed-Vector2(27,45),Vector2(54,89)),Rect2(data.cabinet+Vector2(-18,5),Vector2(36,20)),Rect2(data.plant+Vector2(-10,7),Vector2(20,14))]
     for point in data.tiles:
      var pad=Rect2(point-Vector2(27,27),Vector2(54,54));check(data.bounds.encloses(pad),"building footprint inside physical walls")
      for obstacle in obstacles:check(not pad.intersects(obstacle),"pad never overlaps character furniture %s legacy%s room%d tier%d at%s vs%s" % [id,legacy,i,tier,point,obstacle])
     old=data.tiles;old_bounds=data.bounds
    maximum.append(old_bounds)
   for i in range(6):
    for j in range(i):check(not maximum[i].intersects(maximum[j]),"maximum rooms do not overlap another room")
  var m=MatchModel.new();check(m.configure_endless(id,"standard",17,1),"real Endless configure")
  m.player_position=m.rooms[0].center();check(m.claim_room(0),"claim fresh three-pad room");m.player_position=m.player().bed_position();check(m.sleep_player(),"occupy front anchored bed")
  var r=m.player();check(r.tile_count()==3,"new run starts with exactly three usable slots")
  var first=r.layout.tiles.duplicate();var bed=r.bed_position();var door=r.door_position();var money=Vector2.ZERO
  r.bed_level=4;r.door_level=4;r.gold=1e6;r.electricity=1e6;r.door_hp=r.max_hp()
  for tier in range(1,8):
   var gold=r.gold;var power=r.electricity
   check(m.expansion.purchase(m),"actual paid next expansion "+str(tier));money+=RoomExpansion.COSTS[tier]
   check(is_equal_approx(gold-r.gold,RoomExpansion.COSTS[tier].x) and is_equal_approx(power-r.electricity,RoomExpansion.COSTS[tier].y),"exact separate resources paid once")
   check(r.tile_count()==RoomExpansion.SLOTS[tier] and r.bed_position()==bed and r.door_position()==door,"actual geometry matches purchased tier without moving room owner")
   for i in range(first.size()):check(r.tile_position(i)==first[i],"actual initial placements retain positions")
  check(not m.expansion.purchase(m) and r.tile_count()==16,"maximum rejects extra expansion")
  m.endless.phase="intermission";m.endless.completed=1;m.endless.sealed_wave=1;m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD
  var data=ReplaySnapshot.encode(m);check(not data.is_empty() and ReplaySnapshot.valid(JSON.parse_string(JSON.stringify(data))),"new geometry checkpoint JSON roundtrip is valid")
  var restored=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(data)))
  check(restored!=null and restored.player().tile_count()==16 and restored.player().bed_position()==bed and restored.player().layout.tiles==r.layout.tiles,"resume restores actual paid capacity and stable geometry")
 print("OVERHAUL_EXPANSION_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
