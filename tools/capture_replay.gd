extends "res://tools/capture_visual_overhaul.gd"
# Isolated prepared production states; no natural-match or human-quality claim.
const REPLAY_BASELINE="d16a82da5baccdf5bcbe566635ee949c086c7a32"
func capture(name):
 if game.mode=="match" and game.ui.current_screen=="match":
  game.ui.items_ui.update(0);game.ui.update_match()
 await super.capture(name)
func click(button,double_click=false):
 var ready=button!=null and button.is_visible_in_tree() and not button.disabled
 check(ready,"real visible enabled control")
 if ready:await super.click(button,double_click)
func finish_render():
 print("REPLAY_RENDER_CHECKS=",checks," FAILURES=",failures," BASELINE=",REPLAY_BASELINE)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
func ui_review():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();await advance(.15);await capture("01-menu-"+suffix)
  await click(find_button("Endless Siege"));check(game.ui.current_screen=="endless_setup","actual skull action opens Endless setup")
  await capture("extra-endless-setup-"+suffix)
  game.ui.replay_ui.show_hub();await capture("extra-replay-hub-"+suffix)
  await click(find_button("Open Challenge Codes"));await capture("extra-codes-input-"+suffix)
  await click(find_button("Generate code"));await capture("extra-code-generated-"+suffix)
  var code=game.ui.replay_ui.code_text;check(ChallengeCode.decode(code).ok,"actual generator produces supported code")
  await click(find_button("Copy code"));await advance(.1)
  check(DisplayServer.clipboard_get()==code,"actual code clipboard copy")
  await capture("extra-code-copied-"+suffix)
  game.ui.replay_ui.code_text="NF2-not-valid";game.ui.replay_ui.show_codes()
  await click(find_button("Start coded challenge"));await capture("extra-code-rejected-"+suffix)
  check(game.ui.current_screen=="challenge_codes" and game.ui.replay_ui.notice.contains("Malformed"),"invalid code keeps valid UI with explanation")
  game.ui.replay_ui.show_practice();await capture("extra-practice-setup-"+suffix)
  game.ui.replay_ui.show_cosmetics();await capture("extra-cosmetic-gallery-locked-"+suffix)
  game.ui.replay_ui.show_hub()
func load_earned(name: String,suffix: String):
 game.return_menu()
 var source="res://docs/evidence/replay/render-earned-"+name+"-profile.json"
 var target="user://replay-render-earned-"+name+"-"+suffix+"-"+str(Time.get_ticks_usec())+".json"
 check(DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target))==OK,"copy authentic earned profile")
 var p=PlayerProfile.new(target);check(p.load_profile(),"load copied earned profile")
 # A's headless run did not exercise onboarding. Only graduate the GUI copy;
 # the earned model/economy/checkpoint and canonical evidence remain untouched.
 if not p.tutorial_completed:
  p.tutorial_completed=true;check(p.save_profile(),"graduate isolated GUI copy only")
 game.profile=p
 check(game.resume_endless(),"actual Game resume of earned checkpoint")
 game.set_process(false);await process_frame
 return game.model
func live_frames(seconds: float):
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec();var delta=minf(.1,(now-previous)/1000000.0);previous=now
  game._process(delta)
func transition_audio_review():
 var m=await load_earned("needle","audio");await click(find_button("Continue · Salvage"))
 # Controlled real combat finale on a GUI copy, not natural balance evidence.
 # Actual damage and breach routines generate presentation events; none are fabricated.
 var h=m.hunter;var npc=m.rooms[0 if m.player_room!=0 else 1]
 h.boss_policy.enabled=false;h.transformed=false;h.target=npc.index;h.state=HunterState.State.ATTACK
 m.time=m.preparation+.1
 npc.owner=1;npc.alive=true;npc.sleeping=true;npc.closed=true;npc.rescue_used=true;npc.door_hp=1
 h.position=npc.door_approach();h._damage_door(npc,m,2)
 h.state=HunterState.State.BREACH;h.position=npc.bed_position();h.tick(.01,m)
 check(not npc.alive and m.presentation_events.any(func(e):return e.type=="elimination" and e.room==npc.index),"actual breach produces NPC elimination event")
 game.audio_system.update_state(.01,m,"match")
 var active=[]
 for v in game.audio_system.voices:
  if v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"").begins_with("death_scream"):active.append(v)
 check(not active.is_empty(),"genuine elimination begins actual death audio")
 var pending_before=game.audio_system.pending_laughs.size()+game.audio_system.pending_deaths.size()
 h.hurt(h.hp*100+100);m.tick(.01);game._process(.01);await process_frame
 print("REPLAY_AUDIO_FINALE hp=",h.hp," state=",h.state," result=",m.result," phase=",m.endless.phase," ui=",game.ui.current_screen)
 check(m.endless.phase=="intermission","real controlled Hunter defeat reaches wave intermission")
 print("REPLAY_AUDIO_BEFORE_CONTINUE active=",active.size()," pending=",pending_before," positions=",active.map(func(v):return v.get_playback_position()))
 await click(find_button("Continue · Salvage"))
 print("REPLAY_AUDIO_AFTER_CONTINUE playing=",active.map(func(v):return v.playing)," pending=",game.audio_system.pending_laughs.size()+game.audio_system.pending_deaths.size())
 var preserved=active.all(func(v):return v.playing)
 print("REPLAY_AUDIO_CONTINUE_PRESERVED=",preserved)
 check(preserved and game.audio_system.pending_laughs.size()+game.audio_system.pending_deaths.size()>=pending_before,"fresh encounter preserves actual final death/laugh sequence")
 await capture("detail-immediate-wave-transition")
 await live_frames(3.5)
 check(game.audio_system.pending_laughs.is_empty() and game.audio_system.pending_deaths.is_empty(),"preserved death/laugh sequence drains without stale queue")
func accelerated_until(test: Callable,max_steps: int=6000) -> int:
 var steps=0
 while not test.call() and game.model.result=="" and steps<max_steps:
  for i in range(20):
   game._process(1.0/30.0);steps+=1
   if test.call() or game.model.result!="":break
  await process_frame
 return steps
func visible_text(node):
 var out=""
 if node is Label and node.is_visible_in_tree():out+=node.text+"\n"
 for child in node.get_children():out+=visible_text(child)
 return out
func practice_review():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();var permanent=preload("res://tests/replay_test_support.gd").profile_signature(game.profile)
  var ru=game.ui.replay_ui;ru.practice_archetype="crusher";ru.practice_boss=false;ru.practice_items=["shield","repair"];ru.show_practice()
  await click(find_button("Begin Practice"));var m=game.model;var r=m.player();var wallet=game.item_wallet()
  check(m.run_kind=="practice" and not m.tutorial_mode and wallet!=game.profile,"dedicated real practice uses temporary wallet")
  check(r.buildings[m.practice_tile].level==4 and r.buildings[m.practice_tile].invested_gold>0,"practice begins with actually paid L4")
  game.ui.open_context();await capture("practice-paid-level4-"+suffix)
  await click(game.ui.actions.upgrade);await capture("practice-real-branch-selection-"+suffix)
  await click(game.ui.specialization_items[1]);check(r.buildings[m.practice_tile].get("specialization","")!="","actual paid branch selection in Practice")
  await click(game.ui.actions.sell);check(r.buildings.is_empty(),"temporary sale removes weapon for controlled damage observation")
  var steps=await accelerated_until(func():return r.door_damage_taken>0,3000)
  check(r.door_damage_taken>0 and m.hunter.attacks>0,"practice actual normal Hunter deals door damage")
  print("REPLAY_PRACTICE_DAMAGE steps=",steps," damage=",r.door_damage_taken," hunter_damage=",m.hunter.damage)
  await click(game.ui.items_ui.hotbar[1]);check(wallet.inventory.repair==4,"successful temporary Repair consumes one local stock")
  await capture("practice-real-combat-"+suffix)
  game.toggle_pause();await capture("practice-pause-reset-"+suffix)
  var previous=m;await click(find_button("Reset Practice"));m=game.model
  check(m!=previous and m.player().door_hp==m.player().max_hp() and game.item_wallet().inventory.repair==5,"actual Reset makes fresh local combat and stock")
  game.return_menu();check(preload("res://tests/replay_test_support.gd").profile_signature(game.profile)==permanent,"practice combat, item, sale, reset and exit preserve every permanent profile field")
  ru.practice_boss=true;ru.practice_items=["time_freeze","reaper_seal"];ru.show_practice();await click(find_button("Begin Practice"));m=game.model
  await accelerated_until(func():return m.hunter.transformed and m.hunter.state!=HunterState.State.TRANSFORM,600)
  check(m.hunter.transformed,"Practice real Reaper transformation completes")
  await capture("practice-reaper-"+suffix)
  await click(game.ui.items_ui.hotbar[0]);var after=game.item_wallet().inventory.time_freeze
  check(game.ui.items_ui.hotbar[1].disabled and not game.activate_item(1),"second temporary Legendary control disabled and action refused")
  check(after==4 and game.item_wallet().inventory.reaper_seal==5,"practice Legendary limit blocks second temporary Legendary")
  await capture("practice-legendary-limit-"+suffix)
  game.return_menu();check(preload("res://tests/replay_test_support.gd").profile_signature(game.profile)==permanent,"boss Practice leaves all permanent fields untouched")
  game.start_tutorial(true);check(game.tutorial_active and game.model.tutorial_mode,"original tutorial remains separate")
  await capture("practice-original-tutorial-preserved-"+suffix)
  await click(find_button("Exit practice",game.onboarding));check(not game.onboarding.active and not game.tutorial_active,"real original tutorial exit cleans its overlay")
func challenge_review():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);game.return_menu()
  var permanent=preload("res://tests/replay_test_support.gd").profile_signature(game.profile)
  var ru=game.ui.replay_ui
  ru.code_text=ChallengeCode.encode({"map":"abandoned_dorm","archetype":"stalker","difficulty":"standard","seed":742,"preset":1,"gear":1})
  ru.show_codes();await capture("challenge-pasted-normalized-rules-"+suffix)
  await click(find_button("Start coded challenge"));var m=game.model
  check(m.run_kind=="challenge" and m.rooms[0].gold==15 and (m.match_boosts.is_empty() or m.match_boosts==RankCatalog.bonuses([])),"pasted code starts actual normalized alternate preset")
  check(game.item_wallet().inventory.overdrive==2 and game.item_wallet().inventory.frost==2,"code controls real loaned gear")
  await capture("challenge-normalized-live-"+suffix)
  var steps=await accelerated_until(func():return m.result!="",15000)
  check(m.result=="defeat" and m.terminal_recorded and m.challenge_recorded,"actual exposed-survivor contact records local challenge defeat")
  print("REPLAY_CHALLENGE_TERMINAL steps=",steps," time=",m.time," result=",m.result," sealed=",m.terminal_recorded)
  var result_text=visible_text(game.ui.panel).to_lower()
  check(result_text.contains(MapCatalog.map(m.map_id).title.to_lower()) and result_text.contains(RankCatalog.DIFFICULTIES[m.difficulty].name.to_lower()) and result_text.contains(StrategyCatalog.ARCHETYPES[m.hunter.archetype].name.to_lower()) and (result_text.contains("ruleset 1") or result_text.contains("normalized rules 1")),"actual result explicitly shows map, mode, archetype and ruleset")
  await capture("challenge-actual-result-"+suffix)
  await click(find_button("Copy result summary"));check(DisplayServer.clipboard_get().contains(m.challenge_code) and DisplayServer.clipboard_get().contains("self-reported"),"actual result clipboard states code and local provenance")
  var copied=DisplayServer.clipboard_get().to_lower()
  check(copied.contains(MapCatalog.map(m.map_id).title.to_lower()) and copied.contains(RankCatalog.DIFFICULTIES[m.difficulty].name.to_lower()) and copied.contains(StrategyCatalog.ARCHETYPES[m.hunter.archetype].name.to_lower()) and copied.contains("ruleset 1"),"actual copied result explicitly includes map, mode, archetype and ruleset")
  await capture("challenge-result-copied-"+suffix)
  await click(find_button("Why did I lose?"));check(not m.defeat_facts.report.is_empty(),"real challenge contact produces factual analysis")
  await capture("challenge-factual-exposed-defeat-"+suffix)
  var current=preload("res://tests/replay_test_support.gd").profile_signature(game.profile)
  permanent.replay.challenge_best={};current.replay.challenge_best={}
  check(current==permanent,"challenge adds personal record without permanent rewards, inventory, pity or other field changes")
  game.return_menu()
func presentation_review():
 await load_earned("advanced","presentation");await click(find_button("End run here · keep earned records"))
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for boundary in ["epic","legendary"]:
   game.profile.replay.pity={"epic_dry":7,"legendary_dry":39 if boundary=="legendary" else 12};game.profile.save_profile()
   var m=fixture();var r=m.player();r.occupied_seconds=100;r.damage_dealt=2000
   # Prepared qualifying terminal, with actual transformation and combat seal.
   m.hunter._begin_transformation(m)
   for step in range(150):m.tick(1.0/30.0)
   check(m.hunter.transformed,"actual transformation precedes controlled campaign win")
   m.hunter.hurt(m.hunter.hp*100+100);m.tick(.01);game._process(.01)
   var receipt=game.profile.pending_spin();check(not receipt.is_empty(),"eligible actual settlement saves boundary receipt")
   if receipt.is_empty():continue
   var rarity=ItemCatalog.ITEMS[receipt.item].rarity
   check(rarity=="Legendary" if boundary=="legendary" else rarity in ["Epic","Legendary"],"guaranteed boundary delivers qualifying rarity")
   var saved_receipt=receipt.duplicate(true);var inventory=game.profile.inventory.duplicate(true)
   check(game.profile.load_profile() and preload("res://tests/replay_test_support.gd").numeric_same(game.profile.pending_spin(),saved_receipt) and preload("res://tests/replay_test_support.gd").numeric_same(game.profile.inventory,inventory),"saved pity receipt reload neither rerolls nor duplicates")
   game.ui.items_ui.spin();await advance(1.6);await capture("pity-"+boundary+"-guarantee-receipt-next-"+suffix)
   await click(find_button("Skip animation"));await advance(.15);await capture("pity-"+boundary+"-actual-reward-"+suffix)
   print("REPLAY_PITY ",boundary," ",suffix," actual=",receipt.odds," before=",receipt.pity_before," next=",game.profile.replay.pity," item=",receipt.item)
   check(not game.profile.claim_spin(game.match_id).is_empty(),"claim saved conditional draw")
  game.return_menu();game.ui.replay_ui.show_cosmetics()
  check(CosmeticCatalog.ITEMS.keys().all(func(id):return CosmeticCatalog.earned(game.profile,id)),"real controlled campaign win plus authentic wave20 unlock four appearances")
  for id in CosmeticCatalog.ITEMS:
   if game.profile.replay.cosmetics[CosmeticCatalog.ITEMS[id].slot]!=id:await click(find_button("Equip appearance"))
  await capture("cosmetics-four-equipped-gallery-"+suffix)
  game.ui.replay_ui.practice_items=["barricade","feather"];game.ui.replay_ui.practice_boss=false
  check(game.start_practice("crusher",false,["barricade","feather"]),"real cosmetic world Practice")
  var m=game.model;var r=m.player();var tile=m.practice_tile
  check(m.specialize_building(tile,"precision"),"actual temporary Needle branch purchase")
  for i in range(5):check(m.upgrade_building(tile),"temporary paid Needle prestige upgrade")
  var model_before=preload("res://tests/replay_test_support.gd").model_signature(m)
  for id in CosmeticCatalog.ITEMS:game.profile.equip_cosmetic(id)
  var model_after=preload("res://tests/replay_test_support.gd").model_signature(m)
  check(model_before==model_after,"equipping cosmetic shapes changes no live combat/economy/model stat")
  for id in CosmeticCatalog.ITEMS:game.profile.equip_cosmetic(id)
  game.full_map=false;game.focus_camera(true);game.selected_tile=tile;game.ui.open_context()
  r.door_hp=r.max_hp()*.28;await advance(.2)
  await capture("cosmetics-damaged-door-branch10-world-"+suffix)
  if resolution.y==720:
   game.profile.settings.reduced_effects=true;await advance(.2);await capture("cosmetics-damaged-door-branch10-reduced-720");game.profile.settings.reduced_effects=false
  game.return_menu()
func realtime_audio_review():
 root.size=Vector2i(1280,720);game.return_menu()
 var a=game.audio_system
 check(a.streams.size()==105,"105 actual loaded audio streams")
 var missing=[]
 for id in a.streams:
  if a.streams[id]==null or a.streams[id].get_length()<=0:missing.append(id)
 check(missing.is_empty(),"all loaded audio streams have playable nonzero length")
 var initial_voices=a.voices.size();var initial_children=a.get_child_count()
 for i in range(5):
  game.start_practice("crusher",i%2==0,["inferno","overdrive"]);game.return_menu();await process_frame
 check(a.voices.size()==initial_voices and a.get_child_count()==initial_children,"five actual temporary mode transitions do not accumulate audio nodes")
 var effect=AudioEffectRecord.new();AudioServer.add_bus_effect(0,effect);effect.set_recording_active(true)
 game.start_practice("crusher",true,["inferno","overdrive"])
 await live_frames(4.5)
 await click(game.ui.items_ui.hotbar[0]);await live_frames(1.2);await click(game.ui.items_ui.hotbar[1])
 check(game.item_wallet().inventory.inferno==4 and game.item_wallet().inventory.overdrive==4,"both temporary item activations genuinely succeed after shared cooldown")
 var peak_voices=0;var peak_pending=0;var start=Time.get_ticks_usec()
 while Time.get_ticks_usec()-start<12*1000000:
  await live_frames(.1)
  var d=a.get_diagnostics();peak_voices=maxi(peak_voices,int(d.voices));peak_pending=maxi(peak_pending,int(d.pending_critical))
 await capture("audio-real-time-reaper-combat-720")
 effect.set_recording_active(false);var wav=effect.get_recording()
 check(wav!=null and wav.data.size()>1000,"actual real-time mixer records samples")
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path("res://docs/evidence/replay/render-realtime-mix.wav"))==OK,"save actual real-time combat mixer")
 var data={"fixture":"Actual Practice Reaper, real wall-clock deltas; temporary Inferno + Overdrive activated through visible buttons.","peak_voices":peak_voices,"peak_pending":peak_pending,"children_before":initial_children,"children_after":a.get_child_count(),"diagnostics":a.get_diagnostics(),"stream_lengths_valid":missing.is_empty()}
 var file=FileAccess.open("res://docs/evidence/replay/render-audio-metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(data," "));file.close()
 print("REPLAY_REALTIME_AUDIO ",JSON.stringify(data));check(peak_voices<=16 and a.get_child_count()==initial_children,"real-time voice pool bounded with no accumulation")
func defeat_review():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.profile.item_loadout=["shield","repair"];game.profile.replay.pity={"epic_dry":6,"legendary_dry":18};game.profile.save_profile()
  var m=fixture();var r=m.player();r.occupied_seconds=100;r.gold=2500;r.electricity=100
  var stock={"shield":game.profile.inventory.shield,"repair":game.profile.inventory.repair};var h=m.hunter
  h.target=r.index;h.state=HunterState.State.ATTACK;h.position=r.door_approach()
  h._damage_door(r,m,50);check(m.repair_door(),"actual manual repair recorded before controlled final breach")
  h._damage_door(r,m,r.door_hp+100);h.state=HunterState.State.BREACH;h.position=r.bed_position();h.tick(.01,m)
  check(not r.alive,"actual Hunter breach contact eliminates occupied player")
  game._process(.01);await advance(1.6)
  check(m.result=="defeat" and not m.defeat_facts.report.is_empty(),"genuine controlled contact captures final facts")
  var facts=m.defeat_facts.report
  check(facts.unused==stock and facts.repairs==1 and facts.damage>=100 and facts.sequence.size()>=3,"factual door damage, repair, sequence and equipped stock agree before reward transaction")
  check(game.profile.replay.pity=={"epic_dry":6,"legendary_dry":18},"actual eligible Consolation does not advance or reset Victory pity")
  await capture("defeat-real-campaign-result-"+suffix)
  await click(find_button("Why did I lose?"));await capture("defeat-real-door-facts-before-reward-stock-"+suffix)
  game.ui.items_ui.spin();await advance(1.6);await capture("pity-consolation-unchanged-"+suffix)
  check(not game.profile.claim_spin(game.match_id).is_empty(),"actual eligible consolation receipt claim")
  game.return_menu()
func final_detail_review():
 await ui_review()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);game.return_menu();var button=find_button("Endless Siege")
  var point=root.get_final_transform()*button.get_global_rect().get_center()
  var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion);await process_frame
  await capture("detail-endless-distinct-hover-"+suffix)
  button.grab_focus();await process_frame;await capture("detail-endless-keyboard-focus-"+suffix)
  var press=InputEventMouseButton.new();press.position=point;press.global_position=point;press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;Input.parse_input_event(press);await process_frame
  await capture("detail-endless-distinct-pressed-"+suffix)
  press=InputEventMouseButton.new();press.position=point;press.global_position=point;press.button_index=MOUSE_BUTTON_LEFT;press.pressed=false;Input.parse_input_event(press);await process_frame
  check(game.ui.current_screen=="endless_setup","pressed skull action remains functional")
  await load_earned("advanced","final-"+suffix);await capture("detail-authentic-wave20-final-milestones-"+suffix)
  await click(find_button("Continue · Recharge"));await live_frames(.25)
  game.profile.settings.reduced_effects=true;await capture("detail-endless-wave21-reduced-"+suffix);game.profile.settings.reduced_effects=false
func early_review():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);game.return_menu();game.ui.replay_ui.show_endless()
  await click(find_button("New Endless run"));check(game.model.run_kind=="endless" and game.model.endless.wave==1 and game.model.endless.completed==0,"actual skull setup starts real first wave")
  await capture("endless-actual-new-run-wave1-"+suffix)
  # Walk a genuine navigation path, then use the same E input as Windows controls.
  var m=game.model;var target=m.rooms[0].bed_position()+Vector2(45,0);var path=m.player_navigation_path(m.player_position,target);var steps=0
  for waypoint in path:
   while m.player_position.distance_to(waypoint)>2 and steps<600:
    m.move_player((waypoint-m.player_position).normalized(),1.0/60);game._process(1.0/60);steps+=1
   await process_frame
  for i in range(2):
   for pressed in [true,false]:
    var event=InputEventKey.new();event.keycode=KEY_E;event.physical_keycode=KEY_E;event.pressed=pressed;Input.parse_input_event(event);await process_frame
  check(m.player()!=null and m.player().sleeping,"real first-wave navigation plus E claims and occupies bed")
  print("REPLAY_EARLY_WALK steps=",steps," path=",path," final=",m.player_position," target=",target," owner=",m.rooms[0].owner," time=",m.time)
  await live_frames(.5)
  await capture("endless-actual-wave1-occupied-"+suffix)
  game.return_menu();check(game.profile.forfeit_endless(),"actual first-wave run can explicitly forfeit")
func earned_review():
 var recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for name in ["needle","arc","advanced"]:
   var m=await load_earned(name,suffix);var r=m.player();var expected=20 if name=="advanced" else 4
   check(m.endless.completed==expected and m.endless.phase=="intermission","authentic earned wave checkpoint "+name)
   print("REPLAY_EARNED ",name," ",suffix," time=",m.time," income=",r.income_total," wave=",m.endless.completed," buildings=",JSON.stringify(r.buildings))
   await capture("earned-"+name+"-intermission-"+suffix)
   await click(find_button("Prepare defenses · frozen economy"));check(game.ui.current_screen=="match" and game.ui.replay_ui.preparing,"actual frozen preparation action")
   var before=Vector3(m.time,r.gold,r.electricity);await live_frames(.35)
   check(Vector3(m.time,r.gold,r.electricity)==before,"intermission has no passive time or income")
   await capture("earned-"+name+"-frozen-preparation-"+suffix)
   if name=="needle":
    var tile=-1
    for i in range(r.tile_count()):
     if not r.buildings.has(i):tile=i;break
    if tile<0:
     for i in r.buildings:
      if r.buildings[i].kind=="generator":tile=int(i);break
     game.selected_tile=tile;game.ui.open_context();await process_frame
     await click(game.ui.actions.sell)
    check(tile>=0 and not r.buildings.has(tile),"actual utility sale creates available build pad")
    game.selected_tile=tile;game.begin_placement("generator");await process_frame
    await click(game.ui.confirm_button);await process_frame
    check(r.buildings.has(tile) and r.buildings[tile].kind=="generator" and r.buildings[tile].invested_gold==30,"real frozen purchase records actual30G investment")
    var paid_gold=r.gold
    await capture("earned-needle-newest-paid-ledger-"+suffix)
    await click(find_button("Wave"));await click(find_button("Save & exit to menu"))
    check(game.mode=="menu","actual safe suspend returns menu")
    check(game.profile.load_profile() and game.resume_endless(),"reload actual newest saved checkpoint")
    m=game.model;r=m.player()
    check(r.buildings.has(tile) and r.buildings[tile].invested_gold==30 and is_equal_approx(r.gold,paid_gold),"new purchase ledger and current resources survive reload")
    await capture("earned-needle-reloaded-newest-ledger-"+suffix)
   else:
    await click(find_button("Wave"))
   var old_hunter=m.hunter
   await click(find_button("Continue · Salvage"))
   check(m.endless.wave==expected+1 and m.endless.phase=="combat" and m.hunter!=old_hunter,"one fresh encounter follows actual Continue")
   await capture("earned-"+name+"-next-wave-"+suffix)
   var captured_boss=false;var fired=false;var steps=0;var wave_limit=m.endless.wave+4
   while steps<9000 and m.result=="" and m.endless.wave<wave_limit and not fired:
    for i in range(20):
     game._process(1.0/30.0);steps+=1
     if m.hunter.transformed and m.hunter.state==HunterState.State.TRANSFORM and not captured_boss and m.hunter.transform_remaining<BossCatalog.TRANSFORM_SECONDS*.7:
      await capture("earned-"+name+"-reaper-milestone-"+suffix);captured_boss=true
     if m.combat_events.any(func(e):return e.get("type","") in ["launch","impact"] and e.get("room",-1)==m.player_room and int(e.get("level",0))==10):fired=true;break
     if m.result!="" or m.endless.phase=="intermission":break
    await process_frame
    if m.endless.phase=="intermission" and not fired:
     await click(find_button("Continue · Reinforce"))
   check(fired,"authentic earned Level10 weapon fires in actual combat "+name)
   print("REPLAY_EARNED_FIRING ",name," ",suffix," steps=",steps," wave=",m.endless.wave," actual_damage=",r.damage_dealt)
   game.ui.show_match();game.full_map=false;game.focus_camera(true)
   var selected=-1
   for tile in r.buildings:
    if int(r.buildings[tile].level)==10 and (name=="advanced" or r.buildings[tile].kind==("turret" if name=="needle" else "heavy")):selected=int(tile);break
   check(selected>=0,"earned selected Level10 remains")
   game.selected_tile=selected;game.ui.open_context();await capture("earned-"+name+"-level10-combat-"+suffix)
   game.return_menu();check(game.resume_endless(),"midwave return retains only prior safe intermission")
   await click(find_button("End run here · keep earned records"))
   check(game.mode=="result" and game.profile.active_match.is_empty() and game.profile.replay.checkpoint.is_empty(),"actual safe end differs from suspended run")
   await capture("earned-"+name+"-safe-end-"+suffix)
 recording.set_recording_active(false);var wav=recording.get_recording()
 check(wav!=null and wav.data.size()>1000,"record actual earned wave audio")
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path("res://docs/evidence/replay/render-earned-mix.wav"))==OK,"save actual earned mixer")
 print("REPLAY_AUDIO ",JSON.stringify(game.audio_system.get_diagnostics()))
func run():
 phase=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "before"
 output="res://docs/evidence/replay/render-screens/"
 if phase=="before" and FileAccess.file_exists(output+"before/01-menu-720.png"):
  push_error("Preserved replay baseline exists; refusing overwrite.");quit(1);return
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://replay-render-"+phase+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 game.profile.next_match_id=2;game.profile.xp=3800;game.profile.rm_cash=200
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.item_loadout=["barricade","time_freeze"];game.profile.equipped=["dreamer","first_aid"];game.profile.save_profile()
 if phase=="ui":
  phase="after";await ui_review();await finish_render();return
 if phase=="earned":
  phase="after";await earned_review();await finish_render();return
 if phase=="audio-transition":
  phase="after";await transition_audio_review();await finish_render();return
 if phase=="practice":
  phase="after";await practice_review();await finish_render();return
 if phase=="challenge":
  phase="after";await challenge_review();await finish_render();return
 if phase=="presentation":
  phase="after";await presentation_review();await finish_render();return
 if phase=="realtime-audio":
  phase="after";await realtime_audio_review();await finish_render();return
 if phase=="defeat":
  phase="after";await defeat_review();await finish_render();return
 if phase=="final-detail":
  phase="after";await final_detail_review();await finish_render();return
 if phase=="early":
  phase="after";await early_review();await finish_render();return
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();await advance(.15);await capture("01-menu-"+suffix)
  var m=fixture("stage_1");m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.player().door_hp=m.player().max_hp()*.4
  await advance(.2);game.ui.items_ui.update(0);game.ui.update_match();await capture("02-gameplay-"+suffix)
  m.player().occupied_seconds=100;m.player().damage_dealt=2000;m.hunter.hp=0;m.tick(.01)
  check(m.result=="victory" and m.strategy.verified(m,game.profile.active_match),"prepared terminal sealed through actual model")
  game._process(.01);await advance(1.6);check(not game.profile.pending_spins.is_empty(),"actual saved victory spin")
  game.ui.items_ui.spin();await capture("03-victory-spin-"+suffix)
  check(not game.profile.claim_spin(game.match_id).is_empty(),"claim actual saved spin");game.return_menu()
 print("REPLAY_RENDER_CHECKS=",checks," FAILURES=",failures," BASELINE=",REPLAY_BASELINE)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
