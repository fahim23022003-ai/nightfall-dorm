extends RefCounted
## Story screens reuse the regular Inventory and permanent-perk editors.
const MODES := ["standard","hard","hell"]
const GOLD := "D9BC83"
const BODY := "C0CBCD"
const QUIET := "8EAAAB"

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
 ui.box(Rect2(83,46,1114,628),"192631","748691")
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
 ui.box(Rect2(124,381,1030,119),"22333B","566D72")
 if track.finished:
  _line("DAWN HAS RETURNED",Vector2(143,398),23,970,GOLD,true)
  _line("This difficulty track is complete. Its chapters are available in the Story Archive.",Vector2(145,446),17,970,BODY)
 else:
  var enemy: Dictionary=StrategyCatalog.ARCHETYPES[mission.archetype]
  ui.premium_icon(mission.archetype,Vector2(145,402),Vector2(60,60))
  _line(mission.objective,Vector2(224,392),22,900,"E6DBBF",true)
  var setting: String=MapCatalog.map(mission.theme).title
  if game.model.procedural_v2_requested:setting+="  /  "+mission.topology.replace("_"," ").capitalize()
  _paragraph("%s   ·   %s" % [setting,enemy.hint],Rect2(225,426,886,58),16,BODY)
 var slots:=_loadout_text(p)
 _line(slots,Vector2(125,515),16,1023,BODY)
 var support: String=notice if not notice.is_empty() else p.warning if p.warning!="" else "First-clear XP is shared across modes. A loss drops one level, down to your checkpoint."
 _line(support,Vector2(125,553),15,1022,"E3AE8D" if not notice.is_empty() or p.warning!="" else QUIET)
 ui.button("Main menu",Vector2(123,605),game.return_menu,170,40)
 ui.button("Items",Vector2(309,605),ui.items_ui.inventory,151,40)
 ui.button("Perks",Vector2(475,605),ui.progression.show_perk_loadout,148,40)
 var launch: Button=ui.button("STORY ARCHIVE" if track.finished else "START MISSION",Vector2(828,595),func():
  if track.finished:show_archive()
  elif not game.start_story(mode) and ui.current_screen=="story_prepare":
   notice=p.warning if p.warning!="" else "Mission could not start. Confirm that the profile can be saved."
   show_prepare(),326,52)
 launch.name="StartStoryMission"
 launch.disabled=p.read_only and not track.finished

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
 if reveal:_line("Your saved item reward opens first.",Vector2(280,517),14,715,QUIET)
 var next: Button=ui.button("STORY ARCHIVE" if completed else "CONTINUE STORY" if won else "TRY AGAIN",Vector2(278,565),func():
  if reveal:ui.items_ui.spin()
  elif completed:
   game.return_menu()
   show_archive()
  else:show_prepare(),432,52)
 next.name="ContinueStoryResult"
 ui.button("Main menu",Vector2(744,567),game.return_menu,254,48)
 if not bool(options.get("reduced_effects",false)):
  card.modulate.a=.35
  card.create_tween().tween_property(card,"modulate",Color.WHITE,.34)

func _position_text(label: Label, report: Dictionary, current: int):
 label.text="STORY COMPLETE   ·   LEVEL 50" if report.finished else "STORY %s   ·   %02d → %02d" % ["LEVEL" if report.cleared else "POSITION",report.level,current]

func show_archive():
 if game.mode=="result":game.return_menu()
 ui.progression.story_context=false
 _begin_screen("story_archive")
 game.audio_event("menu")
 ui.box(Rect2(94,48,1092,620),"1B2934","778690")
 _line("STORY ARCHIVE",Vector2(135,75),40,978,"E6DBBF",true)
 _line("Revisit chapter openings and the final ending after reaching them.",Vector2(138,135),17,960,BODY)
 var highest:=0
 for mode: String in MODES:
  highest=maxi(highest,int(StoryProgress.summary(game.profile.story,mode).highest))
 for chapter in range(1,StoryCatalog.CHAPTERS.size()+1):
  var visited: bool=(chapter-1)*StoryCatalog.CHAPTER_LENGTH<=highest
  var title: String=StoryCatalog.CHAPTERS[chapter-1][0]
  var selected:=chapter
  var at:=Vector2(139+(chapter-1)%2*507,187+floori(float(chapter-1)/2.0)*65)
  var button: Button=ui.button("%02d   ·   %s%s" % [chapter,title,"   ·   Locked" if not visited else ""],at,func():_archive_page(selected),477,47)
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
