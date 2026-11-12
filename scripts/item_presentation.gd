extends RefCounted
const OFFSET=Vector2(145,40)
func draw(c):
 var m=c.model
 var fx=m.items
 var room=m.player()
 if room==null: return
 var p=OFFSET+room.door_position()
 var time=m.time
 var reduced=game_reduced(c)
 advanced(c,m,room,fx,p,time,reduced)
 legendary(c,m,room,fx,p,time,reduced)
 if fx.shield_hp>0:
  c.draw_circle(p,39,Color(.2,.55,1,.14))
  c.draw_arc(p,40,0,TAU,48,Color(.4,.8,1,.9),3)
  c.draw_string(c.presentation.font,p+Vector2(42,-74),"SHIELD %d · %.0fs" % [fx.shield_hp,fx.timers.get("shield",0)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("9BDFFF"))
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
  for i in range(3 if reduced else 10):
   var direction=Vector2.from_angle(i*TAU/(3 if reduced else 10)+age)
   var point=q+direction*(12+age*55)
   if id in ["battery","overdrive"]:
    c.draw_polyline(PackedVector2Array([point,point+Vector2(6,-10),point+Vector2(1,-18),point+Vector2(10,-27)]),Color(color,alpha),2)
   elif id=="repair":
    c.draw_line(point-Vector2(5,0),point+Vector2(5,0),Color(color,alpha),3)
    c.draw_line(point-Vector2(0,5),point+Vector2(0,5),Color(color,alpha),3)
   elif id=="gold": c.draw_circle(point,4,Color(color,alpha))
   else: c.draw_line(point,point+direction*10,Color(color,alpha),3)
 # Numbers are a final foreground pass. Aggregate same item/phase and assign lanes.
 var groups={}
 for event in fx.events:
  if event.value<=0 or event.age>=1.5: continue
  var key=str(event.item)+":"+str(event.phase)
  if not groups.has(key): groups[key]={"value":0.0,"age":event.age,"event":event}
  groups[key].value+=event.value
  groups[key].age=minf(groups[key].age,event.age)
 var lane=0
 for key in groups:
  var group=groups[key]
  var e=group.event
  var point=OFFSET+e.position+Vector2(-145,-94-lane*26-group.age*12)
  if e.item in ["gold","battery","pillow"]: point=OFFSET+room.bed_position()+Vector2(40,-35-lane*26)
  var prefix="+" if e.phase in ["activate","income"] else "-" if e.phase=="explode" else "BLOCK "
  var text=prefix+str(snappedf(group.value,.01))+(" GOLD" if e.item=="cursed_fortune" else "")
  var color=Color(ItemCatalog.ITEMS[e.item].color)
  c.draw_string_outline(c.presentation.font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,4,Color("111421"))
  c.draw_string(c.presentation.font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
  lane+=1
func game_reduced(c) -> bool:
 return c.profile.settings.get("reduced_effects",false)
func advanced(c,m,room,fx,p,time,reduced):
 if float(fx.timers.get("barricade",0))>0:
  for i in range(3):
   var q=p+Vector2(-26+i*25,-22)
   c.draw_line(q,q+Vector2(0,40),Color("A5B5C8"),7)
   c.draw_circle(q+Vector2(0,5),3,Color("E4EFF5"))
 if float(fx.timers.get("pillow",0))>0:
  var q=OFFSET+room.bed_position()
  c.draw_arc(q,38+sin(time*3)*3,0,TAU,32,Color(1,.82,.25,.7),3)
  c.draw_texture_rect(load("res://assets/items/pillow.svg"),Rect2(q+Vector2(22,-35),Vector2(30,30)),false)
 if float(fx.timers.get("inferno",0))>0:
  for tile in room.buildings:
   if room.buildings[tile].kind not in ["turret","heavy"]: continue
   var q=OFFSET+room.tile_position(tile)
   for i in range(3 if reduced else 6):
    var angle=i*TAU/6+time*2
    c.draw_colored_polygon(PackedVector2Array([q+Vector2.from_angle(angle)*20,q+Vector2.from_angle(angle+.3)*30+Vector2(0,-10),q+Vector2.from_angle(angle+.6)*20]),Color(1,.4,.12,.65))
  for shot in m.projectiles:
   if shot.room==m.player_room: c.draw_line(OFFSET+shot.position,OFFSET+shot.position-Vector2(16,0),Color("FF8C46"),4)
 if fx.burn_remaining>0:
  var q=OFFSET+m.hunter.position
  c.draw_arc(q,34,0,TAU,32,Color("FF763D"),3)
  c.draw_string(c.presentation.font,q+Vector2(40,-35),"BURN %.1fs" % fx.burn_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("FFAF72"))
 if float(fx.timers.get("decoy",0))>0:
  var q=OFFSET+fx.decoy_point
  c.draw_texture_rect(load("res://assets/items/decoy.svg"),Rect2(q+Vector2(-22,-40-sin(time*3)*4),Vector2(44,50)),false)
  c.draw_arc(q,38,0,TAU,32,Color(.85,.55,1,.5),2)
  c.draw_string(c.presentation.font,q+Vector2(40,0),"DECOY %.1fs" % fx.timers.decoy,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("E2AAF2"))
 if float(fx.timers.get("smoke",0))>0:
  for i in range(4 if reduced else 9):
   var q=p+Vector2.from_angle(i*TAU/9+time*.5)*37
   c.draw_circle(q,12,Color(.45,.2,.6,.22))
  c.draw_string(c.presentation.font,p+Vector2(45,15),"SMOKE %.1fs" % fx.timers.smoke,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("DBB5F6"))
 for event in fx.events:
  if event.age>1.5 or event.item not in ["barricade","feather","inferno","pillow","coupon","decoy","rescue","smoke"]: continue
  var q=OFFSET+event.position
  if event.item=="rescue": c.draw_line(OFFSET+room.door_position(),q,Color(.4,1,.8,1-event.age/1.5),3)
  if event.item=="feather":
   for i in range(3 if reduced else 7):
    var direction=Vector2.from_angle(i*TAU/7+event.age)
    c.draw_texture_rect(load("res://assets/items/feather.svg"),Rect2(q+direction*(15+event.age*55)-Vector2(10,10),Vector2(20,20)),false,Color(1,1,1,1-event.age/1.5))

func legendary(c,m,room,fx,p,time,reduced):
 var h=OFFSET+m.hunter.position
 var freeze=float(fx.timers.get("time_freeze",0))
 if freeze>0:
  c.draw_circle(h,35,Color(.25,.65,1,.12))
  c.draw_arc(h,39,0,TAU,48,Color("A9EAFF"),3)
  for i in range(4 if reduced else 8):
   var ray=Vector2.from_angle(i*TAU/8)
   c.draw_line(h+ray*31,h+ray*45,Color("D4F4FF"),2)
  c.draw_line(h,h+Vector2(0,-25),Color("E1F8FF"),3)
  c.draw_line(h,h+Vector2(19,0),Color("E1F8FF"),3)
  c.draw_string(c.presentation.font,h+Vector2(44,-46),"FROZEN %.1fs" % freeze,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("BEF0FF"))
 if float(fx.timers.get("reaper_seal",0))>0:
  for ring in range(1 if reduced else 2):
   var points=PackedVector2Array()
   for i in range(7): points.append(h+Vector2.from_angle(i*TAU/6+time*.3)*(38+ring*12))
   c.draw_polyline(points,Color("FFE291"),2)
  c.draw_line(h+Vector2(-23,-23),h+Vector2(23,23),Color("FFE291"),3)
  c.draw_line(h+Vector2(-23,23),h+Vector2(23,-23),Color("FFE291"),3)
 if fx.guardian_shield_hp>0 and float(fx.timers.get("guardian_heart",0))>0:
  c.draw_arc(p,46,0,TAU,48,Color("FFE6B1"),3)
  c.draw_string(c.presentation.font,p+Vector2(48,-55),"GUARDIAN %d · %.1fs" % [fx.guardian_shield_hp,fx.timers.guardian_heart],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("FFE6B1"))
 if float(fx.timers.get("cursed_fortune",0))>0:
  c.draw_arc(h,43,time,time+TAU*.8,40,Color("DB9CF4"),3)
  c.draw_string(c.presentation.font,h+Vector2(44,-64),"CURSED %.1fs · +25%% DMG" % fx.timers.cursed_fortune,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("E1B1F6"))
 for e in fx.events:
  if not ItemCatalog.legendary(str(e.item)) or e.phase!="activate" or e.age>1.6: continue
  var age=float(e.age)
  var fade=clampf(1-age/1.6,0,1)
  var q=h if e.item in ["time_freeze","reaper_seal"] else p
  var color=Color(ItemCatalog.ITEMS[e.item].color)
  if e.item=="time_freeze":
   for i in range(1 if reduced else 3):
    c.draw_arc(q,30+age*(75+i*20),0,TAU,64,Color(color,fade*.55),2)
  elif e.item=="guardian_heart":
   for side in [-1,1]:
    for i in range(3 if reduced else 6):
     var spread=sin(minf(age/.4,1)*PI/2)
     var start=q+Vector2(side*15,0)
     var tip=q+Vector2(side*(40+i*7)*spread,-10-i*8)
     c.draw_colored_polygon(PackedVector2Array([start,tip,tip+Vector2(side*7,12),start+Vector2(0,12)]),Color(1,.85,.5,fade*.8))
   c.draw_texture_rect(load("res://assets/items/guardian_heart.svg"),Rect2(q+Vector2(-23,-46-age*12),Vector2(46,46)),false,Color(1,1,1,fade))
  elif e.item=="cursed_fortune":
   c.draw_texture_rect(load("res://assets/items/cursed_fortune.svg"),Rect2(q+Vector2(-27,-55),Vector2(54,54)),false,Color(1,1,1,fade))
   c.draw_line(q+Vector2(-24,-51-age*16),q+Vector2(24,-51-age*16),Color(1,.85,.4,fade),5)
   for i in range(3 if reduced else 12):
    var coin=q+Vector2.from_angle(-PI+i*PI/12)*(22+age*65)+Vector2(0,age*age*18)
    c.draw_circle(coin,3,Color(1,.81,.3,fade))
    if i%3==0: c.draw_circle(q+Vector2.from_angle(i*2+age)*40,10,Color(.5,.2,.65,fade*.18))
  else:
   c.draw_texture_rect(load("res://assets/items/reaper_seal.svg"),Rect2(q+Vector2(-31,-45),Vector2(62,62)),false,Color(1,1,1,fade*.8))
