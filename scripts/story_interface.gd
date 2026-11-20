extends RefCounted
## Story screens reuse the regular Inventory and permanent-perk editors.
const MODES := ["standard","hard","hell"]
const GOLD := "D2B47B"
const BODY := "BAC8D6"
const QUIET := "BAC8D6"

var ui
var game
var notice:=""

func _init(owner):
 ui=owner
 game=ui.game

func show_prepare():
 if game.mode=="result":game.return_menu()
 ui.progression.story_context=true
 game.campaign_mode=true
 var p: PlayerProfile=game.profile
 var mode: String=p.selected_difficulty
 var track:=StoryProgress.summary(p.story,mode)
 var mission:=StoryCatalog.mission(track.position)
 _begin_screen("story_prepare")
 game.audio_event("menu")
 if game.survivor_preview_enabled and not game.mobile_mode and ui.has_method("theme_panel"):
  _show_preparation(p,mode,track,mission)
  return
 ui.box(Rect2(83,46,1114,628),"192631",GOLD)
 _line("STORY MODE     /     CHAPTER %02d  ·  %s" % [mission.chapter,mission.chapter_title.to_upper()],Vector2(123,76),15,935,GOLD)
 _line("LEVEL %02d     %s" % [mission.level,mission.title],Vector2(120,108),40,968,"E6DBBF",true)
 ui.progression.badge(p.rank_index(),Vector2(1092,80),66)
 _line("%02d / 50 cleared   ·   Checkpoint floor %02d   ·   %s" % [track.highest,track.checkpoint,RankCatalog.DIFFICULTIES[mode].name],Vector2(123,165),17,1005,BODY)
 _progress(track.highest,Vector2(124,205),1030)
 var clue: String=StoryCatalog.ENDING if track.finished else mission.briefing
 if not track.finished and mission.chapter_start:
  clue=mission.chapter_opening+"\n"+clue
 var briefing:=_paragraph(clue,Rect2(124,227,1028,72),17 if mission.chapter_start else 20,"D8CEBB")
 if not track.finished and mission.chapter_start and not p.settings.get("reduced_effects",false):
  briefing.modulate.a=0.0
  briefing.create_tween().tween_property(briefing,"modulate:a",1.0,.52)
 for i in range(MODES.size()):
  var picked: String=MODES[i]
  var state:=StoryProgress.summary(p.story,picked)
  var button: Button=ui.button(("%s   ·   " % RankCatalog.DIFFICULTIES[picked].name)+("Complete" if state.finished else "Level %02d" % state.position),Vector2(124+i*346,309),func(): _select(picked),331,54)
  button.name="StoryDifficulty_"+picked
  button.toggle_mode=true
  button.button_pressed=mode==picked
  button.disabled=p.read_only
  button.icon=PremiumButton.texture(picked)
  button.expand_icon=true
  button.add_theme_constant_override("icon_max_width",25)
 ui.box(Rect2(124,381,1030,119),"2D3D4C","66788A")
 if track.finished:
  _line("DAWN HAS RETURNED",Vector2(143,398),23,970,GOLD,true)
  _line("This difficulty track is complete. Its chapters are available in the Story Archive.",Vector2(145,446),17,970,BODY)
 else:
  var enemy: Dictionary=StrategyCatalog.ARCHETYPES[mission.archetype]
  ui.premium_icon(mission.archetype,Vector2(145,402),Vector2(60,60))
  _line(mission.objective,Vector2(224,392),22,900,"E6DBBF",true)
  var setting: String=MapCatalog.map(mission.theme).title
  if game.model.procedural_v2_requested:setting+="  /  "+mission.topology.replace("_"," ").capitalize()
  if StoryCatalog.phase16_enabled():
   _paragraph("%s   ·   %s" % [setting,enemy.hint],Rect2(225,423,886,44),15,BODY)
   _line(_encounter_summary(mission,mode),Vector2(225,467),14,895,GOLD).name="StoryEncounterTiming"
  else:
   _paragraph("%s   ·   %s" % [setting,enemy.hint],Rect2(225,426,886,58),16,BODY)
 var slots:=_loadout_text(p)
 _line(slots,Vector2(125,515),16,1023,BODY)
 var support: String=notice if not notice.is_empty() else p.warning if p.warning!="" else "First-clear XP is shared across modes. A loss drops one level, down to your checkpoint."
 _line(support,Vector2(125,553),15,1022,"E3AE8D" if not notice.is_empty() or p.warning!="" else QUIET)
 ui.button("‹ Main menu",Vector2(123,605),game.return_menu,170,40)
 ui.button("Item loadout",Vector2(309,605),ui.items_ui.inventory,151,40)
 ui.button("Perks",Vector2(475,605),ui.progression.show_perk_loadout,148,40)
 var launch: Button=ui.button("STORY ARCHIVE" if track.finished else "START MISSION",Vector2(828,595),func():_launch(mode,track.finished),326,52)
 launch.name="StartStoryMission"
 launch.disabled=p.read_only and not track.finished

func _show_preparation(profile: PlayerProfile, mode: String, track: Dictionary, mission: Dictionary):
 ui.theme_backdrop()
 ui.theme_panel(Rect2(72,46,1136,628),"frame")
 _line("STORY PREPARATION   ·   CHAPTER %02d  /  %s" % [mission.chapter,mission.chapter_title.to_upper()],Vector2(110,78),15,986,GOLD)
 _line("LEVEL %02d   %s" % [mission.level,mission.title],Vector2(106,104),42,1010,"F4F0E8",true)
 ui.progression.badge(profile.rank_index(),Vector2(1106,72),58)
 _line("%02d of 50 cleared   ·   Checkpoint %02d" % [track.highest,track.checkpoint],Vector2(110,164),16,800,BODY)
 _progress(track.highest,Vector2(110,193),1060)
 for i in range(MODES.size()):
  var picked: String=MODES[i]
  var difficulty: Dictionary=StoryProgress.summary(profile.story,picked)
  var text: String=RankCatalog.DIFFICULTIES[picked].name+"  ·  "+("Complete" if difficulty.finished else "Level %02d" % difficulty.position)
  var choice: Button=ui.button(text,Vector2(110+i*359,225),func():_select(picked),341,47)
  choice.name="StoryDifficulty_"+picked
  choice.toggle_mode=true
  choice.button_pressed=mode==picked
  choice.disabled=profile.read_only
  ui.theme_button(choice,"selected" if mode==picked else "secondary",picked)
 ui.theme_panel(Rect2(110,294,652,260),"card")
 _line("MISSION BRIEFING",Vector2(131,314),15,610,GOLD)
 var chapter_rules := StoryCatalog.phase16_enabled()
 var caption: String=StoryCatalog.ENDING if track.finished else mission.briefing
 if chapter_rules and not track.finished:
  if mission.chapter_start:
   caption=mission.chapter_opening+"\n"+caption
  _paragraph(caption,Rect2(131,337,609,68),15 if mission.chapter_start else 19,"F4F0E8").name="StoryBriefing"
  var route: String=MapCatalog.map(mission.theme).title
  if game.model.procedural_v2_requested:route+=" · "+mission.topology.replace("_"," ").capitalize()
  _line(route,Vector2(131,403),15,610,BODY).name="StoryRoutePreview"
  _line(_encounter_summary(mission,mode),Vector2(131,426),14,614,GOLD).name="StoryEncounterTiming"
  ui.premium_icon(mission.archetype,Vector2(132,465),Vector2(48,48))
  _line(mission.objective,Vector2(194,453),19,548,"F4F0E8",true)
  _paragraph(StrategyCatalog.ARCHETYPES[mission.archetype].hint,Rect2(195,483,545,59),14,BODY)
 else:
  _paragraph(caption,Rect2(131,353,609,91),20,"F4F0E8")
  if not track.finished:
   ui.premium_icon(mission.archetype,Vector2(132,459),Vector2(53,53))
   _line(mission.objective,Vector2(199,451),19,535,"F4F0E8",true)
   _paragraph("%s · %s" % [MapCatalog.map(mission.theme).title,StrategyCatalog.ARCHETYPES[mission.archetype].hint],Rect2(200,483,537,59),14,BODY)
 ui.theme_panel(Rect2(782,294,388,260),"card")
 _line("YOUR LOADOUT",Vector2(802,314),15,350,GOLD)
 var names:=PackedStringArray()
 for id in profile.item_loadout:names.append(ItemCatalog.ITEMS[id].name)
 _line("Consumables   %d / %d" % [names.size(),ItemCatalog.SLOTS],Vector2(802,349),18,343,"F4F0E8")
 _paragraph(", ".join(names) if not names.is_empty() else "No consumables equipped",Rect2(802,378,341,59),15,BODY)
 _line("%s rank   ·   %d / %d perks" % [profile.rank_name(),profile.equipped.size(),profile.perk_slots()],Vector2(802,441),16,340,BODY)
 ui.theme_button(ui.button("Edit items",Vector2(802,488),ui.items_ui.inventory,170,42),"inventory","inventory")
 ui.theme_button(ui.button("Rank perks",Vector2(987,488),ui.progression.show_perk_loadout,161,42),"secondary","rank")
 var support: String=notice if notice!="" else profile.warning if profile.warning!="" else "A lost night drops one level, down to the earned checkpoint."
 _line(support,Vector2(110,571),15,1059,BODY)
 ui.theme_button(ui.button("‹ Main menu",Vector2(110,609),game.return_menu,180,40),"quiet")
 var launch: Button=ui.button("STORY ARCHIVE" if track.finished else "START MATCH",Vector2(832,600),func():_launch(mode,track.finished),338,49)
 launch.name="StartStoryMission"
 launch.disabled=profile.read_only and not track.finished
 ui.theme_button(launch,"primary","play")
 launch.grab_focus()

func _encounter_summary(mission: Dictionary, mode: String) -> String:
 var encounter: Dictionary=mission.encounter
 var parts: PackedStringArray=["%ds to prepare" % encounter.preparation]
 if game.model.procedural_v2_requested:
  parts.append("Hall recovery %ds after arrival" % encounter.hall)
 parts.append("Reaper can awaken" if StoryCatalog.reaper_policy(mission,mode).enabled else "First form only")
 return " · ".join(parts)

func _launch(mode: String, finished: bool):
 if finished:
  show_archive()
 elif not game.open_story_lobby(mode) and ui.current_screen=="story_prepare":
  notice=game.profile.warning if game.profile.warning!="" else "Mission could not start. Confirm that the profile can be saved."
  show_prepare()

func _select(mode: String):
 if game.profile.select_difficulty(mode):
  notice=""
  show_prepare()
 else:
  notice="Could not save the selected difficulty."
  show_prepare()

func _loadout_text(p: PlayerProfile) -> String:
 var items:=PackedStringArray()
 var perks:=PackedStringArray()
 for id in p.item_loadout:items.append(ItemCatalog.ITEMS[id].name)
 for perk in RankCatalog.PERKS:
  if perk.id in p.equipped:perks.append(perk.name)
 return "Consumables %d / %d  ·  %s     |     Perks %d / %d  ·  %s" % [
  items.size(),ItemCatalog.SLOTS,", ".join(items) if not items.is_empty() else "None",
  perks.size(),p.perk_slots(),", ".join(perks) if not perks.is_empty() else "None",
 ]

func show_result():
 _begin_screen("story_result")
 var result: Dictionary=game.last_progression.get("story",{})
 var mission:=StoryCatalog.mission(game.model.story_level)
 var mode: String=game.model.difficulty
 var won: bool=game.model.result=="victory"
 var completed: bool=result.get("finished",false)
 if StoryCatalog.phase16_enabled() and not result.is_empty():
  _show_chapter_result(mission,result,mode,won)
  return
 var veil:=ColorRect.new()
 veil.color=Color("10171E")
 veil.color.a=.88
 veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
 veil.size=Vector2(1280,720)
 ui.panel.add_child(veil)
 var edge: String="A98B5C" if won else "A56871"
 var card: Panel=ui.box(Rect2(229,68,822,584),"1A2630",edge)
 _line(RankCatalog.DIFFICULTIES[mode].name.to_upper()+"     /     "+mission.chapter_title.to_upper(),Vector2(276,105),16,728,GOLD)
 _line("DAWN SURVIVED" if completed else "NIGHT SURVIVED" if won else "NIGHT LOST",Vector2(272,138),54,730,"E7DAB5" if won else "DEABA8",true)
 _line("LEVEL %02d   %s" % [mission.level,mission.title],Vector2(278,215),25,718,BODY,true)
 if result.is_empty():
  _line("Story progress is waiting for a safe save.",Vector2(279,275),20,715,BODY)
  ui.button("Retry save",Vector2(277,570),game.retry_settlement,430,48)
  ui.button("Main menu",Vector2(744,570),game.return_menu,255,48)
  return
 var next_position: int=result.position
 var position_label:=_line("",Vector2(279,275),25,718,GOLD,true)
 _position_text(position_label,result,mission.level)
 var options: Dictionary=game.profile.settings
 if not bool(options.get("reduced_effects",false)) and next_position!=mission.level:
  position_label.create_tween().tween_method(func(level: float):_position_text(position_label,result,roundi(level)),float(mission.level),float(next_position),.65).set_delay(.35)
 var following: String=StoryCatalog.ENDING if completed else ("Next  ·  Level %02d  ·  %s" if won else "Retry  ·  Level %02d  ·  %s") % [next_position,result.next_title]
 _paragraph(following,Rect2(280,325,718,57),19,BODY)
 var floor_text: String="Checkpoint %02d   ·   Highest clear %02d" % [result.checkpoint,result.highest]
 if not won and next_position==mission.level:
  floor_text+="   ·   Checkpoint held"
 _line(floor_text,Vector2(280,394),15,715,QUIET)
 var rank:=int(game.last_progression.get("new_rank",game.profile.rank_index()))
 var badge: TextureRect=ui.progression.badge(rank,Vector2(279,431),65)
 var promoted:=bool(game.last_progression.get("promoted",false))
 var rank_name: String=RankCatalog.NAMES[rank]
 var growth:=int(game.last_progression.get("new_xp",0))-int(game.last_progression.get("old_xp",0))
 _line("PROMOTED TO "+rank_name.to_upper() if promoted else "PERMANENT RANK   ·   "+rank_name.to_upper(),Vector2(356,439),19,635,GOLD if promoted else BODY,true)
 _line("+%d XP earned%s" % [growth,"   ·   First-clear bonus %d XP" % result.reward_xp if result.first_clear else ""],Vector2(356,470),15,635,BODY)
 if promoted:
  game.audio_event("perk_unlocked")
  if not bool(options.get("reduced_effects",false)):
   badge.pivot_offset=badge.size*.5
   badge.scale=Vector2(.65,.65)
   badge.create_tween().tween_property(badge,"scale",Vector2.ONE,.55).set_trans(Tween.TRANS_BACK)
 var reveal: bool=not game.profile.pending_spins.is_empty()
 if game.survivor_preview_enabled:
  _line("RM CASH EARNED  +%d    ·    CURRENT BALANCE  %d RM" % [
   int(game.last_progression.get("rm_cash",0)),int(game.last_progression.get("rm_balance",game.profile.rm_cash))],Vector2(280,515),17,715,GOLD,true)
 elif reveal:
  _line("Your saved item reward opens first.",Vector2(280,517),14,715,QUIET)
 var next: Button=ui.button("STORY ARCHIVE" if completed else "CONTINUE STORY",Vector2(278,565),func():
  if reveal:ui.items_ui.spin()
  elif completed:
   game.return_menu()
   show_archive()
  else:show_prepare(),272,52)
 next.name="ContinueStoryResult"
 if ui.has_method("theme_button"):ui.theme_button(next,"primary","play")
 if game.survivor_preview_enabled:
  ui.button("Prepare items",Vector2(562,569),func():
   game.return_menu()
   show_prepare()
   ui.items_ui.inventory(),144,44)
  ui.button("Shop",Vector2(717,569),ui.shop.show_shop,109,44).name="StoryResultShop"
 ui.button("Main menu",Vector2(835,569),game.return_menu,165,44)
 if not bool(options.get("reduced_effects",false)):
  card.modulate.a=.35
  card.create_tween().tween_property(card,"modulate",Color.WHITE,.34)

func _show_chapter_result(mission: Dictionary, result: Dictionary, mode: String, won: bool) -> void:
 ui.theme_backdrop()
 ui.theme_panel(Rect2(203,51,874,618),"frame")
 var completed: bool=result.finished
 _line("CHAPTER %02d  /  %s  ·  %s" % [mission.chapter,mission.chapter_title.to_upper(),RankCatalog.DIFFICULTIES[mode].name],Vector2(244,74),16,797,GOLD)
 _line("DAWN SURVIVED" if completed else "MISSION CLEARED" if won else "NIGHT LOST",Vector2(239,103),47,804,"F4F0E8" if won else "FFD9DE",true)
 _line("LEVEL %02d · %s" % [mission.level,mission.title],Vector2(244,170),25,785,"F4F0E8",true).name="StoryResultMission"
 var next_position: int=result.position
 var next_level: String="Story complete · Level 50" if completed else ("%s Level %02d · %s" % ["Next" if won else "Retry",next_position,result.next_title])
 _line(next_level,Vector2(247,226),19,787,"F4F0E8").name="StoryResultNextMission"
 _line("Checkpoint %02d  ·  Highest clear %02d" % [result.checkpoint,result.highest],Vector2(247,261),16,786,BODY).name="StoryResultCheckpoint"
 if won:
  ui.theme_panel(Rect2(242,308,796,124),"card")
  _line("LORE REVEALED",Vector2(261,325),16,755,GOLD)
  _paragraph(StoryCatalog.ENDING if completed else mission.discovery,Rect2(261,360,755,55),19,"F4F0E8").name="StoryResultDiscovery"
 else:
  _paragraph("You will resume at the current checkpoint." if next_position==result.checkpoint else "Prepare your loadout before the next attempt.",Rect2(247,314,787,56),18,BODY)
 var award: Dictionary=game.last_progression
 var growth: int=int(award.get("new_xp",0))-int(award.get("old_xp",0))
 var first_clear: String=" · includes %d first-clear XP" % result.reward_xp if result.first_clear else ""
 _line("+%d XP%s  ·  %s rank" % [growth,first_clear,game.profile.rank_name()],Vector2(247,459),17,788,GOLD).name="StoryResultReward"
 if game.survivor_preview_enabled:
  _line("+%d RM Cash  ·  Wallet %d RM" % [int(award.get("rm_cash",0)),int(award.get("rm_balance",game.profile.rm_cash))],Vector2(247,494),17,788,BODY)
 var reveal: bool=not game.profile.pending_spins.is_empty()
 if reveal:
  _line("A saved item reward opens before the next mission.",Vector2(247,530),15,786,BODY)
 var continue_button: Button=ui.button("Story Archive" if completed else "Continue Story",Vector2(245,581),func():
  if reveal:
   ui.items_ui.spin()
  elif completed:
   show_archive()
  else:
   show_prepare(),248,49)
 continue_button.name="ContinueStoryResult"
 ui.theme_button(continue_button,"primary","play")
 if game.survivor_preview_enabled:
  ui.theme_button(ui.button("Items",Vector2(507,583),func():
   game.return_menu()
   show_prepare()
   ui.items_ui.inventory(),164,46),"inventory","inventory")
  var shop: Button=ui.button("Shop",Vector2(684,583),ui.shop.show_shop,132,46)
  shop.name="StoryResultShop"
  ui.theme_button(shop,"shop","shop")
 ui.theme_button(ui.button("Main menu",Vector2(829,583),game.return_menu,205,46),"quiet")
 if bool(award.get("promoted",false)):
  game.audio_event("perk_unlocked")

func _position_text(label: Label, report: Dictionary, current: int):
 label.text="STORY COMPLETE   ·   LEVEL 50" if report.finished else "STORY %s   ·   %02d → %02d" % ["LEVEL" if report.cleared else "POSITION",report.level,current]

func show_archive():
 if game.mode=="result":game.return_menu()
 ui.progression.story_context=false
 _begin_screen("story_archive")
 game.audio_event("menu")
 ui.box(Rect2(94,48,1092,620),"1B2934","778690")
 _line("STORY ARCHIVE",Vector2(135,75),40,978,"E6DBBF",true)
 _line("Revisit chapter openings, discoveries and the final ending." if StoryCatalog.phase16_enabled() else "Revisit chapter openings and the final ending after reaching them.",Vector2(138,135),17,960,BODY)
 var highest:=0
 for mode: String in MODES:
  highest=maxi(highest,int(StoryProgress.summary(game.profile.story,mode).highest))
 for chapter in range(1,StoryCatalog.CHAPTERS.size()+1):
  var visited: bool=(chapter-1)*StoryCatalog.CHAPTER_LENGTH<=highest
  var title: String=StoryCatalog.CHAPTERS[chapter-1][0]
  var selected:=chapter
  var at:=Vector2(139+(chapter-1)%2*507,187+floori(float(chapter-1)/2.0)*65)
  var button: Button=ui.button("%02d   ·   %s%s" % [chapter,title,"   ·   Locked" if not visited else ""],at,func():_archive_page(selected),477,47)
  button.name="StoryArchiveChapter_%02d" % chapter
  button.disabled=not visited
 ui.button("Extras",Vector2(139,588),ui.replay_ui.show_hub,175,44)
 ui.button("Classic Campaign",Vector2(337,588),ui.campaign.show_stages,270,44)
 ui.button("Read final ending",Vector2(807,588),func():_archive_page(0),315,44).disabled=highest<StoryCatalog.FINAL_LEVEL

func _archive_page(chapter: int):
 _begin_screen("story_archive_chapter")
 ui.box(Rect2(169,100,942,520),"192733","778690")
 var title: String=StoryCatalog.CHAPTERS[chapter-1][0] if chapter>0 else "Dawn or Oblivion"
 var clue: String=StoryCatalog.CHAPTERS[chapter-1][1] if chapter>0 else StoryCatalog.ENDING
 _line("CHAPTER %02d" % chapter if chapter>0 else "THE END",Vector2(220,149),17,828,GOLD)
 _line(title,Vector2(216,191),46,833,"E6DBBF",true)
 if StoryCatalog.phase16_enabled() and chapter>0:
  _paragraph(clue,Rect2(220,250,819,75),20,BODY)
  var highest:=0
  for mode: String in MODES:
   highest=maxi(highest,int(StoryProgress.summary(game.profile.story,mode).highest))
  var first_level: int=(chapter-1)*StoryCatalog.CHAPTER_LENGTH+1
  for level in range(first_level,mini(highest,first_level+StoryCatalog.CHAPTER_LENGTH-1)+1):
   _paragraph("%02d  ·  %s" % [level,StoryCatalog.mission(level).discovery],Rect2(225,329+(level-first_level)*31,805,30),15,BODY).name="StoryArchiveDiscovery_%02d" % level
 else:
  _paragraph(clue,Rect2(220,279,819,127),26,BODY)
 ui.button("Return to archive",Vector2(220,526),show_archive,316,54)

func _line(value: String, at: Vector2, font_size: int, width: float, tint: String, heading: bool=false) -> Label:
 var label: Label=ui.label_at(value,at,font_size,width,heading)
 label.modulate=Color(tint)
 label.clip_text=true
 return label

func _paragraph(value: String, area: Rect2, font_size: int, tint: String) -> Label:
 var label:=_line(value,area.position,font_size,area.size.x,tint)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size=area.size
 return label

func _progress(value: int, at: Vector2, width: float):
 var progress:=ProgressBar.new()
 progress.name="StoryProgress"
 progress.position=at
 progress.show_percentage=false
 progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
 progress.custom_minimum_size=Vector2(width,8)
 progress.max_value=StoryCatalog.FINAL_LEVEL
 progress.value=value
 var background:=StyleBoxFlat.new()
 background.bg_color=Color("111D24")
 background.set_corner_radius_all(5)
 progress.add_theme_stylebox_override("background",background)
 var fill:=StyleBoxFlat.new()
 fill.bg_color=Color(GOLD)
 fill.set_corner_radius_all(5)
 progress.add_theme_stylebox_override("fill",fill)
 ui.panel.add_child(progress)

func _begin_screen(screen: String):
 ui.clear()
 # A difficulty click rebuilds this panel inside the pressed callback.
 # Detach the retired view so the incoming controls keep their names.
 for child in ui.panel.get_children():
  if child.is_queued_for_deletion():ui.panel.remove_child(child)
 ui.current_screen=screen
