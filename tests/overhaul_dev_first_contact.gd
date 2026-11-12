extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("FIRST CONTACT "+label)
func _initialize():call_deferred("run")
func run():
 for mode in ["standard","hard","hell"]:
  for id in StrategyCatalog.ARCHETYPE_IDS:
   var m=MatchModel.new();m.configure_map("abandoned_dorm");m.configure_match(mode,{});m.configure_strategy(7,id);m.running=true;m.time=m.preparation+.1;m.player_room=0
   var r=m.rooms[0];r.owner=0;r.sleeping=true;r.closed=true;r.door_level=4;r.door_hp=r.max_hp();m.player_position=r.bed_position()
   var h=m.hunter;h.boss_policy.enabled=false;h.target=0;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0;h.arcane.cooldown=6
   var hp=r.door_hp
   h.tick(.01,m)
   check(r.door_hp==hp,"first contact harmless "+id+mode)
   check(h.archetype_primed and h.windup_remaining>0,"real warning "+id+mode)
   check(m.presentation_events.any(func(e):return e.type=="archetype_warning"),"warning event "+id+mode)
   h.tick(h.cooldown+.02,m);check(r.door_hp<hp,"subsequent real strike "+id+mode)
 var theme=GothicTheme.make_theme(load("res://assets/fonts/Interface.ttf"))
 check(theme.get_stylebox("panel","TooltipPanel").bg_color.a==1.0,"opaque information panel")
 print("OVERHAUL_FIRST_CONTACT_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
