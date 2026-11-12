extends SceneTree
# Independent presentation contract tests. Art quality is assessed by real renders.
const Materials=preload("res://scripts/gothic_theme.gd")
const Presence=preload("res://scripts/visual_presence.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL QA: "+label)
func fixture(stage="stage_1"):
 var m=MatchModel.new();m.reset(53);m.configure_match("hell");m.configure_stage(stage)
 for r in m.rooms:r.owner=r.index;r.sleeping=true;r.closed=true;r.alive=true
 m.player_room=0;m.time=m.preparation+1;m.bot_claimed=5
 m.player_position=m.player().bed_position()
 return m
func signature(m):
 var rooms=[]
 for r in m.rooms:rooms.append([r.owner,r.alive,r.sleeping,r.door_hp,r.gold,r.electricity,r.buildings.duplicate(true),r.damage_dealt,r.door_damage_taken,r.construction_actions])
 return [m.random.state,m.time,m.running,m.result,m.eliminations,m.hunter.position,m.hunter.state,m.hunter.target,m.hunter.hp,m.hunter.cooldown,m.hunter.damage,m.hunter.interval,m.hunter.speed,m.hunter.windup_remaining,m.hunter.boss_cooldowns.duplicate(true),rooms,m.projectiles.duplicate(true),m.presentation_events.duplicate(true),m.items.timers.duplicate(true),m.items.events.duplicate(true)]
func luminance(c):
 var v=c.srgb_to_linear()
 return .2126*v.r+.7152*v.g+.0722*v.b
func contrast(a,b):return (maxf(luminance(a),luminance(b))+.05)/(minf(luminance(a),luminance(b))+.05)
func materials():
 var theme=Materials.make_theme(load("res://assets/fonts/Interface.ttf"))
 var images=[]
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style=theme.get_stylebox(state,"Button")
  check(style is StyleBoxTexture,"actual layered material for "+state)
  check(style.texture!=null,"real material texture")
  var im=style.texture.get_image()
  check(im.get_width()>=32 and im.get_height()>=32,"material has actual pixel detail")
  check(im.get_pixel(128,64)!=im.get_pixel(8,8) and im.get_pixel(128,20)!=im.get_pixel(128,100),"surface has depth and edge variation")
  var foreground=theme.get_color("font_disabled_color" if state=="disabled" else "font_color","Button")
  check(contrast(foreground,im.get_pixel(128,64))>=(3.0 if state=="disabled" else 4.5),"readable state contrast "+state)
  images.append(im.get_pixel(128,64))
 check(images[0]!=images[1] and images[1]!=images[2],"hover and press recognizable")
 var normal=Materials.surface("22292B","938876","button_normal")
 var count=Materials.materials.size()
 for i in range(50):
  check(Materials.surface("22292B","938876","button_normal")==normal,"same material reuses resource")
  Materials.make_theme(load("res://assets/fonts/Interface.ttf"))
 check(Materials.materials.size()==count,"repeated theme creation does not grow texture cache")
func presence():
 for stage in StageCatalog.STAGES:
  var m=fixture(stage.id);var p=Presence.new();var h=m.hunter
  h.state=HunterState.State.DORMANT
  var before=signature(m);p.update(.2,m)
  check(p.tension=="quiet" and p.intensity==0,"preparation is quiet")
  check(signature(m)==before,"quiet presentation cannot mutate model")
  h.state=HunterState.State.MOVE;h.target=0
  before=signature(m);p.update(.2,m)
  check(p.tension=="approach","actual movement toward a target reports approach")
  check(signature(m)==before,"approach presentation cannot mutate navigation/combat/resources")
  h.position=m.player().door_approach();h.state=HunterState.State.ATTACK
  p.update(.5,m)
  check(p.tension=="siege","real door contact reports siege")
  var toward=m.player().door_position()-h.position
  check(p.heading.dot(toward.normalized())>.9,"heading follows actual door vector on every map")
  m.player().door_hp=m.player().max_hp()*.2;p.update(.2,m)
  check(p.tension=="danger","actual damaged owned door produces danger")
  # Freeze must not continue turning/stepping while the model is immobilized.
  m.items.frozen_delta=.2
  p.heading=Vector2.RIGHT
  var frozen_clock=p.clock;var frozen_heading=p.heading
  before=signature(m);p.update(.2,m)
  check(p.clock==frozen_clock and p.heading.is_equal_approx(frozen_heading),"freeze holds actor animation clock/facing")
  check(signature(m)==before,"freeze presentation never changes item or attack progression")
  m.items.frozen_delta=0
  m.running=false
  var paused=[p.clock,p.heading,p.intensity,p.scars.duplicate(true)]
  p.update(.5,m)
  check([p.clock,p.heading,p.intensity,p.scars]==paused,"paused presentation holds gameplay-dependent state")
  m.running=true
  # Local relief is truthful even while the Hunter is still alive elsewhere.
  h.target=1;h.state=HunterState.State.MOVE;h.position=m.rooms[1].corridor_anchor()
  p.update(.1,m)
  check(p.tension=="relief","leaving immediate player threat creates brief local relief")
  # Genuine events create bounded match-local history; fake deaths/breaches do not.
  p.reset();h.state=HunterState.State.MOVE;h.target=1
  m.record_event("door_break",1);m.record_event("elimination",1)
  p.update(.1,m)
  check(p.scars.is_empty(),"false intact-door/living-survivor callbacks cannot scar room")
  h.target=0;m.hunter._damage_door(m.player(),m,10)
  p.update(.1,m)
  check(p.scars.any(func(s):return s.kind=="door_damage" and s.room==0),"actual damage leaves a door history")
  m.rooms[1].door_hp=0;m.rooms[1].alive=false;m.rooms[1].sleeping=false
  m.record_event("door_break",1);m.record_event("elimination",1)
  before=signature(m);p.update(.1,m)
  check(p.tension=="elimination","actual eliminated survivor produces tension")
  check(signature(m)==before,"aftermath does not invent damage/deaths or rewards")
  var amount=p.scars.size();p.update(.1,m)
  check(p.scars.size()==amount,"repeated callback observation does not duplicate scars")
  check(p.tension=="elimination","elimination emphasis survives more than a single frame")
  for i in range(600):
   m.items.emit_item("trap",m,20,"explode")
   p.update(.01,m)
  check(p.scars.size()<=Presence.MAX_SCARS and p.seen.size()<=512,"decal and observation state remain bounded under event pressure")
  check(not JSON.stringify(PlayerProfile.new()._reward_snapshot()).contains("scars"),"visual history is not stored in profile progression")
  p.reset();check(p.scars.is_empty() and p.seen.is_empty(),"match reset clears scars")
  p.update(.1,fixture(stage.id));check(p.scars.is_empty(),"new model cannot inherit old scars")
func priority():
 var m=fixture();var p=Presence.new()
 m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=m.player().door_approach()
 m.player().door_hp=m.player().max_hp()*.2
 for i in range(20):p.update(.1,m)
 check(p.tension=="danger" and is_equal_approx(p.intensity,1),"immediate player danger reaches its full truthful emphasis")
 m.rooms[1].alive=false;m.rooms[1].sleeping=false;m.rooms[1].door_hp=0
 m.record_event("elimination",1)
 p.update(.1,m)
 check(p.tension=="danger" and is_equal_approx(p.intensity,1),"teammate death cannot override immediate player danger")
func actual_animation():
 var m=fixture("stage_4")
 var p=load("res://scripts/dorm_presentation.gd").new()
 p.update(.1,m)
 m.running=false
 var before=[p.hunter_clock,p.attack_pose]
 p.update(.5,m)
 check([p.hunter_clock,p.attack_pose]==before,"actual Hunter/Reaper sprite clocks stop while paused")
 m.running=true;m.items.frozen_delta=.3
 before=[p.hunter_clock,p.attack_pose]
 p.update(.3,m)
 check([p.hunter_clock,p.attack_pose]==before,"actual Hunter/Reaper sprite clocks stop while frozen")
func run():
 materials();presence();priority();actual_animation()
 print("VISUAL_IDENTITY_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
