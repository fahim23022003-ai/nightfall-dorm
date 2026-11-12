extends "res://tools/capture_phase5d4_core.gd"
var pcm_recorder
var audio_results=[]
var final_audio_path="res://docs/evidence/phase5d4/"
func pcm_begin():pcm_recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,pcm_recorder);pcm_recorder.set_recording_active(true)
func pcm_end(label):
 pcm_recorder.set_recording_active(false);var wav=pcm_recorder.get_recording();check(wav!=null and wav.data.size()>1000,"actual MasterPCM "+label)
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path(final_audio_path+label+".wav"))==OK,"actual WAV "+label)
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1);pcm_recorder=null
func live(seconds):
 var begin=Time.get_ticks_usec();var previous=begin
 while Time.get_ticks_usec()-begin<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();game._process(minf(.1,(now-previous)/1000000.0));previous=now
func event_diff(before):
 var out={}
 for id in game.audio_system.event_counts:
  var count=int(game.audio_system.event_counts[id])-int(before.get(id,0))
  if count>0:out[id]=count
 return out
func track_case(label,seconds):
 var before=game.audio_system.event_counts.duplicate(true);pcm_begin();await live(seconds);pcm_end(label)
 var result={"label":label,"seconds":seconds,"played":event_diff(before),"diagnostics":game.audio_system.get_diagnostics()};audio_results.append(result);return result
func weapons():
 for kind in ["turret","heavy","flame","frost","shock"]:
  game.return_menu();game.start_practice("crusher",false,["shield","repair"]);game.set_process(false);game.tutorial_enabled=false
  var m=game.model;var r=m.player();var tile=m.practice_tile;var h=m.hunter
  h.boss_policy.enabled=false;h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=60;h.tactical_cooldown=60;game.focus_camera(true);await live(.2)
  if kind!="turret":
   await world_click(r.tile_position(tile));await advance(.15);await click(game.ui.actions.sell);await advance(.15);await world_click(r.tile_position(tile));await advance(.15);await click(game.ui.actions["build:"+kind]);await advance(.15)
   check(r.buildings.has(tile) and r.buildings[tile].kind==kind,"actual paid input "+kind)
  game.ui.close_context();game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":.5,"muted":false});await live(1.5)
  var shots=m.shots;var hp=h.hp;var label="core-audio-weapon-"+kind
  var result=await track_case(label,6);var prefix={"turret":"shot_needle","heavy":"shot_arc","flame":"shot_flame","frost":"shot_frost","shock":"shot_shock"}[kind];var cues=0
  for id in result.played:
   if id.begins_with(prefix):cues+=result.played[id]
  check(m.shots>shots and h.hp<hp and cues>0,"actual real projectile/damage/sampled output "+kind)
  check(result.played.get("ghost_hurt",0)>0 and result.played.get("undead_hurt",0)==0,"mainHunterid1 routes its ownhurt "+kind)
  await capture(label+"-720")
func evolution_audio():
 var m=boss_fixture();m.hunter.boss_policy.enabled=false
 for victim in [1,2,3]:
  var r=m.rooms[victim];r.door_hp=0;m.hunter.position=r.bed_position();m.hunter.target=victim;m.hunter.state=HunterState.State.BREACH;check(m.eliminate_resident(victim),"actual unique evolutionkill")
 m.hunter.cooldown=60;m.hunter.tactical_cooldown=60
 game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":.5,"muted":false})
 var result=await track_case("core-audio-three-genuine-evolutions",36)
 check(result.played.get("hunter_evolve",0)==3,"three genuine kills each outputdistinct evolutioncue")
 check(game.audio_system.pending_evolutions.is_empty() and game.audio_system.pending_deaths.is_empty(),"actual death/evolutionqueue drains")
 await capture("three-evolutions-audio-end-720")
func breach_audio():
 var m=boss_fixture();var h=m.hunter;var victim=1;var r=m.rooms[victim]
 h.boss_policy.enabled=false;h.target=victim;h.state=HunterState.State.ATTACK;h.position=r.door_approach();h.cooldown=60;h.tactical_cooldown=60;r.rescue_used=true
 var before=game.audio_system.event_counts.duplicate(true);pcm_begin()
 check(m.apply_room_damage(victim,r.max_hp()*100,"controlled legal breach",1)>0 and r.door_hp<=0,"actual legalstrike destroys NPCdoor")
 h.state=HunterState.State.BREACH
 await live(16);pcm_end("core-audio-real-breach-death-evolve-laugh")
 var played=event_diff(before);check(not r.alive,"actualHunter breach navigation reaches/elim resident")
 check(played.get("hunter_evolve",0)==1 and played.get("hunter_laugh",0)>0,"actual breach outputs evolution and queuedlaugh")
 check(game.audio_system.pending_laughs.is_empty() and game.audio_system.pending_deaths.is_empty() and game.audio_system.pending_evolutions.is_empty(),"breach reaction queues drain")
 audio_results.append({"label":"actual legaldoorbreak/breachwalk/death/evolution/laugh","played":played,"diagnostics":game.audio_system.get_diagnostics(),"actual_dead":not r.alive,"final_Hunter_position":h.position})
 await capture("audio-real-breach-after-reactions-720")
func boss_audio():
 var m=boss_fixture();var h=m.hunter;game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":.5,"muted":false})
 pcm_begin();h.hurt(h.hp-h.max_hp*.54);await live(2.8);pcm_end("core-audio-eligible-transformation");check(h.transformed and h.state!=HunterState.State.TRANSFORM,"real eligibletransformation audio flow")
 m.wrath.recovery=100;h.cooldown=60
 for id in ["assault","scythe_slash","rules_judgement","soul_reaper","phantom_scream"]:
  m.wrath.clear(m);m.wrath.recovery=100;h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=60
  if id in ["soul_reaper","phantom_scream"] and m.wrath.phase<2:h.hurt(h.hp-h.max_hp*.34);await live(.2);m.wrath.recovery=100
  check(m.wrath.begin(id,m,0),"validated actual audiblecast "+id)
  var result=await track_case("core-audio-boss-"+id,ReaperWrath.ABILITIES[id].warning+(4.0 if id=="assault" else 1.2))
  check(m.wrath.counts.get(id,0)>0 and result.played.get("wrath_activate_"+id,0)>0,"real activation cues "+id)
  await capture("audio-"+id+"-720")
 m.wrath.clear(m);m.wrath.recovery=100;h.cooldown=60
 pcm_begin();h.hurt(h.hp-h.max_hp*.09);await live(9);pcm_end("core-audio-crimson-real-threshold-transition")
 check(m.wrath.domain_active() and game.audio_system.get_diagnostics().domain_music and game.audio_system.loop_weights.music_crimson>.5,"actual10pct threshold domain enters8thscore")
 audio_results.append({"label":"actual threshold/domain transition","diagnostics":game.audio_system.get_diagnostics(),"actual_room":m.wrath.domain_room,"remaining":m.wrath.domain_remaining})
 await capture("audio-crimson-active-720")
 game.return_menu();game.set_process(false);var result=await track_case("core-audio-domain-to-menu-cleanup",2)
 check(not game.audio_system.get_diagnostics().domain_music and not game.audio_system.voices.any(func(v):return v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"").begins_with("wrath_warning_")),"actual Menu clearsbattlewarnings/domainidentity")
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";root.size=Vector2i(1280,720);await setup_game()
 var args=OS.get_cmdline_user_args();var mode=args[0] if args.size()>0 else "weapons"
 if mode=="weapons":await weapons()
 elif mode=="evolution":await evolution_audio()
 elif mode=="boss":await boss_audio()
 elif mode=="breach":await breach_audio()
 var f=FileAccess.open(final_audio_path+"core-final-audio-"+mode+"-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":audio_results,"fixture":"Actual real-timeGame._process/model/projectile/input/output. WeaponPractice paidtemporarybudget. Boss/evolutioncontrolledprivateStage3Hell room/time/damage/contact fixtures, not naturalreachability/balance; sourceevent routing real. LinuxDummyhardware; actual internalMasterPCM. NativeWindows/humanauditionUNVERIFIED."}," "))
 print("PHASE5D4_FINAL_AUDIO_",mode.to_upper(),"_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
