extends Control
# One application-lifetime opening; tutorial uses the real model and controls.
var game
var elapsed=0.0
var phase="cinematic"
var step=0
var active=true
var start_position=Vector2.ZERO
var upgraded=false
var damage_observed=false
var threat_started=false
var tutorial_finished=false
var objective
var progress
var continue_button
var sounds_seen={}
const TITLES=["MOVE","FIND A ROOM","SLEEP","GOLD ECONOMY","ELECTRICITY","BUILD A DEFENSE","UPGRADE AND REPAIR","SURVIVE A SIMPLE THREAT","TUTORIAL COMPLETE"]
const NOTES=["WASD or arrow keys: move toward the glowing marker.","Walk into the highlighted empty room. Press E to claim it.","Walk to the glowing bed. Press E to sleep and lock your door.","Sleep to earn Gold. Use Gold to build and upgrade. Watch the Gold counter increase.","Click a floor pad, choose Dynamo, then Confirm placement. The Dynamo produces Electricity, separately from Gold.","Use the glowing pad near your door. Build a Needle turret in range. A distant turret cannot defend this door; sell and rebuild it, or use Recover.","Click your turret and upgrade it once. Then press R to repair the damaged door.","Your practice Hunter is weak. Watch the door take a hit and your turret fire. Your practice resources and stored items are separate.","You are ready. Claim a room, sleep, build defenses and survive the night."]
func _init(owner):game=owner
func _ready():
 theme=GothicTheme.make_theme(game.ui.default_font)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 size=Vector2(1280,720)
 show_opening()
func primary_button(button: Button):
 for state in ["normal","hover","pressed","disabled","focus"]:button.add_theme_stylebox_override(state,GothicTheme.surface("22292B","B49C6E","primary_"+state))
func clean_controls():
 for child in get_children():child.queue_free()
func show_opening():
 clean_controls();phase="cinematic";elapsed=0;active=true
 game.mode="intro"
 var b=Button.new();b.text="Skip opening · Space / Enter / Esc";b.position=Vector2(800,645);b.size=Vector2(430,42);b.pressed.connect(skip);add_child(b)
func skip():
 if phase not in ["cinematic","title"]:return
 cancel_intro_audio();active=false;phase="idle";clean_controls();queue_redraw()
 if game.profile.tutorial_completed:game.return_menu()
 else:game.start_tutorial()
func show_title():
 phase="title";elapsed=0;cancel_intro_audio();game.audio_event("intro_whisper")
 clean_controls()
 var b=Button.new();b.text="Continue · Enter / Space";b.position=Vector2(420,605);b.size=Vector2(440,48);b.pressed.connect(skip);add_child(b)
 primary_button(b)
func cancel_intro_audio():
 if is_instance_valid(game.audio_system):game.audio_system.stop_events(["intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper"])
func begin_tutorial():
 cancel_intro_audio()
 clean_controls();phase="tutorial";active=true;step=0;upgraded=false;damage_observed=false;threat_started=false;tutorial_finished=false
 start_position=game.model.player_position
 var panel=Panel.new();panel.position=Vector2(20,95);panel.size=Vector2(330,270);panel.add_theme_stylebox_override("panel",game.ui.style("172839","E5C77D"));panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
 progress=Label.new();progress.position=Vector2(36,111);progress.size=Vector2(298,30);add_child(progress)
 objective=Label.new();objective.position=Vector2(36,155);objective.size=Vector2(298,170);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;objective.add_theme_font_size_override("font_size",17);add_child(objective)
 var b=Button.new();b.text="Recover / reopen build controls";b.position=Vector2(22,374);b.size=Vector2(325,38);b.pressed.connect(recover);add_child(b)
 if game.profile.tutorial_completed:
  var exit=Button.new();exit.text="Exit practice";exit.position=Vector2(22,420);exit.size=Vector2(325,36);exit.pressed.connect(finish_replay);add_child(exit)
 refresh_objective()
func defense_ready(r) -> bool:
 return r!=null and r.buildings.keys().any(func(tile):return r.buildings[tile].kind in ["turret","heavy"] and r.tile_position(tile).distance_to(r.door_approach())<=Catalog.BUILDINGS[r.buildings[tile].kind].range)
func free_practice_pad(r):
 var nearest=0;var distance=1e20
 for tile in range(r.tile_count()):
  var d=r.tile_position(tile).distance_to(r.door_approach())
  if d<distance:distance=d;nearest=tile
 if r.buildings.has(nearest):r.sell_building(nearest)
 game.selected_tile=nearest
 objective.text="A practice pad near the door is ready. Click its glow, buy a Needle turret and confirm."
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
func finish_replay():
 active=false;phase="idle";game.tutorial_active=false;clean_controls();game.return_menu();queue_redraw()
func next_step():
 step+=1;game.audio_event("tutorial_step");refresh_objective()
func refresh_objective():
 if is_instance_valid(progress):progress.text="PRACTICE · %d / 9 · %s" % [step+1,TITLES[step]]
 if is_instance_valid(objective):objective.text=NOTES[step]
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
    r.door_hp=r.max_hp()*.65;r.gold=maxf(r.gold,500);r.electricity=maxf(r.electricity,100);next_step()
  6:
   if r!=null:
    upgraded=r.buildings.values().any(func(b):return b.kind in ["turret","heavy"] and b.level>=2)
    if upgraded and r.repair_actions>0:next_step()
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
    primary_button(b)
func _process(delta):
 if not active:return
 if phase in ["cinematic","title"]:
  elapsed+=minf(delta,.25)
  if phase=="cinematic":
   for entry in [[.2,"intro_running"],[3.0,"intro_running"],[5.8,"intro_running"],[8.6,"intro_running"],[.5,"intro_breath"],[3.7,"intro_breath"],[6.9,"intro_breath"],[4.3,"intro_lightning"],[10.7,"intro_impact"],[13.0,"intro_shriek"]]:
    var key=str(entry[0])+entry[1]
    if elapsed>=entry[0] and not sounds_seen.has(key):sounds_seen[key]=true;game.audio_event(entry[1])
   if elapsed>=15:show_title()
  elif elapsed>=4:skip()
 elif phase=="tutorial":tutorial_tick(delta)
 queue_redraw()
func _input(event):
 if phase in ["cinematic","title"] and ((event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)):
  skip();get_viewport().set_input_as_handled()
func text(value,pos,size,color=Color.WHITE):
 draw_string(game.ui.default_font,pos,value,HORIZONTAL_ALIGNMENT_CENTER,-1,size,color)
func heading(value,pos,size,color=Color.WHITE):
 var width=game.ui.horror_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 draw_string(game.ui.horror_font,pos-Vector2(width*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw():
 if not active:return
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
