extends "res://tools/phase21/capture_ui.gd"
## Compare the same earned Story slot across preparation, lobby and live HUD.
## The temporary profile seeds chapter progress only; both buttons use real input.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or not args[0].is_absolute_path() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 destination=args[0]
 quality=args[1]
 viewport_size=Vector2i(960,540) if quality=="low" else Vector2i(1280,720)
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=viewport_size
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase221-identity-%d.json" % Time.get_ticks_usec())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game.profile.complete_tutorial()
 game.profile.story.seed_base=1527205665
 game.change_setting("graphics_quality",quality)
 game.ui.show_menu()
 await shop_probe()
 await story_probe("standard",1)
 await story_probe("hell",2)
 await story_probe("hell",50)
 await finish()

func shop_probe():
 var profile: PlayerProfile=game.profile
 profile.rm_cash=0
 await press("menu_shop",game.ui.panel)
 var price: Button=game.ui.panel.get_node("shop_buy_repair")
 check(price.disabled and price.text=="18 RM · Need 18 more RM","actual price and shortfall")
 check(price.get_theme_font_size("font_size")>=18,"Low-readable shop price")
 await still("shop-shortfall")
 await key(KEY_ESCAPE)
 profile.rm_cash=20
 await press("menu_shop",game.ui.panel)
 await press("shop_buy_repair",game.ui.panel)
 check(profile.rm_cash==2 and profile.inventory.get("repair",0)>0,"paid amount and granted stock agree")
 await key(KEY_ESCAPE)

func story_probe(difficulty: String,level: int):
 game.return_menu()
 var profile: PlayerProfile=game.profile
 profile.active_match.clear()
 profile.next_match_id=maxi(profile.next_match_id,level)
 profile.story=StoryProgress.fresh(1527205665)
 for cleared in range(1,level):
  StoryProgress.settle(profile.story,difficulty,cleared,true,cleared)
 check(StoryProgress.valid(profile.story),"isolated level %d profile is valid" % level)
 await press("mode_story",game.ui.panel)
 await press("StoryDifficulty_"+difficulty,game.ui.panel)
 check(profile.selected_difficulty==difficulty and profile.save_ok,"selected difficulty persisted in the test profile")
 var mission:=StoryCatalog.mission(level)
 var policy:=StoryCatalog.reaper_policy(mission,difficulty)
 var name:=HunterIdentity.display(mission.archetype)
 var objective: Label=game.ui.panel.get_node("StoryObjective")
 var encounter: Label=game.ui.panel.get_node("StoryEncounterTiming")
 var objective_text := objective.text
 check(name in objective_text,"preparation gives the opening Hunter's actual display name")
 check(("The Final Reaper" in encounter.text)==policy.enabled,"separate transformation description matches policy")
 for label: Label in [objective,game.ui.panel.get_node("StoryBriefing"),encounter]:
  check(label.get_line_count()==label.get_visible_line_count(),str(label.name)+" fits after wrapping")
 var fixture: String="%s-%02d" % [difficulty,level]
 await still(fixture+"-prep")
 var lobby=await open_prepared_lobby()
 if not is_instance_valid(lobby):return
 var lobby_name: String=lobby._hunter_title
 check(lobby_name==name and lobby._mission.level==level,"lobby shows the prepared Hunter for the same Story level")
 await still(fixture+"-lobby")
 await press("LobbyReady",lobby)
 advance(lobby,7.0)
 advance(lobby,.5)
 await process_frame
 await process_frame
 check(game.mode=="match" and game.model.story_level==level and game.model.difficulty==difficulty,"Start Match and Ready launch selected stage and difficulty")
 game._process(.07)
 check(game.profile.active_match.archetype==mission.archetype and game.model.hunter.archetype==mission.archetype,"profile and Hunter retain same fixed archetype")
 check(game.model.map_seed==StoryProgress.seed_for(profile.story,level),"launch uses the same Story seed")
 check(game.model.hunter.boss_policy.enabled==policy.enabled,"model uses the separately announced transformation policy")
 var hud_name: String=game.ui.hunter_label.text.get_slice("  ·  ",0)
 check(hud_name==name,"match HUD uses the prepared and previewed Hunter name")
 presets[fixture]={"mission_seed":game.model.map_seed,"hunter_id":mission.archetype,"preparation":objective_text,"lobby":lobby_name,"match":hud_name,"reaper_enabled":policy.enabled}
 await still(fixture+"-match")
