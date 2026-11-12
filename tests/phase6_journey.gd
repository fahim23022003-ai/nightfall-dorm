extends "res://tests/onboarding_flow.gd"
# Release integration: one fresh profile travels tutorial -> earned campaign
# reward -> Next Stage -> shop -> inventory -> actual campaign item -> restart.
# Tutorial and navigation use production input. Terminal and attack setup below
# are disclosed controlled combat fixtures, not human/natural balance evidence.
func find_button(text):
 for node in game.ui.panel.get_children():
  if node is Button and node.text==text and not node.is_queued_for_deletion():return node
 return null
func press(text):
 var b=find_button(text);check(b!=null,"actual button exists: "+text)
 if b!=null:
  if b.disabled:await create_timer(1.1).timeout
  check(not b.disabled,"button ready after actual result animation: "+text)
  await mouse_button(b)
 await process_frame;await process_frame
func run():
 await create(false);game.onboarding.skip();game.onboarding.set_process(false)
 await graduate(false);game.onboarding.save_completion()
 check(game.profile.tutorial_completed and game.mode=="menu","fresh tutorial graduates into real main menu")
 await press("Start Game");await press("Prepare");await press("Start Match")
 check(game.mode=="match" and game.model.stage_id=="stage_1","fresh profile reaches first actual campaign")
 var m=game.model
 await walk_to(m.rooms[0].bed_position()+Vector2(31,49));await key(KEY_E);await key(KEY_E)
 check(m.player()!=null and m.player().sleeping,"campaign E input claims and sleeps after tutorial")
 if m.player()==null:await dispose();quit(1);return
 var r=m.player();m.time=m.preparation+120;r.occupied_seconds=120;r.damage_dealt=1000
 m.hunter.state=HunterState.State.SEEK;m.hunter.hurt(m.hunter.hp);game._process(.01)
 await create_timer(1.3).timeout
 check(game.mode=="result" and game.profile.stage_unlocked("stage_2"),"controlled genuine terminal settles first clear")
 var saved_stock=game.profile.inventory.duplicate(true);var receipt=game.profile.pending_spin()
 await press("Lucky Spin · reveal earned item");await press("Skip animation");await press("Save reveal & continue")
 check(game.profile.inventory==saved_stock and not receipt.is_empty() and game.profile.pending_spins.is_empty(),"first earned spin reveal never duplicates stock")
 await press("Choose stage bonus");await press("Select")
 game.ui.show_result();await process_frame
 await press("Next Stage")
 check(game.ui.current_screen=="loadout" and game.profile.selected_stage=="stage_2","first reward/choice routes Next Stage correctly")
 game.return_menu();await process_frame
 await press("Shop · Common supplies")
 var cash=game.profile.rm_cash;var stock=int(game.profile.inventory.get("repair",0))
 check(cash>=OnboardingCatalog.PRICES.repair,"actual first-win RM funds ordinary repair purchase")
 var purchase=null
 for row in game.ui.shop.buttons:
  if row.id=="repair":purchase=row.button
 check(purchase!=null,"real shop repair control exists")
 if purchase!=null:await mouse_button(purchase)
 check(game.profile.rm_cash==cash-OnboardingCatalog.PRICES.repair and int(game.profile.inventory.get("repair",0))==stock+1,"shop spends earned cash and grants exactly one repair")
 game.return_menu();await process_frame;await press("Consumable inventory")
 check(ItemCatalog.IDS[0]=="repair","first inventory card identifies repair")
 await press("Equip");check(game.profile.item_loadout==["repair"],"real inventory card equips purchased item")
 game.return_menu();await process_frame;await press("Start Game");await press("Prepare");await press("Start Match")
 m=game.model
 check(m.stage_id=="stage_2" and game.profile.active_match.items==["repair"],"next campaign snapshots purchased loadout")
 await walk_to(m.rooms[0].bed_position()+Vector2(31,49));await key(KEY_E);await key(KEY_E)
 r=m.player()
 if r==null:check(false,"stage2 claim must succeed");await dispose();quit(1);return
 # Controlled real Hunter-controller damage; the door is not edited for repair.
 m.time=m.preparation+1;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=0
 for i in range(100):
  m.tick(.05)
  if r.door_hp<r.max_hp():break
 check(r.door_hp<r.max_hp() and r.alive,"real Hunter attack supplies eligible repair damage")
 var before_hp=r.door_hp;stock=int(game.profile.inventory.get("repair",0));cash=game.profile.rm_cash
 await key(KEY_1)
 check(r.door_hp>before_hp and int(game.profile.inventory.get("repair",0))==stock-1,"actual campaign hotkey repairs and consumes purchased permanent stock once")
 var path=game.profile.path;var xp=game.profile.xp
 var restored=PlayerProfile.new(path)
 check(restored.load_profile() and restored.tutorial_completed and restored.stage_unlocked("stage_2") and restored.inventory.repair==stock-1 and restored.rm_cash==cash and restored.xp==xp,"restart preserves tutorial, stage, earned balance and consumed stock")
 await dispose()
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("PHASE6_JOURNEY_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
