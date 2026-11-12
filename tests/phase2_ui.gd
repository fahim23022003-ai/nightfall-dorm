extends SceneTree
var assertions=0
var failures=0
var game
var save_path=""

func check(ok: bool,label: String):
 assertions+=1
 if not ok:
  failures+=1
  push_error("PHASE2_UI_FAIL: "+label)

func button_named(text: String,min_x=-10000):
 for node in game.ui.panel.get_children():
  if node is Button and node.text==text and node.visible and not node.is_queued_for_deletion() and node.get_global_rect().position.x>=min_x:
   return node
 return null

func has_label(fragment):
 for node in game.ui.panel.get_children():
  if node is Label and not node.is_queued_for_deletion() and fragment in node.text: return true
 return false

func click(point):
 var physical=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new()
 motion.position=physical
 motion.global_position=physical
 Input.parse_input_event(motion)
 await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=physical
  event.global_position=physical
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame

func click_button(text,min_x=-10000):
 var target=button_named(text,min_x)
 check(target!=null,"real button exists: "+text)
 if target!=null: await click(target.get_global_rect().get_center())

func clean_files():
 var directory=DirAccess.open("user://")
 if directory==null: return
 for name in directory.get_files():
  if name.begins_with(save_path.trim_prefix("user://")):
   DirAccess.remove_absolute("user://"+name)

func _initialize():
 save_path="user://qa-phase2-ui-"+str(Time.get_ticks_usec())+".json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH",save_path)
 call_deferred("run")

func run():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 check(game.profile.path==save_path,"scene uses isolated QA save override")
 check(has_label("Bronze") and has_label("0 XP"),"fresh menu displays rank and XP")
 await click_button("Ranks & rewards")
 check(has_label("BRONZE") and has_label("PERMANENT PERKS"),"actual rank button opens rank/reward screen")
 check(has_label("250 XP to Silver") and has_label("Reinforced frame · Silver required"),"rank screen identifies next available reward")
 var badges=0
 for node in game.ui.panel.get_children():
  if node is TextureRect and not node.is_queued_for_deletion():
   check(node.texture!=null,"rank badge texture exists")
   badges+=1
 check(badges>=8,"all seven rank badges plus current rank rendered as real texture controls")
 for rank_name in RankCatalog.NAMES:
  check(has_label(rank_name),"rank screen names existing rank "+rank_name)
 var rescue_description=false
 for node in game.ui.panel.get_children():
  if node is Button and not node.is_queued_for_deletion() and "Cannot revive" in node.tooltip_text: rescue_description=true
 check(rescue_description,"rank screen retains complete rescue description in perk tooltip")
 await click_button("Choose loadout")
 check(game.ui.current_screen=="loadout" and game.campaign_mode,"rank loadout opens current stage preparation")
 for node in game.ui.panel.get_children():
  if node is Label and not node.is_queued_for_deletion() and "Cannot revive" in node.text:
   check(node.size.x<=370,"loadout description does not overlap equipped/locked buttons")
 var locked=button_named("Gold")
 check(locked!=null and locked.disabled,"Gold reward is visibly locked at Bronze")
 var prior=game.profile.equipped.duplicate()
 if locked!=null: await click(locked.get_global_rect().get_center())
 check(game.profile.equipped==prior,"actual click on locked reward cannot equip")
 await click_button("Equip")
 check(game.profile.equipped==["pocket"],"actual equip click persists unlocked Bronze perk")
 var loaded=PlayerProfile.new(save_path)
 check(loaded.load_profile() and loaded.equipped==["pocket"],"loadout survives fresh profile instance")
 await click_button("Back")
 await click_button("Main menu")
 await click_button("Settings")
 for setting in ["music","effects","ambient"]:
  var slider=game.ui.panel.get_node_or_null(setting+"_volume")
  check(slider is HSlider,"separate volume control exists: "+setting)
  if slider is HSlider:
   await click(slider.get_global_rect().position+Vector2(slider.size.x*0.30,slider.size.y*0.5))
   check(absf(game.profile.settings[setting]-0.30)<0.06,"actual slider click changes persistent "+setting)
 var muted=game.ui.panel.get_node_or_null("muted")
 check(muted is CheckButton,"mute toggle exists")
 if muted is CheckButton: await click(muted.get_global_rect().get_center())
 check(game.profile.settings.muted,"actual mute toggle updates settings")
 loaded=PlayerProfile.new(save_path)
 check(loaded.load_profile() and loaded.settings.muted,"mute survives reload")
 for setting in ["music","effects","ambient"]:
  check(is_equal_approx(loaded.settings[setting],game.profile.settings[setting]),"separate mix value survives reload: "+setting)
 await click_button("Back")
 # A rank fixture isolates unlocking and slot replacement UI, not earned-play XP.
 game.profile.xp=250
 game.profile.save_profile()
 game.ui.show_menu()
 await process_frame
 check(has_label("Silver"),"menu shows promoted profile rank")
 await click_button("Start Game")
 await click_button("Prepare")
 await click_button("Equip",1000)
 check(game.profile.equipped==["reinforced"],"second unlocked perk replaces one equipped slot")
 game.profile.xp=690
 game.profile.save_profile()
 await click_button("Long night")
 check(game.ui.progression.difficulty=="hard","actual difficulty choice records hard mode")
 await click_button("Start Match")
 check(game.mode=="match" and game.model.difficulty=="hard" and game.match_id>0,"actual Start Night launches persisted match snapshot")
 check(game.profile.active_match.equipped==["reinforced"],"active match freezes selected loadout")
 game.model.claim_room(0)
 check(is_equal_approx(game.model.player().max_hp(),Catalog.DOOR_HP[0]*1.05),"UI-selected perk changes actual door HP")
 game.profile.equip("pocket")
 check(is_equal_approx(game.model.player().max_hp(),Catalog.DOOR_HP[0]*1.05),"future loadout changes do not alter active room")
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 game.model.time=game.model.preparation+30
 game.model.player().occupied_seconds=30
 game.model.player().damage_dealt=100
 game.model.player().door_damage_taken=100
 game.model.hunter.hp=0
 game.model.hunter.state=HunterState.State.DEAD
 game.model.result="victory"
 # Exercise real controller terminal handling once; menu/fixtures remain otherwise frozen.
 game._process(0.01)
 await process_frame
 check(game.mode=="result" and not game.last_progression.is_empty(),"terminal controller produces actual progression summary")
 check(has_label("Base 120") and has_label("Difficulty +"),"post-match points breakdown is transparent")
 check(game.last_progression.get("promoted",false) and has_label("PROMOTED") and has_label("Silver → Gold"),"real settlement drives visible old-to-new rank promotion summary")
 await create_timer(1.7).timeout
 check(has_label("690 → %d XP" % game.profile.xp),"animated result reaches exact saved old/new XP")
 var final_xp=game.profile.xp
 game._process(0.01)
 loaded=PlayerProfile.new(save_path)
 check(loaded.load_profile() and loaded.xp==final_xp,"awarded points persist without duplicate terminal processing")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await create_timer(0.2).timeout
 clean_files()
 print("PHASE2_UI_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
