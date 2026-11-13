extends RefCounted
# Modular physical additions: every level unlocks another assembly. Shared
# original source illustrations remain the cores; no economy or model mutations.
var FEET=PackedVector2Array([Vector2(-25,12),Vector2(0,2),Vector2(25,12),Vector2(25,20),Vector2(0,30),Vector2(-25,20)])
var CAP=PackedVector2Array([Vector2(-25,-29),Vector2(-17,-42),Vector2(-8,-34),Vector2(0,-48),Vector2(9,-34),Vector2(18,-42),Vector2(25,-29)])
func plate(c,rect: Rect2,color: Color):
 c.draw_rect(rect,Color("111923"));c.draw_rect(rect.grow(-2),color)
 c.draw_line(rect.position+Vector2(2,2),rect.position+Vector2(rect.size.x-2,2),color.lightened(.35),1)
func draw(c,p,kind: String,level: int,point: Vector2,branch: String="",activity: float=0,target: Vector2=Vector2.ZERO,clock: float=0,angle: float=0,render_scale: float=1.0):
 level=clampi(level,1,10)
 var color=Catalog.BUILDINGS[kind].color if Catalog.BUILDINGS.has(kind) else Color("BFA4C9") if kind=="bed" else Color("86A7B5")
 var metal=Color("415563");var dark=Color("17232E");var trim=Color("D5BD86") if level>=5 else Color("809BA1")
 var reduced=c.profile.settings.reduced_effects
 var motion=clock if activity>0 and not reduced else 0.0
 c.draw_set_transform(point,angle,Vector2.ONE*render_scale)
 if kind=="bed":
  c.draw_texture_rect(p.textures.bed,Rect2(-29,-43,58,86),false)
  for side in [-1,1]:
   plate(c,Rect2(side*28-3,-42,6,83),metal)
   for n in range(1,level):
    var y=-30+n*7;c.draw_line(Vector2(side*28,y),Vector2(side*35,y-3),trim,2)
  if level>=2:plate(c,Rect2(-31,31,62,9),trim)
  if level>=3:plate(c,Rect2(-24,-47,48,9),metal)
  if level>=4:
   for side in [-1,1]:c.draw_circle(Vector2(side*28,-43),5,color)
  if level>=5:
   c.draw_arc(Vector2(0,-35),31,PI,TAU,24,color,4)
   if branch=="conductor":
    for side in [-1,1]:plate(c,Rect2(side*31-4,-30,8,23),Color("729DAB"))
   else:plate(c,Rect2(-20,-29,40,5),Color("D4B772"))
  if level>=6:
   for side in [-1,1]:plate(c,Rect2(side*33-3,-55,6,23),trim)
  if level>=7:c.draw_arc(Vector2(0,-38),36,PI,TAU,24,trim,3)
  if level>=8:
   for side in [-1,1]:c.draw_line(Vector2(side*32,-45),Vector2(side*21,5),Color(color,.65),3)
  if level>=6 and activity>0 and not reduced:
   for side in [-1,1]:
    var at=Vector2(side*31,-39+fposmod(motion*9,60))
    c.draw_circle(at,2.2,Color(color,.65))
  if level>=9:plate(c,Rect2(-34,-60,68,8),metal)
  if level==10:c.draw_colored_polygon(PackedVector2Array([Vector2(-26,-60),Vector2(-18,-76),Vector2(-8,-65),Vector2(0,-81),Vector2(9,-65),Vector2(18,-76),Vector2(26,-60)]),trim)
 elif kind=="door":
  plate(c,Rect2(-31,-42,62,60),metal);plate(c,Rect2(-23,-37,46,50),dark)
  c.draw_line(Vector2(0,-36),Vector2(0,12),trim,2);c.draw_circle(Vector2(8,-10),3,trim)
  for n in range(1,level):
   var y=-34+n*4.7
   c.draw_line(Vector2(-22,y),Vector2(-3,y-2),trim,3);c.draw_line(Vector2(3,y-2),Vector2(22,y),trim,3)
  if level>=3:
   for side in [-1,1]:plate(c,Rect2(side*29-4,-35,8,46),trim)
  if level>=5:
   c.draw_arc(Vector2(0,-12),19,0,TAU,24,color,3)
   if branch=="renewal":c.draw_line(Vector2(-10,-12),Vector2(10,-12),color,3);c.draw_line(Vector2(0,-22),Vector2(0,-2),color,3)
   else:c.draw_colored_polygon(PackedVector2Array([Vector2(-11,-22),Vector2(11,-22),Vector2(9,-5),Vector2(0,1),Vector2(-9,-5)]),trim)
  if level>=6:
   for side in [-1,1]:plate(c,Rect2(side*36-3,-40,6,55),metal)
  if level>=7:plate(c,Rect2(-38,-49,76,8),trim)
  if level>=8:
   for side in [-1,1]:c.draw_line(Vector2(side*35,-40),Vector2(side*35,6),Color(color,.9),2)
  if level>=9:c.draw_arc(Vector2(0,-40),38,PI,TAU,24,metal,6)
  if level==10:c.draw_colored_polygon(CAP+PackedVector2Array([Vector2(0,-29)]),trim)
 else:
  c.draw_colored_polygon(FEET,metal);c.draw_polyline(FEET,trim,1.3)
  # Core silhouette stays recognizable throughout; assemblies grow around it.
  var key=p.building_key(kind,1)
  c.draw_texture_rect(p.cartoon.get(key,p.cartoon.get(kind,p.textures.generator)),Rect2(-19,-30,38,48),false)
  if level>=2:
   for side in [-1,1]:plate(c,Rect2(side*21-4,1,8,18),metal)
  if level>=3:
   for side in [-1,1]:plate(c,Rect2(side*18-4,-24,8,19),color.darkened(.3))
  if level>=4:
   c.draw_line(Vector2(-20,-10),Vector2(20,6),trim,3);c.draw_line(Vector2(20,-10),Vector2(-20,6),trim,3)
  if level>=5:
   plate(c,Rect2(-18,-17,36,9),metal)
   if branch!="":
    var alternate=branch in ["suppression","storm","overcharge","conservation","capacitive","coolant","wildfire","rime_field","rapid_discharge","emergency_protocol","steady_veil","faint_echo","ward","converter","pulse"]
    for side in [-1,1]:
     if alternate:c.draw_arc(Vector2(side*19,-19),7,PI,TAU,12,color,3)
     else:plate(c,Rect2(side*20-4,-27,8,17),trim)
  if level>=6:
   for side in [-1,1]:plate(c,Rect2(side*23-3,-37,6,22),metal)
  if level>=7:plate(c,Rect2(-25,12,50,9),color.darkened(.3))
  if level>=8:
   for side in [-1,1]:c.draw_arc(Vector2(side*21,-8),8,-PI*.8,PI*.8,14,trim,3)
  if level>=9 and kind in ["turret","heavy","flame"]:c.draw_polyline(PackedVector2Array([Vector2(-27,8),Vector2(-27,-24),Vector2(0,-43),Vector2(27,-24),Vector2(27,8)]),metal.lightened(.2),4)
  if kind in ["turret","heavy","flame","frost","shock"]:
   var bearing=target.angle() if target.length()>0 else -PI/2
   var direction=Vector2.from_angle(bearing);var side=direction.orthogonal()
   var barrel=15+level*1.5;var kick=activity*3
   for n in range(1 if level<5 else 2 if level<10 else 3):
    var at=Vector2(0,-10)+side*(n-(0 if level<5 else .5 if level<10 else 1))*7
    c.draw_line(at,at+direction*(barrel-kick),dark,8);c.draw_line(at,at+direction*(barrel-kick),color,4)
   if kind=="frost":
    c.draw_colored_polygon(PackedVector2Array([Vector2(-8,-19),Vector2(0,-39-level),Vector2(10,-19),Vector2(0,-7)]),color)
   elif kind=="flame":
    for side_value in [-1,1]:plate(c,Rect2(side_value*16-5,-35,10,25),Color("A96544"))
   elif kind in ["heavy","shock"]:
    c.draw_circle(Vector2(0,-23),8+level*.35,color.darkened(.4));c.draw_arc(Vector2(0,-23),9+level*.35,motion,motion+PI*1.5,20,color,3)
  elif kind=="generator":
   for n in range(1+int(level/3)):
    var x=(n-level/6.0)*10
    plate(c,Rect2(x-4,-26-level,8,25+level),metal)
    for coil in range(3+int(level/3)):c.draw_line(Vector2(x-6,-24-level+coil*5),Vector2(x+6,-24-level+coil*5),color,2)
   c.draw_arc(Vector2(0,-10),8,motion*2,motion*2+PI*1.6,16,Color("DCE9D6"),2)
  elif kind in ["repair","auto_repair"]:
   var move=sin(motion*3)*4
   for side_value in [-1,1]:
    var elbow=Vector2(side_value*21,-20-move);c.draw_line(Vector2(side_value*13,3),elbow,metal.lightened(.3),5)
    c.draw_line(elbow,Vector2(side_value*7,-32+move),trim,4);c.draw_circle(elbow,4,color)
    c.draw_line(Vector2(side_value*7,-32+move),Vector2(side_value*2,-36+move),color,2)
  elif kind in ["barrier","plasma","antenna","shield"]:
   var top=-25-level*1.8
   c.draw_colored_polygon(PackedVector2Array([Vector2(-13,-16),Vector2(-14,top+9),Vector2(0,top),Vector2(14,top+9),Vector2(13,-16),Vector2(0,-7)]),color.darkened(.4))
   c.draw_polyline(PackedVector2Array([Vector2(-12,top+10),Vector2(0,top+2),Vector2(12,top+10)]),color,3)
   if kind=="plasma":c.draw_circle(Vector2(0,top+14),7,color)
   elif kind=="antenna":
    for n in range(2+int(level/3)):c.draw_arc(Vector2(0,top),8+n*5,PI*1.1,PI*1.9,14,color,2)
   else:c.draw_line(Vector2(-6,top+12),Vector2(6,top+24),color,3)
  elif kind=="decoy":
   c.draw_circle(Vector2(0,-29-level),8+level*.4,color.darkened(.35));c.draw_circle(Vector2(-4,-29-level),2,color);c.draw_circle(Vector2(4,-29-level),2,color)
   c.draw_arc(Vector2(0,-29-level),13,motion,motion+PI,16,color,2)
  else:
   # Economy vault / targeting relay: distinct chamber and receiver machinery.
   plate(c,Rect2(-13,-28-level,26,23),metal)
   if kind=="economy":
    for n in range(1+int(level/3)):c.draw_circle(Vector2(-9+n*6,-16-level),3,Color("E0BF70"))
   else:c.draw_arc(Vector2(0,-27-level),13,PI,TAU,20,color,3);c.draw_line(Vector2(0,-27-level),Vector2(7,-40-level),color,3)
  if level>=9:signature(c,kind,level,color,metal,trim,motion,activity)
 c.draw_set_transform(Vector2.ZERO)

func signature(c,kind: String,level: int,color: Color,metal: Color,trim: Color,motion: float,activity: float):
 var final=level==10
 if kind in ["turret","heavy"]:
  for side in [-1,1]:
   plate(c,Rect2(side*26-4,-33,8,41),trim)
   c.draw_line(Vector2(side*26,-33),Vector2(side*17,-48),metal.lightened(.4),5)
  if kind=="heavy":c.draw_arc(Vector2(0,-29),22,PI,TAU,24,trim,4)
  if final:
   c.draw_line(Vector2(-15,-47),Vector2(15,-47),trim,4)
   for side in [-1,1]:c.draw_circle(Vector2(side*25,-29),5,color)
 elif kind=="generator":
  for side in [-1,1]:
   var hub=Vector2(side*23,-20)
   c.draw_circle(hub,10,metal);c.draw_arc(hub,9,motion,motion+PI*1.7,18,trim,3)
   for n in range(4):
    var v=Vector2.from_angle(n*PI/2+motion);c.draw_line(hub+v*8,hub+v*13,trim,3)
  if final:
   plate(c,Rect2(-16,-49,32,8),trim);c.draw_arc(Vector2(0,-36),17,PI,TAU,20,color,4)
 elif kind in ["repair","auto_repair"]:
  for side in [-1,1]:
   var arm=Vector2(side*25,-36-sin(motion*2)*3)
   c.draw_line(Vector2(side*27,7),arm,metal.lightened(.3),7);c.draw_circle(arm,5,trim)
   c.draw_line(arm,Vector2(side*12,-48),trim,5)
  if final:
   plate(c,Rect2(-7,-52,14,11),color)
   c.draw_line(Vector2(-4,-47),Vector2(4,-47),Color("F0F4DD"),2);c.draw_line(Vector2(0,-51),Vector2(0,-43),Color("F0F4DD"),2)
 elif kind=="economy":
  plate(c,Rect2(-25,-26,50,37),metal)
  for n in range(3 if not final else 5):
   var x=-18+n*(12 if not final else 9)
   for y in range(3):c.draw_line(Vector2(x,-19+y*8),Vector2(x+8,-19+y*8),trim,4)
  if final:c.draw_colored_polygon(PackedVector2Array([Vector2(-27,-31),Vector2(0,-47),Vector2(27,-31)]),trim)
 elif kind=="enhancer":
  c.draw_line(Vector2(0,7),Vector2(0,-33),metal.lightened(.3),8)
  c.draw_arc(Vector2(0,-37),22,0,PI,24,color,5);c.draw_line(Vector2(-20,-35),Vector2(0,-46),trim,3);c.draw_line(Vector2(0,-46),Vector2(20,-35),trim,3)
  if final:
   for side in [-1,1]:c.draw_arc(Vector2(side*24,-13),12,-PI*.5,PI*.5,16,trim,3)
 elif kind=="flame":
  for side in [-1,1]:
   plate(c,Rect2(side*23-6,-40,12,36),Color("9D573C"));c.draw_arc(Vector2(side*23,-40),6,PI,TAU,12,trim,3)
   for n in range(3):c.draw_line(Vector2(side*23-4,-30+n*8),Vector2(side*23+4,-30+n*8),trim,2)
  if final:plate(c,Rect2(-13,-48,26,10),Color("B46A41"));c.draw_line(Vector2(-9,-44),Vector2(9,-44),color,4)
 elif kind=="frost":
  for side in [-1,1]:
   c.draw_colored_polygon(PackedVector2Array([Vector2(side*13,1),Vector2(side*30,-26),Vector2(side*21,-41),Vector2(side*11,-15)]),color.darkened(.15))
   c.draw_line(Vector2(side*14,-9),Vector2(side*22,-32),color.lightened(.3),2)
  if final:c.draw_colored_polygon(PackedVector2Array([Vector2(-7,-30),Vector2(0,-58),Vector2(9,-30),Vector2(0,-19)]),color.lightened(.2))
 elif kind=="shock":
  c.draw_arc(Vector2(0,5),27,0,TAU,24,trim,4)
  for side in [-1,1]:
   for n in range(3):plate(c,Rect2(side*24-3,-22+n*10,6,5),color)
  if final:c.draw_arc(Vector2(0,-17),20,0,TAU,24,color,3)
 elif kind in ["shield","barrier"]:
  var radius=28 if not final else 32
  if kind=="shield":
   c.draw_arc(Vector2(0,-14),radius,PI,TAU,28,metal.lightened(.2),6)
   for side in [-1,1]:c.draw_line(Vector2(side*radius,-14),Vector2(side*radius,7),trim,4)
  else:
   c.draw_polyline(PackedVector2Array([Vector2(0,8),Vector2(-28,-20),Vector2(0,-51 if final else -42),Vector2(28,-20),Vector2(0,8)]),trim,4)
   c.draw_arc(Vector2(0,-20),16,0,TAU,24,color,3)
 elif kind=="plasma":
  for side in [-1,1]:
   plate(c,Rect2(side*23-6,-34,12,36),metal)
   for n in range(4):c.draw_line(Vector2(side*23-4,-28+n*7),Vector2(side*23+4,-28+n*7),color,3)
  if final:c.draw_arc(Vector2(0,-27),22,PI,TAU,24,trim,4);c.draw_circle(Vector2(0,-47),5,color)
 elif kind=="antenna":
  c.draw_line(Vector2(0,-14),Vector2(0,-56),metal.lightened(.4),5)
  for n in range(3 if final else 2):c.draw_arc(Vector2(0,-30-n*8),11+n*4,PI*1.05,PI*1.95,18,color,3)
  for side in [-1,1]:c.draw_line(Vector2(side*13,8),Vector2(side*25,-30),trim,3)
 elif kind=="decoy":
  c.draw_colored_polygon(PackedVector2Array([Vector2(-22,-19),Vector2(-15,-45),Vector2(0,-53 if final else -43),Vector2(15,-45),Vector2(22,-19)]),metal)
  c.draw_circle(Vector2(0,-32),11,color.darkened(.35));c.draw_circle(Vector2(-4,-33),3,color);c.draw_circle(Vector2(4,-33),3,color)
  for side in [-1,1]:c.draw_polyline(PackedVector2Array([Vector2(side*17,-32),Vector2(side*30,-18),Vector2(side*24,-1)]),trim,3)
