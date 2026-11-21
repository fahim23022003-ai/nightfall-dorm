extends "res://tools/capture_survivor_defeat.gd"
## Render the real Story HUD, continuous repair, pause and free camera.

const VIEWPORT := Vector2i(960,540)

func image(label: String,expected: Vector2i):
 if not destination.is_empty():
  await super.image(label,expected)

func send_key(code: Key) -> void:
 for down: bool in [true,false]:
  var event:=InputEventKey.new()
  event.keycode=code
  event.physical_keycode=code
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 destination=args[0]
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=VIEWPORT
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase20-door-capture-%d.json" % OS.get_process_id())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 check(game.profile.complete_tutorial(),"isolated Story profile")
 game.change_setting("graphics_quality","low")
 game.enter_game()
 if not await start_from_ready():
  await finish_capture()
  return
 var folder:=destination
 destination=""
 await walk_probe()
 destination=folder
 var model: MatchModel=game.model
 var room:=model.player()
 if room==null or not room.sleeping:
  check(false,"claim and sleep use the actual Story room")
  await finish_capture()
  return
 room.bed_level=4
 room.door_level=4
 room.gold=220.0
 room.door_hp=room.max_hp()
 model.time=model.preparation+10.0
 model.haunt_recovery.available_at=INF
 model.hunter.position=room.door_approach()
 model.hunter.target=room.index
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.cooldown=3.0
 model.apply_room_damage(room.index,room.door_hp*.47)
 game._process(.05)
 check(room.fear_bed_multiplier==1.5,"real siege enables Bed Gold bonus")
 var gold: float=room.gold
 var hp: float=room.door_hp
 await click(game.ui.quick_repair)
 check(is_equal_approx(gold-room.gold,model.door_survival.price(room)),"HUD charges the exact price once")
 for frame in range(16):game._process(.05)
 check(room.door_hp>hp and model.door_survival.remaining>0.0,"HUD action restores real HP over time")
 await image("01-door-armor-fear-and-repair",VIEWPORT)
 await send_key(KEY_G)
 var frozen: Array=[model.time,room.gold,room.door_hp,model.door_survival.remaining]
 game._process(.5)
 check(game.phase20_help_open and frozen==[model.time,room.gold,room.door_hp,model.door_survival.remaining],"G pauses clocks, currency and HP")
 await image("02-pausing-help",VIEWPORT)
 game.phase20_help.select(4)
 await image("03-hunter-damage-guide",VIEWPORT)
 await send_key(KEY_ESCAPE)
 check(model.running and not game.phase20_help_open,"Esc resumes the match")
 await send_key(KEY_I)
 check(game.ui.items_ui.expanded,"real I action opens the item drawer")
 await image("04-items",VIEWPORT)
 await send_key(KEY_I)
 var start: Vector2=model.player_position
 var drag:=InputEventMouseMotion.new()
 drag.position=Vector2(500,350)
 drag.relative=Vector2(-182,-76)
 drag.button_mask=MOUSE_BUTTON_MASK_MIDDLE
 Input.parse_input_event(drag)
 await process_frame
 check(game.phase20_free_camera and model.player_position==start,"middle-drag leaves the survivor in place")
 await image("05-free-camera",VIEWPORT)
 await send_key(KEY_HOME)
 check(not game.phase20_free_camera,"Home locks the camera")
 await send_key(KEY_M)
 var heatmap: bool=game.phase20_heatmap
 await send_key(KEY_H)
 check(game.full_map and game.phase20_heatmap!=heatmap,"H toggles danger shading on the strategic map")
 if not game.phase20_heatmap:await send_key(KEY_H)
 await image("06-danger-map",VIEWPORT)
 await send_key(KEY_M)
 await capture_victory(model,room)
 await finish_capture()

func capture_victory(model: MatchModel,room: RoomState) -> void:
 var bounds: Rect2=room.spatial.grid_bounds()
 var placed:=false
 for x in range(ceili(bounds.size.x/SpatialConstruction.CELL_SIZE)):
  for y in range(ceili(bounds.size.y/SpatialConstruction.CELL_SIZE)):
   var point: Vector2=room.spatial.aligned(bounds.position+Vector2(x,y)*SpatialConstruction.CELL_SIZE,"turret",0)
   if point.distance_to(room.door_approach())<Catalog.BUILDINGS.turret.range and room.spatial.purchase_reason("turret",point,0)=="":
    placed=model.place_building("turret",point,0)
    if placed:break
  if placed:break
 check(placed,"place and pay for a real finishing Needle")
 if not placed:return
 model.hunter.hp=1.0
 model.hunter.boss_policy.enabled=false
 for frame in range(120):
  game._process(.05)
  if model.result!="":break
 await create_timer(.75).timeout
 check(model.result=="victory" and game.ui.current_screen=="story_result" and not game.last_progression.get("story",{}).is_empty(),"real projectile and settlement produce victory")
 if model.result!="victory":return
 await image("07-victory",VIEWPORT)
 game.ui.campaign.story_ui.show_timeline()
 await image("08-match-timeline",VIEWPORT)

func finish_capture() -> void:
 game.audio_system.shutdown()
 await create_timer(.12).timeout
 game.queue_free()
 await process_frame
 print("PHASE20_STORY_RENDER_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
