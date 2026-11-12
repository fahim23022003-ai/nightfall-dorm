extends RefCounted
## Original procedural environments over shared model geometry and existing art.
## Decorations are presentation only; collision remains entirely map-owned.
const OFFSET=Vector2(145,40)
const PALETTES={
 "dorm":[Color("5C5C58"),Color("66665D"),Color("39494E"),Color("B7A078"),Color("D6BC77")],
 "hospital":[Color("9CACAB"),Color("829797"),Color("4B727B"),Color("D0E2DC"),Color("8DCFD5")],
 "hotel":[Color("54465C"),Color("635067"),Color("352F48"),Color("B99E69"),Color("D4AB82")],
 "lab":[Color("354B55"),Color("415A60"),Color("233640"),Color("80ADA8"),Color("75DED1")],
 "mansion":[Color("604D43"),Color("755D47"),Color("3F3540"),Color("B29B70"),Color("E5B76D")]
}
func render_architecture(c,p):
 var data=c.model.map_data
 var theme=str(data.get("theme","dorm"))
 var colors=PALETTES.get(theme,PALETTES.dorm)
 for corridor in data.corridors:
  var rect=Rect2(OFFSET+corridor.position,corridor.size)
  c.draw_style_box(p.frame(colors[2],colors[3],3),rect.grow(4))
  c.draw_rect(rect,colors[0].darkened(0.28))
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
 for room in c.model.rooms: render_room(c,p,room,theme,colors)
 var title=OFFSET+data.bounds.position+Vector2(10,-20)
 p.text(c,str(data.title).to_upper(),title,18,colors[4])

func render_room(c,p,room,theme,colors):
 var r=Rect2(OFFSET+room.bounds().position,room.bounds().size)
 c.draw_style_box(p.frame(Color("14232D"),Color("111E26"),7),r.grow(9))
 c.draw_rect(r,colors[0])
 var step=32 if theme=="hospital" else 24
 for x in range(0,int(r.size.x),step):
  for y in range(0,int(r.size.y),step):
   var fill=colors[1] if (x/step+y/step)%2==0 else colors[0]
   if theme in ["dorm","mansion"]:
    c.draw_rect(Rect2(r.position+Vector2(x,y),Vector2(minf(step-1,r.size.x-x),minf(step-2,r.size.y-y))),fill)
   elif theme=="hospital":
    c.draw_rect(Rect2(r.position+Vector2(x,y),Vector2(minf(step-1,r.size.x-x),minf(step-1,r.size.y-y))),fill)
   elif theme=="hotel":
    c.draw_circle(r.position+Vector2(x+5,y+5),1.2,colors[3].darkened(0.35))
   else:
    c.draw_rect(Rect2(r.position+Vector2(x,y),Vector2(minf(step,r.size.x-x),minf(step,r.size.y-y))),colors[1],false,0.7)
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
 var owned=room.index==c.model.player_room
 if owned:
  c.draw_style_box(p.frame(Color.TRANSPARENT,Color("7BE3A1"),5),r.grow(11))
  p.text(c,"YOUR ROOM",r.position+Vector2(10,r.size.y-12),11,Color("D4FFE1"))
 var plaque=r.position+Vector2(10,18)
 p.text(c,"%02d · %s" % [room.index+1,room.survivor_name() if room.owner>=0 else "VACANT"],plaque,11,Color("EDF4ED"))
 # Original illustrations stay in the dedicated furniture strip from map data.
 var bed=OFFSET+room.bed_position()
 if theme in ["hotel","mansion"]:
  c.draw_style_box(p.frame(Color("6B4053") if theme=="hotel" else Color("4F3540"),colors[3],5),Rect2(bed-Vector2(43,55),Vector2(86,116)))
 var bed_tint=Color("D7ECEB") if theme=="hospital" else Color("BACDD5") if theme=="lab" else Color.WHITE
 p.sprite(c,"bed_upgraded" if room.bed_level>=2 else "bed",bed,Vector2(66,92),bed_tint)
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
 var glow=r.position+Vector2(25,36)
 p.sprite(c,"warm_glow",glow,Vector2(145,145),Color(colors[4],0.3))
 p.sprite(c,"lantern",glow,Vector2(17,28),colors[4])

func render_tiles(c,p,room,owned):
 for tile in range(room.tile_count()):
  var point=OFFSET+room.tile_position(tile)
  if not room.buildings.has(tile):
   c.draw_style_box(p.frame(Color("657F86") if owned else Color("53666A"),Color("344D59"),6),Rect2(point-Vector2(22,21),Vector2(44,42)))
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
   for pip in range(building.level): c.draw_circle(point+Vector2(-7+pip*5,24),1.5,Color("7BE3A1"))
  if owned and c.selected_tile==tile and c.ui.context_open:
   c.draw_style_box(p.frame(Color.TRANSPARENT,Color("7BE3A1"),6),Rect2(point-Vector2(26,25),Vector2(52,50)))
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
   c.draw_texture_rect(p.cartoon["door_%d" % (room.door_level+1)],Rect2(Vector2(-36,-41),Vector2(73,61)),false,color)
  else: c.draw_texture_rect(p.cartoon.door_1,Rect2(Vector2(-47,-20),Vector2(36,50)),false,Color("94AAB2"))
  if room.door_hp<room.max_hp()*0.55:
   c.draw_polyline(PackedVector2Array([Vector2(-8,-29),Vector2(1,-16),Vector2(-4,-5),Vector2(10,5)]),Color("382432"),2)
 else:
  for i in range(4): c.draw_line(Vector2(-25+i*14,-7),Vector2(-19+i*13,13),Color("88684E"),5)
 c.draw_set_transform(Vector2.ZERO)
 if room.owner>=0:
  var targeted=c.model.hunter.target==room.index and c.model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
  var where=point+Vector2(40,-25) if absf(normal.x)<0.5 else point+Vector2(-35,-65)
  p.bar(c,where,70,room.door_hp/room.max_hp())
  if room.owner==0 or targeted: p.text(c,"%d/%d" % [room.door_hp,room.max_hp()],where+Vector2(0,-5),10,Color("F1D5C7"))
