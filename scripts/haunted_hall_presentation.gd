extends RefCounted
## Architecture markings and the recovery rite use the simulation's real hall and HP budget.
const OFFSET := Vector2(145,40)
const SIDES := ["north","south","west","east"]
const ART := {
 "north":preload("res://assets/haunted_halls/north_altar.svg"),
 "south":preload("res://assets/haunted_halls/south_altar.svg"),
 "west":preload("res://assets/haunted_halls/west_altar.svg"),
 "east":preload("res://assets/haunted_halls/east_altar.svg"),
}
const TINTS := {
 "north":Color("98CEC4"),"south":Color("E2A07A"),
 "west":Color("BEA3CF"),"east":Color("D0CD9A"),
}

func render(c,p,halls: Dictionary, floor_texture: Texture2D, visible: Rect2):
 var recovery=c.model.get("haunt_recovery")
 for id in SIDES:
  if not halls.has(id):continue
  var hall: Dictionary=halls[id]
  var bounds: Rect2=hall.bounds
  bounds.position+=OFFSET
  if not visible.intersects(bounds.grow(70)):continue
  var center: Vector2=hall.center+OFFSET
  var entrance: Vector2=hall.entrance+OFFSET
  var tint: Color=TINTS[id]
  var active: bool=recovery!=null and recovery.phase=="recover" and recovery.hall_id==id
  c.draw_style_box(p.frame(Color("111821"),tint.darkened(.8),8),bounds.grow(6))
  c.draw_texture_rect(floor_texture,bounds,true,tint.darkened(.61))
  c.draw_rect(bounds,Color(tint,.09))
  _walls(c,bounds,entrance,tint)
  var rite_radius := clampf(minf(bounds.size.x,bounds.size.y)*.23,26,55)
  var altar_size := Vector2(minf(bounds.size.x-16,215),100)
  altar_size.y=altar_size.x*.594
  var altar_center := Vector2(center.x,bounds.position.y+17)
  # Leave the north doorway of the southern hall open in front of the altar.
  if id=="south":altar_center.y=center.y+43
  p.sprite(c,"warm_glow",altar_center+Vector2(0,14),Vector2(altar_size.x*.96,115),Color(tint,.48))
  c.draw_texture_rect(ART[id],Rect2(altar_center-Vector2(altar_size.x*.5,altar_size.y*.55),altar_size),false)
  var plaque_text := str(hall.name).to_upper()
  var text_size := roundi(10.0/maxf(c.camera.zoom.x,.12)) if c.full_map else 12
  var label_at := Vector2(center.x-p.font.get_string_size(plaque_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x*.5,bounds.end.y-11)
  p.text(c,plaque_text,label_at,text_size,tint)
  _rite(c,center,rite_radius,tint,active,p.clock,recovery)

func _walls(c,bounds: Rect2,entrance: Vector2,tint: Color):
 var ends := PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
 var edge := -1
 var closest := INF
 for i in range(4):
  var a := ends[i]
  var b := ends[(i+1)%4]
  var gap := entrance.distance_squared_to(Geometry2D.get_closest_point_to_segment(entrance,a,b))
  if gap<closest:
   closest=gap;edge=i
 for i in range(4):
  var a := ends[i]
  var b := ends[(i+1)%4]
  if i==edge:
   var at := Geometry2D.get_closest_point_to_segment(entrance,a,b)
   var dir := a.direction_to(b)
   var before := a+dir*clampf((at-a).dot(dir)-27,0,a.distance_to(b))
   var after := a+dir*clampf((at-a).dot(dir)+27,0,a.distance_to(b))
   c.draw_line(a,before,tint.darkened(.78),7)
   c.draw_line(after,b,tint.darkened(.78),7)
   c.draw_line(before,after,Color(tint,.42),2)
  else:
   c.draw_line(a,b,tint.darkened(.78),7)
  c.draw_circle(a,5,tint.darkened(.38))

func _rite(c,center: Vector2,radius: float,tint: Color,active: bool,clock: float,recovery):
 var animate := active and not CinematicQuality.reduced_motion(c)
 var pulse := .68+.32*sin(clock*2.5) if animate else 1.0
 var detail := CinematicQuality.detail(c)>0
 c.draw_set_transform(center,0,Vector2(1,.50))
 c.draw_arc(Vector2.ZERO,radius,0,TAU,32,Color(tint,.42),2)
 c.draw_arc(Vector2.ZERO,radius-6,0,TAU,24,Color(tint,.32),1)
 for i in range(6):
  var spoke := Vector2.from_angle(TAU*i/6)
  var q := spoke*radius
  var side := spoke.orthogonal()*4
  c.draw_colored_polygon(PackedVector2Array([q+spoke*8,q+side,q-spoke*5,q-side]),Color(tint,.45 if not active else .8))
 if active:
  var progress := clampf(float(recovery.healed)/maxf(1,float(recovery.budget)),0,1)
  c.draw_circle(Vector2.ZERO,radius,Color(tint,.13*pulse))
  if progress>.001:c.draw_arc(Vector2.ZERO,radius+4,0,TAU*progress,28,Color(tint,.78),3)
 c.draw_set_transform(Vector2.ZERO)
 for side in [-1,1]:
  var q := center+Vector2(side*(radius+10),8)
  c.draw_line(q,q-Vector2(0,14),Color("98755D"),2)
  c.draw_circle(q-Vector2(0,14),3,Color(tint,.7))
 if animate and detail:
  for i in range(8):
   var t := fposmod(clock*.72+i*.127,1)
   var q := center+Vector2(cos(i*2.4+clock*.55)*radius*(1-t),sin(i*2.4)*radius*.4-t*80)
   c.draw_line(q,q+Vector2(0,4),Color(tint,.52*sin(t*PI)),1.6)

func draw_hunter_recovery(c,p,point: Vector2):
 var recovery=c.model.get("haunt_recovery")
 if recovery==null or recovery.phase!="recover":return
 var tint: Color=TINTS.get(recovery.hall_id,Color("C4C5D9"))
 var q := point+OFFSET
 var remaining := maxf(0,float(recovery.budget)-float(recovery.healed))
 var caption := "+%d HP RECOVERED" % roundi(float(recovery.healed))
 if remaining<=.1:caption="RECOVERY COMPLETE"
 var width: float=p.font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+20
 var box := Rect2(q+Vector2(-width*.5,31),Vector2(width,23))
 c.draw_style_box(p.frame(Color("17232D"),tint.darkened(.15),4),box)
 p.text(c,caption,box.position+Vector2(10,16),12,tint)
