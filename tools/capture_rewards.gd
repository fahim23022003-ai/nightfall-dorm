extends SceneTree
# Prepared isolated fixtures; actual production transactions/rendering, not balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/rewards/"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1;push_error("REWARDS RENDER: "+label)
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
 print("REWARDS_CAPTURE ",name)
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
func reset_profile(xp=0):
 game.return_menu()
 game.profile=PlayerProfile.new("user://rewards-render-"+str(Time.get_ticks_usec())+".json")
 game.profile.xp=xp
 game.profile.save_profile()
 game.campaign_mode=false
 game.ui.progression.difficulty="standard"
 return game.profile
func record(stage):
 return {"clears":1,"best_time":180.0,"best_damage":2000.0,"best_xp":200,"difficulty":"hell","first_match_id":1}
func match_fixture(stage,mode):
 check(game.start_stage(stage,mode),"real stage starts "+stage)
 game.set_process(false)
 game.tutorial_enabled=false
 var m=game.model
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+120;m.player().occupied_seconds=120;m.player().damage_dealt=200
 m.bot_claimed=5;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.cooldown=100
 game.focus_camera(true)
 return m
func win(m):
 m.hunter.hurt(10000000);m.tick(.01);game._process(0)
 check(game.mode=="result" and not game.last_progression.is_empty(),"real victory and saved settlement")
func text_exists(value):
 for c in game.ui.panel.get_children():
  if c is Label and c.text.contains(value):return true
 return false
func buttons(value):
 var out=[]
 for c in game.ui.panel.get_children():
  if c is Button and c.text==value:out.append(c)
 return out
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://rewards-render-initial-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame;game.set_process(false);root.size=Vector2i(1280,720)
 var recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 var p=reset_profile()
 game.ui.progression.show_loadout();await capture("render-01-bronze-loadout")
 check(p.perk_slots()==1 and not p.equip("reaper_slayer"),"locked Mythic cannot equip")
 p=reset_profile(3800)
 check(p.equip("pocket") and p.equip("dreamer"),"Master two equipped")
 p.inventory={"repair":2,"gold":2};check(p.equip_item("repair") and p.equip_item("gold"),"separate two consumable slots")
 game.ui.progression.show_loadout();await capture("render-02-master-two-perks");check_loadout_layout()
 check(p.equipped.size()==2,"two permanent slots")
 var equipped_buttons=buttons("Equipped ✓")
 await click(equipped_buttons[0]);check(p.equipped.size()==1,"real remove equipped")
 await click(buttons("Equip")[1]);check(p.equipped.size()==2,"real replacement")
 await capture("render-03-perk-replacement")
 p=reset_profile(8000)
 game.ui.progression.show_loadout();await capture("render-04-mythic-requirements-locked")
 check(p.rank_index()==5 and not p.equip("reaper_slayer"),"XP only not Mythic")
 p.statistics={"matches":3,"victories":3,"defeats":0,"standard":0,"hard":3,"hell":0,"reaper_defeats":3};p.next_match_id=2
 for stage in ["stage_1","stage_2","stage_3","stage_4","stage_5"]:p.campaign_records[stage]=record(stage)
 p.highest_rank=p.rank_index();p.save_profile()
 check(p.equip("marksman") and p.equip("reaper_slayer"),"earned Mythic offense selection")
 game.ui.progression.show_loadout();await capture("render-05-mythic-offense");check_loadout_layout()
 root.size=Vector2i(960,540);await capture("render-06-mythic-loadout-small");check_loadout_layout();root.size=Vector2i(1280,720)
 game.ui.progression.show_ranks();await capture("render-07-ranks-seven-perks")
 p=reset_profile(240)
 var m=match_fixture("stage_1","hell")
 win(m);await advance(1.7);await capture("render-08-legitimate-stage-results")
 check(p.achievements.has("first_victory"),"actual win achievement earned")
 check(not p.pending_stage_bonus.is_empty(),"actual firstclear stage offer")
 await click(find_button("Lucky Spin · reveal earned item"));await advance(.25);await capture("render-09-spin-preserved")
 await click(find_button("Skip animation"));await capture("render-10-reward-reveal")
 await click(find_button("Save reveal & continue"));await advance(1.1);await capture("render-11-stage-reward-gate")
 if find_button("Choose stage bonus")!=null:await click(find_button("Choose stage bonus"))
 else:game.ui.progression.show_stage_bonus()
 await capture("render-12-three-stage-choices")
 root.size=Vector2i(960,540);await capture("render-13-stage-choices-small");root.size=Vector2i(1280,720)
 var select=buttons("Select");check(select.size()==3,"exact three choices")
 if select.size()!=3:quit(1);return
 await click(select[1]);await capture("render-14-economic-selected")
 check(p.pending_stage_bonus.choice=="economic" and not p.choose_stage_bonus("battle"),"selection unique")
 var reload=PlayerProfile.new(p.path);check(reload.load_profile() and reload.pending_stage_bonus.choice=="economic","selection reload")
 await click(find_button("Continue to loadout"));await capture("render-15-next-stage-loadout")
 await click(find_button("Start Match"));m=game.model
 check(m.stage_id=="stage_2" and p.pending_stage_bonus.is_empty(),"target stage consumed offer")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();game.focus_camera(true)
 check(is_equal_approx(m.player().gold,50.0+RankCatalog.bonuses(p.equipped).gold),"economic actual starting gold")
 game.ui.update_match()
 await capture("render-16-next-stage-economic-effect")
 game.return_menu();game.ui.progression.achievement_page=0;game.ui.progression.show_achievements()
 await capture("render-17-earned-achievements")
 var oldxp=p.xp;var stock=int(p.inventory.get("repair",0))
 await click(buttons("Claim reward")[0]);await capture("render-18-claimed-achievement")
 check(p.xp==oldxp+15 and int(p.inventory.get("repair",0))==stock+1,"actual achievement XP inventory")
 check(not p.claim_achievement("first_victory"),"duplicate claim blocked")
 reload=PlayerProfile.new(p.path);check(reload.load_profile() and reload.achievements.first_victory.claimed,"claim persisted")
 await click(find_button("Next achievements"));await capture("render-19-achievement-second-page")
 root.size=Vector2i(960,540);await capture("render-20-achievements-small");root.size=Vector2i(1280,720)
 game.profile.update_setting("reduced_effects",true)
 game.ui.progression.show_achievements();await capture("render-21-reduced-achievements")
 p=reset_profile(7950)
 p.statistics={"matches":2,"victories":2,"defeats":0,"standard":0,"hard":2,"hell":0,"reaper_defeats":2};p.next_match_id=2
 for stage in ["stage_1","stage_2","stage_3","stage_4"]:p.campaign_records[stage]=record(stage)
 p.save_profile();m=match_fixture("stage_5","hell");m.hunter.transformed=true
 win(m);await advance(1.8);await capture("render-22-mythic-perk-unlocked")
 check(p.rank_index()==6,"real settlement Mythic gates")
 await advance(.5);recording.set_recording_active(false)
 var mix=recording.get_recording();check(mix!=null and mix.data.size()>1000,"actual engine mix")
 if mix!=null:check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-rewards-mix.wav"))==OK,"saved engine audio")
 for cue in ["perk_unlocked","achievement_unlocked","achievement_claim","difficult_stage","stage_bonus_selected","mythic_perk"]:check(game.audio_system.event_counts.get(cue,0)>0,"real cue "+cue)
 print("REWARDS_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("REWARDS_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.3).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)

func check_loadout_layout():
 var icons=0
 for c in game.ui.panel.get_children():
  if c.is_queued_for_deletion():continue
  if c is TextureRect and c.texture!=null and c.texture.resource_path.contains("/perks/"):
   icons+=1;check(c.size==Vector2(40,40),"perk icon uses requested40px")
  if c is Label and c.text.contains("\n"):
   for b in game.ui.panel.get_children():
    if b is Button and not b.is_queued_for_deletion():check(not c.get_rect().intersects(b.get_rect()),"perk text stays outside buttons")
 check(icons==7,"all seven original perk icons")
