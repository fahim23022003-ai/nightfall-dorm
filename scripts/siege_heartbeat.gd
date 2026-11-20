extends AudioStreamPlayer
## One unstackable cue for a newly active siege of the player's closed door.

const SIEGE_GAP := 8.0
const COOLDOWN := 45.0
const MAX_DURATION := 5.0

const DESPERATE_AFTER := 12.0
const LOW_DOOR_FRACTION := .34

var live := false
var desperate := false
var pressure_seconds := 0.0
var remaining := 0.0
var _away := SIEGE_GAP
var _cooldown := 0.0

func reset() -> void:
 end()
 _cooldown=0.0

func end() -> void:
 stop()
 live=false
 desperate=false
 remaining=0.0
 pressure_seconds=0.0
 _away=SIEGE_GAP

func update(delta: float, model, active: bool, audible: bool) -> bool:
 if not active or model.tutorial_mode:
  end()
  return false
 stream_paused=not model.running
 if not model.running:
  return false
 remaining=maxf(0.0,remaining-delta)
 if remaining==0.0 and playing:
  stop()
 _cooldown=maxf(0.0,_cooldown-delta)
 live=_direct_door_attack(model)
 if not live:
  _away=minf(SIEGE_GAP,_away+delta)
  if _away>=SIEGE_GAP:
   pressure_seconds=0.0
   desperate=false
  return false
 var entering: bool=_away>=SIEGE_GAP
 _away=0.0
 pressure_seconds+=delta
 var room: RoomState=model.player()
 desperate=desperate or pressure_seconds>=DESPERATE_AFTER or room.door_hp<room.max_hp()*LOW_DOOR_FRACTION
 if not entering or _cooldown>0.0 or not audible or stream==null:
  return false
 remaining=minf(MAX_DURATION,stream.get_length())
 _cooldown=COOLDOWN
 play()
 return true

func _direct_door_attack(model) -> bool:
 var room: RoomState=model.player()
 var hunter: HunterState=model.hunter
 if room==null or room.owner!=0 or not room.alive or not room.sleeping or not room.closed or room.door_hp<=0.0:
  return false
 if hunter.state!=HunterState.State.ATTACK or hunter.target!=room.index or hunter.hp<=0.0:
  return false
 var approach:=room.door_approach()
 if model.map_id=="legacy":
  approach=room.door_position()+Vector2(0,22 if room.index<3 else -22)
 return hunter.position.distance_squared_to(approach)<=16.0
