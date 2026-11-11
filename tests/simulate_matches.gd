extends SceneTree

func _initialize():
 call_deferred("run")

func run():
 var failures = 0
 var wins = 0
 var losses = 0
 for strategy in ["passive","balanced","guard","economist"]:
  for seed_value in [7,8,99]:
   var game = MatchModel.new()
   game.reset(seed_value)
   game.claim_room(seed_value%6)
   var room = game.player()
   game.player_position = room.bed_position()
   game.sleep_player()
   room.profile = strategy
   var steps = 0
   while game.result == "" and steps < 12000:
    if strategy != "passive":
     BotAI.tick(room,0.1)
    game.tick(0.1)
    steps += 1
   if game.result == "victory":
    wins += 1
   elif game.result == "defeat":
    losses += 1
   else:
    failures += 1
   print("SIM seed=",seed_value," strategy=",strategy," result=",game.result," time=",snappedf(game.time,0.1)," hunter_level=",game.hunter.level," hunter_hp=",snappedf(game.hunter.hp,0.1)," player_gold=",snappedf(room.gold,0.1)," door_level=",room.door_level," buildings=",room.buildings.size()," shots=",game.shots," eliminated=",game.eliminations)
   if not is_finite(room.gold) or room.gold < 0 or room.electricity < 0:
    failures += 1
 print("SIMULATIONS=12 WINS=",wins," LOSSES=",losses," UNRESOLVED=",failures)
 if wins == 0 or losses == 0:
  push_error("Both natural victory and defeat must be observed")
  failures += 1
 quit(1 if failures else 0)
