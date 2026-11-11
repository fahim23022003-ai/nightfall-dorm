extends SceneTree

func clone_room(room):
 var copy=RoomState.new(room.index)
 for property in ["owner","alive","sleeping","gold","electricity","bed_level","door_level","door_hp"]:
  copy.set(property,room.get(property))
 copy.buildings=room.buildings.duplicate(true)
 return copy

func has_affordable_decision(room):
 # Exercise real production transactions on isolated copies. Never mutate the live room.
 if clone_room(room).upgrade_bed() or clone_room(room).upgrade_door() or clone_room(room).repair_door():
  return true
 for tile in range(6):
  if room.buildings.has(tile):
   if clone_room(room).upgrade_building(tile): return true
  else:
   for kind in Catalog.BUILDINGS:
    if clone_room(room).build(kind,tile): return true
 return false

func _initialize(): call_deferred("run")
func run():
 var failures=0
 var scenarios=0
 for strategy in ["passive","balanced","guard","economist"]:
  for seed_value in [7,8,99]:
   var game=MatchModel.new()
   game.reset(seed_value)
   game.claim_room(seed_value%6)
   var room=game.player()
   room.profile=strategy
   game.player_position=room.bed_position()
   game.sleep_player()
   var previous_purchase=0.0
   var gaps=[]
   var forced=0.0
   var available_wait=0.0
   var max_forced=0.0
   var max_available_wait=0.0
   var purchases=0
   for step in range(18000):
    if game.result!="": break
    var original=[room.gold,room.electricity,room.spent,room.bed_level,room.door_level,room.door_hp,room.last_error,room.buildings.duplicate(true)]
    var affordable=has_affordable_decision(room)
    var after=[room.gold,room.electricity,room.spent,room.bed_level,room.door_level,room.door_hp,room.last_error,room.buildings.duplicate(true)]
    if original!=after:
     failures+=1
     push_error("Read-only decision probe mutated live state")
     break
    var old_spent=room.spent
    if strategy!="passive": BotAI.tick(room,0.1)
    if room.spent>old_spent:
     if purchases>0: gaps.append(game.time-previous_purchase)
     previous_purchase=game.time
     purchases+=1
     forced=0
     available_wait=0
    elif affordable:
     available_wait+=0.1
     forced=0
    else:
     forced+=0.1
     available_wait=0
    max_forced=maxf(max_forced,forced)
    max_available_wait=maxf(max_available_wait,available_wait)
    game.tick(0.1)
   var ending_tail=game.time-previous_purchase
   gaps.sort()
   if game.result=="": failures+=1
   scenarios+=1
   print("PACING strategy=",strategy," seed=",seed_value," room=",room.index+1," result=",game.result," duration=",snappedf(game.time,0.1)," purchases=",purchases," median_purchase_gap=",snappedf(gaps[gaps.size()/2],0.1) if not gaps.is_empty() else 0," max_actual_purchase_gap=",snappedf(gaps.back(),0.1) if not gaps.is_empty() else 0," ending_tail=",snappedf(ending_tail,0.1)," max_gap_including_tail=",snappedf(maxf(ending_tail,gaps.back() if not gaps.is_empty() else 0),0.1)," max_forced_no_affordable_action=",snappedf(max_forced,0.1)," max_wait_with_affordable_action=",snappedf(max_available_wait,0.1))
 print("PACING_SCENARIOS=",scenarios," FAILURES=",failures)
 quit(1 if failures else 0)
