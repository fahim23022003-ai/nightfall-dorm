class_name MatchModel
extends RefCounted

signal feedback(message: String)
var rooms: Array = []
var hunter: HunterState
var player_room = -1
var player_position = Vector2(500,410)
var preparation = Catalog.PREPARATION
var time = 0.0
var result = ""
var running = true
var eliminations = 0
var shots = 0
var damage_dealt = 0.0
var bot_claimed = 0
var random = RandomNumberGenerator.new()

func _init():
 reset()

func reset(seed_value: int = 1):
 random.seed = seed_value
 rooms.clear()
 for i in range(6):
  rooms.append(RoomState.new(i))
 hunter = HunterState.new()
 player_room = -1
 player_position = Vector2(500,410)
 time = 0
 result = ""
 running = true
 eliminations = 0
 shots = 0
 damage_dealt = 0
 bot_claimed = 0

func claim_room(index: int) -> bool:
 if not running or result != "" or index < 0 or index >= rooms.size() or player_room >= 0 or rooms[index].owner >= 0:
  return false
 rooms[index].owner = 0
 player_room = index
 feedback.emit("Room claimed. Approach the bed and press E to sleep.")
 return true

func sleep_player() -> bool:
 if not running or result != "" or player_room < 0:
  return false
 var room = rooms[player_room]
 if hunter.state != HunterState.State.DORMANT and room.bounds().has_point(hunter.position):
  feedback.emit("The hunter is already inside. You cannot lock it out now.")
  return false
 if not room.alive or player_position.distance_to(room.bed_position()) > 60:
  return false
 for occupied in rooms:
  if hunter.state != HunterState.State.DORMANT and occupied.bounds().has_point(hunter.position):
   hunter.target = occupied.index
   hunter.state = HunterState.State.EXIT
   hunter.exit_corridor = false
 room.closed = true
 room.sleeping = true
 player_position = room.bed_position()
 feedback.emit("Door locked. Build defenses on the numbered floor tiles.")
 return true

func player() -> RoomState:
 return rooms[player_room] if player_room >= 0 else null

func buy(kind: String, tile: int) -> bool:
 return player().build(kind,tile) if _can_purchase() else false

func upgrade_bed() -> bool:
 return player().upgrade_bed() if _can_purchase() else false

func upgrade_door() -> bool:
 return player().upgrade_door() if _can_purchase() else false

func repair_door() -> bool:
 return player().repair_door() if _can_purchase() else false

func upgrade_building(tile: int) -> bool:
 return player().upgrade_building(tile) if _can_purchase() else false

func _can_purchase() -> bool:
 return running and result == "" and player() != null and player().alive

func purchase_error() -> String:
 if result != "":
  return "The match has ended. Restart to play again."
 if not running:
  return "Match paused. Resume before purchasing."
 if player() == null:
  return "Enter a free room and press E to claim it first."
 return player().last_error

func move_player(direction: Vector2, delta: float):
 if not running or result != "" or (player() != null and player().sleeping):
  return
 if not is_finite(delta):
  return
 var remaining = clampf(delta,0,0.25)
 while remaining > 0:
  var step = minf(remaining,0.02)
  var destination = player_position + direction.limit_length()*180.0*step
  if can_walk(Vector2(destination.x,player_position.y)):
   player_position.x = destination.x
  if can_walk(Vector2(player_position.x,destination.y)):
   player_position.y = destination.y
  remaining -= step

func can_walk(point: Vector2) -> bool:
 if Rect2(35,335,900,150).has_point(point):
  return true
 for room in rooms:
  if room.bounds().grow(-12).has_point(point) and (room.owner < 0 or room.owner == 0) and not room.closed:
   return true
  if absf(point.x-room.center().x)<26 and point.y>300 and point.y<520 and not room.closed and (room.owner < 0 or room.owner == 0):
   return true
 return false

func interact():
 if player_room < 0:
  for room in rooms:
   if room.bounds().has_point(player_position):
    claim_room(room.index)
    return
  feedback.emit("Enter an unclaimed room, then press E.")
 else:
  if not sleep_player():
   feedback.emit("Move closer to your bed, then press E.")

func tick(delta: float):
 if not running or result != "":
  return
 time += delta
 if bot_claimed < 5 and time > 6+bot_claimed*1.7:
  var options: Array = []
  for room in rooms:
   if room.owner < 0 and not room.bounds().has_point(player_position):
    options.append(room)
  var physically_reserved = false
  for candidate in rooms:
   if candidate.owner < 0 and candidate.bounds().has_point(player_position):
    physically_reserved = true
  if not options.is_empty() and (options.size()>1 or player_room>=0 or physically_reserved):
   var room = options[random.randi_range(0,options.size()-1)]
   room.owner = bot_claimed+1
   room.profile = Catalog.BOT_PROFILES[bot_claimed]
   room.resident_position = room.door_position()+Vector2(0,22 if room.index<3 else -22)
   bot_claimed += 1
 for room in rooms:
  if room.owner > 0 and room.alive and not room.sleeping:
   room.resident_position = room.resident_position.move_toward(room.bed_position(),120*delta)
   if room.resident_position.distance_to(room.bed_position())<2:
    room.sleeping = true
    room.closed = true
  room.tick_economy(delta)
  if room.owner > 0:
   BotAI.tick(room,delta)
 var exposed = time > preparation+25 and (player() == null or not player().sleeping)
 if exposed:
  hunter.tick(0,self)
  hunter.state = HunterState.State.MOVE
  _pursue_exposed_player(delta)
 else:
  hunter.tick(delta,self)
 _turrets(delta)
 if player_room >= 0 and not rooms[player_room].alive:
  result = "defeat"
 elif hunter.hp <= 0:
  result = "victory"
 # A player who never selects a bed is hunted directly after the grace period.
 elif time > preparation+25 and (player() == null or not player().sleeping):
  if hunter.position.distance_to(player_position)<15:
   result = "defeat"

func _turrets(delta: float):
 for room in rooms:
  if not room.alive:
   continue
  var multiplier = 1.0
  for b in room.buildings.values():
   if b.kind == "enhancer":
    multiplier += Catalog.BUILDINGS.enhancer.rate*b.level
  for tile in room.buildings:
   var b = room.buildings[tile]
   if b.kind != "turret" and b.kind != "heavy":
    continue
   b.cooldown -= delta
   var data = Catalog.BUILDINGS[b.kind]
   if hunter.state != HunterState.State.DORMANT and hunter.state != HunterState.State.DEAD and room.tile_position(tile).distance_to(hunter.position)<=data.range and b.cooldown <= 0:
    var amount = data.damage*b.level*multiplier
    hunter.hurt(amount)
    damage_dealt += amount
    shots += 1
    room.shots += 1
    room.damage_dealt += amount
    b.flash = 0.15
    b.cooldown = data.interval/(1.0+(b.level-1)*0.12)

func _pursue_exposed_player(delta: float):
 var current_room = null
 var destination_room = null
 for room in rooms:
  if room.bounds().has_point(hunter.position):
   current_room = room
  if room.bounds().has_point(player_position):
   destination_room = room
 var waypoint = player_position
 if current_room != null and current_room != destination_room:
  waypoint = current_room.door_position()+Vector2(0,22 if current_room.index<3 else -22)
 elif destination_room != null and current_room != destination_room:
  var entry = destination_room.door_position()
  if absf(hunter.position.x-entry.x)>3:
   waypoint = Vector2(hunter.position.x,410) if absf(hunter.position.y-410)>3 else Vector2(entry.x,410)
  else:
   waypoint = entry+Vector2(0,-20 if destination_room.index<3 else 20)
 elif destination_room == null and current_room == null:
  if absf(hunter.position.y-410)>3 and absf(hunter.position.x-player_position.x)>3:
   waypoint = Vector2(hunter.position.x,410)
 hunter.position = hunter.position.move_toward(waypoint,hunter.speed*delta)
