extends "res://tools/capture_replay.gd"
# Release audit, isolated prepared profiles; no natural-play claim.
func run():
 phase=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "baseline"
 output="res://docs/evidence/phase6/render-screens/"
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase6-render-"+phase+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 game.profile.next_match_id=2;game.profile.xp=3800;game.profile.rm_cash=200
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.item_loadout=["barricade","time_freeze"];game.profile.equipped=["dreamer","first_aid"];game.profile.save_profile()
 if phase=="warning":
  phase="current";await warnings();return
 if phase=="dense":
  phase="current";await dense();return
 if phase=="detail":
  phase="current";await details();return
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();await capture("menu-"+suffix)
  game.ui.campaign.show_stages();await capture("stages-"+suffix)
  game.ui.campaign.prepare("stage_2")
  for difficulty in ["standard","hard","hell"]:
   game.ui.progression.difficulty=difficulty;game.ui.progression.show_loadout();await capture("loadout-"+difficulty+"-"+suffix)
  game.ui.shop.show_shop();await capture("shop-"+suffix)
  for i in range(3):game.ui.items_ui.inventory_page=i;game.ui.items_ui.inventory();await capture("inventory-"+str(i)+"-"+suffix)
  game.ui.progression.show_ranks();await capture("ranks-"+suffix)
  for i in range(2):game.ui.progression.achievement_page=i;game.ui.progression.show_achievements();await capture("achievements-"+str(i)+"-"+suffix)
  game.ui.replay_ui.show_endless();await capture("endless-"+suffix)
  game.ui.replay_ui.show_codes();await click(find_button("Generate code"));await capture("codes-"+suffix)
  game.ui.replay_ui.show_practice();await capture("practice-setup-"+suffix)
  game.ui.replay_ui.show_cosmetics();await capture("cosmetics-"+suffix)
  for stage in StageCatalog.STAGES:
   var m=fixture(stage.id);m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.player().door_hp=m.player().max_hp()*.4
   await advance(.15);await capture("siege-"+m.map_id+"-"+suffix)
   game.full_map=true;game.focus_camera(true);game.presentation.environment.update(8,m,false);await advance(.1);await capture("map-"+m.map_id+"-"+suffix)
  var m=fixture();m.player().occupied_seconds=100;m.player().damage_dealt=2000;m.hunter.hp=0;m.tick(.01);game._process(.01);await advance(1.6);await capture("result-"+suffix)
  check(not game.profile.pending_spins.is_empty(),"saved eligible victory spin")
  game.ui.items_ui.spin();await capture("spin-"+suffix);game.profile.claim_spin(game.match_id);game.return_menu()
 await benchmark("720-normal",Vector2i(1280,720),false)
 await benchmark("1080-normal",Vector2i(1920,1080),false)
 await benchmark("720-reduced",Vector2i(1280,720),true)
 var file=FileAccess.open("res://docs/evidence/phase6/render-performance-"+phase+".json",FileAccess.WRITE);file.store_string(JSON.stringify(perf," "))
 # Actual real-time Reaper combat master-bus capture; temporary wallet only.
 game.start_practice("crusher",true,["inferno","overdrive"]);game.set_process(false)
 recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 await live_frames(4);check(game.activate_item(0),"actual temporary Inferno activation")
 await live_frames(1.2);check(game.activate_item(1),"actual temporary Overdrive activation")
 await live_frames(7)
 await capture("real-practice-reaper-audio")
 recording.set_recording_active(false);var wav=recording.get_recording();check(wav!=null and wav.data.size()>1000,"real Master-bus PCM")
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path("res://docs/evidence/phase6/render-audio-"+phase+".wav"))==OK,"save PCM")
 var d=game.audio_system.get_diagnostics();print("PHASE6_AUDIO ",JSON.stringify(d))
 var out=FileAccess.open("res://docs/evidence/phase6/render-audio-"+phase+".json",FileAccess.WRITE);out.store_string(JSON.stringify(d," "))
 print("PHASE6_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)

func details():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for rank in [0,5,6]:
   game.return_menu();game.profile.xp=RankCatalog.THRESHOLDS[rank];game.profile.highest_rank=rank
   game.ui.progression.show_ranks();await process_frame
   var text=visible_text(game.ui.panel);var slots=game.profile.perk_slots()
   check(text.contains("PERMANENT PERKS · %d slot%s" % [slots,"" if slots==1 else "s"]),"actual perk slot label "+str(rank)+" / "+suffix)
   await capture("rank-"+str(rank)+"-"+suffix)
  game.profile.xp=3800;game.profile.highest_rank=5
  var m=fixture("stage_5");m.hunter.boss_policy.enabled=true;m.time=m.preparation+float(m.hunter.boss_policy.deadline)+1;m.hunter.hp=m.hunter.max_hp*.5
  m.hunter.position=m.player().door_approach();m.hunter.target=0;update_model(.01);await advance_model(.6)
  check(m.hunter.transformed and m.hunter.state==HunterState.State.TRANSFORM,"actual transformation animation")
  await capture("reaper-transform-"+suffix)
  await advance_model(BossCatalog.TRANSFORM_SECONDS)
  m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
  update_model(.01);await advance(.1);check(m.hunter.boss_attack!="","actual attack telegraph")
  await capture("reaper-windup-"+suffix);await advance_model(2)
  await capture("reaper-impact-"+suffix)
  m=fixture();var npc=m.rooms[1];npc.door_hp=1
  m.hunter.target=1;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=npc.door_approach();m.hunter.cooldown=0;m.hunter.tick(.01,m)
  for i in range(500):
   if not npc.alive:break
   m.hunter.tick(.05,m)
  check(not npc.alive,"actual bed contact elimination")
  game.full_map=true;game.focus_camera(true);await advance(.25);await capture("survivor-collapse-"+suffix)
  await advance(1.2);await capture("survivor-remains-"+suffix)
  game.onboarding.show_opening();game.onboarding.elapsed=6;game.onboarding.queue_redraw();await capture("opening-"+suffix)
  game.onboarding.show_title();game.onboarding.elapsed=2;game.onboarding.queue_redraw();await capture("creator-title-"+suffix);game.onboarding.skip()
 await benchmark("720-normal",Vector2i(1280,720),false)
 await benchmark("1080-normal",Vector2i(1920,1080),false)
 await benchmark("720-reduced",Vector2i(1280,720),true)
 var fp=FileAccess.open("res://docs/evidence/phase6/render-performance-current.json",FileAccess.WRITE);fp.store_string(JSON.stringify(perf," "))
 # Bounded live rendered combat and mode transition soak; no injected currency claim.
 root.size=Vector2i(1280,720);game.start_practice("crusher",true,["inferno","overdrive"]);game.set_process(false)
 var samples=[];var start=Time.get_ticks_usec();var previous=start
 var first={"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"audio_children":game.audio_system.get_child_count()}
 while Time.get_ticks_usec()-start<30000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now;game._process(delta)
  if samples.size()<int((now-start)/5000000.0):samples.append({"seconds":(now-start)/1000000.0,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"audio_children":game.audio_system.get_child_count(),"projectiles":game.model.projectiles.size(),"damage_records":game.model.combat_events.size(),"presentation_records":game.model.presentation_events.size()})
 await capture("rendered-soak-final")
 var children=game.audio_system.get_child_count()
 for i in range(12):
  game.return_menu();game.ui.replay_ui.show_hub();game.start_practice("crusher",i%2==0,["shield","repair"]);game.set_process(false);await live_frames(.1)
 check(game.audio_system.get_child_count()==children,"audio pool remains bounded after12 actual mode resets")
 check(game.audio_system.get_diagnostics().missing_assets.is_empty(),"no missing routed audio")
 var sf=FileAccess.open("res://docs/evidence/phase6/render-soak.json",FileAccess.WRITE);sf.store_string(JSON.stringify({"conditions":"30 seconds real wall-time Linux llvmpipe Practice Reaper plus12 mode resets, not long-session Windows performance","initial":first,"samples":samples,"audio_after":game.audio_system.get_diagnostics()}," "))
 print("PHASE6_DETAIL_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)

func dense():
 root.size=Vector2i(1280,720);game.start_practice("crusher",true,["overdrive","inferno"],"cursed_mansion");game.set_process(false)
 var m=game.model;var r=m.player();r.gold=500000;r.electricity=500000
 # Deliberately prepared finite stress funds/target HP, never affordability evidence.
 for i in range(10):
  if r.bed_level<Catalog.BED_COST.size():check(r.upgrade_bed(),"paid stress bed upgrade")
  if r.door_level<Catalog.DOOR_COST.size():check(r.upgrade_door(),"paid stress door upgrade")
 for tile in range(r.tile_count()):
  if not r.buildings.has(tile):check(r.build("turret" if tile%2==0 else "heavy",tile),"paid stress weapon")
  while r.buildings[tile].level<10:
   var b=r.buildings[tile]
   check(r.specialize_building(tile,StrategyCatalog.branches(b.kind)[tile%2]) if b.level==4 else r.upgrade_building(tile),"paid stress branch upgrade")
 m.hunter.hp=1000000000;m.hunter.max_hp=1000000000;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK
 await live_frames(.2);check(game.activate_item(0),"real dense Overdrive");await live_frames(1.2);check(game.activate_item(1),"real dense Inferno")
 await capture("dense-normal-start")
 var rows=[];var start=Time.get_ticks_usec();var previous=start;var frames=[];var peak_projectiles=0;var peak_objects=0
 while Time.get_ticks_usec()-start<60000000:
  await process_frame;var now=Time.get_ticks_usec();var ms=(now-previous)/1000.0;previous=now;frames.append(ms);game._process(minf(.1,ms/1000.0));peak_projectiles=maxi(peak_projectiles,m.projectiles.size());peak_objects=maxi(peak_objects,int(Performance.get_monitor(Performance.OBJECT_COUNT)))
  if now-start>30000000:game.profile.settings.reduced_effects=true
  if rows.size()<int((now-start)/10000000.0):rows.append({"seconds":(now-start)/1000000.0,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"audio_children":game.audio_system.get_child_count(),"projectiles":m.projectiles.size(),"combat_records":m.combat_events.size(),"presentation_records":m.presentation_events.size(),"shots":m.shots})
 check(m.shots>100,"actual high frequency stress firing")
 check(r.buildings.size()==16 and r.buildings.values().all(func(b):return b.level==10),"sixteen genuinely paid max-level fixture weapons retained")
 await capture("dense-reduced-final")
 frames.sort();var sum=0.0
 for ms in frames:sum+=ms
 var out={"conditions":"60 real seconds Linux llvmpipe720p,16 paid L10 weapons; explicitly injected finite500kG/500kE and1e9 target HP for stress only. First30s normal, then ReducedEffects. Not economy/natural survival or Windows FPS proof.","frames":frames.size(),"mean_frame_ms":sum/maxi(1,frames.size()),"p95_frame_ms":frames[int((frames.size()-1)*.95)],"peak_projectiles":peak_projectiles,"peak_objects":peak_objects,"samples":rows,"audio":game.audio_system.get_diagnostics()}
 var f=FileAccess.open("res://docs/evidence/phase6/render-dense.json",FileAccess.WRITE);f.store_string(JSON.stringify(out," "))
 print("PHASE6_DENSE_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)

func warnings():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for reduced in [false,true]:
   game.profile.settings.reduced_effects=reduced
   var m=fixture("stage_5");m.hunter.boss_policy.enabled=true;m.time=m.preparation+float(m.hunter.boss_policy.deadline)+1;m.hunter.hp=m.hunter.max_hp*.5;m.hunter.position=m.player().door_approach();m.hunter.target=0
   update_model(.01);await advance_model(.6)
   check(game.horror.boss_banner>0 and game.horror.last_model==m and m.hunter.boss_attack=="","actual awakening remains before attack")
   if not reduced:await capture("awakening-retained-"+suffix)
   await advance_model(BossCatalog.TRANSFORM_SECONDS)
   m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
   update_model(.01);await advance(.1)
   check(m.hunter.boss_attack!="" and game.horror.boss_banner>0 and game.horror.last_model==m,"actual overlapping timers reach priority draw guard")
   check(game.ui.warning_label.visible and game.ui.warning_label.text.contains("REPAIR NOW"),"real counterplay warning remains visible")
   await capture("reaper-windup-"+suffix+("-reduced" if reduced else ""))
 print("PHASE6_WARNING_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
