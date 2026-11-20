extends "res://tools/capture_visual_rebirth.gd"
## Native desktop controls with an isolated profile and a prepared Endless room.

func control(id: String) -> Button:
 return game.ui.panel.get_node_or_null(id) as Button

func run():
 var args:=OS.get_cmdline_user_args()
 if args.is_empty() or args.size()>2 or not args[0].is_absolute_path() or (args.size()==2 and args[1] not in ["fallback","compact"]):
  push_error("Pass an absolute evidence directory and optionally fallback or compact after --.")
  quit(2)
  return
 var destination:=args[0].trim_suffix("/")
 DirAccess.make_dir_recursive_absolute(destination)
 phase=destination.get_file()
 output=destination.get_base_dir()+"/"
 var compact:=args.size()==2 and args[1]=="compact"
 root.size=Vector2i(960,540) if compact else Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 if args.size()==2 and not compact:
  await _fallback()
  return
 if compact:
  check(root.get_texture().get_image().get_size()==Vector2i(960,540),"native compact viewport")
  await click(control("mode_story"))
  await _render_frame()
  check(game.ui.current_screen=="story_prepare","compact Story Preparation remains clickable")
  await capture("compact-story-preparation")
  game.return_menu()
 check(game.ui.use_living_ui(),"Survivor preview uses the premium desktop menu")
 game.profile.rm_cash=40
 game.ui.show_menu()
 await _render_frame()
 check(is_instance_valid(control("mode_story")),"Story menu control")
 check(is_instance_valid(control("mode_endless")),"Endless menu control")
 await capture("main-menu-720")
 await click(control("menu_shop"))
 await _render_frame()
 check(game.ui.current_screen=="shop","Shop reached through its button")
 await capture("shop-720")
 var stock: int=game.profile.inventory.get("repair",0)
 await click(control("shop_buy_repair"))
 await _render_frame()
 check(game.profile.rm_cash==22 and int(game.profile.inventory.get("repair",0))==stock+1,"Real RM Cash button purchases exactly one item")
 await capture("shop-purchase-720")
 await click(control("shop_back"))
 await _render_frame()
 await click(control("menu_inventory"))
 await _render_frame()
 check(game.ui.current_screen=="inventory","Inventory reached through its button")
 await click(control("inventory_equip_repair"))
 await _render_frame()
 check("repair" in game.profile.item_loadout,"Real inventory equip callback")
 await capture("inventory-720")
 await click(control("inventory_back"))
 await _render_frame()
 await click(control("menu_settings"))
 await _render_frame()
 check(game.ui.current_screen=="settings","Settings reached through its button")
 await capture("settings-720")
 var quality:=game.ui.panel.get_node("graphics_quality") as OptionButton
 quality.select(0)
 quality.item_selected.emit(0)
 check(game.profile.settings.graphics_quality=="low","Graphics setting changed through native option callback")
 await click(control("settings_controls"))
 check(game.ui.current_screen=="help","keyboard controls open from Settings")
 await click(control("help_back"))
 check(game.ui.current_screen=="settings","control guide returns to Settings")
 await click(control("settings_back"))
 await _render_frame()
 game.new_balance_version=1
 game.return_menu()
 check(game.start_endless("abandoned_dorm","standard",71),"Actual Endless match for build test")
 var model: MatchModel=game.model
 game.set_process(false)
 game.tutorial_enabled=false
 var target: RoomState=model.rooms[0]
 model.player_position=target.door_position()-target.door_normal()*35
 check(model.claim_room(0),"Real player claim at accessible room")
 model.player_position=target.bed_position()
 check(model.sleep_player(),"Real sleep sets up purchases")
 target.gold=300
 target.electricity=30
 target.bed_level=4
 target.door_level=4
 target.door_hp=target.max_hp()
 model.enable_player_grid(true)
 game.ui.show_match()
 game.focus_camera(true)
 await advance(.32)
 await click(game.ui.room_selected_summary)
 await advance(.32)
 check(game.ui.context_open and not game.ui.actions["build:turret"].disabled and not game.ui.actions["build:generator"].disabled,"Catalog opens with Needle and Dynamo")
 await capture("build-720")
 var gold: float=model.player().gold
 await click(game.ui.actions["build:turret"])
 await advance(.32)
 check(game.construction.kind=="turret" and game.ui.grid_placement_cancel_button.visible,"Needle placement visibly exposes a real cancel control")
 await capture("build-needle-placement-720")
 await click(game.ui.grid_placement_cancel_button)
 await advance(.20)
 check(not game.construction.active() and model.player().gold==gold,"Cancel spends no Gold")
 await click(game.ui.room_selected_summary)
 await advance(.32)
 await click(game.ui.actions["build:generator"])
 await advance(.32)
 check(game.construction.kind=="generator","Dynamo placement selected through existing button")
 await capture("build-dynamo-placement-720")
 await _finish()

func _fallback():
 game.ui.show_menu()
 await _render_frame()
 check(not game.ui.use_living_ui(),"Survivor opt-out retains original menu")
 check(game.ui.menu_start is MenuDestination,"original standalone menu destination")
 await capture("fallback-menu-720")
 var settings: Button
 for child in game.ui.panel.get_children():
  if child is Button and child.text=="Settings":
   settings=child
   break
 await click(settings)
 await _render_frame()
 check(game.ui.current_screen=="settings","fallback Settings real click")
 check(game.ui.panel.has_node("graphics_quality"),"fallback quality control remains available")
 await capture("fallback-settings-720")
 await _finish()
