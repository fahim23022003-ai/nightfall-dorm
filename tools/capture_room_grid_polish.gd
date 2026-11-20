extends "res://tools/capture_room_grid.gd"
## Repeat the same grid interactions on a checkpoint and the polish build.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --.")
  quit(2)
  return
 if OS.get_environment("NIGHTFALL_FULL_ROOM_GRID")!="1" or OS.get_environment("NIGHTFALL_VISUAL_REBIRTH")!="1":
  push_error("Enable the room grid and visual preview for the capture.")
  quit(2)
  return
 capture_directory=args[0].trim_suffix("/")
 output=capture_directory.get_base_dir()+"/"
 phase=capture_directory.get_file()
 DirAccess.make_dir_recursive_absolute(capture_directory.path_join("frames"))
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 var model=_fresh_room(ROOM_ID)
 var room=model.player()
 check(room!=null and room.spatial!=null and room.spatial.grid,"normal claim and sleep activate the Endless grid")
 if failures>0:
  await _finish()
  return

 var stills := OS.get_environment("NIGHTFALL_GRID_POLISH_STILLS")=="1"
 grid_recording=not stills
 await advance(.20)
 await _preview_unturned(room)
 await _capture_input_journey(model,room)
 if failures>0:
  _write_polish_receipt(room)
  await _finish()
  return

 grid_recording=false
 _populate_dense(model,room)
 check(room.buildings.size()==TARGET_COUNT,"paid dense layout contains exactly 24 structures")
 check(not dense_receipt.is_empty(),"capture records exact purchased geometry")
 game.ui.close_context()
 game.selected_tile=-1
 grid_recording=not stills
 grid_observations["dense_segment_first_frame"]=frame_number
 await key(KEY_P)
 await advance(.43)
 check(game.construction.planning,"native P opens the dense room grid")
 await _mark("07-dense-grid-720",{"building_count":room.buildings.size()})
 await key(KEY_P)
 await advance(.28)
 await _capture_adjacent_selection(room)
 if OS.get_environment("NIGHTFALL_GRID_POLISH_FINAL")=="1":
  await _capture_machine_picker(room)
 game.ui.close_context()
 game.selected_tile=-1
 await advance(.28)
 await _capture_combat_hud(model,room)

 grid_recording=false
 _write_polish_receipt(room)
 await _finish()

func _preview_unturned(room) -> void:
 var center:=_pick_center(room,BUILD_KIND,0,room.bounds().get_center())
 check(center.is_finite(),"located valid unturned Dynamo center")
 if not center.is_finite():return
 var wallet:=Vector2(room.gold,room.electricity)
 await _start_build(BUILD_KIND)
 await point_mouse(center)
 var footprint: Rect2 = room.spatial.footprint_for(center,BUILD_KIND,0)
 check(game.construction.reason()=="","unturned native cursor reports valid floor")
 await _mark("00-unturned-valid-preview-720",{"footprint":[footprint.size.x,footprint.size.y],"center":[center.x,center.y]})
 await advance(.3)
 if OS.get_environment("NIGHTFALL_GRID_POLISH_FINAL")=="1":
  await _check_toolbar_and_reverse_rotation(room)
 await key(KEY_ESCAPE)
 await advance(.2)
 check(room.buildings.is_empty() and Vector2(room.gold,room.electricity).is_equal_approx(wallet),"preview and cancel spend nothing")

func _check_toolbar_and_reverse_rotation(room) -> void:
 var control: Button=game.construction.get("rotate_button")
 check(is_instance_valid(control) and control.is_visible_in_tree(),"grid rotation button receives native input")
 if not is_instance_valid(control):return
 var cursor: Vector2=game.construction.get("cursor_world")
 var center: Vector2=game.construction.point
 var toolbar_point := root.get_final_transform()*control.get_global_rect().get_center()
 Input.warp_mouse(toolbar_point)
 await advance(.16)
 await click(control)
 await advance(.23)
 var snapped: Vector2=room.spatial.aligned(cursor,BUILD_KIND,1)
 var stored_cursor: Vector2=game.construction.get("cursor_world")
 check(game.construction.rotation==1 and game.construction.point.is_equal_approx(snapped) and stored_cursor.is_equal_approx(cursor),"toolbar rotation keeps the last floor cursor after re-snapping")
 await _mark("00a-toolbar-rotation-720",{"rotation":game.construction.rotation,"center":[game.construction.point.x,game.construction.point.y],"floor_pointer":[stored_cursor.x,stored_cursor.y]})
 for down in [true,false]:
  var event:=InputEventKey.new()
  event.keycode=KEY_Q
  event.physical_keycode=KEY_Q
  event.shift_pressed=true
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame
 await advance(.24)
 check(game.construction.rotation==0 and game.construction.point.is_equal_approx(center),"Shift+Q turns back without jumping to toolbar")

func _capture_adjacent_selection(room) -> void:
 var best := INF
 var first := -1
 var second := -1
 for left in room.buildings:
  for right in room.buildings:
   if left>=right or room.buildings[left].kind==room.buildings[right].kind:continue
   var a: Vector2=room.tile_position(left)
   var b: Vector2=room.tile_position(right)
   if room.spatial.hit_test(a)!=left or room.spatial.hit_test(b)!=right:continue
   var distance:=a.distance_squared_to(b)
   if distance<best:
    best=distance
    first=left
    second=right
 check(first>=0 and second>=0 and sqrt(best)<56.0,"fixture has two nearby selectable machines")
 if first<0 or second<0:return
 var wallet:=Vector2(room.gold,room.electricity)
 for item in [[first,"08a-crowded-selection-720"],[second,"08b-neighbor-selection-720"]]:
  var id: int=item[0]
  var point: Vector2=room.tile_position(id)
  await point_mouse(point)
  await world_click(point)
  await advance(.47)
  check(game.selected_tile==id and game.ui.context_mode=="upgrade","native click opens the correct nearby machine")
  await _mark(item[1],{"id":id,"kind":room.buildings[id].kind,"center":[point.x,point.y],"separation":sqrt(best)})
 check(Vector2(room.gold,room.electricity).is_equal_approx(wallet),"hover and nearby selections spend nothing")

func _capture_machine_picker(room) -> void:
 var toggle: Button=game.construction.get("machine_button")
 var list: ItemList=game.construction.get("machine_list")
 check(is_instance_valid(toggle) and is_instance_valid(list),"crowded room machine picker exists")
 if not is_instance_valid(toggle) or not is_instance_valid(list):return
 var wallet:=Vector2(room.gold,room.electricity)
 await click(toggle)
 await advance(.34)
 check(list.is_visible_in_tree() and list.item_count==room.buildings.size(),"actual Machines button lists every owned structure")
 if not list.is_visible_in_tree() or list.item_count==0:return
 await _mark("08c-machines-list-720",{"rows":list.item_count})
 var row:=-1
 var found:=Vector2.INF
 var width:=floori(list.size.x)
 var height:=floori(list.size.y)
 for y in range(floori(height/3.0),floori(height*2/3.0),3):
  var local:=Vector2(width*.5,y)
  var item:=list.get_item_at_position(local,true)
  if item>=0 and list.get_item_metadata(item)[0]!=game.selected_tile:
   row=item
   found=local
   break
 check(found.is_finite(),"picker row is physically visible and clickable")
 if not found.is_finite():return
 var metadata: Array=list.get_item_metadata(row)
 var expected: int=metadata[0]
 check(room.buildings.has(expected) and room.buildings[expected].instance_id==metadata[1],"picker row binds a stable building and instance ID")
 var screen: Vector2=root.get_final_transform()*(list.get_global_transform_with_canvas()*found)
 await _click_screen(screen)
 await advance(.42)
 check(game.selected_tile==expected and game.ui.context_open,"native ItemList click inspects the exact stable ID")
 await _mark("08d-picker-selected-720",{"id":game.selected_tile,"row":row})
 game.ui.close_context()
 await advance(.16)
 check(not game.ui.context_open and game.selected_tile==expected,"closed inspector retains the selected machine")
 await _click_screen(screen)
 await advance(.25)
 check(game.selected_tile==expected and game.ui.context_open,"clicking the same row reopens the inspector")
 check(Vector2(room.gold,room.electricity).is_equal_approx(wallet),"picker interaction spends nothing")
 if list.is_visible_in_tree():
  await click(toggle)
  await advance(.24)

func _click_screen(screen: Vector2) -> void:
 Input.warp_mouse(screen)
 for down in [true,false]:
  var event:=InputEventMouseButton.new()
  event.position=screen
  event.global_position=screen
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func _capture_combat_hud(model,room) -> void:
 _prepare_live_combat(model,room)
 var before_shots: int=model.shots
 var before_attacks: int=model.hunter.attacks
 var preview=game.presentation.nightmare_visual.stalker_preview
 var seen := {}
 var dealt := 0.0
 for frame in range(92):
  game._process(STEP)
  await _draw_recorded_frame()
  for event in model.presentation_events:
   if event.type!="door_damage" or event.room!=room.index or seen.has(event.id):continue
   seen[event.id]=true
   dealt+=float(event.damage)
  if model.shots>before_shots and dealt>0.0 and frame>=36:
   await _mark("09-door-hp-and-room-trait-720",{"door_hp":room.door_hp,"door_max":room.max_hp(),"shots":model.shots-before_shots})
   break
 check(model.shots>before_shots and model.hunter.attacks>before_attacks and dealt>0.0,"actual dense combat exercises both sides")
 check(preview.texture!=null and preview.active_level==10,"live capture binds the existing L10 authored Stalker")
 var door: Button=game.ui.room_door_summary
 var door_value: String="%.0f/%.0f" % [room.door_hp,room.max_hp()]
 check(door.is_visible_in_tree() and door_value in door.text,"bottom HUD displays actual live door health")
 var trait_text: String=""
 if OS.get_environment("NIGHTFALL_GRID_POLISH_FINAL")=="1":
  var trait_label: Label=game.construction.get("room_info")
  var trait_data: Dictionary=StrategyCatalog.TRAITS[room.trait_id]
  check(is_instance_valid(trait_label) and trait_label.is_visible_in_tree(),"room trait is visible during combat")
  if is_instance_valid(trait_label):
   trait_text=trait_label.text
   check(trait_data.name in trait_text and trait_data.benefit in trait_text and trait_data.drawback in trait_text,"room HUD displays the actual trait and both gameplay effects")
 grid_observations["combat"]={
  "shots":model.shots-before_shots,"attacks":model.hunter.attacks-before_attacks,
  "total_door_damage":dealt,"door_hp":room.door_hp,"door_max":room.max_hp(),
  "texture":preview.texture.resource_path if preview.texture!=null else "",
 }
 grid_observations["combat_hud"]={"door":door.text,"trait":trait_text}

func _write_polish_receipt(room) -> void:
 var report:=FileAccess.open(capture_directory.path_join("polish-capture.json"),FileAccess.WRITE)
 if report!=null:
  report.store_string(JSON.stringify({
   "viewport":[1280,720],"fps":24,"frame_count":frame_number,"checks":checks,"failures":failures,
   "fixture":"Prepared seeded legacy-balance Endless room. Scripted native input handles preview, placement, rejected clicks, rotate, move, undo and selection. Paid dense layout and room levels staged between chapters; final combat advances normal match ticks.",
   "observations":grid_observations,"dense_buildings":dense_receipt,
   "ending_wallet":[room.gold,room.electricity],
  },"  ")+"\n")
 print("GRID_POLISH_FRAMES=",frame_number," DENSE_BUILDINGS=",dense_receipt.size())
