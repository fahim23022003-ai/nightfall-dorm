class_name MapCatalog
extends RefCounted

const IDS=["abandoned_dorm","haunted_hospital","forgotten_hotel","underground_lab","cursed_mansion"]
static func _room(rect: Rect2,normal: Vector2,capacity: int,anchor: Vector2) -> Dictionary:
 var c=rect.get_center()
 var vertical=absf(normal.y)>0
 var door=c+Vector2(-105,normal.y*rect.size.y/2) if vertical else c+Vector2(normal.x*rect.size.x/2,-105)
 var bed=c+Vector2(-rect.size.x/2+43,-rect.size.y/2+63) if vertical else c+Vector2(-rect.size.x/2+63,-rect.size.y/2+43)
 var tiles: Array=[]
 var columns=4 if capacity>=16 else 3
 for i in range(capacity):
  var x=-35+(i%columns)*58
  var y=-85+int(i/columns)*58
  tiles.append(c+Vector2(x,y) if vertical else c+Vector2(y,x))
 return {"bounds":rect,"door":door,"door_normal":normal,"bed":bed,"cabinet":c+Vector2(-rect.size.x/2+45,rect.size.y/2-43),"plant":c+Vector2(-rect.size.x/2+30,30),"tiles":tiles,"anchor":anchor}
static func _segment(a: Vector2,b: Vector2,width: float=80) -> Rect2:
 return Rect2(Vector2(minf(a.x,b.x),minf(a.y,b.y))-Vector2.ONE*width/2,(a-b).abs()+Vector2.ONE*width)
static func map(id: String) -> Dictionary:
 var index=IDS.find(id)
 if index<0: return {}
 var names=["Abandoned Student Dorm","Haunted Hospital","Forgotten Hotel","Underground Laboratory","Cursed Mansion"]
 var themes=["dorm","hospital","hotel","lab","mansion"]
 var rooms: Array=[]
 var nodes: Array=[]
 var corridors: Array=[]
 var pairs: Array=[]
 if index==0:
  nodes=[Vector2(75,320),Vector2(475,320),Vector2(875,320)]
  pairs=[[0,1],[1,2]]
  for i in range(6):
   var col=i%3
   var top=i<3
   rooms.append(_room(Rect2(col*400,-80 if top else 400,360,320),Vector2.DOWN if top else Vector2.UP,12,nodes[col]))
 elif index==1:
  nodes=[Vector2(90,310),Vector2(510,310),Vector2(930,310),Vector2(90,430),Vector2(510,430),Vector2(930,430)]
  pairs=[[0,1],[1,2],[0,3],[1,4],[2,5],[3,4],[4,5]]
  for i in range(6):
   var top=i<3
   var col=i%3
   rooms.append(_room(Rect2(col*420+15,-85 if top else 510,350,315),Vector2.DOWN if top else Vector2.UP,10 if col==1 else 12,nodes[i]))
 elif index==2:
  for i in range(6): nodes.append(Vector2(i*340+55,300))
  for i in range(5): pairs.append([i,i+1])
  for i in range(6):
   rooms.append(_room(Rect2(i*340,-90 if i%2==0 else 390,330,310),Vector2.DOWN if i%2==0 else Vector2.UP,10,nodes[i]))
 elif index==3:
  nodes=[Vector2(430,80),Vector2(430,480),Vector2(430,880),Vector2(610,80),Vector2(610,480),Vector2(610,880)]
  pairs=[[0,1],[1,2],[3,4],[4,5],[0,3],[2,5]]
  for i in range(6):
   var left=i<3
   var row=i%3
   rooms.append(_room(Rect2(-15 if left else 700,row*400-80,350,340),Vector2.RIGHT if left else Vector2.LEFT,12,nodes[i]))
 else:
  nodes=[Vector2(80,350),Vector2(540,350),Vector2(1000,350),Vector2(80,500),Vector2(540,500),Vector2(1000,500)]
  pairs=[[0,1],[1,2],[1,4],[3,4],[4,5]]
  for i in range(6):
   var top=i<3
   var col=i%3
   var size=Vector2(390,350) if col!=1 else Vector2(350,315)
   rooms.append(_room(Rect2(Vector2(col*460,-80 if top else 590),size),Vector2.DOWN if top else Vector2.UP,16 if col!=1 else 10,nodes[i]))
 for pair in pairs: corridors.append(_segment(nodes[pair[0]],nodes[pair[1]]))
 for room in rooms:
  var door: Vector2=room.door
  var anchor: Vector2=room.anchor
  var bend=Vector2(door.x,anchor.y) if absf(room.door_normal.y)>0 else Vector2(anchor.x,door.y)
  corridors.append(_segment(door,bend))
  corridors.append(_segment(bend,anchor))
  nodes.append(bend)
 var bounds: Rect2=rooms[0].bounds
 for room in rooms: bounds=bounds.merge(room.bounds)
 for corridor in corridors: bounds=bounds.merge(corridor)
 return {"id":id,"title":names[index],"theme":themes[index],"rooms":rooms,"nodes":nodes,"corridors":corridors,"spawn":nodes[0],"hunter_spawn":nodes[mini(2,nodes.size()-1)],"bounds":bounds.grow(35)}
