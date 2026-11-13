extends RefCounted
const O=Vector2(145,40)
const GAIT={"crusher":6.0,"stalker":4.5,"ravager":12.0,"witch":3.0,"electric":8.0,"storm":3.5}
const PARTS=["cloth","leg","arm","body","head","back","weapon"]
var art: Dictionary={}
var observed_model
var smooth_speed=0.0
var lean=0.0
var gait_clock=0.0
var impact=0.0
var pose=0.0
var last_attack=0
var last_event=0
var cast_blend=0.0
func reset():
 observed_model=null;smooth_speed=0;lean=0;gait_clock=0;impact=0;pose=0;last_attack=0;last_event=0;cast_blend=0
func update(delta: float,m,identity):
 if observed_model!=m:reset();observed_model=m;last_attack=m.hunter.attacks
 var h=m.hunter
 var charge=clampf(1-h.nightmare.warning/2.8,0,1) if h.nightmare.action!="" else clampf(1-h.arcane.warning/1.1,0,1) if h.arcane.action!="" else .5 if h.archetype_primed or h.charged_ready else 0.0
 cast_blend=lerpf(cast_blend,charge,1-exp(-delta*9))
 var goal=clampf(identity.velocity.length()/maxf(1,h.speed),0,1) if h.state in [HunterState.State.MOVE,HunterState.State.EXIT,HunterState.State.SEEK] else 0.0
 smooth_speed=lerpf(smooth_speed,goal,1-exp(-delta*8));lean=lerpf(lean,clampf(identity.velocity.x*.001,-.16,.16),1-exp(-delta*6))
 gait_clock+=delta*GAIT.get(h.archetype,6.0)*maxf(.15,smooth_speed)
 pose=maxf(0,pose-delta);impact=maxf(0,impact-delta*3)
 if h.attacks>last_attack:pose=.42;last_attack=h.attacks
 for e in m.presentation_events:
  if e.id<=last_event:continue
  last_event=e.id
  if m.time-float(e.time)>.3:continue
  if e.type=="nightmare_impact" and e.get("damage_type","")=="physical":impact=.45
  elif e.type=="nightmare_rebirth":impact=.25
func camera_impulse() -> Vector2:
 return Vector2(sin(gait_clock*51),cos(gait_clock*37))*impact*2.2
var font=preload("res://assets/fonts/Interface.ttf")
func _init():
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for tier in range(4):
   for part in PARTS:art["%s_%d_%s" % [kind,tier,part]]=load("res://assets/nightmare/%s_%d_%s.svg" % [kind,tier,part])
func tier_for(level: int) -> int:return 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0
func part(c,key: String,name: String,at: Vector2,pivot: Vector2,angle: float,facing: float,tint: Color,shape: Vector2=Vector2.ONE):
 c.draw_set_transform(at,angle,Vector2(facing,1)*shape)
 c.draw_texture_rect(art[key+"_"+name],Rect2(-pivot,Vector2(128,160)),false,tint)
 c.draw_set_transform(Vector2.ZERO)
func hunter(c,h,clock: float,death_age: float,identity,silhouette=false):
 var level=c.model.evolution.evolution_level;var tier=tier_for(level)
 var rebirth=c.model.evolution.rebirth_remaining
 if rebirth>1.8 or level==10 and not c.model.evolution.final_revealed:tier=2
 var key="%s_%d" % [h.archetype,tier]
 var moving=identity.velocity.length()>1 and h.state in [HunterState.State.MOVE,HunterState.State.EXIT,HunterState.State.SEEK]
 var reduced=CinematicQuality.reduced_motion(c)
 var phase=gait_clock if observed_model==c.model else clock*GAIT[h.archetype]
 var stride=smooth_speed if observed_model==c.model else 1.0 if moving else 0.0
 if reduced:stride*=.35
 var dead=h.state==HunterState.State.DEAD
 var alpha=clampf(1-death_age/1.5,0,1) if dead else .36 if h.conceal_remaining>0 else 1.0
 if alpha<=0:return
 var face=-1.0 if identity.heading.x<-.15 else 1.0
 var p=O+h.position+Vector2(0,-17)
 if h.archetype in ["witch","storm","stalker","electric"]:p.y+=sin(clock*2.2)*(.4 if reduced else 3)
 if h.archetype=="ravager" and moving:p.x+=face*3
 var tint=Color(1.12 if CinematicQuality.reduced_flash(c) else 1.4,1.05,1.02,alpha) if h.hit_flash>0 else Color(1,1,1,alpha)
 if silhouette:tint=Color(0,0,0,alpha)
 var color=Color(0,0,0,alpha) if silhouette else Color(StrategyCatalog.ARCHETYPES[h.archetype].color)
 c.draw_set_transform(O+h.position+Vector2(0,14),0,Vector2(1,.38));c.draw_circle(Vector2.ZERO,34+tier*2,Color(.008,.012,.025,.18*alpha));c.draw_circle(Vector2.ZERO,25+tier*2,Color(.008,.012,.02,.4*alpha));c.draw_set_transform(Vector2.ZERO)
 var windup=clampf(1-h.nightmare.warning/2.8,0,1) if h.nightmare.action!="" else clampf(1-h.arcane.warning/1.1,0,1) if h.arcane.action!="" else .5 if h.archetype_primed or h.charged_ready else 0.0
 var guarding=h.suppression_remaining>0 or h.nightmare.remaining>0 and h.nightmare.effect in ["ossuary","overload","quills"]
 if observed_model==c.model:windup=cast_blend
 if guarding:windup=maxf(windup,.28)
 if rebirth>0:windup=maxf(windup,sin((1-rebirth/3.6)*PI)*.9)
 var slash=sin(clampf((.42-pose)/.42,0,1)*PI) if observed_model==c.model and pose>0 else sin(clampf((h.interval-h.cooldown)/.35,0,1)*PI) if h.state==HunterState.State.ATTACK and h.cooldown>h.interval-.35 else 0.0
 var bend=(lean if observed_model==c.model else clampf(identity.velocity.x*.0005,-.12,.12))-face*windup*.12
 if h.archetype=="ravager":bend+=face*(.14+stride*.12)
 if reduced:bend*=.35
 var breath=sin(clock*2.5)*(.3 if reduced else 1.3)
 if h.archetype=="crusher":p.y+=absf(sin(phase))*stride*2.8
 elif h.archetype=="stalker" and not reduced:p.x+=sin(clock*9)*stride*.8
 if h.archetype=="ravager":p.y-=sin(phase)*stride*3
 var recoil=Vector2(-face*h.hit_flash*12,0)
 var fall=clampf(death_age,0,1) if dead else 0.0
 p+=recoil+Vector2(0,fall*15)
 if h.archetype in ["electric","storm"] and tier>=2 and not reduced:
  for i in range(3):
   var at=p+Vector2.from_angle(clock*.6+i*TAU/3)*Vector2(38,25)-Vector2(0,25)
   c.draw_circle(at,5,Color(color,.08));c.draw_line(at,at+Vector2(6,-9),Color(color,.4),2)
 var flutter=0 if reduced else sin(clock*3.5)*.07+stride*sin(phase)*.1
 part(c,key,"cloth",p+Vector2(-2*face,-30),Vector2(64,65),flutter+bend+fall*.4,face,tint)
 for side in [-1,1]:
  var leg_phase=phase+(PI if side>0 else 0)
  var step=sin(leg_phase)*.36*stride
  part(c,key,"leg",p+Vector2(side*11,0)+Vector2(0,-maxf(0,sin(leg_phase))*7*stride),Vector2(52,111),step+side*fall*.5,side*face,tint)
 part(c,key,"arm",p+Vector2(-24*face,-32),Vector2(34,70),-face*(.12+sin(phase)*.25*stride-windup*.5)+fall*.8,face,tint)
 if moving and identity.heading.y<-.4:part(c,key,"weapon",p+Vector2(30*face,-7),Vector2(100,96),face*.12,face,tint)
 part(c,key,"body",p+Vector2(0,-8+breath),Vector2(64,92),bend+fall*.7,face,tint)
 part(c,key,"back" if moving and identity.heading.y<-.4 else "head",p+Vector2(face*windup*4+(face*12 if h.archetype=="ravager" else 0),(-25 if h.archetype=="ravager" else -35)+breath*.5),Vector2(64,65),-bend*.5+sin(clock*1.7)*.035-fall*.4,face,tint)
 var arm_angle=face*(windup*.8-slash*1.15+sin(phase+PI)*.2*stride)
 part(c,key,"arm",p+Vector2(24*face,-32),Vector2(34,70),arm_angle-fall*.8,-face,tint,Vector2(1+tier*.14,1+tier*.06) if h.archetype=="crusher" else Vector2(1,1+tier*.10) if h.archetype=="stalker" else Vector2.ONE)
 if not moving or identity.heading.y>=-.4:part(c,key,"weapon",p+Vector2((45-slash*12)*face,9-windup*8),Vector2(100,96),arm_angle+face*.12+fall*.9,face,tint,Vector2(.82,.82))
 # Scars/veins, not identical gold ornaments, fill intermediate evolution levels.
 for n in range(level%3):
  var q=p+Vector2(-8+n*9,-35+n*7)
  c.draw_line(q,q+Vector2(4,11),Color(color,.55*alpha),1.6)
 if level>=7 and not reduced and h.archetype in ["stalker","witch"]:
  for side in [-1,1]:
   var tail=PackedVector2Array([p+Vector2(side*20,-44),p+Vector2(side*(44+sin(clock*2+side)*4),-21),p+Vector2(side*34,18),p+Vector2(side*49,29)])
   c.draw_polyline(tail,Color(color,.18*alpha),5)
 if rebirth>0 and not dead:
  var progress=1-rebirth/3.6
  var intensity=sin(progress*PI)
  c.draw_set_transform(p-Vector2(0,22),0,Vector2(1,1.15));c.draw_circle(Vector2.ZERO,70+intensity*20,Color(.06,.025,.12,.16*intensity));c.draw_set_transform(Vector2.ZERO)
  var burst=clampf((progress-.45)*2.3,0,1)
  for i in range(8 if reduced else 14):
   var v=Vector2.from_angle(i*TAU/(8 if reduced else 14))
   var q=p-Vector2(0,26)+v*(24+burst*75)
   c.draw_colored_polygon(PackedVector2Array([q-v*9,q+v*(8+burst*8),q+v.orthogonal()*5]),Color(color,(1-burst)*intensity*.65))
  c.draw_set_transform(p+Vector2(0,16),0,Vector2(1,.32));c.draw_arc(Vector2.ZERO,25+burst*100,0,TAU,48,Color(color,intensity*.7),3);c.draw_set_transform(Vector2.ZERO)
  c.draw_string_outline(font,p+Vector2(-64,-120),"TRUE NIGHTMARE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("101322"))
  c.draw_string(font,p+Vector2(-64,-120),"TRUE NIGHTMARE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(color,.8))
  for side in [-1,1]:
   var q=p+Vector2(side*(20+intensity*28),-15)
   c.draw_arc(q,24+intensity*30,PI*.3,PI*1.7,32,Color(color,.35),4)
  c.draw_arc(p,35+progress*37,-PI*.95,PI*.95,48,Color(color,.8),3)
  for i in range(6 if reduced else 12):
   var v=Vector2.from_angle(i*TAU/(6 if reduced else 12))
   c.draw_line(p+v*(28+progress*15),p+v*(40+progress*45),Color(color,.6*(1-progress*.5)),2)
func bolt(c,a: Vector2,b: Vector2,color: Color,width=5.0,seed_value=0):
 var points=PackedVector2Array([a]);var delta=b-a;var normal=delta.orthogonal().normalized()
 for i in range(1,8):points.append(a+delta*(i/8.0)+normal*sin(i*8.17+seed_value)*8)
 points.append(b);c.draw_polyline(points,Color(color,.3),width+5);c.draw_polyline(points,color,width);c.draw_polyline(points,Color("F3E7FF"),1.4)
 if CinematicQuality.detail(c)>0:
  for i in [2,5]:c.draw_line(points[i],points[i]+normal*(18 if i%2 else -21),Color(color,.7),2)
func sigil(c,p: Vector2,radius: float,color: Color,clock: float):
 c.draw_arc(p,radius,0,TAU,36,color,2)
 for i in range(6):
  var v=Vector2.from_angle(i*TAU/6+clock*.25);var side=v.orthogonal()*5
  c.draw_polyline(PackedVector2Array([p+v*(radius-8)+side,p+v*(radius+3),p+v*(radius-8)-side]),color,2)
func effects(c,clock: float):
 var m=c.model;var h=m.hunter;var n=h.nightmare;var reduced=CinematicQuality.reduced_motion(c) or CinematicQuality.detail(c)==0
 if m.run_kind=="endless" and m.endless.phase!="combat":return
 var action=n.action if n.action!="" else h.arcane.action
 var target=n.target if n.action!="" else h.arcane.target
 if action!="" and target>=0 and target<m.rooms.size() and h.hp>0:
  var q=O+m.rooms[target].door_approach();var delay=n.warning if n.action!="" else h.arcane.warning
  var physical=action in ["faultline","ossuary","quills","rend"]
  var color=Color("E8B17D") if physical else Color("8DEAF2") if action in ["cage","overload","convergence","chain_lightning","interference"] else Color("CAA0F5")
  skill_shape(c,action,q,clock,true,color)
  sigil(c,q,48,color,0 if reduced else clock)
  c.draw_line(O+h.position+Vector2(0,-34),q,Color(color,.45),2)
  c.draw_string_outline(font,q+Vector2(-50,48),"%.1fs" % delay,HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color("101621"))
  c.draw_string(font,q+Vector2(-50,48),"%.1fs" % delay,HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
 if not h.arcane.bolt.is_empty():
  var point=O+h.arcane.bolt.point;var v=(point-(O+h.position)).normalized()
  c.draw_line(point-v*28,point,Color("A77AD4"),5);c.draw_circle(point,8,Color("DDC7FF"))
 # Every impact uses the actual affected room and actual positive damage event.
 for event in m.presentation_events:
  var age=m.time-float(event.time)
  if age<0 or age>.8:continue
  var special=event.type=="nightmare_impact" or event.type=="door_damage" and event.get("source","") in ["chain_lightning","cursed_projectile","interference","scythe","siege"]
  if not special or float(event.get("amount",event.get("damage",0)))<=0:continue
  var p=O+event.position;var physical=event.get("damage_type","magic")=="physical"
  var color=Color("EAB57E") if physical else Color("8BE7F0") if event.get("element","")=="electric" else Color("C29DEE")
  var alpha=(1-age/.8)*(.65 if CinematicQuality.reduced_flash(c) else 1.0)
  if not physical:bolt(c,O+event.get("origin",h.position)+Vector2(25,-70),p,Color(color,alpha),4 if reduced else 7,int(event.id))
  c.draw_arc(p,28+age*72,0,TAU,36,Color(color,alpha*.85),3)
  for i in range(4 if reduced else 8):
   var v=Vector2.from_angle(i*TAU/(4 if reduced else 8));var point=p+v*(28+age*60)
   if physical:c.draw_polyline(PackedVector2Array([p+v*12,point+v.orthogonal()*7,point+v*18]),Color(color,alpha*.8),3)
   else:c.draw_line(point,point+v*10,Color(color,alpha),3)
 for event in m.presentation_events:
  var age=m.time-float(event.time)
  if event.type=="nightmare_release" and age>=0 and age<1.0 and event.room>=0 and event.room<m.rooms.size():
   var col=Color("E9B685") if event.skill in ["faultline","ossuary","quills","rend"] else Color("92EAF4") if event.skill in ["cage","overload","gust","convergence"] else Color("C9A2EE")
   skill_shape(c,event.skill,O+m.rooms[event.room].door_approach(),clock,false,Color(col,1-age))
 if n.remaining>0 and h.hp>0:
  var color=Color("E7B27D") if n.effect in ["faultline","ossuary","quills","rend"] else Color("9BE7ED") if n.effect in ["overload","cage","gust","convergence"] else Color("C5A0DD")
  skill_shape(c,n.effect,O+h.position,clock,false,Color(color,.65))
  if n.target>=0:
   var room=m.rooms[n.target]
   var marked=room.bed_position() if n.effect=="hex" else room.door_position()
   sigil(c,O+marked,25,Color(color,.5),0)
   if n.effect=="cage":
    for tile in room.buildings:
     if room.buildings[tile].kind in ["turret","heavy"]:c.draw_rect(Rect2(O+room.tile_position(tile)-Vector2(18,28),Vector2(36,40)),Color(color,.45),false,1.5)

func omens(c,clock: float):
 var m=c.model
 if m.run_kind!="endless" or m.endless.omen.active=="":return
 var id=m.endless.omen.active;var reduced=CinematicQuality.reduced_motion(c)
 if id=="blood":
  var p=c.get_canvas_transform().affine_inverse()*Vector2(82,200)
  c.draw_texture_rect(c.presentation.textures.warm_glow,Rect2(p-Vector2(75,75),Vector2(150,150)),false,Color(.65,.03,.10,.20))
  c.draw_circle(p,32,Color("723047"));c.draw_arc(p,34,-PI*.8,PI*.8,40,Color("D88993"),2)
  for i in range(4):c.draw_arc(p+Vector2(i*4-8,i*3-7),17+i*2,PI*.2,PI*1.2,20,Color(.15,.02,.05,.65),2)
  c.draw_arc(O+m.hunter.position+Vector2(0,-35),41,0,TAU,36,Color(.8,.16,.27,.55),3)
 elif id=="blackout":
  c.draw_rect(c.presentation.visible_world_rect(c,0),Color(.005,.008,.035,.07 if reduced else .18))
  for b in m.player().buildings:
   if m.player().buildings[b].kind!="generator":continue
   var p=O+m.player().tile_position(b)
   for side in [-1,1]:c.draw_line(p+Vector2(side*17,-20),p+Vector2(side*26,-28),Color("D1D9A7"),2)
 elif id=="walls":
  var p=O+m.player().door_position();sigil(c,p+Vector2(0,-18),32,Color("BA80DA"),0 if reduced else clock*.5)
  for i in range(3):
   var at=p+Vector2(-16+i*15,-28);c.draw_polyline(PackedVector2Array([at,at+Vector2(-3,-10),at+Vector2(7,-5),at+Vector2(3,6)]),Color("DB9EF0"),2)

func skill_shape(c,id: String,p: Vector2,clock: float,charging: bool,color: Color):
 var reduced=CinematicQuality.reduced_motion(c);var detail=CinematicQuality.detail(c)
 var t=0.0 if reduced else clock
 var radius=56.0 if charging else 86.0
 var points=PackedVector2Array()
 if id=="faultline":
  for side in [-1,1]:
   points=PackedVector2Array([p+Vector2(side*12,-5),p+Vector2(side*29,12),p+Vector2(side*21,23),p+Vector2(side*58,34)])
   c.draw_polyline(points,Color(color,color.a*.22),9);c.draw_polyline(points,color,2.5)
 elif id=="ossuary":
  for side in [-1,1]:
   c.draw_polyline(PackedVector2Array([p+Vector2(side*48,23),p+Vector2(side*44,-28),p+Vector2(side*26,-49),p+Vector2(side*12,-35)]),color,5)
 elif id=="drag":
  for i in range(4):
   var v=Vector2.from_angle(i*TAU/4+t*.3)
   c.draw_line(p+v*radius,p+v*20,color,2);c.draw_circle(p+v*radius,4,color)
 elif id=="oath":
  for side in [-1,1]:c.draw_polyline(PackedVector2Array([p+Vector2(side*42,24),p+Vector2(side*37,-24),p+Vector2(0,-49),p+Vector2(-side*12,-22)]),color,3)
 elif id=="quills":
  for i in range(8):
   var v=Vector2.from_angle(i*TAU/8+t*.12)
   c.draw_colored_polygon(PackedVector2Array([p+v*27,p+v*radius+v.orthogonal()*3,p+v*34+v.orthogonal()*6]),color)
 elif id=="rend":
  for i in range(3):
   var a=p+Vector2(-41+i*15,-41)
   c.draw_line(a,a+Vector2(49,69),Color(color,color.a*.2),9);c.draw_line(a,a+Vector2(49,69),color,3)
 elif id=="hex":
  for i in range(5):
   var v=Vector2.from_angle(i*TAU/5+t*.2);var q=p+v*radius
   c.draw_polyline(PackedVector2Array([p+v*20,q-v.orthogonal()*9,q,q+v.orthogonal()*9,p+v*20]),color,2)
 elif id=="ritual":
  for i in range(3):
   var q=p+Vector2.from_angle(i*TAU/3+t*.2)*radius*.65
   sigil(c,q,21,color,t)
 elif id=="cage":
  for i in range(4):
   var x=-42+i*28
   bolt(c,p+Vector2(x,-48),p+Vector2(x+sin(t+i)*4,30),color,1.5,i)
 elif id=="overload":
  for side in [-1,1]:bolt(c,p+Vector2(side*20,-54),p+Vector2(side*52,9),color,3,side)
  c.draw_circle(p,10,Color(color,color.a*.25));c.draw_arc(p,30,0,TAU,32,color,3)
 elif id=="gust":
  for i in range(3):c.draw_arc(p+Vector2(i*3,-i*8),radius-i*7,t*.25+i,t*.25+i+PI*1.3,28,color,2)
 elif id=="convergence":
  # This local channel ornament is not a claim of extra room hits.
  for i in range(3):
   var q=p+Vector2.from_angle(i*TAU/3-PI/2)*radius
   bolt(c,q,p+Vector2(0,-8),Color(color,color.a*.7),2,i)
 if id in ["convergence","ritual"]:
  var top=p-Vector2(0,100 if charging else 126)
  c.draw_set_transform(top,0,Vector2(1,.35));c.draw_circle(Vector2.ZERO,42,Color(color,color.a*.12));c.draw_set_transform(Vector2.ZERO)
  if not charging:bolt(c,top,p-Vector2(0,8),Color(color,color.a*.8),4,7)
 if not charging and detail>0:
  for i in range(4+detail*2):
   var v=Vector2.from_angle(i*TAU/(4+detail*2)+t*.1)
   c.draw_line(p+v*(radius+3),p+v*(radius+9),Color(color,color.a*.45),2)
func atmosphere(c,clock: float):
 var detail=CinematicQuality.detail(c)
 if detail==0:return
 var rect=c.presentation.visible_world_rect(c,0)
 # Low-opacity moonlight stays behind creatures and HUD. Bounded geometry only.
 var base=rect.position+Vector2(rect.size.x*.17,0)
 var drift=0.0 if CinematicQuality.reduced_motion(c) else sin(clock*.12)*18
 for i in range(2 if detail==1 else 3):
  var q=base+Vector2(i*220+drift,0)
  c.draw_colored_polygon(PackedVector2Array([q,q+Vector2(75,0),q+Vector2(260,rect.size.y),q+Vector2(100,rect.size.y)]),Color(.35,.49,.68,.025))
 if c.model.hunter.hp>0 and c.model.hunter.target==c.model.player_room:
  var p=O+c.model.hunter.position
  c.draw_set_transform(p+Vector2(15,16),-.25,Vector2(1,.25));c.draw_circle(Vector2.ZERO,53,Color(.015,.014,.035,.18));c.draw_set_transform(Vector2.ZERO)

 if detail>=2:
  for i in range(3):
   var q=rect.position+Vector2(fposmod(i*311+clock*3,rect.size.x),rect.size.y*(.65+i*.1))
   c.draw_texture_rect(c.presentation.textures.warm_glow,Rect2(q-Vector2(150,28),Vector2(300,56)),false,Color(.25,.36,.50,.035))
