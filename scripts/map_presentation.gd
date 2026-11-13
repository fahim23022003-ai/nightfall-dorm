extends RefCounted
## Original procedural environments over shared model geometry and existing art.
## Decorations are presentation only; collision remains entirely map-owned.
const OFFSET=Vector2(145,40)
var floors={}
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
 for corridor in data.corridors:
  var rect=Rect2(OFFSET+corridor.position,corridor.size)
  if not visible.intersects(rect):continue
  c.draw_style_box(p.frame(colors[2],colors[3],3),rect.grow(4))
  c.draw_texture_rect(floors[theme],rect,true,Color("737B7B"))
  # Metal service rails, rivets and warm wall lights anchor corridor depth.
  for i in range(0,int(rect.size.x),64):
   var q=rect.position+Vector2(i+8,8)
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
 for room in c.model.rooms:
  if visible.intersects(Rect2(OFFSET+room.bounds().position,room.bounds().size)):render_room(c,p,room,theme,colors)
 var title=OFFSET+data.bounds.position+Vector2(10,-20)
 if c.full_map:p.text(c,str(data.title).to_upper(),title,18,colors[4])

func render_room(c,p,room,theme,colors):
 var r=Rect2(OFFSET+room.bounds().position,room.bounds().size)
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
 if owned:
  c.draw_style_box(p.frame(Color.TRANSPARENT,Color("7BE3A1"),5),r.grow(11))
  if not expanded_horizontal:p.text(c,"YOUR ROOM",r.position+Vector2(10,r.size.y-12),11,Color("D4FFE1"))
 var plaque=r.position+Vector2(10,r.size.y-58 if expanded_horizontal else 18)
 p.text(c,"%02d · %s" % [room.index+1,room.survivor_name() if room.owner>=0 else "VACANT"],plaque,11,Color("EDF4ED"))
 if room.trait_id!="":
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
 p.sprite(c,"bed_upgraded" if room.bed_level>=2 else "bed",bed,Vector2(66,92),bed_tint)
 if owned:CosmeticPresentation.bed(c,bed)
 var cabinet=OFFSET+room.cabinet_position()
 p.sprite(c,"cabinet" if theme not in ["lab","hotel"] else "utility" if theme=="lab" else "desk",cabinet,Vector2(38,48))
 p.sprite(c,"plant",OFFSET+room.plant_position(),Vector2(25,34),Color("A5C6A0") if theme=="hospital" else Color.WHITE)
 render_decor(c,p,r,bed,cabinet,theme,colors)
 render_tiles(c,p,room,owned)

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

func render_tiles(c,p,room,owned):
 for tile in range(room.tile_count()):
  var point=OFFSET+room.tile_position(tile)
  if not room.buildings.has(tile):
   c.draw_style_box(p.frame(Color("333E3E") if owned else Color("303839"),Color("7C8270") if owned else Color("414D4B"),4),Rect2(point-Vector2(22,21),Vector2(44,42)))
   c.draw_line(point+Vector2(-18,-17),point+Vector2(18,-17),Color("89917C") if owned else Color("4C5854"),1)
   for side in [-1,1]:c.draw_circle(point+Vector2(side*17,16),1.2,Color("9B947B"))
   c.draw_line(point-Vector2(5,0),point+Vector2(5,0),Color("AFC8C8"),1.5)
   c.draw_line(point-Vector2(0,5),point+Vector2(0,5),Color("AFC8C8"),1.5)
   p.text(c,str(tile+1),point+Vector2(-17,16),8,Color("C3D5D2"))
  else:
   var building=room.buildings[tile]
   var name=p.building_key(building.kind,building.level)
   # Fixed dimensions preserve character/building scale as capacities expand.
   var size=Vector2(53,56)
   var target=c.model.hunter.position-room.tile_position(tile)
   var tilt=clampf(atan2(target.y,absf(target.x)),-0.4,0.4) if building.kind=="turret" else 0.0
   p.sprite(c,name,point-Vector2(0,6),size,Color.WHITE,tilt)
   if owned and building.kind in ["turret","heavy"]:CosmeticPresentation.turret(c,point)
   var branch=str(building.get("specialization",""))
   if branch!="":
    var tint={"precision":Color("DDC68E"),"suppression":Color("9BD3B2"),"focus":Color("BFACE0"),"storm":Color("93DFDF")}.get(branch,Color("B7D2B4"))
    c.draw_arc(point+Vector2(0,7),23,.1,PI-.1,16,Color(tint,.75),2)
    c.draw_texture_rect(PremiumButton.texture(branch),Rect2(point+Vector2(11,-32),Vector2(20,20)),false)
    if branch=="precision":c.draw_line(point+Vector2(0,-15),point+target.normalized()*32-Vector2(0,15),tint,5)
    elif branch=="storm":
     for side in [-1,1]:c.draw_line(point+Vector2(side*17,-6),point+Vector2(side*22,-22),tint,3)
   if building.kind in ["turret","heavy"] and building.flash>0:
    var direction=target.normalized()
    var muzzle=point+direction*21-Vector2(0,5)
    var side=Vector2(-direction.y,direction.x)
    var flash=clampf(building.flash/.15,0,1)
    c.draw_colored_polygon(PackedVector2Array([muzzle-side*4,muzzle+direction*(7+flash*10),muzzle+side*4]),Color("E5C898") if building.kind=="heavy" else Color("A1E0DB"))
    if not c.profile.settings.reduced_effects:c.draw_circle(muzzle,9,Color(.8,.75,.45,.12*flash))
   if building.level<5:
    for pip in range(building.level):c.draw_circle(point+Vector2(-(building.level-1)*2+pip*4,24),1.5,Color("BFCDB9"))
  if owned and c.selected_tile==tile and c.ui.context_open:
   p.selection_outline(c,point)
 if owned and c.pending_build!="":
  var point=OFFSET+c.preview_position
  var color=Color("7BE3A1") if c.placement_reason()=="" else Color("F05467")
  c.draw_style_box(p.frame(Color(color,0.12),color,6),Rect2(point-Vector2(27,26),Vector2(54,52)))
  var name=p.building_key(c.pending_build,1)
  p.sprite(c,name,point-Vector2(0,5),Vector2(53,56),Color(1,1,1,0.6))

func render_door(c,p,room):
 var point=OFFSET+room.door_position()
 if c.get("horror")!=null: point+=c.horror.door_shake(room.index)
 var normal=room.door_normal()
 var angle=PI/2 if absf(normal.x)>0.5 else 0.0
 c.draw_set_transform(point,angle)
 c.draw_style_box(p.frame(Color("526D75"),Color("243B45"),4),Rect2(-Vector2(32,10),Vector2(64,36)))
 if room.door_hp>0:
  var color=Color(1.65,0.65,0.65) if room.damage_flash>0 else Color.WHITE
  if room.closed:
   c.draw_texture_rect(p.cartoon["door_%d" % mini(5,room.door_level+1)],Rect2(Vector2(-36,-41),Vector2(73,61)),false,color)
  else: c.draw_texture_rect(p.cartoon.door_1,Rect2(Vector2(-47,-20),Vector2(36,50)),false,Color("94AAB2"))
  if room.owner==0 and room.closed:CosmeticPresentation.door(c)
  if room.door_hp<room.max_hp()*0.55:
   c.draw_polyline(PackedVector2Array([Vector2(-8,-29),Vector2(1,-16),Vector2(-4,-5),Vector2(10,5)]),Color("382432"),2)
 else:
  for i in range(4): c.draw_line(Vector2(-25+i*14,-7),Vector2(-19+i*13,13),Color("88684E"),5)
 c.draw_set_transform(Vector2.ZERO)
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
