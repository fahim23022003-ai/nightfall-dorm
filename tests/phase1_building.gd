extends SceneTree
var checks=0
var failures=0
var game

func check(ok: bool, label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("PHASE1: "+label)

func _initialize(): call_deferred("run")

func click(button: Button, double_click: bool=false):
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  event.double_click=double_click and pressed
  Input.parse_input_event(event)
  await process_frame

func run():
 for kind in Catalog.BUILDINGS:
  for level in range(1,Catalog.BUILDING_MAX_LEVEL+1):
   var room=RoomState.new(0)
   room.sleeping=true
   room.bed_level=4
   room.gold=10000
   room.electricity=10000
   check(room.build(kind,0),"build "+kind)
   for step in range(1,level): check(room.upgrade_building(0),"upgrade "+kind)
   var invested=Vector2(10000-room.gold,10000-room.electricity)
   var before=Vector2(room.gold,room.electricity)
   check(room.building_refund(0).is_equal_approx(invested*0.5),"quote includes actual upgrades")
   check(room.sell_building(0),"sell "+kind)
   check(Vector2(room.gold,room.electricity).is_equal_approx(before+invested*0.5),"exact half of both currencies")
   check(not room.buildings.has(0),"tile freed")
   var after=Vector2(room.gold,room.electricity)
   check(not room.sell_building(0),"duplicate sale rejected")
   check(not room.sell_building(-1),"invalid tile rejected")
   check(Vector2(room.gold,room.electricity)==after,"rejection cannot mint currency")
   check(room.build(kind,0),"tile reusable")
   room.alive=false
   check(not room.sell_building(0) and room.buildings.has(0),"eliminated resident cannot sell")
 # Investment belongs to payments, not an inferred level or an unpaid fixture.
 var unpaid=RoomState.new(0)
 unpaid.buildings[0]={"kind":"heavy","level":4}
 check(unpaid.building_refund(0)==Vector2.ZERO,"unpaid building has no invented refund")
 var ledger=RoomState.new(0)
 ledger.sleeping=true
 ledger.gold=1000
 ledger.electricity=1000
 ledger.build("repair",0)
 var quote=ledger.building_refund(0)
 ledger.buildings[0].level=4
 check(ledger.building_refund(0)==quote,"refund depends on paid ledger rather than level")
 ledger.buildings[0].level=1
 ledger.gold=0
 var power=ledger.electricity
 check(not ledger.upgrade_building(0),"unaffordable upgrade rejected")
 check(ledger.building_refund(0)==quote and ledger.electricity==power,"failed upgrade adds no investment or power charge")
 ledger.gold=1000
 var start=Vector2(ledger.gold,ledger.electricity)
 ledger.sell_building(0)
 start=Vector2(ledger.gold,ledger.electricity)
 for cycle in range(20):
  check(ledger.build("repair",0) and ledger.sell_building(0),"repeat build sell succeeds")
 check(Vector2(ledger.gold,ledger.electricity).is_equal_approx(start-Vector2(400,50)),"repeated cycles lose exactly half the payments")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_match()
 game.model.claim_room(0)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=1000
 room.electricity=1000
 game.selected_tile=0
 game.begin_placement("turret")
 await process_frame
 await click(game.ui.confirm_button)
 check(room.buildings.size()==1,"real confirmation builds once")
 game.ui.open_context()
 await process_frame
 var before=room.spent
 await click(game.ui.actions.upgrade)
 await click(game.ui.actions.upgrade,true)
 check(room.buildings[0].level==2,"double-click upgrades only once")
 check(room.spent-before==Catalog.BUILDINGS.turret.gold,"double-click charged once")
 await click(game.ui.actions.upgrade)
 check(room.buildings[0].level==3,"subsequent deliberate click works")
 game.model.running=false
 check(not game.model.sell_building(0),"paused sale blocked")
 game.model.running=true
 game.model.result="victory"
 check(not game.model.sell_building(0),"terminal sale blocked")
 game.model.result=""
 await click(game.ui.actions.sell)
 check(not room.buildings.has(0) and not game.ui.context_open,"sell UI frees tile and closes inspector")
 game.mobile_mode=true
 game.selected_tile=1
 check(room.build("generator",1),"mobile sale fixture")
 game.ui.open_context()
 await process_frame
 var sell=game.ui.actions.sell
 check(game.ui.context_box.position.y+game.ui.context_box.size.y<=604,"mobile drawer clears bottom HUD")
 check(sell.size.y>=60,"mobile sell target is finger sized")
 check(game.ui.context_box.get_global_rect().encloses(sell.get_global_rect()),"mobile sell stays inside drawer")
 check(not sell.get_global_rect().intersects(game.ui.actions.upgrade.get_global_rect()),"mobile sale and upgrade do not overlap")
 game.ui.actions.sell.pressed.emit()
 check(not room.buildings.has(1),"mobile drawer sale works")
 game.model.running=false
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 print("PHASE1_BUILDING_CHECKS=%d FAILURES=%d" % [checks,failures])
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
