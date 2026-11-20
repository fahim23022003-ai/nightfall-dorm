extends RefCounted
## Disposable, ordered tutorial. Meaningful operations advance only on the
## real model signal or normal UI action associated with that lesson.

enum Lesson {
 OBJECTIVE, MOVE, SHARED_SPAWN, FIND_ROOM, CLAIM_ROOM, REACH_BED, SLEEP,
 OPEN_BUILD, SELECT_NEEDLE, PLACE_NEEDLE, CANCEL_PREVIEW, REOPEN_BUILD,
 SELECT_DYNAMO, PLACE_DYNAMO, UPGRADE, REPAIR, CLOSE_PANEL, HUNTER_DANGER,
 COMPLETE
}

const TITLES := [
 "Survive the night", "Move around", "Shared spawn", "Find a vacant room",
 "Claim your room", "Reach the bed", "Sleep and earn Gold", "Open Build",
 "Select Needle Turret", "Place the Needle Turret", "Cancel placement",
 "Open Build again", "Select Dynamo", "Place the Dynamo", "Upgrade a machine",
 "Repair the door", "Close the machine panel", "Face the Hunter", "Tutorial complete"
]

const NOTES := [
 "Claim a room, build a defense, and survive. This lesson uses a separate practice room.",
 "Use WASD or the arrow keys to move.",
 "Residents share a starting area before choosing separate rooms.",
 "Follow the corridor into any vacant room.",
 "Press E inside the vacant room to claim it.",
 "Walk within reach of the bed.",
 "Press E to sleep. The door locks, and the occupied bed produces Gold.",
 "Click Build or press B. Your practice allowance covers the lesson purchases.",
 "Choose Needle Turret on the Build panel.",
 "Click a clear grid location near the door. Your Needle targets the Hunter automatically.",
 "The Needle tool is still selected. Press Esc or click Cancel placement.",
 "Click Build or press B to reopen the machine catalogue.",
 "Choose Dynamo. It produces Electricity while you sleep.",
 "Click a legal grid location to build the Dynamo.",
 "Inspect the Needle or Dynamo and click Upgrade. Check the new level.",
 "A practice hit damaged your door. Click Repair or press R.",
 "Click Cancel or press Esc to close the machine panel.",
 "Watch the Hunter attack your door and the Needle fire back. Practice earns no rewards.",
 "Your practice is complete. Continue to Story or replay the tutorial."
]

const CARD_ORIGIN := Vector2(20,154)
const CARD_SIZE := Vector2(320,198)
const PRACTICE_ALLOWANCE := 500.0

var overlay
var game
var model_ref: WeakRef
var observed_room: WeakRef
var stage := Lesson.OBJECTIVE
var movement_origin := Vector2.ZERO
var needle_id := -1
var dynamo_id := -1
var upgraded_id := -1
var gold_before_sleep := 0.0
var lesson_paid := false
var danger_started := false
var danger_damage_before := 0.0
var danger_attacks_before := 0
var danger_shots_before := 0
var repair_damage := 0.0
var story_replay := false
var note := ""
var receipt: Array[Dictionary]=[]
var target_position := Vector2.INF
var target_kind := ""
var next_target_check := 0
var card: Panel
var heading_label: Label
var message_label: Label
var position_label: Label
var response_label: Label
var proceed: Button
var repeat: Button
var recover_button: Button
var exit_button: Button

func _init(control, owner, replay: bool):
 overlay=control
 game=owner
 story_replay=replay
 model_ref=weakref(game.model)

func begin():
 card=Panel.new()
 card.position=CARD_ORIGIN
 card.size=CARD_SIZE
 card.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card.add_theme_stylebox_override("panel",GothicTheme.surface("182222","9D8355","button_normal"))
 overlay.add_child(card)
 position_label=label(Vector2(16,10),Vector2(292,21),15,Color("C9B385"))
 heading_label=label(Vector2(16,35),Vector2(292,27),21,Color("F1E6D3"))
 message_label=label(Vector2(16,67),Vector2(288,61),16,Color("DBDBD1"))
 message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 response_label=label(Vector2(16,129),Vector2(288,24),13,Color("D6A467"))
 response_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 proceed=button("Continue",Vector2(16,153),Vector2(130,32),acknowledge)
 repeat=button("Replay Tutorial",Vector2(155,153),Vector2(149,32),func():complete(true))
 recover_button=button("Recover",Vector2(16,153),Vector2(130,32),recover)
 exit_button=button("Exit practice" if story_replay else "Skip tutorial",Vector2(155,153),Vector2(149,32),overlay.skip_tutorial)
 refresh()

func label(at: Vector2, extent: Vector2, font_size: int, color: Color) -> Label:
 var control:=Label.new()
 control.position=at
 control.size=extent
 control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 control.add_theme_font_size_override("font_size",font_size)
 control.add_theme_color_override("font_color",color)
 card.add_child(control)
 return control

func button(title: String, at: Vector2, extent: Vector2, action: Callable) -> Button:
 var control:=Button.new()
 control.text=title
 control.position=at
 control.size=extent
 control.add_theme_font_size_override("font_size",15)
 control.pressed.connect(action)
 card.add_child(control)
 overlay.primary_button(control)
 return control

func active_model():
 var model=model_ref.get_ref()
 return model if game.tutorial_active and model==game.model else null

func observed_player():
 var model=active_model()
 return model.player() if model!=null else null

func dispose():
 if observed_room!=null:
  var room=observed_room.get_ref()
  if room!=null and room.presentation_action.is_connected(room_action):
   room.presentation_action.disconnect(room_action)

func refresh():
 overlay.step=stage
 position_label.text="PRACTICE · %d / %d" % [stage+1,TITLES.size()]
 heading_label.text=TITLES[stage]
 message_label.text=NOTES[stage]
 response_label.text=note
 proceed.visible=stage in [Lesson.OBJECTIVE,Lesson.SHARED_SPAWN,Lesson.COMPLETE]
 proceed.text="Continue Story" if stage==Lesson.COMPLETE else "Continue"
 repeat.visible=stage==Lesson.COMPLETE
 recover_button.visible=stage==Lesson.HUNTER_DANGER
 exit_button.visible=stage!=Lesson.COMPLETE
 overlay.queue_redraw()

func acknowledge():
 if stage in [Lesson.OBJECTIVE,Lesson.SHARED_SPAWN]:advance()
 elif stage==Lesson.COMPLETE:complete(false)

func advance():
 if stage>=Lesson.COMPLETE:return
 stage+=1
 note=""
 target_kind=""
 target_position=Vector2.INF
 next_target_check=0
 var model=active_model()
 if model==null:return
 if stage==Lesson.MOVE:movement_origin=model.player_position
 if stage==Lesson.REPAIR:demonstrate_damage()
 if stage==Lesson.CLOSE_PANEL and not game.ui.context_open:
  game.selected_tile=upgraded_id
  game.ui.open_context()
 if stage==Lesson.COMPLETE:
  model.running=false
  game.cancel_placement()
  game.ui.close_context()
 overlay.audio_event_for_practice_step()
 refresh()

func permits_interact() -> bool:
 return stage in [Lesson.CLAIM_ROOM,Lesson.SLEEP]

func permits_place(kind: String, point: Vector2=Vector2.INF) -> bool:
 if stage==Lesson.PLACE_NEEDLE and kind=="turret":
  var room=observed_player()
  if room!=null and point.is_finite() and point.distance_to(room.door_approach())>Catalog.BUILDINGS.turret.range:
   set_note("Place the Needle within range of the doorway.")
   return false
  return true
 if stage==Lesson.PLACE_DYNAMO and kind=="generator":return true
 set_note("Follow the current practice instruction.")
 return false

func note_build_open():
 if stage in [Lesson.OPEN_BUILD,Lesson.REOPEN_BUILD]:
  advance()

func note_build_selected(kind: String):
 if (stage==Lesson.SELECT_NEEDLE and kind=="turret") or (stage==Lesson.SELECT_DYNAMO and kind=="generator"):
  advance()
 elif stage in [Lesson.SELECT_NEEDLE,Lesson.SELECT_DYNAMO]:
  set_note("Reopen Build and select the highlighted machine.")
 elif stage==Lesson.CANCEL_PREVIEW and kind=="turret":
  set_note("")

func note_placement_cancelled(kind: String):
 if stage==Lesson.CANCEL_PREVIEW and kind=="turret":
  receipt.append({"event":"explicit_placement_cancel","kind":kind})
  advance()
 elif stage==Lesson.PLACE_NEEDLE and kind=="turret":
  stage=Lesson.SELECT_NEEDLE
  set_note("Reopen Build to select the Needle again.")
  refresh()
 elif stage==Lesson.PLACE_DYNAMO and kind=="generator":
  stage=Lesson.SELECT_DYNAMO
  set_note("Reopen Build to select the Dynamo again.")
  refresh()

func note_panel_closed():
 if stage==Lesson.CLOSE_PANEL:
  receipt.append({"event":"panel_closed"})
  advance()

func room_action(event: String, data: Dictionary):
 var room=observed_player()
 if room==null:return
 if event=="build":
  var id:=int(data.get("tile",-1))
  if not room.buildings.has(id) or float(data.get("spent_gold",0))<=0:return
  var kind: String=data.get("kind","")
  if stage==Lesson.PLACE_NEEDLE and kind=="turret":needle_id=id
  elif stage==Lesson.PLACE_DYNAMO and kind=="generator":dynamo_id=id
  else:return
 elif event=="building_upgrade" and stage==Lesson.UPGRADE:
  var id:=int(data.get("tile",-1))
  if id not in [needle_id,dynamo_id] or int(data.get("level",0))<2 or float(data.get("spent_gold",0))<=0:return
  upgraded_id=id
 elif event=="repair" and stage==Lesson.REPAIR:
  if repair_damage<=0.0 or float(data.get("amount",0))<=0.0 or float(data.get("spent_gold",0))<=0.0:return
 else:return
 var entry:=data.duplicate(true)
 entry.event=event
 receipt.append(entry)
 advance()

func set_note(text: String):
 note=text
 if is_instance_valid(response_label):response_label.text=note

func demonstrate_damage():
 var model=active_model()
 var room=model.player() if model!=null else null
 if room==null:return
 # Run an isolated impact through the normal door-damage transaction.
 var hunter=model.hunter
 var prior=[hunter.state,hunter.position,hunter.target]
 hunter.state=HunterState.State.ATTACK
 hunter.position=room.door_approach()
 hunter.target=room.index
 repair_damage=model.apply_room_damage(room.index,room.max_hp()*.26,"tutorial practice strike")
 hunter.state=prior[0]
 hunter.position=prior[1]
 hunter.target=prior[2]
 if repair_damage<=0.0:set_note("Waiting for a valid practice impact.")

func tick():
 var model=active_model()
 if model==null:return
 var room=model.player()
 match stage:
  Lesson.MOVE:
   if model.player_position.distance_squared_to(movement_origin)>36.0*36.0:advance()
  Lesson.FIND_ROOM:
   for candidate in model.rooms:
    if candidate.owner<0 and candidate.bounds().grow(-12).has_point(model.player_position):
     advance()
     break
  Lesson.CLAIM_ROOM:
   if room!=null and room.owner==0:
    observed_room=weakref(room)
    room.presentation_action.connect(room_action)
    advance()
  Lesson.REACH_BED:
   if room!=null and model.player_position.distance_to(room.bed_position())<=55.0:
    gold_before_sleep=room.income_total
    advance()
  Lesson.SLEEP:
   if room!=null and room.sleeping and room.income_total>gold_before_sleep:
    if not lesson_paid:
     lesson_paid=true
     room.gold+=PRACTICE_ALLOWANCE
    advance()
  Lesson.UPGRADE:
   update_upgrade_prompt(room)
  Lesson.HUNTER_DANGER:
   tick_danger(model,room)

func update_upgrade_prompt(room):
 if room==null:return
 var selected: int=game.selected_tile
 if selected not in [needle_id,dynamo_id]:selected=needle_id
 if not room.buildings.has(selected):return
 var machine: Dictionary=room.buildings[selected]
 var price:=BalanceRules.upgrade(machine.kind,machine.level,room.balance_version)
 var required: float=room.building_price(price.x,price.y).y
 var label_text: String="Dynamo charging · %.1f / %.1f Electricity" % [room.electricity,required] if room.electricity+.00001<required else ""
 if label_text!=note:set_note(label_text)

func tick_danger(model,room):
 if room==null:return
 if not danger_started:
  danger_started=true
  danger_attacks_before=model.hunter.attacks
  danger_damage_before=room.door_damage_taken
  danger_shots_before=room.shots
  model.preparation=model.time-1.0
  var hunter=model.hunter
  hunter.boss_policy.enabled=false
  hunter.hp=85.0
  hunter.max_hp=85.0
  hunter.target=room.index
  hunter.position=room.door_approach()
  hunter.state=HunterState.State.ATTACK
  hunter.cooldown=.1
 if model.result=="victory" and room.shots>danger_shots_before and model.hunter.attacks>danger_attacks_before and room.door_damage_taken>danger_damage_before:
  receipt.append({"event":"practice_combat","attacks":model.hunter.attacks-danger_attacks_before,"shots":room.shots-danger_shots_before,"damage":room.door_damage_taken-danger_damage_before})
  advance()
 elif model.result!="":
  set_note("Use Recover to retry this practice encounter.")

func recover():
 var room=observed_player()
 if stage!=Lesson.HUNTER_DANGER or room==null:return
 var model=active_model()
 model.running=true
 model.result=""
 room.alive=true
 room.sleeping=true
 room.closed=true
 room.door_hp=room.max_hp()
 danger_started=false
 set_note("Practice reset. Your machines are still installed.")

func complete(replay: bool):
 if stage!=Lesson.COMPLETE:return
 if not game.profile.complete_tutorial():
  set_note("The completion could not be saved. Retry.")
  return
 overlay.tutorial_finished=true
 game.audio_event("tutorial_complete")
 overlay.finish_replay()
 if replay:game.start_tutorial(true)
 else:game.enter_game()

func world_rect(rect: Rect2) -> Rect2:
 var a: Vector2=game.world_to_screen(rect.position)
 var b: Vector2=game.world_to_screen(rect.end)
 var to_overlay: Transform2D=overlay.get_global_transform_with_canvas().affine_inverse()
 return Rect2(to_overlay*a,to_overlay*b-to_overlay*a).abs()

func button_rect(control) -> Rect2:
 if not is_instance_valid(control) or not control.is_visible_in_tree() or control.disabled:return Rect2()
 var to_overlay: Transform2D=overlay.get_global_transform_with_canvas().affine_inverse()
 var to_viewport: Transform2D=control.get_global_transform_with_canvas()
 var a:=to_overlay*(to_viewport*Vector2.ZERO)
 var b: Vector2=to_overlay*(to_viewport*control.size)
 return Rect2(a,b-a).abs()

func practice_cell(room,kind: String) -> Vector2:
 if room.spatial==null or not room.spatial.grid:return Vector2.INF
 var rotation: int=game.construction.rotation
 if target_kind==kind and target_position.is_finite() and room.spatial.purchase_reason(kind,target_position,rotation)=="":
  return target_position
 var now:=Time.get_ticks_msec()
 if now<next_target_check:return Vector2.INF
 next_target_check=now+250
 target_kind=kind
 target_position=Vector2.INF
 var area: Rect2=room.spatial.grid_bounds()
 var size: Vector2=room.spatial.footprint_for(Vector2.ZERO,kind,rotation).size
 var start:=area.position+size*.5
 var stop:=area.end-size*.5
 var best:=INF
 for y in range(0,floori((stop.y-start.y)/SpatialConstruction.CELL_SIZE)+1):
  for x in range(0,floori((stop.x-start.x)/SpatialConstruction.CELL_SIZE)+1):
   var point:=start+Vector2(x,y)*SpatialConstruction.CELL_SIZE
   var distance: float=point.distance_squared_to(room.door_approach())
   if kind=="turret" and distance>Catalog.BUILDINGS.turret.range**2:continue
   var actual:=world_rect(room.spatial.footprint_for(point,kind,rotation))
   if not Rect2(345,115,540,485).encloses(actual):distance+=1000000.0
   if distance>=best or room.spatial.purchase_reason(kind,point,rotation)!="":continue
   best=distance
   target_position=point
 return target_position

func focus_target() -> Rect2:
 var model=active_model()
 if model==null:return Rect2()
 var room=model.player()
 var ui=game.ui
 if stage in [Lesson.SELECT_NEEDLE,Lesson.SELECT_DYNAMO,Lesson.UPGRADE,Lesson.CLOSE_PANEL] and ui.bottom_context!=null and ui.bottom_context.is_transitioning():
  return Rect2()
 match stage:
  Lesson.FIND_ROOM:
   var closest=null
   var distance:=INF
   for candidate in model.rooms:
    var span: float=candidate.door_approach().distance_squared_to(model.player_position)
    if candidate.owner<0 and span<distance:
     distance=span
     closest=candidate
   if closest!=null:return world_rect(Rect2(closest.door_position()-Vector2(20,20),Vector2(40,40)))
  Lesson.CLAIM_ROOM:
   return world_rect(Rect2(model.player_position-Vector2(24,24),Vector2(48,48)))
  Lesson.REACH_BED,Lesson.SLEEP:
   if room!=null:return world_rect(Rect2(room.bed_position()-Vector2(22,30),Vector2(44,60)))
  Lesson.OPEN_BUILD,Lesson.REOPEN_BUILD:
   return button_rect(ui.room_selected_summary)
  Lesson.SELECT_NEEDLE:
   var control:=button_rect(ui.actions.get("build:turret"))
   return control if control.has_area() else button_rect(ui.room_selected_summary)
  Lesson.SELECT_DYNAMO:
   var control:=button_rect(ui.actions.get("build:generator"))
   return control if control.has_area() else button_rect(ui.room_selected_summary)
  Lesson.PLACE_NEEDLE,Lesson.PLACE_DYNAMO:
   var kind: String="turret" if stage==Lesson.PLACE_NEEDLE else "generator"
   if game.construction.kind!=kind:
    return build_selector_or_toolbar(ui,kind)
   if room!=null:
    var point:=practice_cell(room,kind)
    if point.is_finite():return world_rect(room.spatial.footprint_for(point,kind,game.construction.rotation))
  Lesson.CANCEL_PREVIEW:
   if game.construction.kind=="turret":return button_rect(ui.grid_placement_cancel_button)
   set_note("Reopen Build and reselect the Needle tool.")
   return build_selector_or_toolbar(ui,"turret")
  Lesson.UPGRADE:
   var upgrade:=button_rect(ui.actions.get("upgrade"))
   if ui.context_open and ui.context_mode=="upgrade" and game.selected_tile in [needle_id,dynamo_id]:return upgrade
   if room!=null and room.buildings.has(needle_id):
    var point: Vector2=room.tile_position(needle_id)
    return world_rect(room.spatial.footprint_for(point,"turret",int(room.buildings[needle_id].get("rotation",0))))
  Lesson.REPAIR:
   return button_rect(ui.quick_repair)
  Lesson.CLOSE_PANEL:
   return button_rect(ui.build_cancel_button)
  Lesson.HUNTER_DANGER:
   return world_rect(Rect2(model.hunter.position-Vector2(22,48),Vector2(44,69)))
 return Rect2()

func build_selector_or_toolbar(ui,kind: String) -> Rect2:
 if ui.bottom_context!=null and ui.bottom_context.is_transitioning():return Rect2()
 var control:=button_rect(ui.actions.get("build:"+kind))
 return control if ui.context_open and ui.context_mode=="build" and control.has_area() else button_rect(ui.room_selected_summary)

func draw():
 var box:=focus_target()
 if not box.has_area():return
 # The outline uses the actual clickable rectangle or the actual world footprint.
 # Omit an offscreen target. Moving it into view would point to a false button.
 var frame:=Rect2(Vector2.ZERO,overlay.size)
 if not frame.encloses(box):return
 if Rect2(CARD_ORIGIN,CARD_SIZE).intersects(box):
  var alternative:=Vector2(940,154)
  if not Rect2(alternative,CARD_SIZE).intersects(box):
   card.position=alternative
 else:card.position=CARD_ORIGIN
 var color:=Color("FFE0A0")
 var edge:=box.grow(5.0)
 overlay.draw_rect(edge,Color(.95,.75,.33,.10))
 overlay.draw_rect(edge,color,false,2.5)
