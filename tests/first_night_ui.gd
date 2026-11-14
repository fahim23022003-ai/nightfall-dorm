extends "res://tests/onboarding_flow.gd"
func find_text(text,node=null):
 if node==null:node=game
 for c in node.get_children():
  if c is Button and c.text==text and c.is_visible_in_tree() and not c.is_queued_for_deletion():return c
  var got=find_text(text,c)
  if got!=null:return got
 return null
func run():
 await create(false);await key(KEY_SPACE);await mouse_button(game.onboarding.welcome_close);await mouse_button(game.ui.menu_start)
 var skip=find_text("Skip practice · no rewards");check(skip!=null,"fresh tutorial has visible Skip")
 await mouse_button(skip)
 check(game.profile.tutorial_completed and game.profile.xp==0 and game.profile.rm_cash==0 and game.mode=="menu","explicit skip saves without reward")
 var copy=PlayerProfile.new(game.profile.path);check(copy.load_profile() and copy.tutorial_completed,"skip survives disk load")
 await mouse_button(find_text("Replay Tutorial"));check(game.tutorial_active and game.onboarding.step==0,"actual Replay Tutorial remains accessible")
 await mouse_button(find_text("Exit practice"));check(game.mode=="menu","actual replay exit")
 for size in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=size;game.ui.show_settings();await process_frame
  var combo=null
  for child in game.ui.panel.get_children():
   if child is OptionButton and child.get_item_count()==3 and child.get_item_text(0)=="Show Guidance":combo=child
  check(combo!=null,"guidance selector exists")
  if combo==null:continue
  check(combo.get_item_count()==3 and combo.size.y>=38 and combo.get_rect().end.x<=1280,"guidance preferences fit logical viewport "+str(size))
 var snap=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/every-night/screens/prepared-wave1-checkpoint.json"))
 game.model=ReplaySnapshot.restore(snap);game.mode="match";game.ui.replay_ui.intermission_saved=false;game.ui.replay_ui.show_intermission()
 await mouse_button(find_text("Wave report"));game._process(.05)
 check(game.ui.current_screen=="wave_report","normal live update cannot dismiss report")
 var wallet=[game.model.player().gold,game.model.player().electricity,game.model.random.state]
 for tab in ["Damage","Economy","Defense","Hunter Skills","Insights","Details"]:
  await mouse_button(find_text(tab));await process_frame
  check(game.ui.current_screen=="wave_report","actual tab click "+tab)
  for child in game.ui.panel.get_children():
   if child is ProgressBar:check(child.size.y<=10,"damage bar cannot grow over the next building label")
   if child is Label and not child.is_queued_for_deletion() and child.position.y>=278 and child.position.y<600:check(child.position.x+child.size.x<=1160,"report paragraph stays inside panel · "+tab+" · "+str(child.get_rect())+" · "+child.text.left(50))
 check(wallet==[game.model.player().gold,game.model.player().electricity,game.model.random.state],"report navigation cannot change wallet/RNG")
 await mouse_button(find_text("Back · wave choices and Omens"));check(game.ui.current_screen=="intermission","actual report back")
 game.ui.show_match();game.ui.replay_ui.preparing=true;game.model.hunter.state=HunterState.State.ATTACK;game.model.hunter.target=game.model.player_room;game.model.hunter.position=game.model.player().door_approach()
 game.profile.settings.guidance_mode="off";game.ui.update_match();game.guidance.refresh(game)
 check(game.ui.warning_box.visible and not game.ui.guide_box.visible,"Guidance Off preserves urgent warnings")
 print("FIRST_NIGHT_UI_CHECKS=",checks," FAILURES=",failures);await dispose();quit(1 if failures else 0)
