class_name VisualPresence
extends RefCounted
# Truthful, read-only pacing and match-local scars. No gameplay RNG or AI mutations.
const MAX_SCARS=48
var scars: Array=[]
var seen: Dictionary={}
var model_ref
var tension="quiet"
var intensity=0.0
var relief=0.0
var previous_threat=false
var elimination_hold=0.0
var heading=Vector2.RIGHT
var velocity=Vector2.ZERO
var last_hunter=Vector2.INF
var clock=0.0
func reset():
 scars.clear();seen.clear();model_ref=null;tension="quiet";intensity=0;relief=0;previous_threat=false;heading=Vector2.RIGHT;velocity=Vector2.ZERO;last_hunter=Vector2.INF;clock=0;elimination_hold=0
func update(delta: float,model):
 if not is_finite(delta) or delta<=0:return
 if model_ref!=null and model_ref!=model:reset()
 model_ref=model
 if not model.running:return
 var action_delta=maxf(0,delta-model.items.frozen_delta)
 clock+=action_delta
 elimination_hold=maxf(0,elimination_hold-delta)
 var h=model.hunter
 velocity=Vector2.ZERO
 if last_hunter.is_finite() and action_delta>0:
  velocity=(h.position-last_hunter)/delta
  if velocity.length()>.1:heading=heading.slerp(velocity.normalized(),clampf(action_delta*10,0,1)).normalized()
 last_hunter=h.position
 if action_delta>0 and h.state in [HunterState.State.ATTACK,HunterState.State.BREACH] and h.target>=0 and h.target<model.rooms.size():
  var goal=model.rooms[h.target].bed_position() if h.state==HunterState.State.BREACH else model.rooms[h.target].door_position()
  if goal.distance_to(h.position)>1:heading=heading.slerp((goal-h.position).normalized(),clampf(action_delta*8,0,1)).normalized()
 var room=model.player()
 var threat=h.hp>0 and h.state not in [HunterState.State.DORMANT,HunterState.State.DEAD]
 var own=room!=null and h.target==model.player_room
 var danger=own and h.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
 if previous_threat and not danger:relief=3.0
 previous_threat=danger
 relief=maxf(0,relief-delta)
 tension="quiet";var target=0.0
 if threat:
  tension="distant";target=.18
  if h.state==HunterState.State.MOVE:tension="approach";target=.38 if own else .27
  if h.state==HunterState.State.ATTACK:tension="siege";target=.65
  if danger and (room.door_hp<room.max_hp()*.35 or h.state==HunterState.State.BREACH):tension="danger";target=1.0
 if relief>0 and not danger:tension="relief";target=.08
 for e in model.presentation_events:
  if seen.has(e.id):continue
  seen[e.id]=true
  var kind=str(e.type)
  if kind in ["door_damage","door_break","elimination"] and e.room>=0 and e.room<model.rooms.size():
   var r=model.rooms[e.room]
   if kind=="door_damage" and (e.damage<=0 or not e.has("hp") or not e.has("max_hp") or e.hp>=e.max_hp):continue
   if kind=="door_break" and r.door_hp>0:continue
   if kind=="elimination" and r.alive:continue
   if kind=="elimination":elimination_hold=2.0
   var point=r.bed_position() if kind=="elimination" else r.door_position()
   var key=kind+":"+str(e.room)
   if not scars.any(func(s):return s.key==key):scars.append({"key":key,"kind":kind,"point":point,"room":e.room})
 for e in model.items.events:
  var key="item:"+str(e.id)
  if seen.has(key):continue
  seen[key]=true
  if e.phase=="explode":scars.append({"key":key,"kind":"scorch","point":e.position,"room":model.player_room})
 if scars.size()>MAX_SCARS:scars=scars.slice(scars.size()-MAX_SCARS)
 if seen.size()>512:
  var keep={}
  for e in model.presentation_events:keep[e.id]=true
  for e in model.items.events:keep["item:"+str(e.id)]=true
  seen=keep
 if elimination_hold>0 and tension!="danger":tension="elimination";target=.8
 intensity=move_toward(intensity,target,delta*.8)
