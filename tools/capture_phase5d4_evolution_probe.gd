extends "res://tools/capture_phase5d4_core.gd"
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game();var m=boss_fixture();m.hunter.boss_policy.enabled=false
 for victim in [1,2,3]:
  var r=m.rooms[victim];r.door_hp=0;m.hunter.target=victim;m.hunter.position=r.bed_position();m.hunter.state=HunterState.State.BREACH;check(m.eliminate_resident(victim),"actualuniquevictim")
 var w=game.presentation.wrath_presentation
 for index in range(4):
  await advance(.15);await capture("evolution-probe-"+str(index))
  print("EVOLUTION_PROBE ",JSON.stringify({"seen_event":w.seen_event,"last_model_matches":w.last_model==m,"queue":w.evolution_queue,"banner_remaining":w.banner_remaining,"time":m.time,"connections":game.ui.horror_layer.draw.get_connections().size(),"events":m.presentation_events.filter(func(e):return e.type=="hunter_evolved")}))
  if index<3:await drive(4)
 print("EVOLUTION_PROBE_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
