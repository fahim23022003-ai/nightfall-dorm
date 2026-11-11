class_name DormTouchControls
extends Node

var game
var direction=Vector2.ZERO
var joystick_finger=-1
var taps: Dictionary={}
var route: Array=[]
var arrival=""
var destination_room=-1
var stalled=0.0
var scroll_gestures: Dictionary={}
const STICK=Vector2(118,510)
const RADIUS=76.0

func _init(owner_game=null): game=owner_game
func reset():
 direction=Vector2.ZERO
 joystick_finger=-1
 taps.clear()
 route.clear()
 arrival=""
 stalled=0
 scroll_gestures.clear()

func local_point(point: Vector2) -> Vector2:
 return game.ui.panel.get_global_transform().affine_inverse()*point

func awake() -> bool:
 return game.mode=="match" and game.model.running and not game.in_background and (game.model.player()==null or not game.model.player().sleeping)

func _input(event):
 if not game.mobile_mode: return
 if scroll_input(event): return
 if game.mode!="match": return
 if event is InputEventScreenTouch:
  var p=local_point(event.position)
  if event.pressed:
   if awake() and joystick_finger<0 and p.distance_to(STICK)<=RADIUS+22:
    joystick_finger=event.index
    route.clear()
    direction=((p-STICK)/RADIUS).limit_length()
    get_viewport().set_input_as_handled()
   else: taps[event.index]={"start":event.position,"last":event.position,"dragged":false}
  elif event.index==joystick_finger:
   joystick_finger=-1
   direction=Vector2.ZERO
   get_viewport().set_input_as_handled()
  elif taps.has(event.index):
   var tap=taps[event.index]
   taps.erase(event.index)
   if not tap.dragged and event.position.distance_to(tap.start)<24 and not ui_hit(event.position) and game.model.running:
    game.handle_touch_tap(event.position)
    get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  if event.index==joystick_finger:
   direction=((local_point(event.position)-STICK)/RADIUS).limit_length()
   get_viewport().set_input_as_handled()
  elif taps.has(event.index):
   taps[event.index].last=event.position
   if event.position.distance_to(taps[event.index].start)>24: taps[event.index].dragged=true
 elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
  # Joystick touches must not leak a second emulated click into the HUD.
  if awake() and (joystick_finger>=0 or local_point(event.position).distance_to(STICK)<=RADIUS+22): get_viewport().set_input_as_handled()

func ui_hit(point: Vector2,node: Node=null) -> bool:
 if node==null: node=game.ui.panel
 if node is Control and node.is_visible_in_tree() and not node.is_queued_for_deletion() and node.mouse_filter==Control.MOUSE_FILTER_STOP and node.get_global_rect().has_point(point): return true
 for child in node.get_children():
  if ui_hit(point,child): return true
 return false

func movement(delta: float) -> Vector2:
 if not awake():
  direction=Vector2.ZERO
  return Vector2.ZERO
 if joystick_finger>=0: return direction
 if route.is_empty(): return Vector2.ZERO
 var point: Vector2=route[0]
 if game.model.player_position.distance_to(point)<5:
  route.pop_front()
  if route.is_empty():
   if arrival=="claim" and destination_room>=0: game.model.claim_room(destination_room)
   elif arrival=="sleep": game.model.sleep_player()
   arrival=""
   return Vector2.ZERO
  point=route[0]
 var vector=point-game.model.player_position
 var next=game.model.player_position+vector.normalized()*minf(4,180*delta)
 if not game.model.can_walk(next):
  stalled+=delta
  if stalled>1.0:
   route.clear()
   game.ui.touch_notice("Path blocked. Use the movement stick to go around furniture.")
  return Vector2.ZERO
 stalled=0
 return vector.normalized()*minf(1,vector.length()/maxf(1,180*delta))

func navigate_room(room: RoomState):
 if not awake() or room.owner>=0: return
 route.clear()
 var pos=game.model.player_position
 for current in game.model.rooms:
  if current.bounds().has_point(pos):
   route.append(Vector2(current.center().x,pos.y))
   route.append(current.door_position()+Vector2(0,30 if current.index<3 else -30))
 route.append(Vector2(pos.x,410))
 route.append(Vector2(room.door_position().x,410))
 route.append(room.door_position()+Vector2(0,-34 if room.index<3 else 34))
 destination_room=room.index
 arrival="claim"

func navigate_bed():
 if not awake() or game.model.player()==null: return
 var room=game.model.player()
 var near=room.bed_position()+Vector2(0,55 if room.index<3 else -55)
 route=[Vector2(room.center().x,near.y),near]
 arrival="sleep"

func scroll_at(point: Vector2,node: Node=null):
 if node==null: node=game.ui.panel
 if node is ScrollContainer and node.is_visible_in_tree() and not node.is_queued_for_deletion() and node.get_global_rect().has_point(point): return node
 for child in node.get_children():
  var found=scroll_at(point,child)
  if found!=null: return found
 return null

func scroll_input(event) -> bool:
 if event is InputEventScreenTouch:
  if event.pressed:
   var view=scroll_at(event.position)
   if view!=null: scroll_gestures[event.index]={"view":view,"start":event.position,"value":view.scroll_vertical,"dragging":false}
  elif scroll_gestures.has(event.index):
   var gesture=scroll_gestures[event.index]
   scroll_gestures.erase(event.index)
   if gesture.dragging and is_instance_valid(gesture.view):
    gesture.view.propagate_notification(Control.NOTIFICATION_SCROLL_END)
    get_viewport().set_input_as_handled()
    return true
 elif event is InputEventScreenDrag and scroll_gestures.has(event.index):
  var gesture=scroll_gestures[event.index]
  if not is_instance_valid(gesture.view): scroll_gestures.erase(event.index); return false
  var distance=event.position.y-gesture.start.y
  if absf(distance)>16 or gesture.dragging:
   if not gesture.dragging:
    gesture.dragging=true
    gesture.view.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
   gesture.view.scroll_vertical=int(gesture.value-distance/maxf(0.01,gesture.view.get_global_transform().get_scale().y))
   get_viewport().set_input_as_handled()
   return true
 return false
