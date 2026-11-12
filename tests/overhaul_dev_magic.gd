extends SceneTree
var checks=0
func check(value):
 checks+=1
 if not value:push_error("Magic assertion %d" % checks);quit(1)
func _initialize():call_deferred("run")
func run():
 var m=MatchModel.new();m.configure_map("abandoned_dorm");m.configure_match("standard",{});m.running=true;m.player_room=0
 var r=m.rooms[0];r.owner=0;r.sleeping=true;r.closed=true;r.gold=10000;r.electricity=10000;r.door_level=4;r.door_hp=r.max_hp();m.hunter.position=r.door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK
 for kind in MagicDefense.KINDS:check(r.build(kind,r.buildings.size()))
 var h=m.hunter.hp;var hp=r.door_hp
 check(m.apply_room_damage(0,20,"claw")>0);check(m.hunter.hp==h);check(r.magic_state.stored==0)
 r.door_hp=hp;MagicDefense.tick(m,.1)
 check(r.magic_state.shield>0)
 check(m.apply_room_damage(0,100,"curse")<100);check(m.hunter.hp<h);check(r.magic_state.stored>=0)
 check(DamageRules.multiplier("fire","ice")==1.15)
 check(DamageRules.multiplier("ice","fire")==.9)
 check(DamageRules.weapon("turret").type=="physical")
 check(DamageRules.weapon("flame").type=="magic")
 print("OVERHAUL_MAGIC_CHECKS=%d FAILURES=0" % checks);quit()
