class_name HunterCombatVisual
extends RefCounted
## Presentation of confirmed Hunter contacts. MatchModel owns damage and time.

const OFFSET := Vector2(145.0, 40.0)
const IMPACT_AGE := .48
const MAX_CONTACTS := 12
const BODY_SOURCES := ["door strike", "charged heavy strike", "scythe", "siege", "Scythe Slash"]
const ARCHETYPE_STYLES := {
 "crusher": "heavy", "stalker": "claw", "ravager": "swipe",
 "witch": "cast", "electric": "electric", "storm": "storm",
}
const STYLE_COLORS := {
 "heavy": Color("e7ba85"), "claw": Color("c2a7e8"), "swipe": Color("f4b5a4"),
 "cast": Color("becfff"), "electric": Color("97f4fd"), "storm": Color("acd5e9"),
 "scythe": Color("f0a0b4"), "siege": Color("ef9bb4"),
}

var enabled := OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE") == "1"
var _model_id := 0
var _last_event := 0
var _contacts: Array[Dictionary] = []
var _marks: Dictionary = {}

static func door_socket(room: RoomState) -> Vector2:
 return room.door_position() + room.door_normal() * 7.0 + Vector2(0, -9)

static func consumes(event: Dictionary) -> bool:
 return event.type == "door_damage" and event.get("attacker_id", 0) == 1 and float(event.damage) > 0.0 and event.has("attack_origin")

func reset():
 _model_id = 0
 _last_event = 0
 _contacts.clear()
 _marks.clear()

func new_encounter():
 _contacts.clear()

func has_contacts() -> bool:
 return enabled and not _contacts.is_empty()

func observe(model: MatchModel):
 if not enabled:
  return
 var model_id := model.get_instance_id()
 if _model_id != model_id:
  reset()
  _model_id = model_id
 var end: int = model.presentation_events.size()
 var start := end
 while start > 0 and int(model.presentation_events[start-1].id) > _last_event:
  start -= 1
 for index in range(start,end):
  var event: Dictionary = model.presentation_events[index]
  _last_event = int(event.id)
  if event.room < 0 or event.room >= model.rooms.size():
   continue
  if event.type == "door_upgrade":
   _marks.erase(event.room)
  elif consumes(event):
   var contact := _make_contact(event, model.rooms[event.room])
   _contacts.append(contact)
   if contact.material != "" and contact.style in ["claw", "swipe", "scythe", "heavy"]:
    _marks[event.room] = contact
   if _contacts.size() > MAX_CONTACTS:
    _contacts.pop_front()
 while not _contacts.is_empty() and model.time - float(_contacts.front().time) > IMPACT_AGE:
  _contacts.pop_front()

static func _make_contact(event: Dictionary, room: RoomState) -> Dictionary:
 var boss := bool(event.get("attack_boss", false))
 var source: String = event.source
 var body_contact := source in BODY_SOURCES
 var style := str(ARCHETYPE_STYLES.get(event.get("attack_archetype", ""), "heavy"))
 if source in ["scythe", "Scythe Slash", "Embedded Scythe"]:
  style = "scythe"
 elif source == "siege" or (boss and body_contact):
  style = "siege"
 elif not body_contact:
  var element: String = event.get("element", "neutral")
  if element == "electric":
   style = "storm" if style == "storm" else "electric"
  elif event.get("damage_type", "physical") == "magic":
   style = "cast"
  else:
   style = "heavy"
 var material := ""
 if event.get("damage_type", "physical") == "physical" and style in ["heavy", "claw", "swipe", "scythe"]:
  material = "wood" if int(event.get("door_level", 1)) < 4 else "iron"
 return {
  "id": event.id, "time": event.time, "point": door_socket(room), "normal": room.door_normal(),
  "room": event.room, "source": source, "style": style, "body": body_contact, "origin": event.attack_origin,
  "material": material, "boss": boss, "level": int(event.get("door_level", 1)),
 }

func latest_body_contact(model: MatchModel) -> Dictionary:
 if not enabled or _model_id != model.get_instance_id():
  return {}
 for index in range(_contacts.size() - 1, -1, -1):
  var contact := _contacts[index]
  var age := float(model.time) - float(contact.time)
  if contact.body and age >= 0.0 and age <= IMPACT_AGE:
   var sample := contact.duplicate()
   sample.age = age
   return sample
 return {}

func door_kick(model: MatchModel, room: int) -> Vector2:
 if not enabled or _model_id != model.get_instance_id():
  return Vector2.ZERO
 for index in range(_contacts.size() - 1, -1, -1):
  var contact := _contacts[index]
  var age := float(model.time) - float(contact.time)
  if contact.room == room and age >= 0.0 and age < .23 and contact.style in ["heavy", "siege", "scythe"]:
   return -Vector2(contact.normal) * cos(age * 37.0) * (1.0 - age / .23) * (5.0 if contact.style == "heavy" else 3.0)
 return Vector2.ZERO

func draw_mark(canvas: CanvasItem, room: RoomState):
 if not enabled or not _marks.has(room.index) or room.door_hp <= 0.0 or room.door_hp >= room.max_hp() * .94:
  return
 var mark: Dictionary = _marks[room.index]
 if int(mark.level) != room.door_level + 1:
  return
 var point: Vector2 = OFFSET + mark.point - Vector2(mark.normal) * 6.0
 var tangent := Vector2.RIGHT.rotated(PI * .5 if absf(room.door_normal().x) > .5 else 0.0)
 var down := tangent.orthogonal()
 var dark := Color("443840") if mark.material == "iron" else Color("352124")
 var edge := Color(.60, .62, .65, .34) if mark.material == "iron" else Color(.65, .38, .24, .35)
 if mark.style == "heavy":
  canvas.draw_polyline(PackedVector2Array([point-tangent*9, point-tangent*3+down*5, point+tangent*3-down*4, point+tangent*11]), dark, 2.0, true)
  return
 var span := 3 if mark.style in ["claw", "swipe"] else 1
 for finger in range(span):
  var scratch := point + tangent * (float(finger) - float(span - 1) * .5) * 7.0
  var first := scratch - down * 7.0 + tangent * 3.0
  var last := scratch + down * 9.0 - tangent * 5.0
  canvas.draw_line(first, last, dark, 2.2, true)
  canvas.draw_line(first + down, last + down, edge, 1.0, true)

func draw(canvas: CanvasItem, model: MatchModel, visible: Rect2, detail: int, reduced_motion: bool, reduced_flash: bool, rig_point := Vector2.INF):
 if not enabled or _model_id != model.get_instance_id():
  return
 for contact: Dictionary in _contacts:
  var p := OFFSET + Vector2(contact.point)
  var age := float(model.time) - float(contact.time)
  if age >= 0.0 and age <= IMPACT_AGE and visible.has_point(p):
   _draw_contact(canvas, p, contact, age, detail, reduced_motion, reduced_flash, rig_point if contact == _contacts.back() else Vector2.INF)

func _draw_contact(canvas: CanvasItem, p: Vector2, contact: Dictionary, age: float, detail: int, reduced_motion: bool, reduced_flash: bool, rig_point: Vector2):
 var normal: Vector2 = contact.normal
 var tangent := normal.orthogonal()
 var color: Color = STYLE_COLORS[contact.style]
 var alpha := maxf(0.0, 1.0 - age / IMPACT_AGE) * (.65 if reduced_flash else .92)
 var compact := detail == 0 or reduced_motion
 var live_tip := rig_point if contact.body and rig_point.is_finite() and rig_point.distance_to(p) < 55.0 else Vector2.INF
 match contact.style:
  "claw", "swipe": _draw_claws(canvas, p, normal, contact.style == "swipe", age, alpha, color, compact, live_tip)
  "heavy": _draw_heavy(canvas, p, normal, age, alpha, color, compact)
  "scythe": _draw_scythe(canvas, p, normal, contact.body, age, alpha, color, compact, live_tip)
  "electric": _draw_electric(canvas, p, normal, contact, age, alpha, color, compact, rig_point)
  "storm": _draw_storm(canvas, p, normal, age, alpha, color, compact)
  "cast": _draw_cast(canvas, p, normal, age, alpha, color, compact)
  "siege": _draw_heavy(canvas, p, normal, age, alpha, color, compact)
 if not compact and contact.style in ["heavy", "claw", "storm", "siege"]:
  _draw_haze(canvas,p,normal,tangent,age,alpha,color,contact.style in ["heavy","siege"])
 if contact.material != "" and age < .38 and not compact:
  _draw_fragments(canvas, p, normal, tangent, contact, age, alpha)

func _draw_claws(canvas: CanvasItem, p: Vector2, normal: Vector2, feral: bool, age: float, alpha: float, hue: Color, compact: bool, live_tip: Vector2):
 var tangent := normal.orthogonal() * (-1.0 if feral else 1.0)
 var fade := maxf(0.0, 1.0 - age / (.30 if feral else .44))
 var length := 23.0 if feral else 28.0
 var follow := p.lerp(live_tip,.68) if live_tip.is_finite() else p + normal*length*.4 + tangent*9.0
 for finger in range(3):
  var tip := p + tangent * float(finger - 1) * 7.0
  var bend := PackedVector2Array([
   tip + normal * length + tangent * 12.0,
   follow + tangent * float(finger - 1) * 7.0,
   tip,
   tip - normal * 2.0 - tangent * 6.0,
  ])
  if not compact:
   canvas.draw_polyline(bend, Color(hue, alpha * fade * .26), 5.5, true)
  canvas.draw_polyline(bend, Color(hue.lerp(Color.WHITE, .26), alpha * fade), 2.0 if feral else 1.65, true)

func _draw_heavy(canvas: CanvasItem, p: Vector2, normal: Vector2, age: float, alpha: float, hue: Color, compact: bool):
 var tangent := normal.orthogonal()
 var width := 14.0 if compact else 14.0 + age * 36.0
 canvas.draw_polyline(PackedVector2Array([
  p-tangent*width+normal*5, p-tangent*width*.55-normal*2, p,
  p+tangent*width*.55-normal*2, p+tangent*width+normal*5,
 ]), Color(hue, alpha), 3.0, true)
 if not compact:
  canvas.draw_arc(p+normal*(age*25.0), 10.0+age*42.0, normal.angle()-1.1, normal.angle()+1.1, 15, Color(hue,alpha*.42), 2.0, true)

func _draw_scythe(canvas: CanvasItem, p: Vector2, normal: Vector2, swept: bool, age: float, alpha: float, hue: Color, compact: bool, live_tip: Vector2):
 if not swept:
  canvas.draw_line(p+normal*7.0,p-normal*6.0,Color(hue,alpha*.8),2.0,true)
  return
 var radius := 18.0 if compact else 23.0 + age * 22.0
 var center := p + normal * radius
 var direction := (-normal).angle()
 if live_tip.is_finite():
  var side := clampf((live_tip-p).dot(normal.orthogonal()) / radius,-.35,.35)
  direction += side
 if not compact:
  canvas.draw_arc(center,radius,direction-1.18,direction+.78,18,Color(hue,alpha*.26),8.0,true)
 canvas.draw_arc(center,radius,direction-1.18,direction+.78,18,Color(hue,alpha),2.5,true)

func _draw_electric(canvas: CanvasItem, p: Vector2, normal: Vector2, contact: Dictionary, age: float, alpha: float, hue: Color, compact: bool, rig_point: Vector2):
 var tangent := normal.orthogonal()
 # Local, short, body-led arcs. A remote secondary target still gets
 # the confirmed socket flash without drawing a line across the map.
 var start := p+normal*22.0+Vector2(0,-14)
 var projected := OFFSET + Vector2(contact.origin) + Vector2(0,-30)
 if contact.body and rig_point.is_finite() and rig_point.distance_to(p)<85.0:
  start = rig_point
 elif projected.distance_to(p)<92.0:
  start = projected
 var jitter := tangent * sin(float(contact.id)*7.0+age*43.0) * (3.0 if compact else 8.0)
 var bolt := PackedVector2Array([start,start.lerp(p,.29)+jitter,start.lerp(p,.57)-jitter*.65,start.lerp(p,.79)+jitter*.45,p])
 if not compact:
  canvas.draw_polyline(bolt,Color(hue,alpha*.38),6.0,true)
 canvas.draw_polyline(bolt,Color(hue.lerp(Color.WHITE,.52),alpha),2.0,true)
 if not compact:
  canvas.draw_line(bolt[2],bolt[2]+tangent*14.0+normal*4.0,Color(hue,alpha*.6),1.5,true)

func _draw_storm(canvas: CanvasItem, p: Vector2, normal: Vector2, age: float, alpha: float, hue: Color, compact: bool):
 var direction := normal.angle()
 var rings := 1 if compact else 3
 for layer in range(rings):
  canvas.draw_arc(p+normal*(float(layer)*5.0+age*19.0),9.0+float(layer)*6.0+age*46.0,direction-1.37,direction+.72,14,Color(hue,alpha/(1.0+layer*.8)),1.8,true)

func _draw_cast(canvas: CanvasItem, p: Vector2, normal: Vector2, age: float, alpha: float, hue: Color, compact: bool):
 var count := 3 if compact else 6
 for ray in range(count):
  var angle := normal.angle() - 1.25 + float(ray) / float(count-1) * 2.5
  var direction := Vector2.from_angle(angle)
  var near := 4.0 + age * (15.0 if compact else 24.0)
  var far := near + (11.0 + float(ray % 2) * 4.0) * (1.0 - age)
  canvas.draw_line(p+direction*near,p+direction*far,Color(hue,alpha),1.6,true)
 if not compact:
  canvas.draw_arc(p,9.0+age*27.0,0,TAU,16,Color(hue,alpha*.26),2.0,true)

func _draw_haze(canvas: CanvasItem, p: Vector2, normal: Vector2, tangent: Vector2, age: float, alpha: float, hue: Color, dust: bool):
 for puff in range(3):
  var cross := float(puff - 1)
  var point := p + normal * (age * 31.0 + 6.0) + tangent * (cross * (12.0 + age * 20.0))
  var radius := (6.0 if dust else 10.0) + age * 25.0
  canvas.draw_circle(point,radius,Color(hue,alpha*(.15 if dust else .10)),true,-1.0,true)

func _draw_fragments(canvas: CanvasItem, p: Vector2, normal: Vector2, tangent: Vector2, contact: Dictionary, age: float, alpha: float):
 var heavy: bool = contact.style in ["heavy", "scythe"]
 var wood: bool = contact.material == "wood"
 var count := 6 if heavy else 3
 for fragment in range(count):
  var lane := float(fragment) / float(count-1) - .5
  var jitter := sin(float(contact.id)*32.0+float(fragment)*46.0)
  var departure := p+tangent*(lane*26.0+jitter*7.0)
  var velocity := normal*(21.0+jitter*6.0+float(fragment)*4.0)+tangent*(lane*63.0)
  var position := departure+velocity*age+Vector2(0,age*age*24.0)
  var shade := Color("d49c6c") if wood else Color("fbe1a9")
  if wood:
   var grain := (normal+tangent*jitter).normalized()*(3.0+jitter)
   canvas.draw_colored_polygon(PackedVector2Array([position-grain, position+grain, position+grain.orthogonal()]),Color(shade,alpha*.81))
  else:
   canvas.draw_line(position,position+velocity.normalized()*6.0,Color(shade,alpha*.78),1.4,true)
