extends RefCounted
## Illustration, animation and environment only. No economy/AI mutations.
const OFFSET = Vector2(145,40)
const ROOM_NAMES = ["WILLOW","WREN","ASTER","MOSS","CEDAR","FERN"]
var textures: Dictionary = {}
var cartoon: Dictionary = {}
var prestige_art: Dictionary={}
var all_rooms=true
var item_presentation=preload("res://scripts/item_presentation.gd").new()
var boss_presentation=preload("res://scripts/boss_presentation.gd").new()
var environment=preload("res://scripts/haunted_environment.gd").new()
var fear_rooms: Dictionary={}
var seen_deaths: Dictionary={}
var attack_pose=0.0
var strike_position=Vector2.ZERO
var strike_events: Dictionary={}
var map_presentation=preload("res://scripts/map_presentation.gd").new()
var previous_sleep: Dictionary={}
var sleep_age: Dictionary={}
var directions: Dictionary={}
var visual_events: Array=[]
var seen_event=0
var previous_doors: Dictionary={}
var previous_life: Dictionary={}
var death_ages: Dictionary={}
var enter_from: Dictionary={}
var last_model_time=0.0
var hunter_clock=0.0
var levels: Dictionary={}
var clock = 0.0
var previous: Dictionary = {}
var moving: Dictionary = {}
var death_age = 0.0
var font = preload("res://assets/fonts/Interface.ttf")

func _init():
 for kind in ["turret","heavy"]:
  for level in range(5,11):prestige_art["%s_%d" % [kind,level]]=load("res://assets/defenses/%s_%d.svg" % [kind,level])
 for name in ["bed","bed_upgraded","cabinet","plant","lantern","door","door_reinforced","survivor_idle","survivor_walk_a","survivor_walk_b","survivor_sleep","bot_idle","bot_walk","hunter_idle","hunter_move","hunter_attack","hunter_hurt","hunter_death","turret","heavy","generator","repair","economy","enhancer","floor_wood","corridor","coin","power","foundation","window","shadow","warm_glow"]:
  textures[name] = load("res://assets/art/"+name+".png")

 # New cartoon assets are staged in one room until its actual capture is reviewed.
 var names=["desk","cabinet","bookshelf","plant","lamp","window","utility","generator","repair","economy","enhancer","player_sleep","player_enter","player_eliminated","hunter_idle","hunter_move","hunter_target","hunter_attack","hunter_hurt","hunter_death","construction","projectile","poster","old_poster","clothes","books","rug","pipes"]
 for i in range(1,6): names.append("bed_%d" % i); names.append("door_%d" % i)
 for i in range(1,5): names.append("turret_%d" % i); names.append("heavy_%d" % i)
 for kind in ["generator","repair","economy","enhancer"]:
  for i in range(1,5): names.append("%s_%d" % [kind,i])
 for i in range(6): names.append("floor_%d" % i)
 for i in range(5): names.append("bot_sleep_%d" % i)
 names.append("corridor")
 for dir in ["up","down","left","right"]:
  for i in range(4): names.append("player_%s_%d" % [dir,i])
 for bot in range(5):
  names.append("bot_%d" % bot)
  for i in range(4): names.append("bot_%d_walk_%d" % [bot,i])
 for name in names: cartoon[name]=load("res://assets/cartoon/"+name+".png")
 textures.merge(cartoon,true)
 for alias in {"bed":"bed_1","bed_upgraded":"bed_5","turret":"turret_1","heavy":"heavy_1","cabinet":"cabinet","plant":"plant","lantern":"lamp","window":"window","generator":"generator","repair":"repair","economy":"economy","enhancer":"enhancer","survivor_idle":"player_down_0","survivor_walk_a":"player_down_1","survivor_walk_b":"player_down_3","survivor_sleep":"player_sleep","bot_idle":"bot_0","bot_walk":"bot_0_walk_1"}:
  var mapping={"bed":"bed_1","bed_upgraded":"bed_5","turret":"turret_1","heavy":"heavy_1","cabinet":"cabinet","plant":"plant","lantern":"lamp","window":"window","generator":"generator","repair":"repair","economy":"economy","enhancer":"enhancer","survivor_idle":"player_down_0","survivor_walk_a":"player_down_1","survivor_walk_b":"player_down_3","survivor_sleep":"player_sleep","bot_idle":"bot_0","bot_walk":"bot_0_walk_1"}
  textures[alias]=cartoon[mapping[alias]]
 textures.door=cartoon.door_1
 textures.door_reinforced=cartoon.door_4
 textures.corridor=cartoon.corridor
 textures.floor_wood=cartoon.floor_0
 for name in ["hunter_idle","hunter_move","hunter_attack","hunter_hurt","hunter_death"]: textures[name]=cartoon[name]

func reset():
 fear_rooms.clear();seen_deaths.clear();strike_events.clear();attack_pose=0
 environment.observed_model=null
 previous.clear()
 moving.clear()
 directions.clear()
 previous_sleep.clear()
 previous_life.clear()
 sleep_age.clear()
 death_ages.clear()
 enter_from.clear()
 previous_doors.clear()
 levels.clear()
 visual_events.clear()
 seen_event=0
 death_age=0
 hunter_clock=0
 last_model_time=0

func update(delta: float, model):
 if model.time<last_model_time: reset()
 last_model_time=model.time
 hunter_clock+=maxf(0,delta-model.items.frozen_delta) if model.running else delta
 clock+=delta
 attack_pose=maxf(0,attack_pose-maxf(0,delta-model.items.frozen_delta))
 if not model.tutorial_mode:environment.update(delta,model)
 for index in fear_rooms:fear_rooms[index]+=delta
 var old=previous.duplicate()
 var motion=model.player_position-old.get("player",model.player_position)
 moving.player=motion.length()>0.05
 if motion.length()>0.05:
  directions.player=("right" if motion.x>0 else "left") if absf(motion.x)>absf(motion.y) else ("down" if motion.y>0 else "up")
 previous.player=model.player_position
 for room in model.rooms:
  moving[room.index]=old.has(room.index) and old[room.index].distance_to(room.resident_position)>0.05
  previous[room.index]=room.resident_position
  if room.sleeping and not previous_sleep.get(room.index,false):
   sleep_age[room.index]=0.0
   enter_from[room.index]=old.get("player",room.bed_position()) if room.owner==0 else old.get(room.index,room.resident_position)
  sleep_age[room.index]=sleep_age.get(room.index,0.0)+delta
  previous_sleep[room.index]=room.sleeping
  if not room.alive and previous_life.get(room.index,true): death_ages[room.index]=0.0
  death_ages[room.index]=death_ages.get(room.index,0.0)+delta
  previous_life[room.index]=room.alive
  var old_hp=previous_doors.get(room.index,room.door_hp)
  if old_hp>0 and room.door_hp<=0: effect("break",room.door_position(),0.7)
  elif room.door_hp>old_hp+0.1 and room.door_hp<room.max_hp(): effect("repair",room.door_position(),0.35)
  previous_doors[room.index]=room.door_hp
  for key in ["bed","door"]:
   var value=room.bed_level if key=="bed" else room.door_level
   var id="%d:%s" % [room.index,key]
   if levels.has(id) and value>levels[id]: effect("level",room.bed_position() if key=="bed" else room.door_position(),0.8)
   levels[id]=value
  for tile in room.buildings:
   var b=room.buildings[tile]
   var id="%d:tile%d" % [room.index,tile]
   if not levels.has(id): effect("build",room.tile_position(tile),0.45)
   elif b.level>levels[id]: effect("prestige" if b.level==10 else "level",room.tile_position(tile),1.2 if b.level==10 else 0.8)
   levels[id]=b.level
 for e in model.combat_events:
  if e.id>seen_event:
   seen_event=e.id
   if e.type=="impact": effect("impact",e.position,0.3)
 for e in visual_events: e.life-=delta
 visual_events=visual_events.filter(func(e): return e.life>0)
 for event in model.presentation_events:
  if event.type=="survivor_attack" and not strike_events.has(event.id):
   strike_events[event.id]=true;attack_pose=.35;strike_position=model.rooms[event.room].bed_position()
  if event.type=="survivor_fear" and not fear_rooms.has(event.room):fear_rooms[event.room]=0.0
  if event.type=="elimination" and not seen_deaths.has(event.room) and not model.rooms[event.room].alive:
   seen_deaths[event.room]=true;death_ages[event.room]=0.0
 if model.hunter.state==HunterState.State.DEAD: death_age+=delta
 else: death_age=0

func effect(kind: String,point: Vector2,life: float):
 if kind in ["level","prestige"]:visual_events=visual_events.filter(func(e):return not (e.kind in ["level","prestige"] and e.position.distance_to(point)<1))
 visual_events.append({"kind":kind,"position":point,"life":life,"total":life})
 if visual_events.size()>80: visual_events.pop_front()

func building_key(kind: String,level: int) -> String:
 var key="%s_%d" % [kind,mini(4,level)]
 return key if cartoon.has(key) else kind

func sprite(c: Node2D, name: String, center: Vector2, size: Vector2, tint: Color = Color.WHITE, rotation: float = 0.0):
 c.draw_set_transform(center,rotation)
 c.draw_texture_rect(textures[name],Rect2(-size/2,size),false,tint)
 c.draw_set_transform(Vector2.ZERO)

func text(c: Node2D, value: String, pos: Vector2, size: int = 12, color: Color = Color("dfd4bd")):
 c.draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func bar(c: Node2D, pos: Vector2, width: float, fraction: float):
 c.draw_style_box(frame(Color("171c2b"),Color("a18b67"),3),Rect2(pos,Vector2(width,9)))
 var fill = frame(Color("83c9ad") if fraction>0.4 else Color("dc8d76"),Color.TRANSPARENT,2)
 fill.set_border_width_all(0)
 c.draw_style_box(fill,Rect2(pos+Vector2(2,2),Vector2(maxf(0,width-4)*clampf(fraction,0,1),5)))

func frame(fill: Color, edge: Color, radius: int = 5) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = edge
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 return style

func render(c):
 c.draw_rect(Rect2(-3000,-3000,6000,6000),Color("182B3A"))
 # Architectural surround, soft night haze and deliberate negative space.
 for i in range(8):
  c.draw_circle(Vector2(1050,170),420-i*30,Color(0.22,0.29,0.39,0.025))
 for i in range(60):
  var x = fmod(i*173.71,1260)+10
  var y = fmod(i*83.13,880)+10
  c.draw_circle(Vector2(x,y),0.8,Color(0.8,0.78,0.65,0.08+sin(clock+i)*0.035))
 if c.mode == "menu":
  menu_scene(c)
  return
 # Coordinates are translated only here; model geometry is unchanged.
 var m = c.model
 environment.reduced_effects=c.profile.settings.get("reduced_effects",false)
 if not m.tutorial_mode:environment.render(c,self)
 if m.map_id!="legacy": map_presentation.render_architecture(c,self)
 else:
  for room in m.rooms:
   if all_rooms or room.index==1: cartoon_room(c,room,room.index==m.player_room)
   else: room_scene(c,room,room.index==m.player_room)
  c.draw_texture_rect(textures.corridor,Rect2(OFFSET+Vector2(35,330),Vector2(900,160)),false)
  # Hall edges, brass runner and wall sconces join the rooms into one building.
  c.draw_line(OFFSET+Vector2(30,329),OFFSET+Vector2(940,329),Color("a48b6e"),3)
  c.draw_line(OFFSET+Vector2(30,491),OFFSET+Vector2(940,491),Color("a48b6e"),3)
  for x in [340,650]:
   sprite(c,"warm_glow",OFFSET+Vector2(x,366),Vector2(160,150))
   sprite(c,"lantern",OFFSET+Vector2(x,340),Vector2(24,40))
   sprite(c,"warm_glow",OFFSET+Vector2(x,461),Vector2(140,130))
   sprite(c,"lantern",OFFSET+Vector2(x,481),Vector2(23,36))
  text(c,"NORTH   •   NIGHT WATCH",OFFSET+Vector2(363,353),10,Color("b8b5a6"))
  text(c,"SOUTH   •   KEEP THE LIGHTS ALIVE",OFFSET+Vector2(345,479),10,Color("b8b5a6"))
 for room in m.rooms:
  if m.map_id!="legacy": map_presentation.render_door(c,self,room)
  else: door_scene(c,room)
  if room.sleeping:
   if fear_rooms.has(room.index) and m.hunter.target==room.index and m.hunter.state==HunterState.State.BREACH and m.hunter.hp>0:
    var q=OFFSET+room.bed_position()+Vector2(sin(clock*32)*2,-8)
    sprite(c,"player_enter" if room.owner==0 else "bot_%d" % posmod(room.owner-1,5),q,Vector2(40,50))
    text(c,"!",q+Vector2(-4,-35),22,Color("FFB0AC"))
    continue
   var age=sleep_age.get(room.index,1.0)
   if age<0.35:
    var point=enter_from.get(room.index,room.bed_position()).lerp(room.bed_position(),age/0.35)
    c.draw_texture_rect(cartoon.player_enter,Rect2(OFFSET+point-Vector2(23,37),Vector2(46,48)),false)
   else:
    var key="player_sleep" if room.owner==0 else "bot_sleep_%d" % posmod(room.owner-1,5)
    c.draw_texture_rect(cartoon[key],Rect2(OFFSET+room.bed_position()+Vector2(-22,-30+sin(clock*1.7+room.index)*0.6),Vector2(44,46)),false)
    if room.owner>0: text(c,room.survivor_name(),OFFSET+room.bed_position()+Vector2(-17,-34),10,Color("E2D9C8"))
  elif room.owner>0 and room.alive: resident(c,room.resident_position,room.index,false)
  elif not room.alive:
   var age=float(death_ages.get(room.index,2.0))
   var key="player_eliminated" if room.owner==0 else "bot_%d" % posmod(room.owner-1,5)
   var q=OFFSET+(room.eliminated_position if room.eliminated_position.is_finite() else room.bed_position())
   c.draw_rect(Rect2(OFFSET+room.bounds().position,room.bounds().size),Color(.015,.02,.04,.35))
   var collapse=clampf((age-.2)/1.2,0,1)
   c.draw_set_transform(q+Vector2(0,collapse*9),collapse*PI*.5,Vector2.ONE)
   c.draw_texture_rect(cartoon[key],Rect2(Vector2(-18,-28),Vector2(36,48)),false,Color(.55,.5,.65,1-collapse*.35))
   c.draw_set_transform(Vector2.ZERO)
   text(c,"ABANDONED",q+Vector2(-35,38),10,Color("9D879A"))

 if (m.player()==null or not m.player().sleeping) and (m.player()==null or m.player().alive):
  resident(c,m.player_position,-1,true)
 if m.hunter.state != HunterState.State.DORMANT:
  hunter(c,m.hunter)
  if attack_pose>0:
   var q=OFFSET+strike_position
   var sweep=(1-attack_pose/.35)*PI
   c.draw_arc(q,32,sweep-PI*.7,sweep,24,Color(1,.55,.6,attack_pose/.35),3)
   if not c.profile.settings.get("reduced_effects",false):c.draw_line(q+Vector2(-20,-17),q+Vector2(18,15),Color(1,.7,.7,attack_pose/.35),2)
 for shot in m.projectiles:
  var p=OFFSET+shot.position
  var direction=(m.hunter.position-shot.position).normalized()
  if shot.level>=7:
   c.draw_line(p-direction*18,p,Color("F3CB78") if shot.level==10 else Color("B2A3FA"),3)
  if shot.kind=="heavy":
   sprite(c,"projectile",p,Vector2(20+shot.level*2,12+shot.level),Color.WHITE,direction.angle())
  else:
   var side=Vector2(-direction.y,direction.x)*2
   for n in range(2 if shot.level>=3 else 1):
    var start=p+side*(n*2-1 if shot.level>=3 else 0)
    c.draw_line(start-direction*10,start+direction*5,Color("4DDDF3"),3)
    c.draw_line(start-direction*4,start+direction*5,Color("DDF9FF"),1)
 for e in visual_events:
  var p=OFFSET+e.position
  var fraction=e.life/e.total
  if e.kind in ["build","break"]:
   c.draw_texture_rect(cartoon.construction,Rect2(p-Vector2(31,31),Vector2(62,62)),false,Color(1,1,1,fraction))
  elif e.kind in ["level","prestige"]:
   c.draw_arc(p,20+(1-fraction)*18,0,TAU,32,Color(0.48,0.89,0.63,fraction),2)
   text(c,"LEVEL 10 · PRESTIGE" if e.kind=="prestige" else "LEVEL UP",p+Vector2(-40,-20-(1-fraction)*15),12,Color(1,.85,.5,fraction) if e.kind=="prestige" else Color(0.7,1,0.75,fraction))
  else:
   var color=Color("7BE3A1") if e.kind=="repair" else Color("A88CEB")
   for i in range(6):
    var v=Vector2.from_angle(i*TAU/6)*(8+(1-fraction)*15)
    c.draw_line(p+v,p+v*1.3,Color(color,fraction),2)
 for room in m.rooms:
  for tile in room.buildings:
   var b=room.buildings[tile]
   if b.kind in ["turret","heavy"] and b.level>=5:
    prestige(c,OFFSET+room.tile_position(tile),b.level,b.kind)
 if c.get("horror")!=null: c.horror.render_world(c)
 item_presentation.draw(c)
 for f in c.floating:
  sprite(c,"coin",OFFSET+f.position+Vector2(-12,-5),Vector2(13,13),Color(1,1,1,f.life))
  text(c,f.text,OFFSET+f.position,14,Color(0.96,0.77,0.26,f.life))

func room_scene(c, room: RoomState, owned: bool):
 var r = Rect2(OFFSET+room.bounds().position,room.bounds().size)
 c.draw_style_box(frame(Color("080f1c"),Color("0a1221"),9),Rect2(r.position-Vector2(7,3),r.size+Vector2(24,24)))
 c.draw_texture_rect(textures.floor_wood,r,false,Color("d9d2c5") if room.alive else Color("8a7790"))
 # Raised wall surfaces, wallpaper grooves, timber caps and skirting.
 c.draw_style_box(frame(Color("314a53"),Color("142631"),5),Rect2(r.position-Vector2(8,9),Vector2(r.size.x+16,51)))
 for x in range(0,270,13):
  c.draw_line(r.position+Vector2(x,-6),r.position+Vector2(x,39),Color("3b5960"),1)
 c.draw_line(r.position+Vector2(-7,-10),r.position+Vector2(277,-10),Color("ac9475"),3)
 for side in [r.position.x-8,r.end.x]:
  c.draw_style_box(frame(Color("2c414d"),Color("708075"),2),Rect2(Vector2(side,r.position.y+9),Vector2(8,211)))
 c.draw_line(Vector2(r.position.x,r.end.y),r.end,Color("b59b78"),5)
 if owned:
  c.draw_style_box(frame(Color.TRANSPARENT,Color("e0bf7e"),5),r.grow(10))
  var badge=Rect2(r.position+Vector2(8,r.size.y-22 if room.index<3 else 75),Vector2(87,17))
  c.draw_style_box(frame(Color("2c3f46"),Color("e6c68b"),3),badge)
  text(c,"YOUR ROOM",badge.position+Vector2(8,12),10,Color("ffe6af"))
 sprite(c,"window",Vector2(r.position.x+145,r.position.y+24) if room.index<3 else Vector2(r.get_center().x,r.end.y-7),Vector2(57,36))
 sprite(c,"cabinet",OFFSET+room.cabinet_position(),Vector2(38,48))
 sprite(c,"plant",OFFSET+room.plant_position(),Vector2(27,38))
 var bed = OFFSET+room.bed_position()
 sprite(c,"shadow",bed+Vector2(0,26),Vector2(76,51))
 sprite(c,"bed_upgraded" if room.bed_level>=2 else "bed",bed,Vector2(65,92))
 sprite(c,"warm_glow",r.position+Vector2(25,48),Vector2(125,145),Color(1,1,1,0.55))
 sprite(c,"lantern",r.position+Vector2(22,24),Vector2(17,29))
 # Engraved room plaques replace debugging ownership labels.
 var plaque = Rect2(r.position+Vector2(8,1),Vector2(103,18))
 c.draw_style_box(frame(Color("273440"),Color("9c8466"),4),plaque)
 text(c,"%02d  %s" % [room.index+1,ROOM_NAMES[room.index]],plaque.position+Vector2(10,13),10)
 for tile in range(6):
  var p = OFFSET+room.tile_position(tile)
  if not room.buildings.has(tile):
   sprite(c,"foundation",p,Vector2(49,49),Color(1.5,1.35,1.1,1.0) if owned else Color(1,1,1,0.25))
  else:
   var b = room.buildings[tile]
   var pulse = sin(clock*3+tile)*0.02 if b.kind in ["generator","economy","enhancer"] else 0.0
   sprite(c,"shadow",p+Vector2(0,15),Vector2(58,33))
   var angle = (c.model.hunter.position-room.tile_position(tile)).angle()+0.3 if b.kind in ["turret","heavy"] and c.model.time>c.model.preparation else 0.0
   sprite(c,b.kind,p+Vector2(0,-6),Vector2(52,55)*(1+pulse),Color.WHITE,angle*0.18)
   for pip in range(b.level):
    c.draw_circle(p+Vector2(-7+pip*5,25),1.7,Color("eed59a"))
  if owned and c.selected_tile == tile and c.ui.context_open:
   c.draw_arc(p,28,0,TAU,40,Color("f6d78f"),2)

func door_scene(c, room):
 var p = OFFSET+room.door_position()
 if c.get("horror")!=null: p+=c.horror.door_shake(room.index)
 elif room.damage_flash>0: p+=Vector2(sin(clock*90),cos(clock*73))*room.damage_flash*6
 c.draw_style_box(frame(Color("607D8B"),Color("263746"),4),Rect2(p-Vector2(32,10),Vector2(64,36)))
 sprite(c,"shadow",p+Vector2(0,13),Vector2(83,39))
 if room.door_hp>0:
  var tint = Color(1.65,0.65,0.65) if room.damage_flash>0 else Color.WHITE
  if room.closed:
   c.draw_texture_rect(cartoon["door_%d" % (room.door_level+1)],Rect2(p+Vector2(-36,-41),Vector2(73,61)),false,tint)
  else:
   sprite(c,"door",p+Vector2(-31,-10),Vector2(40,50),Color("A3B8C0"),-0.95)
  if room.door_hp < room.max_hp()*0.55:
   c.draw_polyline(PackedVector2Array([p+Vector2(-8,-29),p+Vector2(1,-16),p+Vector2(-4,-5),p+Vector2(10,5)]),Color("382432"),2)
 else:
  for i in range(4):
   c.draw_line(p+Vector2(-25+i*14,-7),p+Vector2(-19+i*13,13),Color("88684e"),5)
 if room.owner>=0:
  var targeted=c.model.hunter.target==room.index and c.model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
  if room.index==c.model.player_room or targeted:
   var hp_box=Rect2(p+Vector2(43,-21),Vector2(79,17))
   c.draw_style_box(frame(Color("263746"),Color("de8b79") if targeted else Color("7BE3A1"),4),hp_box)
   text(c,"%d/%d" % [room.door_hp,room.max_hp()],hp_box.position+Vector2(6,12),10)
   bar(c,p+Vector2(46,0),73,room.door_hp/room.max_hp())
   if targeted:
    c.draw_arc(p+Vector2(0,-9),39,0,TAU,40,Color(0.95,0.61,0.48,0.4+sin(clock*6)*0.2),2)
  else:
   bar(c,p+Vector2(-31,28 if room.index<3 else -42),62,room.door_hp/room.max_hp())

func resident(c, pos: Vector2, index: int, player: bool):
 var walk=moving.get("player" if player else index,false)
 var phase=int(clock*8)%4 if walk else 0
 var texture=cartoon["player_%s_%d" % [directions.get("player","down"),phase]] if player else cartoon["bot_%d_walk_%d" % [posmod(c.model.rooms[index].owner-1,5),phase]]
 var bob=sin(clock*2)*0.4 if not walk else 0.0
 sprite(c,"shadow",OFFSET+pos+Vector2(0,12),Vector2(35,18))
 c.draw_texture_rect(texture,Rect2(OFFSET+pos+Vector2(-18,-40+bob),Vector2(36,52)),false)
 if not player: text(c,c.model.rooms[index].survivor_name(),OFFSET+pos+Vector2(-17,-44),10,Color("E2D9C8"))

func hunter(c,h):
 if h.transformed:
  boss_presentation.draw(c,h,hunter_clock,death_age)
  return
 var name="hunter_move" if int(hunter_clock*4)%2 else "hunter_idle"
 if h.target_time<0.4 and h.target>=0: name="hunter_target"
 if h.state==HunterState.State.ATTACK and h.cooldown>h.interval-0.32:
  name="hunter_target" if h.target<3 else "hunter_attack"
 if h.hit_flash>0: name="hunter_hurt"
 var alpha=1.0
 if attack_pose>0:name="hunter_attack"
 if h.state==HunterState.State.DEAD:
  name="hunter_death"
  alpha=maxf(0,1-death_age/1.2)
 var p=OFFSET+h.position+Vector2(0,-18+sin(hunter_clock*3)*2)
 c.draw_circle(p+Vector2(0,13),25+min(h.level,6)*2,Color(0.65,0.55,0.92,0.035*alpha))
 sprite(c,"shadow",OFFSET+h.position+Vector2(0,14),Vector2(59,27),Color(1,1,1,alpha))
 c.draw_texture_rect(cartoon[name],Rect2(p-Vector2(33,42),Vector2(66,84)),false,Color(1,1,1,alpha))

func menu_scene(c):
 # A furnished moonlit vignette, not the old abstract grid backdrop.
 var r = Rect2(680,170,440,515)
 c.draw_style_box(frame(Color("263b49"),Color("607D8B"),22),r.grow(17))
 c.draw_texture_rect(textures.floor_wood,r,false,Color("d6c8b5"))
 sprite(c,"window",Vector2(905,186),Vector2(174,112))
 sprite(c,"cabinet",Vector2(1060,345),Vector2(119,153))
 sprite(c,"bed_upgraded",Vector2(826,451),Vector2(196,275))
 sprite(c,"survivor_sleep",Vector2(825,421),Vector2(86,122))
 sprite(c,"plant",Vector2(1069,586),Vector2(93,124))
 sprite(c,"warm_glow",Vector2(702,341),Vector2(330,380))
 sprite(c,"lantern",Vector2(710,360),Vector2(74,138))
 sprite(c,"hunter_idle",Vector2(1132,170+sin(clock)*8),Vector2(135,151),Color(0.8,0.9,1,0.42))

func cartoon_room(c,room: RoomState,owned: bool):
 var r=Rect2(OFFSET+room.bounds().position,room.bounds().size)
 c.draw_style_box(frame(Color("152635"),Color("172B3A"),8),r.grow(7))
 c.draw_texture_rect(cartoon["floor_%d" % room.index],r,false)
 var wall=frame(Color("607D8B"),Color("263746"),5)
 wall.set_border_width_all(3)
 c.draw_style_box(wall,Rect2(r.position-Vector2(7,10),Vector2(284,45)))
 for x in [r.position.x-7,r.end.x]: c.draw_style_box(wall,Rect2(Vector2(x,r.position.y+10),Vector2(7,210)))
 c.draw_line(Vector2(r.position.x,r.end.y),r.end,Color("263746"),5)
 c.draw_line(r.position-Vector2(5,9),r.position+Vector2(275,-9),Color("A6B9C1"),3)
 if room.index==3: c.draw_texture_rect(cartoon.rug,Rect2(OFFSET+room.bed_position()-Vector2(44,63),Vector2(88,126)),false)
 c.draw_texture_rect(cartoon["bed_%d" % (room.bed_level+1)],Rect2(OFFSET+room.bed_position()-Vector2(33,46),Vector2(66,92)),false)
 var decor=["desk","desk","cabinet","cabinet","bookshelf","utility"][room.index]
 c.draw_texture_rect(cartoon[decor],Rect2(OFFSET+room.cabinet_position()-Vector2(23,27),Vector2(46,54)),false)
 c.draw_texture_rect(cartoon.plant,Rect2(OFFSET+room.plant_position()-Vector2(15,19),Vector2(30,38)),false)
 if room.index!=5: c.draw_texture_rect(cartoon.window,Rect2(Vector2(r.position.x+120,r.position.y-5),Vector2(47,40)),false)
 if room.index in [0,1]:
  c.draw_texture_rect(cartoon.cabinet if room.index==0 else cartoon.bookshelf,Rect2(r.position+Vector2(175,3),Vector2(28,34)),false)
  c.draw_texture_rect(cartoon.poster,Rect2(r.position+Vector2(5,115),Vector2(26,35)),false)
 elif room.index==2:
  c.draw_texture_rect(cartoon.old_poster,Rect2(r.position+Vector2(5,114),Vector2(26,35)),false)
  c.draw_texture_rect(cartoon.books,Rect2(r.position+Vector2(45,123),Vector2(35,28)),false)
  c.draw_texture_rect(cartoon.clothes,Rect2(r.position+Vector2(46,170),Vector2(37,33)),false)
 elif room.index==3:
  c.draw_texture_rect(cartoon.lamp,Rect2(r.position+Vector2(3,126),Vector2(18,28)),false)
 elif room.index==4:
  c.draw_texture_rect(cartoon.old_poster,Rect2(r.position+Vector2(5,66),Vector2(28,38)),false,Color("A7A1B8"))
  c.draw_polyline(PackedVector2Array([r.position+Vector2(240,2),r.position+Vector2(231,13),r.position+Vector2(236,23)]),Color("435A68"),1)
 elif room.index==5:
  c.draw_texture_rect(cartoon.pipes,Rect2(r.position+Vector2(143,-1),Vector2(53,37)),false)
 sprite(c,"warm_glow",r.position+Vector2(30,40),Vector2(160,180),Color(1,1,1,0.45))
 c.draw_texture_rect(cartoon.lamp,Rect2(r.position+Vector2(8,15),Vector2(23,33)),false)
 var themes=["STANDARD","STUDENT","MESSY","COZY","OLD DORM","MAINTENANCE"]
 text(c,"%02d  %s" % [room.index+1,themes[room.index]],r.position+Vector2(15,14),9 if room.index==5 else 11,Color("E6EDF1"))
 if owned:
  c.draw_style_box(frame(Color.TRANSPARENT,Color("7BE3A1"),6),r.grow(9))
  text(c,"YOUR ROOM",r.position+Vector2(10,210 if room.index<3 else 71),11,Color("D4FFE1"))
 for tile in range(6):
  var p=OFFSET+room.tile_position(tile)
  if not room.buildings.has(tile):
   var pad=frame(Color("6F8991"),Color("425C6D"),7)
   pad.set_border_width_all(2)
   c.draw_style_box(pad,Rect2(p-Vector2(22,21),Vector2(44,42)))
   c.draw_line(p-Vector2(6,0),p+Vector2(6,0),Color("ACC6CD"),2)
   c.draw_line(p-Vector2(0,6),p+Vector2(0,6),Color("ACC6CD"),2)
  else:
   var building=room.buildings[tile]
   var name=building_key(building.kind,building.level)
   var size=Vector2(53,56)*(1+0.04*(building.level-1))
   if building.kind=="turret" and c.model.time>=c.model.preparation:
    var target=c.model.hunter.position-room.tile_position(tile)
    c.draw_set_transform(p-Vector2(0,6),clampf(atan2(target.y,absf(target.x)),-0.4,0.4),Vector2(-1,1) if target.x>0 else Vector2.ONE)
    c.draw_texture_rect(cartoon[name],Rect2(-size/2,size),false)
    c.draw_set_transform(Vector2.ZERO)
   else: c.draw_texture_rect(cartoon[name],Rect2(p-size/2-Vector2(0,6),size),false)
   if room.sleeping and room.alive:
    if building.kind=="generator":
     var hub=p+Vector2(12,-4)
     for spoke in range(3):
      var v=Vector2.from_angle(clock*5+spoke*TAU/3)*6
      c.draw_line(hub-v,hub+v,Color("4DDDF3"),1.5)
    elif building.kind=="enhancer":
     c.draw_arc(p+Vector2(0,-23),6+sin(clock*4)*2,PI,TAU,12,Color(0.3,0.87,0.95,0.5),1)
    elif building.kind=="heavy" and building.level>=3:
     var x=sin(clock*11)*2
     c.draw_polyline(PackedVector2Array([p+Vector2(-12,-21),p+Vector2(-4+x,-26),p+Vector2(3,-19),p+Vector2(13,-24)]),Color("4DDDF3"),1.5)
   for pip in range(building.level): c.draw_circle(p+Vector2(-7+pip*5,24),1.6,Color("7BE3A1"))
  if owned and c.selected_tile==tile and c.ui.context_open:
   c.draw_style_box(frame(Color.TRANSPARENT,Color("7BE3A1"),7),Rect2(p-Vector2(26,25),Vector2(52,50)))
 if c.pending_build!="" and owned:
  var valid=c.placement_reason()==""
  var p=OFFSET+c.preview_position
  var color=Color("7BE3A1") if valid else Color("F05467")
  c.draw_style_box(frame(Color(color,0.12),color,7),Rect2(p-Vector2(27,26),Vector2(54,52)))
  var name=c.pending_build+"_1" if c.pending_build in ["turret","heavy"] else c.pending_build
  c.draw_texture_rect(cartoon[name],Rect2(p-Vector2(27,34),Vector2(54,58)),false,Color(1,1,1,0.6))

func prestige(c,point: Vector2,level: int,kind="turret"):
 c.draw_texture_rect(prestige_art["%s_%d" % [kind,level]],Rect2(point-Vector2(32,39),Vector2(64,64)),false)
 var reduced=c.profile.settings.get("reduced_effects",false)
 var color=Color("E9B866") if level==10 else Color("A5C7ED")
 c.draw_arc(point,23,0,TAU,24,Color(color,.6),2)
 if level>=7:
  for side in [-1,1]:c.draw_line(point+Vector2(side*19,-13),point+Vector2(side*27,-27),color,3)
 if level==10:
  c.draw_colored_polygon(PackedVector2Array([point+Vector2(-16,-28),point+Vector2(-18,-42),point+Vector2(-7,-34),point+Vector2(0,-45),point+Vector2(7,-34),point+Vector2(18,-42),point+Vector2(16,-28)]),Color(color,.85))
  if not reduced:c.draw_arc(point,28,sin(clock)*.2,PI+sin(clock)*.2,24,Color(color,.4),2)
 c.draw_style_box(frame(Color("172338"),color,2),Rect2(point+Vector2(-22,14),Vector2(44,14)))
 text(c,"L%d%s" % [level," MAX" if level==10 else ""],point+Vector2(-18,24),8,color)
