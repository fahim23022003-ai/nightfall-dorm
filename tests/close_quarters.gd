extends SceneTree

var failures:=0
var checks:=0
var previous: Array[float]=[]
var preview: Array[float]=[]

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  if failures<=20:push_error(label)

func nearest_floor(point: Vector2,normal: Vector2,corridors: Array) -> float:
 var near:=400.0
 for rect: Rect2 in corridors:
  if normal.x!=0 and (point.y<rect.position.y or point.y>=rect.end.y):continue
  if normal.y!=0 and (point.x<rect.position.x or point.x>=rect.end.x):continue
  var a: float=(rect.position-point).dot(normal)
  var b: float=(rect.end-point).dot(normal)
  if maxf(a,b)>=0:near=minf(near,maxf(0,minf(a,b)))
 return near

func get_gaps(old: Dictionary,next: Dictionary) -> void:
 for room: Dictionary in old.rooms:
  var r: Rect2=room.bounds
  for direction: Vector2i in NightmareMacroLayout.DIRECTIONS:
   var normal:=Vector2(direction)
   var center:=r.get_center()+normal*r.size*.5
   var tangent:=normal.orthogonal()
   for step: float in [-.35,-.18,0.0,.18,.35]:
    var point:=center+tangent*step*(r.size*tangent.abs()).length()
    if not NightmareMap.contains_point(room,point-normal):continue
    previous.append(nearest_floor(point,normal,old.corridors))
    preview.append(nearest_floor(point,normal,next.corridors))

func verify_routes(model: MatchModel,layout: Dictionary,label: String) -> void:
 var routes:=model.hunter_route_costs(layout.hunter_spawn)
 for room: RoomState in model.rooms:
  check(is_finite(float(routes.get(room.index,INF))),label+" reachable Hunter approach")
  check(not model.navigation_path(layout.spawn,room.door_approach(),true).is_empty(),label+" reachable survivor approach")
 for hall: Dictionary in layout.halls.values():
  check(not model.navigation_path(layout.hunter_spawn,hall.center).is_empty(),label+" reachable Hall")
 for e: Array in layout.lane_links:
  var a: Vector2=layout.nodes[e[0]]
  var b: Vector2=layout.nodes[e[1]]
  # Continuous clearance along each encoded lane, including its tight corners.
  check(NightmareNavigation.visible(model,a,b,false,true) and NightmareNavigation.visible(model,a,b,true,true),label+" lane clearance")

func run() -> void:
 for theme: String in MapCatalog.IDS:
  for family: String in NightmareMacroLayout.FAMILY_IDS:
   for seed: int in [73,8649,10358,12336]:
    var label:="%s/%s/%d" % [theme,family,seed]
    var old:=NightmareMacroLayout.generate(theme,seed,family)
    var preview_map:=NightmareMacroLayout.generate(theme,seed,family,true)
    var snapshot:=NightmareMap.pack(preview_map)
    var restored:=NightmareMap.unpack(JSON.parse_string(JSON.stringify(snapshot)),theme)
    check(not restored.is_empty() and NightmareMap.pack(restored)==snapshot,label+" V3 JSON round trip")
    check(preview_map.rooms==old.rooms and preview_map.halls==old.halls and preview_map.spawn==old.spawn and preview_map.hunter_spawn==old.hunter_spawn,label+" original interiors, halls and spawn preserved")
    check(snapshot==NightmareMap.pack(NightmareMacroLayout.generate(theme,seed,family,true)),label+" deterministic V3")
    snapshot.version=4
    check(NightmareMap.unpack(snapshot,theme).is_empty(),label+" future geometry rejected")
    get_gaps(old,preview_map)
    var model:=MatchModel.new()
    model.reset(seed)
    check(model.configure_map(theme,NightmareMap.pack(preview_map)),label+" production stored-layout path")
    if not model.map_data.is_empty():verify_routes(model,preview_map,label)
 previous.sort();preview.sort()
 print("CLOSE_QUARTERS_GAPS samples=",preview.size()," baseline_median=",previous[previous.size()/2]," baseline_p95=",previous[ceili(previous.size()*.95)-1]," preview_median=",preview[preview.size()/2]," preview_p95=",preview[ceili(preview.size()*.95)-1])
 print("CLOSE_QUARTERS_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
