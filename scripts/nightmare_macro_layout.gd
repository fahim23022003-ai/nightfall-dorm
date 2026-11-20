class_name NightmareMacroLayout
extends RefCounted
## Room sites and circulation are generated independently. Sparse lot edges
## are a collision-safe coordinate system, never a fixed map rectangle.
const FAMILY_IDS := ["ring", "branching", "scattered", "spine", "zigzag", "radial", "twin_wings", "labyrinth", "courtyards", "hybrid"]
const VERSION := 2
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const EDGE_ENDS := [
 [Vector2i.ZERO, Vector2i.RIGHT], [Vector2i.RIGHT, Vector2i.ONE],
 [Vector2i.DOWN, Vector2i.ONE], [Vector2i.ZERO, Vector2i.DOWN],
]
const HALLS := {"north":Vector2.UP, "south":Vector2.DOWN, "west":Vector2.LEFT, "east":Vector2.RIGHT}

static func family_for(id: String, seed: int) -> String:
 var rng := RandomNumberGenerator.new()
 rng.seed = seed ^ hash(id + "/macro-family")
 return FAMILY_IDS[rng.randi_range(0, FAMILY_IDS.size()-1)]

static func generate(id: String, seed: int, family_override: String="") -> Dictionary:
 var theme := MapCatalog.map(id)
 if theme.is_empty() or (not family_override.is_empty() and family_override not in FAMILY_IDS):
  return {}
 var family := family_for(id,seed) if family_override.is_empty() else family_override
 var rng := RandomNumberGenerator.new()
 rng.seed = seed ^ hash(id + "/" + family + "/macro-v2")
 var plan := _design(rng, family)
 var sites: Array[Vector2i] = plan.sites
 var paths: Array = plan.paths
 var turn := rng.randi_range(0,3)
 var mirror := rng.randi_range(0,1)==1
 for i in range(sites.size()):
  sites[i]=_oriented_site(sites[i],turn,mirror)
 for path in paths:
  for i in range(path.size()):
   path[i]=_oriented_vertex(path[i],turn,mirror)

 var streets := {}
 for path in paths:
  for i in range(1,path.size()):
   _street_path(streets,path[i-1],path[i],rng.randi_range(0,1)==1)
 # A room door always leads to a road. A room whose corner is a dead end
 # grows a short branch only on its own boundary.
 var door_streets: Array[int] = []
 for site in sites:
  var best: Array[int] = []
  var branches: Array[int] = []
  for side in range(4):
   var a: Vector2i = site+EDGE_ENDS[side][0]
   var b: Vector2i = site+EDGE_ENDS[side][1]
   if streets.has(_edge(a,b)):
    best.append(side)
   elif _junction(streets,a) or _junction(streets,b):
    branches.append(side)
  var selections: Array[int] = best
  if not branches.is_empty() and (best.is_empty() or rng.randf()<0.42):
   selections=branches
  # The family paths use site corners, including transformed/mirrored
  # corners, so each site has at least one connected side before selection.
  var chosen: int = selections[rng.randi_range(0,selections.size()-1)]
  door_streets.append(chosen)
  _add_street(streets,site+EDGE_ENDS[chosen][0],site+EDGE_ENDS[chosen][1])
  if family in ["ring","labyrinth","courtyards","hybrid"] and not branches.is_empty() and rng.randf()<0.55:
   var extra: int = branches[rng.randi_range(0,branches.size()-1)]
   _add_street(streets,site+EDGE_ENDS[extra][0],site+EDGE_ENDS[extra][1])

 var points: Array[Vector2i] = []
 for edge in streets.values():
  for point: Vector2i in edge:
   if point not in points:
    points.append(point)
 var bounds := Rect2i(points[0],Vector2i.ZERO)
 for point in points:
  bounds=bounds.expand(point)
 for site in sites:
  bounds=bounds.expand(site).expand(site+Vector2i.ONE)
 var x_axis := _axis(rng,bounds.position.x,bounds.end.x)
 var y_axis := _axis(rng,bounds.position.y,bounds.end.y)
 var result := {
  "version":VERSION, "family":family, "seed":seed, "id":id, "title":theme.title, "theme":theme.theme,
  "rooms":[], "nodes":[], "lane_links":[], "lane_widths":[], "corridors":[], "halls":{}
 }
 var nodes := {}
 for point in points:
  nodes[point]=NightmareMap._node(result,_world(point,x_axis,y_axis))
 var shapes: Array[int] = [0, 1, 2, 3, 4, rng.randi_range(0,4)]
 _shuffle(shapes,rng)
 var room_order: Array[int] = [0,1,2,3,4,5]
 _shuffle(room_order,rng)
 var road_anchors := {}
 for index in room_order:
  var site: Vector2i = sites[index]
  var corner := _world(site,x_axis,y_axis)
  var opposite := _world(site+Vector2i.ONE,x_axis,y_axis)
  var side: int = door_streets[index]
  var room := NightmareMap._room(rng,shapes[index],Rect2(corner,opposite-corner),side)
  result.rooms.append(room)
  var a: Vector2i = site+EDGE_ENDS[side][0]
  var b: Vector2i = site+EDGE_ENDS[side][1]
  var edge_key := _edge(a,b)
  if not road_anchors.has(edge_key):
   road_anchors[edge_key]=[]
  road_anchors[edge_key].append(room.anchor)

 for key in streets:
  var edge: Array = streets[key]
  var a: int = nodes[edge[0]]
  var b: int = nodes[edge[1]]
  var start: Vector2 = result.nodes[a]
  var waypoints: Array = road_anchors.get(key,[])
  waypoints.sort_custom(func(p: Vector2,q: Vector2): return p.distance_squared_to(start)<q.distance_squared_to(start))
  var previous := a
  var width := float(rng.randi_range(9,14)*8)
  for point: Vector2 in waypoints:
   var at := NightmareMap._node(result,point)
   _link(result,previous,at,width)
   previous=at
  _link(result,previous,b,width)
 for room in result.rooms:
  _link(result,NightmareMap._node(result,room.anchor),NightmareMap._node(result,room.approach),float(rng.randi_range(9,12)*8))

 # Both spawn positions are selected from real street junctions. The player
 # starts in a useful part of the map rather than being assigned a room.
 var extent := _extent(result)
 var spawn_candidates := _rank_nodes(result,points.size(),extent.get_center())
 result.spawn=result.nodes[spawn_candidates[rng.randi_range(0,mini(3,spawn_candidates.size()-1))]]
 var hunter_candidates := _rank_nodes(result,points.size(),extent.get_center().lerp(extent.position,.52) if rng.randf()<.5 else extent.get_center().lerp(extent.end,.52))
 var hunter_candidate: int = hunter_candidates[rng.randi_range(0,mini(4,hunter_candidates.size()-1))]
 if result.nodes[hunter_candidate]==result.spawn:
  hunter_candidate=hunter_candidates[0] if hunter_candidates[0]!=hunter_candidate else hunter_candidates[1]
 result.hunter_spawn=result.nodes[hunter_candidate]
 var coverage: Array[float] = []
 coverage.resize(sites.size())
 coverage.fill(1800.0)
 var access:=_hall_access(result,points.size())
 for hall in HALLS:
  _add_hall(result,hall,HALLS[hall],extent,access,coverage,rng)
 result.bounds=_extent(result).grow(24)
 return result

static func _design(rng: RandomNumberGenerator,family: String) -> Dictionary:
 match family:
  "ring":
   return _ring(rng)
  "branching":
   return _branches(rng,false)
  "scattered":
   return _scattered(rng,false)
  "spine":
   return _spine(rng,false)
  "zigzag":
   return _spine(rng,true)
  "radial":
   return _branches(rng,true)
  "twin_wings":
   return _wings(rng,false)
  "labyrinth":
   return _scattered(rng,true)
  "courtyards":
   return _courtyards(rng)
  _:
   return _wings(rng,true)

static func _ring(rng: RandomNumberGenerator) -> Dictionary:
 var east := rng.randi_range(3,4)
 var south := rng.randi_range(2,3)
 var sites: Array[Vector2i] = [
  Vector2i(0,0), Vector2i(rng.randi_range(1,east-1),-rng.randi_range(0,1)),
  Vector2i(east,0), Vector2i(east,south),
  Vector2i(rng.randi_range(1,east-1),south+rng.randi_range(0,1)), Vector2i(0,south)
 ]
 var paths := [sites.duplicate()]
 paths[0].append(sites[0])
 return {"sites":sites,"paths":paths}

static func _branches(rng: RandomNumberGenerator,radial: bool) -> Dictionary:
 var sites: Array[Vector2i] = []
 var paths: Array = []
 var endpoints: Array[Vector2i] = []
 var arm_length := 4 if radial else 3
 for i in range(arm_length):
  var axis: Vector2i = DIRECTIONS[i]
  var side := Vector2i(-axis.y,axis.x)
  var near := axis*rng.randi_range(1,2)
  sites.append(near)
  if not radial or i%2==0:
   var far := near+axis*rng.randi_range(1,2)+side*rng.randi_range(-1,1)
   sites.append(far)
   paths.append([Vector2i.ZERO,near,far])
   endpoints.append(far)
  else:
   paths.append([Vector2i.ZERO,near])
   endpoints.append(near)
 if radial:
  var first := rng.randi_range(0,3)
  paths.append([endpoints[first],endpoints[(first+1)%4]])
  if rng.randf()<0.60:
   paths.append([endpoints[(first+2)%4],endpoints[(first+3)%4]])
 elif rng.randf()<0.55:
  # An outer fork connection creates a bypass without turning all arms into a ring.
  var from := rng.randi_range(0,arm_length-2)
  paths.append([endpoints[from],endpoints[from+1]])
 return {"sites":sites,"paths":paths}

static func _scattered(rng: RandomNumberGenerator,labyrinth: bool) -> Dictionary:
 var sites: Array[Vector2i] = [Vector2i.ZERO]
 var width := rng.randi_range(4,5)
 var height := rng.randi_range(3,5)
 var candidates: Array[Vector2i] = []
 for y in range(-height/2,height-height/2):
  for x in range(-width/2,width-width/2):
   if x!=0 or y!=0:candidates.append(Vector2i(x,y))
 for i in range(5):
  var scores := {}
  for candidate in candidates:
   var nearest := INF
   for site in sites:
    nearest=minf(nearest,site.distance_to(candidate))
   scores[candidate]=absf(nearest-(1.25 if labyrinth else 2.75))+rng.randf()*1.40
  var chosen: Vector2i = candidates[0]
  for candidate in candidates:
   if scores[candidate]<scores[chosen]:chosen=candidate
  sites.append(chosen)
  candidates.erase(chosen)
 var paths := _tree(sites,rng)
 var connections := _node_pairs(sites,true)
 _shuffle(connections,rng)
 var loops := rng.randi_range(5,8) if labyrinth else rng.randi_range(1,2)
 for i in range(loops):
  paths.append(connections[i])
 return {"sites":sites,"paths":paths}

static func _spine(rng: RandomNumberGenerator,staircase: bool) -> Dictionary:
 var sites: Array[Vector2i] = []
 var paths: Array = []
 var spine: Array[Vector2i] = []
 var y := 0
 for x in range(6):
  if x>0:
   y+=rng.randi_range(0,1) if staircase else rng.randi_range(-1,1)
  if staircase and x in [2,4]:y+=1
  var junction := Vector2i(x,y)
  spine.append(junction)
  var side: int = 0 if staircase and rng.randf()<.55 else [-1,1][rng.randi_range(0,1)]
  var site := junction+Vector2i(0,side)
  sites.append(site)
  if site!=junction:paths.append([junction,site])
 paths.push_front(spine)
 if not staircase or rng.randf()<0.55:
  var i := rng.randi_range(1,2)
  paths.append([sites[i],sites[i+2]])
 return {"sites":sites,"paths":paths}

static func _wings(rng: RandomNumberGenerator,hybrid: bool) -> Dictionary:
 var a := Vector2i(-rng.randi_range(2,3),rng.randi_range(-1,0))
 var b := Vector2i(rng.randi_range(1,2),rng.randi_range(0,1))
 var west := a+Vector2i(-1,-rng.randi_range(0,1))
 var east := b+Vector2i(1,rng.randi_range(0,1))
 var high := a+Vector2i(rng.randi_range(0,1),-rng.randi_range(1,2))
 var low := b+Vector2i(-rng.randi_range(0,1),rng.randi_range(1,2))
 var sites: Array[Vector2i] = [a,west,high,b,east,low]
 var paths := [[west,a,high],[east,b,low],[a,Vector2i.ZERO,b]]
 if hybrid:
  # Mix a radial, curved-spine or small courtyard connector into the wings.
  match rng.randi_range(0,2):
   0:
    paths.append([high,Vector2i(0,-2),east])
    paths.append([west,Vector2i(0,2),low])
   1:
    paths.append([high,Vector2i(0,-1),Vector2i(0,1),low])
   _:
    paths.append([high,Vector2i(0,-2),Vector2i(1,-2),b])
    paths.append([a,Vector2i(-1,2),Vector2i(1,2),low])
 else:
  paths.append([high,Vector2i(0,high.y),Vector2i(b.x,high.y),b])
  paths.append([a,Vector2i(a.x,low.y),Vector2i(0,low.y),low])
 return {"sites":sites,"paths":paths}

static func _courtyards(rng: RandomNumberGenerator) -> Dictionary:
 var split := rng.randi_range(2,3)
 var east := split+rng.randi_range(2,3)
 var north := -rng.randi_range(1,2)
 var south := rng.randi_range(2,3)
 var sites: Array[Vector2i] = [
  Vector2i(0,0), Vector2i(1,north), Vector2i(split,0),
  Vector2i(east,north+rng.randi_range(0,1)), Vector2i(east,south), Vector2i(split,south)
 ]
 var a := Vector2i(0,south)
 var b := Vector2i(split,north)
 var paths := [[sites[0],sites[1],b,sites[2],sites[5],a,sites[0]],
  [b,sites[3],sites[4],sites[5],sites[2],b]]
 if rng.randf()<0.5:
  paths.append([Vector2i(1,north),Vector2i(1,south),Vector2i(split,south)])
 return {"sites":sites,"paths":paths}

static func _tree(sites: Array[Vector2i],rng: RandomNumberGenerator) -> Array:
 # Random weighted spanning tree conserves travel while changing junctions.
 var paths: Array = []
 var reached := {sites[0]:true}
 var options := _node_pairs(sites,false)
 var weights := {}
 for pair in options:
  weights[pair]=pair[0].distance_to(pair[1])+rng.randf()*1.85
 options.sort_custom(func(a,b):return weights[a]<weights[b])
 while reached.size()<sites.size():
  for pair in options:
   if reached.has(pair[0])==reached.has(pair[1]):continue
   reached[pair[0]]=true
   reached[pair[1]]=true
   paths.append(pair)
   break
 return paths

static func _node_pairs(sites: Array[Vector2i],close_only: bool) -> Array:
 var pairs: Array = []
 for i in range(1,sites.size()):
  for j in range(i):
   if not close_only or sites[i].distance_to(sites[j])<=4.0:
    pairs.append([sites[i],sites[j]])
 return pairs

static func _shuffle(values: Array,rng: RandomNumberGenerator):
 for i in range(values.size()-1,0,-1):
  var pick := rng.randi_range(0,i)
  var item = values[i]
  values[i]=values[pick]
  values[pick]=item

static func _oriented_vertex(point: Vector2i,turn: int,mirror: bool) -> Vector2i:
 if mirror:point.x=-point.x
 for i in range(turn):point=Vector2i(-point.y,point.x)
 return point

static func _oriented_site(point: Vector2i,turn: int,mirror: bool) -> Vector2i:
 # Transform the occupied lot, not just its top-left vertex.
 var a := _oriented_vertex(point,turn,mirror)
 var b := _oriented_vertex(point+Vector2i.ONE,turn,mirror)
 return a.min(b)

static func _edge(a: Vector2i,b: Vector2i) -> Vector4i:
 if a.x>b.x or a.y>b.y:
  return Vector4i(b.x,b.y,a.x,a.y)
 return Vector4i(a.x,a.y,b.x,b.y)

static func _add_street(streets: Dictionary,a: Vector2i,b: Vector2i):
 streets[_edge(a,b)]=[a,b]

static func _junction(streets: Dictionary,at: Vector2i) -> bool:
 for direction in DIRECTIONS:
  if streets.has(_edge(at,at+direction)):return true
 return false

static func _street_path(streets: Dictionary,a: Vector2i,b: Vector2i,horizontal_first: bool):
 var axes := [0,1] if horizontal_first else [1,0]
 for index in axes:
  while a[index]!=b[index]:
   var next:=a
   next[index]+=1 if b[index]>a[index] else -1
   _add_street(streets,a,next)
   a=next

static func _axis(rng: RandomNumberGenerator,minimum: int,maximum: int) -> Dictionary:
 var axis := {}
 var position := 0.0
 for index in range(minimum,maximum+1):
  axis[index]=position
  position+=float(rng.randi_range(35,43)*16)
 return axis

static func _world(point: Vector2i,x_axis: Dictionary,y_axis: Dictionary) -> Vector2:
 return Vector2(x_axis[point.x],y_axis[point.y])

static func _link(data: Dictionary,a: int,b: int,width: float):
 if a==b:return
 data.lane_links.append([a,b])
 data.lane_widths.append(width)
 data.corridors.append(NightmareMap._segment(data.nodes[a],data.nodes[b],width))

static func _extent(data: Dictionary) -> Rect2:
 var extent: Rect2 = data.rooms[0].bounds
 for room in data.rooms:extent=extent.merge(room.bounds)
 for corridor in data.corridors:extent=extent.merge(corridor)
 return extent

static func _rank_nodes(data: Dictionary,count: int,aim: Vector2) -> Array:
 var candidates := range(count)
 candidates.sort_custom(func(a,b):return aim.distance_squared_to(data.nodes[a])<aim.distance_squared_to(data.nodes[b]))
 return candidates

static func _hall_access(data: Dictionary,node_count: int) -> Array:
 var graph:=AStar2D.new()
 for i in range(data.nodes.size()):graph.add_point(i,data.nodes[i])
 for link in data.lane_links:graph.connect_points(link[0],link[1])
 var access: Array = []
 for source in range(node_count):
  var walks: Array[float] = []
  for room in data.rooms:
   var path:=graph.get_point_path(source,data.nodes.find(room.approach))
   var distance:=0.0
   for i in range(1,path.size()):distance+=path[i-1].distance_to(path[i])
   walks.append(distance)
  access.append(walks)
 return access

static func _add_hall(data: Dictionary,id: String,normal: Vector2,extent: Rect2,access: Array,coverage: Array[float],rng: RandomNumberGenerator):
 var tangent := normal.orthogonal()
 var middle := extent.get_center()
 var half_span := (normal.abs()*extent.size).length()*.5
 var far_coordinate := middle.dot(normal)+half_span
 var target := middle.dot(tangent)+(rng.randf()-.5)*140.0
 var size := Vector2(208,176) if normal.y!=0 else Vector2(176,208)
 var width := float(rng.randi_range(9,13)*8)
 var lane_nodes: Array = data.nodes.slice(0,access.size())
 var depth_jitter := float(rng.randi_range(11,19)*8)
 var best_score := INF
 var best_source := -1
 var best_walk := 0.0
 for i in range(lane_nodes.size()):
  var from: Vector2 = lane_nodes[i]
  # Continue past the outermost street on this line. Internal recesses
  # are allowed, but the shaft should never overlap an existing lane.
  if lane_nodes.any(func(other: Vector2):
   return other.dot(tangent)==from.dot(tangent) and other.dot(normal)>from.dot(normal)):
   continue
  var beyond := far_coordinate-from.dot(normal)
  var depths := [168.0,248.0,328.0,440.0,beyond+depth_jitter+88.0]
  for walk: float in depths:
   var center := from+normal*walk
   if (center-middle).dot(normal)<half_span*.55:
    continue
   var rectangle := Rect2(center-size*.5,size)
   if not _hall_site_clear(data,from,rectangle,width):
    continue
   var score:=.20*absf(center.dot(normal)-far_coordinate)+.24*absf(center.dot(tangent)-target)+walk*.22
   for r in range(coverage.size()):
    # Prioritize more rooms within a plausible retreat distance. Preserve
    # the normal state machine's distance, time and healing limits.
    var travel: float = access[i][r]+walk
    var improvement: float = coverage[r]-travel
    if improvement>0.0:
     score-=improvement*.48
     if travel<880.0 and coverage[r]>=880.0:score-=220.0
   if score<best_score:
    best_score=score
    best_source=i
    best_walk=walk
 # A shaft outside the extreme street extends through empty space, and
 # at least one side row or column meets that condition in every layout.
 assert(best_source>=0)
 var from: Vector2 = lane_nodes[best_source]
 var center := from+normal*best_walk
 var entrance := center-normal*88.0
 var rectangle := Rect2(center-size*.5,size)
 var approach_node := NightmareMap._node(data,entrance)
 _link(data,best_source,approach_node,width)
 _link(data,approach_node,NightmareMap._node(data,center),width)
 data.corridors.append(rectangle)
 data.halls[id]={"id":id,"name":id.capitalize()+" Haunted Hall","bounds":rectangle,"entrance":entrance,"center":center}
 for r in range(coverage.size()):coverage[r]=minf(coverage[r],access[best_source][r]+best_walk)

static func _hall_site_clear(data: Dictionary,from: Vector2,hall: Rect2,width: float) -> bool:
 var shaft := NightmareMap._segment(from,hall.get_center(),width)
 for room in data.rooms:
  if room.bounds.intersects(shaft) or room.bounds.intersects(hall):
   return false
 for corridor: Rect2 in data.corridors:
  if corridor.intersects(hall):
   return false
 return true
