class_name TeammateInterface
extends RefCounted
var ui
var game
var expanded=false
var toggle: Button
var body: Panel
var rows: Array=[]
var indices: Array=[]
var watching: Label
var home: Button
var empty: Label
func _init(owner):ui=owner;game=ui.game
func create():
 toggle=ui.button("Team · T",Vector2(920,91),toggle_panel,334,36)
 body=ui.box(Rect2(920,137,334,330),"20272F","9E8CAA")
 empty=ui.label_at("Teammates are finding rooms.",Vector2(14,18),16,306,false,body)
 rows.clear();indices.clear()
 for i in range(5):
  var slot=i
  var b=ui.button("",Vector2(10,12+i*60),func():
   if slot<indices.size():game.spectate_room(indices[slot]),314,54,body)
  b.add_theme_font_size_override("font_size",14);b.clip_text=true
  rows.append(b)
 watching=ui.label_at("",Vector2(920,137),14,334,true)
 home=ui.button("Return to My Room · Home",Vector2(770,466),game.return_to_my_room,263,34)
 update()
func toggle_panel():
 expanded=not expanded
 if expanded:game.cancel_placement();ui.close_context();ui.items_ui.expanded=false
 update()
func update():
 if not is_instance_valid(toggle):return
 var m=game.model
 var roster=m.rooms.filter(func(r):return r.owner>0)
 var alive=roster.filter(func(r):return r.alive).size()
 toggle.visible=not game.tutorial_active
 body.visible=expanded and toggle.visible
 toggle.text="TEAM %d/%d ALIVE · %s [T]" % [alive,roster.size(),"Close" if expanded else "View"]
 indices.clear()
 for r in roster:indices.append(r.index)
 empty.visible=roster.is_empty()
 for i in range(rows.size()):
  rows[i].visible=i<roster.size()
  if i>=roster.size():continue
  var r=roster[i]
  var threat=m.hunter.target==r.index and m.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
  threat=threat or m.minions.any(func(u):return u.hp>0 and u.target==r.index and u.position.distance_to(r.door_approach())<=3)
  var approaching=m.hunter.target==r.index and m.hunter.state==HunterState.State.MOVE
  var state="DEAD" if not r.alive else "BREACHED" if r.door_hp<=0 else "UNDER ATTACK" if threat else "APPROACHING" if approaching else "Alive"
  rows[i].text="%s · Room %02d · %s\nDoor %d/%d · Click to spectate" % [r.survivor_name(),r.index+1,state,r.door_hp,r.max_hp()]
  rows[i].tooltip_text="Observe only; your character and ownership stay in your room."
  rows[i].modulate=Color("F4B5B5") if threat or not r.alive else Color.WHITE
 var active=game.watched_room>=0 and game.watched_room<m.rooms.size()
 watching.visible=active and not expanded;home.visible=active
 ui.room_selected_summary.visible=not active
 for b in [ui.room_bed_summary,ui.room_door_summary,ui.room_selected_summary]:b.disabled=m.player()==null or active
 if active:
  var r=m.rooms[game.watched_room];var own=m.player()
  var danger=own!=null and (m.hunter.target==own.index and m.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH] or m.minions.any(func(u):return u.hp>0 and u.target==own.index and u.position.distance_to(own.door_approach())<=3))
  watching.text="OBSERVE ONLY · %s · Room %02d%s" % [r.survivor_name(),r.index+1," · ELIMINATED" if not r.alive else ""]
  if danger:watching.text="YOUR DOOR IS UNDER ATTACK! · HOME TO RETURN"
  watching.modulate=Color("FFB1A4") if danger else Color("D9CBE9")
  for b in [ui.room_bed_summary,ui.room_door_summary,ui.room_selected_summary]:b.disabled=true;b.tooltip_text="Return to your own room to edit its defenses."
