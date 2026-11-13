extends SceneTree
func _initialize(): call_deferred("run")
func build_empty(room,kind):
 for tile in range(room.tile_count()):
  if not room.buildings.has(tile): return room.build(kind,tile)
 return false
func stacked_policy(room):
 if room.door_hp<room.max_hp()*0.3 and room.repair_door(): return
 if room.bed_level<2:
  if room.door_level<maxi(0,room.bed_level-1): room.upgrade_door()
  else: room.upgrade_bed()
  return
 if room.door_level<2:
  room.upgrade_door()
  return
 if not BotAI.has_kind(room,"generator"):
  build_empty(room,"generator")
  return
 var amplifiers=0
 for b in room.buildings.values():
  if b.kind=="economy": amplifiers+=1
 if amplifiers<2:
  build_empty(room,"economy")
  return
 if room.buildings.size()<room.tile_count():
  build_empty(room,"turret")
  return
 for tile in room.buildings:
  if room.buildings[tile].kind=="turret" and room.buildings[tile].level<4:
   room.upgrade_building(tile)
   return
func run():
 var failures=0
 var total=0
 var wins=0
 var losses=0
 var unresolved=0
 for definition in StageCatalog.STAGES:
  var stage_wins=0
  var stage_losses=0
  for difficulty in ["standard","hard"]:
   for room_index in range(6):
    for strategy in (["balanced","passive","stacked"] if definition.id in ["stage_2","stage_5"] else ["balanced","passive"]):
     var model=MatchModel.new()
     model.reset(11)
     model.configure_match(difficulty)
     if not model.configure_stage(definition.id):
      failures+=1
      continue
     model.claim_room(room_index)
     var room=model.player()
     model.player_position=room.bed_position()
     model.sleep_player()
     room.profile=strategy
     var steps=0
     var max_buildings=0
     var peak_hunter=1
     var max_step=0.0
     var illegal_steps=0
     var strategy_clock=0.0
     while model.result=="" and steps<18000:
      if strategy=="balanced": BotAI.tick(room,0.1)
      elif strategy=="stacked":
       strategy_clock-=0.1
       if strategy_clock<=0:
        stacked_policy(room)
        strategy_clock=0.45
      var previous=model.hunter.position
      model.tick(0.1)
      var moved=previous.distance_to(model.hunter.position)
      max_step=maxf(max_step,moved)
      # Temporary dash/concealment speeds may expire before terminal. Compare
      # every actual move with that frame's speed, never a run max to final speed.
      if moved>model.hunter.speed*0.1+0.1:illegal_steps+=1
      max_buildings=maxi(max_buildings,room.buildings.size())
      peak_hunter=maxi(peak_hunter,model.hunter.level)
      if room.gold< -0.0001 or room.electricity< -0.0001 or not is_finite(room.gold) or not is_finite(room.electricity):
       failures+=1
       break
      var owners=[]
      for resident in model.rooms:
       if resident.owner>=0:
        if resident.owner in owners: failures+=1
        owners.append(resident.owner)
      steps+=1
     total+=1
     if model.result=="victory":
      wins+=1
      stage_wins+=1
     elif model.result=="defeat":
      losses+=1
      stage_losses+=1
     else:
      unresolved+=1
      failures+=1
     if illegal_steps>0:
      failures+=1
      push_error("MAP SIM illegal movement steps %d for %s/%s/room%d/%s" % [illegal_steps,definition.id,difficulty,room_index,strategy])
     print("MAP_SIM stage=",definition.id," map=",model.map_id," difficulty=",difficulty," room=",room_index+1," strategy=",strategy," result=",model.result," time=",snappedf(model.time,0.1)," buildings=",max_buildings," shots=",model.shots," hunter_level=",peak_hunter," max_step=",snappedf(max_step,0.01))
  print("MAP_OUTCOMES stage=",definition.id," wins=",stage_wins," losses=",stage_losses)
  if stage_wins==0 or stage_losses==0:
   failures+=1
   push_error("MAP SIM missing tested victory/defeat for "+definition.id)
 print("MAP_SIMULATIONS=",total," WINS=",wins," LOSSES=",losses," UNRESOLVED=",unresolved," FAILURES=",failures)
 quit(0 if failures==0 else 1)
