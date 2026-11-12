extends RefCounted
const OFFSET=Vector2(145,40)
func draw(c):
 var m=c.model
 var fx=m.items
 var room=m.player()
 if room==null: return
 var p=OFFSET+room.door_position()
 var time=m.time
 if fx.shield_hp>0:
  c.draw_circle(p,39,Color(.2,.55,1,.14))
  c.draw_arc(p,40,0,TAU,48,Color(.4,.8,1,.9),3)
  c.draw_string(c.presentation.font,p+Vector2(-42,-54),"SHIELD %d · %.0fs" % [fx.shield_hp,fx.timers.get("shield",0)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("9BDFFF"))
 if float(fx.timers.get("overdrive",0))>0:
  for tile in room.buildings:
   if room.buildings[tile].kind in ["turret","heavy"]:
    var q=OFFSET+room.tile_position(tile)
    c.draw_arc(q,28,time*4,time*4+TAU*.8,32,Color(1,.64,.25,.8),3)
    c.draw_circle(q,22,Color(1,.5,.1,.13))
  for shot in m.projectiles:
   if shot.room==m.player_room: c.draw_circle(OFFSET+shot.position,6,Color(1,.65,.2,.5))
 if float(fx.timers.get("frost",0))>0:
  var q=OFFSET+m.hunter.position
  c.draw_circle(q,32,Color(.35,.7,1,.2))
  c.draw_arc(q,33,0,TAU,40,Color(.6,.85,1,.7),2)
  for i in range(7):
   var r=q+Vector2.from_angle(i*TAU/7+time)*27
   c.draw_line(r-Vector2(0,6),r+Vector2(0,6),Color("C5F4FF"),2)
   c.draw_line(r-Vector2(5,0),r+Vector2(5,0),Color("C5F4FF"),2)
 if float(fx.timers.get("radar",0))>0:
  var q=OFFSET+m.hunter.position
  c.draw_arc(q,42+fmod(time*25,35),0,TAU,48,Color(.5,1,.8,.55),2)
  c.draw_line(q+Vector2(-50,0),q+Vector2(50,0),Color(.4,1,.8,.55),1)
  c.draw_line(q+Vector2(0,-50),q+Vector2(0,50),Color(.4,1,.8,.55),1)
 if not fx.trap.is_empty():
  var q=OFFSET+fx.trap.position
  var texture=load("res://assets/items/trap.svg")
  c.draw_texture_rect(texture,Rect2(q-Vector2(17,17),Vector2(34,34)),false)
  c.draw_arc(q,30,0,TAU,36,Color(1,.5,.45,.3+sin(time*6)*.15),2)
  c.draw_string(c.presentation.font,q+Vector2(-24,38),"ARMED %.0fs" % fx.trap.remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("FFD3A0"))
 for event in fx.events:
  var id=str(event.item)
  var color=Color(ItemCatalog.ITEMS[id].color)
  var q=OFFSET+(m.hunter.position if id=="frost" else room.bed_position() if id in ["gold","battery","radar"] else event.position)
  var age=float(event.age)
  var alpha=clampf(1-age/1.5,0,1)
  if alpha<=0: continue
  if id=="gold" and event.phase=="activate":
   var crate=load("res://assets/items/gold.svg")
   var lift=sin(minf(1,age/.7)*PI/2)*18
   c.draw_set_transform(q+Vector2(0,-18),sin(age*13)*.08,Vector2.ONE)
   c.draw_texture_rect(crate,Rect2(-25,-25,50,50),false,Color(1,1,1,alpha))
   c.draw_set_transform(Vector2.ZERO)
   c.draw_line(q+Vector2(-23,-28-lift),q+Vector2(20,-32-lift),Color(1,.85,.42,alpha),6)
  var size=24+age*42
  if event.phase=="end":
   c.draw_arc(q,25+age*20,0,TAU,32,Color(color,alpha*.5),1)
   c.draw_string(c.presentation.font,q+Vector2(-30,-35-age*20),"EFFECT ENDED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(color,alpha))
   continue
  if event.phase=="explode": size=30+age*85
  c.draw_arc(q,size,0,TAU,40,Color(color,alpha*.8),3)
  for i in range(10):
   var direction=Vector2.from_angle(i*TAU/10+age)
   var point=q+direction*(12+age*55)
   if id in ["battery","overdrive"]:
    c.draw_polyline(PackedVector2Array([point,point+Vector2(6,-10),point+Vector2(1,-18),point+Vector2(10,-27)]),Color(color,alpha),2)
   elif id=="repair":
    c.draw_line(point-Vector2(5,0),point+Vector2(5,0),Color(color,alpha),3)
    c.draw_line(point-Vector2(0,5),point+Vector2(0,5),Color(color,alpha),3)
   elif id=="gold": c.draw_circle(point,4,Color(color,alpha))
   else: c.draw_line(point,point+direction*10,Color(color,alpha),3)
  if event.value>0:
   var prefix="+" if event.phase=="activate" else "-" if event.phase=="explode" else "ABSORB "
   c.draw_string(c.presentation.font,q+Vector2(-25,-38-age*32),prefix+str(snappedf(event.value,.01)),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(color,alpha))
