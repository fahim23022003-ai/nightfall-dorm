extends SceneTree

func _initialize():
 call_deferred("run")

func run():
 var turret_counts = []
 var hunter_counts = []
 for delta in [0.02,0.05,0.1]:
  var g = MatchModel.new()
  g.claim_room(0)
  var room = g.player()
  g.player_position = room.bed_position()
  g.sleep_player()
  room.gold = 1000
  room.build("turret",0)
  g.hunter.hp = 100000
  g.hunter.state = HunterState.State.MOVE
  g.hunter.position = room.tile_position(0)
  for i in range(int(30/delta)):
   g._turrets(delta)
  turret_counts.append(g.shots)
  g = MatchModel.new()
  g.claim_room(0)
  room = g.player()
  g.player_position = room.bed_position()
  g.sleep_player()
  room.door_level = 4
  room.door_hp = room.max_hp()
  g.time = g.preparation+1
  g.hunter.state = HunterState.State.ATTACK
  g.hunter.target = 0
  g.hunter.position = room.door_position()+Vector2(0,22)
  for i in range(int(30/delta)):
   g.hunter.tick(delta,g)
  hunter_counts.append(g.hunter.attacks)
  print("RATE dt=",delta," turret_shots_30s=",turret_counts.back()," hunter_attacks_30s=",hunter_counts.back())
 turret_counts.sort()
 hunter_counts.sort()
 var failures = 0
 if turret_counts.back()-turret_counts.front()>1 or hunter_counts.back()-hunter_counts.front()>1:
  failures += 1
  push_error("Combat rates diverge by more than one action across timesteps")
 print("RATE_SCENARIOS=6 FAILURES=",failures)
 quit(1 if failures else 0)
