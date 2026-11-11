extends SceneTree

func _initialize():
 call_deferred("run")

func invest_turret_focus(room):
 if room.door_hp < room.max_hp()*0.45 and room.repair_door():
  return
 if room.bed_level < 1:
  room.upgrade_bed()
  return
 if room.door_level < 1:
  room.upgrade_door()
  return
 if room.buildings.size() >= 2 and room.bed_level < 2:
  room.upgrade_bed()
  return
 for tile in range(6):
  if not room.buildings.has(tile):
   room.build("turret",tile)
   return
 room.upgrade_door()

func run():
 var failures = 0
 var matches = 0
 for room_index in [0,2,5]:
  for strategy in ["passive","balanced","turret_focus"]:
   for delta in [0.02,0.05,0.1]:
    var game = MatchModel.new()
    game.reset(7)
    game.claim_room(room_index)
    var room = game.player()
    room.profile = "balanced"
    game.player_position = room.bed_position()
    game.sleep_player()
    var time_budget = 0.0
    var frames = 0
    while game.result == "" and frames < int(1800/delta):
     if strategy == "balanced":
      BotAI.tick(room,delta)
     elif strategy == "turret_focus":
      time_budget -= delta
      if time_budget <= 0:
       time_budget = 0.5
       invest_turret_focus(room)
     game.tick(delta)
     frames += 1
    if game.result == "":
     failures += 1
    matches += 1
    print("TIMESTEP room=",room_index+1," strategy=",strategy," dt=",delta," result=",game.result," time=",snappedf(game.time,0.1)," bed_index=",room.bed_level," door_index=",room.door_level," buildings=",room.buildings.size()," hunter_hp=",snappedf(game.hunter.hp,0.1))
 print("TIMESTEP_MATCHES=",matches," UNRESOLVED=",failures)
 quit(1 if failures else 0)
