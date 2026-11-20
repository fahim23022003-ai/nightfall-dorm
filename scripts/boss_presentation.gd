extends RefCounted
# Original layered vector animation; purely visual, bounded deterministic particles.
const OFFSET=Vector2(145,40)
const Articulation=preload("res://scripts/articulated_hunter.gd")
const NightmareVisual=preload("res://scripts/nightmare_presentation.gd")
var articulated=Articulation.new()
const SCYTHE_GRIPS={
 "oblique": Vector2(166,126),
 "front": Vector2(164,128),
 "left": Vector2(104,127),
 "right": Vector2(132,129)
}
var robes=[]
var weapon=preload("res://assets/boss/scythe.svg")
var preview_enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var preview_textures: Dictionary = {}
var preview_poses: Dictionary = {}
var cloak_geometry = preload("res://scripts/phantom_witch_visual.gd").new()
var preview_projection := 1.0
var preview_texture_path := ""
var preview_pose_name := ""
var preview_grip := Vector2.ZERO
var preview_grip_side := 1.0
var preview_has_grip := false
var transition_previous_texture := ""
var low_haze: GradientTexture2D

func _init():
 for i in range(4): robes.append(load("res://assets/boss/reaper_%d.svg" % i))

func preview_texture(form: String) -> Texture2D:
 if not preview_textures.has(form):
  var path := "res://assets/visual_rebirth/grim_reaper/%s.png" % form
  preview_textures[form] = load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null
 return preview_textures[form]

func draw_preview_body(c, form: String, floor: Vector2, tint: Color, motion: String, progress: float, reduced: bool, heading: Vector2) -> bool:
 if not preview_enabled:return false
 var view := cloak_geometry.facing(heading)
 var texture := preview_texture(form + "_" + view) if view != "oblique" else null
 if absf(heading.x) > .18:
  preview_projection = signf(heading.x)
 var projection := 1.0
 if texture == null:
  texture = preview_texture(form)
  projection = preview_projection
  view = "oblique"
 if texture == null:return false
 preview_texture_path = texture.resource_path
 preview_pose_name = motion
 CinematicQuality.draw_hunter_backlight(c,floor,Color("a97499"),tint.a,true)
 if tint.r<=1.0:tint*=Color(1.15,1.15,1.2,1)
 var frame := 0 if reduced and motion in ["hover","glide","turn"] else roundi(clampf(progress,0.0,1.0)*16.0)
 var sample := float(frame)/16.0
 var key := Vector2i(["hover","glide","turn","tell","release","hit","recover","evolve","vanish"].find(motion),frame)
 if not preview_poses.has(key):
  preview_poses[key] = cloak_geometry.build_pose(motion,sample,1,224.0)
 var pose_transform := Transform2D(0.0,Vector2(projection,1.0),0.0,floor)
 c.draw_mesh(preview_poses[key],texture,pose_transform,tint)
 # The rear illustration shows the occluding mantle, without a visible hand.
 preview_has_grip = form == "transformed" and SCYTHE_GRIPS.has(view)
 if preview_has_grip:
  var grip: Vector2 = SCYTHE_GRIPS[view]
  var offset: Vector2 = cloak_geometry.deformation(grip/Vector2(224,264),motion,sample)
  preview_grip = pose_transform * ((grip-Vector2(112,260))*(104.0/256.0)+offset)
  preview_grip_side = -1.0 if view == "left" else projection
 return true

func draw_approach(c,h,clock: float,death_age: float,heading: Vector2, moving: bool, turn: float, release: float) -> bool:
 articulated.clear_frame()
 transition_previous_texture=""
 if not approach_visible(c.model):return false
 var reduced := CinematicQuality.reduced_motion(c)
 var floor := OFFSET + Vector2(h.position) + Vector2(0,13.0)
 var motion := "hover"
 var progress := fposmod(clock*.38,1.0)
 var alpha := 1.0
 if h.state == HunterState.State.DEAD:
  motion = "vanish"
  progress = clampf(death_age,0.0,1.0)
  alpha = clampf(1.0-death_age/1.5,0.0,1.0)
  if articulated.enabled and alpha<=0.0:
   preview_texture_path=""
   preview_pose_name=""
   return true
 elif h.windup_remaining > 0.0:
  motion = "tell"
  var duration := float(RankCatalog.pressure(h.difficulty).windup) if h.charged_ready else float(StrategyCatalog.ARCHETYPES.get(h.archetype, {}).get("windup", 1.0))
  if h.charged_ready and h.archetype=="crusher":
   duration=maxf(duration,.9)
  progress = clampf(1.0-h.windup_remaining/maxf(.01,duration),0.0,1.0)
 elif release>0:
  motion = "release"
  progress = 1.0-release/.42
 elif h.hit_flash > 0.0:
  motion = "hit"
  progress = clampf(h.hit_flash*2.0,0.0,1.0)
 elif h.recovery_remaining>0:
  motion = "recover"
  progress = clampf(h.recovery_remaining/.85,0.0,1.0)
 elif turn>.18 and not reduced:
  motion = "turn"
  progress = turn
 elif moving:
  motion = "glide"
  progress = fposmod(clock*.57,1.0)
 var tint := Color(1.1,1,1,alpha) if h.hit_flash > 0.0 else Color(1,1,1,alpha)
 if articulated.enabled and draw_articulation(c,h,"approach",floor,tint,heading,clock,moving,death_age,progress,reduced):
  return true
 return draw_preview_body(c,"approach",floor,tint,motion,progress,reduced,heading)

func draw(c,h,clock: float,death_age: float,heading=Vector2.RIGHT,reduced=false,moving=false,turn=0.0,release=0.0):
 articulated.clear_frame()
 transition_previous_texture=""
 var active_rig: bool = preview_enabled and articulated.enabled
 var low_detail:=CinematicQuality.detail(c)==0
 var changing: bool = h.state==HunterState.State.TRANSFORM
 var progress:=clampf(1.0-float(h.transform_remaining)/BossCatalog.TRANSFORM_SECONDS,0.0,1.0) if changing else 1.0
 var dead: bool = h.state==HunterState.State.DEAD
 var alpha:=clampf(1.0-death_age/1.5,0.0,1.0) if dead else clampf(progress*2.0,0.0,1.0)
 var p: Vector2=OFFSET+h.position+Vector2(0,-14+sin(clock*3)*3)
 if dead and death_age>(1.5 if active_rig else 1.8):
  if active_rig:
   preview_texture_path=""
   preview_pose_name=""
  return
 if active_rig and low_detail:
  draw_low_haze(c,p,0.0 if CinematicQuality.reduced_motion(c) else clock,progress,death_age,alpha)
 else:
  # Smoke wreath curls with time through the transformation and death.
  for i in range(7 if reduced or (preview_enabled and low_detail) else 18):
   var angle=i*TAU/18+clock*(0.6 if i%2 else -0.45)
   var radius=24+sin(clock*2+i)*8+(30*sin(progress*PI) if changing else 0)+(death_age*60 if dead else 0)
   var q=p+Vector2(cos(angle)*radius,sin(angle)*radius*.55+12-i%3*8)
   c.draw_circle(q,8+i%4,Color(.07,.045,.12,.5*alpha))
   c.draw_arc(q,9+i%4,angle,angle+1.7,8,Color(.54,.28,.68,.22*alpha),1.2)
 if changing:
  c.draw_arc(p,28+progress*45,-PI/2,-PI/2+TAU*progress,64,Color(.85,.35,.7,.8*alpha),2.5)
  for i in range(7):
   var q=p+Vector2.from_angle(i*TAU/7+clock)*42
   c.draw_line(q,q+Vector2(0,-15*sin(progress*PI)),Color(.66,.42,.86,.45),2)
 var stretch=1.0+sin(clock*3)*.018
 var tint=Color(1.1 if CinematicQuality.reduced_flash(c) else 1.7,1.1,1.1 if CinematicQuality.reduced_flash(c) else 1.4,alpha) if h.hit_flash>0 else Color(1,1,1,alpha)
 var fall=Vector2(0,death_age*16) if dead else Vector2.ZERO
 var preview_motion := "evolve" if changing else "vanish" if dead else "hover"
 var preview_progress := fposmod(clock*.46,1.0)
 if changing:preview_progress=progress
 elif dead:preview_progress=death_age
 elif h.boss_attack!="":
  preview_motion="tell"
  preview_progress=1.0-h.windup_remaining/BossCatalog.ATTACKS[h.boss_attack].windup
 elif c.model.wrath.active():
  preview_motion="tell"
  preview_progress=1.0-c.model.wrath.warning/ReaperWrath.ABILITIES[c.model.wrath.ability].warning
 elif h.arcane.action!="":
  preview_motion="tell"
  preview_progress=1.0-h.arcane.warning/(.7 if h.arcane.action=="shadow_dash" else 1.1)
 elif release>0:
  preview_motion="release"
  preview_progress=1.0-release/.42
 elif h.hit_flash>0:
  preview_motion="hit"
  preview_progress=h.hit_flash*2.0
 elif moving:
  preview_motion="turn" if turn>.18 else "glide"
  preview_progress=turn if turn>.18 else fposmod(clock*.65,1.0)
 elif h.last_boss_attack!="" and h.boss_action_age<.92:
  preview_motion="recover"
  preview_progress=1.0-clampf((h.boss_action_age-.42)/.5,0,1)
 var lower: Vector2=p+Vector2(0,34)+fall
 var reduce_motion: bool=reduced or (preview_enabled and CinematicQuality.reduced_motion(c))
 if active_rig and changing:
  var departing:=1.0-smoothstep(.04,.42,progress)
  if departing>0.0 and draw_articulation(c,h,"approach",lower,Color(.93,.88,.96,departing),heading,clock,false,0.0,progress,reduce_motion):
   transition_previous_texture=articulated.last_asset
  tint.a=smoothstep(.04,.48,progress)
 var drawn: bool=active_rig and draw_articulation(c,h,"transformed",lower,tint,heading,clock,moving,death_age,preview_progress,reduce_motion)
 if not drawn:
  drawn=draw_preview_body(c,"transformed",lower,tint,preview_motion,preview_progress,reduce_motion,heading)
 if not drawn:
  c.draw_texture_rect(robes[int(clock*6)%4],Rect2(p+Vector2(-42,-76)+fall,Vector2(84,110*stretch)),false,tint)
 var handed=preview_grip_side if drawn and preview_has_grip else -1.0 if heading.x<-.15 else 1.0
 var angle=(-.18+sin(clock*2)*.05)*handed
 if h.boss_attack!="":
  var data=BossCatalog.ATTACKS[h.boss_attack]
  var charge=clampf(1-h.windup_remaining/data.windup,0,1)
  angle=(-.2-charge*1.3)*(handed if drawn else 1.0)
  var color=Color(.7,.3,1,.65) if h.boss_attack=="surge" else Color(1,.25,.38,.7)
  c.draw_arc(p,48,-PI/2,-PI/2+TAU*charge,48,color,3)
  if h.target>=0 and h.target<c.model.rooms.size():
   var door=OFFSET+c.model.rooms[h.target].door_position()
   c.draw_line(p,door,color,2)
   c.draw_arc(door,28+charge*8,0,TAU,32,color,2)
 elif h.boss_action_age<.4 and h.last_boss_attack in ["scythe","siege"]:
  angle=lerpf(-1.5,1.2,h.boss_action_age/.4)*(handed if drawn else 1.0)
  if articulated.last_asset.is_empty():c.draw_arc(p,53,-1.9,angle,32,Color(1,.57,.66,(1-h.boss_action_age/.4)*alpha),4)
 elif drawn and c.model.wrath.ability=="scythe_slash":
  var charge:=1.0-float(c.model.wrath.warning)/float(ReaperWrath.ABILITIES.scythe_slash.warning)
  angle=(-.28-1.13*charge)*handed
 if (not drawn and (not active_rig or c.model.wrath.scythe.is_empty())) or (preview_has_grip and c.model.wrath.scythe.is_empty()):
  var grip=preview_grip if drawn else p+Vector2(23*handed,-23)+fall
  c.draw_set_transform(grip,angle,Vector2(handed,1))
  c.draw_texture_rect(weapon,Rect2(-19,-67,62,105) if drawn else Rect2(-20,-61,62,105),false,tint)
  c.draw_set_transform(Vector2.ZERO)
 # Eyes pulse separately from cloth motion.
 if not drawn:
  for x in [-7,7]: c.draw_circle(p+Vector2(x,-42),2.4,Color(1,.15,.42,(.65+.25*sin(clock*5))*alpha))
 if h.surge_remaining>0 and h.surge_room>=0:
  var room=c.model.rooms[h.surge_room]
  for tile in room.buildings:
   if room.buildings[tile].kind not in DefenseEffects.WEAPONS: continue
   var q=OFFSET+room.tile_position(tile)
   c.draw_arc(q,24,clock,clock+TAU*.85,24,Color(.73,.39,.95,.8),2)
   c.draw_line(q+Vector2(-7,-7),q+Vector2(7,7),Color(.9,.65,1,.9),2)


func draw_low_haze(c: CanvasItem, at: Vector2, clock: float, progress: float, death_age: float, alpha: float):
 if low_haze==null:
  var ramp:=Gradient.new()
  ramp.offsets=PackedFloat32Array([0.0,.43,1.0])
  ramp.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.37),Color(1,1,1,0)])
  low_haze=GradientTexture2D.new()
  low_haze.gradient=ramp
  low_haze.width=32
  low_haze.height=32
  low_haze.fill=GradientTexture2D.FILL_RADIAL
  low_haze.fill_from=Vector2(.5,.5)
  low_haze.fill_to=Vector2(1,.5)
 var spread:=25.0+21.0*sin(progress*PI)+death_age*44.0
 for curl in range(3):
  var angle:=clock*.65+curl*TAU/3.0
  var center:=at+Vector2.from_angle(angle)*Vector2(spread,spread*.5)+Vector2(0,8)
  var size:=Vector2(31,24)*(1.0+death_age*.30)
  c.draw_texture_rect(low_haze,Rect2(center-size*.5,size),false,Color(.43,.24,.56,.32*alpha))

func articulated_contact() -> Vector2:
 return articulated.contact

func draw_articulation(c,h,form: String,floor: Vector2,tint: Color,heading: Vector2,clock: float,moving: bool,death_age: float,windup: float,reduced: bool) -> bool:
 var timing:=NightmareVisual.articulation_timing(c,h,clock,windup,moving,clampf(death_age,0.0,1.0))
 if form=="transformed":
  timing=transformed_timing(c.model,h,timing)
 if timing.aim.is_finite():
  heading=(Vector2(timing.aim)-OFFSET-Vector2(h.position)+Vector2(0,9)).normalized()
 CinematicQuality.draw_hunter_backlight(c,floor,Color("a97499"),tint.a,true)
 if tint.r<=1.0:tint*=Color(1.15,1.15,1.2,1)
 var shown:=articulated.draw(c,"reaper_"+form,floor,tint,heading,clock,clock*3.8,1.0 if moving else 0.0,timing.motion,timing.progress,timing.aim,reduced,c.model.wrath.scythe.is_empty())
 if shown:
  preview_texture_path=articulated.last_asset
  preview_pose_name=articulated.pose_name
  preview_has_grip=false
 return shown


func transformed_timing(model: MatchModel, h: HunterState, ordinary: Dictionary) -> Dictionary:
 if ordinary.motion in ["vanish","evolve","contact","follow"]:
  return ordinary
 var wrath: ReaperWrath=model.wrath
 if wrath.active():
  var charge:=clampf(1.0-float(wrath.warning)/float(ReaperWrath.ABILITIES[wrath.ability].warning),0.0,1.0)
  if wrath.ability=="scythe_slash" and wrath.cast_target>=0 and wrath.cast_target<model.rooms.size():
   return {"motion":"windup","progress":charge,"aim":OFFSET+HunterCombatVisual.door_socket(model.rooms[wrath.cast_target])}
  return {"motion":"cast","progress":charge,"aim":Vector2.INF}
 if h.boss_attack=="surge":
  var charge:=clampf(1.0-float(h.windup_remaining)/float(BossCatalog.ATTACKS.surge.windup),0.0,1.0)
  return {"motion":"cast","progress":charge,"aim":Vector2.INF}
 if not wrath.scythe.is_empty() and float(wrath.scythe.flight)>0.0:
  return {"motion":"cast_release","progress":clampf(1.0-float(wrath.scythe.flight)/.8,0.0,1.0),"aim":Vector2.INF}
 if h.last_boss_attack!="" and h.boss_action_age<.92 and ordinary.motion=="idle":
  return {"motion":"recover","progress":1.0-clampf((float(h.boss_action_age)-.42)/.50,0.0,1.0),"aim":Vector2.INF}
 return ordinary


func approach_visible(model: MatchModel) -> bool:
 if not preview_enabled or not model.hunter.boss_policy.get("enabled",false):
  return false
 if not articulated.enabled:
  return true
 if model.story_level>0:
  return model.story_level in [39,40,45,50]
 return model.run_kind in ["practice","endless"] or model.stage_id=="stage_5"
