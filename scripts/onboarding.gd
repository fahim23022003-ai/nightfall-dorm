extends Control
# One application-lifetime opening; tutorial uses the real model and controls.
var game
var elapsed=0.0
var phase="cinematic"
var step=0
var active=true
var start_position=Vector2.ZERO
var repair_baseline=0
var upgraded=false
var damage_observed=false
var threat_started=false
var tutorial_finished=false
var objective
var action_feedback: Label
var progress
var continue_button
var sounds_seen={}
var welcome_dismissed=false
var welcome_close: Button
const TITLES=["MOVE","FIND A ROOM","SLEEP","GOLD ECONOMY","ELECTRICITY","BUILD A DEFENSE","UPGRADE AND REPAIR","SURVIVE A SIMPLE THREAT","TUTORIAL COMPLETE"]
const NOTES=["Move with WASD / arrows toward the glowing room.","Walk inside the glowing empty room. Press E to claim it.","Approach the glowing bed. Press E to sleep: the door locks and Gold starts.","Watch Gold rise while sleeping. Gold pays for buildings, upgrades and repairs.","Build [B] → Dynamo. It produces Electricity; it does not attack.","Build a Needle near the glowing door. Select it to see its real range [O]. Dynamos do not shoot.","Select your Needle. Upgrade once, then repair the damaged door [R].", "Survive the practice Hunter. Your turret attacks automatically; watch door HP.","Practice won! Next: Stage 1 on Normal. Real matches earn Rank XP and RM Cash; practice never does."]
func _init(owner):game=owner
func _ready():
 theme=GothicTheme.make_theme(game.ui.default_font)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 size=Vector2(1280,720)
 if game.profile.tutorial_completed:show_title()
 else:show_opening()
func primary_button(button: Button):
 for state in ["normal","hover","pressed","disabled","focus"]:button.add_theme_stylebox_override(state,GothicTheme.surface("22292B","B49C6E","primary_"+state))
func clean_controls():
 for child in get_children():child.queue_free()
func show_opening():
 clean_controls();phase="cinematic";elapsed=0;active=true
 game.mode="intro"
 game.audio_system.begin_cinematic()
 var b=Button.new();b.text="Skip opening · Space / Enter / Esc";b.position=Vector2(800,645);b.size=Vector2(430,42);b.pressed.connect(skip);add_child(b)
func is_welcome_open() -> bool:return active and phase=="title" and not welcome_dismissed
func skip():
 if phase!="cinematic":return
 show_title()
func show_title():
 if welcome_dismissed:
  cancel_intro_audio();game.audio_system.end_cinematic();clean_controls();active=false;phase="idle";mouse_filter=Control.MOUSE_FILTER_IGNORE;game.return_menu();return
 phase="title";elapsed=0;active=true;cancel_intro_audio();game.audio_system.end_cinematic();game.mode="menu"
 clean_controls();mouse_filter=Control.MOUSE_FILTER_STOP
 var shade=ColorRect.new();shade.color=Color(.015,.02,.03,.82);shade.size=Vector2(1280,720);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
 var panel=Panel.new();panel.position=Vector2(260,128);panel.size=Vector2(760,472);panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",game.ui.style("172839","B49C6E"));add_child(panel)
 game.ui.label_at("Welcome to Nightfall Dorm",Vector2(305,177),36,620,true,self)
 game.ui.label_at("Created by Fahim",Vector2(307,245),24,630,false,self).modulate=Color("E6CEAA")
 var story=game.ui.label_at("You escaped the darkness...\nBut the nightmare followed you.\n\nFind a room. Lock the door.\nSurvive the night.",Vector2(308,308),23,650,false,self)
 story.size.y=210
 game.ui.label_at("Close this welcome to enter the dorm.",Vector2(308,549),16,630,false,self).modulate=Color("B7C6C7")
 welcome_close=Button.new();welcome_close.name="WelcomeClose";welcome_close.text="×";welcome_close.position=Vector2(945,145);welcome_close.size=Vector2(56,56);welcome_close.add_theme_font_size_override("font_size",34);welcome_close.tooltip_text="Close welcome";welcome_close.pressed.connect(close_welcome);add_child(welcome_close)
 for property in ["focus_next","focus_previous","focus_neighbor_left","focus_neighbor_right","focus_neighbor_top","focus_neighbor_bottom"]:welcome_close.set(property,NodePath("."))
 primary_button(welcome_close);welcome_close.grab_focus();queue_redraw()
func close_welcome():
 if not is_welcome_open():return
 welcome_dismissed=true;active=false;phase="idle";mouse_filter=Control.MOUSE_FILTER_IGNORE;clean_controls();game.mode="menu";game.ui.show_menu();queue_redraw()
 if is_instance_valid(game.ui.menu_start):game.ui.menu_start.grab_focus()
func cancel_intro_audio():
 if is_instance_valid(game.audio_system):game.audio_system.stop_events(["intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","door_break"])
func begin_tutorial():
 cancel_intro_audio()
 clean_controls();phase="tutorial";active=true;step=0;continue_button=null;repair_baseline=0;upgraded=false;damage_observed=false;threat_started=false;tutorial_finished=false
 start_position=game.model.player_position
 var panel=Panel.new();panel.position=Vector2(20,145);panel.size=Vector2(330,176);panel.add_theme_stylebox_override("panel",game.ui.style("172839","E5C77D"));panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
 progress=Label.new();progress.position=Vector2(36,155);progress.size=Vector2(298,40);progress.add_theme_font_size_override("font_size",15);add_child(progress)
 objective=Label.new();objective.position=Vector2(36,200);objective.size=Vector2(298,84);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;objective.add_theme_font_size_override("font_size",17);add_child(objective)
 var b=Button.new();b.text="Recover / reopen build controls";b.position=Vector2(22,330);b.size=Vector2(325,38);b.pressed.connect(recover);add_child(b)
 action_feedback=game.ui.label_at("",Vector2(36,286),13,296,false,self);action_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;action_feedback.size.y=34;action_feedback.modulate=Color("EFADAE")
 var skip_button=Button.new();skip_button.text="Skip practice · no rewards";skip_button.position=Vector2(22,372);skip_button.size=Vector2(325,34);skip_button.pressed.connect(skip_tutorial);add_child(skip_button)
 if game.profile.tutorial_completed:
  var exit=Button.new();exit.text="Exit practice";exit.position=Vector2(22,414);exit.size=Vector2(325,36);exit.pressed.connect(finish_replay);add_child(exit)
 refresh_objective()
func defense_ready(r) -> bool:
 return r!=null and r.buildings.keys().any(func(tile):return r.buildings[tile].kind in ["turret","heavy"] and r.tile_position(tile).distance_to(r.door_approach())<=BuildingStats.weapon_stats(game.model,r,r.buildings[tile]).range*game.model.hunter.nightmare.range_factor(r.index))
func free_practice_pad(r):
 var nearest=0;var distance=1e20
 for tile in range(r.tile_count()):
  var d=r.tile_position(tile).distance_to(r.door_approach())
  if d<distance:distance=d;nearest=tile
 if r.buildings.has(nearest):r.sell_building(nearest)
 game.selected_tile=nearest
 objective.text="A practice pad near the door is ready. Click its glow, then BUILD a Needle turret in the bottom panel."
func recover():
 if phase!="tutorial":return
 game.model.running=true
 game.pending_build=""
 game.ui.show_match()
 if game.model.player()!=null:
  game.model.player().gold=maxf(game.model.player().gold,500)
  game.model.player().electricity=maxf(game.model.player().electricity,40) if step>=5 else game.model.player().electricity
  if step>=7:game.model.player().door_hp=maxf(game.model.player().door_hp,game.model.player().max_hp()*.8)
  if step>=5 and not defense_ready(game.model.player()):
   free_practice_pad(game.model.player())
   if step>=7:
    step=5;threat_started=false;game.model.result="";game.model.hunter.state=HunterState.State.DORMANT;refresh_objective()
  elif step==4 and game.model.player().buildings.size()>=game.model.player().tile_count():free_practice_pad(game.model.player())
 if step in [4,5]:
  var room=game.model.player()
  if room!=null:
   var best=-1;var distance=1e20
   for tile in range(room.tile_count()):
    if room.buildings.has(tile):continue
    var d=room.tile_position(tile).distance_to(room.door_approach())
    if d<distance:best=tile;distance=d
   if best>=0:game.selected_tile=best;game.ui.open_context()
 elif step==6:
  for tile in game.model.player().buildings:
   if game.model.player().buildings[tile].kind in ["turret","heavy"]:game.selected_tile=tile;game.ui.open_context();break
func skip_tutorial():
 if phase!="tutorial":return
 if game.profile.complete_tutorial():finish_replay()
 elif is_instance_valid(objective):objective.text="Cannot save the skip choice. Retry or keep practicing."
func finish_replay():
 active=false;phase="idle";game.tutorial_active=false;clean_controls();game.return_menu();queue_redraw()
func next_step():
 step+=1;game.audio_event("tutorial_step");refresh_objective()
func refresh_objective():
 if is_instance_valid(progress):progress.text="FIRST NIGHT · %d / 9\n%s" % [step+1,TITLES[step]]
 if is_instance_valid(objective):objective.text="Upgrade confirmed. Now repair the damaged door [R]." if step==6 and upgraded else NOTES[step]
func save_completion():
 if step!=8:return
 if not game.profile.complete_tutorial():
  objective.text="Tutorial complete. Saving failed; keep this window open and press Save completion to retry."
  return
 tutorial_finished=true;game.audio_event("tutorial_complete");finish_replay()
func tutorial_tick(delta):
 var m=game.model;var r=m.player()
 if step<7:
  m.preparation=m.time+10000
  m.bot_claimed=5
 if r!=null:
  r.gold=maxf(r.gold,150) if step>=4 and step<=6 else r.gold
  if not r.alive:
   r.alive=true;r.closed=true;r.sleeping=true;r.door_hp=r.max_hp();m.result="";threat_started=false;m.hunter.state=HunterState.State.DORMANT
  if step>=7 and r.door_hp<r.max_hp()*.2:r.door_hp=r.max_hp()*.8
 match step:
  0:
   if m.player_position.distance_to(start_position)>45:next_step()
  1:
   if r!=null:next_step()
  2:
   if r!=null and r.sleeping:next_step()
  3:
   if r!=null and r.income_total>=3:next_step()
  4:
   if r!=null and r.buildings.values().any(func(b):return b.kind=="generator") and r.electricity>0:next_step()
  5:
   if defense_ready(r):
    r.door_hp=r.max_hp()*.65;r.gold=maxf(r.gold,500);r.electricity=maxf(r.electricity,100);repair_baseline=r.repair_actions;next_step()
  6:
   if r!=null:
    var before=upgraded;upgraded=r.buildings.values().any(func(b):return b.kind in ["turret","heavy"] and b.level>=2)
    if before!=upgraded:refresh_objective()
    if upgraded and r.repair_actions>repair_baseline:next_step()
  7:
   m.preparation=maxf(m.preparation,m.time-25)
   if not defense_ready(r):
    step=5;threat_started=false;m.result="";m.hunter.state=HunterState.State.DORMANT;refresh_objective();return
   if not threat_started:
    threat_started=true;m.preparation=m.time-1
    m.hunter.hp=100;m.hunter.max_hp=100;m.hunter.target=r.index;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=.1;m.hunter.boss_policy.enabled=false
   damage_observed=damage_observed or m.hunter.attacks>0
   if m.result=="victory" and r.shots>0 and damage_observed:
    m.result="";m.running=false;game.pending_build="";game.ui.close_context();next_step()
    var b=Button.new();b.text="Save completion & enter menu";b.position=Vector2(420,565);b.size=Vector2(440,48);b.pressed.connect(save_completion);add_child(b)
    continue_button=b;primary_button(b)
func _process(delta):
 if not active:return
 if phase in ["cinematic","title"]:
  elapsed+=minf(delta,.25)
  if phase=="cinematic":
   for entry in [[.2,"intro_running"],[3.0,"intro_running"],[5.8,"intro_running"],[8.6,"intro_running"],[.5,"intro_breath"],[3.7,"intro_breath"],[6.9,"intro_breath"],[4.3,"intro_lightning"],[4.7,"intro_whisper"],[8.8,"door_break"],[10.7,"intro_impact"],[13.0,"intro_shriek"]]:
    var key=str(entry[0])+entry[1]
    if elapsed>=entry[0] and not sounds_seen.has(key):sounds_seen[key]=true;game.audio_event(entry[1])
   if elapsed>=15:show_title()
  # Welcome deliberately has no timer dismissal. Only its X closes it.
 elif phase=="tutorial":
  tutorial_tick(delta)
  if is_instance_valid(action_feedback):action_feedback.text=game.ui.feedback_text if game.presentation.clock<game.ui.feedback_until and game.ui.feedback_text not in ["Defense improved!",""] else ""
 queue_redraw()
func _input(event):
 if is_welcome_open():
  if event is InputEventKey:
   # Let the focused X handle its standard GUI accept action, including Space.
   if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_TAB] and get_viewport().gui_get_focus_owner()==welcome_close:return
   get_viewport().set_input_as_handled()
  return
 if phase=="cinematic" and ((event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)):
  skip();get_viewport().set_input_as_handled()
func text(value,pos,size,color=Color.WHITE):
 draw_string(game.ui.default_font,pos,value,HORIZONTAL_ALIGNMENT_CENTER,-1,size,color)
func heading(value,pos,size,color=Color.WHITE):
 var width=game.ui.horror_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 draw_string(game.ui.horror_font,pos-Vector2(width*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw():
 if not active or phase=="title":return
 if phase=="tutorial":
  var m=game.model;var r=m.player();var target=m.rooms[0].door_position() if r==null else r.bed_position() if step<=3 else r.door_position()
  if step in [4,5] and r!=null:
   var nearest=-1;var distance=1e20
   for i in range(r.tile_count()):
    if r.buildings.has(i):continue
    var d=r.tile_position(i).distance_to(r.door_position())
    if d<distance:distance=d;nearest=i
   if nearest>=0:target=r.tile_position(nearest)
  if step==6 and r!=null:
   target=r.door_position()
   if not upgraded:
    for tile in r.buildings:
     if r.buildings[tile].kind in ["turret","heavy"]:target=r.tile_position(tile);break
  elif step==7:target=m.hunter.position
  var q=game.get_canvas_transform()*(target+game.MAP_OFFSET)
  q=q.clamp(Vector2(375,120),Vector2(1220,595))
  if step<8:draw_arc(q,26+sin(Time.get_ticks_msec()*.004)*4,0,TAU,32,Color("FFE39C"),3)
  if step<8:draw_line(q+Vector2(0,-60),q+Vector2(0,-32),Color("FFE39C"),4)
  if step<8:draw_colored_polygon(PackedVector2Array([q+Vector2(0,-25),q+Vector2(-8,-38),q+Vector2(8,-38)]),Color("FFE39C"))
  if step==8:
   draw_rect(Rect2(380,220,520,300),Color("172839"));heading("TUTORIAL COMPLETE",Vector2(640,310),32,Color("FFE39C"));text("Your first night begins with preparation.",Vector2(440,370),20)
  return
 draw_rect(Rect2(0,0,1280,720),Color("080D19"))
 var t=elapsed
 var motion=t if phase=="cinematic" else 15+t*.15
 for i in range(13):
  var x=fposmod(i*137-motion*34,1500)-100
  draw_line(Vector2(x,0),Vector2(x-40,610),Color(.05,.10,.14),28)
  draw_colored_polygon(PackedVector2Array([Vector2(x-90,360),Vector2(x+15,25),Vector2(x+95,360)]),Color(.025,.06,.08))
 draw_circle(Vector2(1040,100),60,Color(.5,.64,.75,.25))
 var reduced=game.profile.settings.reduced_effects
 for i in range(4 if reduced else 9):
  var q=Vector2(fposmod(i*200+motion*22,1500)-100,450+sin(i+motion*.3)*65)
  fog_ellipse(q,Vector2(200,55),Color(.4,.53,.6,.035))
 if phase=="title":
  draw_rect(Rect2(0,0,1280,720),Color(0,0,0,.65))
  heading("Welcome to NightFall Dorm",Vector2(640,255),46,Color("CF6574"))
  text("Created by Fahim",Vector2(485,320),30,Color("F0D7B5"))
  var lines=["You escaped the darkness...","But the nightmare followed you.","Find a room. Lock the door.","Survive the night."]
  for i in range(lines.size()):
   if t>=i*.35:text(lines[i],Vector2(450,390+i*40),23,Color("D8E4E9"))
  return
 var player=Vector2(280+t*44,495+sin(t*19)*5)
 if t>=8:
  var approach=clampf((t-8)/2.5,0,1)
  draw_rect(Rect2(800,170,370,420),Color("182532"));draw_colored_polygon(PackedVector2Array([Vector2(750,175),Vector2(980,50),Vector2(1220,175)]),Color("223544"))
  draw_rect(Rect2(910,380,95,210),Color("070B10"))
  heading("DORMITORY",Vector2(980,270),23,Color("83989C"))
  player=Vector2(632,495).lerp(Vector2(958,520),approach)
  if t>=10.3:
   var closed=clampf((t-10.3)/.2,0,1)
   draw_rect(Rect2(910,380,95*closed,210),Color("424E57"))
   if closed>=1:draw_line(Vector2(915,385),Vector2(1000,585),Color("79808A"),3)
 if t<10.5:
  var frame=game.presentation.cartoon.get("player_right_"+str(int(t*11)%4))
  if frame!=null:draw_texture_rect(frame,Rect2(player-Vector2(40,76),Vector2(80,96)),false)
 var hunter=Vector2(player.x-195,470) if t<8 else Vector2(437+521*clampf((t-8)/2.7,0,1),470)
 var texture=game.presentation.cartoon.get("hunter_move")
 if texture!=null:draw_texture_rect(texture,Rect2(hunter-Vector2(55,90),Vector2(110,140)),false,Color(.23,.26,.35) if t<4 else Color(.8,.85,1))
 draw_circle(hunter+Vector2(-9,-49),3,Color("FF6678"));draw_circle(hunter+Vector2(9,-49),3,Color("FF6678"))
 if t>4.3 and t<4.5 and not reduced:draw_rect(Rect2(0,0,1280,720),Color(.5,.65,.8,.16))
 if t>10.7 and t<11.1:draw_arc(Vector2(958,485),40+(t-10.7)*160,0,TAU,40,Color(.9,.6,.5,.65),4)
 if t>=12:draw_rect(Rect2(0,0,1280,720),Color(0,0,0,clampf((t-12)/2,0,1)))
func fog_ellipse(center: Vector2,radius: Vector2,color: Color):
 var pts=PackedVector2Array()
 for i in range(40):pts.append(center+Vector2(cos(i*TAU/40),sin(i*TAU/40))*radius)
 draw_colored_polygon(pts,color)
