extends "res://tests/premium_strategy_ui.gd"
# Actual production scene/controls. D independently reviews raster/clipboard/audio.
const Support=preload("res://tests/replay_test_support.gd")
func key(code):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;Input.parse_input_event(event);await process_frame
 await settle()
func amount_signature(m):
 var r=m.player()
 return [r.max_hp(),r.income_rate(),r.power_multiplier,r.turret_multiplier,m.match_boosts.duplicate(true)]
func prepare_claim():
 var m=game.model;m.player_position=m.rooms[0].center();await key(KEY_E)
 check(m.player_room==0,"actual E claims new-mode room")
 m.player_position=m.player().bed_position();await key(KEY_E)
 check(m.player().sleeping and m.player().closed,"actual E occupies new-mode bed")
func terminal(win=false):
 var m=game.model;var r=m.player();var h=m.hunter
 m.bot_claimed=5;m.time=m.preparation+25
 for i in range(1,6):
  var other=m.rooms[i];other.owner=i;other.profile=Catalog.BOT_PROFILES[i-1];other.closed=true;other.sleeping=true;other.resident_position=other.bed_position()
 h.boss_policy.enabled=false;h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=100
 if win:
  r.gold=1000;r.electricity=100;r.occupied_seconds=25
  var tile=Support.nearest_pad(r,r.door_approach());check(m.buy("turret",tile),"UI terminal fixture pays real in-range turret");game.selected_tile=tile;h.hp=1
 else:
  r.door_hp=1;h.cooldown=0;h.archetype_primed=true;h.encounter_attacks=1
 for i in range(500):
  m.tick(.1)
  if m.result!="" or (m.endless!=null and m.endless.phase=="intermission"):break
 game._process(0);await settle()
func endless_flow():
 game.return_menu();await settle();screen("new main menu")
 check(find("Endless Siege").icon!=null,"real main menu has recognizable Endless emblem")
 await click(find("Endless Siege"));await settle();screen("Endless setup")
 await click(find("Laboratory"));await settle()
 check(game.ui.replay_ui.selected_map=="underground_lab","actual map card changes Endless map")
 await click(find("New Endless run"));await settle()
 check(game.model.run_kind=="endless" and game.model.map_id=="underground_lab","actual New starts declared model and resources")
 await prepare_claim()
 check(game.model.player().rescue_payment.is_valid(),"actual Game pre-room binding installs durable FirstAid at claim")
 await terminal(true)
 check(game.ui.current_screen=="intermission" and game.profile.replay.checkpoint.completed==1,"real wave completion opens saved intermission")
 screen("saved intermission")
 await click(find("Prepare defenses · frozen economy"));await settle()
 check(game.ui.replay_ui.preparing and game.ui.current_screen=="match","actual intermission preparation exposes real building controls")
 var r=game.model.player();var time=game.model.time;var gold=r.gold
 game._process(.2);await settle()
 check(game.model.time==time and r.gold==gold,"preparation HUD cannot farm passive income")
 game.ui.open_context();await settle()
 await click(game.ui.actions.upgrade);await settle()
 var tile=game.selected_tile
 check(r.buildings[tile].level==2 and r.buildings[tile].invested_power==3,"actual frozen preparation buys paid upgrade with correct ledger")
 await key(KEY_ESCAPE)
 check(not game.ui.context_open,"first Esc preserves existing inspector-cancellation behavior")
 await key(KEY_ESCAPE)
 check(game.ui.current_screen=="intermission" and game.profile.replay.checkpoint.rooms[0].buildings[0].level==2,"actual Esc saves newest paid preparation before returning to wave choice")
 await click(find("Save & exit to menu"));await settle()
 check(game.mode=="menu","actual safe checkpoint exit returns to menu")
 var saved=game.profile._reward_snapshot();game.campaign_mode=true;game.ui.progression.show_loadout();await settle()
 await click(find("Start Match"));await settle()
 check(game.ui.current_screen=="endless_setup" and game.ui.replay_ui.notice.to_lower().contains("forfeit") and game.profile._reward_snapshot()==saved,"actual blocked campaign explains Resume/Forfeit without replacing durable run")
 await click(find("Resume saved checkpoint"));await settle()
 check(game.ui.current_screen=="intermission" and game.model.player().buildings[tile].level==2,"actual Resume restores latest level/ledger, not stale pre-upgrade snapshot")
 check(is_equal_approx(float(game.last_income[0]),game.model.player().income_total) and game.floating.is_empty(),"resume does not replay historical income as new floating Gold")
 var old_hunter=game.model.hunter;var electricity=game.model.player().electricity
 await click(find("Continue · Recharge"));await settle()
 check(game.ui.current_screen=="match" and game.model.endless.wave==2 and game.model.hunter!=old_hunter and game.model.player().electricity==electricity+5,"actual Continue applies one aid and replaces one Hunter")
 check(is_equal_approx(float(game.last_income[0]),game.model.player().income_total) and game.floating.is_empty(),"carried-wave HUD cannot emit fake whole-run income feedback")
 await terminal(true)
 check(game.ui.current_screen=="intermission" and game.model.endless.completed==2,"actual continued encounter returns to safe next checkpoint")
 var defeats=int(game.audio_system.event_counts.get("defeat",0));var rewards=int(game.audio_system.event_counts.get("reward",0))
 await click(find("End run here · keep earned records"));await settle()
 game._process(0);await settle()
 check(game.model.result=="retired" and game.mode=="result" and game.profile.active_match.is_empty() and game.profile.replay.checkpoint.is_empty(),"actual safe end closes active run without invented defeat or stuck resume")
 check(int(game.audio_system.event_counts.get("defeat",0))==defeats and int(game.audio_system.event_counts.get("reward",0))>=rewards,"safe retirement uses earned-record audio without a false defeat cue")
 screen("Endless retired result")
 await click(find("Main menu"));await settle()
func practice_flow():
 var snapshot=Support.profile_signature(game.profile);var bytes=FileAccess.get_file_as_bytes(game.profile.path)
 game.ui.replay_ui.show_practice();await settle();screen("Practice setup")
 var options=controls(game.ui.panel,OptionButton)
 check(options.size()==4,"practice exposes archetype/map/two actual item selectors")
 options[3].select(options[2].selected);options[3].item_selected.emit(options[2].selected);await settle()
 check(find("Begin Practice").disabled and game.ui.replay_ui.practice_hint.text.contains("two different"),"duplicate temporary item choices visibly disable invalid start")
 options[3].select(ItemCatalog.IDS.find("repair"));options[3].item_selected.emit(ItemCatalog.IDS.find("repair"));await settle()
 check(not find("Begin Practice").disabled,"valid distinct item choices enable actual Practice start")
 await click(find("Begin Practice"));await settle()
 check(game.model.run_kind=="practice" and not game.model.tutorial_mode and game.item_wallet()!=game.profile,"actual Practice uses temporary wallet and real combat")
 var wallet=game.item_wallet();game.model.hunter.state=HunterState.State.MOVE;game.model.hunter.target=0
 await key(KEY_1);game.ui.items_ui.update(0);await settle()
 check(wallet.inventory.shield==4 and game.ui.items_ui.hotbar[0].text.contains("×4"),"actual item key spends local stock and HUD shows local quantity")
 check(Support.profile_signature(game.profile)==snapshot and FileAccess.get_file_as_bytes(game.profile.path)==bytes,"actual Practice input leaves every permanent field/byte/RNG untouched")
 await click(game.ui.pause_button);await settle();await click(find("Reset Practice"));await settle()
 check(game.item_wallet().inventory.shield==5 and game.model.player().buildings[game.model.practice_tile].level==4,"actual pause RESET restores only local scenario")
 var cache=GothicTheme.materials.size();var nodes=game.get_child_count()
 for i in range(10):
  game.reset_practice();await settle()
 check(GothicTheme.materials.size()==cache and game.get_child_count()==nodes,"repeated real Practice reset keeps cached materials and root nodes bounded")
 await terminal(false)
 check(game.mode=="result" and game.model.result=="defeat","actual local combat produces Practice result")
 screen("Practice result")
 await click(find("Why did I lose?"));await settle();screen("factual defeat analysis")
 check(game.model.defeat_facts.report.unused.repair==5,"analysis uses temporary pre-loot equipped stock, not permanent inventory")
 check(controls(game.ui.panel,Label).any(func(l):return l.text.begins_with("Final recorded source:")),"actual result analysis displays factual source/resources/history")
 await click(find("Return to results"));await settle();await click(find("Main menu"));await settle()
 check(Support.profile_signature(game.profile)==snapshot and FileAccess.get_file_as_bytes(game.profile.path)==bytes,"Practice reset/defeat/analysis/exit cannot award or consume permanent progress")
func challenge_flow():
 var snapshot=game.profile._reward_snapshot();var bytes=FileAccess.get_file_as_bytes(game.profile.path)
 # Use non-default modes/archetypes so the result cannot pass by echoing the
 # profile's Normal preference or a hardcoded Hunter name.
 game.ui.replay_ui.difficulty="hell" if root.size.x>1280 else "hard"
 game.ui.replay_ui.practice_archetype="ravager" if root.size.x>1280 else "stalker"
 game.ui.replay_ui.show_codes();await settle();screen("Challenge codes")
 await click(find("Generate code"));await settle()
 var code=game.ui.replay_ui.code_text
 check(ChallengeCode.decode(code).ok,"actual Generate creates valid complete shareable code")
 await click(find("Copy code"));await settle()
 check(game.ui.replay_ui.notice.contains("Clipboard") or game.ui.replay_ui.notice.contains("Copied"),"actual Copy handles available/unavailable clipboard explicitly")
 await click(find("Start coded challenge"));await settle()
 check(game.model.run_kind=="challenge" and game.model.match_boosts.is_empty() and game.item_wallet()!=game.profile,"actual coded start removes permanent perk/stock advantage")
 await prepare_claim()
 check(game.model.player().door_multiplier==1 and game.model.player().turret_multiplier==1 and game.item_wallet().inventory.shield==2,"actual coded player uses normalized stats and exactly two loaned items")
 await key(KEY_1)
 check(game.item_wallet().inventory.shield==1 and game.profile._reward_snapshot()==snapshot and FileAccess.get_file_as_bytes(game.profile.path)==bytes,"actual coded item key consumes only loaned stock")
 await terminal(false)
 check(game.model.result=="defeat" and game.model.challenge_recorded and game.mode=="result","actual coded terminal stores one self-reported personal result")
 var after=game.profile._reward_snapshot();var expected=snapshot.duplicate(true);expected.replay.challenge_best=after.replay.challenge_best.duplicate(true)
 check(after==expected,"coded result changes personal code record only, never inventory/cash/XP/pity/campaign")
 check(not game.profile.record_challenge(game.model) and game.profile._reward_snapshot()==after,"same coded result cannot record repeatedly")
 screen("Challenge result card")
 var model=game.model;var map_title=MapCatalog.map(model.map_id).title
 var difficulty=RankCatalog.DIFFICULTIES[model.difficulty].name;var archetype=StrategyCatalog.ARCHETYPES[model.hunter.archetype].name
 var labels=controls(game.ui.panel,Label)
 check(labels.any(func(l):return l.is_visible_in_tree() and l.text.contains(map_title) and l.text.contains(difficulty)),"result visibly names actual challenge map and difficulty")
 check(labels.any(func(l):return l.is_visible_in_tree() and l.text.contains(archetype) and l.text.contains("Normalized rules %d" % ChallengeCode.RULESET)),"result visibly names actual archetype and ruleset")
 var summary=game.ui.replay_ui.challenge_result_summary()
 check(summary.contains(model.challenge_code) and summary.contains(map_title) and summary.contains(difficulty) and summary.contains(archetype) and summary.contains("ruleset %d" % ChallengeCode.RULESET) and summary.contains(model.result) and summary.contains("self-reported"),"actual Copy builder includes complete factual challenge metadata and self-report limit")
 print("REPLAY_RESULT_METADATA=",difficulty," / ",archetype," / ",map_title," / ruleset ",ChallengeCode.RULESET)
 await click(find("Copy result summary"));await settle()
 await click(find("Main menu"));await settle()
func cosmetics_and_pity():
 game.ui.replay_ui.show_cosmetics();await settle();screen("earned cosmetic gallery")
 var equips=[]
 for b in controls(game.ui.panel,Button):
  if b.text=="Equip appearance":equips.append(b)
 var unlocked=controls(game.ui.panel,Button).filter(func(b):return b.text in ["Equip appearance","Equipped ✓"])
 check(unlocked.size()>=2 and not equips.is_empty(),"genuine earlier campaign/Reaper progress unlocks visual equipment")
 var stock=game.profile.inventory.duplicate(true);var xp=game.profile.xp;var cash=game.profile.rm_cash
 await click(equips[0]);await settle()
 check(game.profile.inventory==stock and game.profile.xp==xp and game.profile.rm_cash==cash,"actual cosmetic equip never grants stat currency or items")
 game.return_menu();game.profile.replay.pity={"epic_dry":7,"legendary_dry":39}
 var started=game.start_stage("stage_1","standard")
 check(started,"campaign preserved after all replay modes")
 if not started:return
 await prepare_claim();await terminal(true)
 check(game.profile.pending_spins.size()==1,"actual qualifying campaign terminal still grants one saved spin")
 var receipt=game.profile.pending_spin();game.ui.items_ui.spin();await settle();screen("pity guaranteed spin")
 if receipt.is_empty():check(false,"genuine saved spin receipt required before inspecting odds");return
 check(controls(game.ui.panel,Label).any(func(l):return l.text==receipt.odds and l.text.contains("Legendary 100%")),"saved-draw guaranteed odds are visible independently of next progress")
 var table=null
 for l in controls(game.ui.panel,Label):
  if l.text.split("\n").size()==20:table=l
 check(table!=null,"all20 actual conditional item probabilities displayed")
 if table!=null:
  for id in ItemCatalog.IDS:
   var row=""
   for line in table.text.split("\n"):
    if line.begins_with(ItemCatalog.ITEMS[id].name+" "):row=line
   var pieces=row.rsplit(" ",true,1)
   check(pieces.size()==2 and pieces[1].ends_with("%") and pieces[1].trim_suffix("%").to_float()==(25.0 if ItemCatalog.legendary(id) else 0.0),"guaranteed draw per-item probability is actual25%/0%: "+id)
 check(controls(game.ui.panel,Label).any(func(l):return l.text.begins_with("NEXT Victory:") and l.tooltip_text.contains("Legendary 4%")),"next-draw reset odds cannot replace saved100% odds")
 stock=game.profile.inventory.duplicate(true);await click(find("Skip animation"));await settle();await click(find("Save reveal & continue"));await settle()
 check(game.profile.pending_spins.is_empty() and game.profile.inventory==stock,"actual reveal/claim consumes receipt without duplicate stock")
 game.return_menu();await settle()
func run():
 profile_path="user://replay-ui-"+str(Time.get_ticks_usec())+".json";OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 var p=Support.profile(profile_path);p.pending_spins=[];p.item_loadout=[];p.equipped=["first_aid","reinforced"];check(p.save_profile(),"prepared real migrated profile saves")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle();game.set_process(false);game.onboarding.skip();await settle()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;game.profile.settings.reduced_effects=resolution.x>1280
  await endless_flow();await practice_flow();await challenge_flow();await cosmetics_and_pity()
 game.audio_system.shutdown();var until=Time.get_ticks_msec()+550
 while Time.get_ticks_msec()<until:await process_frame
 game.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(profile_path+suffix):DirAccess.remove_absolute(profile_path+suffix)
 print("REPLAY_UI_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
