class_name ProgressionInterface
extends RefCounted

var ui
var game
var difficulty="standard"

func _init(owner_ui):
 ui=owner_ui
 game=ui.game

func badge(rank: int,pos: Vector2,size=72):
 var art=TextureRect.new()
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.texture=load("res://assets/ranks/"+RankCatalog.NAMES[rank].to_lower()+".svg")
 art.position=pos
 art.size=Vector2(size,size)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.panel.add_child(art)
 return art

func menu_summary():
 var p=game.profile
 badge(p.rank_index(),Vector2(444,398),76)
 var next=p.promotion_requirement()
 ui.label_at("%s · %d XP" % [p.rank_name(),p.xp],Vector2(430,488),16,240)
 var progress=ui.label_at(next,Vector2(430,519),13,224)
 progress.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 progress.size=Vector2(224,80)
 progress.set_deferred("size",Vector2(224,80))
 ui.button("Ranks & rewards",Vector2(72,596),show_ranks,330,44)
 if p.warning!="":
  var notice=ui.label_at(p.warning,Vector2(430,608),13,224)
  notice.clip_text=true
  notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  notice.size=Vector2(224,62)
  notice.set_deferred("size",Vector2(224,62))
  notice.modulate=Color("FFD27A")

func show_ranks():
 if game.mode=="result": game.return_menu()
 if game.mobile_mode:
  game.mobile_ui.show_rewards(ui,false)
  return
 ui.clear()
 game.audio_event("menu")
 ui.box(Rect2(60,40,1160,638))
 var p=game.profile
 var art=badge(p.rank_index(),Vector2(86,62),100)
 var pulse=art.create_tween().set_loops()
 pulse.tween_property(art,"modulate",Color(1.15,1.05,1.25),1.2)
 pulse.tween_property(art,"modulate",Color.WHITE,1.2)
 ui.label_at("%s · %d lifetime XP" % [p.rank_name().to_upper(),p.xp],Vector2(205,65),28,940,true)
 ui.label_at("Highest: %s · %s" % [RankCatalog.NAMES[p.highest_rank],p.promotion_requirement()],Vector2(205,108),15,940)
 var rank=p.rank_index()
 var base=RankCatalog.THRESHOLDS[rank]
 var target=RankCatalog.THRESHOLDS[mini(6,rank+1)]
 var bar=ProgressBar.new()
 bar.position=Vector2(205,143)
 bar.size=Vector2(930,18)
 bar.max_value=1 if rank==6 else target-base
 bar.value=1 if rank==6 else clampi(p.xp-base,0,target-base)
 ui.panel.add_child(bar)
 for i in range(7):
  badge(i,Vector2(90+i*157,180),58)
  ui.label_at("%s\n%d XP" % [RankCatalog.NAMES[i],RankCatalog.THRESHOLDS[i]],Vector2(94+i*157,239),15,145)
 var st=p.statistics
 ui.label_at("RECORDS · %d matches · %d wins / %d defeats · Reapers %d · Stage %d/5" % [st.matches,st.victories,st.defeats,st.reaper_defeats,p.highest_completed_stage()],Vector2(92,292),19,1060,true)
 ui.label_at("Tracked since this update · Normal %d · Long Night %d · Hell %d wins" % [st.standard,st.hard,st.hell],Vector2(92,323),17,1060)
 var records=[]
 for stage in StageCatalog.STAGES:
  var record=p.stage_record(stage.id)
  records.append("%d: uncleared" % stage.number if record.is_empty() else "%d: %.1fs / %dXP" % [stage.number,record.best_time,record.best_xp])
 ui.label_at("Best stages · "+" · ".join(records),Vector2(92,352),15,1060)
 ui.label_at("PERMANENT BOOSTS · one equipped · Mythic grants prestige, no extra gameplay perk",Vector2(92,389),18,1060,true)
 for i in range(6):
  var perk=RankCatalog.PERKS[i]
  var pos=Vector2(92+(i%2)*544,424+int(i/2)*51)
  var owned=perk.id in p.unlocked()
  var id=perk.id
  ui.label_at(perk.name+" · "+("Unlocked" if owned else RankCatalog.NAMES[i]+" required"),pos,16,400)
  var button=ui.button("Equipped" if id in p.equipped else "Equip",pos+Vector2(416,-5),func():
   if p.equip(id): game.audio_event("reward")
   show_ranks(),106,36)
  button.tooltip_text=perk.description
  button.disabled=not owned or p.read_only
 ui.label_at("Wins: 120 base + performance + stage/reaper bonuses, then difficulty. Losses: ≤1 XP/30s, cap30.",Vector2(92,584),14,1060)
 ui.button("Back",Vector2(92,622),ui.show_menu,180,40)
 ui.button("Choose loadout",Vector2(900,622),func(): ui.campaign.prepare(game.profile.selected_stage),270,40)

func show_loadout():
 if game.mode=="result": game.return_menu()
 if game.mobile_mode:
  game.mobile_ui.show_rewards(ui,true)
  return
 ui.clear()
 ui.current_screen="loadout"
 game.audio_event("menu")
 ui.box(Rect2(90,40,1100,640))
 var stage=StageCatalog.stage(game.profile.selected_stage) if game.campaign_mode else {}
 ui.label_at("STAGE %d · %s" % [stage.number,stage.title] if not stage.is_empty() else "PREPARE FOR THE NIGHT",Vector2(125,68),27,950,true)
 badge(game.profile.rank_index(),Vector2(1090,58),64)
 var preparation="Choose at most %d unlocked boost. Selection is saved; bots receive no rank bonuses." % RankCatalog.MAX_EQUIPPED
 if not stage.is_empty(): preparation="Defeat the hunter · Prep %ds · Hunter HP ×%.2f / damage ×%.2f / speed ×%.2f" % [stage.preparation,stage.hunter_hp,stage.hunter_damage,stage.hunter_speed]
 ui.label_at(preparation,Vector2(125,117),17,980)
 if not stage.is_empty():
  var boss=BossCatalog.encounter(stage.id,difficulty)
  var encounter=" · Reaper: after %ds at ≤55%% HP, or %ds. No healing." % [boss.opening,boss.deadline] if boss.enabled else " · Introductory encounter: no Reaper transformation."
  ui.label_at(MapCatalog.map(stage.map).get("title","")+encounter,Vector2(125,143),15,980)
 for i in range(6):
  var item=RankCatalog.PERKS[i]
  var owned=item.id in game.profile.unlocked()
  var at=Vector2(125+(i%2)*520,168+int(i/2)*110)
  var id=item.id
  var text=ui.label_at(item.name+"\n"+item.description,at,18,370)
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  text.size=Vector2(370,90)
  var b=ui.button("Equipped ✓" if id in game.profile.equipped else ("Equip" if owned else RankCatalog.NAMES[i]),at+Vector2(378,10),func():
   if game.profile.equip(id): game.audio_event("reward")
   show_loadout(),120,44)
  b.disabled=not owned or game.profile.read_only
 ui.label_at("DIFFICULTY",Vector2(125,506),19,250,true)
 for index in range(3):
  var key=["standard","hard","hell"][index]
  var selected=key
  var b=ui.button(("✓ " if difficulty==key else "")+RankCatalog.DIFFICULTIES[key].name,Vector2(325+index*255,496),func():
   difficulty=selected
   if game.campaign_mode: game.profile.select_difficulty(selected)
   show_loadout(),242,46)
  b.tooltip_text={"standard":"Original forgiving economy and pressure.","hard":"32s escalation; charged fourth strikes; repairs weaken to65% during siege. +25% XP.","hell":"EXPERT RISK:25s escalation; charged third strikes; repairs weaken to40%. +50% XP."}[key]
  if key=="hell": b.modulate=Color("F08B88")
 var hint={"standard":"Normal · forgiving pressure and full repair effectiveness.","hard":"Long Night · charged strikes,32s escalation; siege repairs fall to65%.","hell":"HELL · expert risk! Charged strikes,25s escalation; siege repairs fall to40%."}
 ui.label_at(hint[difficulty],Vector2(125,583),15,990)
 var names=PackedStringArray()
 for id in game.profile.equipped: names.append(RankCatalog.perk(id).name)
 ui.label_at("Boost: "+("None" if names.is_empty() else ", ".join(names))+" · "+RankCatalog.DIFFICULTIES[difficulty].name,Vector2(125,554),18,980)
 ui.button("Back",Vector2(125,612),ui.campaign.show_stages if game.campaign_mode else ui.show_menu,180,44)
 ui.button("Ranks & rewards",Vector2(330,612),show_ranks,250,44)
 ui.button("Start Match" if game.campaign_mode else "Start Night",Vector2(860,612),func():
  if game.campaign_mode: game.start_stage(game.profile.selected_stage,difficulty)
  else: game.start_match(difficulty),290,44)

func result_summary():
 var report=game.last_progression
 if report.is_empty(): return
 var b=report.breakdown
 var line="No XP: occupy a bed for 20s and survive 10s after the hunter arrives."
 if b.eligible:
  line="Base %d · Survival %d · Damage %d · Defense %d\nStage +%d · Reaper +%d · Difficulty +%d · Loss %d = +%d XP" % [b.victory,b.survival,b.damage,b.defense,b.get("stage_bonus",0),b.get("reaper_bonus",0),b.difficulty_bonus,b.loss_adjustment,b.total]
 if game.campaign_mode:
  var campaign=report.get("campaign",{})
  line+="\nStage reward: +%d XP%s" % [campaign.get("reward_xp",0)," (already claimed)" if campaign.get("cleared",false) and not campaign.get("first_clear",false) else ""]
 if b.get("ceiling_adjustment",0)<0:
  line+=(" · XP cap %d" if game.campaign_mode else "\nLifetime XP cap adjustment: %d") % b.ceiling_adjustment
 var text=ui.label_at(line,Vector2(366,418),16,548)
 text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 text.size.y=70
 var result_badge=badge(game.profile.rank_index(),Vector2(382,480),42)
 var rankline=ui.label_at("%s → %s · %d → %d XP" % [RankCatalog.NAMES[report.old_rank],game.profile.rank_name(),report.get("old_xp",game.profile.xp),game.profile.xp],Vector2(434,482),15,415)
 if report.promoted:
  rankline.text=("MYTHIC ASCENSION\n" if game.profile.rank_index()==6 else "PROMOTED\n")+rankline.text
  rankline.modulate=Color("FFD27A")
  rankline.scale=Vector2(0.92,0.92)
  var promotion=rankline.create_tween()
  promotion.tween_interval(.95)
  promotion.tween_property(rankline,"scale",Vector2.ONE,0.5).set_trans(Tween.TRANS_BACK)
 if int(b.total)>0:
  var old_points=int(report.get("old_xp",game.profile.xp-int(b.total)))
  var new_points=game.profile.xp
  var names="%s → %s" % [RankCatalog.NAMES[report.old_rank],game.profile.rank_name()]
  var prefix=("MYTHIC ASCENSION\n" if report.new_rank==6 else "PROMOTED\n") if report.promoted else ""
  rankline.text=prefix+"%s · %d → %d XP" % [names,old_points,old_points]
  var counting=rankline.create_tween()
  counting.tween_interval(.95)
  counting.tween_method(func(value):
   rankline.text=prefix+"%s · %d → %d XP" % [names,old_points,roundi(value)],float(old_points),float(new_points),0.65)
 if report.promoted and report.new_rank==6:
  result_badge.pivot_offset=result_badge.size*.5
  result_badge.scale=Vector2(.7,.7)
  var celebration=result_badge.create_tween()
  celebration.tween_interval(.95)
  celebration.tween_property(result_badge,"scale",Vector2(1.25,1.25),.35).set_trans(Tween.TRANS_BACK)
  celebration.parallel().tween_property(result_badge,"modulate",Color(1.5,1.2,.75),.35)
  celebration.tween_property(result_badge,"scale",Vector2.ONE,.4)
  celebration.parallel().tween_property(result_badge,"modulate",Color.WHITE,.4)
 if not game.profile.save_ok:
  ui.button("Save failed — retry",Vector2(390 if game.campaign_mode else 650,580),func():
   game.profile.save_profile()
   if game.profile.save_ok: ui.show_result(),235,32)
