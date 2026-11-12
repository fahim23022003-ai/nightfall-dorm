class_name ProgressionInterface
extends RefCounted

var ui
var game
var difficulty="standard"
var achievement_page=0

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
 ui.label_at("PERMANENT PERKS · 1 slot; Master unlocks 2 · Mythic: Reaper Slayer",Vector2(92,389),18,1060,true)
 for i in range(RankCatalog.PERKS.size()):
  var perk=RankCatalog.PERKS[i]
  var pos=Vector2(92+(i%3)*365,424+int(i/3)*51)
  perk_icon(perk.id,Vector2(92+(i%3)*365,420+int(i/3)*51),28)
  var owned=perk.id in p.unlocked()
  var id=perk.id
  ui.label_at(perk.name+" · "+("Unlocked" if owned else RankCatalog.NAMES[perk.rank]+" required"),pos+Vector2(34,0),13,210)
  var button=ui.button("Equipped" if id in p.equipped else "Equip",pos+Vector2(250,-5),func():
   if p.equip(id): game.audio_event("reward")
   show_ranks(),100,32)
  button.tooltip_text=perk.description
  button.disabled=not owned or p.read_only
 ui.label_at("Wins: 120 base + performance + stage/reaper bonuses, then difficulty. Losses: ≤1 XP/30s, cap30.",Vector2(92,584),14,1060)
 ui.button("Achievements",Vector2(400,622),show_achievements,260,40)
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
 var preparation="Choose at most %d unlocked boost. Selection is saved; bots receive no rank bonuses." % game.profile.perk_slots()
 if not stage.is_empty(): preparation="Defeat the hunter · Prep %ds · Hunter HP ×%.2f / damage ×%.2f / speed ×%.2f" % [stage.preparation,stage.hunter_hp,stage.hunter_damage,stage.hunter_speed]
 ui.label_at(preparation,Vector2(125,117),17,980)
 if not stage.is_empty():
  var boss=BossCatalog.encounter(stage.id,difficulty)
  var encounter=" · Reaper: after %ds at ≤55%% HP, or %ds. No healing." % [boss.opening,boss.deadline] if boss.enabled else " · Introductory encounter: no Reaper transformation."
  ui.label_at(MapCatalog.map(stage.map).get("title","")+encounter,Vector2(125,143),15,980)
 for i in range(RankCatalog.PERKS.size()):
  var item=RankCatalog.PERKS[i]
  var owned=item.id in game.profile.unlocked()
  var at=Vector2(125+(i%2)*520,168+int(i/2)*80)
  var id=item.id
  perk_icon(id,at,40)
  var text=ui.label_at(item.name+"\n"+item.description,at+Vector2(48,0),14,325)
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  text.size=Vector2(325,72)
  var b=ui.button("Equipped ✓" if id in game.profile.equipped else ("Equip" if owned else RankCatalog.NAMES[item.rank]),at+Vector2(378,10),func():
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
 var bonus=RankCatalog.bonuses(game.profile.equipped)
 ui.label_at("Preview: +%.0f Gold · Door +%.0f%% · Income +%.0f%% · Power +%.0f%% · Turrets +%.0f%% · Reaper +%.0f%%" % [bonus.gold,(bonus.door-1)*100,(bonus.income-1)*100,(bonus.power-1)*100,(bonus.damage-1)*100,(bonus.reaper-1)*100],Vector2(125,583),14,990)
 var names=PackedStringArray()
 for id in game.profile.equipped: names.append(RankCatalog.perk(id).name)
 ui.label_at("Perks %d/%d: " % [game.profile.equipped.size(),game.profile.perk_slots()]+("None" if names.is_empty() else ", ".join(names))+" · "+RankCatalog.DIFFICULTIES[difficulty].name,Vector2(125,554),18,980)
 ui.button("Back",Vector2(125,612),ui.campaign.show_stages if game.campaign_mode else ui.show_menu,180,44)
 ui.button("Ranks & rewards",Vector2(330,612),show_ranks,250,44)
 ui.button("Items · %d/2" % game.profile.item_loadout.size(),Vector2(605,612),ui.items_ui.inventory,230,44)
 ui.button("Start Match" if game.campaign_mode else "Start Night",Vector2(860,612),func():
  if game.campaign_mode: game.start_stage(game.profile.selected_stage,difficulty)
  else: game.start_match(difficulty),290,44)

func result_summary():
 var report=game.last_progression
 if report.is_empty():
  if not game.profile.save_ok:ui.button("Retry reward save",Vector2(390,530),game.retry_settlement,495,44)
  return
 var earned=report.get("achievements",[])
 if not earned.is_empty():
  var celebration=ui.box(Rect2(28,212,300,170),"203747","E8BE61")
  ui.label_at("ACHIEVEMENTS EARNED!",Vector2(42,226),19,274,true)
  var titles=[]
  for id in earned:titles.append(RewardCatalog.achievement(id).name)
  var names=ui.label_at(", ".join(titles),Vector2(42,262),16,274)
  names.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.set_deferred("size",Vector2(274,70))
  ui.button("Review earned rewards",Vector2(42,338),show_achievements,274,32)
  flourish(celebration)
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
  game.audio_event("perk_unlocked")
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

func perk_icon(id: String,pos: Vector2,size=40):
 var icon=TextureRect.new()
 icon.texture=load("res://assets/perks/"+id+".svg")
 icon.position=pos;icon.size=Vector2(size,size)
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.panel.add_child(icon)
 return icon
func flourish(node):
 if game.profile.settings.get("reduced_effects",false):return
 node.pivot_offset=node.size*.5
 node.scale=Vector2(.9,.9)
 node.create_tween().tween_property(node,"scale",Vector2.ONE,.3).set_trans(Tween.TRANS_BACK)
func show_achievements():
 ui.clear();ui.current_screen="achievements"
 ui.box(Rect2(60,35,1160,650))
 ui.label_at("ACHIEVEMENTS · EARNED REWARDS",Vector2(90,55),28,1080,true)
 ui.label_at("%d / 12 earned · %d XP · Rewards save once; stock-full claims wait safely." % [game.profile.achievements.size(),game.profile.xp],Vector2(92,100),17,1060)
 for i in range(6):
  var data=RewardCatalog.ACHIEVEMENTS[i+achievement_page*6]
  var pos=Vector2(92+(i%2)*550,145+int(i/2)*142)
  var earned=game.profile.achievements.has(data.id)
  var claimed=earned and game.profile.achievements[data.id].claimed
  var card=ui.box(Rect2(pos,Vector2(530,130)),"203747","FFD780" if earned else "607D8B")
  var icon=TextureRect.new();icon.texture=load("res://assets/achievements/"+data.id+".svg");icon.position=pos+Vector2(8,14);icon.size=Vector2(52,52);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ui.panel.add_child(icon)
  ui.label_at(data.name+(" · CLAIMED" if claimed else " · EARNED" if earned else " · LOCKED"),pos+Vector2(70,8),18,450,true)
  var desc=ui.label_at(data.description,pos+Vector2(70,35),14,440);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(440,38))
  ui.label_at("Reward: up to +%d XP · 1 × %s" % [data.xp,ItemCatalog.ITEMS[data.item].name],pos+Vector2(70,77),13,440)
  ui.label_at(game.profile.achievement_progress(data.id),pos+Vector2(280,104),14,225)
  var id=data.id
  var b=ui.button("Claim reward" if not claimed else "Claimed",pos+Vector2(70,98),func():
   var old_rank=game.profile.rank_index()
   var old_xp=game.profile.xp
   if game.profile.claim_achievement(id):
    game.audio_event("achievement_claim")
    if game.profile.rank_index()>old_rank:game.audio_event("mythic_perk" if game.profile.rank_index()==6 else "perk_unlocked")
    game.profile.warning="Claimed: +%d XP · 1 × %s" % [game.profile.xp-old_xp,ItemCatalog.ITEMS[RewardCatalog.achievement(id).item].name]
   else:game.audio_event("failure")
   show_achievements(),180,28)
  b.disabled=not earned or claimed or game.profile.read_only
  if earned and not claimed:flourish(icon)
 ui.button("Next achievements" if achievement_page==0 else "First achievements",Vector2(870,58),func():achievement_page=1-achievement_page;show_achievements(),290,36)
 ui.label_at(game.profile.warning,Vector2(92,578),14,1060)
 ui.button("Back to ranks",Vector2(92,620),show_ranks,240,42)
 ui.button("Stage rewards",Vector2(365,620),show_stage_bonus,240,42).disabled=game.profile.pending_stage_bonus.is_empty()
func show_stage_bonus():
 var offer=game.profile.pending_stage_bonus
 if offer.is_empty():ui.campaign.show_stages();return
 ui.clear();ui.current_screen="stage_bonus"
 ui.box(Rect2(80,90,1120,540))
 ui.label_at("CHOOSE ONE · NEXT STAGE PREPARATION",Vector2(115,115),28,1050,true)
 ui.label_at("Earned by clearing %s · Applies only to %s · Saved, finite and separate from perks/items." % [offer.source,offer.target],Vector2(115,166),16,1040)
 var index=0
 for id in RewardCatalog.STAGE_BONUSES:
  var data=RewardCatalog.STAGE_BONUSES[id]
  var pos=Vector2(115+index*355,230)
  var card=ui.box(Rect2(pos,Vector2(335,230)),"203747","E8BE61")
  ui.label_at(data.name,pos+Vector2(15,18),21,305,true)
  var desc=ui.label_at(data.description,pos+Vector2(15,70),18,305);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(305,90))
  var selected=id
  var b=ui.button("Select" if offer.choice=="" else "Selected" if offer.choice==id else "Unavailable",pos+Vector2(15,172),func():
   if game.profile.choose_stage_bonus(selected):game.audio_event("stage_bonus_selected")
   else:game.audio_event("failure")
   show_stage_bonus(),305,42)
  b.disabled=offer.choice!="" or game.profile.read_only
  flourish(card);index+=1
 ui.button("Continue to loadout",Vector2(715,535),func():ui.campaign.prepare(offer.target),420,48).disabled=offer.choice==""
 ui.button("Save & return to stages",Vector2(115,535),ui.campaign.show_stages,420,48)
