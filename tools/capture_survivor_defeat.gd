extends "res://tests/survivor_lobby_integration.gd"
## Two actual early Story defeats fund a shop transaction and next lobby ticket.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or DisplayServer.get_name()=="headless":
  quit(2)
  return
 destination=args[0]
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://survivor-defeat-raster-%d.json" % OS.get_process_id())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 check(game.profile.complete_tutorial(),"fresh isolated progression fixture")
 game.enter_game()
 var awards: Array=[]
 for attempt in range(2):
  if not await start_from_ready():
   break
  var folder:=destination
  destination=""
  await walk_probe()
  destination=folder
  var model: MatchModel=game.model
  var room:=model.player()
  if room==null or not room.sleeping:
   check(false,"own and sleep in a room first")
   break
  while model.result=="" and model.time<model.preparation+.2:
   model.tick(.1)
  model.apply_room_damage(room.index,room.door_hp-1.0)
  model.hunter.state=HunterState.State.ATTACK
  model.hunter.position=room.door_approach()
  model.hunter.target=room.index
  model.hunter.cooldown=0.0
  model.hunter.archetype_primed=true
  for frame in range(300):
   if model.result!="":break
   model.tick(.1)
  check(model.result=="defeat" and model.terminal_recorded,"actual Hunter strike followed by terminal breach")
  game._process(0.0)
  check(game.ui.current_screen=="story_result" and game.last_progression.get("rm_cash",0)>=6,"recorded RM Cash appears in Story results")
  awards.append(game.last_progression.get("rm_cash",0))
  await image("0%d-legitimate-defeat" % (attempt+1),Vector2i(1280,720))
  if not game.profile.pending_spins.is_empty():
   var ticket: int=game.profile.pending_spins[0].match_id
   check(not game.profile.claim_spin(ticket).is_empty(),"acknowledge the normally earned item receipt")
  if attempt==0:
   game.return_menu()
   game.enter_game()
 var cash: int=game.profile.rm_cash
 await press("StoryResultShop",game.ui.panel)
 await press("shop_buy_radar",game.ui.panel)
 check(game.profile.rm_cash==cash-OnboardingCatalog.PRICES.radar,"actual Shop click deducts Radar price")
 await image("03-shop-purchase",Vector2i(1280,720))
 game.return_menu()
 game.ui.items_ui.inventory()
 await press("inventory_equip_radar",game.ui.panel)
 check("radar" in game.profile.item_loadout,"actual inventory click equips Radar")
 await image("04-item-equipped",Vector2i(1280,720))
 game.return_menu()
 game.enter_game()
 await image("05-next-story-loadout",Vector2i(1280,720))
 check(await start_from_ready() and "radar" in game.profile.active_match.get("items",[]),"next real match preserves equipped Radar")
 var file:=FileAccess.open(destination.path_join("defeat-journey.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"awards":awards,"pre_purchase_balance":cash,"balance":game.profile.rm_cash,
  "checks":checks,"failures":failures},"  ")+"\n")
 file.close()
 game.audio_system.shutdown()
 await create_timer(.12).timeout
 game.queue_free()
 await process_frame
 print("SURVIVOR_DEFEAT_JOURNEY_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures!=0))

func start_from_ready() -> bool:
 var lobby=await open_prepared_lobby()
 if not is_instance_valid(lobby):return false
 await press("LobbyReady",lobby)
 advance(lobby,7.0)
 advance(lobby,.5)
 await process_frame
 await process_frame
 return game.mode=="match"
