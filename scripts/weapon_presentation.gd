extends RefCounted
## Canvas draws for existing model projectiles and finalized hit events.

const COLORS := {"turret":Color("FFE6B0"),"heavy":Color("98B9FF"),"flame":Color("FF9C55"),"frost":Color("A9F1FF"),"shock":Color("D8A4FF"),"barrier":Color("DDA8F3"),"trap":Color("F8DCA6")}
const ELEMENT_COLORS := {"fire":Color("FFB06F"),"ice":Color("A8EFFF"),"electric":Color("BCD5FF"),"earth":Color("F0CD9E")}
const BRANCH_COLORS := {"precision":Color("FFC383"),"suppression":Color("A5F2BA"),"focus":Color("D3BEFF"),"storm":Color("80FFF2"),"searing":Color("FFB871"),"wildfire":Color("FFA791"),"deep_chill":Color("D8FCFF"),"rime_field":Color("7AD5FF"),"capacitor_burst":Color("FFE8FF"),"rapid_discharge":Color("C6AEFF")}
const INK := Color("121524")
const CONTACT_HEIGHT := Vector2(0,-9)
const MAX_CONTACTS := 26
const MAX_NUMBERS := 32
const CONTACT_LIFE := .30
const NUMBER_LIFE := .95

var feed: WeakRef
var clock := 0.0
var player_room := -1
var number_mode := "all"
var low := false
var contacts: Array[Dictionary] = []
var numbers: Array[Dictionary] = []
var muzzles: Dictionary = {}
var flight_seen: Dictionary = {}

func reset() -> void:
 contacts.clear();numbers.clear();muzzles.clear();flight_seen.clear()
 clock=0.0

func begin_frame(c, model, delta: float) -> void:
 if not model.weapon_feedback.enabled:
  return
 if feed==null or feed.get_ref()!=model.weapon_feedback:
  if feed!=null and feed.get_ref()!=null:
   feed.get_ref().received.disconnect(_receive)
  feed=weakref(model.weapon_feedback)
  model.weapon_feedback.received.connect(_receive)
  reset()
 clock+=delta
 player_room=model.player_room
 low=CinematicQuality.detail(c)==0
 var current_mode: String=c.profile.settings.get("damage_numbers","all")
 if current_mode!=number_mode:
  numbers.clear()
  number_mode=current_mode
 if not contacts.is_empty():contacts=contacts.filter(func(entry):return clock-entry.born<CONTACT_LIFE)
 if not numbers.is_empty():numbers=numbers.filter(func(entry):return clock-entry.last<NUMBER_LIFE)
 for key in muzzles.keys():
  if clock-muzzles[key].born>.15:muzzles.erase(key)

func _receive(event: Dictionary) -> void:
 var type: String=event.type
 if type=="launch":
  var key:=WeaponFeedback.key_for(event.room,event.building_id,event.building_instance_id)
  muzzles[key]={"born":clock,"event":event}
  return
 var projectile: int=event.projectile_id
 var had_flight:=flight_seen.has(projectile)
 if type in ["impact","cancel"]:flight_seen.erase(projectile)
 if type=="cancel":return
 if type!="burn":
  var existing := false
  for previous in contacts:
   if previous.event.target_id==event.target_id and previous.event.kind==event.kind and previous.event.reason==event.reason and clock-previous.born<.08:
    existing=true
    break
  if not existing:
   if contacts.size()>=MAX_CONTACTS:contacts.pop_front()
   contacts.append({"born":clock,"event":event,"short_shot":type=="impact" and not had_flight and event.flight_age<=.26})
 if number_mode=="off" or number_mode=="mine" and event.room!=player_room:
  return
 if event.damage<=0 and event.reason not in ["blocked","immune"]:return
 _add_number(event)

func _add_number(event: Dictionary) -> void:
 var marker: String=event.reason if event.damage<=0 else "burn" if event.type=="burn" else "hit"
 var element: String=event.element if event.element!="neutral" else event.damage_type
 var group: String="combined" if number_mode=="combined" and marker=="hit" else element
 var window := .55 if marker=="burn" else .28 if number_mode=="combined" else .19 if low else .13
 var active := 0
 for index in range(numbers.size()-1,-1,-1):
  var entry: Dictionary=numbers[index]
  if entry.target!=event.target_id:continue
  active+=1
  if entry.marker!=marker or entry.group!=group or clock-entry.born>window:continue
  entry.amount+=event.damage
  entry.count+=1
  entry.last=clock
  entry.dirty=true
  return
 if numbers.size()>=MAX_NUMBERS:
  # Bound the number of visible labels during dense summons. Prefer returning
  # space from the oldest label; the combat ledger still contains every hit.
  numbers.pop_front()
 var tint: Color=ELEMENT_COLORS.get(element,Color("E4C9FF") if event.damage_type=="magic" else Color("FFF1D6"))
 if group=="combined":tint=Color("FFF1D6")
 if event.damage<=0:tint=Color("CEDDF1")
 var base_lane:=posmod(event.target_id*3,5) if event.target_id>1 else 0
 numbers.append({"target":event.target_id,"marker":marker,"group":group,"amount":event.damage,"count":1,"position":event.position,"born":clock,"last":clock,"tint":tint,"lane":posmod(base_lane+active,8),"dirty":true})

func muzzle(c, visuals, event: Dictionary) -> Vector2:
 var origin: Vector2=event.origin
 var scale := 1.0
 if event.grid:
  var footprint := SpatialConstruction.grid_footprint(origin,event.kind,event.rotation)
  scale=clampf(minf(footprint.size.x,footprint.size.y)/44.0,.65,1.0)
 return origin+visuals.discharge_socket(c,event.kind,event.level,event.target_position-origin,scale,1.0)

func projectile_point(c, visuals, shot: Dictionary, target: Vector2) -> Vector2:
 var point: Vector2=shot.position
 if shot.age<.12:
  var given={"origin":shot.from,"target_position":shot.get("launch_target",target),"rotation":shot.get("rotation",0),"grid":shot.get("grid",false),"kind":shot.kind,"level":shot.level}
  var offset:=muzzle(c,visuals,given)-Vector2(shot.from)
  var muzzle_weight:=1.0-smoothstep(0.0,.12,shot.age)
  point+=offset*muzzle_weight+CONTACT_HEIGHT*(1.0-muzzle_weight)
 else:
  point+=CONTACT_HEIGHT
 return point

func draw_combat(c, visuals, model, visible: Rect2, world_offset: Vector2) -> void:
 var scale := 1.0/maxf(.24,c.get_canvas_transform().get_scale().x)
 var reduced_flash := CinematicQuality.reduced_flash(c)
 for value: Dictionary in muzzles.values():
  var event: Dictionary=value.event
  if not visible.has_point(world_offset+Vector2(event.origin)):continue
  var point:=world_offset+muzzle(c,visuals,event)
  var direction: Vector2=(event.target_position-event.origin).normalized()
  var tint:=_color(event)
  var fade:=clampf(1.0-(clock-value.born)/.15,0,1)
  c.draw_circle(point,(3.1+fade)*scale,Color(tint,fade*.87))
  if not reduced_flash:
   c.draw_line(point,point+direction*(7.0+fade*3.0)*scale,Color(tint.lightened(.55),fade),2.0*scale)
 for shot: Dictionary in model.projectiles:
  if not visible.has_point(world_offset+Vector2(shot.position)):continue
  var actor=model.target_by_id(int(shot.target_id))
  if actor==null:continue
  var point:=world_offset+projectile_point(c,visuals,shot,actor.position)
  var goal: Vector2=world_offset+actor.position+CONTACT_HEIGHT
  var direction: Vector2=(goal-point).normalized()
  if direction.is_zero_approx():direction=(Vector2(shot.get("launch_target",actor.position))-Vector2(shot.from)).normalized()
  if direction.is_zero_approx():direction=Vector2.UP
  var trail:=point-direction*minf((27.0 if shot.kind=="heavy" else 19.0)*scale,maxf(3.0,float(shot.age)*float(shot.speed)))
  draw_flight(c,shot,point,trail,direction,scale)
  flight_seen[shot.id]=true
 for view in contacts:
  var event: Dictionary=view.event
  var point :=world_offset+Vector2(event.position)+CONTACT_HEIGHT
  var fading:=clampf(1.0-(clock-view.born)/CONTACT_LIFE,0,1)
  if view.short_shot or event.type=="reflect":
   var start: Vector2=world_offset+(Vector2(event.origin) if event.type=="reflect" else muzzle(c,visuals,event))
   if visible.intersects(Rect2(start,Vector2.ZERO).expand(point).grow(1.0)):
    c.draw_line(start,point,Color(_color(event),fading*.80),2.1*scale,true)
  if visible.has_point(point):draw_contact(c,event,point,fading,scale,reduced_flash)

func _color(event: Dictionary) -> Color:
 return BRANCH_COLORS.get(event.get("specialization",""),COLORS.get(event.kind,Color("FFE5AF")))

func draw_flight(c, shot: Dictionary, point: Vector2, tail: Vector2, direction: Vector2, scale: float) -> void:
 var tint:=_color(shot)
 var side:=direction.orthogonal()*scale
 var width:=2.2 if shot.kind=="turret" else 3.8
 c.draw_line(tail,point,INK,(width+2.5)*scale)
 if shot.kind=="shock":
  var bend:=side*(4.0 if int(shot.id)%2==0 else -4.0)
  c.draw_polyline(PackedVector2Array([tail,tail.lerp(point,.36)+bend,tail.lerp(point,.65)-bend*.7,point]),tint,2.6*scale,true)
 else:
  c.draw_line(tail,point,tint,width*scale)
 if shot.kind=="turret":
  c.draw_line(point-direction*4.5*scale,point+direction*3.2*scale,Color("FFF5D8"),1.8*scale)
 elif shot.kind=="frost":
  c.draw_colored_polygon(PackedVector2Array([point+direction*6*scale,point+side*3,point-direction*5*scale,point-side*3]),Color("EAFDFF"))
 else:
  c.draw_circle(point,(4.7 if shot.kind=="heavy" else 3.7)*scale,tint)
  c.draw_circle(point,2.0*scale,tint.lightened(.75))

func draw_contact(c, event: Dictionary, point: Vector2, fade: float, scale: float, reduced_flash: bool) -> void:
 var blocked: bool=event.damage<=0
 var tint :=Color("C5D3ED") if blocked else _color(event)
 var radius: float=(5.0+(1.0-fade)*(13.0 if event.kind=="heavy" else 9.0))*scale
 if blocked or event.kind in ["heavy","frost","barrier","shock"]:
  c.draw_arc(point,radius,0,TAU,16,Color(tint,fade*.9),2.0*scale)
 if not blocked:
  var count:=3 if low or reduced_flash else 5
  for ray in range(count):
   var radial:=Vector2.from_angle(float(ray)*TAU/count+.27)
   if event.kind=="flame":radial=(radial+Vector2.UP*.65).normalized()
   c.draw_line(point+radial*radius*.45,point+radial*radius,Color(tint,fade*.90),1.65*scale)
 if event.slow and event.kind=="frost":
  c.draw_arc(point,13*scale,0,PI,12,Color("ACF3FF",fade*.72),1.5*scale)

func draw_numbers(c, font: Font, visible: Rect2, world_offset: Vector2) -> void:
 var unit := 1.0/maxf(.16,c.get_canvas_transform().get_scale().x)
 var motion := not CinematicQuality.reduced_motion(c)
 var canvas: Transform2D=c.get_global_transform_with_canvas()
 var viewport: Rect2=c.get_viewport_rect()
 for entry in numbers:
  var point: Vector2=world_offset+entry.position
  if not visible.has_point(point):continue
  var screen:=canvas*point
  if not viewport.grow(4.0).has_point(screen):continue
  var lived: float=clock-entry.born
  var fresh: float=clock-entry.last
  var alpha:=1.0-smoothstep(.53,NUMBER_LIFE,fresh)
  var fontsize: int=17 if entry.marker in ["burn","blocked","immune"] else 22 if entry.amount>=90.0 else 19
  if entry.dirty or entry.get("font_size",0)!=fontsize:
   var label := WeaponFeedback.format_damage(entry.amount)
   if entry.marker=="burn":label="BURN " + label
   elif entry.marker in ["blocked","immune"]:label=entry.marker.to_upper()
   if entry.count>1 and entry.marker=="hit":label+="  ×%d" % entry.count
   entry.label=label
   var glyphs: TextLine=entry.get("glyphs")
   if glyphs==null:glyphs=TextLine.new()
   else:glyphs.clear()
   glyphs.add_string(label,font,fontsize)
   entry.glyphs=glyphs
   entry.width=glyphs.get_line_width()
   entry.font_size=fontsize
   entry.dirty=false
  var side: float=-1.0 if entry.lane%2==0 else 1.0
  if screen.x<170:side=1.0
  if screen.x>viewport.size.x-170:side=-1.0
  var x: float=side*(30.0+floorf(entry.lane/4.0)*76.0+entry.width/2.0)
  var y := (-22.0 if screen.y>204 else 22.0)-floorf(entry.lane%4/2.0)*23.0-(minf(lived,.8)*27.0 if motion else 0.0)
  var pos:=point+Vector2(x,y)*unit
  var pop := 1.0+(.18*(1.0-smoothstep(.03,.18,lived)) if motion else 0.0)
  c.draw_set_transform(pos,0.0,Vector2.ONE*unit*pop)
  var glyphs: TextLine=entry.glyphs
  var at:=Vector2(-entry.width/2.0,-glyphs.get_line_ascent())
  var canvas_item: RID=c.get_canvas_item()
  glyphs.draw_outline(canvas_item,at,4,Color(INK,alpha))
  glyphs.draw(canvas_item,at,Color(entry.tint,alpha))
 c.draw_set_transform(Vector2.ZERO)
