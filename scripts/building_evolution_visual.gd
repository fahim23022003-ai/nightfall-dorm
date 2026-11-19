extends RefCounted
# Cached original shaded machinery, compact on pads; full detail in inspection.
var art: Dictionary={}
const WEAPON_ART_DIR = "res://assets/visual_rebirth/buildings/"
const NEEDLE_CELL = 112
const ARC_CELL = 96
const WEAPON_BEARINGS = 12
const WEAPON_CANVAS_SIZE = 99.0
const WEAPON_UNIT = WEAPON_CANVAS_SIZE / 3.75
const SUPPORT_BRANCHES = {"generator":["regulated","overcharge"],"repair":["sustain","conservation"]}
var rebirth_enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var rebirth_atlases: Dictionary = {}
const KINDS=["turret","heavy","generator","repair","economy","enhancer","flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna","bed","door"]
func _init():
 for kind in KINDS:
  for tier in range(4):art[kind+str(tier)]=load("res://assets/cinematic_buildings/%s_%d.svg" % [kind,tier])
func tier_for(level: int) -> int:return 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0
func draw(c,_p,kind: String,level: int,point: Vector2,branch: String="",activity: float=0,target: Vector2=Vector2.ZERO,clock: float=0,angle: float=0,render_scale: float=1.0,tint: Color=Color.WHITE):
 level=clampi(level,1,10)
 if support_rebirth_active(kind):
  draw_rebirth_support(c, kind, level, point, branch, activity, clock, angle, render_scale, tint)
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
  if ResourceLoader.exists(base_path) and ResourceLoader.exists(moving_path):
   var base := load(base_path) as Texture2D
   var moving := load(moving_path) as Texture2D
   if base != null and moving != null:
    textures = [base, moving]
  rebirth_atlases[kind] = textures
 return not rebirth_atlases[kind].is_empty()

func needle_rebirth_active() -> bool:
 return load_rebirth_atlas("turret", "launcher")

func arc_rebirth_active() -> bool:
 return load_rebirth_atlas("heavy", "launcher")

func support_rebirth_active(kind: String) -> bool:
 return SUPPORT_BRANCHES.has(kind) and load_rebirth_atlas(kind, "motion")

func support_activity(room, building: Dictionary) -> float:
 if building.kind == "generator":
  return 1.0 if room.alive and room.sleeping and not room.production_paused else 0.0
 return 1.0 if room.repair_status(building).actual > 0.0 else 0.0

func weapon_rebirth_active(kind: String) -> bool:
 return kind == "turret" and needle_rebirth_active() or kind == "heavy" and arc_rebirth_active()

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

func draw_rebirth_support(c, kind: String, level: int, point: Vector2, branch: String, activity: float, clock: float, angle: float, render_scale: float, tint: Color):
 var state := level - 1
 if level >= 5:
  if branch == SUPPORT_BRANCHES[kind][0]:
   state = level + 5
  elif branch == SUPPORT_BRANCHES[kind][1]:
   state = level + 11
 var phase := 0
 if activity > 0.0 and not CinematicQuality.reduced_motion(c):
  phase = posmod(floori(clock * (14.0 if kind == "generator" else 9.0)), 8)
 var cell := 96
 var rect := Rect2(Vector2(-WEAPON_CANVAS_SIZE * 0.5, -WEAPON_CANVAS_SIZE * 0.5 - 0.87 * WEAPON_UNIT), Vector2.ONE * WEAPON_CANVAS_SIZE)
 var atlas: Array = rebirth_atlases[kind]
 c.draw_set_transform(point, angle, Vector2.ONE * render_scale)
 c.draw_texture_rect_region(atlas[0], rect, Rect2((state % 6) * cell, floori(state / 6.0) * cell, cell, cell), tint)
 c.draw_texture_rect_region(atlas[1], rect, Rect2(phase * cell, state * cell, cell, cell), tint)
 c.draw_set_transform(Vector2.ZERO)

func draw_rebirth_weapon(c, kind: String, level: int, point: Vector2, branch: String, activity: float, target: Vector2, angle: float, render_scale: float, tint: Color):
 var arc := kind == "heavy"
 var state := level - 1
 if level >= 5:
  if branch in ["precision", "focus"]:
   state = level + 5
  elif branch in ["suppression", "storm"]:
   state = level + 11
 var heading := weapon_heading(target)
 var projected := weapon_projection(heading)
 var fire := clampf(activity / 0.15, 0.0, 1.0)
 var recoil := arc_recoil(c, projected, fire) if arc else needle_recoil(c, projected, fire)
 var cell := ARC_CELL if arc else NEEDLE_CELL
 var rect := Rect2(Vector2(-WEAPON_CANVAS_SIZE * 0.5, -WEAPON_CANVAS_SIZE * 0.5 - 0.87 * WEAPON_UNIT), Vector2.ONE * WEAPON_CANVAS_SIZE)
 c.draw_set_transform(point, angle, Vector2.ONE * render_scale)
 var atlas: Array = rebirth_atlases[kind]
 c.draw_texture_rect_region(atlas[0], rect, Rect2((state % 6) * cell, floori(state / 6.0) * cell, cell, cell), tint)
 c.draw_texture_rect_region(atlas[1], Rect2(rect.position - recoil, rect.size), Rect2(heading * cell, state * cell, cell, cell), tint)
 if fire > 0:
  if arc:
   draw_arc_discharge(c, heading, arc_muzzle(projected, recoil), branch, fire)
  else:
   var muzzle := needle_muzzle(projected, recoil)
   var direction := projected.normalized()
   var side := direction.orthogonal()
   var alpha := fire * 0.85
   if CinematicQuality.reduced_flash(c):
    c.draw_circle(muzzle, 1.6, Color(0.63, 0.86, 0.88, alpha))
   else:
    c.draw_colored_polygon(PackedVector2Array([muzzle - side * 2.0, muzzle + direction * (3.0 + 5.0 * fire), muzzle + side * 2.0]), Color(0.69, 0.93, 0.91, alpha))
 c.draw_set_transform(Vector2.ZERO)

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
