extends RefCounted
# Original layered vector animation; purely visual, bounded deterministic particles.
const OFFSET=Vector2(145,40)
var robes=[]
var weapon=preload("res://assets/boss/scythe.svg")
var preview_enabled := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
var preview_textures: Dictionary = {}
var preview_poses: Dictionary = {}
var cloak_geometry = preload("res://scripts/phantom_witch_visual.gd").new()
var preview_projection := 1.0
var preview_texture_path := ""
var preview_pose_name := ""
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
 if texture == null:return false
 preview_texture_path = texture.resource_path
 preview_pose_name = motion
 CinematicQuality.draw_hunter_backlight(c,floor,Color("a97499"),tint.a,true)
 if tint.r<=1.0:tint*=Color(1.15,1.15,1.2,1)
 var frame := 0 if reduced and motion in ["hover","glide","turn"] else roundi(clampf(progress,0.0,1.0)*16.0)
 var key := Vector2i(["hover","glide","turn","tell","release","hit","recover","evolve","vanish"].find(motion),frame)
 if not preview_poses.has(key):
  preview_poses[key] = cloak_geometry.build_pose(motion,float(frame)/16.0,1,224.0)
 c.draw_mesh(preview_poses[key],texture,Transform2D(0.0,Vector2(projection,1.0),0.0,floor),tint)
 return true

func draw_approach(c,h,clock: float,death_age: float,heading: Vector2, moving: bool, turn: float, release: float) -> bool:
 if not preview_enabled or not h.boss_policy.get("enabled",false):return false
 var reduced := CinematicQuality.reduced_motion(c)
 var floor := OFFSET + Vector2(h.position) + Vector2(0,13.0)
 var motion := "hover"
 var progress := fposmod(clock*.38,1.0)
 var alpha := 1.0
 if h.state == HunterState.State.DEAD:
  motion = "vanish"
  progress = clampf(death_age,0.0,1.0)
  alpha = clampf(1.0-death_age/1.5,0.0,1.0)
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
 return draw_preview_body(c,"approach",floor,tint,motion,progress,reduced,heading)

func draw(c,h,clock: float,death_age: float,heading=Vector2.RIGHT,reduced=false,moving=false,turn=0.0,release=0.0):
 var changing=h.state==HunterState.State.TRANSFORM
 var progress=1.0-h.transform_remaining/BossCatalog.TRANSFORM_SECONDS if changing else 1.0
 var dead=h.state==HunterState.State.DEAD
 var alpha=clampf(1.0-death_age/1.5,0,1) if dead else clampf(progress*2,0,1)
 var p=OFFSET+h.position+Vector2(0,-14+sin(clock*3)*3)
 if dead and death_age>1.8: return
 # Smoke wreath curls with time, expanding through the transformation and death.
 for i in range(7 if reduced or (preview_enabled and CinematicQuality.detail(c)==0) else 18):
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
 var drawn := draw_preview_body(c,"transformed",p+Vector2(0,34)+fall,tint,preview_motion,preview_progress,reduced or (preview_enabled and CinematicQuality.reduced_motion(c)),heading)
 if not drawn:
  c.draw_texture_rect(robes[int(clock*6)%4],Rect2(p+Vector2(-42,-76)+fall,Vector2(84,110*stretch)),false,tint)
 var handed=preview_projection if drawn else -1.0 if heading.x<-.15 else 1.0
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
  c.draw_arc(p,53,-1.9,angle,32,Color(1,.57,.66,(1-h.boss_action_age/.4)*alpha),4)
 elif drawn and c.model.wrath.ability=="scythe_slash":
  var charge:=1.0-float(c.model.wrath.warning)/float(ReaperWrath.ABILITIES.scythe_slash.warning)
  angle=(-.28-1.13*charge)*handed
 if not drawn or c.model.wrath.scythe.is_empty():
  c.draw_set_transform(p+Vector2(23*handed,-23)+fall,angle,Vector2(handed,1))
  c.draw_texture_rect(weapon,Rect2(-20,-61,62,105),false,tint)
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
