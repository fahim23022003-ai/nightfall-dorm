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
const MAX_CACHED_ATLASES := 16

var enabled := OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE") == "1"
var textures: Dictionary[String,Texture2D] = {}
var regions_by_pose: Dictionary = {}
var _regions: Dictionary
var _vertices := PackedVector2Array()
var _uvs := PackedVector2Array()
var _batch_indices: Dictionary[int,PackedInt32Array] = {}
var _tint := PackedColorArray([Color.WHITE])
var contact := Vector2.INF
var wrist := Vector2.INF
var weapon_grip := Vector2.INF
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

static func catalog_key(family: String, level: int) -> String:
 var candidate:=family if level==1 and family in ["stalker","ravager"] else "%s_l%02d" % [family,level]
 return candidate if Atlas.POSES.has(candidate+"_front") else ""

func clear_frame() -> void:
 contact=Vector2.INF
 wrist=Vector2.INF
 weapon_grip=Vector2.INF
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
  var texture:=load(path) as Texture2D
  if texture==null:return false
  if textures.size()>=MAX_CACHED_ATLASES:
   var oldest: String=textures.keys()[0]
   textures.erase(oldest)
   regions_by_pose.erase(oldest)
  textures[key]=texture
  var atlas_size:=texture.get_size()
  var regions:={}
  for id in Atlas.POSES[key].regions:
   var packed: Array=Atlas.POSES[key].regions[id]
   var rect: Array=packed[0]
   var source_rect:=Rect2(rect[0],rect[1],rect[2],rect[3])
   var uv_start:=source_rect.position/atlas_size
   var uv_end:=source_rect.end/atlas_size
   var uvs:=PackedVector2Array([uv_start,Vector2(uv_end.x,uv_start.y),uv_end,Vector2(uv_start.x,uv_end.y)])
   regions[id]=[point(packed[1]),source_rect.size,uvs]
  regions_by_pose[key]=regions
 var atlas:=textures[key]
 _regions=regions_by_pose[key]
 _tint[0]=tint
 var art: Dictionary=Atlas.POSES[key]
 var chains: Dictionary=art.chains
 var pivot:=point(art.pivot)
 var facing:=-1.0 if view_name=="left" else 1.0 if view_name=="right" else 0.0
 var crawl:=family.begins_with("ravager")
 var spectral:=family.begins_with("stalker")
 var heavy:=family.begins_with("crusher")
 var twitch:=family.begins_with("electric")
 var gale:=family.begins_with("storm")
 var witch:=family.begins_with("witch")
 var reaper:=family.begins_with("reaper")
 var arm_attack:=target.is_finite() and motion in ["windup","contact","follow"]
 var rear_scythe:=family=="reaper_transformed" and view_name=="back"
 var armed:=family=="reaper_transformed" and chains.has("near") and show_weapon and (not rear_scythe or arm_attack)
 var transfer:=smoothstep(.76,1.0,progress) if arm_attack and motion=="windup" else 0.0
 var effort:=1.0-clampf(progress/.30,0.0,1.0) if motion=="follow" else maxf(float(motion=="contact"),transfer)
 var coil:=smoothstep(0.0,.76,progress)*(1.0-transfer) if motion=="windup" else 0.0
 var hit:=progress if motion=="hit" else 0.0
 var recover:=progress if motion=="recover" else 0.0
 var turn:=progress if motion=="turn" else 0.0
 var vanish:=progress if motion=="vanish" else 0.0
 var swell:=sin(progress*PI) if motion in ["evolve","heal"] else 0.0
 var breathe:=sin(clock*2.4)*(.85 if reduced else 1.45)
 var amplitude:=maxf(stride,.85 if motion=="lunge" else 0.0)*(.68 if reduced else 1.0)
 var step:=sin(gait)
 var shoulder_direction:=Vector2(facing,0.0)
 if arm_attack:
  var root_delta:=target-floor
  if absf(root_delta.x)>5.0:
   shoulder_direction.x=signf(root_delta.x)
 var attack_lean:=(.20*effort-.19*coil)*shoulder_direction.x
 var weight_roll:=step*amplitude*(.085 if crawl else .042)+turn*facing*(.10 if crawl else .07)
 if motion=="lunge":weight_roll+=facing*.12*sin(progress*PI)
 var torso_angle:=attack_lean+weight_roll+hit*.12*maxf(.2,facing)+vanish*.28*facing
 var lift_distance:=1.35 if crawl else 2.1 if heavy else .65
 var lower_at:=floor+Vector2(0,-lift_distance*absf(step)*amplitude)
 if witch or gale:
  lower_at.y-=sin(clock*(2.1 if witch else 1.7))*2.8
 var spine:=lower_at+Vector2(shoulder_direction.x*(6.0*effort-3.0*coil),breathe-(1.9 if crawl else 1.3)*amplitude*cos(gait)+9.5*effort-2.0*coil+vanish*6.5-3.0*swell+3.0*recover)
 var hem_pivot:=point(art.hem)
 var garment_angle:=-torso_angle*.4+sin(gait-1.03)*amplitude*(.08 if spectral else .062)+.13*swell-turn*facing*.05
 if witch or gale:
  garment_angle+=sin(clock*2.5+(1.0 if gale else .1))*(.10 if gale else .064)
 var hem_world:=lower_at+(hem_pivot-pivot)*SCALE
 # The front-facing Stalker leans toward the door out of the image plane.
 # Compress the projected trunk around the pelvis, not the arm segments.
 var fold:=1.0
 if arm_attack:
  fold-=effort*(.49 if spectral else .32 if not crawl and not reaper else 0.0)
 if arm_attack and (family.contains("_l") or rear_scythe) and chains.has("near"):
  # Step the shoulders into the door if the painted bind pose is foreshortened.
  # Lower legs keep their floor anchors, and cloth follows the weight shift.
  var bones: Array=chains.near
  var shoulder:=world_point(point(bones[0]),hem_pivot,spine,pivot,torso_angle,fold)
  var aim:=target
  if armed:
   var sign_x:=-1.0 if view_name=="left" else 1.0
   var edge:=SCYTHE_EDGE*Vector2(sign_x,1.0)
   aim-=edge.rotated(edge.angle_to(Vector2(shoulder_direction.x,-1.0 if rear_scythe else 1.0).normalized()))
  var maximum_reach:=0.0
  for idx in range(3):
   maximum_reach+=point(bones[idx]).distance_to(point(bones[idx+1]))*SCALE
  var step_in:=shoulder.direction_to(aim)*clampf(shoulder.distance_to(aim)-maximum_reach*.97,0.0,40.0 if rear_scythe else 34.0)*effort
  spine+=step_in
  hem_world+=step_in*.31
 var neck:=point(art.neck)
 var neck_world:=world_point(neck,hem_pivot,spine,pivot,torso_angle,fold)
 var lead: Dictionary={}
 var weapon_side:=-1.0 if view_name=="left" else 1.0
 var blade_axis:=SCYTHE_EDGE*Vector2(weapon_side,1.0) if armed else Vector2.ZERO
 var weapon_idle:=-.45*weapon_side
 var striking_angle:=blade_axis.angle_to(Vector2(shoulder_direction.x,-1.0 if rear_scythe else 1.0)) if armed else 0.0
 pose_name=motion
 last_asset=atlas.resource_path

 # Limbs are articulated before drawing but ordered from back to front.
 # Cloth stays in its own layer to read as follow-through, not locked to hips.
 var angles := {}
 for name in chains:
  if rear_scythe and name=="near" and not armed:continue
  var bones: Array=chains[name]
  var is_leg: bool=name.ends_with("foot")
  var rotation:=torso_angle*.4 if is_leg else torso_angle
  var start:=point(bones[0])
  var root:=world_point(start,hem_pivot,lower_at if is_leg else spine,pivot,rotation,1.0 if is_leg else fold)
  var joint:=root+((point(bones[1])-start)*SCALE).rotated(rotation)
  var bend:=root+((point(bones[2])-start)*SCALE).rotated(rotation)
  var tip:=root+((point(bones[3])-start)*SCALE).rotated(rotation)
  var offset_phase:=gait+PI if name in ["far","foot"] else gait
  var cycle:=sin(offset_phase)
  var lift:=maxf(0.0,cos(offset_phase))
  if crawl:
   tip+=Vector2(cycle*(13.0 if is_leg else 11.0)*(facing if facing!=0.0 else .42),-lift*(9.0 if is_leg else 11.0))*amplitude
  elif is_leg:
   tip+=Vector2(cycle*(7.8 if heavy else 5.2),-lift*(4.5 if heavy else 3.0))*amplitude
  else:
   if twitch and not reduced:
    tip+=Vector2(sin(clock*19+offset_phase),cos(clock*23+offset_phase))*1.55
   if gale or witch:
    tip+=Vector2(sin(clock*3.8+offset_phase)*2.4,-cos(clock*3.2+offset_phase)*3.1)
   tip+=Vector2(cycle*(5.25 if spectral else 2.9),-lift*(4.25 if spectral else 2.0))*amplitude
   tip+=Vector2(sin(clock*2.8+offset_phase)*1.75,-2.0*swell)
  var weapon_angle:=weapon_idle-.98*coil*weapon_side
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
  elif motion in ["cast","cast_release"] and not is_leg:
   var gesture:=sin(clampf(progress,0.0,1.0)*PI) if motion=="cast_release" else smoothstep(0.0,1.0,progress)
   var hand_side:=1.0 if name=="near" else -1.0
   tip+=Vector2(hand_side*(12.0 if witch or gale else 8.0),-gesture*(18.0 if witch else 12.0))*gesture+Vector2(0,-3.0*lift)
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
  draw_chain(art,"far_foot",angles.far_foot)
 if angles.has("foot"):
  draw_chain(art,"foot",angles.foot)
 draw_piece("hem",hem_world,hem_pivot,garment_angle)
 if angles.has("far"):
  draw_chain(art,"far",angles.far)
 var torso_at:=world_point(hem_pivot,hem_pivot,spine,pivot,torso_angle)
 draw_piece("torso",torso_at,hem_pivot,torso_angle,1.0,fold)
 var nod:=sin(clock*2.0-.4)*(.045 if reduced else .073)+.12*coil-.16*effort-.15*hit+turn*facing*.045
 draw_piece("head",neck_world,neck,torso_angle+nod)
 if not lead.is_empty():
  draw_chain(art,"near",lead,false)
  if armed:
   # Staff pivots at the actual hand; the palm is redrawn above the shaft.
   c.draw_set_transform(Vector2.ZERO)
   flush_layers(c,atlas)
   var grip: Vector2=lead.tip
   weapon_grip=grip
   var blade_transform:=Transform2D(lead.weapon_angle,Vector2(lead.weapon_sign,1.0),0.0,grip)
   c.draw_set_transform_matrix(blade_transform)
   c.draw_texture_rect(SCYTHE,Rect2(-SCYTHE_GRIP,SCYTHE_SIZE),false,tint)
   contact=blade_transform*SCYTHE_EDGE
  else:
   contact=lead.tip
  draw_end(art,"near",lead)
 c.draw_set_transform(Vector2.ZERO)
 flush_layers(c,atlas)
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

func draw_chain(art: Dictionary, name: String, chain: Dictionary, include_end:=true) -> void:
 var bones: Array=art.chains[name]
 var a:=point(bones[0])
 var b:=point(bones[1])
 var d:=point(bones[2])
 var upper: Vector2=chain.joint-chain.root
 var lower: Vector2=chain.bend-chain.joint
 draw_piece(name+"_upper",chain.root,a,(b-a).angle_to(upper),upper.length()/maxf(.1,(b-a).length()*SCALE))
 draw_piece(name+"_lower",chain.joint,b,(d-b).angle_to(lower),lower.length()/maxf(.1,(d-b).length()*SCALE))
 if include_end:
  draw_end(art,name,chain)

func draw_end(art: Dictionary, name: String, chain: Dictionary) -> void:
 var bones: Array=art.chains[name]
 var anchor:=point(bones[2])
 var end: Vector2=chain.tip-chain.bend
 draw_piece(name+"_end",chain.bend,anchor,(point(bones[3])-anchor).angle_to(end))

func draw_piece(id: String, world: Vector2, local: Vector2, rotation: float, length_scale:=1.0, vertical_scale:=1.0) -> void:
 if not _regions.has(id):
  return
 var region: Array=_regions[id]
 var top_left: Vector2=region[0]-local
 var size: Vector2=region[1]
 var transform:=Transform2D(rotation,Vector2(1.0,vertical_scale)*SCALE*length_scale,0.0,world)
 var corner:=transform*top_left
 var across:=transform.x*size.x
 var down:=transform.y*size.y
 _vertices.append(corner)
 _vertices.append(corner+across)
 _vertices.append(corner+across+down)
 _vertices.append(corner+down)
 _uvs.append_array(region[2])

func flush_layers(canvas: CanvasItem, atlas: Texture2D) -> void:
 if _vertices.is_empty():return
 var size:=_vertices.size()
 if not _batch_indices.has(size):
  var indices:=PackedInt32Array()
  for base in range(0,size,4):
   indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
  _batch_indices[size]=indices
 RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),_batch_indices[size],_vertices,_tint,_uvs,PackedInt32Array(),PackedFloat32Array(),atlas.get_rid())
 _vertices.clear()
 _uvs.clear()
