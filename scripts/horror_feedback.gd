extends RefCounted
var heading_font=preload("res://assets/fonts/GrenzeGotisch-SemiBold.ttf")
## Read-only event presentation. Never changes gameplay or consumes model RNG.
const OFFSET=Vector2(145,40)
const MAX_ALERTS=3
const MAX_NUMBERS=12
var notifications: Array=[]
var damage_numbers: Array=[]
var door_impacts: Dictionary={}
var danger_rooms: Dictionary={}
var breaks: Array=[]
var clock=0.0
var last_event=0
var last_model
var cooldowns: Dictionary={}
var observed_counts: Dictionary={}
var eliminated_rooms: Dictionary={}
var breached_rooms: Dictionary={}
var boss_banner=0.0
var font=preload("res://assets/fonts/Interface.ttf")

func reset():
 boss_banner=0
 notifications.clear()
 damage_numbers.clear()
 door_impacts.clear()
 danger_rooms.clear()
 breaks.clear()
 cooldowns.clear()
 observed_counts.clear();eliminated_rooms.clear();breached_rooms.clear()
 last_event=0
 clock=0
 last_model=null

func update(delta: float,model):
 if not is_finite(delta) or delta<0: return
 if last_model!=null and last_model!=model: reset()
 last_model=model
 clock+=delta
 boss_banner=maxf(0,boss_banner-delta)
 for collection in [notifications,damage_numbers,breaks]:
  for item in collection: item.age+=delta
 notifications=notifications.filter(func(n): return n.age<n.life)
 damage_numbers=damage_numbers.filter(func(n): return n.age<n.life)
 breaks=breaks.filter(func(n): return n.age<n.life)
 for room in door_impacts.keys():
  door_impacts[room].age+=delta
  if door_impacts[room].age>0.32: door_impacts.erase(room)
 for room in danger_rooms.keys():
  danger_rooms[room]-=delta
  if danger_rooms[room]<=0: danger_rooms.erase(room)
 for event in model.presentation_events:
  if event.id<=last_event: continue
  last_event=event.id
  observe(event,model)

func observe(event: Dictionary,model):
 if event.type=="boss_transform":
  boss_banner=3.4
  observed_counts["boss_transform"]=int(observed_counts.get("boss_transform",0))+1
  return
 if event.type=="boss_death":
  boss_banner=0
  return
 var index=int(event.get("room",-1))
 if index<0 or index>=model.rooms.size(): return
 var room=model.rooms[index]
 if room.owner<0: return
 var kind=event.type
 if kind=="elimination":
  if room.alive or eliminated_rooms.has(index):return
  eliminated_rooms[index]=true
 if kind=="door_break":
  if room.door_hp>0 or breached_rooms.has(index):return
  breached_rooms[index]=true
 observed_counts[kind]=int(observed_counts.get(kind,0))+1
 var name=room.survivor_name()
 var room_name="Room %d" % (index+1)
 var escalation={"encounter":1,"door_break":2,"elimination":3}
 if escalation.has(kind):
  var suffix=":"+str(index)
  notifications=notifications.filter(func(n): return not (n.key.ends_with(suffix) and n.priority<int(escalation[kind])))
 if kind=="door_damage":
  var damage=float(event.get("damage",0))
  if not is_finite(damage) or damage<=0: return
  var combined=false
  for n in damage_numbers:
   if n.room==index:
    n.damage+=damage
    n.age=0.0
    combined=true
    break
  if not combined:
   damage_numbers.append({"room":index,"position":event.position,"damage":damage,"age":0.0,"life":1.05})
   if damage_numbers.size()>MAX_NUMBERS: damage_numbers.pop_front()
  door_impacts[index]={"age":0.0,"strength":clampf(damage/maxf(1,room.max_hp())*25,1,5)}
  danger_rooms[index]=2.0
 elif kind=="approach":
  alert("approach:%d" % index,"!","Hunter approaching %s!" % room_name,0,5.0)
 elif kind=="encounter":
  danger_rooms[index]=3.0
  alert("encounter:%d" % index,"!!","%s under attack · %s" % ["You are" if room.owner==0 else name+" is",room_name],1,4.0)
 elif kind=="boss_warning":
  danger_rooms[index]=float(event.delay)+0.5
  var attack=str(event.attack)
  var hint="repair now" if attack!="surge" else "keep repairing"
  alert("boss:%s:%d" % [attack,index],"!!","%s · %s · %s" % [BossCatalog.ATTACKS[attack].name.capitalize(),room_name,hint],2,0.5)
 elif kind=="boss_surge":
  danger_rooms[index]=float(event.duration)
  alert("surge:%d" % index,"!!","%s turrets silenced · repairs still work" % room_name,2,1.0)
 elif kind=="item_rescue":
  alert("rescue:%d" % index,"+","%s rescued · +%.0f door HP" % [name,event.damage],2,1.0)
 elif kind=="charged_attack":
  danger_rooms[index]=2.0
  alert("charged:%d" % index,"!!","Heavy strike · %s · repair now!" % room_name,2,1.0)
 elif kind=="door_break":
  breaks.append({"room":index,"position":event.position,"age":0.0,"life":1.0})
  if breaks.size()>6: breaks.pop_front()
  danger_rooms[index]=4.0
  alert("break:%d" % index,"X","%s door destroyed!" % room_name,4 if room.owner==0 else 2,8.0)
 elif kind=="elimination":
  danger_rooms[index]=4.0
  var remaining=model.rooms.filter(func(r):return r.owner>=0 and r.alive).size()
  alert("elimination:%d" % index,"X","SURVIVOR ELIMINATED — %s · ROOM %02d · %d SURVIVORS REMAIN" % [name,index+1,remaining],3,30.0)

func alert(key: String,icon: String,message: String,priority: int,cooldown: float):
 if clock<float(cooldowns.get(key,-1)): return
 cooldowns[key]=clock+cooldown
 for n in notifications:
  if n.key==key: return
 if notifications.size()>=MAX_ALERTS:
  var lowest=0
  for i in range(1,notifications.size()):
   if notifications[i].priority<notifications[lowest].priority: lowest=i
  if notifications[lowest].priority>priority: return
  notifications.remove_at(lowest)
 notifications.append({"key":key,"icon":icon,"text":message,"priority":priority,"age":0.0,"life":4.3 if priority>=2 else 3.2})
 notifications.sort_custom(func(a,b): return a.priority>b.priority)

func door_shake(index: int) -> Vector2:
 if not door_impacts.has(index): return Vector2.ZERO
 var hit=door_impacts[index]
 var gain=(1-hit.age/0.32)*hit.strength
 return Vector2(sin(hit.age*95),cos(hit.age*73))*gain

func render_world(c):
 for index in danger_rooms:
  var room=c.model.rooms[index]
  var alpha=minf(1,danger_rooms[index])*0.3
  c.draw_arc(OFFSET+room.door_position()+Vector2(0,-10),42+sin(clock*7)*2,0,TAU,32,Color(1,0.25,0.2,alpha),2)
  # Also serves as a compact map indicator when the camera is zoomed out.
  c.draw_circle(OFFSET+room.center()+Vector2(100,-80),7,Color(1,0.2,0.16,alpha+0.2))
 for n in damage_numbers:
  var alpha=clampf((n.life-n.age)/0.35,0,1)
  var point=OFFSET+n.position+Vector2(-12,-43-n.age*30)
  var value="-%s" % str(snappedf(n.damage,0.01))
  var size=16 if n.damage<40 else 20
  c.draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,Color(0.08,0.04,0.08,alpha))
  c.draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(1,0.42,0.32,alpha))
 for n in breaks:
  var point=OFFSET+n.position
  var alpha=1-n.age/n.life
  c.draw_arc(point,15+n.age*65,0,TAU,32,Color(1,0.35,0.16,alpha),3*alpha)
  for i in range(9):
   var direction=Vector2.from_angle(i*TAU/9)
   var shard=point+direction*(8+n.age*65)+Vector2(0,n.age*n.age*38)
   c.draw_line(shard,shard+direction*8,Color(0.75,0.45,0.28,alpha),4*alpha)

func render_notifications(c):
 # Active counterplay warnings take priority over the decorative awakening.
 if boss_banner>0 and (last_model==null or (last_model.hunter.boss_attack=="" and last_model.hunter.surge_remaining<=0)):
  var alpha=minf(1,boss_banner/.5)
  var box=GothicTheme.surface("583344","A28EB2").duplicate()
  box.modulate_color=Color(1,1,1,.94*alpha)
  c.draw_style_box(box,Rect2(285,100,710,75))
  c.draw_string(heading_font,Vector2(317,131),"THE GRIM REAPER HAS AWAKENED",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(1,.72,.84,alpha))
  c.draw_string(font,Vector2(319,157),"Watch the scythe. Repair during warnings. Keep your defenses firing.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.88,.82,.96,alpha))
 # Screen-space, left of build controls and below the tutorial panel. No input capture.
 var offset=0.0
 for i in range(notifications.size()):
  var n=notifications[i]
  var elimination=n.key.begins_with("elimination:")
  var entering=1-pow(1-clampf(n.age/0.22,0,1),3)
  var alpha=minf(entering,clampf((n.life-n.age)/0.5,0,1))
  var point=Vector2(20-(1-entering)*430,218+offset)
  var color=Color("F45A61") if elimination or n.priority>=4 else [Color("D9B65B"),Color("EF8864"),Color("F45A61"),Color("C293EE")][clampi(n.priority,0,3)]
  var panel=GothicTheme.surface("583344" if elimination or n.priority>=4 else "172839",color.to_html(false)).duplicate()
  panel.modulate_color=Color(1,1,1,alpha*.94)
  var height=56 if elimination else 33
  c.draw_style_box(panel,Rect2(point,Vector2(420,height)))
  c.draw_string(font,point+Vector2(10,22),n.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(color,alpha))
  if elimination:
   var parts=n.text.split(" — ",true,1)
   c.draw_string(font,point+Vector2(40,21),parts[0],HORIZONTAL_ALIGNMENT_LEFT,370,15,Color(1,.78,.78,alpha))
   c.draw_string(font,point+Vector2(40,43),parts[1] if parts.size()>1 else n.text,HORIZONTAL_ALIGNMENT_LEFT,370,12,Color(.96,.95,.92,alpha))
  else:c.draw_string(font,point+Vector2(40,22),n.text,HORIZONTAL_ALIGNMENT_LEFT,370,16,Color(.96,.95,.92,alpha))
  offset+=height+5
