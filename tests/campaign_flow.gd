extends SceneTree
var checks=0
var failures=0
var game
var profile_path="user://campaign-independent-flow.json"
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  push_error("CAMPAIGN FLOW: "+label)
func _initialize(): call_deferred("run")
func button(text:String):
 for node in game.ui.panel.get_children():
  if node is Button and node.text==text and not node.is_queued_for_deletion(): return node
 return null
func press(text:String):
 var b=button(text)
 check(b!=null,"button exists "+text)
 if b!=null: b.pressed.emit()
 await process_frame
func reveal_reward():
 if game.profile.pending_spins.is_empty(): return
 var receipt=game.profile.pending_spin()
 var stock=game.profile.inventory.duplicate(true)
 check(button("Lucky Spin · reveal earned item")!=null,"earned reward gates existing continuation")
 await press("Lucky Spin · reveal earned item")
 check(game.ui.current_screen=="spin","results opens real spin screen")
 await press("Skip animation")
 check(game.ui.items_ui.spin_ready,"skip reveals predetermined item")
 check(game.profile.inventory==stock,"skip animation never adds stock twice")
 await press("Save reveal & continue")
 check(game.profile.pending_spins.is_empty() and game.profile.inventory==stock,"acknowledgment clears receipt without duplicate grant")
 check(game.profile.claim_spin(int(receipt.match_id)).is_empty(),"repeated reveal acknowledgment rejected")
 if not game.profile.pending_stage_bonus.is_empty() and game.profile.pending_stage_bonus.choice=="":
  await press("Choose stage bonus")
  check(game.ui.current_screen=="stage_bonus","saved stage offer follows spin")
  await press("Select")
  check(game.profile.pending_stage_bonus.choice=="reinforced","one actual stage choice saved")
  check(not game.profile.choose_stage_bonus("economic"),"repeated choice rejected")
  game.ui.show_result()
  await process_frame

func finish(result:String):
 var room=game.model.player()
 if room==null:
  game.model.claim_room(0)
  room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 game.model.time=80
 room.occupied_seconds=60
 room.damage_dealt=1000
 game.model.result=result
 game.model.hunter.hp=0 if result=="victory" else 100
 if result=="defeat": room.alive=false; room.sleeping=false
 game._process(0.01)
 await process_frame
 await reveal_reward()
func process_roundtrip(mode: String):
 var path="user://campaign-independent-process.json"
 if mode=="campaign_write":
  for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(path+suffix)
 var p=PlayerProfile.new(path)
 if mode=="campaign_write":
  var entry=p.begin_match("standard","stage_1")
  var m=MatchModel.new()
  m.configure_match("standard",RankCatalog.bonuses(entry.equipped))
  m.configure_stage("stage_1")
  m.claim_room(0)
  m.player().sleeping=true
  m.player().occupied_seconds=60
  m.time=80
  m.hunter.hp=0
  m.result="victory"
  check(p.settle_match(entry.id,m).campaign.cleared,"process writer clear")
  check(p.select_stage("stage_2") and p.select_difficulty("hard") and p.equip("pocket"),"process writer preferences")
 else:
  check(p.load_profile(),"new process loads saved profile")
  check(p.selected_stage=="stage_2" and p.selected_difficulty=="hard","new process retains stage/difficulty")
  check(p.stage_record("stage_1").clears==1 and p.stage_unlocked("stage_2") and not p.stage_unlocked("stage_3"),"new process retains records and locks")
  check(p.equipped==["pocket"] and p.xp>0,"new process retains loadout and xp")
 print("CAMPAIGN_PROCESS_",mode," CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)

func run():
 var arguments=OS.get_cmdline_user_args()
 if not arguments.is_empty() and arguments[0] in ["campaign_write","campaign_read"]:
  process_roundtrip(arguments[0])
  return
 for suffix in ["",".bak",".tmp"]:
  DirAccess.remove_absolute(profile_path+suffix)
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 check(game.profile.selected_stage=="stage_1","new profile selects stage1")
 check(not game.start_stage("stage_2"),"locked stage cannot launch")
 game.ui.campaign.show_stages()
 check(game.ui.current_screen=="stages","stage select opens")
 check(not game.ui.campaign.prepare("stage_2"),"locked prepare rejected")
 check(game.ui.campaign.prepare("stage_1"),"stage1 prepare")
 check(game.ui.current_screen=="loadout" and game.mode!="match","prepare does not auto start")
 check(not game.profile.equip("marksman"),"locked perk rejected")
 check(game.profile.equip("pocket"),"existing unlocked perk equips")
 await press("Start Match")
 check(game.model.stage_id=="stage_1" and game.campaign_mode,"start launch snapshot stage")
 check(game.model.player()==null and game.model.match_boosts.gold==5,"perk enters actual configuration")
 game.model.claim_room(0)
 check(game.model.player().gold==30,"perk affects actual gold")
 await finish("victory")
 check(game.mode=="result" and game.profile.stage_unlocked("stage_2"),"victory unlock stage2")
 var old_id=game.match_id
 await press("Next Stage")
 check(game.ui.current_screen=="loadout" and game.profile.selected_stage=="stage_2","next opens stage2 loadout")
 check(game.match_id==old_id and game.mode!="match","next does not auto restart match")
 await press("Start Match")
 check(game.model.stage_id=="stage_2","stage2 starts")
 await finish("defeat")
 check(not game.profile.stage_unlocked("stage_3"),"defeat no next unlock")
 await press("Change Loadout")
 check(game.ui.current_screen=="loadout" and game.profile.selected_stage=="stage_2","change loadout stays correct")
 await press("Start Match")
 await finish("defeat")
 await press("Retry Stage")
 check(game.model.stage_id=="stage_2" and game.mode=="match","retry correct stage")
 for difficulty in ["standard","hard"]:
  check(game.start_stage("stage_2",difficulty),"difficulty stage starts "+difficulty)
  var data=StageCatalog.stage("stage_2")
  var tuning=RankCatalog.DIFFICULTIES[difficulty]
  check(is_equal_approx(game.model.hunter.max_hp,Catalog.HUNTER.hp*data.hunter_hp*tuning.hp),"HP scaling composes "+difficulty)
  game.model.time=game.model.preparation+0.01
  game.model.hunter.tick(0.01,game.model)
  check(is_equal_approx(game.model.hunter.damage,Catalog.HUNTER.damage*data.hunter_damage*tuning.damage),"damage scaling survives tick "+difficulty)
 check(game.ui.campaign.prepare("stage_1"),"completed replay remains preparable")
 await press("Start Match")
 await finish("victory")
 check(not game.last_progression.campaign.first_clear and game.last_progression.campaign.reward_xp==0,"replay grants no duplicate firstclear")
 var earned=game.profile.xp
 check(game.profile.settle_match(game.match_id,game.model).is_empty() and game.profile.xp==earned,"duplicate settle blocked")
 await press("Stage Select")
 check(game.ui.current_screen=="stages","result stage select routes")
 await press("Main menu")
 check(game.mode=="menu","main menu routes")
 var reload=PlayerProfile.new(profile_path)
 check(reload.load_profile(),"campaign save reload")
 check(reload.stage_unlocked("stage_2") and not reload.stage_unlocked("stage_3"),"locks survive restart")
 check(reload.stage_record("stage_1").clears==2 and reload.equipped==["pocket"],"records and loadout survive")
 for stage_id in ["stage_2","stage_3","stage_4","stage_5"]:
  check(game.start_stage(stage_id,"standard"),"sequential start "+stage_id)
  await finish("victory")
  check(game.last_progression.campaign.cleared,"sequential clear "+stage_id)
 check(game.profile.highest_unlocked_stage()==5,"campaign caps at five")
 check(button("Next Stage")==null,"final stage offers no nonexistent next")
 check(game.profile.campaign_records.size()==5,"five completion records")
 for stage in ["campaign_write","campaign_read"]:
  var output=[]
  var code=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/campaign_flow.gd","--",stage],output,true)
  check(code==0,"separate process "+stage+" succeeds: "+str(output))
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("CAMPAIGN_FLOW_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
