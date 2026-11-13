class_name ConstructionControls
extends RefCounted
# Endless-only desktop workflow. The model owns validation, purchase and move locks.
var game
var kind=""
var moving=-1
var point=Vector2.ZERO
var snap=true
var planning=false
var hover=-1
var hint: Label
var status: Label
var plan_button: Button
var snap_button: Button
var move_button: Button
var ranges=true
var undo_button: Button
var range_button: Button
var last_visual: Dictionary={}
func _init(owner):game=owner
func room():
 var r=game.model.player() if game.model!=null else null
 return r if game.model.run_kind=="endless" and r!=null and r.spatial!=null else null
func applicable() -> bool:return game.mode=="match" and room()!=null and game.watched_room<0 and not game.mobile_mode
func active() -> bool:return kind!="" or moving>=0
func from_screen(screen: Vector2) -> Vector2:return game.get_viewport().get_canvas_transform().affine_inverse()*screen-game.MAP_OFFSET
func aligned(at: Vector2,fine=false) -> Vector2:
 if not snap or fine:return at
 var origin=room().door_position();return origin+((at-origin)/8).round()*8
func cancel():
 if room()!=null:game.model.cancel_building_move()
 kind="";moving=-1;hover=-1
func reset():cancel();planning=false;last_visual.clear()
func create():
 var ui=game.ui
 status=ui.label_at("",Vector2(357,143),13,300)
 plan_button=ui.button("Plan [P]",Vector2(665,140),toggle_plan,110,30)
 snap_button=ui.button("Snap 8 [F]",Vector2(782,140),toggle_snap,120,30)
 hint=ui.label_at("",Vector2(355,600),14,550);hint.size.y=42;hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 hint.add_theme_stylebox_override("normal",GothicTheme.surface("18252D","6B8B8B","button_normal"))
 move_button=ui.button("Move [V]",Vector2(840,161),begin_move,370,32,ui.context_box)
 for b in [plan_button,snap_button,move_button]:b.add_theme_font_size_override("font_size",14)
 undo_button=ui.button("Undo move [Z]",Vector2(840,2),undo,160,28,ui.context_box)
 range_button=ui.button("Range [O]",Vector2(660,2),toggle_range,160,28,ui.context_box)
 range_button.tooltip_text="Distance to eligible enemies; outside the ring is out of range. Red: invalid placement or weapons temporarily locked. Enemy eligibility still applies."
 refresh()
func toggle_range():ranges=not ranges;refresh();game.queue_redraw()
func undo():
 var ok=room().spatial.undo(game.model)
 if ok:last_visual.clear()
 game.ui.purchase(ok);refresh();game.queue_redraw()
func toggle_plan():planning=not planning;game.queue_redraw();refresh()
func toggle_snap():snap=not snap;game.queue_redraw();refresh()
func begin(building_kind: String) -> bool:
 if not applicable() or not game.model._can_purchase() or building_kind not in Catalog.BUILDINGS:return false
 var r=room()
 if r.buildings.size()>=r.tile_count():r.reject("Capacity reached. Expand your room.");game.ui.purchase(false);return false
 game.cancel_placement();kind=building_kind;point=aligned(from_screen(game.get_viewport().get_mouse_position()),Input.is_physical_key_pressed(KEY_SHIFT));refresh()
 return true
func begin_move() -> bool:
 if not applicable():return false
 var id=game.selected_tile;var r=room();var error=r.spatial.move_reason(game.model,id)
 if error!="":r.reject(error);game.ui.purchase(false);return false
 game.cancel_placement()
 if not game.model.begin_building_move(id):game.ui.purchase(false);return false
 moving=id;point=r.tile_position(id);refresh();return true
func reason() -> String:
 if not applicable():return "Return to your own Endless room"
 var r=room()
 if not game.model._can_purchase():return "Resume an active occupied room to build"
 if moving>=0:
  var error=r.spatial.move_reason(game.model,moving)
  return error if error!="" else r.spatial.geometry_reason(point,moving)
 return r.spatial.purchase_reason(kind,point) if kind!="" else "Choose a building"
func confirm(at: Vector2,fine=false) -> bool:
 if not applicable() or not active():return false
 point=aligned(at,fine);var r=room();var error=reason()
 if error!="":r.reject(error);game.ui.purchase(false);refresh();return false
 var id=moving;var before=r.tile_position(id) if id>=0 else Vector2.ZERO
 var ok=game.model.move_building(point) if moving>=0 else game.model.place_building(kind,point)
 if ok:
  if id<0:id=r.spatial.next_id-1
  else:last_visual={"id":id,"instance":int(r.buildings[id].instance_id),"from":before,"to":point,"life":.22}
  game.selected_tile=id;kind="";moving=-1
 game.ui.purchase(ok);refresh();game.queue_redraw();return ok
func handle_cancel(event) -> bool:
 if not applicable():return false
 var escape=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE
 var right=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT
 if (escape or right) and (active() or planning):
  game.cancelled_pointer=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  cancel();planning=false;game.ui.close_context();refresh();game.queue_redraw();return true
 return false
func handle(event) -> bool:
 if not applicable():
  if game.mode=="match" and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_O:toggle_range();return true
  return false
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_O:toggle_range();return true
  if event.keycode==KEY_Z:undo();return true
  if event.keycode==KEY_B:game.ui.open_build_menu();return true
  if event.keycode==KEY_V:begin_move();return true
  if event.keycode==KEY_P:toggle_plan();return true
  if event.keycode==KEY_F and (active() or planning):toggle_snap();return true
 if event is InputEventMouseMotion:
  if active():point=aligned(from_screen(event.position),event.shift_pressed)
  hover=room().spatial.hit_test(from_screen(event.position));game.queue_redraw()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var at=from_screen(event.position)
  if active():confirm(at,event.shift_pressed);return true
  var id=room().spatial.hit_test(at)
  if id>=0:game.selected_tile=id;game.ui.open_context()
  elif room().bounds().has_point(at):game.ui.open_build_menu()
  else:return false
  return true
 return false
func update(delta: float):
 if not last_visual.is_empty():
  last_visual.life=maxf(0,last_visual.life-delta)
  if last_visual.life<=0:last_visual.clear()
 if not applicable():
  if active():cancel()
  refresh();return
 if moving>=0 and room().spatial.moving_id!=moving:cancel()
 if active():point=aligned(from_screen(game.get_viewport().get_mouse_position()),Input.is_physical_key_pressed(KEY_SHIFT))
 refresh()
func refresh():
 if not is_instance_valid(status):return
 var r=room();var visible=applicable() and game.ui.current_screen=="match"
 var display=visible and (planning or active() or game.ui.context_open and game.ui.context_mode=="expansion")
 for control in [status,plan_button,snap_button]:control.visible=display
 hint.visible=visible and active()
 move_button.visible=visible and game.ui.context_open and game.ui.context_mode=="upgrade" and r.buildings.has(game.selected_tile)
 undo_button.visible=visible and game.ui.context_open and game.ui.context_mode=="upgrade"
 undo_button.disabled=not visible or r.spatial.undo_reason(game.model)!=""
 range_button.visible=game.mode=="match" and game.watched_room<0 and game.ui.context_open and game.ui.context_mode=="upgrade"
 range_button.text="Range: %s [O]" % ("ON" if ranges else "OFF")
 if not visible:return
 status.text="BUILDINGS %d / %d · %s" % [r.buildings.size(),r.tile_count(),RoomExpansion.NAMES[r.expansion_tier]]
 plan_button.text="Close plan [P]" if planning else "Plan [P]";snap_button.text="Snap 8: %s [F]" % ("ON" if snap else "OFF")
 var why=r.spatial.move_reason(game.model,game.selected_tile)
 move_button.disabled=why!="";move_button.tooltip_text=why if why!="" else "Reposition this same building; investments and cooldown remain."
 if active():
  var error=reason();hint.text=("MOVE" if moving>=0 else "BUILD "+Catalog.BUILDINGS[kind].name)+" · "+("Valid floor" if error=="" else error)+"\nClick place · Esc / right cancel · Shift fine · F snap · O range"
  hint.modulate=Color("B9E0D3") if error=="" else Color("F0B1B7")
func rendered_position(r,id: int) -> Vector2:
 if not last_visual.is_empty() and r==room() and last_visual.id==id and r.buildings.has(id) and int(r.buildings[id].instance_id)==last_visual.instance and not CinematicQuality.reduced_motion(game):return last_visual.from.lerp(last_visual.to,1-pow(last_visual.life/.22,3))
 return r.tile_position(id)
func draw_floor(c,r):
 if not applicable() or r!=room():return
 var showing=planning or active() or game.ui.context_open and game.ui.context_mode=="expansion"
 if not showing:return
 var offset=game.MAP_OFFSET
 c.draw_rect(Rect2(offset+r.bounds().position+Vector2(8,8),r.bounds().size-Vector2(16,16)),Color(.15,.42,.35,.07));c.draw_rect(Rect2(offset+r.bounds().position+Vector2(8,8),r.bounds().size-Vector2(16,16)),Color(.40,.75,.66,.65),false,2)
 for blocked in r.spatial.blocks():
  c.draw_rect(Rect2(offset+blocked.rect.position,blocked.rect.size),Color(.65,.28,.30,.13));c.draw_rect(Rect2(offset+blocked.rect.position,blocked.rect.size),Color(.70,.40,.38,.55),false,1)
 for id in r.buildings:
  var rect=SpatialConstruction.footprint(offset+r.tile_position(id));var selected=id==game.selected_tile or id==moving
  var obstructing=active() and id!=moving and SpatialConstruction.footprint(offset+point).grow(2).intersects(rect)
  c.draw_rect(rect,Color(.20,.65,.55,.12 if selected else .035));c.draw_rect(rect,Color("F08C95") if obstructing else Color(.52,.90,.77,.85 if selected else .4),false,2 if selected or obstructing else 1)
func draw_preview(c):
 if not applicable() or not active():return
 var r=room();var b=r.buildings.get(moving,{})
 var id=b.get("kind",kind);var level=int(b.get("level",1));var branch=b.get("specialization","")
 if id=="":return
 var valid=reason()=="";var color=Color("89DABD") if valid else Color("F08C95");var p=game.MAP_OFFSET+point
 c.draw_set_transform(p+Vector2(0,8),0,Vector2(1,.3));c.draw_circle(Vector2.ZERO,26,Color(.015,.025,.035,.3));c.draw_set_transform(Vector2.ZERO)
 var rect=SpatialConstruction.footprint(p)
 c.draw_style_box(game.presentation.frame(Color(color,.10),color,5),rect)
 c.draw_rect(rect.grow(2),Color(color,.95),false,2.5)
 game.presentation.building_visual.draw(c,game.presentation,id,level,p,branch,0,game.model.hunter.position-point,0,0,1.0,Color(1,1,1,.58))
 if moving>=0:
  c.draw_line(game.MAP_OFFSET+r.tile_position(moving),p,Color(color,.6),1.5)

func draw_range(c):
 if game.mode!="match" or game.watched_room>=0 or not ranges:return
 var r=game.model.player();var b={};var at=point
 if r==null:return
 if active():b=r.buildings.get(moving,{"kind":kind,"level":1,"specialization":""})
 elif game.ui.context_open and game.ui.context_mode=="upgrade" and r.buildings.has(game.selected_tile):b=r.buildings[game.selected_tile];at=r.tile_position(game.selected_tile)
 if b.is_empty() or b.kind not in DefenseEffects.WEAPONS:return
 var radius=BuildingStats.weapon_stats(game.model,r,b).range*game.model.hunter.nightmare.range_factor(r.index)
 var center=game.MAP_OFFSET+at
 var unavailable=game.model.wrath.rules_remaining>0 or r.magic_state.disrupt>0 or active() and reason()!=""
 var color=Color(.85,.35,.4,.1) if unavailable else Color(.35,.8,.77,.11)
 var poly=PackedVector2Array()
 for i in range(64):poly.append(center+Vector2.from_angle(i*TAU/64)*radius)
 c.draw_colored_polygon(poly,color);c.draw_arc(center,radius,0,TAU,96,Color(.9,.4,.45,.65) if unavailable else Color(.5,.9,.85,.65),1.5)
 if active():game.presentation.text(c,"RANGE %.0f · outside ring: out of range" % radius,center+Vector2(28,-34),10,Color("B7DED4"))
