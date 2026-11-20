extends RefCounted
# Cached original shaded machinery, compact on pads; full detail in inspection.
var art: Dictionary={}
const WEAPON_ART_DIR = "res://assets/visual_rebirth/buildings/"
const NEEDLE_CELL = 112
const ARC_CELL = 96
const WEAPON_BEARINGS = 12
const WEAPON_CANVAS_SIZE = 99.0
const WEAPON_UNIT = WEAPON_CANVAS_SIZE / 3.75
const ATLAS_BOUNDS = preload("res://scripts/rebirth_atlas_bounds.gd")
const MASTERWORK_DETAILS = "res://assets/visual_rebirth/buildings/masterwork_details.svg"
# Atlas cell and material grade for each finished housing. Details are drawn
# below each operating assembly so recoil and actual effect sockets stay clear.
const MASTERWORK = {
 "turret": [0,Color(.87,.97,1.09)],
 "heavy": [1,Color(1.12,.91,.91)],
 "generator": [2,Color(.91,1.04,1.11)],
 "repair": [3,Color(1.14,1.02,.86)],
 "economy": [4,Color(1.08,.96,1.14)],
 "enhancer": [5,Color(.88,1.00,1.13)],
 "flame": [6,Color(1.18,.87,.80)],
 "frost": [7,Color(.83,1.04,1.18)],
 "shock": [8,Color(1.08,1.02,.90)],
 "auto_repair": [9,Color(.91,1.10,.99)],
 "shield": [10,Color(.88,1.12,.91)],
 "decoy": [11,Color(1.10,.91,.99)],
 "barrier": [12,Color(.91,.94,1.16)],
 "plasma": [13,Color(1.08,.92,1.13)],
 "antenna": [14,Color(.83,1.12,1.05)],
}
var masterwork_details: Texture2D
const SUPPORT_BRANCHES = {
 "generator":["regulated","overcharge"],
 "repair":["sustain","conservation"],
 "economy":["dividend","capacitive"],
 "enhancer":["ballistic","coolant"],
 "shock":["capacitor_burst","rapid_discharge"],
 "auto_repair":["efficient_mending","emergency_protocol"],
 "shield":["aegis_burst","steady_veil"],
 "decoy":["force_lure","faint_echo"],
 "plasma":["reservoir","converter"],
}
const SUPPORT_CLOCK_RATES = {"generator":14.0, "repair":9.0, "economy":8.0, "enhancer":11.0, "auto_repair":12.0, "shield":8.0, "decoy":10.0, "plasma":9.0}
const STATIC_BRANCHES = {
 "bed":["lucid","conductor"],
 "door":["bulwark","renewal"],
 "barrier":["mirror","ward"],
 "antenna":["dome","pulse"],
}
const WEAPON_BRANCHES = {
 "turret":["precision","suppression"],
 "heavy":["focus","storm"],
 "flame":["searing","wildfire"],
 "frost":["deep_chill","rime_field"],
}
var rebirth_enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var rebirth_atlases: Dictionary = {}
const KINDS=["turret","heavy","generator","repair","economy","enhancer","flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna","bed","door"]
func _init():
 for kind in KINDS:
  for tier in range(4):art[kind+str(tier)]=load("res://assets/cinematic_buildings/%s_%d.svg" % [kind,tier])
func tier_for(level: int) -> int:return 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0
func draw(c,_p,kind: String,level: int,point: Vector2,branch: String="",activity: float=0,target: Vector2=Vector2.ZERO,clock: float=0,angle: float=0,render_scale: float=1.0,tint: Color=Color.WHITE):
 level=clampi(level,1,10)
 if STATIC_BRANCHES.has(kind) and load_rebirth_atlas(kind,""):
  var state := rebirth_state(level,branch,STATIC_BRANCHES[kind],6 if kind in ["bed","door"] else 5)
  draw_rebirth_base(c,kind,state,point,angle,render_scale,tint,level==10)
  return
 if support_rebirth_active(kind):
  draw_rebirth_support(c, kind, level, point, branch, activity, clock, angle, render_scale, tint)
  return
 if kind == "frost" and weapon_rebirth_active(kind):
  draw_rebirth_frost(c,level,point,branch,activity,angle,render_scale,tint)
  return
 if weapon_rebirth_active(kind):
  draw_rebirth_weapon(c, kind, level, point, branch, activity, target, angle, render_scale, tint)
  return
 var tier=tier_for(level);var core=art.get(kind+str(tier))
 if core==null:return
 var color=Catalog.BUILDINGS[kind].color if Catalog.BUILDINGS.has(kind) else Color("B5B4CD")
 var motion=clock if activity>0 and not CinematicQuality.reduced_motion(c) else 0.0
 var special=kind in ["bed","door"]
 # 46x52 pad footprint: no high-level geometry can spill onto adjacent cores.
 var size=Vector2(64,80) if special else Vector2(54,67.5)
 var pivot=Vector2(size.x*.5,size.y*.78)
 c.draw_set_transform(point,angle,Vector2.ONE*render_scale)
 c.draw_texture_rect(core,Rect2(-pivot,size),false,tint)
 # Within-tier structural additions make every purchased level physically distinct.
 var growth=level-([1,4,7,10][tier])
 for n in range(growth):
  var x=-16+n*10
  c.draw_style_box(_rib(color),Rect2(x,-8,7,12+n*2))
 if branch!="":
  # Exclusive branch geometry: paired radiators versus a reinforced central housing.
  var alternate=branch in ["suppression","storm","overcharge","conservation","capacitive","coolant","wildfire","rime_field","rapid_discharge","emergency_protocol","steady_veil","faint_echo","ward","converter","pulse","renewal","conductor"]
  if alternate:
   for side in [-1,1]:
    for n in range(3):c.draw_line(Vector2(side*17,-10+n*4),Vector2(side*21,-12+n*4),color,1.5)
  else:c.draw_rect(Rect2(-4,-17,8,12),Color(color,.7));c.draw_rect(Rect2(-4,-17,8,12),Color("B4C1C6"),false,1)
 if kind in ["turret","heavy","flame"]:
  var bearing=target.normalized() if target.length()>0 else Vector2.UP
  var at=Vector2(0,-11);var end=at+bearing*(14+level*.25-activity*2)
  c.draw_line(at,end,Color("172739"),5);c.draw_line(at-Vector2(1,1),end-Vector2(1,1),color,2)
  if activity>0:c.draw_circle(end,2.5+activity*2,Color(color,.8))
 elif kind=="generator" and activity>0:
  var at=Vector2(0,-4)
  for side in [-1,1]:
   var v=Vector2.from_angle(motion*2+side*PI/2)*6
   c.draw_line(at-v,at+v,Color("E7D6AD"),1.6)
 elif kind in ["repair","auto_repair"] and activity>0:
  for side in [-1,1]:
   var at=Vector2(side*13,-18-sin(motion*2+side)*2)
   c.draw_line(Vector2(side*16,0),at,Color("B4D3C5"),2);c.draw_circle(at,1.7,color)
 elif kind in ["shield","plasma","barrier","frost","shock","antenna"] and activity>0:
  c.draw_arc(Vector2(0,-15),9,motion*.6,motion*.6+PI*1.3,16,Color(color,.55),1.5)
 if level==10:
  # Role-colored inlaid lights replace identical crowns and giant gold rings.
  for side in [-1,1]:c.draw_circle(Vector2(side*16,5),1.5,color)
 c.draw_set_transform(Vector2.ZERO)
func load_rebirth_atlas(kind: String, moving_layer: String) -> bool:
 if not rebirth_enabled:
  return false
 if not rebirth_atlases.has(kind):
  var base_path := WEAPON_ART_DIR + kind + "/base.png"
  var moving_path := WEAPON_ART_DIR + kind + "/" + moving_layer + ".png"
  var textures := []
  if ResourceLoader.exists(base_path) and (moving_layer.is_empty() or ResourceLoader.exists(moving_path)):
   var base := load(base_path) as Texture2D
   if base != null:
    if moving_layer.is_empty():
     textures = [base]
    else:
     var moving := load(moving_path) as Texture2D
     if moving != null:textures = [base, moving]
  rebirth_atlases[kind] = textures
 return not rebirth_atlases[kind].is_empty()

func needle_rebirth_active() -> bool:
 return load_rebirth_atlas("turret", "launcher")

func arc_rebirth_active() -> bool:
 return load_rebirth_atlas("heavy", "launcher")

func support_rebirth_active(kind: String) -> bool:
 return SUPPORT_BRANCHES.has(kind) and load_rebirth_atlas(kind, "motion")

func support_activity(room, building: Dictionary, model = null) -> float:
 match building.kind:
  "repair":
   return 1.0 if room.repair_status(building).actual > 0.0 else 0.0
  "shock":
   return building.flash
  "auto_repair":
   var interval := 5.0 if building.get("specialization","") == "emergency_protocol" else 3.0
   return 1.0 if room.alive and building.cooldown > interval-.67 else 0.0
  "shield":
   var branch: String = building.get("specialization","")
   var duration := 2.0 if branch == "aegis_burst" else 4.0 if branch == "steady_veil" else 3.0
   return 1.0 if room.alive and room.barrier_hp > 0.0 and room.barrier_remaining > 0.0 and building.cooldown > 12.0-duration else 0.0
  "decoy":
   if model == null:return 0.0
   var lure = model.defenses
   return 1.0 if lure.lure_room == room.index and lure.lure_remaining > 0.0 and lure.lure_instance == building.get("instance_id",0) else 0.0
  "plasma":
   return 1.0 if (room.magic_state.stored > 0.0 and room.magic_state.storage_time > 0.0) and building == MagicDefense.best(room,"plasma") else 0.0
  "enhancer":
   if room.alive:
    for weapon in room.buildings.values():
     if weapon.kind in DefenseEffects.WEAPONS and weapon.flash > 0.0:
      return 1.0
   return 0.0
  _:
   return 1.0 if room.alive and room.sleeping and not room.production_paused else 0.0

func weapon_rebirth_active(kind: String) -> bool:
 return WEAPON_BRANCHES.has(kind) and load_rebirth_atlas(kind, "" if kind == "frost" else "launcher")

# Aim at the most recent real shot while the launcher is active. When a shot
# already landed, use its matching launch event without altering the model.
func weapon_target(model, room, tile: int, kind: String, activity: float) -> Vector2:
 var origin: Vector2 = room.tile_position(tile)
 if weapon_rebirth_active(kind) and activity > 0:
  for i in range(model.projectiles.size() - 1, -1, -1):
   var shot: Dictionary = model.projectiles[i]
   if shot.room != room.index or shot.get("building_id", -1) != tile:
    continue
   var actor = model.target_by_id(int(shot.target_id))
   return (actor.position if actor != null else shot.position) - origin
  for i in range(model.combat_events.size() - 1, -1, -1):
   var event: Dictionary = model.combat_events[i]
   if event.type != "launch" or event.kind != kind or event.room != room.index or event.position != origin:
    continue
   for impact_index in range(i + 1, model.combat_events.size()):
    var impact: Dictionary = model.combat_events[impact_index]
    if impact.type == "impact" and impact.projectile_id == event.projectile_id:
     return impact.position - origin
   var actor = model.target_by_id(int(event.target_id))
   if actor != null:
    return actor.position - origin
   break
 return model.hunter.position - origin

func weapon_heading(target: Vector2) -> int:
 if target.length_squared() <= 0.001:
  return 0
 var bearing := atan2(-target.y * sqrt(2.0), target.x)
 return posmod(roundi(bearing * WEAPON_BEARINGS / TAU), WEAPON_BEARINGS)

func weapon_projection(heading: int) -> Vector2:
 var yaw := heading * TAU / WEAPON_BEARINGS
 return Vector2(cos(yaw), -sin(yaw) / sqrt(2.0))

func needle_recoil(c, projected: Vector2, fire: float) -> Vector2:
 return Vector2.ZERO if CinematicQuality.reduced_motion(c) else projected.normalized() * (2.5 * fire)

func needle_muzzle(projected: Vector2, recoil: Vector2) -> Vector2:
 # Project the primary dart point (0.91, 0, 1.59) through the bake camera.
 return projected * (0.91 * WEAPON_UNIT) - Vector2(0, 1.59 * WEAPON_UNIT / sqrt(2.0)) - recoil

func arc_recoil(c, projected: Vector2, fire: float) -> Vector2:
 return Vector2.ZERO if CinematicQuality.reduced_motion(c) else projected.normalized() * (1.4 * fire)

func arc_muzzle(projected: Vector2, recoil: Vector2) -> Vector2:
 # Midpoint between the two baked electrode terminals.
 return projected * (0.68 * WEAPON_UNIT) - Vector2(0, 1.77 * WEAPON_UNIT / sqrt(2.0)) - recoil

func elemental_recoil(c, projected: Vector2, fire: float) -> Vector2:
 return Vector2.ZERO if CinematicQuality.reduced_motion(c) else projected.normalized() * fire

func elemental_muzzle(kind: String, projected: Vector2, recoil: Vector2) -> Vector2:
 var socket := Vector2(.68, 1.56) if kind == "flame" else Vector2(0.0, 1.46)
 return projected * (socket.x * WEAPON_UNIT) - Vector2(0, socket.y * WEAPON_UNIT / sqrt(2.0)) - recoil

func rebirth_state(level: int, branch: String, branches: Array, branch_level: int = 5) -> int:
 var state := level - 1
 if level >= branch_level:
  if branch == branches[0]:
   state = 10 + level - branch_level
  elif branch == branches[1]:
   state = 21 + level - 2 * branch_level
 return state

func draw_atlas_layer(c,kind: String,layer: int,destination: Rect2,column: int,row: int,cell: int,tint: Color):
 var source := Rect2(Vector2(column,row)*cell,Vector2.ONE*cell)
 if ATLAS_BOUNDS.LAYERS.has(kind):
  var trim: Rect2 = ATLAS_BOUNDS.LAYERS[kind][layer]
  var scale := destination.size / source.size
  destination = Rect2(destination.position+trim.position*scale,trim.size*scale)
  source = Rect2(source.position+trim.position,trim.size)
 c.draw_texture_rect_region(rebirth_atlases[kind][layer],destination,source,tint)

func draw_masterwork_detail(c, kind: String, tint: Color):
 if not MASTERWORK.has(kind):
  return
 if masterwork_details == null:
  masterwork_details = load(MASTERWORK_DETAILS) as Texture2D
 if masterwork_details == null:
  return
 var index: int = MASTERWORK[kind][0]
 var atlas_position := Vector2((index % 5) * 48, floori(index / 5.0) * 48)
 var area := Rect2(-19,-23,38,24)
 c.draw_texture_rect_region(masterwork_details,area,Rect2(atlas_position+Vector2(5,13),area.size),tint)

func masterwork_tint(kind: String, tint: Color, is_masterwork: bool) -> Color:
 return tint * MASTERWORK[kind][1] if is_masterwork and MASTERWORK.has(kind) else tint

func draw_rebirth_support(c, kind: String, level: int, point: Vector2, branch: String, activity: float, clock: float, angle: float, render_scale: float, tint: Color):
 var state := rebirth_state(level, branch, SUPPORT_BRANCHES[kind])
 var phase := 0
 if activity > 0.0 and not CinematicQuality.reduced_motion(c):
  phase = clampi(ceili(activity / .15 * 7.0),1,7) if kind == "shock" else posmod(floori(clock * SUPPORT_CLOCK_RATES[kind]), 8)
 var cell := 96
 var rect := Rect2(Vector2(-WEAPON_CANVAS_SIZE * 0.5, -WEAPON_CANVAS_SIZE * 0.5 - 0.87 * WEAPON_UNIT), Vector2.ONE * WEAPON_CANVAS_SIZE)
 c.draw_set_transform(point, angle, Vector2.ONE * render_scale)
 draw_atlas_layer(c,kind,0,rect,state%6,floori(state/6.0),cell,masterwork_tint(kind,tint,level==10))
 if level == 10:
  draw_masterwork_detail(c,kind,tint)
 draw_atlas_layer(c,kind,1,rect,phase,state,cell,tint)
 c.draw_set_transform(Vector2.ZERO)

func draw_rebirth_base(c,kind: String,state: int,point: Vector2,angle: float,render_scale: float,tint: Color,is_masterwork: bool = false):
 var rect := Rect2(Vector2(-WEAPON_CANVAS_SIZE * .5,-WEAPON_CANVAS_SIZE * .5-.87*WEAPON_UNIT),Vector2.ONE*WEAPON_CANVAS_SIZE)
 c.draw_set_transform(point,angle,Vector2.ONE*render_scale)
 draw_atlas_layer(c,kind,0,rect,state%6,floori(state/6.0),ARC_CELL,masterwork_tint(kind,tint,is_masterwork))
 if is_masterwork:
  draw_masterwork_detail(c,kind,tint)
 c.draw_set_transform(Vector2.ZERO)

func draw_rebirth_frost(c, level: int, point: Vector2, branch: String, activity: float, angle: float, render_scale: float, tint: Color):
 var state := rebirth_state(level,branch,WEAPON_BRANCHES["frost"])
 draw_rebirth_base(c,"frost",state,point,angle,render_scale,tint,level==10)
 if activity > 0.0:
  c.draw_set_transform(point,angle,Vector2.ONE*render_scale)
  draw_elemental_discharge(c,"frost",elemental_muzzle("frost",Vector2.ZERO,Vector2.ZERO),Vector2.UP,clampf(activity/.15,0,1))
  c.draw_set_transform(Vector2.ZERO)

func draw_rebirth_weapon(c, kind: String, level: int, point: Vector2, branch: String, activity: float, target: Vector2, angle: float, render_scale: float, tint: Color):
 var state := rebirth_state(level, branch, WEAPON_BRANCHES[kind])
 var heading := weapon_heading(target)
 var projected := weapon_projection(heading)
 var fire := clampf(activity / 0.15, 0.0, 1.0)
 var recoil := needle_recoil(c, projected, fire) if kind == "turret" else arc_recoil(c, projected, fire) if kind == "heavy" else elemental_recoil(c, projected, fire)
 var cell := NEEDLE_CELL if kind == "turret" else ARC_CELL
 var rect := Rect2(Vector2(-WEAPON_CANVAS_SIZE * 0.5, -WEAPON_CANVAS_SIZE * 0.5 - 0.87 * WEAPON_UNIT), Vector2.ONE * WEAPON_CANVAS_SIZE)
 c.draw_set_transform(point, angle, Vector2.ONE * render_scale)
 draw_atlas_layer(c,kind,0,rect,state%6,floori(state/6.0),cell,masterwork_tint(kind,tint,level==10))
 if level == 10:
  draw_masterwork_detail(c,kind,tint)
 draw_atlas_layer(c,kind,1,Rect2(rect.position-recoil,rect.size),heading,state,cell,tint)
 if fire > 0:
  if kind == "heavy":
   draw_arc_discharge(c, heading, arc_muzzle(projected, recoil), branch, fire)
  elif kind == "turret":
   var muzzle := needle_muzzle(projected, recoil)
   var direction := projected.normalized()
   var side := direction.orthogonal()
   var alpha := fire * 0.85
   if CinematicQuality.reduced_flash(c):
    c.draw_circle(muzzle, 1.6, Color(0.63, 0.86, 0.88, alpha))
   else:
    c.draw_colored_polygon(PackedVector2Array([muzzle - side * 2.0, muzzle + direction * (3.0 + 5.0 * fire), muzzle + side * 2.0]), Color(0.69, 0.93, 0.91, alpha))
  else:
   draw_elemental_discharge(c, kind, elemental_muzzle(kind, projected, recoil), projected.normalized(), fire)
 c.draw_set_transform(Vector2.ZERO)

func draw_elemental_discharge(c, kind: String, muzzle: Vector2, direction: Vector2, fire: float):
 var tint := Color("F39B60") if kind == "flame" else Color("A5D7ED")
 tint.a = fire * .85
 if CinematicQuality.reduced_flash(c):
  c.draw_circle(muzzle, 1.5, tint)
  return
 var across := direction.orthogonal()
 c.draw_colored_polygon(PackedVector2Array([muzzle - across * 2.1, muzzle + direction * (4.0 + fire * 5.0), muzzle + across * 2.1]), tint)
 c.draw_circle(muzzle, 1.2, Color(1.0, .91, .78, tint.a))

func draw_arc_discharge(c, heading: int, center: Vector2, branch: String, fire: float):
 var yaw := heading * TAU / WEAPON_BEARINGS
 var lateral := Vector2(-sin(yaw), -cos(yaw) / sqrt(2.0)) * (0.103 * WEAPON_UNIT)
 var direction := weapon_projection(heading).normalized()
 var color := Color("B9A6E9") if branch == "focus" else Color("86CCE2")
 color.a = fire * 0.83
 if CinematicQuality.reduced_flash(c):
  c.draw_line(center - lateral, center + lateral, color, 1.15)
  return
 var path := PackedVector2Array([center - lateral, center - lateral * 0.37 + direction * 1.15, center + lateral * 0.23 - direction, center + lateral])
 c.draw_polyline(path, Color(color, color.a * 0.34), 3.8, true)
 c.draw_polyline(path, color, 1.15, true)
 c.draw_circle(center, 1.8 + fire * 1.3, Color(color, color.a * 0.43))

var ribs: Dictionary={}
func _rib(color: Color):
 var key=color.to_html()
 if not ribs.has(key):
  var s=StyleBoxFlat.new();s.bg_color=color.darkened(.5);s.border_color=color.lightened(.1);s.set_border_width_all(1);s.set_corner_radius_all(2);ribs[key]=s
 return ribs[key]
