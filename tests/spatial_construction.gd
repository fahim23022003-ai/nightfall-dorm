extends "res://tests/replay_endless.gd"
# Prepared wallets exercise actual transactions, never economic reachability claims.
func free_point(r,exclude=Vector2.INF):
 var rect=r.bounds().grow(-30)
 for y in range(int(rect.position.y),int(rect.end.y),47):
  for x in range(int(rect.position.x),int(rect.end.x),49):
   var p=Vector2(x+.375,y+.625)
   if p.distance_to(exclude)>48 and r.spatial.geometry_reason(p)=="":return p
 return Vector2.INF
func fill(r,amount,kind="turret"):
 for i in range(amount):
  var p=free_point(r)
  if not p.is_finite():return false
  if not r.spatial.place(kind,p):return false
 return true
func fresh_and_expansion():
 for map in MapCatalog.IDS:
  for room_index in range(6):
   var m=MatchModel.new();m.configure_endless(map,"standard",71,1);m.claim_room(room_index);m.player_position=m.player().bed_position();m.sleep_player()
   var r=m.player();r.gold=1000000;r.electricity=1000000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
   check(r.spatial!=null and r.tile_count()==3,"all maps/orientations enable only human free room")
   for other in m.rooms:
    if other!=r:check(other.spatial==null,"NPC rooms remain fixed")
   check(fill(r,3),"three arbitrary fractional positions fit starting room")
   var original=r.buildings.duplicate(true);var wallet=[r.gold,r.electricity];var next=r.spatial.next_id
   check(not m.place_building("turret",free_point(r)) and r.buildings==original and [r.gold,r.electricity]==wallet and r.spatial.next_id==next,"capacity rejection is transactional")
   var anchors=[r.bed_position(),r.layout.cabinet,r.layout.plant]
   for tier in range(1,8):
    var before=r.buildings.duplicate(true);var gold=r.gold;var power=r.electricity
    check(m.expansion.purchase(m),"actual expansion purchases all tiers")
    check(r.tile_count()==RoomExpansion.SLOTS[tier] and is_equal_approx(gold-r.gold,RoomExpansion.COSTS[tier].x) and is_equal_approx(power-r.electricity,RoomExpansion.COSTS[tier].y),"exact capacity progression and unchanged prices")
    check(r.buildings==before and [r.bed_position(),r.layout.cabinet,r.layout.plant]==anchors,"expansion preserves structures and furniture")
    check(fill(r,r.tile_count()-r.buildings.size()),"new unlocked floor fills legitimate capacity")
   check(r.buildings.size()==16 and not m.expansion.purchase(m),"sixteen maximum; no extra expansion")
func placement_and_moves():
 var a=fixture();var m=a.m;var r=m.player();m.time=0
 var point=free_point(r);var gold=r.gold;var power=r.electricity
 for bad in [r.door_position(),r.bed_position(),r.layout.cabinet+Vector2(0,10),r.layout.plant+Vector2(0,10),r.bounds().position-Vector2.ONE,Vector2(INF,0),Vector2(NAN,0)]:
  check(not m.place_building("turret",bad) and r.buildings.is_empty() and r.gold==gold and r.electricity==power,"invalid geometry/furniture/nonfinite spends nothing")
 check(m.place_building("turret",point) and r.tile_position(16)==point,"chosen fractional world coordinates are stored exactly")
 var b=r.buildings[16].duplicate(true);gold=r.gold;power=r.electricity
 check(not m.place_building("generator",point) and r.buildings.size()==1 and r.gold==gold and r.electricity==power,"overlap cannot buy/charge")
 check(m.begin_building_move(16),"level1 begins move")
 check(not m.sell_building(16) and not m.upgrade_building(16) and not m.place_building("generator",free_point(r)),"reserved instance cannot sell/upgrade or purchase during move")
 check(not m.move_building(r.door_position()) and r.buildings[16]==b,"invalid move changes no building fields")
 m.cancel_building_move();check(r.buildings[16]==b and r.spatial.moving_id==-1,"one-action cancellation preserves original")
 var target=free_point(r,point);check(m.begin_building_move(16) and m.move_building(target),"valid move succeeds")
 b.position=target;check(r.buildings[16]==b and r.gold==gold and r.electricity==power,"identity, cooldown, ledger and economy preserved")
 m.time=m.preparation+1;check(not m.begin_building_move(16),"combat reposition rejected")
 check(m.place_building("generator",point),"legal combat construction preserved and vacated floor reusable")
 var refund=r.building_refund(16);gold=r.gold;power=r.electricity
 check(m.sell_building(16) and is_equal_approx(r.gold-gold,refund.x) and is_equal_approx(r.electricity-power,refund.y),"moved building refunds exact half actual eligible spend")
 check(not m.sell_building(16) and m.place_building("turret",target) and r.buildings.has(18),"no double refund or ID reuse")
 r.gold=0;gold=r.electricity;check(not m.place_building("heavy",free_point(r)) and r.electricity==gold,"insufficient resource transaction leaves state")
func all_buildings():
 for kind in Catalog.BUILDINGS:
  var a=fixture();var m=a.m;var r=m.player();m.time=0;r.gold=1000000;r.electricity=1000000
  var at=free_point(r);check(m.place_building(kind,at),kind+" free purchase")
  for level in range(2,11):
   var b=r.buildings[16]
   var ok=m.specialize_building(16,StrategyCatalog.branches(kind)[0]) if b.level==4 else m.upgrade_building(16)
   check(ok and r.buildings[16].level==level,kind+" actual level "+str(level))
  check(not m.upgrade_building(16),kind+" level11 rejected")
  r.buildings[16].cooldown=3.375;var before=r.buildings[16].duplicate(true);var to=free_point(r,at)
  check(m.begin_building_move(16) and m.move_building(to),kind+" L10 specialized move")
  before.position=to;check(before==r.buildings[16],kind+" every field except position unchanged")
  var investment=Vector2(before.invested_gold,before.invested_power);var gold=r.gold;var power=r.electricity
  check(m.sell_building(16) and is_equal_approx(r.gold-gold,investment.x*.5) and is_equal_approx(r.electricity-power,investment.y*.5),kind+" L10 refunds original and all upgrades")
func saves_and_combat():
 var old=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"));var m=Snapshot.restore(old)
 check(m!=null,"earned wave45 old schema migrates")
 if m==null:return
 var r=m.player();check(m.endless.completed==45 and r.spatial.relocations.is_empty() and r.buildings.size()==old.rooms[m.player_room].buildings.size(),"earned45 retains all original structures/positions/tier")
 var good=Snapshot.encode(m);check(Snapshot.valid(good),"migrated snapshot writer schema2 validates")
 var restored=Snapshot.restore(JSON.parse_string(JSON.stringify(good)))
 check(restored!=null and Support.numeric_same(Snapshot.encode(restored),good),"JSON replay roundtrip retains exact state/positions/IDs")
 var index=m.player_room
 var bad=good.duplicate(true);bad.rooms[index].buildings[0].erase("position");check(not Snapshot.valid(bad),"new schema missing position rejected")
 for value in [[INF,0],[NAN,0],[9999,9999],[0],["x",0]]:
  bad=good.duplicate(true);bad.rooms[index].buildings[0].position=value;check(not Snapshot.valid(bad),"malformed coordinates rejected")
 bad=good.duplicate(true);bad.rooms[index].buildings[1].position=bad.rooms[index].buildings[0].position;check(not Snapshot.valid(bad),"forged overlapping save rejected")
 bad=good.duplicate(true);bad.rooms[index].buildings[1].instance_id=bad.rooms[index].buildings[0].instance_id;check(not Snapshot.valid(bad),"duplicate instance UID rejected")
 bad=good.duplicate(true);bad.rooms[index].buildings[1].tile=bad.rooms[index].buildings[0].tile;check(not Snapshot.valid(bad),"duplicate selector rejected")
 bad=good.duplicate(true);bad.rooms[index].construction.next_id=1;check(not Snapshot.valid(bad),"invalid monotonic identity rejected")
 var a=fixture();m=a.m;r=m.player();m.time=0;var at=free_point(r)
 check(m.place_building("turret",at),"real weapon for relocated launch")
 var destination=r.fixed_tile_position(0)+Vector2(8,-3);check(m.begin_building_move(16) and m.move_building(destination),"relocation before real tick")
 m.time=m.preparation+.1;m.hunter.boss_policy.enabled=false;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=100
 m.tick(.01)
 check(not m.projectiles.is_empty() and m.projectiles[0].from==destination,"actual model tick launches projectile from new position")
 var hp=m.hunter.hp
 for i in range(50):m.tick(.05)
 check(m.hunter.hp<hp and r.shots>0,"relocated turret causes actual combat damage")
 clear_wave(a);check(a.p.checkpoint_endless(m),"new positions saved through actual profile checkpoint transaction")
 var loader=PlayerProfile.new(a.p.path);check(loader.load_profile(),"new profile disk reload")
 restored=loader.resume_endless();check(restored!=null and restored.player().tile_position(16)==destination,"Quit/Continue exact coordinates and identity")
func run():
 fresh_and_expansion();placement_and_moves();all_buildings();saves_and_combat()
 Support.cleanup(prefix)
 print("SPATIAL_CONSTRUCTION_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
