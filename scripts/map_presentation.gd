extends RefCounted
## Original procedural environments over shared model geometry and existing art.
## Decorations are presentation only; collision remains entirely map-owned.
const OFFSET=Vector2(145,40)
const FAMILY_NAMES={
 "ring":"RING COURTYARD","branching":"BRANCHING FORK","scattered":"SCATTERED ASYMMETRIC","spine":"LONG SPINE",
 "zigzag":"ZIGZAG STAIRCASE","radial":"RADIAL SPOKES","twin_wings":"TWIN WINGS","labyrinth":"LABYRINTH",
 "courtyards":"ASYMMETRIC COURTYARDS","hybrid":"MIXED HYBRID"
}
var halls_visual=preload("res://scripts/haunted_hall_presentation.gd").new()
var floors={}
var grid_layouts: Dictionary={}
var wall_layouts: Dictionary={}
var close_passages=preload("res://scripts/close_quarters_draw_cache.gd").new()
var batched_walls:=OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE")=="1"
func _init():
 for theme in ["dorm","hospital","hotel","lab","mansion"]:floors[theme]=load("res://assets/visual_identity/"+theme+"_floor.svg")
const PALETTES={
 "dorm":[Color("484844"),Color("59574E"),Color("273033"),Color("918166"),Color("D5BE8E")],
 "hospital":[Color("526060"),Color("68716A"),Color("293B3F"),Color("9CAFA4"),Color("B7D7BF")],
 "hotel":[Color("49404B"),Color("61565C"),Color("2C2837"),Color("998265"),Color("CBB797")],
 "lab":[Color("35484C"),Color("4A5B5C"),Color("202F35"),Color("77998D"),Color("A5CCC3")],
 "mansion":[Color("483E3B"),Color("63534A"),Color("302831"),Color("9E8967"),Color("D7BE8B")]
}
func render_architecture(c,p):
 var data=c.model.map_data
 var theme=str(data.get("theme","dorm"))
 var colors=PALETTES.get(theme,PALETTES.dorm)
 var visible=p.visible_world_rect(c)
 var generated: bool=c.model.is_procedural()
 if c.macro_overview():
  render_macro_overview(c,p,data,theme,colors,visible)
  return
 var close_quarters: bool=data.get("version")==NightmareMap.CLOSE_QUARTERS_VERSION
 if close_quarters:render_close_passages(c,p,data,theme,colors,visible)
 for corridor in data.corridors if not close_quarters else []:
  var rect=Rect2(OFFSET+corridor.position,corridor.size)
  if not visible.intersects(rect):continue
  if not generated:c.draw_style_box(p.frame(colors[2],colors[3],3),rect.grow(4))
  c.draw_texture_rect(floors[theme],rect,true,Color("737B7B"))
  # Metal service rails, rivets and warm wall lights anchor corridor depth.
  for i in range(0,int(rect.size.x),64):
   var q=rect.position+Vector2(i+8,8)
   if batched_walls and not visible.grow(24).has_point(q):continue
   c.draw_circle(q,2,colors[3].darkened(.1))
   c.draw_line(q+Vector2(0,12),q+Vector2(7,22),Color(.08,.09,.12,.5),2)
  var light=rect.position+Vector2(15,15)
  c.draw_circle(light,20,Color(colors[4],.035+.012*sin(p.clock*1.1+light.x)))
  c.draw_line(light-Vector2(5,0),light+Vector2(5,0),colors[4],2)
  if theme=="hotel":
   var runner=rect.grow(-12)
   c.draw_rect(runner,Color("674759"))
   c.draw_rect(runner.grow(-4),Color("674759"),false,2)
  elif theme=="lab":
   for x in range(0,int(rect.size.x),28):
    for y in range(0,int(rect.size.y),28):
     c.draw_line(rect.position+Vector2(x,y),rect.position+Vector2(minf(x+18,rect.size.x),y),Color("667D7D"),1)
  elif theme=="hospital":
   for x in range(0,int(rect.size.x),32):
    for y in range(0,int(rect.size.y),32):
     c.draw_rect(Rect2(rect.position+Vector2(x,y),Vector2(minf(31,rect.size.x-x),minf(31,rect.size.y-y))),Color("738D91") if (x/32+y/32)%2==0 else Color("617B81"))
  else:
   for y in range(0,int(rect.size.y),22): c.draw_line(rect.position+Vector2(0,y),rect.position+Vector2(rect.size.x,y),colors[3].darkened(0.5),1)
 var halls: Dictionary=data.get("halls",{})
 if not halls.is_empty():halls_visual.render(c,p,halls,floors[theme],visible)
 for room in c.model.rooms:
  if visible.intersects(Rect2(OFFSET+room.bounds().position,room.bounds().size)):render_room(c,p,room,theme,colors)
 var title=OFFSET+data.bounds.position+Vector2(10,-20)
 if c.full_map:
  var label := str(data.title).to_upper()
  var title_size := 18
  if generated:
   label+=" · SEED "+str(data.seed)
   title_size=roundi(14.0/maxf(c.camera.zoom.x,.12))
   var width: float=p.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
   title=OFFSET+Vector2(data.bounds.get_center().x-width*.5,data.bounds.end.y+85)
  p.text(c,label,title,title_size,colors[4])

func render_close_passages(c,_p,data: Dictionary,theme: String,colors: Array,visible: Rect2) -> void:
 close_passages.render(c,data,floors[theme],colors,OFFSET,visible,CinematicQuality.detail(c))

func render_macro_overview(c,p,data: Dictionary,theme: String,colors: Array,visible: Rect2):
 # Use the physical lane surfaces. Painting borders first keeps overlaps
 # readable as junctions instead of looking like closed junction lines.
 var stroke: float=2.0/c.camera.zoom.x
 var surface: Color=colors[1].lerp(Color("41464B"),.42)
 for corridor: Rect2 in data.corridors:
  var rect:=Rect2(corridor.position+OFFSET,corridor.size)
  if visible.intersects(rect):c.draw_rect(rect.grow(stroke),Color("252D35"))
 for corridor: Rect2 in data.corridors:
  var rect:=Rect2(corridor.position+OFFSET,corridor.size)
  if visible.intersects(rect):c.draw_rect(rect,surface)
 for room: RoomState in c.model.rooms:
  if not visible.intersects(Rect2(room.bounds().position+OFFSET,room.bounds().size)):continue
  render_overview_room(c,p,room,theme,colors)
 for id in data.halls:
  var hall: Dictionary=data.halls[id]
  var rect:=Rect2(hall.bounds.position+OFFSET,hall.bounds.size)
  if not visible.intersects(rect):continue
  var tint: Color=halls_visual.TINTS[id]
  c.draw_rect(rect.grow(stroke),tint.darkened(.39))
  c.draw_rect(rect,tint.darkened(.72))
  var label: String=str(id).substr(0,1).to_upper()
  if c.camera.zoom.x>=.20:label+=" · HALL"
  draw_overview_label(c,p,label,hall.center+OFFSET,tint)
 draw_overview_footer(c,p,data,colors[4])

func render_overview_room(c,p,room: RoomState,theme: String,colors: Array):
 var selected: bool=room.index==c.overview_room
 var owned: bool=room.index==c.model.player_room
 var tint:=Color("E4BE83") if selected else Color("A8D0B5") if owned else Color("CED2CD")
 var floor_tint: Color=colors[0].lightened(.13)
 if owned:floor_tint=floor_tint.lerp(Color("375952"),.64)
 if not room.alive:floor_tint=floor_tint.darkened(.24)
 if c.model.player_first_requested and c.phase20_heatmap and room.owner>=0 and room.alive:
  if PlayerDoorSurvival.under_siege(c.model,room):floor_tint=floor_tint.lerp(Color("A03A50"),.78)
  elif room.door_hp<=room.max_hp()*.30:floor_tint=floor_tint.lerp(Color("A35443"),.68)
  elif c.model.time-c.model.chronicle.last_attack(room.index)<35.0:floor_tint=floor_tint.lerp(Color("8E6835"),.50)
 for part: Rect2 in room.layout.floor:
  var surface:=Rect2(OFFSET+part.position,part.size)
  c.draw_rect(surface,floor_tint)
  if CinematicQuality.detail(c)>0:
   c.draw_texture_rect(floors[theme],surface,true,Color(1,1,1,.17))
 var walls:=PackedVector2Array()
 for edge in room.layout.walls:
  walls.append(edge[0]+OFFSET)
  walls.append(edge[1]+OFFSET)
 c.draw_multiline(walls,tint.darkened(.38), (2.2 if selected or owned else 1.2)/c.camera.zoom.x)
 var tag: String="%02d" % [room.index+1]
 if c.camera.zoom.x>=.20:
  var state: String=c.model.room_rush_status(room.index)
  tag+="  "+("YOU" if owned else room.survivor_name().split(" ")[0] if room.owner>=0 else "OPEN · NPC EN ROUTE" if state=="approaching" else "VACANT")
 draw_overview_label(c,p,tag,room.bed_position()+OFFSET,tint)

func draw_overview_label(c,p,label: String,at: Vector2,tint: Color):
 var zoom: float=c.camera.zoom.x
 var size:=roundi(11.0/zoom)
 var width: float=p.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 var box:=Rect2(at-Vector2(width*.5+3.0/zoom,6.0/zoom),Vector2(width+6.0/zoom,13.0/zoom))
 c.draw_rect(box,Color("141B23"))
 p.text(c,label,box.position+Vector2(3.0/zoom,10.0/zoom),size,tint)

func draw_overview_footer(c,p,data: Dictionary,tint: Color):
 var view: Vector2=c.get_viewport_rect().size
 var top:=view.y*.838
 var left:=view.x*.035
 var label: String=FAMILY_NAMES.get(data.family,str(data.family).replace("_"," ").to_upper())
 c.draw_set_transform_matrix(c.get_canvas_transform().affine_inverse())
 c.draw_rect(Rect2(Vector2(left,top),Vector2(view.x-2*left,39)),Color("172028"))
 c.draw_line(Vector2(left,top),Vector2(view.x-left,top),Color("5A6667"),1)
 p.text(c,label+"  ·  "+str(data.title).to_upper()+"  ·  SEED "+str(data.seed),Vector2(left+12,top+15),13,tint)
 var hall_key: String="N / S / W / E   HAUNTED HALLS"
 var hall_key_width: float=p.font.get_string_size(hall_key,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
 p.text(c,hall_key,Vector2(view.x-left-hall_key_width-12,top+15),11,tint)
 var detail: String="Click a room to inspect" if not c.mobile_mode else "Tap a room to inspect"
 var detail_tint:=Color("BBC8C7")
 if c.overview_room>=0:
  var room: RoomState=c.model.rooms[c.overview_room]
  var resident: String=c.room_ownership_label(room) if c.model.room_rush_active() else room.survivor_name() if room.owner>=0 else "Vacant"
  if c.model.player_first_requested and room.owner>0 and PlayerDoorSurvival.under_siege(c.model,room) and room.door_hp<=room.max_hp()*.30:
   resident+=" · SOS"
  if c.model.room_rush_status(room.index)=="approaching":
   resident+=" · Still vacant"
  var trait_name: String=StrategyCatalog.TRAITS.get(room.trait_id,{}).get("name","")
  detail="%02d  %s" % [room.index+1,resident]
  if not trait_name.is_empty():detail+="  ·  "+trait_name
  if c.model.player_room<0 and c.model.time<c.model.preparation and room.owner<0 and not c.overview_opening.is_empty():
   detail+="  ·  Walk ~%ds  ·  Hunter ~%ds if targeted first" % [c.overview_opening.entry_seconds,c.overview_opening.hunter_seconds]
   if c.model.player_first_requested:
    var gap: float=c.overview_opening.hunter_seconds-c.overview_opening.entry_seconds
    detail+=" · %s approach risk" % ("High" if gap<10.0 else "Moderate" if gap<20.0 else "Low")
   if c.overview_opening.get("early_siege_risk",false) and not c.model.player_first_requested:
    detail+="  ·  FAST HUNTER ROUTE"
    detail_tint=Color("EDBA78")
  elif c.model.player_first_requested and is_finite(c.model.chronicle.last_attack(room.index)):
   detail+=" · Last hit %.0fs ago" % maxf(0.0,c.model.time-c.model.chronicle.last_attack(room.index))
 p.text(c,detail,Vector2(left+12,top+31),11,detail_tint)
 if not c.mobile_mode:
  var controls: String="Wheel · middle-drag · H danger · 0 reset · M focus" if c.model.player_first_requested else "Wheel zoom  ·  Middle drag  ·  0 reset  ·  M focus"
  var width: float=p.font.get_string_size(controls,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
  p.text(c,controls,Vector2(view.x-left-width-12,top+31),11,Color("BBC8C7"))
 c.draw_set_transform(Vector2.ZERO)

func render_room(c,p,room,theme,colors):
 var r=Rect2(OFFSET+room.bounds().position,room.bounds().size)
 var generated: bool=room.layout.has("floor")
 if generated:
  render_generated_room_floor(c,p,room,theme,colors)
 else:
  c.draw_style_box(p.frame(Color("14232D"),Color("111E26"),7),r.grow(9))
  c.draw_rect(r,colors[0])
  c.draw_texture_rect(floors[theme],r,true,Color.WHITE if room.alive else Color("85818C"))
  # Quiet seams and water stains replace a uniform checkerboard.
  for i in range(4):
   var q=r.position+Vector2(18+i*23,45+i*31)
   c.draw_arc(q,12+i*3,.3,2.2,12,Color(.08,.09,.11,.15),2)
  # Wall surfaces follow actual room size; entrances are cut from the right edge.
  var normal=room.door_normal()
  var doorway=OFFSET+room.door_position()
  for edge in range(4):
   var horizontal=edge<2
   var start=Vector2(r.position.x,r.position.y if edge==0 else r.end.y) if horizontal else Vector2(r.position.x if edge==2 else r.end.x,r.position.y)
   var finish=Vector2(r.end.x,start.y) if horizontal else Vector2(start.x,r.end.y)
   var door_edge=(edge==0 and normal.y<0) or (edge==1 and normal.y>0) or (edge==2 and normal.x<0) or (edge==3 and normal.x>0)
   if door_edge:
    var along=Vector2.RIGHT if horizontal else Vector2.DOWN
    c.draw_line(start,doorway-along*33,colors[2],9)
    c.draw_line(doorway+along*33,finish,colors[2],9)
   else: c.draw_line(start,finish,colors[2],9)
   c.draw_line(start+Vector2(0,-3),finish+Vector2(0,-3),Color(colors[3],0.5),1)
 var expanded_horizontal=c.model.run_kind=="endless" and c.model.expansion.initialized and not c.model.expansion.legacy and absf(room.door_normal().x)>0
 var owned=room.index==c.model.player_room
 var focused_grid: bool=c.construction!=null and c.construction.focused_grid(room)
 if owned:
  if not generated:c.draw_style_box(p.frame(Color.TRANSPARENT,Color("7BE3A1"),5),r.grow(11))
  if not generated and not expanded_horizontal and not focused_grid:p.text(c,"YOUR ROOM",r.position+Vector2(10,r.size.y-12),11,Color("D4FFE1"))
 var plaque=r.position+Vector2(10,r.size.y-58 if expanded_horizontal else 18)
 if generated:
  var strip: Rect2=room.layout.floor[0]
  plaque=strip.position+OFFSET+Vector2(12,19)
 if not focused_grid:
  var plaque_size := 11
  if generated and c.full_map:
   plaque_size=roundi(10.0/maxf(c.camera.zoom.x,.12))
  var occupant: String=c.room_ownership_label(room) if c.model.room_rush_active() else room.survivor_name() if room.owner>=0 else "VACANT"
  p.text(c,"%02d · %s" % [room.index+1,occupant],plaque,plaque_size,Color("EDF4ED"))
 if room.trait_id!="" and not focused_grid and not generated:
  var room_trait=StrategyCatalog.TRAITS[room.trait_id]
  var at=r.position+Vector2(8,r.size.y-48) if expanded_horizontal else r.position+Vector2(r.size.x-193,4)
  c.draw_texture_rect(PremiumButton.texture(room_trait.icon),Rect2(at,Vector2(23,23)),false)
  p.text(c,room_trait.name,at+Vector2(28,13),11,Color("DDD3B9"))
  p.text(c,room_trait.benefit,at+Vector2(0,29),9,Color("B1C2AA"))
  p.text(c,room_trait.drawback,at+Vector2(0,41),9,Color("C99A8D"))
 # Original illustrations stay in the dedicated furniture strip from map data.
 var bed=OFFSET+room.bed_position()
 if theme in ["hotel","mansion"]:
  c.draw_style_box(p.frame(Color("6B4053") if theme=="hotel" else Color("4F3540"),colors[3],5),Rect2(bed-Vector2(43,55),Vector2(86,116)))
 var bed_tint=Color("D7ECEB") if theme=="hospital" else Color("BACDD5") if theme=="lab" else Color.WHITE
 p.building_visual.draw(c,p,"bed",room.bed_level+1,bed,room.bed_branch,1.0 if room.sleeping and room.alive else 0.0,Vector2.ZERO,p.clock if owned else 0.0)
 if owned:CosmeticPresentation.bed(c,bed)
 var cabinet=OFFSET+room.cabinet_position()
 p.sprite(c,"cabinet" if theme not in ["lab","hotel"] else "utility" if theme=="lab" else "desk",cabinet,Vector2(38,48))
 p.sprite(c,"plant",OFFSET+room.plant_position(),Vector2(25,34),Color("A5C6A0") if theme=="hospital" else Color.WHITE)
 if not generated:render_decor(c,p,r,bed,cabinet,theme,colors)
 render_tiles(c,p,room,owned)

func render_generated_room_floor(c,p,room,theme,colors):
 var simplified := CinematicQuality.detail(c)==0
 for part in room.layout.floor:
  var surface := Rect2(OFFSET+part.position,part.size)
  if simplified:
   c.draw_rect(surface,colors[0] if room.alive else colors[0].darkened(.22))
  else:
   c.draw_rect(surface,colors[0])
   c.draw_texture_rect(floors[theme],surface,true,Color.WHITE if room.alive else Color("85818C"))
 var player_owned: bool=room.index==c.model.player_room
 var trim: Color=Color("739B87") if player_owned else colors[3]
 if batched_walls:
  render_batched_room_walls(c,room,colors[2],trim)
  return
 for segment in room.layout.walls:
  var start: Vector2=OFFSET+segment[0]
  var finish: Vector2=OFFSET+segment[1]
  c.draw_line(start,finish,Color("11171E"),15)
  c.draw_line(start,finish,colors[2],9)
  c.draw_line(start+Vector2(0,-3),finish+Vector2(0,-3),Color(trim,.80),2)
  if start.distance_squared_to(finish)>44*44:
   var center:=start.lerp(finish,.5)
   c.draw_circle(center,2.4,Color(trim,.74))

func render_batched_room_walls(c, room: RoomState, edge: Color, trim: Color):
 # The wall segments are identical across frames. Draw the same layered
 # strokes as packed line batches, while the room and door remain dynamic.
 var cached: Dictionary=wall_layouts.get(room.index,{})
 var walls: Array=room.layout.walls
 if cached.is_empty() or cached.source!=walls:
  var points:=PackedVector2Array()
  var border:=PackedVector2Array()
  var studs:=PackedVector2Array()
  for segment in walls:
   var first: Vector2=segment[0]+OFFSET
   var last: Vector2=segment[1]+OFFSET
   points.append(first)
   points.append(last)
   border.append(first+Vector2(0,-3))
   border.append(last+Vector2(0,-3))
   if first.distance_squared_to(last)>44.0*44.0:studs.append(first.lerp(last,.5))
  cached={"source":walls.duplicate(true),"points":points,"border":border,"studs":studs}
  wall_layouts[room.index]=cached
 if cached.points.is_empty():return
 c.draw_multiline(cached.points,Color("11171E"),15)
 c.draw_multiline(cached.points,edge,9)
 c.draw_multiline(cached.border,Color(trim,.80),2)
 for center: Vector2 in cached.studs:
  c.draw_circle(center,2.4,Color(trim,.74))

func render_decor(c,p,r,bed,cabinet,theme,colors):
 var wall=r.position+Vector2(r.size.x-66,20)
 if theme=="hospital":
  # Medical cabinet cross and an IV stand beside the hospital bed.
  c.draw_rect(Rect2(cabinet+Vector2(-9,-17),Vector2(18,5)),Color("C14B53"))
  c.draw_rect(Rect2(cabinet+Vector2(-3,-23),Vector2(6,17)),Color("C14B53"))
  var iv=bed+Vector2(-39,-10)
  c.draw_line(iv-Vector2(0,29),iv+Vector2(0,34),Color("D4E1DF"),3)
  c.draw_line(iv+Vector2(-10,-27),iv+Vector2(11,-27),Color("D4E1DF"),2)
  c.draw_style_box(p.frame(Color("A0CFD5"),Color("D6E7E2"),2),Rect2(iv+Vector2(3,-23),Vector2(10,18)))
  c.draw_polyline(PackedVector2Array([iv+Vector2(8,-5),iv+Vector2(14,6),bed+Vector2(-23,7)]),Color("8CB9BD"),1)
  c.draw_rect(Rect2(wall,Vector2(37,17)),Color("233E4B"))
  c.draw_polyline(PackedVector2Array([wall+Vector2(3,11),wall+Vector2(10,11),wall+Vector2(14,5),wall+Vector2(18,14),wall+Vector2(23,7),wall+Vector2(32,7)]),Color("9DD7BD"),1)
 elif theme=="hotel":
  # Luggage, brass clock and a framed guest-room number.
  c.draw_style_box(p.frame(Color("8D6950"),Color("352D36"),4),Rect2(cabinet+Vector2(13,4),Vector2(24,23)))
  c.draw_arc(cabinet+Vector2(25,3),6,PI,TAU,12,colors[3],2)
  c.draw_line(cabinet+Vector2(20,7),cabinet+Vector2(20,24),colors[3],2)
  c.draw_circle(wall+Vector2(12,10),11,colors[3])
  c.draw_circle(wall+Vector2(12,10),8,Color("39313E"))
  c.draw_line(wall+Vector2(12,10),wall+Vector2(12,4),colors[3],1)
  c.draw_line(wall+Vector2(12,10),wall+Vector2(17,12),colors[3],1)
 elif theme=="lab":
  # Chemical vials, monitor and striped warning rail.
  c.draw_rect(Rect2(wall,Vector2(50,22)),Color("192D37"))
  c.draw_rect(Rect2(wall+Vector2(4,4),Vector2(22,12)),Color("408C85"))
  for i in range(3):
   var vial=cabinet+Vector2(-11+i*10,-28)
   c.draw_rect(Rect2(vial,Vector2(6,14)),Color("64BCAF") if i%2==0 else Color("A497D0"))
   c.draw_line(vial-Vector2(1,1),vial+Vector2(7,-1),Color("B5C9CA"),2)
  for i in range(5): c.draw_line(wall+Vector2(30+i*4,3),wall+Vector2(26+i*4,17),colors[3],2)
 elif theme=="mansion":
  # Original portrait silhouette and candle cluster.
  c.draw_style_box(p.frame(Color("302B3A"),Color("B29969"),3),Rect2(wall,Vector2(30,37)))
  c.draw_circle(wall+Vector2(15,12),6,Color("83727F"))
  c.draw_arc(wall+Vector2(15,29),10,PI,TAU,16,Color("83727F"),5)
  for i in range(3):
   var candle=cabinet+Vector2(-10+i*10,-28)
   c.draw_rect(Rect2(candle,Vector2(5,12)),Color("DAC7A5"))
   c.draw_circle(candle+Vector2(2,-3),3,Color("E4B66A"))
 else:
  p.sprite(c,"poster",wall+Vector2(15,9),Vector2(25,31))
  p.sprite(c,"books",cabinet+Vector2(0,-22),Vector2(25,18))
  c.draw_polyline(PackedVector2Array([r.position+Vector2(9,53),r.position+Vector2(17,63),r.position+Vector2(12,76)]),Color("303E42"),2)
 # Small paper scraps and old pipework live in the furniture strip only.
 for i in range(3):
  var scrap=Vector2(r.position.x+12+i*9,r.end.y-42+i*6)
  c.draw_colored_polygon(PackedVector2Array([scrap,scrap+Vector2(8,-2),scrap+Vector2(10,6),scrap+Vector2(1,8)]),Color("928878").darkened(.2+i*.08))
 c.draw_polyline(PackedVector2Array([r.position+Vector2(8,75),r.position+Vector2(8,116),r.position+Vector2(20,116)]),Color("78685C"),3)
 c.draw_line(r.position+Vector2(6,93),r.position+Vector2(11,93),Color("A18C6C"),2)
 var glow=r.position+Vector2(25,36)
 p.sprite(c,"warm_glow",glow,Vector2(145,145),Color(colors[4],0.3))
 p.sprite(c,"lantern",glow,Vector2(17,28),colors[4])

static func grid_scale(rect: Rect2) -> float:
 return clampf(minf(rect.size.x,rect.size.y)/44.0,.65,1.0)

static func draw_grid_facing(c,rect: Rect2,rotation: int,color: Color):
 var toward := Vector2.DOWN.rotated(rotation*PI/2)
 var side := toward.orthogonal()
 var tip := rect.get_center()+toward*(absf(toward.x)*rect.size.x+absf(toward.y)*rect.size.y)*.5
 c.draw_colored_polygon(PackedVector2Array([tip,tip-toward*6.0-side*4.0,tip-toward*6.0+side*4.0]),color)

# Rendering-only cache. A layout can be replaced by loading or replay, and
# machine state can mutate in place, so compare the actual geometry.
func grid_layout(room) -> Dictionary:
 var cached: Dictionary=grid_layouts.get(room.index,{})
 if not cached.is_empty() and cached.room.get_ref()==room and cached.rules_version==room.spatial.rules_version and cached.entries.size()==room.buildings.size():
  var matches:=true
  for id in room.buildings:
   var building: Dictionary=room.buildings[id]
   var entry: Dictionary=cached.entries.get(id,{})
   if entry.is_empty() or entry.center!=building.position or entry.kind!=building.kind or entry.rotation!=building.get("rotation",0):
    matches=false
    break
  if matches:return cached
 var entries: Dictionary={}
 var outlines:=PackedVector2Array()
 var ids: Array=room.buildings.keys()
 for id in ids:
  var building: Dictionary=room.buildings[id]
  var center: Vector2=room.tile_position(id)
  var rotation:=int(building.get("rotation",0))
  var rect: Rect2=room.spatial.footprint_for(center,building.kind,rotation)
  entries[id]={"center":center,"kind":building.kind,"rotation":rotation,"rect":rect,"scale":SpatialConstruction.art_scale(building.kind,rect,room.spatial.rules_version)}
  var a:=OFFSET+rect.position
  var b:=a+Vector2(rect.size.x,0)
  var d:=a+Vector2(0,rect.size.y)
  var c:=OFFSET+rect.end
  outlines.append_array(PackedVector2Array([a,b,b,c,c,d,d,a]))
 ids.sort_custom(func(a,b):
  var first: Vector2=entries[a].center
  var second: Vector2=entries[b].center
  return a<b if first.y==second.y else first.y<second.y)
 cached={"room":weakref(room),"rules_version":room.spatial.rules_version,"entries":entries,"ids":ids,"outlines":outlines}
 grid_layouts[room.index]=cached
 return cached

func render_tiles(c,p,room,owned):
 var grid: bool=room.spatial!=null and room.spatial.grid
 var layout:=grid_layout(room) if grid else {}
 if room.spatial!=null and c.construction!=null:c.construction.draw_floor(c,room,layout)
 var ids=layout.ids if grid else room.buildings.keys() if room.spatial!=null else range(room.tile_count())
 var low_detail := CinematicQuality.detail(c)==0
 var hide_empty_pads: bool = low_detail and not owned and c.model.is_procedural() and c.model.full_grid_requested
 var visible: Rect2=p.visible_world_rect(c,110)
 var decoration_view := visible.grow(-40)
 for tile in ids:
  var center: Vector2=layout.entries[tile].center if grid else room.tile_position(tile)
  if room.spatial!=null and c.construction!=null and c.construction.last_visual.get("id",-1)==tile:
   center=c.construction.rendered_position(room,tile)
  var point:=OFFSET+center
  if not visible.has_point(point):continue
  if not room.buildings.has(tile):
   if hide_empty_pads or not decoration_view.has_point(point):continue
   c.draw_style_box(p.frame(Color("333E3E") if owned else Color("303839"),Color("7C8270") if owned else Color("414D4B"),4),Rect2(point-Vector2(22,21),Vector2(44,42)))
   c.draw_line(point+Vector2(-18,-17),point+Vector2(18,-17),Color("89917C") if owned else Color("4C5854"),1)
   for side in [-1,1]:c.draw_circle(point+Vector2(side*17,16),1.2,Color("9B947B"))
   c.draw_line(point-Vector2(5,0),point+Vector2(5,0),Color("AFC8C8"),1.5)
   c.draw_line(point-Vector2(0,5),point+Vector2(0,5),Color("AFC8C8"),1.5)
   p.text(c,str(tile+1),point+Vector2(-17,16),8,Color("C3D5D2"))
  else:
   var building=room.buildings[tile]
   var target=p.building_visual.weapon_target(c.model,room,tile,building.kind,building.flash) if building.kind in DefenseEffects.WEAPONS else Vector2.ZERO
   var activity=building.flash
   if p.building_visual.support_rebirth_active(building.kind):
    activity=p.building_visual.support_activity(room,building,c.model)
   elif building.kind=="generator":activity=1.0 if room.alive and room.sleeping and not room.production_paused else 0.0
   elif building.kind=="repair":activity=1.0 if room.alive and room.sleeping and room.door_hp>0 and room.door_hp<room.max_hp() and (StrategyCatalog.support(building).get("power_cost",0)==0 or room.electricity>0) else 0.0
   elif building.kind in ["auto_repair","shield","decoy"]:activity=1.0 if building.cooldown>0 else 0.0
   var scale := 1.0
   if grid:
    var entry: Dictionary=layout.entries[tile]
    scale=entry.scale
    if entry.rotation!=0:
     var footprint: Rect2=entry.rect
     footprint.position+=point-entry.center
     draw_grid_facing(c,footprint,entry.rotation,Color("c3aa79"))
   p.building_visual.draw(c,p,building.kind,building.level,point,building.get("specialization",""),activity,target,p.clock if owned or c.watched_room==room.index else 0.0,0.0,scale)
   if owned and building.kind in ["turret","heavy"]:CosmeticPresentation.turret(c,point)
   var branch=str(building.get("specialization",""))
   if branch!="" and owned and c.selected_tile==tile and c.ui.context_open:
    c.draw_texture_rect(PremiumButton.texture(branch),Rect2(point+Vector2(15,-17),Vector2(12,12)),false)
   if building.kind in ["turret","heavy"] and building.flash>0 and not p.building_visual.weapon_rebirth_active(building.kind):
    var direction=target.normalized()
    var muzzle=point+direction*21-Vector2(0,5)
    var side=Vector2(-direction.y,direction.x)
    var flash=clampf(building.flash/.15,0,1)
    c.draw_colored_polygon(PackedVector2Array([muzzle-side*4,muzzle+direction*(7+flash*10),muzzle+side*4]),Color("E5C898") if building.kind=="heavy" else Color("A1E0DB"))
    if not c.profile.settings.reduced_effects:c.draw_circle(muzzle,9,Color(.8,.75,.45,.12*flash))
   if building.level<5 and not grid:
    for pip in range(building.level):c.draw_circle(point+Vector2(-(building.level-1)*2+pip*4,24),1.5,Color("BFCDB9"))
  if not grid and owned and c.selected_tile==tile and c.ui.context_open:
   p.selection_outline(c,point)
 if owned and room.spatial==null and c.pending_build!="":
  var point=OFFSET+c.preview_position
  var color=Color("7BE3A1") if c.placement_reason()=="" else Color("F05467")
  c.draw_style_box(p.frame(Color(color,0.12),color,6),Rect2(point-Vector2(27,26),Vector2(54,52)))
  var name=p.building_key(c.pending_build,1)
  p.sprite(c,name,point-Vector2(0,5),Vector2(53,56),Color(1,1,1,0.6))

func render_door(c,p,room):
 var point=OFFSET+room.door_position()
 if not CinematicQuality.reduced_motion(c):
  if c.get("horror")!=null:point+=c.horror.door_shake(room.index)
  if p.hunter_combat.enabled:point+=p.hunter_combat.door_kick(c.model,room.index)
 var normal=room.door_normal()
 var angle=PI/2 if absf(normal.x)>0.5 else 0.0
 c.draw_set_transform(point,angle)
 c.draw_style_box(p.frame(Color("526D75"),Color("243B45"),4),Rect2(-Vector2(32,10),Vector2(64,36)))
 if room.door_hp>0:
  var color=Color(1.65,0.65,0.65) if room.damage_flash>0 else Color.WHITE
  var redesigned: bool=c.model.living_dorm_requested
  if redesigned and room.damage_flash<=0.0:
   color={"hospital":Color("BDD7D7"),"hotel":Color("E2BCC1"),"lab":Color("AFD3C2"),"mansion":Color("DFC7B5")}.get(c.model.map_data.get("theme"),Color.WHITE)
  if room.closed:
   p.building_visual.draw(c,p,"door",room.door_level+1,point,room.door_branch,room.damage_flash,Vector2.ZERO,p.clock,angle,1.0,color if redesigned else Color.WHITE)
   c.draw_set_transform(point,angle)
  else: c.draw_texture_rect(p.cartoon.door_1,Rect2(Vector2(-47,-20),Vector2(36,50)),false,Color("94AAB2"))
  if room.owner==0 and room.closed:CosmeticPresentation.door(c)
  if redesigned and room.closed:
   var condition: float=room.door_hp/maxf(1.0,room.max_hp())
   if condition<.80:c.draw_line(Vector2(-12,-25),Vector2(-7,-29),Color("AB9A83"),1.0)
   if condition<.30:c.draw_polyline(PackedVector2Array([Vector2(8,-40),Vector2(2,-32),Vector2(8,-25),Vector2(1,-17),Vector2(12,-11)]),Color("1F1319"),2.0)
  if room.door_hp<room.max_hp()*0.55:
   c.draw_polyline(PackedVector2Array([Vector2(-8,-29),Vector2(1,-16),Vector2(-4,-5),Vector2(10,5)]),Color("382432"),2)
 else:
  for i in range(4): c.draw_line(Vector2(-25+i*14,-7),Vector2(-19+i*13,13),Color("88684E"),5)
 c.draw_set_transform(Vector2.ZERO)

func render_door_status(c,p,room):
 if c.construction!=null and c.construction.focused_grid(room):return
 var point=OFFSET+room.door_position();var normal=room.door_normal()
 if room.owner>=0:
  var targeted=c.model.hunter.target==room.index and c.model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
  var where=point+Vector2(40,-25) if absf(normal.x)<0.5 else point+Vector2(-35,50)
  var label_screen=c.get_canvas_transform()*where
  if label_screen.y>75 and label_screen.y<150:
   where+=c.get_canvas_transform().basis_xform_inv(Vector2(0,155-label_screen.y))
  if room.owner==0 or targeted:
   var ward=room.magic_state.shield>0
   c.draw_style_box(p.frame(Color("111B24"),Color("65736D"),3),Rect2(where+Vector2(-4,-20),Vector2(80,46 if ward else 33)))
   p.text(c,"%d/%d" % [roundi(room.door_hp),roundi(room.max_hp())],where+Vector2(0,-6),11,Color("F1E3CA"))
   if ward:p.text(c,"WARD %.0f" % room.magic_state.shield,where+Vector2(0,22),9,Color("9CEBF2"))
  p.bar(c,where,70,room.door_hp/room.max_hp())
