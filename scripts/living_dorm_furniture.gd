class_name LivingDormFurniture
extends RefCounted
## Fresh geometry only. Keep door, bed, access waypoints and all NPC pads.

static func arrange(layout: Dictionary) -> void:
 _tuck(layout,"cabinet")
 _tuck(layout,"plant")

static func _tuck(layout: Dictionary, kind: String) -> void:
 var original: Vector2=layout[kind]
 var strips: Array=layout.floor
 var best:=original
 var distance:=INF
 for wall in layout.walls:
  var start: Vector2=wall[0]
  var finish: Vector2=wall[1]
  if start.distance_to(finish)<72.0:
   continue
  var tangent:=start.direction_to(finish)
  var inset_start:=start+tangent*30.0
  var inset_finish:=finish-tangent*30.0
  var nearest:=Geometry2D.get_closest_point_to_segment(original,inset_start,inset_finish)
  var normal:=tangent.orthogonal()
  for step in [0,-24,24,-48,48,-72,72]:
   var along:=Geometry2D.get_closest_point_to_segment(nearest+tangent*float(step),inset_start,inset_finish)
   for side in [-1,1]:
    var candidate:=along+normal*float(side)*(44.0 if kind=="cabinet" else 34.0)
    candidate=candidate.snapped(Vector2(2,2))
    var d:=candidate.distance_squared_to(original)
    if d>=distance or d>112.0*112.0 or not _fits(layout,strips,kind,candidate):
     continue
    best=candidate
    distance=d
 layout[kind]=best

static func _fits(layout: Dictionary, strips: Array, kind: String, point: Vector2) -> bool:
 var envelope:=Rect2(point-Vector2(25,29),Vector2(50,62)) if kind=="cabinet" else Rect2(point-Vector2(17,18),Vector2(34,43))
 if not strips.any(func(strip):return strip.intersects(envelope)) or not NightmareMap.contains_rect(layout,envelope,8.0):
  return false
 var keep_clear:=SpatialConstruction.blocked_for(layout)
 for index in [0,2 if kind=="cabinet" else 1,3]:
  if envelope.intersects(keep_clear[index].rect.grow(12.0)):
   return false
 for route: Rect2 in layout.access_route:
  if envelope.intersects(route.grow(8.0)):
   return false
 for point_on_route: Vector2 in layout.interior_nodes:
  if envelope.grow(12.0).has_point(point_on_route):
   return false
 var footprint:=Rect2(point+Vector2(-22,1),Vector2(44,28)) if kind=="cabinet" else Rect2(point+Vector2(-14,3),Vector2(28,22))
 for pad: Vector2 in layout.tiles:
  if footprint.intersects(SpatialConstruction.footprint(pad)):
   return false
 return true
