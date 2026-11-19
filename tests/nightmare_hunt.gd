extends "res://tests/earned_power.gd"

func run():
 var m=fresh()
 var room=m.player()
 room.electricity=12
 check(not m.route_defense_power(),"preparation rejects ward")
 m.time=m.preparation+1
 check(m.route_defense_power() and room.electricity==6,"ward costs actual Electricity")
 check(not m.route_defense_power() and room.electricity==6,"duplicate activation is atomic")
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.position=room.door_approach()
 m.hunter.target=room.index
 m.apply_room_damage(room.index,60,"door strike")
 check(m.contribution.ward_blocked>0 and m.ward_capacity<60,"ward blocks actual damage")
 m.time+=5
 var capacity=m.ward_capacity
 m.apply_room_damage(room.index,10,"door strike")
 check(m.ward_capacity==capacity,"expired ward cannot block")
 m.hunter.hp=0
 m.endless.finish_wave(m)
 var snapshot=ReplaySnapshot.encode(m)
 check(not snapshot.is_empty() and ReplaySnapshot.valid(snapshot),"current checkpoint with ward and contribution validates")
 var restored=ReplaySnapshot.restore(snapshot)
 check(restored!=null and restored.ward_ready_at==m.ward_ready_at and restored.contribution.ward_blocked==m.contribution.ward_blocked,"resume preserves cooldown and contribution")
 var legacy=fresh(1)
 check(not legacy.route_defense_power(),"legacy excludes ward")
 print("NIGHTMARE_HUNT_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
