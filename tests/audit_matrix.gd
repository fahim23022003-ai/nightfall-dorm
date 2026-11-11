extends SceneTree

func _initialize():
 call_deferred("run")

func run():
 var failures = 0
 var aggregate = {}
 var modes = ["passive","balanced"]
 var room_indices = range(6)
 if "--near-room-profiles" in OS.get_cmdline_user_args():
  modes = ["guard","engineer","economist","gunner","balanced"]
  room_indices = [2]
 for mode in modes:
  aggregate[mode] = {"win":0,"loss":0,"unresolved":0,"times":[],"advanced":0,"max_bed":0,"max_door":0,"peak_power":0.0,"max_hunter":0,"heavy_matches":0,"enhancer_matches":0,"upgrade_matches":0,"electricity_spent":0.0}
  for room_index in room_indices:
   var room_wins = 0
   var room_losses = 0
   var times = []
   for seed_value in range(1,13):
    var game = MatchModel.new()
    game.reset(seed_value)
    game.claim_room(room_index)
    var room = game.player()
    room.profile = mode
    game.player_position = room.bed_position()
    game.sleep_player()
    var step = 0
    var advanced = false
    var peak_power = 0.0
    var heavy = false
    var enhancer = false
    var upgraded = false
    var electricity_spent = 0.0
    while game.result == "" and step < 18000:
     if mode != "passive":
      var power_before = room.electricity
      BotAI.tick(room,0.1)
      electricity_spent += maxf(0,power_before-room.electricity)
     game.tick(0.1)
     peak_power = maxf(peak_power,room.electricity)
     for b in room.buildings.values():
      heavy = heavy or b.kind == "heavy"
      enhancer = enhancer or b.kind == "enhancer"
      upgraded = upgraded or b.level > 1
      if b.kind == "heavy" or b.kind == "enhancer" or b.level > 1:
       advanced = true
     if room.gold < -0.0001 or room.electricity < -0.0001 or room.door_hp < 0 or not is_finite(room.gold):
      failures += 1
      push_error("Resource invariant violated")
      break
     step += 1
    if game.result == "victory":
     aggregate[mode].win += 1
     room_wins += 1
    elif game.result == "defeat":
     aggregate[mode].loss += 1
     room_losses += 1
    else:
     aggregate[mode].unresolved += 1
     failures += 1
    aggregate[mode].heavy_matches += 1 if heavy else 0
    aggregate[mode].enhancer_matches += 1 if enhancer else 0
    aggregate[mode].upgrade_matches += 1 if upgraded else 0
    aggregate[mode].electricity_spent += electricity_spent
    aggregate[mode].times.append(game.time)
    times.append(game.time)
    aggregate[mode].advanced += 1 if advanced else 0
    aggregate[mode].max_bed = maxi(aggregate[mode].max_bed,room.bed_level)
    aggregate[mode].max_door = maxi(aggregate[mode].max_door,room.door_level)
    aggregate[mode].peak_power = maxf(aggregate[mode].peak_power,peak_power)
    aggregate[mode].max_hunter = maxi(aggregate[mode].max_hunter,game.hunter.level)
   times.sort()
   print("MATRIX strategy=",mode," room=",room_index+1," wins=",room_wins," losses=",room_losses," median_seconds=",snappedf(times[6],0.1))
  aggregate[mode].times.sort()
  print("SUMMARY strategy=",mode," wins=",aggregate[mode].win," losses=",aggregate[mode].loss," unresolved=",aggregate[mode].unresolved," median_seconds=",snappedf(aggregate[mode].times[aggregate[mode].times.size()/2],0.1)," advanced_matches=",aggregate[mode].advanced," max_bed_index=",aggregate[mode].max_bed," max_door_index=",aggregate[mode].max_door," peak_power=",snappedf(aggregate[mode].peak_power,0.1)," max_hunter=",aggregate[mode].max_hunter," heavy_matches=",aggregate[mode].heavy_matches," enhancer_matches=",aggregate[mode].enhancer_matches," upgraded_building_matches=",aggregate[mode].upgrade_matches," electricity_spent=",snappedf(aggregate[mode].electricity_spent,0.1))
 print("AUDIT_MATRIX_MATCHES=",modes.size()*room_indices.size()*12," FAILURES=",failures)
 quit(1 if failures else 0)
