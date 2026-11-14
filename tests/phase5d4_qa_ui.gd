extends "res://tests/premium_strategy_ui.gd"
const Support=preload("res://tests/replay_test_support.gd")
var rectangles=[]
# Freeze simulation, but preserve real frame-driven enabled/reason updates.
func settle():
 # Historical prepared fixture: preserve v1 prices; Phase12 tests exercise default v2.
 if game!=null and is_instance_valid(game):game.new_balance_version=1
 await process_frame
 if game!=null and is_instance_valid(game) and game.mode=="match":game.ui.update_match()
 # Ordinary inspector actions wait for the real wall-time drawer animation.
 # Dedicated overhaul input tests separately exercise guarded moving controls.
 if game!=null and is_instance_valid(game) and game.mode=="match" and game.ui.bottom_context!=null:
  var deadline=Time.get_ticks_msec()+1500
  while game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()<deadline:await process_frame
 await process_frame
func click(control,double_click=false):
 await settle()
 await super.click(control,double_click)
 await settle()
func primitive(value,seen={}):
 if value is RandomNumberGenerator:return {"seed":str(value.seed),"state":str(value.state)}
 if value is Dictionary:
  var out={}
  for k in value:out[k]=primitive(value[k],seen)
  return out
 if value is Array:
  var out=[]
  for v in value:out.append(primitive(v,seen))
  return out
 if value is Object:
  if value==null:return null
  var id=value.get_instance_id()
  if seen.has(id) or value is WeakRef or value.get_script()==null:return {"object":id}
  seen[id]=true
  var out={}
  for p in value.get_script().get_script_property_list():
   if p.name!="script":out[p.name]=primitive(value.get(p.name),seen)
  return out
 if value is Callable or value is Signal:return "callback"
 return value
func state():return JSON.stringify(primitive(game.model,{}))
func camera():return [game.camera.position,game.camera.zoom,game.camera_target,game.model.player_position]
func key(code):
 for down in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.pressed=down;Input.parse_input_event(e);await process_frame
 await settle()
func pointer(point,down,double_click=false):
 var physical=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new();motion.position=physical;motion.global_position=physical;Input.parse_input_event(motion);await process_frame
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=physical;e.global_position=physical;e.pressed=down;e.double_click=double_click;Input.parse_input_event(e);await process_frame
func point_click(point,double_click=false):
 await pointer(point,true,double_click);await pointer(point,false);await settle()
func pad(tile):
 await settle()
 var pos=game.world_to_screen(game.model.player().tile_position(tile));await point_click(pos)
 game.ui.update_match();await settle()
func next_pad():
 var r=game.model.player()
 for i in range(r.tile_count()):
  if not r.buildings.has(i):return i
 return -1
func stable_panel(label,before,model_state):
 check(camera()==before,label+" leavescamera/zoom/goal/playerpositionunchanged")
 check(state()==model_state,label+" leavesallmodelprimitive/RNG/stateunchanged")
 var rect=game.ui.context_box.get_global_rect();rectangles.append(rect)
 check(rect.position.y>=430 and rect.size.x>=1000 and rect.end.x<=1280.1 and rect.end.y<=720.1,label+" useswidefixedbottomregion")
 for r in rectangles:check(r==rect,label+" neverchangescontextparentgeometry")
 for b in controls(game.ui.context_box,Button):
  if b.is_visible_in_tree():check(inside(b.get_global_rect(),rect),label+" actualinteractivebuttonfitscontextregion")
func branch_flow(kind):
 var r=game.model.player();game.ui.close_context()
 if kind in ["bed","door"]:
  await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await click(game.ui.actions[kind])
 else:
  game.selected_tile=game.model.practice_tile;game.ui.open_context();await settle();await click(game.ui.actions.upgrade)
 await settle()
 check(game.ui.context_mode=="specialize" and game.ui.branch_confirm.disabled,"exclusivechoice startsunconfirmedanddisabled")
 var prior=state();var cam=camera();await click(game.ui.specialization_items[1]);await settle()
 check(game.ui.pending_branch!="" and not game.ui.branch_confirm.disabled,"ordinarychoicebuttonselectsreadablependingbranch")
 stable_panel("branch selection "+kind,cam,prior)
 check(game.ui.specialization_items[1].text.contains("SELECTED") and game.ui.specialization_items[1].icon!=null,"selectedbranchhasactualartandselectedstate")
 await click(game.ui.specialization_items[3]);await settle()
 check(state()==prior,"Backfromselectionneverchargesorchangesbranch")
 game.ui.close_context()
 # Reopen and make one explicit paid confirmation; two rapid confirmation
 # presses must not purchase a second tier after the controls change.
 if kind in ["bed","door"]:
  await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await click(game.ui.actions[kind])
 else:
  game.selected_tile=game.model.practice_tile;game.ui.open_context();await settle();await click(game.ui.actions.upgrade)
 await click(game.ui.specialization_items[2]);await settle()
 var gold=r.gold;var power=r.electricity;var at=game.ui.branch_confirm.get_global_rect().get_center()
 var quote=Vector2(650,60) if kind=="bed" else Vector2(700,60) if kind=="door" else Vector2(125,19)
 await point_click(at);await point_click(at,true)
 check(is_equal_approx(gold-r.gold,quote.x) and is_equal_approx(power-r.electricity,quote.y),"explicitbranchConfirmchargesquotedpriceonce "+kind)
 check((r.bed_level if kind=="bed" else r.door_level)==5 if kind in ["bed","door"] else r.buildings[game.model.practice_tile].level==5,"confirmedbranchadvancesexactlyonetier")
 game.ui.close_context()
func effective_stats():
 game.start_practice("crusher",false,["overdrive","repair"]);await settle()
 var m=game.model;var r=m.player();var tile=m.practice_tile
 check(m.specialize_building(tile,"suppression"),"controlledstatfixturepaysactualNeedlebranch")
 var free=[]
 for i in range(r.tile_count()):
  if not r.buildings.has(i):free.append(i)
 for index in range(2):
  check(m.buy("enhancer",free[index]),"actualsupportrelaypurchasedforstatcheck")
  for n in range(3):check(m.upgrade_building(free[index]),"actualrelayupgrades")
  check(m.specialize_building(free[index],"coolant" if index==0 else "ballistic"),"realtradeoffrelaychoice")
 r.turret_multiplier=1.03;m.match_boosts.reaper=1.06;m.stage_bonus={"damage":1.08,"seconds":60};m.time=10;m.preparation=0;m.hunter.transformed=false;m.hunter.conceal_remaining=3
 await key(KEY_1)
 check(m.items.timers.get("overdrive",0)>0,"actualtemporaryOverdriveactivatesforcurrentstatpreview")
 var expected_raw=9*5*.8*(1+.35*4.5*.75+.35*4.5*1.2)*1.03
 var expected_interval=(.9/1.48)*.82*.9/1.35
 var expected_hit=expected_raw*1.06*1.08
 var concealed=BuildingStats.weapon_stats(m,r,r.buildings[tile])
 check(is_equal_approx(concealed.range,240*.9*.8) and is_equal_approx(concealed.hit,expected_raw*1.08),"normalconcealrangeapplieswithoutprematureReapermultiplier")
 m.hunter.transformed=true;m.hunter.conceal_remaining=0
 var expected_range=240*.9
 var stats=BuildingStats.weapon_stats(m,r,r.buildings[tile])
 check(is_equal_approx(stats.damage,expected_raw) and is_equal_approx(stats.hit,expected_hit) and is_equal_approx(stats.interval,expected_interval) and is_equal_approx(stats.dps,expected_hit/expected_interval) and is_equal_approx(stats.range,expected_range),"effectivepreviewindependentlymatchesrelay/perk/item/stage/boss/concealmathexactlyonce")
 game.selected_tile=tile;game.ui.open_context();await settle()
 check(game.ui.selected_details.text.contains("Hit %.1f" % expected_hit) and game.ui.selected_details.text.contains("%.1f DPS" % (expected_hit/expected_interval)),"actualinspectorlabelsdisplayeffectivestatsnotbaseskins")
 m.hunter.state=HunterState.State.MOVE;m.hunter.position=r.tile_position(tile)+Vector2(20,0);r.buildings[tile].cooldown=0;m._turrets(0)
 check(m.projectiles.size()==1 and is_equal_approx(m.projectiles[0].damage,expected_raw) and is_equal_approx(r.buildings[tile].cooldown,expected_interval),"actuallaunchusesthesamecorrectdamage/ratewithoutimpactdoublebuff")
 var hp=m.hunter.hp;m._advance_projectiles(.5)
 check(is_equal_approx(hp-m.hunter.hp,expected_hit),"actualprojectileimpactreceivesstage/Reapermultipliersonce")
func run():
 profile_path="user://phase5d4-qa-ui-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;check(p.save_profile(),"isolatedUIprofileprepared")
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await settle()
 var permanent=Support.profile_signature(game.profile);var bytes=FileAccess.get_file_as_bytes(profile_path)
 for map in MapCatalog.IDS:
  if "--one-map" in OS.get_cmdline_user_args() and map!=MapCatalog.IDS[0]:continue
  rectangles.clear();game.start_practice("crusher",false,["repair","shield"],map);await settle();game.focus_camera(true)
  var r=game.model.player();var before=camera();var initial=state();var parent_id=game.ui.context_box.get_instance_id();var tile=next_pad()
  await pad(tile);await settle();stable_panel("actual emptyfloor click "+map,before,initial)
  check(game.ui.context_mode=="build" and game.selected_tile==tile,"actualownedpadopensbuildpalette")
  for kind in Catalog.BUILDINGS:
   var card=game.ui.actions["build:"+kind]
   check(card.visible and card.text=="BUILD" and card.tooltip_text!="","registeredmachinehasliteralBuild/requirementscontrol "+kind)
  # Every fifth card is in the risky rightmost column. Its new inspector can
  # occupy the same point, so the OS double-click trailing event must be eaten.
  var kinds=Catalog.BUILDINGS.keys()
  for index in range(4,kinds.size(),5):
   tile=next_pad();await pad(tile);await settle();var kind=kinds[index];var card=game.ui.actions["build:"+kind];var at=card.get_global_rect().get_center();var gold=r.gold;var power=r.electricity;var count=r.buildings.size();before=camera()
   print("QA_CARD_BEFORE ",map," ",kind," at=",at," rect=",card.get_global_rect()," disabled=",card.disabled," selected=",game.selected_tile," mode=",game.ui.context_mode)
   await point_click(at);await point_click(at,true)
   print("QA_CARD_AFTER ",kind," mode=",game.ui.context_mode," selected=",game.selected_tile," bought=",r.buildings.get(tile,{})," last_error=",r.last_error," hover=",root.gui_get_hovered_control())
   check(r.buildings.size()==count+1 and r.buildings[tile].kind==kind and r.buildings[tile].level==1,"rightcolumn realdoubleclickpurchasesoncewithoutaccidentalUpgrade "+kind)
   check(is_equal_approx(gold-r.gold,Catalog.BUILDINGS[kind].gold) and is_equal_approx(power-r.electricity,Catalog.BUILDINGS[kind].power),"doubleclickchargesonlyoneactualbaseprice")
   check(game.pending_build=="" and not game.placement_on_tile and game.ui.context_mode=="upgrade","directBuildhasnostuckmouse-followpreview")
   check(camera()==before,"Build/inspectorswapdoesnotmoveview")
   game.ui.close_context();tile=next_pad();await pad(tile);await settle();card=game.ui.actions["build:"+kind];at=card.get_global_rect().get_center();var unchanged=state()
   print("QA_HELD_START ",kind," actionmode=",card.action_mode," count=",r.buildings.size()," context=",game.ui.context_mode)
   await pointer(at,true)
   print("QA_HELD_DOWN ",kind," count=",r.buildings.size()," context=",game.ui.context_mode," visible=",card.is_visible_in_tree()," pressed=",card.is_pressed())
   await key(KEY_ESCAPE)
   print("QA_HELD_ESCAPE ",kind," context=",game.ui.context_open," mode=",game.ui.context_mode," running=",game.model.running," count=",r.buildings.size())
   await pointer(at,false);await settle()
   print("QA_HELD_RELEASE ",kind," context=",game.ui.context_open," mode=",game.ui.context_mode," running=",game.model.running," count=",r.buildings.size()," newtile=",r.buildings.get(tile,{}))
   check(state()==unchanged and not game.ui.context_open and game.pending_build=="","heldBuildpresscancelledwithEscapebefore releasecannotchargeorstick")
   await pad(tile);await settle();check(game.ui.context_mode=="build","samepadreopenscleanlyaftercancel")
   game.ui.close_context()
  # One context parent and camera framing across every inspect/branch state.
  game.selected_tile=game.model.practice_tile;before=camera();var same=state();game.ui.open_context();await settle();stable_panel("machine inspector "+map,before,same)
  check(game.ui.selected_details.text.contains("LEVEL 4") and game.ui.selected_details.text.contains("Hit 36.0") and game.ui.selected_details.text.contains("54.4 DPS") and game.ui.selected_details.text.contains("Choose and confirm"),"weaponinspectoradvertisesactualcurrentcombatstats")
  for kind in ["bed","door"]:
   game.ui.close_context();before=camera();same=state();await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await settle();stable_panel("structure inspector "+kind,before,same)
   check(game.ui.actions[kind].text.contains("Gold") and game.ui.actions[kind].text.contains("Electricity"),"structuralupgradeusesliteralresourceunits")
  await branch_flow("turret");await branch_flow("bed");await branch_flow("door")
  check(game.ui.context_box.get_instance_id()==parent_id,"allcontextsreuseonepredictableparent")
  game.return_menu();await settle()
  check(Support.profile_signature(game.profile)==permanent and FileAccess.get_file_as_bytes(profile_path)==bytes,"UI/previews/temporarypurchasesnevermutatepermanentprogress")
 await effective_stats()
 print("PHASE5D4_UI_QA_CHECKS=",checks," MAPS=",1 if "--one-map" in OS.get_cmdline_user_args() else 5," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 Support.cleanup(profile_path);quit(1 if failures else 0)
