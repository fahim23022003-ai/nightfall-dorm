extends SceneTree
# Independent Agent C transaction and actual-input regression tests.
var checks=0
var failures=0
var game

func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("PHASE1 INDEPENDENT: "+label)

func _initialize(): call_deferred("run")

func mouse(point: Vector2,double_click=false):
 point=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 for down in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=down
  e.double_click=double_click and down
  Input.parse_input_event(e)
  await process_frame

func key(code: int):
 for down in [true,false]:
  var e=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  Input.parse_input_event(e)
  await process_frame

func tap(point: Vector2,double_tap=false):
 for down in [true,false]:
  var e=InputEventScreenTouch.new()
  e.position=root.get_final_transform()*point
  e.index=0
  e.pressed=down
  e.double_tap=double_tap and down
  Input.parse_input_event(e)
  await process_frame

func money(room) -> Vector2: return Vector2(room.gold,room.electricity)

func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase1-independent-profile.json")
 # Repeated buy/upgrade/sell cannot increase either currency; failed upgrades
 # must not become investments refunded later.
 for kind in Catalog.BUILDINGS:
  var r=RoomState.new(0)
  r.sleeping=true
  r.bed_level=4
  r.gold=100000
  r.electricity=100000
  for iteration in range(8):
   var before=money(r)
   check(r.build(kind,5),"cycle build "+kind)
   check(not r.build(kind,5),"duplicate build rejects "+kind)
   check(r.upgrade_building(5),"cycle upgrade "+kind)
   var paid=before-money(r)
   var after=money(r)
   check(r.building_refund(5).is_equal_approx(paid*0.5),"separate currency exact investment "+kind)
   check(r.sell_building(5),"cycle sale "+kind)
   check(money(r).is_equal_approx(after+paid*0.5),"refund exactly half "+kind)
   var sold=money(r)
   check(not r.sell_building(5) and money(r)==sold,"duplicate sale no resources "+kind)
   check(money(r).x<=before.x and money(r).y<=before.y,"no cycle profit "+kind)
  check(r.build(kind,0),"failed upgrade fixture "+kind)
  var original=r.building_refund(0)
  r.gold=0
  r.electricity=0
  check(not r.upgrade_building(0),"unaffordable upgrade rejects "+kind)
  check(r.building_refund(0)==original,"failed upgrade not refundable "+kind)
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.start_match()
 game.set_process(false)
 game.model.claim_room(0)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=1000
 room.electricity=1000
 game.focus_camera(true)
 game.ui.update_match()
 game.selected_tile=0
 game.ui.open_context()
 await process_frame
 var before=money(room)
 var card=game.ui.actions["build:turret"].get_global_rect().get_center()
 await mouse(card)
 await mouse(card,true)
 check(game.pending_build=="turret" and money(room)==before,"card double-click only previews without charge")
 await mouse(game.ui.confirm_button.get_global_rect().get_center())
 check(room.buildings.has(0) and game.pending_build=="" and not game.ui.context_open,"confirm exits placement")
 var built=money(room)
 await mouse(game.ui.confirm_button.get_global_rect().get_center(),true)
 check(money(room)==built and room.buildings.size()==1,"trailing confirmation click cannot charge twice")
 game.selected_tile=1
 game.begin_placement("repair")
 await process_frame
 var cancel: Button
 for node in game.ui.confirmation_items:
  if node is Button and node!=game.ui.confirm_button: cancel=node
 await mouse(cancel.get_global_rect().get_center())
 check(game.pending_build=="" and not game.ui.context_open and money(room)==built,"actual Cancel button frees pending without spending")
 game.begin_placement("generator")
 await key(KEY_ESCAPE)
 check(game.pending_build=="" and game.model.running and money(room)==built,"Escape cancels without pause or charge")
 game.begin_placement("generator")
 game.ui.close_context()
 check(game.pending_build=="" and not game.ui.context_open,"closing inspector cannot leave invisible placement")
 game.begin_placement("generator")
 await mouse(game.ui.room_selected_summary.get_global_rect().get_center())
 check(game.pending_build=="" and game.ui.context_open and game.ui.context_mode=="build","selected dock switches inspector and cancels preview")
 game.begin_placement("generator")
 game.toggle_pause()
 check(game.pending_build=="" and not game.model.running,"pause clears placement")
 check(not game.confirm_placement() and money(room)==built,"paused stale confirmation cannot purchase")
 game.toggle_pause()
 game.begin_placement("repair")
 game.placement_on_tile=false
 check(not game.confirm_placement() and money(room)==built,"invalid pad confirmation cannot charge")
 game.handle_touch_tap(game.world_to_screen(room.tile_position(1)))
 check(game.placement_on_tile and game.pending_build=="repair","valid pad recovers invalid preview")
 check(game.confirm_placement(),"recovered preview purchases once")
 check(not game.confirm_placement(),"repeat method confirmation rejects")
 game.selected_tile=2
 game.begin_placement("turret")
 game.model.result="victory"
 game._process(0.01)
 check(game.mode=="result" and game.pending_build=="","match result clears pending placement")
 # Exercise raw mobile taps and the engine mouse-emulation path together.
 game.mobile_mode=true
 Input.emulate_mouse_from_touch=true
 game.start_match()
 game.model.claim_room(0)
 room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=1000
 room.electricity=1000
 game.focus_camera(true)
 game.ui.update_match()
 game.selected_tile=0
 game.begin_placement("repair")
 await process_frame
 before=money(room)
 var confirm=game.ui.confirm_button.get_global_rect().get_center()
 await tap(confirm)
 var purchased=money(room)
 await tap(confirm,true)
 check(room.buildings.size()==1 and money(room)==purchased,"raw mobile double-tap confirmation charges once")
 check((before-purchased).is_equal_approx(Vector2(Catalog.BUILDINGS.repair.gold,Catalog.BUILDINGS.repair.power)),"raw mobile purchase tracks separate currencies")
 game.ui.open_context()
 game.ui.update_match()
 await process_frame
 var sale=game.ui.actions.sell.get_global_rect().get_center()
 await tap(sale)
 var refunded=money(room)
 await tap(sale,true)
 check(not room.buildings.has(0) and money(room)==refunded,"raw mobile double-tap sale refunds once")
 check((refunded-purchased).is_equal_approx((before-purchased)*0.5),"raw mobile refund exactly half paid")
 game.selected_tile=0
 game.begin_placement("turret")
 game.mobile_back()
 check(game.pending_build=="" and money(room)==refunded,"Android Back cancellation never spends")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("PHASE1_INDEPENDENT_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
