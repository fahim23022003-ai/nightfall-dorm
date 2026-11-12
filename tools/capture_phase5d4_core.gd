extends "res://tools/capture_phase5d4_early.gd"
var cases=[]
func mark(label,data={}):
 var row=data.duplicate(true);row.label=label;row.time=game.model.time;row.phase=game.model.wrath.phase;row.minions=game.model.minions.size();row.events=game.model.presentation_events.duplicate(true);cases.append(row)
func drive(seconds):
 for i in range(ceili(seconds/.05)):
  update_model(.05);game.focus_camera(false,.05)
  if is_instance_valid(game.ui.horror_layer):game.ui.horror_layer.queue_redraw()
  await process_frame
func boss_fixture():
 game.return_menu();check(game.start_stage("stage_3","hell"),"actual eligible stage3 Hell")
 game.set_process(false);game.tutorial_enabled=false
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5;m.time=m.preparation+9
 for i in range(6):
  var r=m.rooms[i]
  if i>0:r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position();r.bot_timer=1e6
  r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=20000;r.electricity=5000
 var h=m.hunter;h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=30;h.tactical_cooldown=30
 game.focus_camera(true);game.audio_system.reset_match(m);game.ui.update_match()
 return m
func transform(m):
 var h=m.hunter;var before=h.hp
 h.hurt(h.hp-h.max_hp*.54);var damaged=h.hp
 await drive(.1);check(h.state==HunterState.State.TRANSFORM and h.transformed,"eligible actual55pct damage triggers once")
 check(h.hp<=damaged,"transformation does not refill current HP");await capture("eligible-transformation-"+str(root.size.y));await drive(2.5)
 check(h.transformed and h.state!=HunterState.State.TRANSFORM,"actual2.4second transformation completes")
 m.wrath.recovery=100;mark("genuine eligible transform",{"hp_before":before,"hp_after":h.hp})
func new_buildings():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  var m=prepared();await world_click(m.player().tile_position(0));await advance(.2);await capture("new-twelve-card-palette-"+suffix)
  for kind in DefenseEffects.SPECIAL:
   for choice in range(2):
    m=prepared();var r=m.player();await world_click(r.tile_position(0));await advance(.15)
    var gold=r.gold;var power=r.electricity;await click(game.ui.actions["build:"+kind]);await advance(.15)
    check(r.buildings.has(0) and r.buildings[0].kind==kind,"actual BUILD "+kind)
    check(r.gold<gold and r.electricity<power and game.pending_build=="","one direct paidpurchase "+kind)
    if choice==0:await capture(kind+"-level1-"+suffix)
    for i in range(3):await click(game.ui.actions.upgrade);await advance(.08)
    check(r.buildings[0].level==4,"paid actuallevel4 "+kind)
    await click(game.ui.actions.upgrade);await advance(.15)
    var a=game.ui.specialization_items[1];var b=game.ui.specialization_items[2]
    for card in [a,b]:check(not card.get_global_rect().intersects(game.ui.branch_confirm.get_global_rect()),"branch/action separated "+kind)
    if choice==0:await capture(kind+"-branches-"+suffix)
    gold=r.gold;power=r.electricity;await click(game.ui.specialization_items[choice+1]);await advance(.1)
    check(r.gold==gold and r.electricity==power,"newbranch selection doesnotspend "+kind)
    await click(game.ui.branch_confirm);await advance(.12)
    check(r.buildings[0].get("specialization","")==StrategyCatalog.branches(kind)[choice],"actualexclusive newbranch "+kind)
    await capture(kind+"-branch"+str(choice+1)+"-level5-"+suffix)
    for i in range(5):await click(game.ui.actions.upgrade);await advance(.08)
    check(r.buildings[0].level==10 and game.ui.actions.upgrade.disabled,"realpaidtemporary L10, L11disabled "+kind)
    await capture(kind+"-branch"+str(choice+1)+"-level10-"+suffix)
    mark(kind+" branch"+str(choice+1),{"paid_gold":r.buildings[0].invested_gold,"paid_electricity":r.buildings[0].invested_power,"budget_remaining":[r.gold,r.electricity]})
func boss_scenes():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);var m=boss_fixture();await transform(m);await capture("reaper-phase1-"+suffix)
  for id in ["summon","assault","soul_steal","scythe_slash","rules_judgement"]:
   m.wrath.clear(m);m.wrath.recovery=100;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.cooldown=30
   check(m.wrath.begin(id,m,0),"validated realcast "+id);await drive(.45);await capture(id+"-warning-"+suffix)
   await drive(ReaperWrath.ABILITIES[id].warning);check(m.wrath.counts.get(id,0)>0,"actualcast completes "+id)
   if id=="assault":
    check(m.minions.size()==10,"actualmajorassault has10realagents");await drive(2);game.full_map=true;game.focus_camera(true);await capture("ten-undead-map-"+suffix);m.wrath.recovery=100;await drive(8);check(m.minions.size()==10,"tenactualagentspersistthroughlegalnavigation");await capture("ten-undead-spread-"+suffix);game.full_map=false;game.focus_camera(true)
   await capture(id+"-active-"+suffix);mark(id)
  m.wrath.clear(m);m.hunter.hurt(m.hunter.hp-m.hunter.max_hp*.34);await drive(.1);m.wrath.recovery=100
  check(m.wrath.phase==2,"actual35pct HPphase2trigger");await capture("reaper-phase2-"+suffix)
  for id in ["enhanced_undead","soul_reaper","phantom_scream","final_judgement"]:
   m.wrath.clear(m);m.wrath.recovery=100;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.cooldown=30
   check(m.wrath.begin(id,m,0),"validated phase2cast "+id);await drive(.65)
   if id=="phantom_scream":game.full_map=true;game.focus_camera(true)
   await capture(id+"-warning-"+suffix);await drive(ReaperWrath.ABILITIES[id].warning)
   check(m.wrath.counts.get(id,0)>0,"phase2actualactivation "+id);await capture(id+"-active-"+suffix);game.full_map=false;game.focus_camera(true);mark(id)
  # Seeded final threshold picks a valid room, never a fake displayed target.
  m.wrath.clear(m);m.hunter.hurt(m.hunter.hp-m.hunter.max_hp*.09);await drive(.1)
  check(m.wrath.ability=="crimson_execution" and m.wrath.final_used,"actualfinal10 threshold starts once")
  await capture("crimson-warning-"+suffix);var target=m.wrath.cast_target;await drive(3.1)
  check(m.wrath.domain_active() and m.minions.is_empty(),"realcombined domain clearsminions")
  if target!=m.player_room:game.spectate_room(target)
  game.focus_camera(true);await drive(.4);await capture("crimson-thrown-scythe-"+suffix);await drive(.8);await capture("crimson-embedded-domain-"+suffix)
  game.profile.settings.reduced_effects=true;await advance(.15);await capture("crimson-reduced-effects-"+suffix);game.profile.settings.reduced_effects=false
  while m.wrath.domain_active() and m.wrath.domain_remaining>1 and m.hunter.position.distance_to(m.rooms[target].door_approach())>3:await drive(.25)
  check(m.wrath.domain_active() and m.hunter.position.distance_to(m.rooms[target].door_approach())<=3,"actual legalnavigation reaches NPCduel beforetimeout")
  await capture("crimson-arrival-duel-"+suffix)
  mark("final10 combineddomain",{"actual_target":target,"npc_target":target!=m.player_room,"scythe":m.wrath.scythe.duplicate(true)})
  m.hunter.hurt(m.hunter.hp+1);await drive(.1);check(not m.wrath.domain_active() and m.wrath.scythe.is_empty() and m.minions.is_empty(),"realbossdeath cleansdomain/scythe/minions")
  await capture("crimson-boss-death-cleanup-"+suffix)
func status_scenes():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for id in ["crusher","stalker","ravager"]:
   game.return_menu();game.start_practice(id,false,["shield","repair"]);game.set_process(false);game.tutorial_enabled=false
   var m=game.model;var h=m.hunter;h.boss_policy.enabled=false
   h.state=HunterState.State.ATTACK if id=="crusher" else HunterState.State.MOVE;h.target=0;h.position=m.player().door_approach() if id=="crusher" else m.player().corridor_anchor();h.tactical_cooldown=0;h.cooldown=10
   await drive(.1);await capture(id+"-ability-warning-"+suffix);await drive(1);await capture(id+"-ability-active-"+suffix);mark(id+" ability")
  var m=boss_fixture();m.hunter.boss_policy.enabled=false
  for victim in [1,2,3]:
   var r=m.rooms[victim];r.door_hp=0;m.hunter.target=victim;m.hunter.position=r.bed_position();m.hunter.state=HunterState.State.BREACH
   check(m.eliminate_resident(victim),"validattackercontact uniqueelimination")
  check(m.evolution.acquired.size()==3,"threeunique seeded buffs from3realdeaths")
  await advance(.15);await capture("evolution-first-banner-"+suffix);check(game.presentation.wrath_presentation.evolution_queue[0].power==1,"first actualqueuedbanner");await drive(4);await capture("evolution-second-banner-"+suffix);check(game.presentation.wrath_presentation.evolution_queue[0].power==2,"second actualqueuedbanner");await drive(4);await capture("evolution-third-banner-"+suffix);check(game.presentation.wrath_presentation.evolution_queue[0].power==3,"third actualqueuedbanner")
  await drive(4);var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*game.ui.hunter_label.get_global_rect().get_center();motion.global_position=motion.position;Input.parse_input_event(motion);await create_timer(.7).timeout
  await capture("evolution-persistent-hover-"+suffix);mark("3actualkills and persistentpower",{"buffs":m.evolution.acquired.duplicate()})
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game()
 var args=OS.get_cmdline_user_args();var mode=args[0] if args.size()>0 else "buildings"
 if mode=="buildings":await new_buildings()
 elif mode=="boss":await boss_scenes()
 elif mode=="status":await status_scenes()
 var f=FileAccess.open("res://docs/evidence/phase5d4/core-render-"+mode+"-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"fixture":"Controlled deterministic actualmodel/input rendering. Practice purchasesuseactualtemporary20kGold/5kElectricity; bosscases configure eligiblecampaignstage3Hell rooms/time and applyrealHunterdamage. No naturalreachability/strategybalance/Windowsclaim."}," "))
 print("PHASE5D4_CORE_RENDER_",mode.to_upper(),"_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
