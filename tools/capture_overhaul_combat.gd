extends "res://tools/capture_phase5d4_core.gd"
var reports=[]
var pcm_recorder
func save_data(name,data):
 var f=FileAccess.open(output+phase+"/"+name+".json",FileAccess.WRITE);f.store_string(JSON.stringify(data," "))
func pcm_start():
 pcm_recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,pcm_recorder);pcm_recorder.set_recording_active(true)
func pcm_finish(name):
 pcm_recorder.set_recording_active(false);var wav=pcm_recorder.get_recording();check(wav!=null and wav.data.size()>1000,"actual Master signal "+name)
 if wav!=null:check(wav.save_to_wav(ProjectSettings.globalize_path(output+phase+"/"+name+".wav"))==OK,"actual PCM artifact")
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1);pcm_recorder=null
func live(seconds):
 var start=Time.get_ticks_usec();var last=start
 while Time.get_ticks_usec()-start<seconds*1e6:
  await process_frame;var now=Time.get_ticks_usec();game._process(minf(.05,(now-last)/1e6));last=now
func fixture_kind(kind):
 game.return_menu();check(game.start_practice(kind,false,["shield","repair"]),"actual Practice roster "+kind)
 game.set_process(false);game.tutorial_enabled=false
 var m=game.model;var h=m.hunter;var r=m.player()
 h.boss_policy.enabled=false;h.state=HunterState.State.ATTACK;h.target=r.index;h.position=r.door_approach();h.cooldown=60;h.tactical_cooldown=60;h.arcane.cooldown=60
 r.gold=500000;r.electricity=500000;r.door_hp=r.max_hp();m.wrath.recovery=100
 # Remove real Practice Needle by real sale, so states/casts stay isolated.
 if r.buildings.has(m.practice_tile):check(r.sell_building(m.practice_tile),"actual temporary Needle sale")
 game.ui.close_context();game.focus_camera(true);game.audio_system.reset_match(m);game.presentation.reset();game.ui.update_match()
 return m
func hunter_states():
 root.size=Vector2i(1280,720)
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var m=fixture_kind(kind);var h=m.hunter;var r=m.player()
  h.state=HunterState.State.DORMANT;await advance(.15);await capture(kind+"-idle-720")
  h.state=HunterState.State.MOVE;h.position=r.corridor_anchor();h.target=r.index;h.target_time=10
  await drive(.3);check(game.presentation.identity.velocity.length()>0,"actual legal movement "+kind);await capture(kind+"-move-720")
  h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0;h.tactical_cooldown=60;h.arcane.cooldown=60;h.archetype_primed=false;h.charged_ready=false
  var strikes=h.attacks;await drive(.9)
  check(h.attacks>strikes,"actual normal attack executes "+kind);await capture(kind+"-attack-720")
  check(m.apply_target_damage(1,30,r.index,{"type":"physical","element":"neutral"})>0,"actual projectile-route hit "+kind)
  game.presentation.update(.01,m);await capture(kind+"-hurt-720")
  h.hit_flash=0;h.apply_suppression(.15);game.presentation.update(.01,m);check(h.suppression_remaining>0,"actual defensive reaction "+kind);await capture(kind+"-defend-720")
  h.suppression_remaining=0;h.tactical_cooldown=60;h.arcane.cooldown=60
  if kind in ["crusher","stalker","ravager"]:
   h.state=HunterState.State.ATTACK if kind=="crusher" else HunterState.State.MOVE
   h.tactical_cooldown=0;check(h._tactics(.01,m),"actual tactical warning "+kind)
  else:
   h.state=HunterState.State.ATTACK;h.position=r.door_approach();h.arcane.cooldown=0;check(h.arcane.tick(h,m,.01),"actual magic warning "+kind)
  game.presentation.update(.01,m);await capture(kind+"-special-warning-720")
  h.arcane.action="";h.tactical_action="";h.boss_policy.enabled=false
  check(m.apply_target_damage(1,h.hp*2,r.index,{"type":"physical","element":"neutral"})>0 and h.state==HunterState.State.DEAD,"actual lethal hit "+kind)
  game.presentation.update(.05,m);await capture(kind+"-death-720")
  reports.append({"hunter":kind,"normal_attacks":h.attacks,"state":"actual movement/strike/hurt/suppression/warning/lethal hit routes; controlled state preconditions and wallets"})
 root.size=Vector2i(1920,1080)
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var m=fixture_kind(kind);await advance(.1);await capture(kind+"-identity-1080")
func magic_buildings():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for kind in MagicDefense.KINDS:
   for choice in range(2):
    var m=fixture_kind("witch");var r=m.player()
    await world_click(r.tile_position(0));await advance(.35)
    check(game.ui.build_items.size()==75,"all fifteen illustrated cards registered")
    if kind=="barrier" and choice==0:await capture("fifteen-card-palette-"+suffix)
    var gold=r.gold;var power=r.electricity;await click(game.ui.actions["build:"+kind]);await advance(.1)
    check(r.buildings.has(0) and r.buildings[0].kind==kind and r.gold<gold and r.electricity<power,"actual paid magic BUILD "+kind)
    if choice==0:await capture(kind+"-level1-"+suffix)
    for level in range(3):await click(game.ui.actions.upgrade);await advance(.06)
    check(r.buildings[0].level==4,"actual L4 "+kind)
    await click(game.ui.actions.upgrade);await advance(.12)
    check(game.ui.context_mode=="specialize","actual exclusive branch inspector "+kind)
    if choice==0:await capture(kind+"-branch-preview-"+suffix)
    await click(game.ui.specialization_items[choice+1]);await advance(.05);await click(game.ui.branch_confirm);await advance(.08)
    check(r.buildings[0].specialization==StrategyCatalog.branches(kind)[choice],"real paid exclusive branch "+kind)
    for level in range(5):await click(game.ui.actions.upgrade);await advance(.06)
    check(r.buildings[0].level==10 and game.ui.actions.upgrade.disabled,"real L10 with max guard "+kind)
    await capture(kind+"-branch"+str(choice+1)+"-L10-"+suffix)
    game.ui.close_context();await advance(.3)
    var h=m.hunter;h.state=HunterState.State.ATTACK;h.position=r.door_approach();h.target=r.index
    if kind=="antenna":
     MagicDefense.tick(m,.01);var shield=r.magic_state.shield
     check(shield>0,"actual paid Antenna ward generated")
     var before=r.door_hp;m.apply_room_damage(r.index,20,"cursed_projectile",1,true,{"type":"magic","element":"ice"})
     check(r.magic_state.shield<shield and r.door_hp==before,"actual ward absorbs magic before door")
    elif kind=="plasma":
     m.apply_room_damage(r.index,150,"cursed_projectile",1,true,{"type":"magic","element":"ice"});check(r.magic_state.stored>0,"actual Plasma stores absorbed magic")
    else:
     var before=h.hp;m.apply_room_damage(r.index,150,"cursed_projectile",1,true,{"type":"magic","element":"ice"});check(h.hp<before and r.magic_state.reflect_cd>0,"actual Barrier reflection damages living attacker")
    game.presentation.update(.01,m);await capture(kind+"-real-magic-effect-branch"+str(choice+1)+"-"+suffix)
    if kind=="plasma":
     var before=r.door_hp;var stored=r.magic_state.stored;MagicDefense.tick(m,.1)
     check(r.door_hp>before and r.magic_state.stored<stored,"actual stored-energy release repairs")
     await capture(kind+"-energy-release-branch"+str(choice+1)+"-"+suffix)
    if choice==0:
     game.profile.settings.reduced_effects=true;await capture(kind+"-reduced-"+suffix);game.profile.settings.reduced_effects=false
func ability_case(kind,ability,transformed=false):
 var m=fixture_kind(kind);var h=m.hunter;var r=m.player()
 if transformed:
  h.transformed=true;m.wrath.phase=1;m.wrath.recovery=100;h.hp=h.max_hp*.5
 if ability=="shadow_dash":h.state=HunterState.State.MOVE;h.position=r.corridor_anchor()
 else:
  h.state=HunterState.State.ATTACK;h.position=r.door_approach()
  if ability=="cursed_projectile":
   h.position=r.door_approach()+r.door_normal()*65
   check(m.navigation_walkable(h.position) and m._visible(h.position,r.door_approach()),"legal ranged projectile position")
 h.arcane.cooldown=0;h.tactical_cooldown=60;h.cooldown=60
 game.audio_system.set_mix({"music":.5,"effects":.7,"ambient":.3,"muted":false})
 var played=game.audio_system.event_counts.duplicate(true);var hp=r.door_hp;var hunterhp=h.hp;var pos=h.position
 pcm_start();await live(.15)
 check(h.arcane.action==ability,"real timed ability warning "+ability);await capture(ability+"-warning-"+str(root.size.y))
 if ability=="cursed_projectile":
  var flight_started=Time.get_ticks_usec();var history=[]
  while h.arcane.bolt.is_empty() and r.door_hp==hp and Time.get_ticks_usec()-flight_started<3000000:
   history.append({"time":m.time,"warning":h.arcane.warning,"action":h.arcane.action,"position":str(h.position),"casts":h.arcane.casts.duplicate()});await live(.01)
  save_data("flight-history-"+str(root.size.y),history)
  check(not h.arcane.bolt.is_empty(),"actual ranged cursed bolt in flight");await capture(ability+"-projectile-flight-"+str(root.size.y));await live(.8)
 else:await live(1.6)
 check(h.arcane.casts.get(ability,0)>0,"real telegraph completes "+ability)
 if ability=="shadow_dash":check(h.position.distance_to(pos)>1,"actual ShadowDash follows navigation")
 else:check(r.door_hp<hp,"real magic door damage "+ability)
 if ability=="soul_drain":check(h.hp>hunterhp,"real bounded SoulDrain heal")
 if ability=="interference":check(r.magic_state.disrupt>0,"real short turret disruption")
 await capture(ability+"-active-"+str(root.size.y));await live(.7);pcm_finish("audio-"+ability+"-"+str(root.size.y))
 var diff={}
 for key in game.audio_system.event_counts:
  var count=game.audio_system.event_counts[key]-played.get(key,0)
  if count>0:diff[key]=count
 check(not diff.is_empty(),"actual ability audio producer events "+ability)
 reports.append({"ability":ability,"actual_audio_events":diff,"cast_count":h.arcane.casts.get(ability,0),"door_damage":hp-r.door_hp,"hunter_delta":h.hp-hunterhp})
func combat_info():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  var m=fixture_kind("witch");game.ui.close_context();await advance(.4)
  var tooltip=game.ui.hunter_label.tooltip_text
  check(tooltip.contains("Physical") and tooltip.contains("Magic") and tooltip.contains("+15%") and tooltip.contains("-10%"),"actual concise damage/element tooltip")
  var point=root.get_final_transform()*game.ui.hunter_label.get_global_rect().get_center()
  var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
  await advance(1.1);await capture("damage-element-tooltip-"+str(resolution.y))
  check(game.ui.hunter_label.tooltip_text.length()<1800,"tooltip remains bounded")
func earned_checkpoint():
 var source="res://docs/evidence/gameplay-overhaul/combat-render/earned-wave45-input.json"
 var original=FileAccess.get_sha256(source);var canonical=JSON.parse_string(FileAccess.get_file_as_string(source))
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;game.return_menu()
  var path="user://overhaul-earned-gui-"+str(Time.get_ticks_usec())+".json";var profile=PlayerProfile.new(path)
  profile.tutorial_completed=true;profile.next_match_id=int(canonical.run_id)
  var entry=profile.begin_endless(canonical.map,canonical.difficulty,int(canonical.seed));check(not entry.is_empty(),"isolated matching profile metadata")
  profile.replay.checkpoint=canonical.duplicate(true);check(profile.save_profile(),"isolated canonical checkpoint wrapper saved")
  game.profile=profile;check(game.resume_endless(),"actual Game saved-checkpoint resume")
  game.set_process(false);await click(find_button("Prepare defenses · frozen economy"));await advance(.3)
  var m=game.model;var r=m.player();var ledger=r.buildings.duplicate(true);var gold=r.gold;var power=r.electricity
  check(m.endless.completed==45 and r.tile_count()==16 and m.eliminations==5,"actual earned late Hell state")
  for kind in ["turret","heavy","barrier","plasma","antenna"]:
   var found=false
   for b in r.buildings.values():
    if b.kind==kind and b.level==10:found=true
   check(found,"genuine earned L10 "+kind)
  game.ui.close_context();game.focus_camera(true);await advance(.4);await capture("earned-hell-wave45-sixteen-slots-"+str(resolution.y))
  check(r.gold==gold and r.electricity==power and r.buildings==ledger,"GUI inspection preserves earned wallets/investments")
  check(FileAccess.get_sha256(source)==original,"canonical earned checkpoint byte-preserved")
  reports.append({"earned_source":source,"sha256":original,"completed":45,"resolution":resolution.y,"gold":gold,"electricity":power,"buildings":ledger})
func plasma_readout():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  for branch in StrategyCatalog.branches("plasma"):
   var m=fixture_kind("witch");var r=m.player();check(r.build("plasma",0),"paid Plasma")
   for level in range(3):check(r.upgrade_building(0),"paid Plasma upgrade")
   check(r.specialize_building(0,branch),"paid exclusive Plasma branch")
   for level in range(5):check(r.upgrade_building(0),"paid Plasma prestige")
   await advance(1.5)
   m.apply_room_damage(r.index,150,"cursed_projectile",1,true,{"type":"magic","element":"ice"})
   check(r.magic_state.stored>0 and r.buildings[0].level==10,"actual maxlevel storedmagic")
   game.presentation.update(.01,m);await capture("plasma-readout-fixed-"+branch+"-"+str(resolution.y))
   reports.append({"plasma_branch":branch,"stored":r.magic_state.stored,"capacity":MagicDefense.stats(r.buildings[0]).capacity,"resolution":resolution.y})
func defense_audio():
 root.size=Vector2i(1280,720)
 for kind in MagicDefense.KINDS:
  var m=fixture_kind("witch");var r=m.player();check(r.build(kind,0),"actual paid audiofixture "+kind)
  game.audio_system.set_mix({"music":.5,"effects":.7,"ambient":.3,"muted":false})
  await live(1.5) # Drain initial Practice setup/sale/upgrade audio before measuring new effects.
  var before=game.audio_system.event_counts.duplicate(true);pcm_start()
  MagicDefense.tick(m,.01);var hp=m.hunter.hp
  m.apply_room_damage(r.index,150,"cursed_projectile",1,true,{"type":"magic","element":"ice"})
  await live(2);pcm_finish("audio-magic-"+kind)
  var diff={}
  for key in game.audio_system.event_counts:
   var count=game.audio_system.event_counts[key]-before.get(key,0)
   if count>0:diff[key]=count
  var expected="impact_shock" if kind=="barrier" else "auto_repair_activate" if kind=="plasma" else "shield_absorb"
  check(diff.get(expected,0)>0,"actual magic effect reaches recorded cue "+kind)
  reports.append({"defense_audio":kind,"actual_audio_events":diff,"expected":expected,"hunter_reflected_damage":hp-m.hunter.hp})
func reaper_states():
 root.size=Vector2i(1280,720)
 var m=boss_fixture();await transform(m);var h=m.hunter;var r=m.player()
 h.arcane.cooldown=60;h.tactical_cooldown=60;h.cooldown=60;m.wrath.recovery=100
 h.state=HunterState.State.SEEK;await advance(.1);await capture("reaper-idle-720")
 h.state=HunterState.State.MOVE;h.position=r.corridor_anchor();await drive(.25);await capture("reaper-legal-move-720")
 h.state=HunterState.State.ATTACK;h.position=r.door_approach();h.cooldown=0;await drive(1.0);await capture("reaper-real-attack-720")
 check(m.apply_target_damage(1,30,r.index,{"type":"physical","element":"neutral"})>0,"actual Reaper hurt route");game.presentation.update(.01,m);await capture("reaper-hurt-720")
 h.hit_flash=0;h.apply_suppression(.15);game.presentation.update(.01,m);await capture("reaper-defensive-suppression-720")
 h.suppression_remaining=0;h.hurt(h.hp-h.max_hp*.34);await drive(1.3);m.wrath.recovery=100
 check(m.wrath.phase==2,"real second awakening retained")
 await capture("reaper-phase2-720")
 h.hurt(h.hp-h.max_hp*.09);await drive(3.5);m.wrath.recovery=100
 check(m.wrath.final_used,"real final threshold remains once-only")
 h.hurt(h.hp*10);game.presentation.update(.02,m)
 check(h.state==HunterState.State.DEAD,"real Reaper lethal hit after final guard")
 await capture("reaper-defeat-720")
func run():
 output="res://docs/evidence/gameplay-overhaul/";phase="combat-render"
 var bind={"scripts":{},"hunter_art":{}}
 for file in DirAccess.get_files_at("res://scripts"):
  if file.ends_with(".gd"):bind.scripts[file]=FileAccess.get_sha256("res://scripts/"+file)
 for file in DirAccess.get_files_at("res://assets/hunters"):
  if file.ends_with(".svg"):bind.hunter_art[file]=FileAccess.get_sha256("res://assets/hunters/"+file)
 var bind_args=OS.get_cmdline_user_args();save_data("source-"+str(bind_args[0] if bind_args.size()>0 else "empty"),bind)
 await setup_game()
 var args=OS.get_cmdline_user_args()
 if "hunters" in args:await hunter_states()
 elif "buildings" in args:await magic_buildings()
 elif "reaper" in args:await reaper_states()
 elif "defense-audio" in args:await defense_audio()
 elif "plasma-readout" in args:await plasma_readout()
 elif "earned" in args:await earned_checkpoint()
 elif "info" in args:await combat_info()
 elif "abilities" in args:
  for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
   root.size=resolution
   await ability_case("witch","cursed_projectile");await ability_case("electric","interference");await ability_case("storm","chain_lightning");await ability_case("crusher","soul_drain",true);await ability_case("crusher","shadow_dash",true)
 save_data("result-"+str(args[0] if args.size()>0 else "empty"),{"checks":checks,"failures":failures,"rows":reports,"fixture":"Actual isolated Practice/real gameplay methods/input and Master recordings; controlled legal Hunter positions/warnings,500000 temporaryGold/E. Paid machinelevels/branches. Not natural economy/humanquality/nativeWindows verification."})
 print("OVERHAUL_COMBAT_RENDER_",str(args)," CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
