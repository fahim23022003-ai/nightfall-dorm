extends RefCounted
# Cosmetic world only: no entities, physics, targeting, navigation or model RNG.
const OFFSET=Vector2(145,40)
const KINDS=["shadow_walker","watching_eyes","crawling_shadow","window_watcher","fog_apparition"]
const THEMES={"dorm":{"rain":12,"fog":5,"storm":30.0,"color":"526879"},"hospital":{"rain":8,"fog":4,"storm":38.0,"color":"7CA7AE"},"hotel":{"rain":16,"fog":5,"storm":32.0,"color":"8A6B94"},"lab":{"rain":3,"fog":3,"storm":42.0,"color":"65AA9F"},"mansion":{"rain":28,"fog":8,"storm":24.0,"color":"777B9F"}}
var creatures: Array=[]
var anchors: Array=[]
var weather_events: Array=[]
var scenery: Array=[]
var serial=0
var clock=0.0
var flash=0.0
var thunder_due=-1.0
var next_lightning=12.0
var next_wind=3.0
var observed_model
var theme="dorm"
var rng=RandomNumberGenerator.new()
var reduced_effects=false
var bounds=Rect2()
func is_exterior(point: Vector2,model,radius=26.0) -> bool:
 for room in model.rooms:
  if room.bounds().grow(radius).has_point(point):return false
 if model.map_id!="legacy":
  for rect in model.map_data.get("corridors",[]):
   if rect.grow(radius).has_point(point):return false
 else:
  if Rect2(25,320,930,180).grow(radius).has_point(point):return false
 return true
func configure(model):
 observed_model=model;clock=0;flash=0;thunder_due=-1;serial=0;weather_events.clear();creatures.clear();anchors.clear();scenery.clear()
 theme=str(model.map_data.get("theme","dorm"));bounds=model.map_bounds().grow(180)
 rng.seed=7823+abs(hash(model.map_id))
 for y in range(int(bounds.position.y),int(bounds.end.y),46):
  for x in range(int(bounds.position.x),int(bounds.end.x),46):
   var point=Vector2(x,y)
   if is_exterior(point,model,30):anchors.append(point)
 for i in range(mini(70,anchors.size())):
  scenery.append({"position":anchors[(i*17)%anchors.size()],"variant":i%5})
 var visible_anchors=[]
 var center=model.map_bounds().get_center()
 for point in anchors:
  if model.map_bounds().grow(60).has_point(point) and absf(point.y-center.y)<model.map_bounds().size.y*.35:visible_anchors.append(point)
 if visible_anchors.is_empty():visible_anchors=anchors.duplicate()
 visible_anchors.sort_custom(func(a,b):return a.distance_to(center)<b.distance_to(center))
 for i in range(5):
  if anchors.is_empty():break
  var point=visible_anchors[mini(i*3,visible_anchors.size()-1)]
  creatures.append({"kind":KINDS[i],"position":point,"origin":point,"age":float(-i*2),"life":12.0+i,"visible":i==0,"generation":0})
 next_lightning=12+rng.randf_range(0,5);next_wind=3
func emit_weather(cue: String,point: Vector2):
 serial+=1;weather_events.append({"id":serial,"cue":cue,"position":point,"time":clock})
 if weather_events.size()>16:weather_events.pop_front()
func update(delta: float,model,reduced=null):
 if model!=observed_model:configure(model)
 if not is_finite(delta) or delta<=0 or not model.running:return
 if reduced!=null:reduced_effects=bool(reduced)
 clock+=delta;flash=maxf(0,flash-delta)
 if clock>=next_lightning:
  flash=.6
  thunder_due=clock+rng.randf_range(.6,1.8)
  next_lightning=clock+THEMES[theme].storm+rng.randf_range(0,12)
 if thunder_due>=0 and clock>=thunder_due:
  emit_weather("weather_thunder",bounds.get_center());thunder_due=-1
 if clock>=next_wind:
  emit_weather("weather_wind",bounds.get_center());emit_weather("weather_rain",bounds.get_center())
  next_wind=clock+10+rng.randf_range(0,4)
 for creature in creatures:
  creature.age+=delta
  if creature.age>creature.life:
   creature.age=-rng.randf_range(4,9);creature.generation+=1
   creature.origin=anchors[rng.randi_range(0,anchors.size()-1)];creature.position=creature.origin
  creature.visible=creature.age>=0 and creature.age<=creature.life
  var movement=Vector2(sin(creature.age*.35)*35,cos(creature.age*.25)*10) if creature.kind in ["shadow_walker","crawling_shadow"] else Vector2.ZERO
  var candidate=creature.origin+movement
  if is_exterior(candidate,model,30):creature.position=candidate
func creature_alpha(creature) -> float:
 if not creature.visible:return 0.0
 if creature.kind=="fog_apparition":return clampf(flash*3,0,1)
 return clampf(minf(creature.age,creature.life-creature.age),0,1)*.8
func render(c,p):
 var m=c.model
 if observed_model!=m:configure(m)
 var palette=Color(THEMES[theme].color)
 var visible=p.visible_world_rect(c,90)
 # Scenery is drawn beneath architecture. Every animated actor remains outside
 # the protected room/corridor union, including its complete bounding footprint.
 for entry in scenery:
  var q=OFFSET+entry.position
  if not visible.has_point(q):continue
  var variant=entry.variant
  if theme in ["dorm","mansion"]:
   c.draw_line(q+Vector2(0,35),q+Vector2(-5,-44),Color("17202A"),8)
   for side in [-1,1]:
    c.draw_polyline(PackedVector2Array([q+Vector2(-3,-12),q+Vector2(side*20,-28),q+Vector2(side*32,-47)]),Color("1B2630"),4)
   if theme=="mansion" and variant%2==0:
    c.draw_style_box(p.frame(Color("30303D"),Color("62616B"),8),Rect2(q+Vector2(10,4),Vector2(22,29)))
    c.draw_line(q+Vector2(15,15),q+Vector2(27,15),Color("74717D"),2)
  elif theme=="hospital":
   c.draw_rect(Rect2(q-Vector2(29,30),Vector2(58,63)),Color("233B45"))
   c.draw_line(q+Vector2(-22,-25),q+Vector2(20,-25),Color(palette,.35+.2*sin(clock*3+q.x)),3)
   c.draw_line(q+Vector2(-8,10),q+Vector2(9,10),Color("765565"),3);c.draw_line(q+Vector2(0,2),q+Vector2(0,18),Color("765565"),3)
  elif theme=="hotel":
   c.draw_rect(Rect2(q-Vector2(29,34),Vector2(58,70)),Color("302737"))
   for side in [-1,1]:
    c.draw_rect(Rect2(q+Vector2(side*14-7,-22),Vector2(14,23)),Color("131B28"))
    c.draw_line(q+Vector2(side*14-6,-20),q+Vector2(side*14+5,-3),Color("665968"),1)
  else:
   c.draw_style_box(p.frame(Color("162D35"),Color("47776F"),3),Rect2(q-Vector2(27,36),Vector2(54,75)))
   c.draw_rect(Rect2(q-Vector2(19,27),Vector2(38,47)),Color("1A4549"))
   c.draw_line(q-Vector2(14,24),q+Vector2(11,12),Color(.5,.9,.8,.25),2)
   if sin(clock*4+q.x)>.94:c.draw_line(q+Vector2(22,-18),q+Vector2(29,-11),Color("B6EDD0"),2)
 for creature in creatures:
  var alpha=creature_alpha(creature)
  if alpha<=0:continue
  var q=OFFSET+creature.position
  if not visible.has_point(q):continue
  var shade=Color(.08,.09,.15,alpha)
  match creature.kind:
   "shadow_walker":
    c.draw_circle(q+Vector2(0,-17),7,shade);c.draw_line(q+Vector2(0,-8),q+Vector2(0,11),shade,10)
    for side in [-1,1]:c.draw_line(q+Vector2(0,8),q+Vector2(side*8*sin(clock*2),23),shade,4)
   "watching_eyes":
    for side in [-1,1]:c.draw_circle(q+Vector2(side*6,0),2.4,Color(1,.45,.32,alpha*(.7+.3*sin(clock*2))))
   "crawling_shadow":
    c.draw_circle(q,9,shade)
    for i in range(4):
     var leg=Vector2(-19+i*12,9+sin(clock*4+i)*5)
     c.draw_line(q, q+leg,shade,3)
   "window_watcher":
    c.draw_rect(Rect2(q-Vector2(18,27),Vector2(36,49)),Color("334552"),false,3)
    c.draw_circle(q+Vector2(0,-10),7,shade);c.draw_line(q+Vector2(0,-4),q+Vector2(0,19),shade,12)
   "fog_apparition":
    c.draw_circle(q+Vector2(0,-11),10,Color(palette,alpha))
    c.draw_colored_polygon(PackedVector2Array([q+Vector2(-8,-5),q+Vector2(-17,22),q+Vector2(0,15),q+Vector2(16,23),q+Vector2(8,-5)]),Color(palette,alpha))
    if flash>0:c.draw_arc(q,27,0,TAU,24,Color(.7,.85,1,alpha*.3),2)
 for i in range(3):
  ellipse(c,OFFSET+Vector2(bounds.position.x+fposmod(clock*6+i*410,bounds.size.x),bounds.position.y+25),Vector2(230,43),Color(.03,.05,.08,.6))
 # Fog, rain, clouds and birds remain beneath all gameplay geometry and actors.
 var fog_count=2 if reduced_effects else int(THEMES[theme].fog)
 for i in range(fog_count):
  var q=Vector2(bounds.position.x+fposmod(i*311+clock*12,bounds.size.x),bounds.position.y+fposmod(i*193,bounds.size.y))
  ellipse(c,OFFSET+q,Vector2(150,25),Color(palette,.075))
 var rain_count=3 if reduced_effects else int(THEMES[theme].rain)
 for i in range(rain_count):
  var q=Vector2(bounds.position.x+fposmod(i*137+clock*24,bounds.size.x),bounds.position.y+fposmod(i*89+clock*180,bounds.size.y))
  c.draw_line(OFFSET+q,OFFSET+q+Vector2(-8,23),Color(palette,.25),1)
 if theme in ["mansion","dorm"]:
  for i in range(3 if not reduced_effects else 1):
   var q=OFFSET+Vector2(bounds.position.x+fposmod(clock*40+i*290,bounds.size.x),bounds.position.y+30+sin(clock+i)*10)
   c.draw_polyline(PackedVector2Array([q+Vector2(-9,-sin(clock*8)*6),q,q+Vector2(9,-sin(clock*8)*6)]),Color("747484"),2)
 if flash>0 and not reduced_effects:c.draw_rect(Rect2(OFFSET+bounds.position,bounds.size),Color(.65,.76,.9,flash*.09))
func ellipse(c,center: Vector2,radius: Vector2,color: Color):
 var points=PackedVector2Array()
 for i in range(32):points.append(center+Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius)
 c.draw_colored_polygon(points,color)
