extends RefCounted
# Cached original shaded machinery, compact on pads; full detail in inspection.
var art: Dictionary={}
const KINDS=["turret","heavy","generator","repair","economy","enhancer","flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna","bed","door"]
func _init():
 for kind in KINDS:
  for tier in range(4):art[kind+str(tier)]=load("res://assets/cinematic_buildings/%s_%d.svg" % [kind,tier])
func tier_for(level: int) -> int:return 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0
func draw(c,_p,kind: String,level: int,point: Vector2,branch: String="",activity: float=0,target: Vector2=Vector2.ZERO,clock: float=0,angle: float=0,render_scale: float=1.0,tint: Color=Color.WHITE):
 level=clampi(level,1,10)
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
var ribs: Dictionary={}
func _rib(color: Color):
 var key=color.to_html()
 if not ribs.has(key):
  var s=StyleBoxFlat.new();s.bg_color=color.darkened(.5);s.border_color=color.lightened(.1);s.set_border_width_all(1);s.set_corner_radius_all(2);ribs[key]=s
 return ribs[key]
