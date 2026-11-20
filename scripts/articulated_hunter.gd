extends RefCounted
## Directional cut-out rig. Each joint texture overlaps the next bone at its
## pivot, and a reconstructed torso hides the painted bind pose under the arm.

const Atlas = preload("res://scripts/articulated_hunter_atlas.gd")
const SCYTHE = preload("res://assets/boss/scythe.svg")
const SCALE := 104.0 / 256.0
const SCYTHE_SIZE := Vector2(62,105)
const SCYTHE_GRIP := Vector2(.32,.65) * SCYTHE_SIZE
const SCYTHE_EDGE := Vector2(.89,.50) * SCYTHE_SIZE - SCYTHE_GRIP
const CONTACT_HOLD := .045
const STRIKE_RECOVERY := .42

var enabled := OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE") == "1"
var textures: Dictionary[String,Texture2D] = {}
var contact := Vector2.INF
var wrist := Vector2.INF
var pose_name := ""
var view_name := ""
var last_asset := ""
var joint_points := PackedVector2Array()

static func cardinal(heading: Vector2, previous: String) -> String:
 if heading.length_squared()<.02:
  return previous if previous!="" else "front"
 var horizontal := absf(heading.x)
 var vertical := absf(heading.y)
 if absf(horizontal-vertical)<.14 and previous!="":
  return previous
 if horizontal>vertical:
  return "right" if heading.x>0.0 else "left"
 return "front" if heading.y>=0.0 else "back"

func clear_frame() -> void:
 contact=Vector2.INF
 wrist=Vector2.INF
 pose_name=""
 last_asset=""
 joint_points.clear()

func draw(c: CanvasItem, family: String, floor: Vector2, tint: Color, heading: Vector2, clock: float, gait: float, stride: float, motion: String, progress: float, target: Vector2, reduced: bool, show_weapon:=true) -> bool:
 if not enabled:
  return false
 view_name=cardinal(heading,view_name)
 var key:=family+"_"+view_name
 if not Atlas.POSES.has(key):
  return false
 if not textures.has(key):
  var path:="res://assets/visual_rebirth/articulated/%s.png" % key
  if not ResourceLoader.exists(path,"Texture2D"):
   return false
  textures[key]=load(path) as Texture2D
 var atlas:=textures[key]
 var art: Dictionary=Atlas.POSES[key]
 var chains: Dictionary=art.chains
 var pivot:=point(art.pivot)
 var facing:=-1.0 if view_name=="left" else 1.0 if view_name=="right" else 0.0
 var crawl:=family=="ravager"
 var spectral:=family=="stalker"
 var reaper:=family.begins_with("reaper")
 var armed:=family=="reaper_transformed" and chains.has("near") and show_weapon
 var arm_attack:=target.is_finite() and motion in ["windup","contact","follow"]
 var transfer:=smoothstep(.76,1.0,progress) if arm_attack and motion=="windup" else 0.0
 var effort:=1.0-clampf(progress/.30,0.0,1.0) if motion=="follow" else maxf(float(motion=="contact"),transfer)
 var coil:=smoothstep(0.0,.76,progress)*(1.0-transfer) if motion=="windup" else 0.0
 var hit:=progress if motion=="hit" else 0.0
 var vanish:=progress if motion=="vanish" else 0.0
 var swell:=sin(progress*PI) if motion in ["evolve","heal"] else 0.0
 var breathe:=sin(clock*2.4)*(.85 if reduced else 1.45)
 var amplitude:=stride*(.68 if reduced else 1.0)
 var step:=sin(gait)
 var shoulder_direction:=Vector2(facing,0.0)
 if arm_attack:
  var root_delta:=target-floor
  if absf(root_delta.x)>5.0:
   shoulder_direction.x=signf(root_delta.x)
 var attack_lean:=(.20*effort-.19*coil)*shoulder_direction.x
 var weight_roll:=step*amplitude*(.085 if crawl else .042)
 var torso_angle:=attack_lean+weight_roll+hit*.12*maxf(.2,facing)+vanish*.28*facing
 var lower_at:=floor+Vector2(0,-(1.35 if crawl else .65)*absf(step)*amplitude)
 var spine:=lower_at+Vector2(shoulder_direction.x*(6.0*effort-3.0*coil),breathe-(1.9 if crawl else 1.3)*amplitude*cos(gait)+9.5*effort-2.0*coil+vanish*6.5-3.0*swell)
 var hem_pivot:=point(art.hem)
 var garment_angle:=-torso_angle*.4+sin(gait-1.03)*amplitude*(.08 if spectral else .062)+.13*swell
 var hem_world:=lower_at+(hem_pivot-pivot)*SCALE
 # The front-facing Stalker leans toward the door out of the image plane.
 # Compress the projected trunk around the pelvis, not the arm segments.
 var fold:=1.0-.49*effort if spectral and arm_attack else 1.0
 var neck:=point(art.neck)
 var neck_world:=world_point(neck,hem_pivot,spine,pivot,torso_angle,fold)
 var lead: Dictionary={}
 pose_name=motion
 last_asset=atlas.resource_path

 # Limbs are articulated before drawing but ordered from back to front.
 # Cloth stays in its own layer to read as follow-through, not locked to hips.
 var angles := {}
 for name in chains:
  var bones: Array=chains[name]
  var is_leg: bool=name.ends_with("foot")
  var root:=world_point(point(bones[0]),hem_pivot,lower_at if is_leg else spine,pivot,torso_angle*.4 if is_leg else torso_angle)
  if not is_leg:root=world_point(point(bones[0]),hem_pivot,spine,pivot,torso_angle,fold)
  var rotation:=torso_angle*.4 if is_leg else torso_angle
  var start:=point(bones[0])
  var joint:=root+((point(bones[1])-start)*SCALE).rotated(rotation)
  var bend:=root+((point(bones[2])-start)*SCALE).rotated(rotation)
  var tip:=root+((point(bones[3])-start)*SCALE).rotated(rotation)
  var offset_phase:=gait+PI if name in ["far","foot"] else gait
  var cycle:=sin(offset_phase)
  var lift:=maxf(0.0,cos(offset_phase))
  if crawl:
   tip+=Vector2(cycle*(13.0 if is_leg else 11.0)*(facing if facing!=0.0 else .42),-lift*(9.0 if is_leg else 11.0))*amplitude
  elif not is_leg:
   tip+=Vector2(cycle*(5.25 if spectral else 2.9),-lift*(4.25 if spectral else 2.0))*amplitude
   tip+=Vector2(sin(clock*2.8+offset_phase)*1.75,-2.0*swell)
  var weapon_side:=-1.0 if view_name=="left" else 1.0
  var blade_axis:=SCYTHE_EDGE*Vector2(weapon_side,1.0)
  var weapon_idle:=-.45*weapon_side
  var weapon_angle:=weapon_idle-.98*coil*weapon_side
  var striking_angle:=blade_axis.angle_to(Vector2(shoulder_direction.x,1.0).normalized())
  var rest_tip:=tip
  if (arm_attack or motion=="windup") and name=="near":
   if motion=="windup":
    tip+=Vector2(-shoulder_direction.x*(8.0 if armed else 11.0),-21.0 if crawl else -15.0)*coil
    if absf(shoulder_direction.x)<.1:tip.x+=10.0*coil*(1.0 if view_name=="front" else -1.0)
    if arm_attack:
     if armed:
      weapon_angle=lerp_angle(weapon_angle,striking_angle,transfer)
      tip=tip.lerp(target-blade_axis.rotated(striking_angle),transfer)
     else:
      tip=tip.lerp(target,transfer)
   else:
    var follow:=clampf(progress/.26,0.0,1.0) if motion=="follow" else 0.0
    var aim:=target+Vector2(4.0*shoulder_direction.x,12.0)*sin(follow*PI)
    if armed:
     weapon_angle=lerp_angle(striking_angle,weapon_idle,follow)
     aim-=blade_axis.rotated(weapon_angle)
    tip=aim.lerp(rest_tip,follow)
  elif arm_attack and name=="far":
   tip+=Vector2(-5.0*shoulder_direction.x,4.0)*effort+Vector2(6.0*shoulder_direction.x,4.0)*coil
  var chain:=solve(root,joint,bend,rest_tip,tip,arm_attack and name=="near",crawl)
  angles[name]=chain
  if name=="near":
   lead=chain
   wrist=chain.bend
   joint_points=PackedVector2Array([chain.root,chain.joint,chain.bend,chain.tip])
   if armed:
    chain["weapon_angle"]=weapon_angle
    chain["weapon_sign"]=weapon_side
 if angles.has("far_foot"):
  draw_chain(c,atlas,art,"far_foot",angles.far_foot,tint)
 if angles.has("foot"):
  draw_chain(c,atlas,art,"foot",angles.foot,tint)
 draw_piece(c,atlas,art,"hem",hem_world,hem_pivot,garment_angle,tint)
 if angles.has("far"):
  draw_chain(c,atlas,art,"far",angles.far,tint)
 var torso_at:=world_point(hem_pivot,hem_pivot,spine,pivot,torso_angle)
 draw_piece(c,atlas,art,"torso",torso_at,hem_pivot,torso_angle,tint,1.0,fold)
 var nod:=sin(clock*2.0-.4)*(.045 if reduced else .073)+.12*coil-.16*effort-.15*hit
 draw_piece(c,atlas,art,"head",neck_world,neck,torso_angle+nod,tint)
 if not lead.is_empty():
  draw_chain(c,atlas,art,"near",lead,tint,false)
  if armed:
   # Staff pivots at the actual hand; the palm is redrawn above the shaft.
   var grip: Vector2=lead.tip
   var blade_transform:=Transform2D(lead.weapon_angle,Vector2(lead.weapon_sign,1.0),0.0,grip)
   c.draw_set_transform_matrix(blade_transform)
   c.draw_texture_rect(SCYTHE,Rect2(-SCYTHE_GRIP,SCYTHE_SIZE),false,tint)
   contact=blade_transform*SCYTHE_EDGE
  else:
   contact=lead.tip
  draw_end(c,atlas,art,"near",lead,tint)
 c.draw_set_transform(Vector2.ZERO)
 return true

static func point(data: Array) -> Vector2:
 return Vector2(data[0],data[1])

static func world_point(at: Vector2, anchor: Vector2, floor: Vector2, pivot: Vector2, angle: float, vertical_scale:=1.0) -> Vector2:
 return floor+(anchor-pivot)*SCALE+((at-anchor)*SCALE*Vector2(1.0,vertical_scale)).rotated(angle)

static func solve(root: Vector2, rest_joint: Vector2, rest_wrist: Vector2, rest_tip: Vector2, tip_target: Vector2, reaching: bool, crawl: bool) -> Dictionary:
 var upper:=rest_joint-root
 var lower:=rest_wrist-rest_joint
 var palm:=rest_tip-rest_wrist
 var wrist_aim:=tip_target-palm
 if reaching and tip_target.distance_squared_to(root)>.05:
  var extension:=tip_target-root
  palm=extension.normalized()*palm.length()
  wrist_aim=tip_target-palm
 var line:=wrist_aim-root
 var direction:=line.normalized() if line.length_squared()>.001 else upper.normalized()
 var a:=maxf(.5,upper.length())
 var b:=maxf(.5,lower.length())
 # Mild projection foreshortening can open into its full length at contact.
 var expand:=clampf(line.length()/(a+b),1.0,1.14) if reaching else 1.0
 a*=expand
 b*=expand
 var distance:=clampf(line.length(),absf(a-b)+.2,a+b-.05)
 var angle:=acos(clampf((a*a+distance*distance-b*b)/(2.0*a*distance),-1.0,1.0))
 var side:=signf(direction.cross(upper))
 if side==0.0:
  side=-1.0 if crawl else 1.0
 var joint:=root+direction.rotated(angle*side)*a
 var bend:=root+direction*distance
 return {"root":root,"joint":joint,"bend":bend,"tip":bend+palm}

func draw_chain(c: CanvasItem, atlas: Texture2D, art: Dictionary, name: String, chain: Dictionary, tint: Color, include_end:=true) -> void:
 var bones: Array=art.chains[name]
 var a:=point(bones[0])
 var b:=point(bones[1])
 var d:=point(bones[2])
 var upper: Vector2=chain.joint-chain.root
 var lower: Vector2=chain.bend-chain.joint
 draw_piece(c,atlas,art,name+"_upper",chain.root,a,(b-a).angle_to(upper),tint,upper.length()/maxf(.1,(b-a).length()*SCALE))
 draw_piece(c,atlas,art,name+"_lower",chain.joint,b,(d-b).angle_to(lower),tint,lower.length()/maxf(.1,(d-b).length()*SCALE))
 if include_end:
  draw_end(c,atlas,art,name,chain,tint)

func draw_end(c: CanvasItem, atlas: Texture2D, art: Dictionary, name: String, chain: Dictionary, tint: Color) -> void:
 var bones: Array=art.chains[name]
 var anchor:=point(bones[2])
 var end: Vector2=chain.tip-chain.bend
 draw_piece(c,atlas,art,name+"_end",chain.bend,anchor,(point(bones[3])-anchor).angle_to(end),tint)

func draw_piece(c: CanvasItem, atlas: Texture2D, art: Dictionary, id: String, world: Vector2, local: Vector2, rotation: float, tint: Color, length_scale:=1.0, vertical_scale:=1.0) -> void:
 if not art.regions.has(id):
  return
 var packed: Array=art.regions[id]
 var region: Array=packed[0]
 var source:=Rect2(region[0],region[1],region[2],region[3])
 c.draw_set_transform(world,rotation,Vector2(1.0,vertical_scale)*SCALE*length_scale)
 c.draw_texture_rect_region(atlas,Rect2(point(packed[1])-local,source.size),source,tint)
