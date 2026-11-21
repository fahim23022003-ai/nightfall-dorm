class_name NightmareLobby
extends Control
## A presentation-only offline roster. The host creates the match on launch.

signal start_requested
signal cancel_requested
signal cue_requested(cue: String)

const WAIT_SECONDS := 15.0
const TRANSITION_SECONDS := .42
const CANVAS := Vector2(1280,720)
const DISPLAY = preload("res://assets/fonts/GrenzeGotisch-SemiBold.ttf")
const TEXT = preload("res://assets/fonts/Interface.ttf")
const FACADE = preload("res://assets/visual_identity/menu_facade.svg")
const MUTED := Color("9BA9AA")
const TEXT_COLOR := Color("DAD9D0")
const IVORY := Color("EAD8AF")
const GOLD := Color("DAB77C")
const READY_COLOR := Color("A9CDB5")

var elapsed := 0.0
var loading := false
var human_ready := false
var armed := false
var active := false
var window_focused := true
var suspended := false
var _generation := 0
var _load_elapsed := 0.0
var _last_second := -1
var _ready_button: Button
var _back: Button
var _mission: Dictionary
var _difficulty := ""
var _hunter_title := ""
var _unknown_hunter := false
var _hunter: Texture2D
var _survivors: Array[Texture2D] = []
var _phases := PackedInt32Array()
var _stagger := PackedFloat32Array()

func _ready():
 name="NightmareLobby"
 size=CANVAS
 mouse_filter=Control.MOUSE_FILTER_STOP
 _ready_button=_button("READY",Rect2(490,598,300,62),true)
 _back=_button("Back",Rect2(52,610,155,47),false)
 _ready_button.name="LobbyReady"
 _back.name="LobbyBack"
 _ready_button.pressed.connect(press_ready)
 _back.pressed.connect(request_cancel)
 var window:=get_window()
 window_focused=DisplayServer.get_name()=="headless" or window.has_focus()
 window.focus_entered.connect(_focus_entered)
 window.focus_exited.connect(_focus_exited)
 _survivors.append(preload("res://assets/cartoon/player_down_0.png"))
 for index in range(5):
  _survivors.append(load("res://assets/cartoon/bot_%d.png"%index) as Texture2D)
 _refresh_controls()
 if active:
  _arm_after_present(_generation)
 else:
  hide()
 set_process(active)

func configure(mission: Dictionary, difficulty: String, staged_archetype: String, seed: int):
 _generation+=1
 _mission=mission.duplicate()
 _difficulty=str(RankCatalog.DIFFICULTIES.get(difficulty,{}).get("name","Normal"))
 _select_hunter(staged_archetype)
 var rng:=RandomNumberGenerator.new()
 rng.seed=seed
 _stagger.clear()
 _phases.clear()
 for slot in range(5):
  _stagger.append(.85+float(slot)*1.12+rng.randf_range(.0,.44))
  _phases.append(0)
 elapsed=0.0
 loading=false
 human_ready=false
 armed=false
 active=true
 _load_elapsed=0.0
 _last_second=-1
 show()
 set_process(true)
 _refresh_controls()
 queue_redraw()
 if is_node_ready():
  _arm_after_present(_generation)

func close():
 _generation+=1
 active=false
 armed=false
 loading=false
 set_process(false)
 hide()

func set_suspended(value: bool):
 if suspended!=value:
  suspended=value
  _refresh_controls()
  queue_redraw()

func _focus_entered():
 window_focused=true
 _refresh_controls()
 queue_redraw()

func _focus_exited():
 window_focused=false
 _refresh_controls()
 queue_redraw()

func _arm_after_present(generation: int):
 await get_tree().process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
 if generation!=_generation or not active:
  return
 armed=true
 _refresh_controls()
 queue_redraw()
 if window_focused and not suspended:
  _ready_button.grab_focus()
 cue_requested.emit("open")

func seconds_left() -> int:
 return ceili(maxf(0.0,WAIT_SECONDS-elapsed))

func ready_ai_count() -> int:
 return _phases.count(2)

func roster() -> Array[Dictionary]:
 var actors: Array[Dictionary]=[]
 for index in range(Catalog.SURVIVOR_NAMES.size()):
  actors.append({"name":Catalog.SURVIVOR_NAMES[index],"human":index==0,"phase":_phase_label(index).to_lower()})
 return actors

func _phase_label(index: int) -> String:
 if index==0:
  return "Ready" if human_ready else "Waiting"
 var phase:=_phases[index-1] if _phases.size()==5 else 0
 return "Ready" if phase==2 else "Joining" if phase==1 else "Standby"

func _process(delta: float):
 advance(delta)

func advance(delta: float):
 if not active or not armed or suspended or not window_focused or not is_finite(delta) or delta<=0.0:
  return
 if loading:
  _load_elapsed += delta
  if _load_elapsed+0.000001>=TRANSITION_SECONDS:
   active=false
   set_process(false)
   start_requested.emit()
  return
 elapsed=minf(WAIT_SECONDS,elapsed+delta)
 var dirty:=false
 for slot in range(_phases.size()):
  var phase:=2 if elapsed>=_stagger[slot]+.72 else 1 if elapsed>=_stagger[slot] else 0
  if phase==_phases[slot]:
   continue
  _phases[slot]=phase
  dirty=true
  if phase==2:
   cue_requested.emit("join")
 var second:=seconds_left()
 if second!=_last_second or dirty:
  _last_second=second
  queue_redraw()
 if elapsed+0.000001>=WAIT_SECONDS:
  elapsed=WAIT_SECONDS
  _phases.fill(2)
  if not human_ready:
   press_ready()
   return
 if human_ready and ready_ai_count()==5:
  _begin_loading()

func press_ready():
 if not active or not armed or human_ready or loading or suspended or not window_focused:
  return
 human_ready=true
 _refresh_controls()
 queue_redraw()
 cue_requested.emit("ready")
 if ready_ai_count()==5:
  _begin_loading()

func _begin_loading():
 loading=true
 _load_elapsed=0.0
 _refresh_controls()
 queue_redraw()

func request_cancel():
 if not active:
  return
 cue_requested.emit("back")
 close()
 cancel_requested.emit()

func _unhandled_key_input(event):
 if active and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  request_cancel()
  get_viewport().set_input_as_handled()

func _refresh_controls():
 if _ready_button==null:
  return
 _ready_button.text="ENTERING THE DORM…" if loading else "READY  ✓" if human_ready else "READY"
 _ready_button.disabled=not armed or human_ready or loading or suspended or not window_focused
 _back.disabled=not active

func _select_hunter(archetype: String):
 var spec: Dictionary=StrategyCatalog.ARCHETYPES.get(archetype,{})
 _unknown_hunter=spec.is_empty() and archetype!="reaper"
 _hunter_title="Hunter unconfirmed" if _unknown_hunter else "Grim Reaper" if archetype=="reaper" else str(spec.name)
 var path: String
 if archetype=="reaper":
  path="res://assets/visual_rebirth/grim_reaper/approach_front.png"
 else:
  path="res://assets/visual_rebirth/%s/level_01_front.png"%("stalker" if _unknown_hunter else archetype)
 if not _unknown_hunter and OS.get_environment("NIGHTFALL_LIVING_DORM")=="1":
  _hunter_title=HunterIdentity.display(archetype,archetype=="reaper")
 _hunter=load(path) as Texture2D if ResourceLoader.exists(path,"Texture2D") else null

func _button(caption: String, rect: Rect2, primary: bool) -> Button:
 var button:=Button.new()
 button.text=caption
 button.position=rect.position
 button.size=rect.size
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 button.add_theme_font_override("font",TEXT)
 button.add_theme_font_size_override("font_size",20 if primary else 16)
 button.add_theme_color_override("font_color",Color("041814") if primary else IVORY)
 button.add_theme_color_override("font_focus_color",Color("041814") if primary else IVORY)
 button.add_theme_color_override("font_hover_color",Color("041814") if primary else Color.WHITE)
 button.add_theme_color_override("font_pressed_color",Color("041814") if primary else Color.WHITE)
 button.add_theme_color_override("font_disabled_color",TEXT_COLOR)
 button.add_theme_stylebox_override("normal",_button_style(Color("218A78") if primary else Color("223038"),Color("7AD9B9") if primary else Color("647679")))
 button.add_theme_stylebox_override("hover",_button_style(Color("50B99F") if primary else Color("33434A"),Color("A3F1D6") if primary else GOLD))
 button.add_theme_stylebox_override("pressed",_button_style(Color("2D9C85") if primary else Color("19242D"),IVORY))
 button.add_theme_stylebox_override("disabled",_button_style(Color("2A3034"),Color("66666A")))
 var focus:=_button_style(Color.TRANSPARENT,Color("F4DEA8"))
 focus.set_border_width_all(2)
 focus.set_expand_margin_all(3.0)
 button.add_theme_stylebox_override("focus",focus)
 if GothicTheme.tactical_enabled():
  var role: String="primary" if primary else "quiet"
  for state in ["normal","hover","pressed","disabled","focus"]:
   button.add_theme_stylebox_override(state,GothicTheme.living_surface(role,state))
  for state in ["font_color","font_focus_color","font_hover_color","font_pressed_color"]:
   button.add_theme_color_override(state,GothicTheme.TACTICAL_COLORS.text)
 add_child(button)
 return button

func _button_style(fill: Color, edge: Color) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=fill
 style.border_color=edge
 style.set_border_width_all(1)
 style.set_corner_radius_all(4)
 return style

func _draw():
 if not active and not loading:
  return
 draw_rect(Rect2(Vector2.ZERO,CANVAS),Color("111820"))
 draw_texture_rect(FACADE,Rect2(Vector2.ZERO,CANVAS),false,Color(.24,.28,.31,.54))
 draw_rect(Rect2(Vector2.ZERO,CANVAS),Color(.04,.064,.078,.45))
 draw_rect(Rect2(38,28,1204,240),Color(.023,.042,.047,.76))
 draw_rect(Rect2(38,28,1204,240),Color("3D4D4B"),false,1.0)
 _draw_hunter()
 _draw_brief()
 for index in range(6):
  _draw_card(index)
 _draw_countdown()

func _draw_hunter():
 var panel:=Rect2(39,29,352,238)
 draw_rect(panel,GothicTheme.TACTICAL_COLORS.panel if GothicTheme.tactical_enabled() else Color("1A262B"))
 draw_rect(panel.grow(-13),Color("303838"),false,1.0)
 var center:=Vector2(218,149)
 draw_circle(center,88.0,Color(.57,.36,.20,.15))
 draw_arc(center,78.0,0.0,TAU,32,Color(.58,.39,.24,.28),1.0,true)
 draw_arc(center,89.0,0.0,TAU,32,Color(.58,.39,.24,.17),1.0,true)
 if _hunter!=null:
  _fit_texture(_hunter,Rect2(88,34,260,225),Color(.06,.075,.081,1) if _unknown_hunter else Color(1.05,1.04,1.0))
 draw_line(Vector2(54,253),Vector2(376,253),Color(.68,.52,.32,.45),1.0)

func _draw_brief():
 var chapter: String=str(_mission.get("chapter_title","Endless Mode"))
 var title: String=str(_mission.get("title","The dorm awaits"))
 var level:=int(_mission.get("level",0))
 _text("OFFLINE SESSION  ·  AI SURVIVORS",Vector2(427,65),14,GOLD)
 _text("LEVEL %02d  /  %s"%[level,chapter.to_upper()] if level>0 else chapter.to_upper(),Vector2(427,104),15,MUTED)
 draw_string(DISPLAY,Vector2(424,162),title,HORIZONTAL_ALIGNMENT_LEFT,790,56,IVORY)
 draw_line(Vector2(426,185),Vector2(1203,185),Color("5B5C51"),1.0)
 _text(_hunter_title,Vector2(427,224),22,IVORY)
 _text(_difficulty,Vector2(1054,224),16,TEXT_COLOR)

func _draw_card(index: int):
 var rect:=Rect2(40+index*202,309,190,198)
 var human:=index==0
 var phase:=int(_phases[index-1]) if not human and _phases.size()==5 else 0
 var ready:=human_ready if human else phase==2
 var edge:=GOLD if human else Color("677E70") if ready else Color("415357")
 var surface: Color=Color("1D2A32") if human else Color("18242B")
 if GothicTheme.tactical_enabled():surface=GothicTheme.TACTICAL_COLORS.card if human else GothicTheme.TACTICAL_COLORS.panel
 draw_rect(rect,surface)
 draw_rect(rect,edge,false,1.0)
 draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),edge)
 var center:=rect.position+Vector2(95,73)
 draw_circle(center,43.0,Color(.40,.50,.48,.19 if ready or human else .08))
 if index<_survivors.size():
  _fit_texture(_survivors[index],Rect2(rect.position+Vector2(56,14),Vector2(78,100)),Color.WHITE if ready or human or phase==1 else Color(.7,.72,.76,.58))
 draw_string(TEXT,rect.position+Vector2(0,133),str(Catalog.SURVIVOR_NAMES[index]),HORIZONTAL_ALIGNMENT_CENTER,190,21,IVORY if human else TEXT_COLOR)
 var status:=_phase_label(index)
 _center_text("PLAYER" if human else "AI SURVIVOR",rect.position+Vector2(0,157),190,11,MUTED)
 _center_text(status,rect.position+Vector2(0,181),190,14,READY_COLOR if ready else IVORY if phase==1 else MUTED)

func _draw_countdown():
 var y:=535.0
 draw_line(Vector2(40,y),Vector2(1240,y),Color("53604F"),1.0)
 var label:= "Loading mission…" if loading else "Countdown paused" if suspended or not window_focused else "%02d s remaining  ·  Waiting for AI"%seconds_left() if human_ready else "AUTO-READY IN %02d s"%seconds_left()
 _center_text(label,Vector2(0,577),1280,19,IVORY)
 var ready_count:=ready_ai_count()+int(human_ready)
 _text("%d / 6 READY"%ready_count,Vector2(1081,631),16,READY_COLOR if ready_count==6 else MUTED)
 if not GothicTheme.tactical_enabled():
  _text("%d / 5 AI ready"%ready_ai_count(),Vector2(1084,650),12,MUTED)

func _fit_texture(texture: Texture2D, bounds: Rect2, tint: Color):
 if texture==null:
  return
 var size_px:=texture.get_size()
 if size_px.x<=0.0 or size_px.y<=0.0:
  return
 var scale_px:=minf(bounds.size.x/size_px.x,bounds.size.y/size_px.y)
 var fitted:=size_px*scale_px
 draw_texture_rect(texture,Rect2(bounds.get_center()-fitted*.5,fitted),false,tint)

func _text(label: String, at: Vector2, font_size: int, tint: Color):
 draw_string(TEXT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,tint)

func _center_text(label: String, at: Vector2, width: float, font_size: int, tint: Color):
 draw_string(TEXT,at,label,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,tint)
