class_name WeaponFeedback
extends RefCounted
## Read-only consumers receive finalized combat events before the history is trimmed.

signal received(event: Dictionary)

const NUMBER_MODES := ["all", "mine", "combined", "off"]
var enabled := OS.get_environment("NIGHTFALL_WEAPON_FEEDBACK") != "0"
var totals: Dictionary = {}

func send(event: Dictionary) -> void:
 if not enabled:
  return
 var type: String = event.type
 var instance: int = event.get("building_instance_id", 0)
 var tile: int = event.get("building_id", -1)
 if instance > 0 and tile >= 0 and type != "cancel":
  var key := key_for(event.room, tile, instance)
  if type == "launch" or type == "reflect":
   if not totals.has(key):
    totals[key] = {"damage":0.0,"burn":0.0,"hits":0,"last_damage":0.0}
   var info: Dictionary = totals[key]
   info.launch_time = event.time
   info.target_id = event.target_id
   info.aim = event.get("target_position",event.position) - event.origin
  if type != "launch" and totals.has(key):
   var info: Dictionary = totals[key]
   info.damage += event.damage
   if type == "burn":
    info.burn += event.damage
   elif event.damage > 0:
    info.hits += 1
    info.last_damage = event.damage
 received.emit(event)

func remove(room: int, tile: int, instance: int) -> void:
 totals.erase(key_for(room, tile, instance))

func machine(room, tile: int) -> Dictionary:
 var instance := int(room.buildings.get(tile, {}).get("instance_id", 0))
 return totals.get(key_for(room.index, tile, instance), {})

static func key_for(room: int, tile: int, instance: int) -> String:
 return "%d:%d:%d" % [room, tile, instance]

static func format_damage(amount: float) -> String:
 if amount > 0.0 and amount < 0.005:
  return "<0.01"
 var formatted := "%.2f" % amount
 return formatted.trim_suffix(".00") if formatted.ends_with(".00") else formatted.trim_suffix("0") if formatted.ends_with("0") else formatted
