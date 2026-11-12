extends SceneTree
# Prepared isolated fixtures; actual production transactions/rendering, not balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/items/"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1;push_error("ITEM RENDER: "+label)
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
 print("ITEM_CAPTURE ",name)
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
 m.player().door_level=4
 m.player().door_hp=m.player().max_hp()*.6
 m.time=m.preparation+120
 m.player().occupied_seconds=120
 m.player().damage_dealt=200
 m.bot_claimed=5
 m.hunter.target=0
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.position=m.player().door_approach()
 m.hunter.cooldown=100
 m.hunter.boss_policy.enabled=false
 for tile in [0,1]:
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
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://items-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 root.size=Vector2i(1280,720)
 for id in ItemCatalog.IDS:game.profile.inventory[id]=5
 game.profile.save_profile()
 game.ui.items_ui.inventory()
 await capture("render-01-inventory")
 for i in range(8):
  var text=ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity+" · "+ItemCatalog.ITEMS[ItemCatalog.IDS[i]].description
  for child in game.ui.panel.get_children():
   if child is Label and child.text==text:
    var width=child.get_theme_font("font").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
    print("ITEM_DESCRIPTION_WIDTH ",ItemCatalog.IDS[i]," width=",width," available=",child.size.x)
 root.size=Vector2i(960,540)
 await capture("render-02-inventory-small")
 root.size=Vector2i(1280,720)
 var record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 var m=fixture(["repair","gold"])
 finish(m,true)
 await advance(1.2)
 await capture("render-03-victory-result-spin-gate")
 var reward=game.profile.pending_spin()
 var stock=game.profile.inventory[reward.item]
 await click(find_button("Lucky Spin · reveal earned item"))
 await advance(.4)
 await capture("render-04-victory-wheel")
 await click(find_button("Skip animation"))
 check(game.ui.items_ui.spin_ready,"skip reveals")
 await capture("render-05-victory-reveal")
 await click(find_button("Save reveal & continue"))
 check(game.profile.pending_spins.is_empty() and game.profile.inventory[reward.item]==stock,"reveal never awards twice")
 m=fixture(["repair","gold"])
 finish(m,false)
 await advance(1.2)
 await click(find_button("Lucky Spin · reveal earned item"))
 await advance(2.7)
 await capture("render-06-consolation-reveal")
 await click(find_button("Save reveal & continue"))
 await advance(1.0)
 await click(find_button("Retry Stage"))
 check(game.mode=="match" and game.model.items.events.is_empty(),"real Retry resets temporary item state")
 m=game.model
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 m.player().door_hp=m.player().max_hp()*.5
 var cue_before=int(game.audio_system.event_counts.get("item_repair",0))
 await key(KEY_1)
 await advance(.2)
 check(int(game.audio_system.event_counts.get("item_repair",0))==cue_before+1,"actual Retry activation cue is observed afresh")
 await capture("render-07b-retry-clean-activation")
 game.ui.campaign.prepare("stage_1")
 await capture("render-07-loadout-inventory-link")
 for pair in [["repair","gold"],["battery","radar"],["shield","overdrive"],["frost","trap"]]:
  m=fixture(pair)
  for slot in range(2):
   var id=pair[slot]
   var before=int(game.profile.inventory[id])
   m.items.cooldown=0
   if id=="trap": m.hunter.position+=Vector2(80,0)
   if id=="frost":m.hunter.transformed=true
   game.ui.items_ui.update(0)
   if slot==0:await key(KEY_1)
   else:await click(game.ui.items_ui.hotbar[1])
   game.ui.items_ui.update(0)
   check(int(game.profile.inventory[id])==before-1,"real activation consumes once "+id)
   await key(KEY_1 if slot==0 else KEY_2)
   check(int(game.profile.inventory[id])==before-1,"repeated input blocked "+id)
   game.ui.feedback_until=0
   for e in m.items.events:e.age=.15
   await advance(.2)
   if id=="overdrive": m._turrets(.1)
   await capture("render-08-"+id+"-activation")
   if id=="shield":
    var hp=m.player().door_hp
    m.hunter.cooldown=0
    m.hunter.tick(.01,m)
    check(m.player().door_hp==hp and m.items.shield_hp<m.player().max_hp()*.3,"actual shield absorbs attack")
    await advance(.2)
    await capture("render-09-shield-absorb")
   if id=="radar":
    check(game.ui.items_ui.radar_label.text.contains("Target"),"radar displays target")
    root.size=Vector2i(960,540)
    await capture("render-10-radar-small")
    root.size=Vector2i(1280,720)
   if id=="trap":
    var hp=m.hunter.hp
    m.hunter.position=m.items.trap.position
    m.items.tick(.01,m)
    check(m.items.trap.is_empty() and m.hunter.hp<hp,"trap deals damage once")
    await advance(.2)
    await capture("render-11-trap-explosion")
  m.items.tick(50,m)
  await advance(.2)
  await capture("render-12-expired-"+pair[0])
  check(m.items.timers.is_empty(),"temporary effects end")
  if "radar" in pair:check(game.ui.items_ui.radar_label.text=="","radar information clears on expiry")
 record.set_recording_active(false)
 var mix=record.get_recording()
 check(mix!=null and mix.data.size()>1000,"actual engine audio recorded")
 if mix!=null:check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-item-mix.wav"))==OK,"audio saved")
 for id in ItemCatalog.IDS:check(game.audio_system.event_counts.get("item_"+id,0)>0,"activation sound "+id)
 check(game.audio_system.event_counts.get("item_reveal",0)>0,"reveal sound")
 print("ITEM_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("ITEM_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
