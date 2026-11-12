extends "res://tools/capture_visual_overhaul.gd"
var manifest_rows=[]
var original_hashes={}
func capture(name):
 if game.mode=="match":game.ui.update_match();game.ui.items_ui.update(0)
 await super.capture(name)
func advance(seconds):
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame;var now=Time.get_ticks_usec();var delta=(now-previous)/1000000.0;previous=now
  if game.mode=="match":game.focus_camera(false,delta)
  game.presentation.update(delta,game.model);game.horror.update(delta,game.model)
  game.audio_system.update_state(delta,game.model,game.mode);game.ui.items_ui.update(delta)
  if game.mode=="match":game.ui.update_match()
  game.queue_redraw()
func key(code):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func world_click(point):
 var at=root.get_final_transform()*game.world_to_screen(point)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func save_json(name,value):
 var f=FileAccess.open("res://docs/evidence/phase5d3/"+name+".json",FileAccess.WRITE);f.store_string(JSON.stringify(value," "))
func setup_game():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase5d3-team-render-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 game.profile.xp=3800;game.profile.highest_rank=5;game.profile.rm_cash=200;game.profile.next_match_id=2
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 check(game.profile.save_profile(),"prepared graduated profile valid")
func end_run(label):
 print("PHASE5D3_",label,"_CHECKS=",checks," FAILURES=",failures)
 save_json("render-"+label.to_lower()+"-result",{"checks":checks,"failures":failures,"conditions":"Actual Linux Godot rendering/input, prepared isolated profiles unless explicitly earned source; no Windows or human-quality claim."})
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
func run():
 output="res://docs/evidence/phase5d3/render-screens/";phase="team"
 await setup_game()
 var args=OS.get_cmdline_user_args()
 if "earned" in args:phase="earned";await earned();await end_run("EARNED_NORMAL" if "normal" in args else "EARNED_HELL" if "hell" in args else "EARNED");return
 if "branches" in args:phase="branches";await branches();await end_run("BRANCHES");return
 if "clarity" in args:phase="clarity";await clarity();await end_run("CLARITY");return
 await team();await end_run("TEAM")
func team():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for stage in StageCatalog.STAGES:
   var m=fixture(stage.id);var own=m.player();var pos=m.player_position;var owner=m.player_room;var h=m.hunter
   h.boss_policy.enabled=false;h.state=HunterState.State.MOVE;h.target=2;h.position=m.rooms[2].corridor_anchor()
   game.ui.teammates.expanded=false;game.ui.teammates.update();await key(KEY_T)
   check(game.ui.teammates.expanded and game.ui.teammates.body.visible,"actualT opens roster "+m.map_id)
   check(game.ui.teammates.indices.size()==5 and game.ui.teammates.toggle.text.contains("5/5"),"roster uses actual five living teammates "+m.map_id)
   for i in range(game.ui.teammates.indices.size()):
    var r=m.rooms[game.ui.teammates.indices[i]];var b=game.ui.teammates.rows[i]
    check(b.text.contains(r.survivor_name()) and b.text.contains("Room %02d" % (r.index+1)),"row uses actual owner/name/room")
   await capture(m.map_id+"-roster-"+suffix)
   var watched=game.ui.teammates.indices[1]
   await click(game.ui.teammates.rows[1]);await advance(1.4)
   check(game.watched_room==watched and game.ui.teammates.watching.text.contains(m.rooms[watched].survivor_name()),"actualrow observes correct survivor")
   check(game.camera.position.distance_to(game.camera_target)<2,"camera smoothly settles to valid room")
   check(m.player_position==pos and m.player_room==owner and own.owner==0,"spectator never moves player or ownership")
   check(game.ui.room_bed_summary.disabled and game.ui.room_door_summary.disabled and game.ui.room_selected_summary.disabled,"spectator summaries read-only")
   var before=own.buildings.duplicate(true);await world_click(m.rooms[watched].tile_position(0));await advance(.1)
   check(not game.ui.context_open and own.buildings==before,"actual spectator worldclick cannot edit teammate/owned buildings")
   await capture(m.map_id+"-watching-"+suffix)
   var previous=game.watched_room;await key(KEY_PAGEDOWN);await advance(.25)
   check(game.watched_room!=previous,"actualPageDown cycles")
   await key(KEY_PAGEUP);await advance(.25);check(game.watched_room==previous,"actualPageUp returns preceding teammate")
   # Real model clocks continue during spectating; controlled target/warnings are
   # set for deterministic render without claiming a naturally lost match.
   h.target=own.index;h.state=HunterState.State.ATTACK;h.position=own.door_approach();h.cooldown=10
   var time=m.time;game._process(.1);await advance(.2)
   check(m.time>time,"spectating does not pause actual model")
   check(game.audio_system.listener_position==own.bed_position(),"audio listener remains anchored to own survivor")
   check(game.ui.teammates.watching.text.contains("YOUR DOOR IS UNDER ATTACK"),"own danger awareness shown while observing teammate")
   await capture(m.map_id+"-own-danger-"+suffix)
   # Actual Hunter breach/bed contact eliminates the watched teammate.
   var r=m.rooms[watched];r.door_hp=1;r.rescue_used=true;h._clear_tactics();h.target=watched;h.position=r.door_approach();h._damage_door(r,m,100);h.state=HunterState.State.BREACH;h.position=r.bed_position();h.tick(.01,m)
   check(not r.alive,"actual controlled bed contact eliminates watched teammate")
   game.audio_system.update_state(.01,m,game.mode);game.ui.teammates.update();await advance(.2)
   check(game.watched_room==watched and game.ui.teammates.watching.text.contains("ELIMINATED"),"dead observed room remains valid labelled camera")
   check(game.ui.teammates.toggle.text.contains("4/5"),"live teammate count updates afteractualelimination")
   await capture(m.map_id+"-eliminated-"+suffix)
   await key(KEY_HOME);await advance(.1)
   check(game.watched_room==-1 and game.camera.position.distance_to(game.camera_target)<2,"actualHome restores own camera immediately")
   check(m.player_position==pos and m.player_room==owner,"own control state restored withoutteleport")
   if stage.id=="stage_1":
    await click(game.ui.teammates.rows[0]);await advance(.2);await click(game.ui.teammates.home);await advance(.1)
    check(game.watched_room==-1,"actual obvious ReturntoMyRoom button")
    # Actual UI interaction while roster remains open, inspect stacking.
    await click(game.ui.room_bed_summary);await advance(.2)
    check(game.ui.context_open and not game.ui.teammates.body.visible,"opening own inspector collapses overlapping roster")
    await capture("own-context-with-roster-"+suffix)
    game.ui.close_context()
   game.profile.settings.reduced_effects=resolution.y==1080
func copy_earned(source):
 game.return_menu();game.set_process(false)
 var file="res://docs/evidence/phase5d3/"+source+".json"
 original_hashes[source]=FileAccess.get_sha256(file)
 var canonical=JSON.parse_string(FileAccess.get_file_as_string(file))
 var dest="user://phase5d3-earned-render-"+source+"-"+str(Time.get_ticks_usec())+".json"
 check(DirAccess.copy_absolute(ProjectSettings.globalize_path(file),ProjectSettings.globalize_path(dest))==OK,"copy authentic earned profile")
 var p=PlayerProfile.new(dest);check(p.load_profile() and not p.read_only,"earned profile writable load")
 if not p.tutorial_completed:p.tutorial_completed=true;check(p.save_profile(),"graduate GUI copy only")
 var copied=JSON.parse_string(FileAccess.get_file_as_string(dest));copied.onboarding.tutorial_completed=canonical.onboarding.tutorial_completed
 check(copied==canonical,"GUIcopy changes only tutorial flag after JSON normalization")
 game.profile=p;check(game.resume_endless(),"actual earned checkpoint resume")
 game.set_process(false);await click(find_button("Prepare defenses · frozen economy"));await process_frame
 return game.model
func earned():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for source in ["balance-earned-all8-haunted_hospital-standard","balance-earned-all8-cursed_mansion-hell-alternative"]:
   if "normal" in OS.get_cmdline_user_args() and "hell" in source:continue
   if "hell" in OS.get_cmdline_user_args() and "standard" in source:continue
   var m=await copy_earned(source);var r=m.player();var label="normal" if m.difficulty=="standard" else "hell"
   check(r.bed_level==9 and r.door_level==9 and r.bed_branch!="" and r.door_branch!="","both structures genuinely earnedL10andbranch")
   game.ui.teammates.expanded=false;game.ui.teammates.update();await advance(.15);await capture(label+"-all8-world-"+suffix)
   var ledger={"gold":r.gold,"electricity":r.electricity,"buildings":r.buildings.duplicate(true)}
   await click(game.ui.room_bed_summary);await advance(.15)
   check(game.ui.context_title.text.contains("10 / 10") and game.ui.bed_details.text.contains(StrategyCatalog.BRANCHES[r.bed_branch].name),"actual max bed inspector names earnedbranch")
   await capture(label+"-bed10-"+suffix);game.ui.close_context()
   await click(game.ui.room_door_summary);await advance(.15)
   check(game.ui.context_title.text.contains("10 / 10") and game.ui.door_details.text.contains(StrategyCatalog.BRANCHES[r.door_branch].name),"actual max door inspector names earnedbranch")
   await capture(label+"-door10-"+suffix);game.ui.close_context()
   for kind in Catalog.BUILDINGS:
    var tile=-1
    for t in r.buildings:
     if r.buildings[t].kind==kind:tile=t;break
    check(tile>=0 and r.buildings[tile].level==10,"earned machineL10 "+kind)
    await world_click(r.tile_position(tile));await advance(.15)
    check(game.ui.context_open and game.ui.selected_details.text.contains("10 / 10") and game.ui.actions.upgrade.disabled,"actual maximum-level inspector disablesL11 "+kind)
    await capture(label+"-"+kind+"10-"+suffix);game.ui.close_context()
   check(r.gold==ledger.gold and r.electricity==ledger.electricity and r.buildings==ledger.buildings,"inspection preserves actual earned resources/investment")
   game.profile.settings.reduced_effects=true;await advance(.15);await capture(label+"-all8-reduced-"+suffix)
   check(FileAccess.get_sha256("res://docs/evidence/phase5d3/"+source+".json")==original_hashes[source],"canonical earned profile remains unchanged")
 save_json("render-earned-"+("normal" if "normal" in OS.get_cmdline_user_args() else "hell" if "hell" in OS.get_cmdline_user_args() else "all")+"-source-hashes",original_hashes)
func branches():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for kind in ["bed","door","generator","repair","economy","enhancer"]:
   game.return_menu();game.start_practice("crusher",false,["shield","repair"]);game.set_process(false)
   var r=game.model.player();game.ui.teammates.expanded=false;game.ui.teammates.update()
   if kind in ["bed","door"]:
    await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary)
    await click(game.ui.actions[kind])
   else:
    var tile=0
    while r.buildings.has(tile):tile+=1
    check(r.build(kind,tile),"actual temporary paidrole building")
    for i in range(3):check(r.upgrade_building(tile),"actual paidrole upgrade")
    await world_click(r.tile_position(tile));await advance(.15);await click(game.ui.actions.upgrade)
   await advance(.15)
   await capture(kind+"-branches-"+suffix)
   check(game.ui.context_mode=="specialize","actualrole choice UI "+kind)
   var ids=StrategyCatalog.branches(kind)
   for i in range(2):
    var b=game.ui.specialization_items[i+1]
    check(b.visible and not b.disabled and b.icon!=null and b.text.contains(StrategyCatalog.BRANCHES[ids[i]].name),"actual newbranchicon/description/eligiblequote")
   await click(game.ui.specialization_items[1]);await advance(.1)
   check(game.ui.context_mode!="specialize","actual paidbranch selection completes")
   await capture(kind+"-chosen-"+suffix)

func clarity():
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  var m=fixture();var target=game.ui.teammates.indices[0] if not game.ui.teammates.indices.is_empty() else 1
  m.hunter.state=HunterState.State.MOVE;m.hunter.target=target;m.hunter.position=m.rooms[target].corridor_anchor();game.ui.teammates.expanded=false
  await key(KEY_T);await advance(.2)
  check(game.ui.teammates.rows[0].text.contains("APPROACHING"),"live approach status names actual target")
  await capture("team-approaching-"+suffix)
  game.return_menu();game.start_practice("crusher",false,["coupon","repair"]);game.set_process(false)
  var r=game.model.player();var stock=game.item_wallet().inventory.coupon
  check(game.activate_item(0),"real temporary coupon arms for structural UI check")
  await click(game.ui.room_bed_summary);await advance(.1);await click(game.ui.actions.bed);await capture("bed-full-price-coupon-retained-"+suffix)
  check(game.ui.context_mode=="specialize" and game.ui.specialization_items[-1].text.contains("5"),"structural Back correctly keepsL5")
  check(not game.ui.specialization_items[1].text.contains("COUPON"),"structuralquote doesnot falsely markdiscount")
  var g=r.gold;var e=r.electricity
  await click(game.ui.specialization_items[1]);await advance(.1)
  check(r.bed_level==5 and r.gold==g-Catalog.BED_COST[4] and r.electricity==e-Catalog.BED_POWER[4] and r.coupon_armed and game.item_wallet().inventory.coupon==stock,"structure pays fullprice without spending machinecoupon")
  await capture("bed-upgraded-coupon-still-armed-"+suffix)
  game.return_menu();game.start_practice("crusher",false,["coupon","repair"]);game.set_process(false);r=game.model.player()
  var tile=0
  while r.buildings.has(tile):tile+=1
  check(r.build("generator",tile),"paid couponfixturegenerator")
  for i in range(3):check(r.upgrade_building(tile),"paid generatorlevel")
  await world_click(r.tile_position(tile));await advance(.15);await capture("machine-specialize-action-fits-"+suffix)
  check(game.activate_item(0),"real machinecoupon armed")
  await click(game.ui.actions.upgrade);await capture("machine-discounted-branch-"+suffix)
  check(game.ui.context_mode=="specialize" and game.ui.specialization_items[1].text.contains("COUPON"),"actual eligible branchdisplayscouponquote")
  check(game.ui.specialization_items[-1].text.contains("4"),"machineBackcorrectlykeepsL4")
  await click(game.ui.specialization_items[1]);await advance(.15);await capture("machine-actual-discount-refund-"+suffix)
  check(not r.coupon_armed and game.item_wallet().inventory.coupon==4,"successful actualdiscount consumes exactlyone temporarycoupon")
