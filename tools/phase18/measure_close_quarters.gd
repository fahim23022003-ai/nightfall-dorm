extends "res://tools/phase16/measure_dense_active.gd"
## Same full-room combat fixture on the V2 reference and opt-in V3 geometry.

const NAV_REPEAT := 5

func _navigation_sample(model: MatchModel, room: RoomState) -> Dictionary:
 var landmarks: Array[Vector2] = [model.map_data.spawn,model.map_data.hunter_spawn]
 for id in HauntedRecovery.HALL_IDS:
  landmarks.append(model.map_data.halls[id].entrance)
 var samples := []
 var lengths := []
 for repeat in range(NAV_REPEAT):
  for endpoint in landmarks:
   var start := Time.get_ticks_usec()
   var route := model.navigation_path(endpoint,room.door_approach())
   samples.append((Time.get_ticks_usec()-start)/1000.0)
   check(not route.is_empty() and Vector2(route.back()).is_equal_approx(room.door_approach()),"measured navigation reaches actual door")
   lengths.append(_distance(endpoint,route))
 return {
  "route_query_ms":_timing(samples),"query_count":samples.size(),"route_world_distance":_timing(lengths),
  "node_count":model.map_data.nodes.size(),"corridor_count":model.map_data.corridors.size(),
 }

func _distance(origin: Vector2, route: Array) -> float:
 var distance := 0.0
 for point: Vector2 in route:
  distance += origin.distance_to(point)
  origin = point
 return distance

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=3 or not args[0].is_absolute_path() or args[1] not in ["medium","low"] or args[2] not in ["24","40","60"]:
  push_error("Pass absolute output, medium or low, and 24/40/60 density after --.")
  quit(2)
  return
 var destination := args[0]
 var density := int(args[2])
 var quality := args[1]
 var close := OS.get_environment("NIGHTFALL_CLOSE_QUARTERS")=="1"
 phase=destination.get_file()
 output=destination.get_base_dir()+"/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=STANDARD_VIEW_SIZE
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",quality)
 var model := MatchModel.new()
 model.reset(MATCH_SEED)
 check(model.configure_match("hell") and model.configure_stage(DENSE_STAGE) and model.configure_balance(),"configure same prepared Campaign")
 check(model.configure_strategy(MATCH_SEED,"stalker"),"same Stalker")
 check(model.map_data.get("version")== (3 if close else 2),"requested physical geometry version")
 game._adopt_session(model)
 game.set_process(false)
 var room := _dense_room(model,density)
 if room==null:
  await _finish()
  return
 check(room.buildings.size()==density,"exact legal building count")
 var route_sample := _navigation_sample(model,room)
 _prepare_encounter(model,room,false)
 await _render_frame()
 var initial := _gameplay_digest(model)
 var visual_initial := _image_hash(root.get_texture().get_image())
 var initial_visible := _visible_building_centers(room)
 var close_sample := await _measure_native(model)
 var final := root.get_texture().get_image()
 var final_visible := _visible_building_centers(room)
 check(initial_visible==density and final_visible==density,"each building center visible in camera at both measurements")
 check(final.get_size()==STANDARD_VIEW_SIZE,"actual native 720p viewport")
 check(model.result.is_empty() and close_sample.shots>0 and close_sample.strikes>0 and close_sample.hunter_hp_delta<0,"live authoritative attacks, launches and damage")
 check(not game.presentation.nightmare_visual.articulated.last_asset.is_empty(),"Hunter articulation remains active")
 check(final.save_png(destination.path_join("active-720.png"))==OK,"native dense viewport")
 var receipt := FileAccess.open(destination.path_join("measure.json"),FileAccess.WRITE)
 check(receipt!=null,"save raw metrics")
 if receipt!=null:
  receipt.store_string(JSON.stringify({
   "version":model.map_data.get("version"),"theme":model.map_id,"family":model.map_data.family,
   "seed":MATCH_SEED,"quality":quality,"buildings":room.buildings.size(),"room":room.index,
   "visible_buildings_at_start":initial_visible,"visible_buildings_at_end":final_visible,
   "renderer":RenderingServer.get_video_adapter_name(),"viewport":[1280,720],
   "geometry_sha256":JSON.stringify(NightmareMap.pack(model.map_data),"",true,true).sha256_text(),
   "gameplay_initial_sha256":initial,"visual_initial_sha256":visual_initial,"visual_final_sha256":_image_hash(final),
   "combat":close_sample,"navigation":route_sample,"checks":checks,"failures":failures,
  },"  ",true,true)+"\n")
  receipt.close()
 await _finish()
