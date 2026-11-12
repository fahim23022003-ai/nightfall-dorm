extends "res://tools/capture_phase5d4_core.gd"
var recorder
var phases=[]
var spawn_next=0.0
var output_dir="res://docs/evidence/phase5d4/"
func record_begin():
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
func record_end(label):
 recorder.set_recording_active(false);var wav=recorder.get_recording();check(wav!=null and wav.data.size()>1000,"actual MasterPCM "+label)
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path(output_dir+label+".wav"))==OK,"save actual MasterPCM "+label)
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1);recorder=null
func row(label):
 var m=game.model
 return {"label":label,"time":m.time,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"minions":m.minions.size(),"projectiles":m.projectiles.size(),"combat_events":m.combat_events.size(),"presentation_events":m.presentation_events.size(),"visual_events":game.presentation.visual_events.size(),"floating":game.floating.size(),"routes":m._navigation_routes.size(),"audio":game.audio_system.get_diagnostics()}
func maintain_density():
 var m=game.model
 # Endurance fixture suppresses random percent-HP Wrath casts, retaining real assault/minion/nav/projectile/audio systems.
 m.wrath.recovery=1e9
 for u in m.minions:
  if u.max_hp<100000:u.max_hp=100000;u.hp=100000
 if m.time>=spawn_next and m.minions.is_empty() and not m.wrath.active():
  if m.wrath.begin("assault",m,m.player_room):spawn_next=m.time+64
func realtime(seconds,label,dense=false):
 var begin=Time.get_ticks_usec();var previous=begin;var elapsed=[];var before=game.audio_system.event_counts.duplicate(true)
 record_begin()
 while Time.get_ticks_usec()-begin<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now;elapsed.append(delta*1000)
  if dense:maintain_density()
  game._process(delta)
 record_end(label);elapsed.sort()
 var sum=0.0
 for ms in elapsed:sum+=ms
 var detail=row(label);detail.wall_seconds=(Time.get_ticks_usec()-begin)/1000000.0;detail.frames=elapsed.size();detail.mean_frame_ms=sum/maxi(1,elapsed.size());detail.p95_frame_ms=elapsed[int((elapsed.size()-1)*.95)];detail.events={}
 for id in game.audio_system.event_counts:
  var count=int(game.audio_system.event_counts[id])-int(before.get(id,0))
  if count>0:detail.events[id]=count
 phases.append(detail)
func effect_fixture():
 var m=prepared("underground_lab");var r=m.player();var tiles=range(r.tile_count());tiles.sort_custom(func(a,b):return r.tile_position(a).distance_squared_to(r.door_approach())<r.tile_position(b).distance_squared_to(r.door_approach()))
 var used=[]
 for tile in tiles:
  if not r.buildings.has(tile):used.append(tile)
 var index=0
 for kind in DefenseEffects.SPECIAL:
  var tile=used[index];index+=1;check(r.build(kind,tile),"paid temporary effect fixture "+kind)
  for level in range(3):check(r.upgrade_building(tile),"paid effect level4 "+kind)
  check(r.specialize_building(tile,StrategyCatalog.branches(kind)[0]),"paid real effect specialization "+kind)
 r.door_hp=r.max_hp()*.6;m.hunter.state=HunterState.State.MOVE;m.hunter.position=r.corridor_anchor();m.hunter.target=0;m.hunter.cooldown=30;m.hunter.tactical_cooldown=30;m.hunter.boss_policy.enabled=false
 game.focus_camera(true);game.audio_system.reset_match(m);return m
func dense_fixture():
 game.return_menu();game.start_practice("crusher",true,["shield","repair"],"underground_lab");game.set_process(false);game.tutorial_enabled=false
 var m=game.model;m.bot_claimed=5
 for i in range(6):
  var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position();r.bot_timer=1e9;r.gold=1e6;r.electricity=1e6;r.bed_level=9;r.door_level=9;r.bed_branch="lucid";r.door_branch="bulwark";r.door_multiplier=100;r.door_hp=r.max_hp()*.8;r.buildings.clear()
  var slots=range(r.tile_count());slots.sort_custom(func(a,b):return r.tile_position(a).distance_squared_to(r.door_approach())<r.tile_position(b).distance_squared_to(r.door_approach()))
  var slot_index=0
  for kind in ["shock","flame","frost","turret","heavy","generator","repair","economy","enhancer","auto_repair","shield","decoy"]:
   var slot=slots[slot_index]
   check(r.build(kind,slot),"paid dense fixture "+kind)
   for level in range(1,10):check(r.specialize_building(slot,StrategyCatalog.branches(kind)[1 if kind=="turret" else 0]) if level==4 else r.upgrade_building(slot),"paid dense upgrade")
   slot_index+=1
 var h=m.hunter;h.max_hp=1e8;h.hp=1e8;h.transformed=true;h.state=HunterState.State.ATTACK;h.position=m.player().door_approach();h.target=0;h.cooldown=3;h.tactical_cooldown=1e9
 m.wrath.recovery=1e9;m.wrath.phase=1;spawn_next=m.time+64;check(m.wrath.begin("assault",m,0),"actual dense ten-agent cast begins")
 game.audio_system.reset_match(m);game.audio_system.set_mix({"music":1.0,"effects":1.0,"ambient":.5,"muted":false});game.focus_camera(true)
 return m
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";root.size=Vector2i(1280,720);await setup_game();var profile_bytes=FileAccess.get_file_as_bytes(game.profile.path)
 var m=effect_fixture();game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":.5,"muted":false})
 # Actual real-time producer/FX observation before artificial stress HP/resources.
 record_begin();var begin=Time.get_ticks_usec();var previous=begin
 while Time.get_ticks_usec()-begin<1600000:
  await process_frame;var now=Time.get_ticks_usec();game._process(minf(.1,(now-previous)/1000000.0));previous=now
 record_end("core-effects-default-master")
 var status={"burns":m.defenses.burns.duplicate(true),"slow_seconds":m.hunter.suppression_remaining,"slow_strength":m.hunter.suppression_strength,"barrier_hp":m.player().barrier_hp,"barrier_seconds":m.player().barrier_remaining,"lure_seconds":m.defenses.lure_remaining,"door_hp":m.player().door_hp,"events":m.presentation_events.duplicate(true)}
 await capture("six-defenses-actually-active-720");phases.append({"label":"real six-defense activation","status":status})
 m=dense_fixture();await realtime(8,"core-dense-maxmix-start",true);await capture("dense-ten-undead-many-turrets-720")
 var start=m.time;var start_wall=Time.get_ticks_usec();var next_sample=start;var deadline=start_wall+180000000
 while m.time<start+600 and Time.get_ticks_usec()<deadline and game.mode=="match":
  for step in range(8):maintain_density();game._process(.05)
  if m.time>=next_sample:perf.append(row("accelerated600s"));next_sample+=30
  await process_frame
 check(m.time>=start+600 and game.mode=="match","actual Game._process survives600simulatedseconds")
 phases.append({"label":"accelerated session","simulated_seconds":m.time-start,"wall_seconds":(Time.get_ticks_usec()-start_wall)/1000000.0,"steps_per_frame":8,"step_seconds":.05})
 await realtime(8,"core-dense-maxmix-end",true);await capture("dense-after600simulated-seconds-720")
 var ending=row("end");perf.append(ending)
 check(m.minions.size()<=10 and m.projectiles.size()<=256 and m.combat_events.size()<=96 and m.presentation_events.size()<=128 and game.presentation.visual_events.size()<=80,"final bounded pools")
 check(FileAccess.get_file_as_bytes(game.profile.path)==profile_bytes,"stress Practice leaves permanentprofile bytes unchanged")
 var f=FileAccess.open(output_dir+"core-dense-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"phases":phases,"samples":perf,"fixture":"FirstsixeffectsactualpaidPracticebudget. Densefixture:72actualpaidL10machines/30weapons across6rooms; deliberately1milliontemporaryG/Eperroom,100xdoorHP,100millionHunterHP,100kminionHP for sustained non-balance stress. Actualassaultwarnings create up10realnav/attackableminions;55slifetimes+cooldownrespawn. Random percent-max-HP Wrath casts suppressed eachstep to isolate endurance; their fullactualcombat tested separately. Real-time8s Master maxmix before/after accelerated600simseconds; accelerated frame timings are NOT real-time gameplay FPS.","environment":"Linux Godot4.6.3 Xorg/Mesa Dummyhardware; actual internalMasterPCM. CPUquiet agreed root/A/C.","windows":"UNVERIFIED","human_sound_quality":"UNVERIFIED"}," "))
 print("PHASE5D4_DENSE_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
