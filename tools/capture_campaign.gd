extends SceneTree
# Prepared progression/render/input fixtures, not naturally won campaign matches.
var game
var failures=0
var checks=0
var output="res://docs/evidence/campaign/"
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("CAMPAIGN RENDER: "+label)
func capture(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var result=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("CAMPAIGN_CAPTURE ",name," size=",image.get_size()," code=",result)
 check(result==OK,"image saved "+name)
func button_named(name: String):
 for child in game.ui.panel.get_children():
  if child is Button and child.text==name and not child.is_queued_for_deletion(): return child
 return null
func click(button):
 check(button!=null,"expected button exists")
 if button==null: return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for down in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=down
  Input.parse_input_event(e)
  await process_frame
func result_fixture(id: String,win=true,difficulty="standard"):
 check(game.start_stage(id,difficulty),"fixture stage starts "+id)
 game.set_process(false)
 game.model.claim_room(1)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 game.model.time=game.model.preparation+40
 game.model.player().occupied_seconds=40
 game.model.player().damage_dealt=500
 game.model.hunter.hp=0 if win else 100
 game.model.result="victory" if win else "defeat"
 game._process(0.0)
 check(game.mode=="result","actual result transition")
 check(not game.last_progression.is_empty(),"actual eligible settlement")
 await create_timer(1.4).timeout
func run():
 var profile="user://campaign-render-fixture.json"
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(profile+suffix): DirAccess.remove_absolute(profile+suffix)
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.size=Vector2i(1280,720)
 game.ui.campaign.show_stages()
 await capture("01-new-campaign-locked")
 var locked=button_named("Locked")
 await click(locked)
 check(game.ui.current_screen=="stages","locked button cannot navigate")
 check(game.ui.campaign.prepare("stage_1"),"unlocked stage prepares")
 await capture("02-stage1-bronze-preparation")
 game.profile.xp=3800 # Visual fixture to inspect all legitimate rank options.
 for perk in RankCatalog.PERKS:
  game.profile.equip(perk.id)
  game.ui.progression.difficulty="hard" if perk.rank%2 else "standard"
  game.ui.progression.show_loadout()
  await capture("03-preparation-"+perk.id)
 check(game.profile.equipped.size()==1,"one-slot selections remain enforced")
 await result_fixture("stage_1")
 check(game.profile.stage_unlocked("stage_2"),"first clear unlocks next")
 await capture("04-stage1-victory-next")
 await click(button_named("Next Stage"))
 check(game.ui.current_screen=="loadout" and game.profile.selected_stage=="stage_2","real Next Stage button opens next preparation")
 await capture("05-stage2-preparation")
 await result_fixture("stage_2",false)
 await capture("06-stage2-defeat-retry")
 await click(button_named("Retry Stage"))
 check(game.mode=="match" and game.model.stage_id=="stage_2","real Retry Stage button restarts same stage")
 game.return_menu()
 game.ui.campaign.show_stages()
 await capture("07-cleared-best-record")
 root.size=Vector2i(960,600)
 await process_frame
 game.ui.campaign.show_stages()
 await capture("08-stage-select-960x540")
 game.ui.campaign.prepare("stage_2")
 await click(button_named("Long night"))
 check(game.profile.selected_difficulty=="hard" and game.ui.progression.difficulty=="hard","actual difficulty button persists independently")
 await capture("09-hard-preparation-960x540")
 for id in ["stage_2","stage_3","stage_4","stage_5"]:
  await result_fixture(id)
 await capture("10-campaign-complete-960x540")
 await click(button_named("Stage Select"))
 check(game.ui.current_screen=="stages","real result Stage Select navigates")
 await capture("11-all-stages-cleared-960x540")
 root.size=Vector2i(1280,720)
 game.profile.xp=RankCatalog.MAX_XP-1
 await result_fixture("stage_5",true,"hard")
 await capture("12-hard-xp-cap-result")
 root.size=Vector2i(960,600)
 await process_frame
 var saved_path=game.profile.path
 game.profile.path="user://campaign-render-missing-"+str(Time.get_ticks_usec())+"/profile.json"
 check(not game.profile.save_profile() and not game.profile.save_ok,"actual save failure induced with missing parent")
 game.ui.show_result()
 await create_timer(1.4).timeout
 await capture("13-save-failed-result-960x540")
 var retry=button_named("Save failed — retry")
 var main=button_named("Main menu")
 check(retry!=null and main!=null and not retry.get_global_rect().intersects(main.get_global_rect()),"save retry and main menu hitboxes separate")
 game.profile.path=saved_path
 await click(retry)
 check(game.profile.save_ok,"actual retry saves after path recovery")
 await create_timer(1.4).timeout
 await capture("14-save-retry-recovered-960x540")
 print("CAMPAIGN_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
