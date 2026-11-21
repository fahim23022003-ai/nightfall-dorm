extends RefCounted
var heading_font=preload("res://assets/fonts/GrenzeGotisch-SemiBold.ttf")
## Read-only event presentation. Never changes gameplay or consumes model RNG.
const OFFSET=Vector2(145,40)
const MAX_ALERTS=3
const MAX_NUMBERS=12
const HUD_LANES := [Rect2(920,155,330,481),Rect2(20,218,320,418)]
const HUD_FALLBACK := Rect2(389,141,506,57)
const HUD_SPACING := 6.0
var phase16 := OS.get_environment("NIGHTFALL_PHASE16")=="1"
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
  var damage_type=str(event.get("damage_type","physical"))
  if damage_type not in ["physical","magic"]:damage_type="physical"
  var combined=false
  for n in damage_numbers:
   if n.room==index and n.get("damage_type","physical")==damage_type:
    n.damage+=damage
    n.age=0.0
    combined=true
    break
  if not combined:
   damage_numbers.append({"room":index,"position":event.position,"damage":damage,"age":0.0,"life":1.05,"damage_type":damage_type})
   if damage_numbers.size()>MAX_NUMBERS: damage_numbers.pop_front()
  door_impacts[index]={"age":0.0,"strength":clampf(damage/maxf(1,room.max_hp())*25,1,5),"damage_type":damage_type}
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
 if phase16:
  var visible: Rect2=c.presentation.visible_world_rect(c,75)
  draw_siege_marks(c,visible)
  if c.full_map:return
 else:
  draw_legacy_danger(c)
 draw_damage_numbers(c)
 if phase16:draw_breach_draft(c)
 else:draw_legacy_breaks(c)

func draw_legacy_danger(c):
 for index in danger_rooms:
  var room=c.model.rooms[index]
  var alpha=minf(1,danger_rooms[index])*0.3
  c.draw_arc(OFFSET+room.door_position()+Vector2(0,-10),42+sin(clock*7)*2,0,TAU,32,Color(1,0.25,0.2,alpha),2)
  # Also serves as a compact map indicator when the camera is zoomed out.
  c.draw_circle(OFFSET+room.center()+Vector2(100,-80),7,Color(1,0.2,0.16,alpha+0.2))
func draw_damage_numbers(c):
 for n in damage_numbers:
  var alpha=clampf((n.life-n.age)/.35,0,1)
  var geometry=damage_number_geometry(c,n)
  var point=geometry.point;var value=geometry.value;var caption=geometry.caption
  var color=Color(.8,.65,1,alpha) if geometry.magic else Color(1,.76,.48,alpha)
  var size=geometry.font_size;var width=geometry.width
  c.draw_rect(Rect2(point+Vector2(-5,-27),Vector2(width,33)),Color(.05,.07,.1,.86*alpha))
  c.draw_line(point+Vector2(-5,-27),point+Vector2(width-5,-27),color,1.5)
  c.draw_string(font,point-Vector2(0,16),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
  c.draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,2,Color(.04,.04,.07,alpha))
  c.draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func draw_legacy_breaks(c):
 for n in breaks:
  var point=OFFSET+n.position
  var alpha=1-n.age/n.life
  c.draw_arc(point,15+n.age*65,0,TAU,32,Color(1,0.35,0.16,alpha),3*alpha)
  for i in range(9):
   var direction=Vector2.from_angle(i*TAU/9)
   var shard=point+direction*(8+n.age*65)+Vector2(0,n.age*n.age*38)
   c.draw_line(shard,shard+direction*8,Color(0.75,0.45,0.28,alpha),4*alpha)

func draw_siege_marks(c,visible: Rect2):
 var reduced_motion := CinematicQuality.reduced_motion(c) or CinematicQuality.detail(c)==0
 var reduced_flash := CinematicQuality.reduced_flash(c)
 for index in danger_rooms:
  var room=c.model.rooms[index]
  var door: Vector2=OFFSET+room.door_position()
  if not visible.has_point(door):continue
  var normal: Vector2=room.door_normal()
  var tangent := normal.orthogonal()
  var fade:= minf(1.0,float(danger_rooms[index]))
  var amber:=Color("E69A71") if room.door_hp>room.max_hp()*.34 else Color("F39F9D")
  if c.full_map:
   var marker := door+normal*29
   c.draw_circle(marker,12,Color("1A1722"))
   c.draw_circle(marker,8,Color(amber,.8*fade))
   continue
  # Two jamb marks face the actual exterior without filling the doorway.
  for side in [-1,1]:
   var outer: Vector2=door+normal*12+tangent*side*32
   var edge := PackedVector2Array([outer-tangent*side*7,outer,outer+normal*17])
   c.draw_polyline(edge,Color("171821"),4)
   c.draw_polyline(edge,Color(amber,.64*fade),2)
  if not door_impacts.has(index) or reduced_flash:continue
  var hit: Dictionary=door_impacts[index]
  var age:=float(hit.age)
  var strength:=clampf(float(hit.strength)*.26,.28,1)
  var impact_color:=Color("D7B7EF") if hit.damage_type=="magic" else Color("EDC196")
  var reach := 0.0 if reduced_motion else 70.0*age
  for i in range(3):
   var head := door+normal*(12+reach)+tangent*(i-1)*(8.0+reach*.3)
   c.draw_line(head,head+normal*(5+i),Color(impact_color,(1-age/.32)*strength*.8),1.5)

func draw_breach_draft(c):
 var reduced := CinematicQuality.reduced_motion(c) or CinematicQuality.detail(c)==0
 var visible: Rect2=c.presentation.visible_world_rect(c,75)
 for event in breaks:
  var door := OFFSET+Vector2(event.position)
  if not visible.has_point(door):continue
  var normal: Vector2=c.model.rooms[event.room].door_normal()
  var tangent := normal.orthogonal()
  var age := clampf(float(event.age)/float(event.life),0,1)
  var fade := 1.0-age
  # A brief draft leaves the broken threshold. It is keyed to the break, not a
  # weather clock, and never fills the room or flashes the screen.
  for i in range(3 if reduced else 7):
   var side := float(i-1) if reduced else float(i-3)
   var distance := 10.0 if reduced else 14.0+age*(42.0+absf(side)*4.0)
   var q := door+normal*distance+tangent*side*(8.0+age*4.0)
   c.draw_line(q,q+normal*9+tangent*side,Color(.53,.42,.46,.67*fade),2)

func boss_awaken_visible() -> bool:
 return boss_banner>0 and (last_model==null or (last_model.hunter.boss_attack=="" and last_model.hunter.surge_remaining<=0))

func render_notifications(c, ui=null):
 if phase16 and ui!=null:
  draw_contextual_alerts(c,ui)
  return
 # Active counterplay warnings take priority over the decorative awakening.
 if boss_awaken_visible():
  var alpha=minf(1,boss_banner/.5)
  var box=GothicTheme.surface("583344","A28EB2").duplicate()
  box.modulate_color=Color(1,1,1,.94*alpha)
  c.draw_style_box(box,Rect2(350,139,710,75))
  c.draw_string(heading_font,Vector2(382,170),"THE GRIM REAPER HAS AWAKENED",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(1,.72,.84,alpha))
  c.draw_string(font,Vector2(384,196),"Watch the scythe. Repair during warnings. Keep your defenses firing.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.88,.82,.96,alpha))
 # Legacy screen-space notification lane.
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

func damage_number_geometry(c,n: Dictionary) -> Dictionary:
 var magic=n.get("damage_type","physical")=="magic"
 var value="-%s" % str(snappedf(n.damage,.01));var caption="MAGIC" if magic else "PHYSICAL"
 var size=16 if n.damage<40 else 19
 var width=maxf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x,font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)+10
 var normal=c.model.rooms[n.room].door_normal()
 var horizontal=absf(normal.x)>.5
 var offset=Vector2(12 if magic else -68,-90 if magic else -64)
 # Lab entrances face sideways near the upper wall: keep their two cues below
 # the doorway, outside the room and beyond the attacker's silhouette.
 if horizontal:offset=Vector2(80 if normal.x>0 else -75-width,52 if magic else 10)
 var drift=0.0 if horizontal or CinematicQuality.reduced_motion(c) else n.age*22
 var point=OFFSET+n.position+offset-Vector2(0,drift)
 var canvas=c.get_canvas_transform();var screen=canvas*(point+Vector2(-5,-27))
 var span=Vector2(width,33)*canvas.get_scale();var shift=0.0
 if screen.x<12:shift=12-screen.x
 elif screen.x+span.x>1268:shift=1268-screen.x-span.x
 point+=canvas.basis_xform_inv(Vector2(shift,0))
 return {"point":point,"rect":Rect2(point+Vector2(-5,-27),Vector2(width,33)),"value":value,"caption":caption,"font_size":size,"width":width,"magic":magic}

func notification_placements(ui) -> Array[Dictionary]:
 var placements: Array[Dictionary]=[]
 if ui.current_screen!="match" or not ui.pause_items.is_empty():
  return placements
 var occupied:=visible_hud(ui)
 var candidates:=notifications.duplicate()
 if boss_awaken_visible():
  var index := 0
  while index<candidates.size() and candidates[index].priority>=3:
   index+=1
  candidates.insert(index,{"key":"awakening","icon":"!","text":"GRIM REAPER AWAKENED — Watch the scythe. Repair during warnings.",
   "priority":3,"age":3.4-boss_banner,"life":3.4})
 for notification in candidates:
  if placements.size()>=MAX_ALERTS:break
  if _summary_duplicates(notification,ui):continue
  var is_loss: bool=notification.key.begins_with("elimination:")
  var two_lines: bool=is_loss or notification.key=="awakening"
  var card_height:=50.0 if two_lines else 31.0
  var lanes := HUD_LANES + [HUD_FALLBACK] if notification.priority>=1 else HUD_LANES
  for lane in lanes:
   var box:=Rect2(lane.position,Vector2(lane.size.x,card_height))
   var moved:=true
   while moved and box.end.y<=lane.end.y:
    moved=false
    for reserved in occupied:
     if reserved.intersects(box):
      box.position.y=reserved.end.y+HUD_SPACING
      moved=true
   if box.end.y>lane.end.y:continue
   placements.append({"box":box,"notification":notification,"loss":is_loss,"two_lines":two_lines})
   occupied.append(box)
   break
 return placements

func visible_hud(ui) -> Array[Rect2]:
 var reserved: Array[Rect2]=[]
 var controls: Array=[ui.guide_box,ui.warning_box,ui.context_box,ui.run_panel,
  ui.grid_placement_banner,ui.ward_button,ui.upgrade_notice]
 if ui.tactical_hud!=null:
  controls.append_array([ui.tactical_hud.menu,ui.tactical_hud.objective,ui.items_ui.drawer,ui.room_door_summary])
 if ui.teammates!=null:
  controls.append_array([ui.teammates.body,ui.teammates.watching])
 if ui.haunted_hud!=null:controls.append(ui.haunted_hud.banner)
 if ui.items_ui!=null:
  controls.append_array(ui.items_ui.hotbar)
  controls.append(ui.items_ui.legendary_banner)
  for label in [ui.items_ui.radar_label,ui.items_ui.feedback_label]:
   if is_instance_valid(label) and label.text!="":controls.append(label)
 var wrath=ui.game.model.wrath
 if wrath.rules_remaining>0 or wrath.production_remaining>0:
  reserved.append(Rect2(414,112,570,48))
 if not ui.game.presentation.wrath_presentation.evolution_queue.is_empty():
  reserved.append(Rect2(454,180,724,100).grow(3))
 var construction=ui.game.construction
 if construction!=null:
  controls.append_array([construction.hint,construction.status,construction.room_card,
   construction.machine_button,construction.machine_list,construction.plan_button,construction.rotate_button])
 for control in controls:
  if is_instance_valid(control) and control.is_visible_in_tree():
   reserved.append(control.get_global_rect().grow(3))
 if ui.context_open and ui.bottom_context!=null:
  # Reserve the drawer's eventual resting place while its tween is in flight.
  var drawer: Rect2=ui.bottom_context.body
  if ui.bottom_context.catalogue_layout:drawer=ui.build_catalogue.drawer_bounds()
  elif ui.bottom_context.machine_view!=null and ui.bottom_context.machine_view.plate.is_visible_in_tree():
   drawer=drawer.merge(ui.bottom_context.machine_view.plate.get_global_rect())
  reserved.append(drawer.grow(3))
 return reserved

func _summary_duplicates(entry: Dictionary,ui) -> bool:
 if not is_instance_valid(ui.warning_box) or not ui.warning_box.visible:return false
 var hunter=ui.game.model.hunter
 if hunter.target!=ui.game.model.player_room or hunter.state not in [HunterState.State.ATTACK,HunterState.State.BREACH]:
  return false
 return entry.key.ends_with(":"+str(hunter.target)) and entry.key.get_slice(":",0) in ["approach","encounter","charged","boss","surge"]

func draw_contextual_alerts(c,ui):
 if notifications.is_empty() and not boss_awaken_visible():return
 for placement in notification_placements(ui):
  var n: Dictionary=placement.notification
  var entering:=clampf(float(n.age)/.16,0,1)
  var alpha:=minf(entering,clampf((float(n.life)-float(n.age))/.45,0,1))
  var box: Rect2=placement.box
  var urgent: bool=placement.loss or n.priority>=4
  var color: Color=Color("F3A3A7") if urgent else [Color("E2C185"),Color("E9A991"),Color("F2B0AA"),Color("C5ADEB")][clampi(n.priority,0,3)]
  c.draw_rect(box,Color(.065,.084,.112,.93*alpha))
  c.draw_rect(box,Color(color,.43*alpha),false,1)
  c.draw_line(box.position,box.position+Vector2(0,box.size.y),Color(color,.95*alpha),2)
  c.draw_string(font,box.position+Vector2(13,21),n.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(color,alpha))
  var text_width:=box.size.x-46
  if placement.two_lines:
   var parts: PackedStringArray=n.text.split(" — ",true,1)
   c.draw_string(font,box.position+Vector2(36,20),parts[0],HORIZONTAL_ALIGNMENT_LEFT,text_width,14,Color(color,alpha))
   if parts.size()>1:
    c.draw_string(font,box.position+Vector2(36,39),parts[1],HORIZONTAL_ALIGNMENT_LEFT,text_width,12,Color(.97,.93,.90,alpha))
  else:
   var size:=14 if font.get_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x<=text_width else 12
   c.draw_string(font,box.position+Vector2(36,21),n.text,HORIZONTAL_ALIGNMENT_LEFT,text_width,size,Color(.97,.93,.90,alpha))
