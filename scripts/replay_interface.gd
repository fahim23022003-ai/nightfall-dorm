class_name ReplayInterface
extends RefCounted
var ui
var game
var notice=""
var selected_map="abandoned_dorm"
var difficulty="standard"
var seed_text="17"
var code_text=""
var practice_archetype="crusher"
var practice_boss=false
var practice_items=["shield","repair"]
var practice_map="abandoned_dorm"
var intermission_saved=false
var preparing=false
var wave_label
var notice_label
var practice_start
var practice_hint
func _init(owner):
 ui=owner;game=ui.game;difficulty=game.profile.selected_difficulty
 var stage=StageCatalog.stage(game.profile.selected_stage)
 if not stage.is_empty():selected_map=stage.map
func page(title: String,subtitle: String,screen: String):
 ui.clear();ui.current_screen=screen
 ui.box(Rect2(70,35,1140,650))
 ui.label_at(title,Vector2(105,58),32,1060,true)
 var info=ui.label_at(subtitle,Vector2(107,111),16,1060)
 info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.set_deferred("size",Vector2(1060,55))
func paragraph(text: String,at: Vector2,width: float,height: float,font=17):
 var label=ui.label_at(text,at,font,width);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.set_deferred("size",Vector2(width,height))
 return label
func option(labels: Array,index: int,at: Vector2,width: float,callback: Callable):
 var box=OptionButton.new();box.position=at;box.size=Vector2(width,42)
 for text in labels:box.add_item(str(text))
 box.select(index);box.item_selected.connect(callback)
 for state in ["normal","hover","pressed","disabled","focus"]:box.add_theme_stylebox_override(state,GothicTheme.surface("22292B","938876","button_"+state))
 ui.panel.add_child(box);return box
func input(text: String,at: Vector2,width: float,callback: Callable):
 var box=LineEdit.new();box.position=at;box.size=Vector2(width,44);box.text=text;box.text_changed.connect(callback)
 box.add_theme_stylebox_override("normal",GothicTheme.surface("171C22","938876"));ui.panel.add_child(box);return box
func seed_number() -> int:
 if seed_text.length()>6 or not seed_text.is_valid_int():return 0
 var value=int(seed_text)
 return value if value>=1 and value<=999999 else 0
func show_hub():
 page("THE REPLAY CHAMBER","Independent challenges, advanced training and earned appearances. Campaign progress and the original tutorial remain available.","replay_hub")
 var cards=[{"icon":"challenge","name":"Challenge Codes","text":"Share a fixed map, seed, Hunter and normalized gear. No rank or permanent item advantage.","call":show_codes},{"icon":"practice","name":"Practice Room","text":"Real combat, temporary funds and items. Train repair, branches and Reaper warnings safely.","call":show_practice},{"icon":"cosmetic","name":"Earned Cosmetics","text":"Four original appearances unlocked through real accomplishments. No stat advantage.","call":show_cosmetics}]
 for i in range(cards.size()):
  var data=cards[i];var at=Vector2(107+i*362,194)
  ui.box(Rect2(at,Vector2(342,298)),"203747","9C8DAA")
  ui.premium_icon(data.icon,at+Vector2(132,16),Vector2(78,78))
  ui.label_at(data.name,at+Vector2(17,106),27,310,true)
  paragraph(data.text,at+Vector2(17,150),306,94)
  ui.button("Open "+data.name,at+Vector2(17,246),data.call,308,38)
 var pity=game.profile.replay.pity
 paragraph("LUCKY SPIN · Next Victory odds: "+SpinPity.summary("victory",pity)+"\nEpic+ guaranteed by qualifying Victory 8; Legendary by 40. Current dry streaks %d / %d. Consolation does not advance/reset." % [pity.epic_dry,pity.legendary_dry],Vector2(107,523),1050,69,16)
 ui.button("Main menu",Vector2(107,622),game.return_menu,320,42)
 ui.button("Endless Siege",Vector2(855,622),show_endless,320,42)
func show_endless():
 page("ENDLESS SIEGE","One Hunter each wave. Rooms, actual paid investments and resources carry. Save only BETWEEN waves; consumed items and the run-wide Legendary limit never rewind.","endless_setup")
 for i in range(5):
  var id=MapCatalog.IDS[i];var picked=id
  var b=ui.button(["Dorm","Hospital","Hotel","Laboratory","Mansion"][i],Vector2(107+i*216,195),func():selected_map=picked;show_endless(),204,64)
  b.toggle_mode=true;b.button_pressed=selected_map==id
  b.tooltip_text=MapCatalog.map(id).title
 ui.label_at(MapCatalog.map(selected_map).title,Vector2(107,280),24,1050,true)
 for i in range(3):
  var key=["standard","hard","hell"][i];var chosen=key
  var b=ui.button(("✓ " if difficulty==key else "")+RankCatalog.DIFFICULTIES[key].name,Vector2(107+i*362,330),func():difficulty=chosen;show_endless(),342,55)
  b.icon=PremiumButton.texture(key);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",32)
 ui.label_at("Seed (1–999999)",Vector2(107,414),17,300)
 var seed_field=input(seed_text,Vector2(107,450),320,func(text):seed_text=text);seed_field.max_length=6
 paragraph("Best cleared wave: %d · Milestones 5/10/15/20 award 8 RM +20 XP each, once per profile. No campaign spins, contract bonuses or loss statistics. Late waves reduce repairs during contact and add Reaper encounters." % game.profile.replay.best_wave,Vector2(467,415),708,96,16)
 paragraph(notice if notice!="" else "NEW replaces the previous run explicitly. Returning mid-wave keeps only the last safe checkpoint; spent permanent items stay spent.",Vector2(107,527),1060,45,15)
 var resume=ui.button("Resume saved checkpoint",Vector2(107,590),func():
  if not game.resume_endless():notice="No compatible checkpoint is available.";show_endless(),515,42)
 resume.disabled=game.profile.replay.checkpoint.is_empty() or game.profile.read_only
 var start=ui.button("New Endless run",Vector2(647,590),func():
  if seed_number()==0 or not game.start_endless(selected_map,difficulty,seed_number()):notice="Choose a valid seed and writable profile.";show_endless(),528,42)
 start.icon=PremiumButton.texture("endless");start.disabled=game.profile.read_only
 ui.button("Back",Vector2(107,645),game.return_menu,220,28)
 var forfeit=ui.button("Forfeit saved run",Vector2(845,645),func():
  if game.profile.forfeit_endless():notice="Run forfeited. Items already spent remain spent."
  show_endless(),330,28)
 forfeit.disabled=game.profile.active_match.get("run_kind","")!="endless"
func show_intermission():
 if preparing:
  preparing=false;intermission_saved=game.profile.checkpoint_endless(game.model)
 var run=game.model.endless;var next=run.scaling(run.wave+1)
 page("WAVE %d CLEARED" % run.completed,"The world is paused: no passive income, cooldown recovery or repeated choice rewards. Choose one modest aid, then face one fresh Hunter.","intermission")
 ui.premium_icon("endless",Vector2(107,191),Vector2(110,110))
 ui.label_at("NEXT · WAVE %d · %s" % [run.wave+1,StrategyCatalog.ARCHETYPES[StrategyCatalog.ARCHETYPE_IDS[posmod(run.seed_value+run.wave,3)]].name],Vector2(245,193),30,900,true)
 paragraph("HP ×%.2f · damage ×%.2f · contact repairs %.0f%% of mode value%s\nBest cleared: %d · Gold %.2f · Electricity %.2f" % [next.hunter_hp,next.hunter_damage,run.repair_effectiveness(run.wave+1)*100," · REAPER ENCOUNTER" if run.boss_wave(run.wave+1) else "",game.profile.replay.best_wave,game.model.player().gold,game.model.player().electricity],Vector2(245,245),900,70,18)
 ui.button("Prepare defenses · frozen economy",Vector2(107,329),func():preparing=true;game.ui.show_match(),1068,36)
 var choices=[{"id":"repair","name":"Reinforce","text":"Restore 10% maximum HP to your intact door."},{"id":"supply","name":"Salvage","text":"Carry 25 extra Gold into the next wave."},{"id":"power","name":"Recharge","text":"Carry 5 extra Electricity into the next wave."}]
 for i in range(3):
  var data=choices[i];var choice=data.id;var at=Vector2(107+i*362,377)
  ui.box(Rect2(at,Vector2(342,144)))
  paragraph(data.text,at+Vector2(15,12),312,62,18)
  ui.button("Continue · "+data.name,at+Vector2(15,91),func():game.continue_endless(choice),312,39).disabled=not intermission_saved
 var claimed=int(game.profile.replay.milestone_wave);var eligible=mini(20,int(run.completed/5)*5)
 var eligible_text="none" if eligible==0 else "through wave %d" % eligible
 var claimed_text="none" if claimed==0 else "through wave %d" % claimed
 var upcoming="All four milestone bonuses claimed." if claimed>=20 else "Wave %d bonus eligible; awaiting wallet space." % (claimed+5) if eligible>=claimed+5 else "Next: wave %d, +8 RM / up to 20 XP." % (claimed+5)
 ui.label_at("THIS RUN ELIGIBLE: "+eligible_text+" · PROFILE CLAIMED: "+claimed_text+" · "+upcoming,Vector2(107,534),14,1060)
 paragraph("Checkpoint saved. Safe to exit; reload restores this intermission." if intermission_saved else "SAVE FAILED: remain here and retry. Continue is disabled until a safe save succeeds.",Vector2(107,571),1050,32,16)
 if intermission_saved:ui.button("End run here · keep earned records",Vector2(107,614),game.end_endless_here,518,42)
 ui.button("Save & exit to menu",Vector2(657,614),func():
  if game.profile.checkpoint_endless(game.model):game.return_menu()
  else:intermission_saved=false;show_intermission(),518,42).disabled=not intermission_saved
 if not intermission_saved:ui.button("Retry checkpoint save",Vector2(107,614),func():intermission_saved=game.profile.checkpoint_endless(game.model);show_intermission(),518,42)
func show_codes():
 page("CHALLENGE CODES","Share a local ruleset with friends. Fixed 30 Hz simulation and normalized gear/perks; inputs, platform and Godot version can still affect results. No online verification or permanent rewards.","challenge_codes")
 option(["Dorm","Hospital","Hotel","Laboratory","Mansion"],MapCatalog.IDS.find(selected_map),Vector2(107,190),340,func(i):selected_map=MapCatalog.IDS[i])
 option(["Crusher","Stalker","Ravager"],StrategyCatalog.ARCHETYPE_IDS.find(practice_archetype),Vector2(477,190),340,func(i):practice_archetype=StrategyCatalog.ARCHETYPE_IDS[i])
 option(["Normal","Long Night","Hell"],["standard","hard","hell"].find(difficulty),Vector2(847,190),328,func(i):difficulty=["standard","hard","hell"][i])
 var seed_field=input(seed_text,Vector2(107,260),340,func(text):seed_text=text);seed_field.max_length=6
 paragraph("Preset: 25G / 0E, no perks, room traits enabled. Loaned Shield + Repair Kit, two each. All 20 owned item stacks remain untouched.",Vector2(477,258),698,65,17)
 ui.button("Generate code",Vector2(107,339),func():
  code_text=ChallengeCode.encode({"map":selected_map,"archetype":practice_archetype,"difficulty":difficulty,"seed":seed_number(),"preset":0,"gear":0})
  notice="Generated normalized ruleset 1." if code_text!="" else "Seed must be 1–999999."
  show_codes(),340,44)
 var entry=input(code_text,Vector2(107,416),1068,func(text):
  code_text=text
  if is_instance_valid(notice_label):notice_label.text=code_preview())
 entry.placeholder_text="Paste an NF2 challenge code here"
 ui.button("Copy code",Vector2(107,488),func():copy_text(code_text),340,44)
 ui.button("Start coded challenge",Vector2(477,488),func():
  if not game.start_challenge(code_text):show_codes(),698,44)
 notice_label=paragraph(code_preview() if ChallengeCode.decode(code_text).ok or notice=="" else notice,Vector2(107,554),1060,48,15)
 ui.button("Back to replay chamber",Vector2(107,622),show_hub,400,42)
func copy_text(text: String):
 if text=="":notice="Nothing to copy.";return
 if DisplayServer.get_name()=="headless":notice="Clipboard unavailable in this renderer; select the text and copy it.";return
 DisplayServer.clipboard_set(text);notice="Copied to clipboard."
 if is_instance_valid(notice_label):notice_label.text=notice
func code_preview() -> String:
 var parsed=ChallengeCode.decode(code_text)
 if not parsed.ok:return "Paste a complete valid code, or generate one above."
 var c=parsed.config
 return "CODE RULES: %s · %s · %s · %dG /0E · no perks\nLoaned: %s, two each · room traits 1 · ruleset 1 / Godot 4.6 · Reaper after 70s/120s" % [MapCatalog.map(c.map).title,StrategyCatalog.ARCHETYPES[c.archetype].name,RankCatalog.DIFFICULTIES[c.difficulty].name,25 if int(c.preset)==0 else 15,"Shield + Repair" if int(c.gear)==0 else "Overdrive + Frost"]
func show_practice():
 page("PRACTICE ROOM","Real combat values, temporary 20,000 Gold / 5,000 Electricity and temporary item stock. No XP, RM, spins, achievements, records, pity or permanent inventory changes.","practice_setup")
 ui.premium_icon("practice",Vector2(107,185),Vector2(100,100))
 option(["Crusher","Stalker","Ravager"],StrategyCatalog.ARCHETYPE_IDS.find(practice_archetype),Vector2(245,190),420,func(i):practice_archetype=StrategyCatalog.ARCHETYPE_IDS[i])
 var boss=CheckButton.new();boss.text="Train Grim Reaper telegraphs";boss.position=Vector2(710,190);boss.size=Vector2(450,44);boss.button_pressed=practice_boss;boss.toggled.connect(func(value):practice_boss=value);ui.panel.add_child(boss)
 option(["Dorm","Hospital","Hotel","Laboratory","Mansion"],MapCatalog.IDS.find(practice_map),Vector2(245,255),420,func(i):practice_map=MapCatalog.IDS[i])
 var names=[]
 for id in ItemCatalog.IDS:names.append(ItemCatalog.ITEMS[id].name)
 ui.label_at("Temporary item slot 1",Vector2(107,345),18,500)
 ui.label_at("Temporary item slot 2",Vector2(657,345),18,500)
 option(names,ItemCatalog.IDS.find(practice_items[0]),Vector2(107,390),518,func(i):practice_items[0]=ItemCatalog.IDS[i];update_practice_selection())
 option(names,ItemCatalog.IDS.find(practice_items[1]),Vector2(657,390),518,func(i):practice_items[1]=ItemCatalog.IDS[i];update_practice_selection())
 paragraph("Start with a genuinely paid level 4 Needle on the nearest firing pad. Choose its L5 branch in the real inspector, build an Arc, repair with R, activate with 1/2. Pause offers RESET PRACTICE. Legendary limit remains one per reset; auto items trigger normally.",Vector2(107,467),1060,85,18)
 ui.button("Back",Vector2(107,614),show_hub,400,44)
 practice_hint=ui.label_at("",Vector2(107,565),16,1060)
 practice_start=ui.button("Begin Practice",Vector2(657,614),func():game.start_practice(practice_archetype,practice_boss,practice_items,practice_map),518,44)
 update_practice_selection()
func update_practice_selection():
 if is_instance_valid(practice_start):practice_start.disabled=practice_items[0]==practice_items[1]
 if is_instance_valid(practice_hint):practice_hint.text="Choose two different item types for the two temporary slots." if practice_items[0]==practice_items[1] else "Each selected item has five temporary uses; the Legendary cap still applies."
func show_cosmetics():
 page("EARNED APPEARANCES","Original visual equipment only. Damage, HP, income, electricity, prices, branches, Prestige 10 and progression are unchanged.","cosmetics")
 var index=0
 for id in CosmeticCatalog.ITEMS:
  var data=CosmeticCatalog.ITEMS[id];var selected=id;var unlocked=CosmeticCatalog.earned(game.profile,id);var at=Vector2(107+(index%2)*550,184+int(index/2)*210)
  ui.box(Rect2(at,Vector2(520,194)),"203747","B39F7C" if unlocked else "607D8B")
  ui.premium_icon(id,at+Vector2(10,16),Vector2(100,110))
  ui.label_at(data.name,at+Vector2(125,10),23,380,true)
  paragraph(data.description,at+Vector2(125,48),375,61,16)
  paragraph(("UNLOCKED · " if unlocked else "LOCKED · ")+data.condition,at+Vector2(125,111),375,35,14)
  var button=ui.button("Equipped ✓" if game.profile.replay.cosmetics[data.slot]==id else "Equip appearance" if unlocked else "Locked",at+Vector2(125,151),func():game.profile.equip_cosmetic(selected);show_cosmetics(),375,32)
  button.disabled=not unlocked or game.profile.read_only;index+=1
 ui.button("Back to replay chamber",Vector2(107,630),show_hub,400,38)
func show_session_result():
 var model=game.model
 page(("ENDLESS RUN ENDED" if model.run_kind=="endless" else "CHALLENGE "+model.result.to_upper() if model.run_kind=="challenge" else "PRACTICE "+model.result.to_upper()),"Actual local results. Challenge summaries are self-reported, not an online leaderboard. Practice has no permanent rewards.","replay_result")
 var line="Time %.1fs · Damage %.1f" % [model.time,model.damage_dealt]
 if model.run_kind=="endless":line+="\nCompleted wave %d · Best %d · Run %d" % [model.endless.completed,game.profile.replay.best_wave,model.endless.run_id]
 if model.run_kind=="challenge":
  var mode_name=RankCatalog.DIFFICULTIES[model.difficulty].name
  var archetype_name=StrategyCatalog.ARCHETYPES[model.hunter.archetype].name
  line+="\n"+model.challenge_code+"\n"+MapCatalog.map(model.map_id).title+" · "+mode_name+"\nNormalized rules %d · " % ChallengeCode.RULESET+archetype_name
 paragraph(line,Vector2(107,205),1060,160,24)
 if model.run_kind=="challenge":
  var record=game.profile.replay.challenge_best.get(model.challenge_code.sha256_text().left(16),{})
  paragraph("Personal best score %d · time of that score %.1fs · %s" % [record.get("score",0),record.get("time",0),str(record.get("outcome","unrecorded"))],Vector2(107,389),1050,50,18)
  ui.button("Copy result summary",Vector2(107,467),func():copy_text(challenge_result_summary()),500,44)
  if model.challenge_recorded:notice_label=ui.label_at("",Vector2(107,535),15,500)
  if not model.challenge_recorded:ui.button("Retry challenge record save",Vector2(107,535),func():game.profile.record_challenge(model);show_session_result(),500,44)
 if model.result=="defeat":ui.button("Why did I lose?",Vector2(657,467),show_defeat_analysis,518,44)
 if model.run_kind=="endless" and game.last_progression.is_empty() and not game.profile.save_ok:ui.button("Retry result save",Vector2(107,535),game.retry_settlement,500,44)
 ui.button("Main menu",Vector2(107,614),game.return_menu,400,44)
 ui.button("Reset Practice" if model.run_kind=="practice" else "Replay options",Vector2(657,614),game.reset_practice if model.run_kind=="practice" else show_hub,518,44)
func challenge_result_summary() -> String:
 var model=game.model
 if model.run_kind!="challenge":return ""
 return "Nightfall Dorm | %s | %s | %s | ruleset %d | %s | %s | %.2fs | damage %.1f | self-reported" % [model.challenge_code,MapCatalog.map(model.map_id).title,RankCatalog.DIFFICULTIES[model.difficulty].name,ChallengeCode.RULESET,StrategyCatalog.ARCHETYPES[model.hunter.archetype].name,model.result,model.time,model.damage_dealt]
func show_defeat_analysis():
 var facts=game.model.defeat_facts.report
 page("WHY DID I LOSE?","A compact factual record from your actual defeat, captured before result rewards changed inventory. It does not claim a single proven cause.","defeat_analysis")
 if facts.is_empty():paragraph("No eligible defeat telemetry is available.",Vector2(107,210),1050,80)
 else:
  paragraph("Final recorded source: %s · %s%s\nElapsed %.1fs · Gold %.2f · Electricity %.2f\nDoor level %d · manual repairs %d · recorded door damage %.1f" % [facts.source,StrategyCatalog.ARCHETYPES.get(facts.archetype,{}).get("name","Hunter")," / Reaper" if facts.reaper else "",facts.elapsed,facts.gold,facts.power,facts.door_level,facts.repairs,facts.damage],Vector2(107,191),1050,135,20)
  var buildings=[]
  for b in facts.buildings:buildings.append(Catalog.BUILDINGS[b.kind].name+" L%d" % b.level+(" / "+b.branch if b.branch!="" else ""))
  paragraph("Final buildings: "+(", ".join(buildings) if not buildings.is_empty() else "none"),Vector2(107,340),1050,65,16)
  var stock=[]
  for id in facts.unused:stock.append(ItemCatalog.ITEMS[id].name+" ×%d" % facts.unused[id])
  paragraph("Equipped stock at defeat: "+(", ".join(stock) if not stock.is_empty() else "none"),Vector2(107,413),1050,58,16)
  var history=[]
  for event in facts.get("door_history",[]).slice(-3):history.append(("Upgrade L%d" % event.level if event.type=="door_upgrade" else "Repair")+" @%.1fs" % event.time)
  var sequence=[]
  for event in facts.sequence.slice(-3):sequence.append(event.type.replace("_"," ")+" @%.1fs" % event.time)
  paragraph("Recent door history since start/resume: "+(", ".join(history) if not history.is_empty() else "none")+"\nFinal sequence this session: "+" → ".join(sequence),Vector2(107,475),1050,43,13)
  paragraph("\n".join(facts.tips),Vector2(107,528),1050,68,17)
 ui.button("Return to results",Vector2(107,622),ui.show_result if game.model.run_kind=="campaign" else show_session_result,440,42)
func update_hud():
 if not is_instance_valid(wave_label):return
 var m=game.model
 if m.run_kind=="endless":
  var scale=m.endless.scaling();wave_label.text="BEST %d · HP×%.1f · DMG×%.1f · REPAIR %.0f%%" % [game.profile.replay.best_wave,scale.hunter_hp,scale.hunter_damage,m.endless.repair_effectiveness()*100]
  wave_label.tooltip_text="Wave factors; mode and archetype modifiers also apply. Contact repair multiplier composes with the selected mode. One fresh Hunter per wave; one Legendary for the entire run."
