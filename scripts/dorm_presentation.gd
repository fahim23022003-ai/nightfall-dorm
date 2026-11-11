extends RefCounted
## Illustration, animation and environment only. No economy/AI mutations.
const OFFSET = Vector2(145,40)
const ROOM_NAMES = ["WILLOW","WREN","ASTER","MOSS","CEDAR","FERN"]
var textures: Dictionary = {}
var clock = 0.0
var previous: Dictionary = {}
var moving: Dictionary = {}
var death_age = 0.0
var font = preload("res://assets/fonts/Interface.ttf")

func _init():
 for name in ["bed","bed_upgraded","cabinet","plant","lantern","door","door_reinforced","survivor_idle","survivor_walk_a","survivor_walk_b","survivor_sleep","bot_idle","bot_walk","hunter_idle","hunter_move","hunter_attack","hunter_hurt","hunter_death","turret","heavy","generator","repair","economy","enhancer","floor_wood","corridor","coin","power","foundation","window","shadow","warm_glow"]:
  textures[name] = load("res://assets/art/"+name+".png")

func update(delta: float, model):
 clock += delta
 moving.player = previous.has("player") and previous.player.distance_to(model.player_position)>0.05
 previous.player = model.player_position
 for room in model.rooms:
  moving[room.index] = previous.has(room.index) and previous[room.index].distance_to(room.resident_position)>0.05
  previous[room.index] = room.resident_position
 if model.hunter.state == HunterState.State.DEAD: death_age += delta
 else: death_age = 0

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
 c.draw_rect(Rect2(0,0,1280,900),Color("101c2b"))
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
 for room in m.rooms:
  room_scene(c,room,room.index==m.player_room)
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
  door_scene(c,room)
  if room.sleeping:
   var tint = Color.WHITE if room.owner==0 else Color("f5dfb5")
   sprite(c,"survivor_sleep",OFFSET+room.bed_position()+Vector2(0,-8+sin(clock*1.6+room.index)*0.5),Vector2(33,48),tint)
  elif room.owner>0 and room.alive:
   resident(c,room.resident_position,room.index,false)
  elif not room.alive:
   sprite(c,"warm_glow",OFFSET+room.bed_position(),Vector2(70,65),Color(0.6,0.3,0.6,0.3))
 if (m.player()==null or not m.player().sleeping) and (m.player()==null or m.player().alive):
  resident(c,m.player_position,-1,true)
 if m.hunter.state != HunterState.State.DORMANT:
  hunter(c,m.hunter)
 for room in m.rooms:
  for tile in room.buildings:
   var b = room.buildings[tile]
   if b.kind in ["turret","heavy"] and b.flash>0:
    var from = OFFSET+room.tile_position(tile)+Vector2(0,-12)
    var to = OFFSET+m.hunter.position+Vector2(0,-12)
    var color = Color("b2f6d6") if b.kind=="turret" else Color("d5b4ff")
    c.draw_line(from,to,Color(color,0.18),8)
    c.draw_line(from,to,color,2)
    sprite(c,"warm_glow",from,Vector2(35,35),color)
 for f in c.floating:
  text(c,f.text,OFFSET+f.position,14,Color(0.98,0.84,0.51,f.life))

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
 c.draw_texture_rect(textures.floor_wood,Rect2(p-Vector2(30,10),Vector2(60,56)),false)
 sprite(c,"shadow",p+Vector2(0,13),Vector2(83,39))
 if room.door_hp>0:
  var tint = Color(1.6,1.25,1.2) if room.damage_flash>0 else Color.WHITE
  if room.closed:
   sprite(c,"door_reinforced" if room.door_level>=2 else "door",p+Vector2(0,-10),Vector2(73,61),tint)
  else:
   sprite(c,"door",p+Vector2(-31,-10),Vector2(40,50),Color("a1aa9b"),-0.95)
  if room.door_hp < room.max_hp()*0.55:
   c.draw_polyline(PackedVector2Array([p+Vector2(-8,-29),p+Vector2(1,-16),p+Vector2(-4,-5),p+Vector2(10,5)]),Color("382432"),2)
 else:
  for i in range(4):
   c.draw_line(p+Vector2(-25+i*14,-7),p+Vector2(-19+i*13,13),Color("88684e"),5)
 if room.owner>=0:
  var targeted=c.model.hunter.target==room.index and c.model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
  if room.index==c.model.player_room or targeted:
   var hp_box=Rect2(p+Vector2(43,-21),Vector2(79,17))
   c.draw_style_box(frame(Color("211e30"),Color("de8b79") if targeted else Color("d8bc89"),4),hp_box)
   text(c,"%d/%d" % [room.door_hp,room.max_hp()],hp_box.position+Vector2(6,12),10)
   bar(c,p+Vector2(46,0),73,room.door_hp/room.max_hp())
   if targeted:
    c.draw_arc(p+Vector2(0,-9),39,0,TAU,40,Color(0.95,0.61,0.48,0.4+sin(clock*6)*0.2),2)
  else:
   bar(c,p+Vector2(-31,28 if room.index<3 else -42),62,room.door_hp/room.max_hp())

func resident(c, pos: Vector2, index: int, player: bool):
 var walk = moving.get("player" if player else index,false)
 var name = "survivor_idle" if player or index%2==0 else "bot_idle"
 if walk:
  name = ("survivor_walk_a" if int(clock*8)%2==0 else "survivor_walk_b") if player or index%2==0 else ("bot_walk" if int(clock*8)%2==0 else "bot_idle")
 var tint = [Color("c7e0da"),Color("ffdfaa"),Color("d8ccf2"),Color("cfdda8"),Color("e9bec9"),Color.WHITE][posmod(index,6)] if not player else Color.WHITE
 var bob = sin(clock*(9 if walk else 2)+index)*(1.5 if walk else 0.6)
 sprite(c,"shadow",OFFSET+pos+Vector2(0,14),Vector2(36,21))
 sprite(c,name,OFFSET+pos+Vector2(0,-13+bob),Vector2(34,51),tint)

func hunter(c, h):
 var name = "hunter_move" if int(clock*4)%2 else "hunter_idle"
 if h.state == HunterState.State.ATTACK and h.cooldown>h.interval-0.32: name = "hunter_attack"
 if h.hit_flash>0: name = "hunter_hurt"
 var alpha = 1.0
 if h.state == HunterState.State.DEAD:
  name = "hunter_death"
  alpha = maxf(0,1-death_age/1.2)
 var p = OFFSET+h.position+Vector2(0,-19+sin(clock*3)*3)
 sprite(c,"shadow",OFFSET+h.position+Vector2(0,15),Vector2(75,35),Color(1,1,1,alpha))
 sprite(c,name,p,Vector2(82,86),Color(1,1,1,alpha))
 if h.hit_flash>0:
  for i in range(5):
   var v = Vector2.from_angle(i*TAU/5+clock)*26
   c.draw_line(p+v,p+v*1.2,Color("c2f9df"),2)

func menu_scene(c):
 # A furnished moonlit vignette, not the old abstract grid backdrop.
 var r = Rect2(680,170,440,515)
 c.draw_style_box(frame(Color("263b49"),Color("b49772"),22),r.grow(17))
 c.draw_texture_rect(textures.floor_wood,r,false,Color("d6c8b5"))
 sprite(c,"window",Vector2(905,186),Vector2(174,112))
 sprite(c,"cabinet",Vector2(1060,345),Vector2(119,153))
 sprite(c,"bed_upgraded",Vector2(826,451),Vector2(196,275))
 sprite(c,"survivor_sleep",Vector2(825,421),Vector2(86,122))
 sprite(c,"plant",Vector2(1069,586),Vector2(93,124))
 sprite(c,"warm_glow",Vector2(702,341),Vector2(330,380))
 sprite(c,"lantern",Vector2(710,360),Vector2(74,138))
 sprite(c,"hunter_idle",Vector2(1132,170+sin(clock)*8),Vector2(135,151),Color(0.8,0.9,1,0.42))
