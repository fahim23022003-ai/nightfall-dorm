extends "res://tests/survivor_lobby_integration.gd"
## Native controls and actual Story model in an isolated test profile.

var viewport_size:=Vector2i(960,540)
var presets: Dictionary={}
var quality: String

func image(label: String,expected: Vector2i):
 if not destination.is_empty():await super.image(label,expected)

func key(code: Key) -> void:
 for down: bool in [true,false]:
  var event:=InputEventKey.new()
  event.keycode=code
  event.physical_keycode=code
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func still(name: String) -> void:
 await image(name,viewport_size)

func collect_frames(name: String, count: int=45) -> void:
 var frames: Array[float]=[]
 var process: Array[float]=[]
 var draws: Array[int]=[]
 for i in range(count+5):
  var started:=Time.get_ticks_usec()
  game._process(1.0/60.0)
  var cpu:=Time.get_ticks_usec()-started
  await RenderingServer.frame_post_draw
  if i>=5:
   frames.append((Time.get_ticks_usec()-started)/1000.0)
   process.append(cpu/1000.0)
   draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
 frames.sort()
 process.sort()
 draws.sort()
 presets[name]={"median_ms":frames[count/2],"p95_ms":frames[ceili(count*.95)-1],"p99_ms":frames[ceili(count*.99)-1],
  "game_process_median_ms":process[count/2],"draw_calls":draws[count/2]}

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()<2 or not args[0].is_absolute_path() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 destination=args[0]
 quality=args[1]
 var bench: bool="bench" in args
 if quality!="low":viewport_size=Vector2i(1280,720)
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=viewport_size
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://tactical-preview-%d.json" % Time.get_ticks_usec())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game.profile.complete_tutorial()
 game.change_setting("graphics_quality",quality)
 game.change_setting("adaptive_performance",false)
 game.profile.inventory.radar=1
 game.profile.equip_item("radar")
 game.ui.show_menu()
 var tactical: bool=game.ui.has_method("use_tactical_ui") and game.ui.use_tactical_ui()
 await still("01-main-menu")
 if bench:await collect_frames("main_menu")
 await press("menu_settings",game.ui.panel)
 await still("02-graphics")
 if tactical:
  for index in range(1,6):
   await press("settings_page_"+str(index),game.ui.panel)
   await still("02-settings-%d" % index)
   if index==1:
    var slider: HSlider=game.ui.panel.find_child("music_volume",true,false)
    slider.grab_focus()
    await key(KEY_RIGHT)
    check(is_equal_approx(game.profile.settings.music,slider.value),"keyboard volume persists through real slider")
  await key(KEY_ESCAPE)
  check(game.ui.current_screen=="menu","settings Escape returns one level")
 else:
  await press("settings_back",game.ui.panel)
 await press("menu_inventory",game.ui.panel)
 await still("03-inventory")
 if tactical:await key(KEY_ESCAPE)
 else:await press("inventory_back",game.ui.panel)
 await press("menu_shop",game.ui.panel)
 await still("04-shop")
 await press("shop_back",game.ui.panel)
 await press("menu_ranks",game.ui.panel)
 await still("05-rank")
 game.return_menu()
 await click(game.ui.menu_start)
 await still("06-story-prepare")
 if bench:await collect_frames("story_prepare")
 var lobby=await open_prepared_lobby()
 if not is_instance_valid(lobby):
  finish()
  return
 advance(lobby,4.0)
 await still("07-lobby")
 if bench:await collect_frames("story_lobby")
 await press("LobbyReady",lobby)
 advance(lobby,7.0)
 advance(lobby,.5)
 await process_frame
 await process_frame
 var folder:=destination
 destination=""
 await walk_probe()
 destination=folder
 var model: MatchModel=game.model
 var room:=model.player()
 check(room!=null and room.sleeping,"own actual occupied Story room")
 if not is_instance_valid(game) or room==null:
  finish()
  return
 game._process(.05)
 await still("08-hud-calm")
 if bench:await collect_frames("hud_calm")
 await key(KEY_B)
 await create_timer(.24).timeout
 await still("09-build")
 if bench:await collect_frames("build")
 await click(game.ui.actions["build:turret"])
 await create_timer(.24).timeout
 var construction=game.construction
 var target:=needle_cell(room)
 check(target.is_finite(),"legal camera-visible Needle cell")
 if target.is_finite():
  await pointer(target)
  game.ui.update_match()
  await still("10-placement-valid")
  if bench:await collect_frames("placement")
  var cash: float=room.gold
  await pointer(room.door_position())
  game.ui.update_match()
  await still("11-placement-blocked")
  check(construction.reason()!="" and room.gold==cash,"blocked path does not debit Gold")
  await pointer(target)
  await mouse(INPUT_CLICK,target)
  check(room.buildings.size()==1,"world click bought exactly one Needle")
  if construction.active() or game.ui.context_open:await key(KEY_ESCAPE)
  await mouse(INPUT_CLICK,target)
  await create_timer(.24).timeout
  check(game.ui.context_mode=="upgrade" and game.ui.context_open,"physical machine opens inspector")
  await still("12-machine-inspector")
 await key(KEY_I)
 check(game.ui.items_ui.expanded,"I opened items")
 if tactical:check(not game.ui.context_open,"Items replaces machine inspector")
 await key(KEY_1)
 await still("13-items")
 if bench:await collect_frames("items")
 await key(KEY_ESCAPE)
 check(not game.ui.items_ui.expanded or not tactical,"Escape closes Items before pause")
 if tactical:
  await press("tactical_more",game.ui.panel)
  await still("14-more")
  await press("utility_settings",game.ui.panel)
  var paused_at: float=model.time
  game._process(.2)
  check(game.ui.tactical_settings!=null and model.time==paused_at,"match Settings pauses model")
  await key(KEY_ESCAPE)
  check(game.ui.tactical_settings==null and model.running,"active match settings resumes same match")
  await key(KEY_ESCAPE)
  check(not model.running and not game.ui.pause_items.is_empty(),"Escape reaches the pause menu from an idle HUD")
  await still("14-pause")
  await click(game.ui.pause_items[3])
  check(model.running and game.ui.pause_items.is_empty(),"actual Resume unlocks the game")
 await key(KEY_G)
 var frozen: float=model.time
 game._process(.4)
 check(game.phase20_help_open and model.time==frozen,"help waits for Resume without simulating")
 await still("15-help")
 if bench:await collect_frames("help")
 await key(KEY_ESCAPE)
 check(model.running and not game.phase20_help_open,"Escape resumes real match")
 await key(KEY_M)
 await still("16-danger-map")
 await key(KEY_M)
 model.time=model.preparation+10
 model.haunt_recovery.available_at=INF
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.position=room.door_approach()
 model.hunter.target=room.index
 model.hunter.cooldown=2
 game._process(.05)
 await still("17-hunter-attacking")
 if bench:await collect_frames("active_combat")
 room.door_hp=room.max_hp()*.27
 game._process(.05)
 await still("18-critical-door")
 finish()

const INPUT_CLICK:=true
func needle_cell(room: RoomState) -> Vector2:
 var bounds:=room.spatial.grid_bounds()
 var target:=Vector2.INF
 var best:=INF
 for y in range(int(bounds.size.y/SpatialConstruction.CELL_SIZE)):
  for x in range(int(bounds.size.x/SpatialConstruction.CELL_SIZE)):
   var world:=bounds.position+Vector2(x,y)*SpatialConstruction.CELL_SIZE
   var point:=room.spatial.aligned(world,"turret",0)
   var screen: Vector2=game.world_to_screen(point)
   if not Rect2(295,185,565,410).has_point(screen):continue
   var distance:=point.distance_squared_to(room.door_approach())
   if distance<best and room.spatial.purchase_reason("turret",point,0)=="":
    target=point
    best=distance
 return target

func pointer(target: Vector2) -> void:
 var point: Vector2=root.get_final_transform()*game.world_to_screen(target)
 var event:=InputEventMouseMotion.new()
 event.position=point
 event.global_position=point
 Input.parse_input_event(event)
 await process_frame

func mouse(pressed: bool,target: Vector2) -> void:
 var point: Vector2=root.get_final_transform()*game.world_to_screen(target)
 for state: bool in [pressed,false]:
  var event:=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=state
  Input.parse_input_event(event)
  await process_frame

func finish():
 FileAccess.open(destination.path_join("receipt.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":presets},"  ")+"\n")
 game.audio_system.shutdown()
 await create_timer(.12).timeout
 game.queue_free()
 await process_frame
 print("TACTICAL_UI_INPUT_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
