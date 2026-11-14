extends "res://tests/onboarding_flow.gd"
func button_named(text,node=null):
 if node==null:node=game.ui.panel
 for child in node.get_children():
  if child is Button and child.text==text and child.is_visible_in_tree() and not child.is_queued_for_deletion():return child
  var found=button_named(text,child)
  if found!=null:return found
 return null
func run():
 await create(true);game.onboarding.close_welcome();await process_frame
 check(game.new_balance_version==2 and game.start_endless("abandoned_dorm","standard",71),"actual new Game default is earned-power2")
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
 # Prepared funds/one-HP enemy isolate UI/transactions only, not progression proof.
 r.gold=10000.125;r.electricity=10000.25;check(m.buy("turret",0),"paid weapon fixture")
 m.time=m.preparation+.1;m.hunter.hp=1;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=99;m.hunter.boss_policy.enabled=false
 for i in range(80):
  m.tick(.1)
  if m.endless.phase=="intermission":break
 check(m.endless.phase=="intermission" and game.profile.checkpoint_endless(m),"real clear/checkpoint initializes choices")
 game.ui.replay_ui.intermission_saved=true;game.ui.replay_ui.show_intermission();await process_frame
 await mouse_button(button_named("Run perks / merchant"));await process_frame
 check(game.ui.current_screen=="run_choices","actual integrated intermission button")
 for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;RunChoiceInterface.show(game.ui);await process_frame
  for child in game.ui.panel.get_children():
   if child is Button and not child.is_queued_for_deletion():check(child.get_rect().end.x<=1190 and child.get_rect().end.y<=685,"run choice button within logical viewport "+str(size))
 var choice=m.choices.draft[0];await mouse_button(button_named("Choose · "+RunChoices.CATALOG[choice].name));await process_frame
 check(m.choices.selected==[choice] and m.choices.draft.is_empty(),"actual click selects exactly one perk")
 var offer=m.choices.offers.filter(func(o):return o.id in ["shield","barricade","pillow"])[0];var text="Buy %s · %.0fG / %.0fE · ×%d" % [offer.id.capitalize(),offer.gold,offer.power,offer.left]
 var before=[r.gold,r.electricity];await mouse_button(button_named(text));await process_frame
 check(int(m.choices.stock.get(offer.id,0))==1 and r.gold==before[0]-offer.gold and r.electricity==before[1]-offer.power,"actual merchant click pays exact separate resources")
 check(not m.choices.buy(m,offer.id),"repeated sold-out purchase rejected")
 var path=game.profile.path;game.profile.path+="/missing/profile.json";var old=m.choices.snapshot();before=[r.gold,r.electricity]
 check(not game.run_transaction("buy",m.choices.offers[1].id) and [r.gold,r.electricity]==before and m.choices.snapshot()==old,"failed disk transaction rolls back fractional wallet, stock and claims")
 game.profile.path=path
 var id=offer.id;check(game.continue_endless("repair"),"normal continue after choice/shop")
 if m.items.can_activate(id,m)!="":
  check(not game.use_run_stock(id) and int(m.choices.stock[id])==1,"unavailable item consumes no stock")
  for i in range(120):
   m.tick(.1)
   if m.items.can_activate(id,m)=="":break
 check(game.use_run_stock(id) and int(m.choices.stock[id])==0,"existing consumable effect activates only after successful stock journal")
 check(not game.use_run_stock(id),"zero stock cannot reactivate")
 var saved_profile=PlayerProfile.new(path);check(saved_profile.load_profile(),"saved profile with use journal loads")
 game.profile=saved_profile;check(game.resume_endless(),"actual Game resume route")
 check(int(game.model.choices.stock.get(id,0))==0 and int(game.model.choices.used[id])==1,"resume cannot rewind spent merchant stock")
 check(game.profile.inventory.is_empty() and game.profile.xp==0 and game.profile.rm_cash==0,"temporary merchant supplies never enter permanent wallet/rewards")
 print("EARNED_POWER_UI_CHECKS=",checks," FAILURES=",failures);await dispose();quit(1 if failures else 0)
