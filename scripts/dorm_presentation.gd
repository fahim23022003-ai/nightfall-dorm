extends RefCounted
## Illustration, animation and environment only. No economy/AI mutations.
const OFFSET = Vector2(145,40)
const ROOM_NAMES = ["WILLOW","WREN","ASTER","MOSS","CEDAR","FERN"]
var nightmare_visual=preload("res://scripts/nightmare_presentation.gd").new()
var building_visual=preload("res://scripts/building_evolution_visual.gd").new()
var hunter_art={}
var textures: Dictionary = {}
var cartoon: Dictionary = {}
var prestige_art: Dictionary={}
var all_rooms=true
var ally_group: Array=[]
var ally_pending: Array=[]
var ally_pending_since=0.0
var item_presentation=preload("res://scripts/item_presentation.gd").new()
var wrath_presentation=preload("res://scripts/wrath_presentation.gd").new()
var boss_presentation=preload("res://scripts/boss_presentation.gd").new()
var identity=preload("res://scripts/visual_presence.gd").new()
var menu_art=preload("res://assets/visual_identity/menu_facade.svg")
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
 for element in ["fire","ice","electric","earth"]:hunter_art["element_"+element]=load("res://assets/hunters/element_"+element+".svg")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for state in ["idle","walk","attack","hurt","defend","special","death"]:hunter_art[kind+"_"+state]=load("res://assets/hunters/"+kind+"_"+state+".svg")
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
 for kind in DefenseEffects.SPECIAL+MagicDefense.KINDS:
  cartoon[kind]=load("res://assets/wrath/"+kind+".svg");textures[kind]=cartoon[kind]
 textures.door=cartoon.door_1
 textures.door_reinforced=cartoon.door_4
 textures.corridor=cartoon.corridor
 textures.floor_wood=cartoon.floor_0
 for name in ["hunter_idle","hunter_move","hunter_attack","hunter_hurt","hunter_death"]: textures[name]=cartoon[name]

func reset():
 ally_group.clear();ally_pending.clear();ally_pending_since=0.0
 wrath_presentation.reset()
 identity.reset();nightmare_visual.reset()
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
func new_encounter(model):
 nightmare_visual.reset()
 # Preserve room aftermath, corpse ages, build levels and bounded scars.
 identity.heading=Vector2.RIGHT;identity.velocity=Vector2.ZERO;identity.last_hunter=model.hunter.position
 identity.previous_threat=false;identity.relief=0;identity.elimination_hold=0;identity.tension="quiet";identity.intensity=0
 hunter_clock=0;death_age=0;attack_pose=0;visual_events.clear()

func update(delta: float, model):
 if model.time<last_model_time: reset()
 last_model_time=model.time
 var action_delta=maxf(0,delta-model.items.frozen_delta) if model.running else 0.0
 hunter_clock+=action_delta
 identity.update(delta,model)
 nightmare_visual.update(delta,model,identity)
 clock+=delta
 attack_pose=maxf(0,attack_pose-action_delta)
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
 if kind in ["level","prestige","repair"]:visual_events=visual_events.filter(func(e):return not (e.kind in (["level","prestige"] if kind!="repair" else ["repair"]) and e.position.distance_to(point)<1))
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

func visible_world_rect(c,margin=140.0) -> Rect2:
 var inverse=c.get_canvas_transform().affine_inverse()
 var viewport=c.get_viewport_rect()
 var a=inverse*viewport.position
 return Rect2(a,inverse*viewport.end-a).abs().grow(margin)

func render(c):
 c.draw_rect(Rect2(-3000,-3000,6000,6000),Color("11171E"))
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
 var visible=visible_world_rect(c)
 environment.reduced_effects=CinematicQuality.reduced_flash(c) or CinematicQuality.detail(c)==0
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
 nightmare_visual.atmosphere(c,clock)
 render_scars(c)
 for room in m.rooms:
  if not visible.intersects(Rect2(OFFSET+room.bounds().position,room.bounds().size)):continue
  if m.map_id!="legacy": map_presentation.render_door(c,self,room)
  else: door_scene(c,room)
  render_door_scars(c,room)
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
    # The room plaque and Team panel already identify sleeping residents.
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
 render_resident_labels(c)
 wrath_presentation.draw(c,clock)
 for shot in m.projectiles:
  var p=OFFSET+shot.position
  var actor=m.target_by_id(int(shot.target_id))
  var direction=((actor.position if actor!=null else shot.position+Vector2.RIGHT)-shot.position).normalized()
  var branch=str(shot.get("specialization",""))
  if branch!="":
   var tint={"precision":Color("E6C48D"),"suppression":Color("9EC7A4"),"focus":Color("C1A6DF"),"storm":Color("83DFDA")}.get(branch,Catalog.BUILDINGS[shot.kind].color)
   c.draw_line(p-direction*(24 if branch=="precision" else 13),p,tint,4 if branch=="precision" else 2)
   if branch=="storm":c.draw_polyline(PackedVector2Array([p-direction*17,p-direction*8+Vector2(0,5),p]),tint,2)
  if not c.profile.settings.reduced_effects:
   c.draw_line(p-direction*15,p,Color(.45,.65,.72,.16),6)
  if shot.level>=7:
   c.draw_line(p-direction*18,p,Color("F3CB78") if shot.level==10 else Color("B2A3FA"),3)
  if shot.kind in ["flame","frost","shock"]:
   var tint=Catalog.BUILDINGS[shot.kind].color
   c.draw_line(p-direction*20,p,tint,4 if shot.kind=="shock" else 3)
   c.draw_circle(p,4,tint)
   if shot.kind=="frost":
    c.draw_line(p+Vector2(-4,-5),p+Vector2(4,5),Color("E0F8FF"),1.5)
    c.draw_line(p+Vector2(4,-5),p+Vector2(-4,5),Color("E0F8FF"),1.5)
  elif shot.kind=="heavy":
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
   var reduced=c.profile.settings.reduced_effects
   var lift=0.0 if reduced else (1-fraction)*12
   c.draw_arc(p,24+(0 if reduced else (1-fraction)*14),0,TAU,32,Color(.92,.77,.47,fraction),2.5)
   for i in range(4 if c.profile.settings.reduced_effects else 8):
    var v=Vector2.from_angle(i*TAU/(4 if c.profile.settings.reduced_effects else 8));var at=p+v*(10+(1-fraction)*32)
    c.draw_rect(Rect2(at,Vector2(3,5)),Color(1,.82,.5,fraction))
   var value="LEVEL 10 · PRESTIGE" if e.kind=="prestige" else "UPGRADED"
   var at=p+Vector2(-36,-38-lift)
   c.draw_string_outline(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color(.06,.08,.1,fraction))
   text(c,value,at,11,Color(1,.88,.6,fraction))
  else:
   var color=Color("A8C9AE") if e.kind=="repair" else Color("C8AA79")
   if e.kind=="impact":c.draw_arc(p,5+(1-fraction)*13,0,TAU,20,Color(color,fraction*.65),1.5)
   for i in range(3 if c.profile.settings.reduced_effects else 6):
    var v=Vector2.from_angle(i*TAU/6)*(8+(1-fraction)*15)
    c.draw_line(p+v,p+v*1.3,Color(color,fraction),2)
 for room in m.rooms:
  var bed_badge_offset=Vector2(40,-17) if m.run_kind=="endless" and m.expansion.initialized and not m.expansion.legacy else Vector2(0,34)
  if room.bed_level>=5:support_prestige(c,OFFSET+room.bed_position()+bed_badge_offset,room.bed_level+1,room.bed_branch)
  if room.door_level>=5 and room.door_hp>0:support_prestige(c,OFFSET+room.door_position()+Vector2(0,-58),room.door_level+1,room.door_branch)
  for tile in room.buildings:
   var b=room.buildings[tile]
   if b.level>=5:
    var selected=room.index==m.player_room and c.selected_tile==tile and c.ui.context_open and c.watched_room<0
    if b.kind in ["turret","heavy"]:prestige(c,OFFSET+room.tile_position(tile),b.level,b.kind,selected)
    else:support_prestige(c,OFFSET+room.tile_position(tile),b.level,b.get("specialization",""),selected,m.map_id=="legacy")
 if m.run_kind=="endless" and m.endless.omen.active in ["blood","blackout"]:
  var tint=Color(.35,.01,.04,.045) if m.endless.omen.active=="blood" else Color(.01,.01,.07,.12)
  if c.profile.settings.reduced_effects:tint.a*=.35
  c.draw_rect(visible_world_rect(c,0),tint)
 nightmare_visual.effects(c,clock);nightmare_visual.omens(c,clock)
 if c.construction!=null:c.construction.draw_range(c);c.construction.draw_preview(c)
 if c.model.map_id!="legacy":
  for room in m.rooms:map_presentation.render_door_status(c,self,room)
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
 building_visual.draw(c,self,"bed",room.bed_level+1,bed,room.bed_branch,1.0 if room.sleeping else 0.0,Vector2.ZERO,clock)
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
   building_visual.draw(c,self,"door",room.door_level+1,p,room.door_branch,room.damage_flash,Vector2.ZERO,clock)
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
   text(c,"%d/%d" % [roundi(room.door_hp),roundi(room.max_hp())],hp_box.position+Vector2(6,12),10)
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
 # Names are laid out together so clustered arrivals cannot overprint each other.

func hunter(c,h):
 if h.transformed:
  boss_presentation.draw(c,h,hunter_clock,death_age,identity.heading,c.profile.settings.get("reduced_effects",false))
  return
 if h.archetype in StrategyCatalog.ARCHETYPES:
  nightmare_visual.hunter(c,h,hunter_clock,death_age,identity);return
 var name="hunter_move" if int(hunter_clock*4)%2 else "hunter_idle"
 if h.target_time<0.4 and h.target>=0: name="hunter_target"
 if h.state==HunterState.State.ATTACK and h.cooldown>h.interval-0.32:
  name="hunter_target" if identity.heading.y<-.2 else "hunter_attack"
 if h.hit_flash>0: name="hunter_hurt"
 var alpha=1.0
 var archetype=h.archetype
 var shape=Vector2(1.13,1.04) if archetype=="crusher" else Vector2(.9,1.08) if archetype=="stalker" else Vector2(1.03,.94) if archetype=="ravager" else Vector2.ONE
 var tint=Color("C9B5A0") if archetype=="crusher" else Color("B8B0D6") if archetype=="stalker" else Color("D3AAA3") if archetype=="ravager" else Color(.83,.88,.92)
 if archetype=="stalker" and h.state in [HunterState.State.MOVE,HunterState.State.SEEK] and h.position.distance_to(c.model.player_position)>300:alpha=.68
 if h.conceal_remaining>0:alpha=.35
 if attack_pose>0:name="hunter_attack"
 if h.state==HunterState.State.DEAD:
  name="hunter_death"
  alpha=maxf(0,1-death_age/1.2)
 var p=OFFSET+h.position+Vector2(0,-18+sin(hunter_clock*3)*2)
 var affinity=DamageRules.affinity(archetype)
 if affinity!="neutral":c.draw_texture_rect(hunter_art["element_"+affinity],Rect2(p+Vector2(31,-64),Vector2(18,18)),false)
 c.draw_circle(p+Vector2(0,13),25+min(h.level,6)*2,Color(0.65,0.55,0.92,0.035*alpha))
 sprite(c,"shadow",OFFSET+h.position+Vector2(0,14),Vector2(59,27),Color(1,1,1,alpha))
 var facing=-1.0 if identity.heading.x<-.15 else 1.0
 var lean=clampf(identity.velocity.x/300,-.12,.12)
 if h.state==HunterState.State.ATTACK:lean=identity.heading.x*.08
 if h.charged_ready:lean-=identity.heading.x*clampf(1-h.windup_remaining/maxf(.01,RankCatalog.pressure(h.difficulty).windup),0,1)*.12
 if h.archetype_primed:
  name="hunter_target";lean-=identity.heading.x*.18
  c.draw_arc(p+Vector2(0,10),38,-PI*.9,PI*.1,24,Color(tint,.75),2)
 c.draw_set_transform(p,lean,Vector2(facing,1)*shape)
 var pose="death" if h.state==HunterState.State.DEAD else "hurt" if h.hit_flash>0 else "special" if h.arcane.action!="" or h.tactical_action!="" or h.archetype_primed else "defend" if h.suppression_remaining>0 else "attack" if name=="hunter_attack" else "walk" if identity.velocity.length()>1 and int(hunter_clock*7)%2 else "idle"
 var art=hunter_art.get(archetype+"_"+pose,cartoon[name])
 c.draw_texture_rect(art,Rect2(Vector2(-39,-62),Vector2(78,100)),false,Color(1,1,1,alpha))
 if archetype=="crusher":
  for side in [-1,1]:c.draw_style_box(frame(Color("414444"),Color("A2987E"),2),Rect2(Vector2(side*27-9,-19),Vector2(18,21)))
 elif archetype=="stalker":
  c.draw_line(Vector2(-16,-25),Vector2(16,-25),Color("C4B3DE"),2)
 elif archetype=="ravager":
  for side in [-1,1]:
   for i in range(3):c.draw_line(Vector2(side*(26+i*3),5),Vector2(side*(30+i*3),18),Color("D6A898"),2)
 c.draw_set_transform(Vector2.ZERO)
 if archetype!="" and (h.archetype_primed or c.full_map):text(c,StrategyCatalog.ARCHETYPES[archetype].name,p+Vector2(-42,-57),10,tint)
 if h.state in [HunterState.State.MOVE,HunterState.State.EXIT] and identity.velocity.length()>1 and not c.profile.settings.reduced_effects:
  var trailing=-identity.heading
  for i in range(3):c.draw_line(p+trailing*(15+i*7)+Vector2(0,15),p+trailing*(24+i*7)+Vector2(0,17),Color(.4,.35,.6,.18-i*.035),2)
 # Attack contact and wind-up read separately from hovering locomotion.
 if h.state==HunterState.State.ATTACK and h.cooldown<h.interval*.22:
  var claw=p+identity.heading*25
  for i in range(3):c.draw_line(claw+Vector2(-6+i*6,-6),claw+Vector2(-11+i*6,8),Color(.8,.54,.58,.55),1.5)

func menu_scene(c):
 c.draw_texture_rect(menu_art,Rect2(0,0,1280,720),false)
 # Slow, bounded moving haze and distant presence remain behind all interaction.
 for i in range(4 if not c.profile.settings.reduced_effects else 2):
  var q=Vector2(700+fmod(clock*10+i*170,650),360+i*65)
  var points=PackedVector2Array()
  for n in range(32):points.append(q+Vector2(cos(n*TAU/32)*220,sin(n*TAU/32)*28))
  c.draw_colored_polygon(points,Color(.55,.61,.61,.025))
 var q=Vector2(1115+sin(clock*.3)*8,370+sin(clock*1.5)*4)
 sprite(c,"hunter_idle",q,Vector2(94,120),Color(.5,.58,.65,.43))
 for side in [-1,1]:c.draw_circle(q+Vector2(side*7,-27),2,Color(.65,.22,.28,.7))
 c.draw_line(Vector2(72,143),Vector2(391,143),Color("7D6854"),1)
 for x in [72,391]:c.draw_colored_polygon(PackedVector2Array([Vector2(x,139),Vector2(x+4,143),Vector2(x,147),Vector2(x-4,143)]),Color("B69A6A"))

func render_door_scars(c,room):
 if not identity.scars.any(func(s):return s.kind=="door_damage" and s.room==room.index):return
 var q=OFFSET+room.door_position()
 var angle=PI/2 if absf(room.door_normal().x)>.5 else 0.0
 c.draw_set_transform(q,angle)
 for i in range(3):c.draw_line(Vector2(-14+i*10,-16),Vector2(-20+i*10,8),Color(.16,.09,.12,.75),1.8)
 c.draw_set_transform(Vector2.ZERO)

func render_scars(c):
 for scar in identity.scars:
  var q=OFFSET+scar.point
  if scar.kind=="door_damage":continue
  elif scar.kind=="door_break":
   for i in range(5):
    var point=q+Vector2(-24+i*12,12+(i%2)*6)
    c.draw_line(point,point+Vector2(8,-4),Color("7F6655"),3)
  elif scar.kind=="scorch":
   c.draw_circle(q,20,Color(.045,.04,.055,.65))
   for i in range(5):c.draw_line(q+Vector2.from_angle(i*TAU/5)*8,q+Vector2.from_angle(i*TAU/5+.2)*24,Color(.1,.07,.1,.45),2)
  elif scar.kind=="elimination":
   c.draw_arc(q+Vector2(13,17),25,.2,2.8,16,Color(.1,.08,.13,.35),4)

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
 building_visual.draw(c,self,"bed",room.bed_level+1,OFFSET+room.bed_position(),room.bed_branch,1.0 if room.sleeping else 0.0,Vector2.ZERO,clock)
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
   building_visual.draw(c,self,building.kind,building.level,p,building.get("specialization",""),building.flash,c.model.hunter.position-room.tile_position(tile),clock)
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
   selection_outline(c,p)
 if c.pending_build!="" and owned:
  var valid=c.placement_reason()==""
  var p=OFFSET+c.preview_position
  var color=Color("7BE3A1") if valid else Color("F05467")
  c.draw_style_box(frame(Color(color,0.12),color,7),Rect2(p-Vector2(27,26),Vector2(54,52)))
  var name=c.pending_build+"_1" if c.pending_build in ["turret","heavy"] else c.pending_build
  c.draw_texture_rect(cartoon[name],Rect2(p-Vector2(27,34),Vector2(54,58)),false,Color(1,1,1,0.6))

func prestige(c,point: Vector2,level: int,_kind="turret",detailed=false):
 prestige_badge(c,point,level,detailed)

func support_prestige(c,point: Vector2,level: int,_branch: String="",detailed=false,_show_branch=true):
 prestige_badge(c,point,level,detailed)

func prestige_badge(c,point: Vector2,level: int,detailed: bool):
 var value="L%d%s" % [level," MAX" if level==10 else ""] if detailed else str(level)
 var color=Color("E9B866") if level==10 else Color("B6D5D2")
 var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x+12
 var badge=Rect2(point+Vector2(-width/2,16),Vector2(width,12))
 # Door HP outranks a prestige badge in tightly packed expanded rooms.
 for room in c.model.rooms:
  if room.owner<0:continue
  var normal=room.door_normal()
  var hp=OFFSET+room.door_position()+(Vector2(40,-25) if absf(normal.x)<.5 else Vector2(-35,50))
  if badge.intersects(Rect2(hp+Vector2(-4,-20),Vector2(80,46))):badge.position.y-=18
 c.draw_style_box(frame(Color("101A24"),color if detailed else Color("76867C"),3),badge)
 text(c,value,badge.position+Vector2(6,9),8,color)

func selection_outline(c,point: Vector2):
 var color=Color("E2C68B")
 c.draw_style_box(frame(Color(.85,.72,.43,.045),Color(.88,.76,.52,.75),5),Rect2(point-Vector2(26,25),Vector2(52,50)))
 for x in [-1,1]:
  for y in [-1,1]:
   var corner=point+Vector2(x*27,y*26)
   c.draw_line(corner,corner-Vector2(x*9,0),color,2.5)
   c.draw_line(corner,corner-Vector2(0,y*9),color,2.5)


func resident_label_layout(c) -> Array:
 # At most five teammate labels; stable identity lanes, no random offsets,
 # animation, timers or unbounded search. Full names remain in Team / plaques.
 var m=c.model
 var candidates=[]
 var blockers=[]
 var visible=visible_world_rect(c,0)
 for room in m.rooms:
  if room.owner>=0:
   var door=OFFSET+room.door_position()
   var normal=room.door_normal()
   var hp_offset=Vector2(40,-25) if absf(normal.x)<.5 else Vector2(-35,50)
   blockers.append(Rect2(door+hp_offset+Vector2(-8,-25),Vector2(105,80)))
  if room.owner>0 and room.alive and not room.sleeping:
   var at=OFFSET+room.resident_position
   if visible.has_point(at):
    var priority=0 if room.index==c.watched_room else 1 if room.index==m.hunter.target else 2
    candidates.append({"index":room.index,"point":at,"name":"%02d · %s" % [room.index+1,room.survivor_name()],"priority":priority})
 if m.hunter.state!=HunterState.State.DORMANT:
  blockers.append(Rect2(OFFSET+m.hunter.position+Vector2(-45,-90),Vector2(90,120)))
 if c.get("horror")!=null:
  for number in c.horror.damage_numbers:blockers.append(c.horror.damage_number_geometry(c,number).rect.grow(4))
 candidates.sort_custom(func(a,b):return a.priority<b.priority if a.priority!=b.priority else a.index<b.index)
 candidates=adaptive_allies(candidates)
 var canvas=c.get_canvas_transform()
 var viewport=c.get_viewport_rect().size
 var safe=Rect2(12,150,viewport.x-24,viewport.y-225)
 var labels=[]
 for actor in candidates:
  var width=font.get_string_size(actor.name,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+12
  var lane=0 if actor.get("group",false) else posmod(actor.index-1,5)
  for side in [30.0,105.0,180.0,-width-30.0,-width-105.0,-width-180.0]:
   var rect=Rect2(actor.point+Vector2(side,-47-lane*23),Vector2(width,16))
   var screen=Rect2(canvas*rect.position,rect.size*canvas.get_scale())
   if not safe.encloses(screen):continue
   if c.ui.context_open and screen.end.y>430:continue
   if c.ui.teammates.expanded and screen.end.x>915:continue
   if blockers.any(func(block):return rect.grow(3).intersects(block)):continue
   labels.append({"index":actor.index,"name":actor.name,"rect":rect,"point":actor.point,"priority":actor.priority,"group":actor.get("group",false)})
   blockers.append(rect.grow(3))
   break
 return labels

func render_resident_labels(c):
 for label in resident_label_layout(c):
  var rect=label.rect
  var anchor=Vector2(clampf(label.point.x,rect.position.x,rect.end.x),rect.end.y)
  c.draw_line(label.point+Vector2(0,-38),anchor,Color(.7,.73,.7,.35),1)
  c.draw_style_box(frame(Color("17212B"),Color("9C8A67") if label.priority<2 else Color("4D5B62"),3),rect)
  text(c,label.name,rect.position+Vector2(6,11),10,Color("E8DEC9"))


func adaptive_allies(candidates: Array) -> Array:
 # Only five teammates. Separate enter/leave radii plus time holds prevent
 # mode chatter; identity lanes are unchanged outside genuinely dense groups.
 var eligible=candidates.filter(func(a):return a.priority>=2)
 eligible.sort_custom(func(a,b):return a.index<b.index)
 var proposed=[]
 for anchor in eligible:
  var radius=96.0 if ally_group.has(anchor.index) else 58.0
  var nearby=eligible.filter(func(a):return a.point.distance_to(anchor.point)<=radius)
  var needed=2 if ally_group.has(anchor.index) else 3
  if nearby.size()>=needed:
   proposed=nearby.map(func(a):return a.index);break
 # Long identity lanes in a two-actor cluster also warrant a compact label.
 if proposed.is_empty():
  for anchor in eligible:
   var nearby=eligible.filter(func(a):return a.point.distance_to(anchor.point)<42)
   if nearby.size()==2 and nearby.any(func(a):return posmod(a.index-1,5)>=3):
    proposed=nearby.map(func(a):return a.index);break
 if proposed!=ally_pending:ally_pending=proposed;ally_pending_since=clock
 if clock-ally_pending_since>=(.8 if proposed.is_empty() else .35):ally_group=proposed.duplicate()
 var members=eligible.filter(func(a):return ally_group.has(a.index))
 if members.size()<2:return candidates
 var center=Vector2.ZERO
 for actor in members:center+=actor.point
 center/=members.size()
 var result=candidates.filter(func(a):return not members.any(func(b):return b.index==a.index))
 result.append({"index":members[0].index,"point":center,"name":"ALLIES ×%d" % members.size(),"priority":2,"group":true})
 return result
