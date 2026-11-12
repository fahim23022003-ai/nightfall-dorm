extends SceneTree
# Prepared isolated fixtures; actual production transactions/rendering, not balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/legendary/"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1;push_error("LEGENDARY RENDER: "+label)
func advance(seconds):
 var start=Time.get_ticks_usec()
 var before=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec()
  var delta=(now-before)/1000000.0
  game.audio_system.update_state(delta,game.model,game.mode)
  game.presentation.update(delta,game.model)
  game.horror.update(delta,game.model)
  game.ui.items_ui.update(delta)
  if game.mode=="match":game.ui.update_match()
  game.queue_redraw()
  before=now
func capture(name):
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var code=root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+name+".png"))
 check(code==OK,"saved "+name)
 print("LEGENDARY_CAPTURE ",name)
func find_button(text,node=null):
 if node==null:node=game.ui.panel
 for child in node.get_children():
  if child is Button and child.text==text and not child.is_queued_for_deletion():return child
  var found=find_button(text,child)
  if found!=null:return found
 return null
func click(button):
 check(button!=null,"button exists")
 if button==null:return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame
func key(code):
 for pressed in [true,false]:
  var event=InputEventKey.new()
  event.physical_keycode=code
  event.keycode=code
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame
func fixture(ids):
 game.profile.item_loadout=[]
 for id in ids: check(game.profile.equip_item(id),"equip " + id)
 check(game.start_stage("stage_1","hell"),"real match starts")
 game.set_process(false)
 game.tutorial_enabled=false
 var m=game.model
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 game.profile.bind_items(m,game.match_id)
 m.player().door_level=4
 m.player().door_hp=m.player().max_hp()*.6
 m.time=m.preparation+120
 m.player().occupied_seconds=120
 m.player().damage_dealt=200
 m.player().electricity=1000
 m.bot_claimed=5
 m.hunter.target=0
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.position=m.player().door_approach()
 m.hunter.cooldown=100
 m.hunter.boss_policy.enabled=false
 for tile in range(m.player().tile_count()):
  if m.player().buildings.size()>=2:break
  if m.player().tile_position(tile).distance_to(m.hunter.position)>Catalog.BUILDINGS.turret.range:continue
  m.player().gold=1000
  m.player().build("turret",tile)
 game.focus_camera(true)
 game.ui.items_ui.update(0)
 return m
func finish(m,win):
 if win:m.hunter.hurt(10000000)
 else:m.player().alive=false
 m.tick(.01)
 game._process(0)
 check(game.mode=="result","actual results")
func activate(slot):
 await advance(.3)
 game.model.items.cooldown=0
 game.ui.items_ui.update(0)
 await key(KEY_1 if slot==0 else KEY_2)
 await advance(.15)
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://legendary-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 root.size=Vector2i(1280,720)
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.save_profile()
 game.ui.items_ui.inventory()
 await capture("render-01-original-inventory")
 await click(find_button("Advanced items →"))
 await capture("render-02-advanced-inventory")
 await click(find_button("Legendary items →"))
 check_inventory_layout()
 await capture("render-03-legendary-inventory")
 root.size=Vector2i(960,540)
 await capture("render-04-legendary-inventory-small")
 if "--inventory-only" in OS.get_cmdline_user_args():
  print("LEGENDARY_INVENTORY_CHECKS=",checks," FAILURES=",failures)
  game.audio_system.shutdown()
  await create_timer(.3).timeout
  game.queue_free()
  await process_frame
  quit(0 if failures==0 else 1)
  return
 root.size=Vector2i(1280,720)
 var record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 var m=fixture(["time_freeze","guardian_heart"])
 for seed in range(1,10000):
  var rng=RandomNumberGenerator.new()
  rng.seed=seed
  if ItemCatalog.legendary(ItemCatalog.roll("victory",rng)):
   game.profile.reward_rng.seed=seed;break
 finish(m,true)
 await advance(1.1)
 var receipt=game.profile.pending_spin()
 check(ItemCatalog.legendary(receipt.item),"actual settlement fixed Legendary reward")
 var reward_stock=game.profile.inventory[receipt.item]
 await click(find_button("Lucky Spin · reveal earned item"))
 await advance(.35)
 check_odds("victory")
 await capture("render-05-victory-exact-odds")
 await click(find_button("Skip animation"))
 await advance(.3)
 check(game.profile.inventory[receipt.item]==reward_stock,"skip does not grant twice")
 await capture("render-06-legendary-reveal")
 await click(find_button("Save reveal & continue"))
 check(game.profile.inventory[receipt.item]==reward_stock,"acknowledgement does not grant twice")
 m=fixture(["time_freeze","guardian_heart"])
 finish(m,false)
 await advance(1)
 await click(find_button("Lucky Spin · reveal earned item"))
 check_odds("defeat")
 await capture("render-07-consolation-quarter-percent-odds")
 await click(find_button("Skip animation"))
 await click(find_button("Save reveal & continue"))
 m=fixture(["time_freeze","guardian_heart"])
 var stock=game.profile.inventory.time_freeze
 await activate(0)
 check(game.profile.inventory.time_freeze==stock-1,"keyboard spends one Freeze")
 var point=m.hunter.position
 var cooldown=m.hunter.cooldown
 var gold=m.player().gold
 m.tick(.25)
 await advance(.15)
 var held_clock=game.presentation.hunter_clock
 await advance(.2)
 check(is_equal_approx(game.presentation.hunter_clock,held_clock),"Hunter animation clock held during Freeze")
 check(m.hunter.position==point and m.hunter.cooldown==cooldown,"Freeze stops actual Hunter actions")
 check(m.player().gold>gold,"economy remains active")
 check(game.ui.items_ui.hotbar[1].disabled,"shared Legendary budget disables Heart")
 check(not game.ui.items_ui.legendary_banner.get_global_rect().intersects(game.ui.warning_box.get_global_rect()),"Legendary banner does not obscure combat warning")
 await capture("render-08-time-freeze")
 game.ui.show_settings()
 await click(find_button("Reduced visual effects"))
 check(game.profile.settings.reduced_effects,"reduced effects selected")
 var reloaded=PlayerProfile.new(game.profile.path)
 check(reloaded.load_profile() and reloaded.settings.reduced_effects,"reduced effects persisted")
 game.ui.show_match()
 await advance(.1)
 await capture("render-09-freeze-reduced")
 root.size=Vector2i(960,540)
 await capture("render-10-freeze-small")
 root.size=Vector2i(1280,720)
 game.profile.update_setting("reduced_effects",false)
 m.tick(3)
 await advance(.15)
 check(not m.items.timers.has("time_freeze") and m.hunter.cooldown<cooldown,"Freeze expiry resumes actions")
 await capture("render-11-freeze-expired")
 m=fixture(["time_freeze","repair"])
 m.hunter.transformed=true
 m.hunter.cooldown=0
 m.hunter._boss_strike(m.player(),m)
 check(m.hunter.boss_attack!="","real Reaper telegraph opened")
 await activate(0)
 check(is_equal_approx(m.items.timers.time_freeze,1.5),"Reaper Freeze shorter")
 var warning=m.hunter.boss_attack
 var windup=m.hunter.cooldown
 m.tick(.5)
 await advance(.15)
 check(m.hunter.boss_attack==warning and m.hunter.cooldown==windup,"charged boss attack held")
 await capture("render-12-reaper-freeze")
 m.tick(1.1)
 check(m.hunter.cooldown<windup and m.hunter.boss_attack==warning,"charged boss attack resumes after Freeze")
 m=fixture(["reaper_seal","repair"])
 stock=game.profile.inventory.reaper_seal
 check(not game.activate_item(0),"invalid Seal rejected")
 check(game.profile.inventory.reaper_seal==stock and m.items.cooldown==0,"invalid Seal keeps stock and cooldown")
 await advance(.1)
 await capture("render-13-invalid-seal-feedback")
 m.hunter.transformed=true
 m.hunter.cooldown=0
 m.hunter._boss_strike(m.player(),m)
 var special=m.hunter.boss_attack
 var special_cooldown=m.hunter.boss_cooldowns[special]
 check(special!="","real special counter window")
 await advance(.15)
 await capture("render-14-reaper-counter-window")
 await activate(0)
 check(m.hunter.boss_attack=="" and game.profile.inventory.reaper_seal==stock-1,"valid Seal interrupts and spends one")
 check(m.hunter.boss_cooldowns[special]==special_cooldown,"Seal preserves special cooldown")
 check(game.ui.items_ui.feedback_label.text=="SPECIAL ATTACK INTERRUPTED!","exact Seal message")
 await capture("render-15-reaper-seal")
 m.tick(2)
 check(m.hunter.state!=HunterState.State.DEAD and m.hunter.target==0,"Seal leaves boss targeting valid")
 m=fixture(["guardian_heart","feather"])
 stock=game.profile.inventory.guardian_heart
 m.player().door_hp=10
 m.hunter._damage_door(m.player(),m,100)
 await advance(.15)
 check(game.profile.inventory.guardian_heart==stock-1 and m.player().door_hp>0 and m.player().alive,"actual lethal Heart rescue")
 check(game.ui.items_ui.feedback_label.text=="GUARDIAN HEART ACTIVATED!","exact Heart message")
 check(m.items.guardian_shield_hp>0 and m.items.legendary_used==1,"Heart finite shield and budget")
 await capture("render-16-guardian-heart")
 m.items.tick(.3,m)
 await advance(.1)
 await capture("render-16a-guardian-wings-expanded")
 game.profile.update_setting("reduced_effects",true)
 await capture("render-17-heart-reduced")
 game.profile.update_setting("reduced_effects",false)
 m.tick(3.1)
 check(m.items.guardian_shield_hp==0,"Heart shield expires")
 m=fixture(["cursed_fortune","repair"])
 gold=m.player().gold
 stock=game.profile.inventory.cursed_fortune
 await activate(0)
 check(m.player().gold==gold+500 and game.profile.inventory.cursed_fortune==stock-1,"Fortune exactly500G and one stock")
 check(game.ui.items_ui.feedback_label.text.contains("+500 GOLD"),"explicit Gold feedback")
 m.tick(.25)
 await advance(.15)
 await capture("render-18-cursed-fortune")
 root.size=Vector2i(960,540)
 await capture("render-19-fortune-small")
 root.size=Vector2i(1280,720)
 game.profile.update_setting("reduced_effects",true)
 await capture("render-20-fortune-reduced")
 game.profile.update_setting("reduced_effects",false)
 m.items.tick(20,m)
 m.items.tick(.01,m)
 m.hunter.tick(.01,m)
 await advance(.15)
 check(not m.items.timers.has("cursed_fortune"),"curse expires")
 await capture("render-21-expiry")
 await advance(.5)
 record.set_recording_active(false)
 var mix=record.get_recording()
 check(mix!=null and mix.data.size()>1000,"actual engine mix recorded")
 if mix!=null:check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-legendary-mix.wav"))==OK,"audio saved")
 for id in ["time_freeze","reaper_seal","guardian_heart","cursed_fortune","legendary_reveal"]:check(game.audio_system.event_counts.get("item_"+id,0)>0,"actual cue "+id)
 print("LEGENDARY_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("LEGENDARY_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
func check_odds(outcome):
 var found=false
 for child in game.ui.panel.get_children():
  if child is Label and child.text.contains("Time Freeze") and child.text.contains("%"):
   found=true
   check(child.text.split("\n").size()==20,"all20 odds visible")
   check(child.text.contains("Time Freeze "+("1.0%" if outcome=="victory" else "0.25%")),"exact Legendary odds "+outcome)
  if child is Label and child.text.begins_with("Common"):
   var width=child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
   check(width<=child.size.x,"rarity heading fits")
 check(found,"odds label found")

func check_inventory_layout():
 for child in game.ui.panel.get_children():
  if child is Label and child.tooltip_text!="":
   for button in game.ui.panel.get_children():
    if button is Button and button.text.begins_with("Equip"):
     check(not child.get_global_rect().intersects(button.get_global_rect()),"description does not overlap Equip")
