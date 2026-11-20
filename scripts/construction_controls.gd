class_name ConstructionControls
extends RefCounted
# Desktop construction. The model owns validation, purchase and move locks.
const MapView=preload("res://scripts/map_presentation.gd")
var game
var kind=""
var moving=-1
var point=Vector2.ZERO
var rotation=0
var snap=true
var planning=false
var hover=-1
var hint: Label
var status: Label
var plan_button: Button
var snap_button: Button
var rotate_button: Button
var move_button: Button
var ranges=true
var undo_button: Button
var range_button: Button
var last_visual: Dictionary={}
var cursor_world := Vector2.ZERO
var room_card: Panel
var room_info: Label
var machine_button: Button
var machine_list: ItemList
var machine_rows: Array=[]
var machines_open=false
var grid_floor := Rect2()
var grid_lines := PackedVector2Array()
var grid_floor_parts: Array=[]
var current_preview_error=""
func _init(owner):game=owner
func room():
 var r=game.model.player() if game.model!=null else null
 if r==null or r.spatial==null:return null
 return r if r.spatial.grid or game.model.run_kind=="endless" else null
func applicable() -> bool:return game.mode=="match" and room()!=null and game.watched_room<0 and not game.hunter_spectating and not game.mobile_mode
func focused_grid(r) -> bool:
 return r!=null and r.spatial!=null and r.spatial.grid and applicable() and not game.full_map and r==room()
func active() -> bool:return kind!="" or moving>=0
func from_screen(screen: Vector2) -> Vector2:return game.get_viewport().get_canvas_transform().affine_inverse()*screen-game.MAP_OFFSET
func active_kind() -> String:
 return room().buildings.get(moving,{}).get("kind","") if moving>=0 else kind
func aligned(at: Vector2,fine=false) -> Vector2:
 if room().spatial.grid:return room().spatial.aligned(at,active_kind(),rotation)
 if not snap or fine:return at
 var origin=room().door_position();return origin+((at-origin)/8).round()*8
func cancel():
 if room()!=null:game.model.cancel_building_move()
 kind="";moving=-1;hover=-1;rotation=0
func reset():
 cancel();planning=false;last_visual.clear()
 machines_open=false;machine_rows.clear()
func create():
 var ui=game.ui
 status=ui.label_at("",Vector2(357,143),13,300)
 plan_button=ui.button("Plan [P]",Vector2(665,140),toggle_plan,110,30)
 snap_button=ui.button("Snap 8 [F]",Vector2(782,140),toggle_snap,120,30)
 rotate_button=ui.button("Rotate [Q]",Vector2(782,140),func():rotate(),120,30)
 hint=ui.label_at("",Vector2(355,600),14,550);hint.size.y=42;hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 hint.add_theme_stylebox_override("normal",GothicTheme.surface("18252D","6B8B8B","button_normal"))
 move_button=ui.button("Move [V]",Vector2(840,161),begin_move,370,32,ui.context_box)
 for b in [plan_button,snap_button,rotate_button,move_button]:b.add_theme_font_size_override("font_size",14)
 undo_button=ui.button("Undo move [Z]",Vector2(840,2),undo,160,28,ui.context_box)
 range_button=ui.button("Range [O]",Vector2(660,2),toggle_range,160,28,ui.context_box)
 range_button.tooltip_text="Distance to eligible enemies; outside the ring is out of range. Red: invalid placement or weapons temporarily locked. Enemy eligibility still applies."
 if ui.bottom_context!=null and ui.bottom_context.body==BottomContextPanel.SIDE_BODY:
  undo_button.text="Undo [Z]"
  for index in range(3):
   var control: Button=[range_button,move_button,undo_button][index]
   control.add_theme_font_size_override("font_size",13)
   control.position=Vector2(14+index*114,193);control.size=Vector2(108,28)
 room_card=ui.box(Rect2(20,218,320,111),"18252D","6B8B8B")
 room_info=ui.label_at("",Vector2(12,5),14,296,false,room_card)
 room_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 machine_button=ui.button("Machines",Vector2(20,341),toggle_machines,320,34)
 machine_button.tooltip_text="Open the machine list. Select a row to locate and inspect that exact building."
 machine_list=ItemList.new()
 machine_list.position=Vector2(20,383)
 machine_list.size=Vector2(320,209)
 machine_list.add_theme_font_size_override("font_size",14)
 machine_list.add_theme_stylebox_override("panel",GothicTheme.surface("18252D","6B8B8B","button_normal"))
 ui.attach(machine_list)
 machine_list.item_selected.connect(select_machine)
 machine_list.item_clicked.connect(func(index: int,_at: Vector2,button: int):
  if button==MOUSE_BUTTON_LEFT:select_machine(index))
 machines_open=false
 machine_rows.clear()
 refresh()

func toggle_machines():
 machines_open=not machines_open
 if machines_open and is_instance_valid(game.ui.run_panel):game.ui.run_panel.visible=false
 refresh()

func select_machine(index: int):
 if not focused_grid(room()) or active():return
 var entry: Array=machine_list.get_item_metadata(index)
 var id: int=entry[0]
 if int(room().buildings.get(id,{}).get("instance_id",-1))!=entry[1]:return
 if game.selected_tile==id and game.ui.context_open and game.ui.context_mode=="upgrade":return
 game.selected_tile=id
 game.ui.open_context()
 game.queue_redraw()

func refresh_machines(r,show: bool):
 machine_button.visible=show
 if show:machine_button.text="%s machines · %d" % ["Hide" if machines_open else "Find",r.buildings.size()]
 machine_list.visible=show and machines_open
 if not machine_list.visible:return
 var stale: bool=machine_rows.size()!=r.buildings.size()
 if not stale:
  for row in machine_rows:
   var b: Dictionary=r.buildings.get(row[0],{})
   if b.is_empty() or b.instance_id!=row[1] or b.kind!=row[2] or b.level!=row[3] or b.position!=row[4] or b.get("rotation",0)!=row[5]:
    stale=true
    break
 if stale:
  var origin: Vector2=r.spatial.grid_origin()
  machine_rows.clear()
  machine_list.clear()
  for id in r.buildings:
   var b: Dictionary=r.buildings[id]
   var facing:=int(b.get("rotation",0))
   var footprint:=SpatialConstruction.grid_footprint(b.position,b.kind,facing)
   var cell:=Vector2i((footprint.position-origin)/SpatialConstruction.CELL_SIZE)+Vector2i.ONE
   machine_rows.append([id,b.instance_id,b.kind,b.level,b.position,facing])
   machine_list.add_item("%s L%d · %d, %d" % [Catalog.BUILDINGS[b.kind].name,b.level,cell.x,cell.y])
   machine_list.set_item_metadata(machine_list.item_count-1,[id,b.instance_id])
   machine_list.set_item_tooltip(machine_list.item_count-1,"Top-left footprint cell · column %d, row %d" % [cell.x,cell.y])
 var selected:=machine_list.get_selected_items()
 var current:=selected[0] if not selected.is_empty() else -1
 if current>=0 and machine_list.get_item_metadata(current)[0]==game.selected_tile:return
 machine_list.deselect_all()
 for i in range(machine_rows.size()):
  if machine_rows[i][0]!=game.selected_tile:continue
  machine_list.select(i)
  machine_list.ensure_current_is_visible()
  break

func toggle_range():ranges=not ranges;refresh();game.queue_redraw()
func undo():
 if not applicable():return
 var ok=room().spatial.undo(game.model)
 if ok:last_visual.clear()
 game.ui.purchase(ok);refresh();game.queue_redraw()
func toggle_plan():planning=not planning;game.queue_redraw();refresh()
func toggle_snap():snap=not snap;game.queue_redraw();refresh()
func rotate(step: int=1):
 if not applicable() or not room().spatial.grid or not active():return
 rotation=posmod(rotation+step,4);point=aligned(cursor_world);refresh();game.queue_redraw()
func begin(building_kind: String) -> bool:
 if not applicable() or not game.model._can_purchase() or building_kind not in Catalog.BUILDINGS:return false
 var r=room()
 if not r.spatial.grid and r.buildings.size()>=r.tile_count():r.reject("Capacity reached. Expand your room.");game.ui.purchase(false);return false
 game.cancel_placement();kind=building_kind
 cursor_world=from_screen(game.get_viewport().get_mouse_position())
 if r.spatial.grid and not r.spatial.grid_bounds().has_point(cursor_world):cursor_world=r.spatial.grid_bounds().get_center()
 point=aligned(cursor_world,Input.is_physical_key_pressed(KEY_SHIFT));refresh()
 return true
func begin_move() -> bool:
 if not applicable():return false
 var id=game.selected_tile;var r=room();var error=r.spatial.move_reason(game.model,id)
 if error!="":r.reject(error);game.ui.purchase(false);return false
 game.cancel_placement()
 if not game.model.begin_building_move(id):game.ui.purchase(false);return false
 moving=id;point=r.tile_position(id);cursor_world=point;rotation=int(r.buildings[id].get("rotation",0));refresh();return true
func reason() -> String:
 if not applicable():return "Return to your own room"
 var r=room()
 if not game.model._can_purchase():return "Resume an active occupied room to build"
 if moving>=0:
  var error=r.spatial.move_reason(game.model,moving)
  return error if error!="" else r.spatial.geometry_reason(point,moving,{},active_kind(),rotation)
 return r.spatial.purchase_reason(kind,point,rotation) if kind!="" else "Choose a building"
func confirm(at: Vector2,fine=false) -> bool:
 if not applicable() or not active():return false
 cursor_world=at;point=aligned(at,fine);var r=room();var error=reason()
 if error!="":r.reject(error);game.ui.purchase(false);refresh();return false
 var id=moving;var before=r.tile_position(id) if id>=0 else Vector2.ZERO
 var ok=game.model.move_building(point,rotation if r.spatial.grid else -1) if moving>=0 else game.model.place_building(kind,point,rotation)
 if ok:
  if id<0:id=r.spatial.next_id-1
  else:last_visual={"id":id,"instance":int(r.buildings[id].instance_id),"from":before,"to":point,"life":.22}
  game.selected_tile=id;kind="";moving=-1;rotation=0
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
  if event.keycode==KEY_Q and room().spatial.grid and active():rotate(-1 if event.shift_pressed else 1);return true
  if event.keycode==KEY_F and not room().spatial.grid and (active() or planning):toggle_snap();return true
 if event is InputEventMouseMotion:
  var at:=from_screen(event.position)
  if active():cursor_world=at;point=aligned(at,event.shift_pressed)
  else: hover=room().spatial.hit_test(at)
  game.queue_redraw()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var at=from_screen(event.position)
  if active():confirm(at,event.shift_pressed);return true
  var id=room().spatial.hit_test(at)
  if id>=0:game.selected_tile=id;game.ui.open_context()
  elif room().floor_has_point(at):game.ui.open_build_menu()
  else:return false
  return true
 return false
func update(delta: float):
 if game.hunter_spectating:
  refresh()
  return
 if not last_visual.is_empty():
  last_visual.life=maxf(0,last_visual.life-delta)
  if last_visual.life<=0:last_visual.clear()
 if not applicable():
  if active():cancel()
  refresh();return
 if moving>=0 and room().spatial.moving_id!=moving:cancel()
 if active() and not room().spatial.grid:point=aligned(from_screen(game.get_viewport().get_mouse_position()),Input.is_physical_key_pressed(KEY_SHIFT))
 refresh()
func refresh():
 if not is_instance_valid(status):return
 var r=room();var visible=applicable() and game.ui.current_screen=="match"
 var grid: bool=r!=null and r.spatial.grid
 var focused: bool=focused_grid(r) and visible and game.ui.pause_items.is_empty()
 var supplies_open: bool=is_instance_valid(game.ui.run_panel) and game.ui.run_panel.visible
 room_card.visible=focused and not supplies_open
 if room_card.visible:
  var trait_data: Dictionary=StrategyCatalog.TRAITS.get(r.trait_id,{})
  var room_title: String="YOUR ROOM · %02d" % [r.index+1]
  if not trait_data.is_empty():room_title+=" · "+trait_data.name
  var trait_details: String="" if trait_data.is_empty() else "%s\n%s\n" % [trait_data.benefit,trait_data.drawback]
  var interaction: String="E · Sleep near your bed" if r.alive and not r.sleeping else "Door breached" if r.door_hp<=0 else "Ward %.0f HP" % r.magic_state.shield if r.magic_state.shield>0 else "Build [B]  ·  Plan [P]"
  room_info.text="%s\n%s%s" % [room_title,trait_details,interaction]
 refresh_machines(r,focused and not active() and not supplies_open)
 var display=visible and (planning or active() or game.ui.context_open and (game.ui.context_mode=="expansion" or grid and game.ui.context_mode=="build"))
 status.visible=display;plan_button.visible=display;snap_button.visible=display and not grid
 rotate_button.visible=visible and grid and active()
 hint.visible=visible and active()
 move_button.visible=visible and game.ui.context_open and game.ui.context_mode=="upgrade" and r.buildings.has(game.selected_tile)
 undo_button.visible=visible and game.ui.context_open and game.ui.context_mode=="upgrade"
 undo_button.disabled=not undo_button.visible or r.spatial.undo_reason(game.model)!=""
 range_button.visible=game.mode=="match" and game.watched_room<0 and game.ui.context_open and game.ui.context_mode=="upgrade"
 var side=game.ui.bottom_context!=null and game.ui.bottom_context.body==BottomContextPanel.SIDE_BODY
 range_button.text=("Range [O]" if ranges else "Range off [O]") if side else "Range: %s [O]" % ("ON" if ranges else "OFF")
 undo_button.text="Undo [Z]" if side else "Undo move [Z]"
 if not visible:return
 status.position=Vector2(20,572) if grid else Vector2(357,143)
 plan_button.position=Vector2(20,605) if grid else Vector2(665,140)
 rotate_button.position=Vector2(143,605) if grid else Vector2(782,140)
 status.text="Floor plan" if grid else "BUILDINGS %d / %d · %s" % [r.buildings.size(),r.tile_count(),RoomExpansion.NAMES[r.expansion_tier]]
 plan_button.text="Close plan [P]" if planning else "Plan [P]";snap_button.text="Snap 8: %s [F]" % ("ON" if snap else "OFF")
 if move_button.visible:
  var why=r.spatial.move_reason(game.model,game.selected_tile)
  move_button.disabled=why!="";move_button.tooltip_text=why if why!="" else "Reposition this same building; investments and cooldown remain."
 if active():
  current_preview_error=reason();var error=current_preview_error;var title="Move" if moving>=0 else "Build "+Catalog.BUILDINGS[kind].name
  if grid:
   var footprint: Rect2=r.spatial.footprint_for(point,active_kind(),rotation)
   var cells: Vector2=footprint.size/SpatialConstruction.CELL_SIZE
   var cell:=Vector2i((footprint.position-r.spatial.grid_origin())/SpatialConstruction.CELL_SIZE)+Vector2i.ONE
   title+=" · %d×%d cells" % [cells.x,cells.y]
   if error=="Building overlaps another structure":
    for id in r.buildings:
     if id==moving:continue
     var blocker: Dictionary=r.buildings[id]
     if footprint.intersects(r.spatial.footprint_for(blocker.position,blocker.kind,int(blocker.get("rotation",0)))):
      error="Blocked by "+Catalog.BUILDINGS[blocker.kind].name
      break
   elif error=="Outside unlocked room":error="Footprint extends past the usable floor"
   elif error=="":error="Valid floor · cell %d, %d" % [cell.x,cell.y]
  var controls=("Click to place · " if current_preview_error=="" else "")+"Q / Shift+Q rotate\nEsc / right-click cancels" if grid else "Click place · Esc / right cancel · Shift fine · F snap · O range"
  hint.position=Vector2(20,349) if grid else Vector2(355,600)
  hint.size=Vector2(320,108) if grid else Vector2(550,42)
  hint.text=title+"\n"+("Valid floor" if error=="" else error)+"\n"+controls
  hint.modulate=Color("B9E0D3") if current_preview_error=="" else Color("F0B1B7")
func rendered_position(r,id: int) -> Vector2:
 if not last_visual.is_empty() and r==room() and last_visual.id==id and r.buildings.has(id) and int(r.buildings[id].instance_id)==last_visual.instance and not CinematicQuality.reduced_motion(game):return last_visual.from.lerp(last_visual.to,1-pow(last_visual.life/.22,3))
 return r.tile_position(id)
func draw_floor(c,r,grid_layout: Dictionary={}):
 if not applicable() or r!=room():return
 var grid: bool=r.spatial.grid
 var showing=planning or active() or game.ui.context_open and (game.ui.context_mode=="expansion" or grid and game.ui.context_mode=="build")
 if not showing:return
 var offset=game.MAP_OFFSET
 var floor: Rect2=r.spatial.grid_bounds() if grid else r.bounds().grow(-8)
 if grid and r.layout.has("floor"):
  draw_irregular_grid(c,r,floor)
 else:
  floor.position+=offset
  c.draw_rect(floor,Color(.15,.42,.35,.07))
  c.draw_rect(floor,Color(.40,.75,.66,.65),false,2)
  if grid:draw_grid_lines(c,floor)
 for blocked in r.spatial.blocks():
  c.draw_rect(Rect2(offset+blocked.rect.position,blocked.rect.size),Color(.65,.28,.30,.13));c.draw_rect(Rect2(offset+blocked.rect.position,blocked.rect.size),Color(.70,.40,.38,.55),false,1)
 var preview: Rect2=r.spatial.footprint_for(point,active_kind(),rotation) if active() else Rect2()
 preview.position+=offset
 if grid:
  var outlines: PackedVector2Array=grid_layout.outlines
  if not outlines.is_empty():c.draw_multiline(outlines,Color(.52,.90,.77,.48),1)
  if active():
   for id in grid_layout.entries:
    if id==moving:continue
    var rect: Rect2=grid_layout.entries[id].rect
    rect.position+=offset
    if preview.intersects(rect):c.draw_rect(rect,Color("F08C95"),false,2)
  return
 preview=preview.grow(2)
 for id in r.buildings:
  var b: Dictionary=r.buildings[id]
  var rect: Rect2=r.spatial.footprint_for(r.tile_position(id),b.kind,int(b.get("rotation",0)))
  rect.position+=offset
  var selected=id==game.selected_tile or id==moving
  var obstructing=active() and id!=moving and preview.intersects(rect)
  c.draw_rect(rect,Color(.20,.65,.55,.12 if selected else .035));c.draw_rect(rect,Color("F08C95") if obstructing else Color(.52,.90,.77,.85 if selected else .4),false,2 if selected or obstructing else 1)
func draw_grid_lines(c,floor: Rect2):
 if grid_floor==floor and grid_floor_parts.is_empty():
  if not grid_lines.is_empty():c.draw_multiline(grid_lines,Color(.52,.81,.73,.46),1.0)
  return
 grid_floor=floor
 grid_floor_parts=[]
 var lines=PackedVector2Array()
 for x in range(SpatialConstruction.CELL_SIZE,int(floor.size.x),SpatialConstruction.CELL_SIZE):
  lines.append(floor.position+Vector2(x,0));lines.append(Vector2(floor.position.x+x,floor.end.y))
 for y in range(SpatialConstruction.CELL_SIZE,int(floor.size.y),SpatialConstruction.CELL_SIZE):
  lines.append(floor.position+Vector2(0,y));lines.append(Vector2(floor.end.x,floor.position.y+y))
 grid_lines=lines
 if not lines.is_empty():c.draw_multiline(lines,Color(.52,.81,.73,.46),1.0)
func draw_irregular_grid(c,r,floor: Rect2):
 var parts: Array=r.layout.floor
 for part in parts:
  var shade: Rect2=floor.intersection(part)
  if not shade.has_area():continue
  shade.position+=game.MAP_OFFSET
  c.draw_rect(shade,Color(.15,.42,.35,.15))
 if grid_floor!=floor or grid_floor_parts!=parts:
  grid_floor=floor
  grid_floor_parts=parts.duplicate()
  var step := SpatialConstruction.CELL_SIZE
  var segments: Dictionary={}
  for y in range(0,int(floor.size.y),step):
   for x in range(0,int(floor.size.x),step):
    var corner := floor.position+Vector2(x,y)
    if not r.spatial.grid_cell_walkable(Rect2(corner,Vector2.ONE*step)):continue
    # Deduplicate joined cell edges. Both orientations share the same integral key.
    segments[Vector3i(x,y,0)]=true
    segments[Vector3i(x,y+step,0)]=true
    segments[Vector3i(x,y,1)]=true
    segments[Vector3i(x+step,y,1)]=true
  grid_lines=PackedVector2Array()
  for key in segments:
   var corner: Vector2=game.MAP_OFFSET+floor.position+Vector2(key.x,key.y)
   grid_lines.append(corner)
   grid_lines.append(corner+(Vector2.RIGHT if key.z==0 else Vector2.DOWN)*step)
 if not grid_lines.is_empty():
  c.draw_multiline(grid_lines,Color(.49,.87,.75,.54),1.0)

func draw_machine_focus(c):
 var r=room()
 if not focused_grid(r) or active():return
 var selected: int=game.selected_tile if game.ui.context_open and game.ui.context_mode=="upgrade" else -1
 var id: int=selected if selected>=0 else hover
 if not r.buildings.has(id):return
 var building: Dictionary=r.buildings[id]
 var rect: Rect2=r.spatial.footprint_for(rendered_position(r,id),building.kind,int(building.get("rotation",0)))
 rect.position+=game.MAP_OFFSET
 var color:=Color("F8DF9B") if selected>=0 else Color("B9E0D3")
 c.draw_rect(rect.grow(2),Color("121A1E"),false,4)
 c.draw_rect(rect.grow(1),color,false,2)

func draw_preview(c):
 if not applicable() or not active():return
 var r=room();var b=r.buildings.get(moving,{})
 var id=b.get("kind",kind);var level=int(b.get("level",1));var branch=b.get("specialization","")
 if id=="":return
 var valid=current_preview_error=="";var color=Color("89DABD") if valid else Color("F08C95");var p=game.MAP_OFFSET+point
 c.draw_set_transform(p+Vector2(0,8),0,Vector2(1,.3));c.draw_circle(Vector2.ZERO,26,Color(.015,.025,.035,.3));c.draw_set_transform(Vector2.ZERO)
 var rect: Rect2=r.spatial.footprint_for(point,id,rotation)
 rect.position+=game.MAP_OFFSET
 c.draw_style_box(game.presentation.frame(Color(color,.10),color,5),rect)
 c.draw_rect(rect.grow(2),Color(color,.95),false,2.5)
 var scale: float=MapView.grid_scale(rect) if r.spatial.grid else 1.0
 game.presentation.building_visual.draw(c,game.presentation,id,level,p,branch,0,game.model.hunter.position-point,0,0,scale,Color(1,1,1,.58))
 if r.spatial.grid:MapView.draw_grid_facing(c,rect,rotation,color)
 if moving>=0:
  c.draw_line(game.MAP_OFFSET+r.tile_position(moving),p,Color(color,.6),1.5)

func draw_range(c):
 if game.mode!="match" or game.watched_room>=0 or game.hunter_spectating or not ranges:return
 var r=game.model.player();var b={};var at=point
 if r==null:return
 if active():b=r.buildings.get(moving,{"kind":kind,"level":1,"specialization":""})
 elif game.ui.context_open and game.ui.context_mode=="upgrade" and r.buildings.has(game.selected_tile):b=r.buildings[game.selected_tile];at=r.tile_position(game.selected_tile)
 if b.is_empty() or b.kind not in DefenseEffects.WEAPONS:return
 var radius=BuildingStats.weapon_stats(game.model,r,b).range*game.model.hunter.nightmare.range_factor(r.index)
 var center=game.MAP_OFFSET+at
 var unavailable=game.model.wrath.rules_remaining>0 or r.magic_state.disrupt>0 or active() and current_preview_error!=""
 var color=Color(.85,.35,.4,.1) if unavailable else Color(.35,.8,.77,.11)
 var poly=PackedVector2Array()
 for i in range(64):poly.append(center+Vector2.from_angle(i*TAU/64)*radius)
 c.draw_colored_polygon(poly,color);c.draw_arc(center,radius,0,TAU,96,Color(.9,.4,.45,.65) if unavailable else Color(.5,.9,.85,.65),1.5)
 if active() and not r.spatial.grid:game.presentation.text(c,"RANGE %.0f · outside ring: out of range" % radius,center+Vector2(28,-34),10,Color("B7DED4"))
