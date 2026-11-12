extends SceneTree
var checks=0
var failures=0
var feedback=preload("res://scripts/horror_feedback.gd").new()
class Fixture:
 extends RefCounted
 var rooms: Array=[]
 var presentation_events: Array=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("HORROR FEEDBACK: "+label)
func _initialize(): call_deferred("run")
func run():
 var model=Fixture.new()
 for i in range(6):
  var room=RoomState.new(i)
  room.owner=i
  room.sleeping=true
  room.closed=true
  model.rooms.append(room)
 var next=1
 for type in ["approach","encounter","door_damage","door_break","elimination"]:
  model.presentation_events.append({"id":next,"type":type,"room":2,"position":model.rooms[2].door_position(),"damage":12.5,"time":0.0})
  next+=1
 model.rooms[2].door_hp=0
 model.rooms[2].alive=false
 model.rooms[2].sleeping=false
 feedback.update(0.01,model)
 check(feedback.damage_numbers.size()==1 and feedback.damage_numbers[0].damage==12.5,"damage number retains actual fractional HP lost")
 check(feedback.breaks.size()==1,"one destruction per real break event")
 check(feedback.notifications.size()==1,"higher urgency replaces stale approach/attack alerts for the same room")
 feedback.alert("approach:0","!","Room1",0,5)
 feedback.alert("encounter:1","!!","Room2",1,5)
 feedback.alert("encounter:5","!!","Room6",1,5)
 check(feedback.notifications.size()==3,"simultaneous notifications bounded")
 check(feedback.notifications[0].priority==3 and feedback.notifications[0].text.contains("Mia"),"actual owner identity and elimination priority")
 check(feedback.notifications[0].text.contains("ROOM 03"),"actual model room ID")
 feedback.update(0.01,model)
 check(feedback.breaks.size()==1 and feedback.damage_numbers.size()==1,"observed events cannot repeat")
 check(feedback.observed_counts.encounter==1,"encounter processed exactly once")
 var death_count=int(feedback.observed_counts.get("elimination",0))
 model.presentation_events.append({"id":next,"type":"elimination","room":1,"position":model.rooms[1].door_position()});next+=1
 model.presentation_events.append({"id":next,"type":"door_break","room":1,"position":model.rooms[1].door_position()});next+=1
 feedback.update(.01,model)
 check(int(feedback.observed_counts.get("elimination",0))==death_count and feedback.breaks.size()==1,"living survivor/intact door cannot fabricate deaths or breach")
 var notifications=feedback.notifications.size()
 feedback.alert("elimination:2","X","duplicate",3,30)
 check(feedback.notifications.size()==notifications,"duplicate notification suppressed")
 # Rapid damage aggregates rather than overprinting numbers on one door.
 for i in range(100):
  model.presentation_events.append({"id":next,"type":"door_damage","room":i%6,"position":model.rooms[i%6].door_position(),"damage":2.25,"time":0.0})
  next+=1
 feedback.update(0.01,model)
 check(feedback.damage_numbers.size()<=6,"rapid simultaneous room damage is aggregated")
 var total=0.0
 for n in feedback.damage_numbers: total+=n.damage
 check(is_equal_approx(total,237.5),"aggregate damage is exact sum, no fabricated loss")
 check(feedback.door_impacts.size()==6,"independent per-room shake state")
 check(feedback.door_shake(0).length()>0,"door shake responds to actual impact")
 var before=feedback.notifications.size()
 model.presentation_events.append({"id":next,"type":"encounter","room":-1,"position":Vector2.ZERO,"damage":0})
 next+=1
 model.rooms[4].owner=-1
 model.presentation_events.append({"id":next,"type":"encounter","room":4,"position":Vector2.ZERO,"damage":0})
 feedback.update(0.01,model)
 check(feedback.notifications.size()==before,"invalid and unoccupied rooms cannot fabricate alerts")
 feedback.update(6.0,model)
 check(feedback.notifications.is_empty(),"notifications expire")
 check(feedback.damage_numbers.is_empty() and feedback.breaks.is_empty(),"damage/destruction effects expire")
 check(feedback.door_impacts.is_empty() and feedback.danger_rooms.is_empty(),"room danger and shake expire")
 model.rooms[4].owner=4
 model.presentation_events.append({"id":next+1,"type":"door_damage","room":0,"position":model.rooms[0].door_position(),"damage":22})
 feedback.update(0.01,model)
 feedback.update(0.14,model)
 model.presentation_events.append({"id":next+2,"type":"door_damage","room":0,"position":model.rooms[0].door_position(),"damage":33})
 feedback.update(0.01,model)
 check(feedback.damage_numbers.size()==1 and feedback.damage_numbers[0].damage==55,"separated rapid hits merge without overlapping values")
 check(feedback.damage_numbers[0].age==0,"merged number remains visible after newest hit")
 feedback.update(1.1,model)
 check(feedback.damage_numbers.is_empty(),"merged number expires after last hit")
 feedback.reset()
 check(feedback.last_event==0 and feedback.notifications.is_empty() and feedback.cooldowns.is_empty(),"restart clears event and cooldown state")
 print("HORROR_FEEDBACK_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
