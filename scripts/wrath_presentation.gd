extends RefCounted
# Original immediate-mode animated art; bounded by ten agents and one scythe.
const O=Vector2(145,40)
var seen_event=0
var evolution_queue=[]
var banner_remaining=0.0
var last_model
var font=preload("res://assets/fonts/Interface.ttf")
func reset():
 seen_event=0;evolution_queue.clear();banner_remaining=0;last_model=null
func draw(c,clock: float):
 var m=c.model;var w=m.wrath;var reduced=c.profile.settings.get("reduced_effects",false)
 for u in m.minions:
  if u.hp<=0:continue
  var p=O+u.position;var stride=sin(clock*9+u.id)*3
  var tint=Color("A3A875") if not u.enhanced else Color("BD8EC9")
  if u.hit_flash>0:tint=Color("FFD2CC")
  if u.attack_flash>0:
   c.draw_arc(p+Vector2(0,-5),23,clock*3,clock*3+2.4,16,Color("D07F9B"),3)
   stride=8
  c.draw_circle(p+Vector2(0,-24+stride*.3),9,tint)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-15),p+Vector2(9,-15),p+Vector2(13,6),p+Vector2(-12,6)]),Color("43443F") if not u.enhanced else Color("593851"))
  c.draw_line(p+Vector2(-6,3),p+Vector2(-7+stride,13),tint,4);c.draw_line(p+Vector2(6,3),p+Vector2(7-stride,13),tint,4)
  c.draw_line(p+Vector2(-9,-12),p+Vector2(-17,-4+stride),tint,4);c.draw_line(p+Vector2(8,-12),p+Vector2(17,-8-stride),tint,4)
  c.draw_circle(p+Vector2(-3,-25+stride*.3),2,Color("E97F82"));c.draw_circle(p+Vector2(4,-25+stride*.3),2,Color("E97F82"))
  c.draw_rect(Rect2(p+Vector2(-16,-40),Vector2(32,4)),Color("221C29"));c.draw_rect(Rect2(p+Vector2(-16,-40),Vector2(32*u.hp/u.max_hp,4)),Color("AE698B"))
 for e in m.presentation_events:
  if e.type=="undead_death" and m.time-e.time<.8:
   var p=O+e.position;var age=m.time-e.time
   c.draw_set_transform(p,age*PI*.65,Vector2.ONE)
   c.draw_rect(Rect2(-9,-28,18,33),Color(.44,.36,.45,1-age/.8));c.draw_circle(Vector2(0,-35),8,Color(.7,.6,.65,1-age/.8));c.draw_set_transform(Vector2.ZERO)
 if m.hunter.phase_guard_remaining>0:c.draw_arc(O+m.hunter.position,42,0,TAU,48,Color(.95,.6,.78,.75),4)
 if m.hunter.transformed and w.phase>=2:
  var p=O+m.hunter.position
  c.draw_arc(p,38,clock,clock+TAU*.8,40,Color(.9,.13,.3,.6),3)
  for side in [-1,1]:c.draw_line(p+Vector2(side*14,-58),p+Vector2(side*24,-76),Color("B65B85"),5)
 if w.active() and w.cast_target>=0:
  var p=O+m.rooms[w.cast_target].door_position();var charge=1-w.warning/ReaperWrath.ABILITIES[w.ability].warning
  var color=Color("E9B075") if w.ability in ["soul_steal","soul_reaper"] else Color("E14B73")
  c.draw_arc(p,32,0,TAU*charge,48,color,4)
  c.draw_string(font,p+Vector2(-100,-53),ReaperWrath.ABILITIES[w.ability].name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
  if w.ability in ["soul_steal","soul_reaper"]:
   c.draw_line(O+m.hunter.position,p,Color(.8,.55,.9,.6),3)
   c.draw_circle((O+m.hunter.position).lerp(p,fmod(clock,1.0)),5,color)
  if w.ability=="scythe_slash":c.draw_arc(p,45,-PI+charge*PI,-PI+charge*PI+.8,20,color,7)
  if w.ability=="assault":
   for i in range(10):c.draw_arc(O+m.hunter.position+Vector2.from_angle(i*TAU/10)*45,8,0,TAU,12,color,2)
  if w.ability=="phantom_scream":
   for r in m.rooms:
    if not r.alive or not r.sleeping:continue
    var q=(O+m.hunter.position).lerp(O+r.door_position(),charge)
    c.draw_circle(q,11,Color(.75,.8,.9,.5));c.draw_colored_polygon(PackedVector2Array([q+Vector2(-10,0),q+Vector2(-14,19),q+Vector2(0,12),q+Vector2(13,19),q+Vector2(10,0)]),Color(.65,.68,.85,.35))
 if not w.scythe.is_empty():
  var s=w.scythe;var p=O+s.position
  c.draw_set_transform(p,s.flight*TAU if s.flight>0 else -.35,Vector2.ONE)
  c.draw_line(Vector2(0,-60),Vector2(0,50),Color("937A82"),7)
  c.draw_arc(Vector2(10,-26),40,PI,TAU*1.02,24,Color("D7C4D0"),9)
  c.draw_set_transform(Vector2.ZERO)
  if not reduced:c.draw_arc(p,44,clock,clock+PI,24,Color(.7,.12,.3,.4),3)
 if w.domain_active():
  var r=m.rooms[w.domain_room];var bounds=Rect2(O+r.bounds().position,r.bounds().size)
  c.draw_rect(bounds,Color(.3,.01,.06,.16));c.draw_rect(bounds,Color("B83E65"),false,4)
  c.draw_string(font,bounds.position+Vector2(8,-12),"CRIMSON DOMAIN · %.1fs · ONE ROOM" % w.domain_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("FFB8BD"))
 for r in m.rooms:
  if r.barrier_remaining>0:c.draw_arc(O+r.door_position(),32,-PI,0,32,Color(.45,.78,1,.75),5)
func overlay(c,m):
 var w=m.wrath;var y=132.0
 if w.rules_remaining>0:
  c.draw_string(font,Vector2(420,y),"RULES JUDGEMENT · Turrets / manual items locked %.1fs" % w.rules_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("E6B2C1"));y+=23
 if w.production_remaining>0:
  c.draw_string(font,Vector2(420,y),"FINAL JUDGEMENT · Production paused %.1fs" % w.production_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("E6B2C1"));y+=23
 if last_model!=m:seen_event=0;evolution_queue.clear();banner_remaining=0;last_model=m
 for event in m.presentation_events:
  if event.id<=seen_event:continue
  seen_event=event.id
  if event.type=="hunter_evolved":
   evolution_queue.append(event)
   if evolution_queue.size()>6:evolution_queue.pop_front()
 if not evolution_queue.is_empty():
  # Match time advances only during actual play; sequential banners never overwrite a kill.
  var event=evolution_queue[0]
  if banner_remaining<=0:banner_remaining=m.time+3.8
  if m.time>=banner_remaining:evolution_queue.pop_front();banner_remaining=0;return
  c.draw_rect(Rect2(454,180,724,100),Color(.12,.02,.06,.92))
  c.draw_string(font,Vector2(474,205),"THE HUNTER HAS EVOLVED · POWER %d" % int(event.power),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("FF859F"))
  c.draw_string(font,Vector2(474,229),"BUFF ACQUIRED: "+event.buff_name,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("FFD2B2"))
  var words=str(event.effect).split(" ");var lines=[""]
  for word in words:
   if font.get_string_size(lines[-1]+word,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x>675:lines.append("")
   lines[-1]+=word+" "
  for i in range(mini(lines.size(),2)):c.draw_string(font,Vector2(474,250+i*17),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("F4DADD"))
