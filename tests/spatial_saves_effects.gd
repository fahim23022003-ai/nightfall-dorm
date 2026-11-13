extends "res://tests/spatial_construction.gd"
func legacy_layouts():
 for map in MapCatalog.IDS:
  var a=fixture(map);clear_wave(a);var data=Snapshot.encode(a.m)
  data.version=1;data.ruleset=4;data.expansion.legacy=true
  var index=a.m.player_room
  for i in range(6):
   data.expansion.levels[i]=7 if i==index else RoomExpansion.legacy_tier(MapCatalog.map(map).rooms[i].tiles.size())
   var layout=RoomExpansion.geometry(map,i,int(data.expansion.levels[i]),true)
   data.rooms[i].position=Snapshot.pair(layout.bed);data.rooms[i].erase("construction")
   if i==index:
    data.player_position=Snapshot.pair(layout.bed);data.rooms[i].buildings=[]
    for tile in range(16):data.rooms[i].buildings.append({"tile":tile,"kind":"turret","level":1,"specialization":"","invested_gold":20,"invested_power":0,"cooldown":.375})
   else:
    for b in data.rooms[i].buildings:b.erase("instance_id");b.erase("position")
  check(Snapshot.valid(data),"old full16 legacy schema valid "+map)
  var restored=Snapshot.restore(data)
  check(restored!=null,"old original-layout migration finds all safe positions "+map)
  if restored!=null:
   var r=restored.player();check(r.buildings.size()==16 and r.tile_count()==16 and r.gold==data.rooms[index].gold,"no lost buildings/capacity/wallet in old original geometry "+map)
   check(not Snapshot.encode(restored).is_empty(),"migrated legacy full16 writes valid new schema "+map)
   for id in r.buildings:check(r.buildings[id].cooldown==.375 and r.buildings[id].invested_gold==20 and r.spatial.geometry_reason(r.tile_position(id),id)=="","legacy state and legal footprint "+map)
   print("LEGACY_LAYOUT ",map," RELOCATIONS=",r.spatial.relocations)
func near_point(r):
 var best=Vector2.INF;var distance=INF;var rect=r.bounds().grow(-30)
 for y in range(int(rect.position.y),int(rect.end.y),17):
  for x in range(int(rect.position.x),int(rect.end.x),19):
   var p=Vector2(x+.375,y+.625)
   if r.spatial.geometry_reason(p)=="" and p.distance_to(r.door_approach())<distance:best=p;distance=p.distance_to(r.door_approach())
 return best
func recovery_and_effects():
 var a=fixture();var m=a.m;var r=m.player();m.time=0
 for i in range(7):check(m.expansion.purchase(m),"effect full-room real expansions")
 for kind in ["generator","repair","economy","enhancer","auto_repair","shield","decoy","barrier","plasma","antenna","turret","heavy","flame","frost","shock","turret"]:check(m.place_building(kind,near_point(r) if kind in DefenseEffects.WEAPONS else free_point(r)),"all15 categories legal physical arrangement")
 var state=r.buildings.duplicate(true);var income=r.income_rate();var electricity=r.electricity;r.tick_economy(1)
 check(r.electricity>electricity and r.income_rate()==income,"positioned production/support actual economy ticks")
 m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach()
 var hp=r.door_hp;r.door_hp-=50;MagicDefense.tick(m,.01)
 check(r.magic_state.shield>0,"positioned Antenna creates real bounded ward")
 var shield=r.magic_state.shield;m.apply_room_damage(r.index,10,"test_magic",1,true,{"type":"magic","element":"ice"})
 check(r.magic_state.shield<shield and r.door_hp==hp-50,"ward actually absorbs magic")
 r.magic_state.shield=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach();m.hunter.target=0
 var hunter_hp=m.hunter.hp;m.apply_room_damage(r.index,30,"test_magic",1,true,{"type":"magic","element":"ice"})
 check(r.magic_state.stored>0 and m.hunter.hp<hunter_hp,"positioned Plasma absorption and Barrier reflection remain real")
 var stored=r.magic_state.stored;hp=r.door_hp;MagicDefense.tick(m,.1)
 check(r.door_hp>hp and r.magic_state.stored<stored,"Plasma release repairs real damage")
 m.time=m.preparation+.1;m.hunter.boss_policy.enabled=false;m.hunter.cooldown=100
 for i in range(200):m.tick(.05)
 check(r.shots>0 and m.hunter.hp<hunter_hp and r.buildings.size()==16,"full16 live ticks: attacks, support and bounded objects")
 print("FULL16_TICKS projectiles=",m.projectiles.size()," combat_events=",m.combat_events.size()," presentation_events=",m.presentation_events.size()," shots=",r.shots)
 clear_wave(a);check(a.p.checkpoint_endless(m) and a.p.save_profile(),"disk primary and backup hold valid spatial checkpoint")
 var primary=JSON.parse_string(FileAccess.get_file_as_string(a.p.path));primary.replay.checkpoint.rooms[m.player_room].buildings[0].position=[99999,0]
 var file=FileAccess.open(a.p.path,FileAccess.WRITE);file.store_string(JSON.stringify(primary));file.close()
 var bad_bytes=FileAccess.get_file_as_string(a.p.path);var loader=PlayerProfile.new(a.p.path)
 check(loader.load_profile() and not loader.read_only and loader.warning.contains("backup"),"corrupt-coordinate primary recovers known-good backup")
 check(FileAccess.get_file_as_string(a.p.path)==bad_bytes and loader.resume_endless()!=null,"recovery preserves corrupt primary bytes and valid continuation")
 var valid=loader.replay.checkpoint.duplicate(true);loader.replay.checkpoint.rooms[m.player_room].buildings[0].position=[INF,0]
 check(not loader.save_profile() and FileAccess.get_file_as_string(a.p.path)==bad_bytes,"invalid in-memory spatial state cannot overwrite known disk generations")
 loader.replay.checkpoint=valid
func recovery_preserves_spent_stock():
 var a=fixture("abandoned_dorm","standard",71,["repair"]);var m=a.m;var p=a.p
 clear_wave(a);check(p.checkpoint_endless(m),"checkpoint before real permanent item use")
 check(m.continue_wave("power"),"real next-wave transition")
 m.time=m.preparation+.1;m.player().door_hp-=100
 check(p.activate_item(0,m,a.id),"actual post-checkpoint Repair consumes saved stock")
 var stock=p.inventory.duplicate(true);var ledger=p.active_match.duplicate(true);var cash=p.rm_cash;var xp=p.xp
 var data=JSON.parse_string(FileAccess.get_file_as_string(p.path));data.replay.checkpoint.rooms[m.player_room].buildings[0].position=[99999,0]
 var f=FileAccess.open(p.path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 f=FileAccess.open(p.path+".tmp",FileAccess.WRITE);f.store_string("{partial write");f.close()
 var loaded=PlayerProfile.new(p.path)
 check(loaded.load_profile() and not loaded.read_only and loaded.resume_endless()!=null,"checkpoint-only backup recovery ignores incomplete tmp")
 check(loaded.inventory==stock and Support.numeric_same(loaded.active_match,ledger) and loaded.rm_cash==cash and loaded.xp==xp,"recovery cannot rewind real consumed inventory, use ledger, cash or XP")
 data.replay.checkpoint.ruleset=Snapshot.RULESET+1
 f=FileAccess.open(p.path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close();var future_bytes=FileAccess.get_file_as_string(p.path)
 var future=PlayerProfile.new(p.path);future.load_profile()
 check(future.read_only and future.resume_endless()==null and FileAccess.get_file_as_string(p.path)==future_bytes,"unknown future ruleset stays preserved read-only even with a valid older backup")
func move_event_origin():
 var a=fixture();var m=a.m;var r=m.player();m.time=0
 check(m.place_building("turret",r.fixed_tile_position(0)+Vector2(3,-2)),"move-audio real paid source")
 var before=r.tile_position(16);var to=r.fixed_tile_position(1)+Vector2(4,-3);var wallet=[r.gold,r.electricity]
 check(m.begin_building_move(16) and m.move_building(to),"move-audio real commit")
 var event=m.presentation_events.back()
 check(event.type=="building_moved" and event.position==to and event.from==before and event.to==to and event.instance_id==r.buildings[16].instance_id,"production presentation/audio event uses actual destination and stable identity")
 check([r.gold,r.electricity]==wallet,"move cue cannot charge resources")
func run():
 legacy_layouts();recovery_and_effects();recovery_preserves_spent_stock();move_event_origin();Support.cleanup(prefix)
 print("SPATIAL_SAVES_EFFECTS_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
