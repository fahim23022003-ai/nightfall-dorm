extends SceneTree
# Prepared isolated fixtures; actual production transactions/rendering, not balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/advanced-items/"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1;push_error("ADVANCED RENDER: "+label)
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
 print("ADVANCED_CAPTURE ",name)
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
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://advanced-items-render-"+str(Time.get_ticks_usec())+".json")
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
 root.size=Vector2i(960,540)
 await capture("render-03-advanced-inventory-small")
 root.size=Vector2i(1280,720)
 var record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 var m=fixture(["barricade","shield"])
 for seed in range(1,1000):
  var rng=RandomNumberGenerator.new()
  rng.seed=seed
  var chosen=ItemCatalog.roll("victory",rng)
  if ItemCatalog.ITEMS[chosen].rarity=="Epic": game.profile.reward_rng.seed=seed;break
 finish(m,true)
 await advance(1.2)
 await click(find_button("Lucky Spin · reveal earned item"))
 await advance(.35)
 for child in game.ui.panel.get_children():
  if child is Label and child.text.begins_with("Common "):
   var width=child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
   print("ADVANCED_ODDS_HEADER_WIDTH=",width," AVAILABLE=",child.size.x)
   check(width<=child.size.x,"three rarity header fits")
 await capture("render-04-three-rarity-wheel-odds")
 await click(find_button("Skip animation"))
 await capture("render-05-epic-reveal")
 await click(find_button("Save reveal & continue"))
 m=fixture(["barricade","shield"])
 await activate(0)
 await activate(1)
 m.hunter.cooldown=0
 var hp=m.player().door_hp
 m.hunter.tick(.01,m)
 check(m.player().door_hp==hp,"shield absorbs mitigated attack")
 await advance(.15)
 await capture("render-06-barricade-shield-combination")
 game.ui.show_settings()
 await click(find_button("Reduced visual effects"))
 await capture("render-07a-reduced-effects-setting")
 game.ui.show_match()
 await capture("render-07-reduced-effects")
 check(game.profile.settings.reduced_effects,"reduced effect setting saves")
 var loaded=PlayerProfile.new(game.profile.path)
 check(loaded.load_profile() and loaded.settings.reduced_effects,"reduced effect setting survives reload")
 game.profile.update_setting("reduced_effects",false)
 m=fixture(["feather","repair"])
 m.player().door_hp=m.player().max_hp()*.26
 await advance(.3)
 m.hunter.cooldown=0
 var stock=game.profile.inventory.feather
 m.hunter.tick(.01,m)
 check(m.items.feather_used and game.profile.inventory.feather==stock-1,"actual critical crossing uses feather once")
 await advance(.15)
 await capture("render-08-feather-rescue")
 m=fixture(["inferno","overdrive"])
 m.hunter.transformed=true # Explicit presentation/resistance fixture, not a natural transformation.
 await activate(0)
 await activate(1)
 m._turrets(.1)
 m._advance_projectiles(1)
 var hunter_hp=m.hunter.hp
 m.items.tick(1,m)
 check(m.items.burn_remaining>0 and m.hunter.hp<hunter_hp,"owned projectile ignites actual burn")
 await advance(.15)
 await capture("render-09-inferno-burn")
 m=fixture(["pillow","coupon"])
 await activate(0)
 var rate=m.player().income_rate()
 check(m.player().temporary_income==1.5,"pillow actual income modifier")
 m.tick(1)
 await advance(.15)
 await capture("render-10-pillow-income")
 var stock_coupon=game.profile.inventory.coupon
 await activate(1)
 check(game.profile.inventory.coupon==stock_coupon and m.player().coupon_armed,"coupon arms without consumption")
 var coupon_tile=0
 while m.player().buildings.has(coupon_tile):coupon_tile+=1
 game.selected_tile=coupon_tile
 game.begin_placement("turret")
 game.ui.refresh_context()
 check(game.ui.confirmation_details.text.contains("COUPON"),"coupon preview clearly displayed")
 await capture("render-11-coupon-price-preview")
 var gold=m.player().gold
 check(game.confirm_placement(),"actual discounted building purchase")
 check(game.profile.inventory.coupon==stock_coupon-1,"coupon consumed on purchase")
 var refund=m.player().building_refund(coupon_tile)
 check(is_equal_approx(refund.x,Catalog.BUILDINGS.turret.gold*.3),"refund is half actual discounted investment")
 game.ui.close_context()
 await advance(.15)
 await capture("render-12-coupon-purchase")
 m=fixture(["decoy","smoke"])
 m.hunter.position=m.map_data.hunter_spawn
 await activate(0)
 var before=m.hunter.position
 m.hunter.tick(.5,m)
 check(m.hunter.position!=before,"decoy causes actual movement")
 await capture("render-13-decoy-navigation")
 m=fixture(["smoke","rescue"])
 var other=m.rooms[1]
 other.owner=1;other.alive=true;other.sleeping=true;other.closed=true
 other.door_hp=other.max_hp()*.4
 await activate(0)
 check(m.hunter.target!=0,"smoke retargets another valid room")
 await capture("render-14-shadow-smoke")
 m.items.cooldown=0
 game.ui.items_ui.update(0)
 await key(KEY_2)
 await capture("render-15-rescue-selection")
 # Select through the production targeting controller; UI button text is discovered.
 var selected_button=null
 for child in game.ui.panel.get_children():
  if child is Button and (child.text.contains("Room 2") or child.text.contains(other.survivor_name())):selected_button=child;break
 var before_hp=other.door_hp
 await click(selected_button)
 check(other.door_hp>before_hp,"selected teammate receives actual healing")
 await advance(.15)
 game.full_map=true
 game.focus_camera(true)
 await capture("render-16-team-rescue")
 root.size=Vector2i(960,540)
 await capture("render-17-team-rescue-small")
 root.size=Vector2i(1280,720)
 m.items.tick(30,m)
 await advance(.15)
 await capture("render-18-expiry")
 check(m.items.timers.is_empty(),"temporary effects cleaned up")
 m=fixture(["pillow","coupon"])
 finish(m,false)
 await advance(1.2)
 await click(find_button("Lucky Spin · reveal earned item"))
 await click(find_button("Skip animation"))
 await click(find_button("Save reveal & continue"))
 await advance(1)
 await click(find_button("Retry Stage"))
 check(game.mode=="match" and game.model.items.timers.is_empty(),"actual Retry resets advanced effects")
 m=game.model
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 var cue_before=int(game.audio_system.event_counts.get("item_pillow",0))
 await activate(0)
 check(int(game.audio_system.event_counts.get("item_pillow",0))==cue_before+1,"advanced cue restarts after real Retry")
 await capture("render-19-retry-clean-activation")
 record.set_recording_active(false)
 var mix=record.get_recording()
 check(mix!=null and mix.data.size()>1000,"actual engine mix recorded")
 if mix!=null:check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-advanced-mix.wav"))==OK,"audio saved")
 for id in ["barricade","feather","inferno","pillow","coupon","decoy","rescue","smoke"]:check(game.audio_system.event_counts.get("item_"+id,0)>0,"actual activation cue "+id)
 print("ADVANCED_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("ADVANCED_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
