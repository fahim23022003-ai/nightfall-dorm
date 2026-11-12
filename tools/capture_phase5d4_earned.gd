extends "res://tools/capture_phase5d4_core.gd"
var earned_sources={}
func restore_earned(source):
 game.return_menu();game.set_process(false)
 var file="res://docs/evidence/phase5d4/"+source+".json";earned_sources[source]=FileAccess.get_sha256(file)
 var canonical=JSON.parse_string(FileAccess.get_file_as_string(file));var dest="user://phase5d4-earned-render-"+source+"-"+str(Time.get_ticks_usec())+".json"
 check(DirAccess.copy_absolute(ProjectSettings.globalize_path(file),ProjectSettings.globalize_path(dest))==OK,"copy exact earned checkpoint")
 var p=PlayerProfile.new(dest);check(p.load_profile() and not p.read_only,"canonical realearned checkpoint loads")
 if not p.tutorial_completed:p.tutorial_completed=true;check(p.save_profile(),"graduate isolated GUIcopy")
 var copied=JSON.parse_string(FileAccess.get_file_as_string(dest));copied.onboarding.tutorial_completed=canonical.onboarding.tutorial_completed
 check(copied==canonical,"GUIcopy changes only tutorialflag")
 game.profile=p;check(game.resume_endless(),"actual earned checkpoint resume");game.set_process(false)
 await click(find_button("Prepare defenses · frozen economy"));await advance(.2)
 return game.model
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game()
 var hp_only="hp-only" in OS.get_cmdline_user_args()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for source in ["balance-earned-71standard","balance-earned-47hell"]:
   var m=await restore_earned(source);var r=m.player();var label="earned-"+("hell" if m.difficulty=="hell" else "normal")
   var ledger={"gold":r.gold,"electricity":r.electricity,"buildings":r.buildings.duplicate(true)}
   game.ui.teammates.expanded=false;game.ui.teammates.update();game.focus_camera(true);await advance(.7)
   await capture(label+"-six-new-level10-world-"+suffix)
   for kind in ([] if hp_only else DefenseEffects.SPECIAL+["heavy"]):
    var tile=-1
    for t in r.buildings:
     if r.buildings[t].kind==kind:tile=t;break
    check(tile>=0 and r.buildings[tile].level==10,"naturally paid actualL10 "+kind)
    if tile<0:continue
    await world_click(r.tile_position(tile));await advance(.15)
    check(game.ui.actions.upgrade.disabled and game.ui.selected_details.text.contains("MAX"),"genuine max inspector disablesL11 "+kind)
    await capture(label+"-"+kind+"10-"+suffix);game.ui.close_context()
   if not hp_only:
    await click(game.ui.room_bed_summary);await advance(.1);await capture(label+"-bed10-"+suffix);game.ui.close_context()
   await click(game.ui.room_door_summary);await advance(.1);await capture(label+"-door10-"+suffix);game.ui.close_context()
   if not hp_only:game.profile.settings.reduced_effects=true;await advance(.2);await capture(label+"-reduced-effects-"+suffix)
   check(r.gold==ledger.gold and r.electricity==ledger.electricity and r.buildings==ledger.buildings,"actual earned resources/upgrades untouched by inspection")
   check(FileAccess.get_sha256("res://docs/evidence/phase5d4/"+source+".json")==earned_sources[source],"canonical earned source bytes unchanged")
 var f=FileAccess.open("res://docs/evidence/phase5d4/final-d-earned-"+("hp" if hp_only else "full")+"-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"sources":earned_sources,"fixture":"Real checkpoints earned by AgentA through actual legal economy/combat. GUIcopy tutorialflag onlychanged; no HP/funds/building/ledger injection. Actualbetweenwave frozenpreparation inspections. NativeWindowsUNVERIFIED."}," "))
 print("PHASE5D4_CORE_EARNED_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
