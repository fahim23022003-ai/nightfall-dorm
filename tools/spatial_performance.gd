extends "res://tools/capture_spatial_construction.gd"
func sample(label,frames=240):
 var timings=[];var nodes_before=Performance.get_monitor(Performance.OBJECT_NODE_COUNT);var r=game.model.player();var state=r.buildings.duplicate(true);var wallet=[r.gold,r.electricity]
 for i in range(30):await advance(.001)
 for i in range(frames):
  var start=Time.get_ticks_usec()
  if game.construction.active():
   var at=game.world_to_screen(r.bounds().get_center()+Vector2(sin(i*.07)*95,cos(i*.09)*70));Input.warp_mouse(at)
  game.construction.update(.016);game.presentation.update(.016,game.model);game.ui.update_match();game.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  timings.append((Time.get_ticks_usec()-start)/1000.0)
 timings.sort();var sum=0.0
 for t in timings:sum+=t
 check(r.buildings==state and [r.gold,r.electricity]==wallet,"drag/render does not change combat/economy state")
 var result={"label":label,"frames":frames,"mean_ms":sum/frames,"p95_ms":timings[int(frames*.95)],"nodes_before":nodes_before,"nodes_after":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"active_projectiles":game.model.projectiles.size()}
 print("SPATIAL_PERF ",result);return result
func run():
 output="/workspace/freedom-to-build/";phase="after";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();var m=fresh();var r=m.player()
 for i in range(7):check(m.expansion.purchase(m),"actual full-capacity fixture")
 for kind in Catalog.BUILDINGS:check(m.place_building(kind,candidate(r)),"all fifteen registered bodies")
 check(m.place_building("turret",candidate(r)),"sixteenth actual body");game.focus_camera(true);await advance(1)
 var rows=[];rows.append(await sample("full16 planning off"))
 game.construction.planning=true;rows.append(await sample("full16 planning footprints"));game.construction.planning=false
 game.selected_tile=16;check(game.construction.begin_move(),"full-room drag reservation");rows.append(await sample("full16 live mouse drag validation"));game.construction.cancel()
 var f=FileAccess.open(output+"after/performance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":"Linux Mesa llvmpipe software GL, shared environment","measurement":"render-wait/frame wall time, 30 warmup +240 frames per state; no Windows/FPS/hours-long claim; overlay off vs on measures incremental spatial workload, not a paired old executable benchmark","rows":rows,"checks":checks,"failures":failures}," "))
 print("SPATIAL_PERFORMANCE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
