extends SceneTree
func _initialize(): call_deferred("run")
func empty(room,kind):
 for tile in range(room.tile_count()):
  if not room.buildings.has(tile): return room.build(kind,tile)
 return false
func count(room,kind):
 var n=0
 for b in room.buildings.values():
  if b.kind==kind: n+=1
 return n
func act(room,strategy):
 if room.door_hp<room.max_hp()*0.35 and (room.upgrade_door() or room.repair_door()): return
 if room.bed_level<1:
  room.upgrade_bed()
  return
 if room.door_level<1:
  room.upgrade_door()
  return
 if strategy=="turret_rush" and count(room,"turret")<5:
  empty(room,"turret")
  return
 if not BotAI.has_kind(room,"generator"):
  empty(room,"generator")
  return
 if room.bed_level<2:
  room.upgrade_bed()
  return
 if room.door_level<2:
  room.upgrade_door()
  return
 if strategy=="economy_stack" and count(room,"economy")<4:
  empty(room,"economy")
  return
 if room.buildings.size()<room.tile_count():
  empty(room,"turret")
  return
 for tile in room.buildings:
  if room.buildings[tile].kind=="turret" and room.buildings[tile].level<4:
   room.upgrade_building(tile)
   return
func run():
 var failures=0
 var matches=0
 for definition in StageCatalog.STAGES:
  var geometry=MatchModel.new()
  geometry.configure_stage(definition.id)
  for room in geometry.rooms:
   var needle=0
   var arc=0
   for tile in range(room.tile_count()):
    var distance=room.tile_position(tile).distance_to(room.door_approach())
    if distance<=Catalog.BUILDINGS.turret.range: needle+=1
    if distance<=Catalog.BUILDINGS.heavy.range: arc+=1
   print("MAP_TACTIC map=",geometry.map_id," room=",room.index+1," slots=",room.tile_count()," own_door_needle=",needle," own_door_arc=",arc," size=",room.bounds().size)
 if "--geometry-only" in OS.get_cmdline_user_args():
  quit(0)
  return
 for stage_id in ["stage_2","stage_5"]:
  for difficulty in ["standard","hard"]:
   for index in range(6):
    for strategy in ["balanced","turret_rush","economy_stack"]:
     var model=MatchModel.new()
     model.reset(7)
     model.configure_match(difficulty)
     model.configure_stage(stage_id)
     model.claim_room(index)
     var room=model.player()
     model.player_position=room.bed_position()
     model.sleep_player()
     room.profile="balanced"
     var steps=0
     var timer=0.0
     var peak_buildings=0
     while model.result=="" and steps<18000:
      if strategy=="balanced": BotAI.tick(room,0.1)
      else:
       timer-=0.1
       if timer<=0:
        act(room,strategy)
        timer=0.5
      model.tick(0.1)
      peak_buildings=maxi(peak_buildings,room.buildings.size())
      steps+=1
     matches+=1
     if model.result=="" or room.gold<0 or room.electricity<0: failures+=1
     print("BALANCE_PROBE stage=",stage_id," difficulty=",difficulty," room=",index+1," strategy=",strategy," result=",model.result," time=",snappedf(model.time,0.1)," buildings=",peak_buildings," gold=",snappedf(room.gold,0.1)," hunter_hp=",snappedf(model.hunter.hp,0.1)," player_damage=",snappedf(room.damage_dealt,0.1))
 print("BALANCE_PROBE_MATCHES=",matches," FAILURES=",failures)
 quit(0 if failures==0 else 1)
