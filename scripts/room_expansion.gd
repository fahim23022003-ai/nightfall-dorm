class_name RoomExpansion
extends RefCounted
const SLOTS=[3,6,8,10,11,12,14,16]
const NAMES=["Foundation","Level 1","Level 2","Level 3","Level 4","Level 5","Ultimate I","Ultimate II"]
const COSTS=[Vector2.ZERO,Vector2(120,15),Vector2(240,35),Vector2(450,65),Vector2(700,110),Vector2(1050,180),Vector2(1600,280),Vector2(2400,420)]
var legacy=false
var initialized=false
static func legacy_tier(capacity: int) -> int:
 for i in range(SLOTS.size()):
  if SLOTS[i]>=capacity:return i
 return 7
static func geometry(id: String,index: int,tier: int,old_layout: bool=false) -> Dictionary:
 var map=MapCatalog.map(id)
 if map.is_empty() or index<0 or index>=6 or tier<0 or tier>=SLOTS.size():return {}
 var data=map.rooms[index].duplicate(true);var normal: Vector2=data.door_normal;var door: Vector2=data.door
 var vertical=absf(normal.y)>0;var tangent=Vector2.RIGHT if vertical else Vector2.DOWN
 var target=SLOTS[tier];var rect: Rect2=data.bounds
 if old_layout:
  target=maxi(target,data.tiles.size())
  var original=data.tiles.size();var columns=4 if original>=16 else 3
  var original_back=-INF;var extra_rows=0
  for point in data.tiles:original_back=maxf(original_back,(point-door).dot(-normal))
  var obstacles=[Rect2(data.bed-Vector2(27,45),Vector2(54,89)),Rect2(data.cabinet+Vector2(-18,5),Vector2(36,20)),Rect2(data.plant+Vector2(-10,7),Vector2(20,14))]
  # Retain the complete historical prefix, including its original column count.
  while data.tiles.size()<target:
   var n=data.tiles.size()
   if original<12 and n<12:
    var c=rect.get_center();var x=-35+(n%3)*58;var y=-85+int(n/3)*58
    data.tiles.append(c+Vector2(x,y) if vertical else c+Vector2(y,x))
   else:
    var back=original_back+58*extra_rows;extra_rows+=1
    var row=[]
    for col in range(columns):row.append(door-normal*(back+58)+tangent*(70+col*58))
    # Historical tangential coordinates may differ from the fresh front grid.
    for col in range(columns):
     var p: Vector2=data.tiles[col];row[col]=door-normal*(back+58)+tangent*(p-door).dot(tangent)
    for point in row:
     var pad=Rect2(point-Vector2(27,27),Vector2(54,54));var blocked=false
     for obstacle in obstacles:
      if pad.intersects(obstacle):blocked=true;break
     if data.tiles.size()<target and not blocked:data.tiles.append(point)
  var growth=maxi(0,target-original)*20.0
  if normal.y>0:rect.position.y-=growth;rect.size.y+=growth
  elif normal.y<0:rect.size.y+=growth
  elif normal.x>0:rect.position.x-=growth;rect.size.x+=growth
  else:rect.size.x+=growth
  # Include only added back-space; front wall and doorway never move.
  for point in data.tiles:
   var need=point-normal*34
   rect=rect.expand(need)
  data.bounds=rect
  return data
 var depth=210.0+15.0*(target-3)
 if normal.y>0:rect.position.y=door.y-depth;rect.size.y=depth
 elif normal.y<0:rect.position.y=door.y;rect.size.y=depth
 elif normal.x>0:rect.position.x=door.x-depth;rect.size.x=depth
 else:rect.position.x=door.x;rect.size.x=depth
 data.bounds=rect
 var rail=-32.0 if vertical else -13.0
 data.bed=door-normal*95+tangent*rail
 data.cabinet=door-normal*175+tangent*rail
 data.plant=door-normal*25+tangent*rail
 data.tiles=[]
 for i in range(target):data.tiles.append(door-normal*(65+int(i/3)*58)+tangent*(60+(i%3)*58))
 return data
func configure(model,old_layout: bool=false,levels: Array=[]) -> bool:
 if model.run_kind!="endless" or model.map_id not in MapCatalog.IDS:return false
 legacy=old_layout;initialized=true
 var source=MapCatalog.map(model.map_id)
 for i in range(6):
  var tier=int(levels[i]) if levels.size()==6 else legacy_tier(source.rooms[i].tiles.size()) if legacy else 0
  model.rooms[i].expansion_tier=tier
  model.rooms[i].layout=geometry(model.map_id,i,tier,legacy)
 refresh_geometry(model)
 return true
func refresh_geometry(model):
 model.map_data.rooms=[]
 var bounds: Rect2=model.rooms[0].bounds()
 for room in model.rooms:model.map_data.rooms.append(room.layout.duplicate(true));bounds=bounds.merge(room.bounds())
 for corridor in model.map_data.corridors:bounds=bounds.merge(corridor)
 model.map_data.bounds=bounds.grow(35);model._navigation_routes.clear();model._build_navigation()
func reason(model,index: int) -> String:
 if not initialized or model.run_kind!="endless":return "Physical room expansion is available in Endless Siege."
 if index<0 or index>=model.rooms.size():return "Choose your occupied room."
 var room=model.rooms[index]
 if not model.running or model.result!="" or not room.alive or not room.sleeping:return "An active occupied room is required."
 if room.expansion_tier>=7:return "Ultimate room complete: capacity sixteen buildings."
 var next=room.expansion_tier+1;var required=next if room.balance_version==2 else 1 if next==1 else 2 if next<4 else 3 if next<6 else 4
 if room.bed_level<required or room.door_level<required:return "Requires Bed and Door level %d." % (required+1)
 var cost=BalanceRules.expansion(next,room.balance_version)
 if room.gold+0.00001<cost.x:return "Need %.1f more Gold." % (cost.x-room.gold)
 if room.electricity+0.00001<cost.y:return "Need %.1f more Electricity." % (cost.y-room.electricity)
 return ""
func purchase(model,index: int=-1,npc: bool=false) -> bool:
 if index<0:index=model.player_room
 if index!=model.player_room and not npc:return false
 var error=reason(model,index)
 if error!="":
  if index>=0 and index<model.rooms.size():model.rooms[index].last_error=error
  return false
 var room=model.rooms[index];var next=room.expansion_tier+1;var cost=BalanceRules.expansion(next,room.balance_version)
 var layout=geometry(model.map_id,index,next,legacy)
 if layout.is_empty():return false
 if room.spatial!=null:
  # Keep occupied furniture anchors and every actual structure fixed.
  for key in ["bed","cabinet","plant"]:layout[key]=room.layout[key]
  for id in room.buildings:
   var layout_error=room.spatial.geometry_reason(room.tile_position(id),id,layout)
   if layout_error!="":return room.reject("Expansion would invalidate a structure: "+layout_error)
 if not room.pay(cost.x,cost.y,"physical room expansion"):return false
 if room.spatial!=null:room.spatial.undo_entry.clear()
 var before=room.bounds();room.expansion_tier=next;room.layout=layout;room.construction_actions+=1
 refresh_geometry(model)
 model.record_event("room_expanded",index,{"tier":next,"slots":room.tile_count(),"old_bounds":before,"bounds":room.bounds(),"gold":cost.x,"power":cost.y})
 return true
func snapshot(model) -> Dictionary:
 var levels=[]
 for room in model.rooms:levels.append(room.expansion_tier)
 return {"version":1,"legacy":legacy,"levels":levels}
static func valid(data,map: String) -> bool:
 if not data is Dictionary or data.get("version")!=1 or not data.get("legacy") is bool or not data.get("levels") is Array or data.levels.size()!=6:return false
 var source=MapCatalog.map(map)
 if source.is_empty():return false
 for i in range(6):
  if not ReplaySnapshot.whole(data.levels[i],0,7):return false
  if data.legacy and data.levels[i]<legacy_tier(source.rooms[i].tiles.size()):return false
 return true
