extends SceneTree
# Render-envelope safety; actual culled raster output is independently inspected by D.
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL CULL: "+label)
func run():
 root.size=Vector2i(1280,720)
 var holder=Node2D.new();root.add_child(holder)
 var camera=Camera2D.new();holder.add_child(camera);camera.make_current()
 var p=load("res://scripts/dorm_presentation.gd").new()
 var skipped=0
 for stage in StageCatalog.STAGES:
  var m=MatchModel.new();m.configure_stage(stage.id)
  var world_a=load("res://scripts/haunted_environment.gd").new()
  var world_b=load("res://scripts/haunted_environment.gd").new()
  world_a.configure(m);world_b.configure(m)
  var model_rng=m.random.state
  for center in [m.rooms[0].bounds().get_center(),m.rooms[5].bounds().get_center(),m.map_bounds().get_center()]:
   for zoom in [.35,1.0,1.5]:
    camera.position=center+Vector2(145,40);camera.zoom=Vector2.ONE*zoom;camera.force_update_scroll();await process_frame
    var visible=p.visible_world_rect(holder)
    var exterior=p.visible_world_rect(holder,90)
    var transform=holder.get_canvas_transform()
    var inverse=transform.affine_inverse();var screen=holder.get_viewport_rect()
    for point in [screen.position,Vector2(screen.end.x,screen.position.y),screen.end,Vector2(screen.position.x,screen.end.y)]:
     check(visible.has_point(inverse*point) and exterior.has_point(inverse*point),"actual viewport corners retained with safety margin")
    var regions=[]
    for room in m.rooms:regions.append(Rect2(room.bounds().position+Vector2(145,40),room.bounds().size))
    for rect in m.map_data.corridors:regions.append(Rect2(rect.position+Vector2(145,40),rect.size))
    for rect in regions:
     var projected=Rect2(transform*rect.position,transform*rect.end-transform*rect.position).abs()
     if projected.intersects(screen):
      check(visible.intersects(rect),"visible room/corridor cannot be culled")
     elif not visible.intersects(rect):skipped+=1
    for creature in world_a.creatures:
     var point=creature.position+Vector2(145,40)
     if screen.has_point(transform*point):check(exterior.has_point(point),"on-screen cosmetic actor survives exterior culling")
    # One simulation is queried at each focused viewport; another has no view query.
    # View changes must never become simulation/cosmetic spawning input.
    world_a.update(.5,m);world_b.update(.5,m)
    check(world_a.creatures==world_b.creatures and world_a.rng.state==world_b.rng.state and world_a.clock==world_b.clock,"offscreen cosmetic state advances independently of culling")
  check(world_a.clock>0 and m.random.state==model_rng,"render queries cannot pause cosmetics or consume gameplay RNG")
 check(skipped>0,"optimization actually excludes fully offscreen geometry")
 holder.queue_free();await process_frame
 print("VISUAL_CULL_CHECKS=",checks," OFFSCREEN_REGIONS=",skipped," FAILURES=",failures)
 quit(0 if failures==0 else 1)
