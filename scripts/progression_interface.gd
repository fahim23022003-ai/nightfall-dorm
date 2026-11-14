class_name ProgressionInterface
extends RefCounted

var ui
var game
var difficulty="standard"
var achievement_page=0
var last_claimed=""

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
 ui.label_at("Highest: %s · %s" % [RankCatalog.NAMES[p.highest_rank],p.promotion_requirement()]+(" · Title: Hell Survivor" if p.achievements.get("hell_survivor",{}).get("claimed",false) else ""),Vector2(205,108),15,940)
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
 ui.label_at("PERMANENT PERKS · %d slot%s · Second at Master · Mythic: Reaper Slayer" % [p.perk_slots(),"s" if p.perk_slots()>1 else ""],Vector2(92,389),18,1060,true)
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
 if game.mode=="result":game.return_menu()
 if game.mobile_mode:game.mobile_ui.show_rewards(ui,true);return
 ui.clear();ui.current_screen="loadout";game.audio_event("menu")
 ui.box(Rect2(90,35,1100,650))
 var stage=StageCatalog.stage(game.profile.selected_stage) if game.campaign_mode else {}
 ui.label_at("STAGE %d · %s" % [stage.number,stage.title] if not stage.is_empty() else "PREPARE FOR THE NIGHT",Vector2(125,55),31,950,true)
 badge(game.profile.rank_index(),Vector2(1090,48),64)
 var boosts=RankCatalog.bonuses(game.profile.equipped)
 ui.label_at("Perks %d/%d · Gold +%.0f · Door +%.0f%% · Income +%.0f%% · Turrets +%.0f%% · Items %d/2" % [game.profile.equipped.size(),game.profile.perk_slots(),boosts.gold,(boosts.door-1)*100,(boosts.income-1)*100,(boosts.damage-1)*100,game.profile.item_loadout.size()],Vector2(125,107),16,1000)
 var archetype=game.profile.next_archetype(game.profile.selected_stage if game.campaign_mode else "",difficulty)
 ui.premium_icon(archetype,Vector2(125,143),Vector2(54,54))
 ui.label_at("TONIGHT · "+StrategyCatalog.ARCHETYPES[archetype].name,Vector2(191,140),24,930,true)
 var hint=ui.label_at(StrategyCatalog.ARCHETYPES[archetype].hint,Vector2(191,171),15,930)
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.set_deferred("size",Vector2(930,40))
 var eligible=BossCatalog.encounter(game.profile.selected_stage if game.campaign_mode else "",difficulty).enabled
 ui.label_at("REAPER ELIGIBLE · after8s +55% HP; PhaseII35%, final10%" if eligible else "REAPER: Normal Stage3+; Long Night / Hell Stage2+",Vector2(125,207),13,1020)
 var descriptions={"standard":"Full repairs · forgiving pressure","hard":"Charged strikes · siege repairs 65%","hell":"Expert risk · base siege repairs 65%; curses can reduce" if game.new_balance_version==2 else "Expert risk · siege repairs 40%"}
 for i in range(3):
  var key=["standard","hard","hell"][i];var chosen=key;var at=Vector2(125+i*345,225)
  var card=ui.button("",at,func():
   difficulty=chosen
   if game.campaign_mode:game.profile.select_difficulty(chosen)
   show_loadout(),330,145)
  card.name="mode_"+key;card.set_meta("mode",key)
  for state in ["normal","hover","pressed","disabled","focus"]:
   card.add_theme_stylebox_override(state,GothicTheme.surface("3A2228" if key=="hell" else "292538","CA916F" if key=="hell" else "A89BC5" if key=="hard" else "96B49A","mode_"+key+"_"+("selected" if state=="normal" and difficulty==key else state)))
  card.tooltip_text=descriptions[key]
  ui.premium_icon(key,at+Vector2(14,15),Vector2(65,65))
  ui.label_at(RankCatalog.DIFFICULTIES[key].name.to_upper(),at+Vector2(91,19),26,225,true)
  ui.label_at("SELECTED ✓" if difficulty==key else "Choose this night",at+Vector2(92,58),14,220).modulate=Color("E0C992") if difficulty==key else Color("9DAAA4")
  var description=ui.label_at(descriptions[key],at+Vector2(16,100),15,300)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.set_deferred("size",Vector2(300,36))
 var selected=game.profile.selected_contract
 ui.premium_icon("contract",Vector2(125,395),Vector2(42,42))
 ui.label_at("OPTIONAL CONTRACT · "+(StrategyCatalog.CONTRACTS[selected].name if selected!="" else "None"),Vector2(180,397),23,940,true)
 var description=StrategyCatalog.CONTRACTS[selected].objective+" First qualifying stage/mode clear: +%d RM Cash." % StrategyCatalog.CONTRACTS[selected].cash if selected!="" else "Add a voluntary restriction for a one-time stage/difficulty RM Cash bonus. Standard rewards are unchanged."
 var contract_text=ui.label_at(description,Vector2(125,444),17,1000);contract_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;contract_text.set_deferred("size",Vector2(1000,44))
 ui.button("Optional contracts",Vector2(125,505),show_contracts,305,46)
 ui.button("Permanent perk loadout",Vector2(455,505),show_perk_loadout,335,46)
 ui.button("Consumable inventory",Vector2(815,505),ui.items_ui.inventory,335,46)
 var reserved=game.profile.pending_stage_bonus
 var bonus="Stage bonus: "+RewardCatalog.STAGE_BONUSES[reserved.choice].name if not reserved.is_empty() and reserved.target==game.profile.selected_stage and reserved.choice!="" else "One Hunter · room traits trade durability, income and power · specialization opens at turret level 4"
 ui.label_at(bonus,Vector2(125,568),15,1010)
 ui.button("Back",Vector2(125,618),ui.campaign.show_stages if game.campaign_mode else ui.show_menu,180,44)
 ui.button("Ranks & rewards",Vector2(330,618),show_ranks,250,44)
 ui.button("Items · %d/2" % game.profile.item_loadout.size(),Vector2(605,618),ui.items_ui.inventory,230,44)
 ui.button("Start Match" if game.campaign_mode else "Start Night",Vector2(860,618),func():
  if game.campaign_mode:game.start_stage(game.profile.selected_stage,difficulty)
  else:game.start_match(difficulty),290,44)

func show_perk_loadout():
 ui.clear();ui.current_screen="perk_loadout"
 ui.box(Rect2(90,40,1100,640))
 ui.label_at("PERMANENT PERK LOADOUT",Vector2(125,68),32,1000,true)
 ui.label_at("Choose %d permanent perks. Consumables use their own two slots; selections save immediately." % game.profile.perk_slots(),Vector2(125,118),17,1000)
 for i in range(RankCatalog.PERKS.size()):
  var item=RankCatalog.PERKS[i];var id=item.id;var owned=id in game.profile.unlocked()
  var at=Vector2(125+(i%2)*520,174+int(i/2)*96)
  ui.box(Rect2(at,Vector2(500,86)),"203747","A4AE93" if id in game.profile.equipped else "607D8B")
  perk_icon(id,at+Vector2(10,15),48)
  var text=ui.label_at(item.name+"\n"+item.description,at+Vector2(68,8),15,282)
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.set_deferred("size",Vector2(282,70))
  var button=ui.button("Equipped ✓" if id in game.profile.equipped else "Equip" if owned else RankCatalog.NAMES[item.rank],at+Vector2(362,20),func():
   if game.profile.equip(id):game.audio_event("reward")
   show_perk_loadout(),126,44)
  button.disabled=not owned or game.profile.read_only
 ui.button("Back to preparation",Vector2(125,612),show_loadout,330,44)
 ui.button("Ranks & rewards",Vector2(825,612),show_ranks,330,44)

func show_contracts():
 ui.clear();ui.current_screen="contracts"
 ui.box(Rect2(90,45,1100,630))
 ui.label_at("OPTIONAL CHALLENGE CONTRACTS",Vector2(125,70),32,1020,true)
 ui.label_at("Win a genuine match to qualify. Each stage + difficulty + contract pays once. Aborts and defeats pay no contract bonus.",Vector2(125,121),16,1010)
 var index=0
 for id in StrategyCatalog.CONTRACTS:
  var data=StrategyCatalog.CONTRACTS[id];var chosen=id;var at=Vector2(125+index*345,188)
  ui.box(Rect2(at,Vector2(330,332)),"203747","C4B27D" if game.profile.selected_contract==id else "7C8988")
  ui.premium_icon("contract",at+Vector2(132,16),Vector2(64,64))
  ui.label_at(data.name,at+Vector2(15,91),25,300,true)
  var objective=ui.label_at(data.objective,at+Vector2(15,136),18,300)
  objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;objective.set_deferred("size",Vector2(300,94))
  var key=StrategyCatalog.claim_key(game.profile.selected_stage,difficulty,id)
  ui.premium_icon("cash",at+Vector2(15,239),Vector2(30,30))
  ui.label_at("+%d RM Cash · %s" % [data.cash,"CLAIMED" if game.profile.contract_claims.has(key) else "first completion"],at+Vector2(54,242),15,260)
  var button=ui.button("Selected ✓" if game.profile.selected_contract==id else "Choose contract",at+Vector2(15,283),func():
   if game.profile.select_contract(chosen):game.audio_event("button")
   show_contracts(),300,36)
  button.disabled=game.profile.read_only
  index+=1
 ui.button("No contract · standard match",Vector2(125,565),func():
  game.profile.select_contract("");show_contracts(),470,44)
 ui.button("Confirm & return",Vector2(655,565),show_loadout,495,44)

func result_summary():
 var report=game.last_progression
 if report.is_empty():
  if not game.profile.save_ok:ui.button("Retry reward save",Vector2(390,530),game.retry_settlement,495,44)
  return
 if report.has("contract"):
  var contract=report.contract
  ui.box(Rect2(945,224,300,180),"203747","C4B27D")
  ui.premium_icon("contract",Vector2(960,238),Vector2(40,40))
  ui.label_at("CONTRACT RESULT",Vector2(1009,244),22,221,true)
  ui.label_at(StrategyCatalog.CONTRACTS[contract.id].name,Vector2(960,291),21,270,true)
  var detail="Qualified · +%d RM Cash" % contract.cash if contract.cash>0 else "Qualified · already claimed" if contract.qualified and contract.claimed else "Qualified · wallet full; retry on another win" if contract.qualified else "Not completed · no bonus"
  var text=ui.label_at(detail+("\n"+contract.reason if contract.reason!="" else ""),Vector2(960,332),15,270)
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.set_deferred("size",Vector2(270,66))
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
 if report.promoted:
  var unlocks=RankCatalog.PERKS.filter(func(perk):return perk.rank>report.old_rank and perk.rank<=report.new_rank)
  var card=ui.box(Rect2(28,400,300,160),"203747","E8BE61")
  ui.label_at("PERK UNLOCKED",Vector2(42,413),20,274,true)
  var names=[]
  for perk in unlocks:names.append(perk.name)
  var label=ui.label_at(", ".join(names)+( " · Second slot unlocked" if report.old_rank<5 and report.new_rank>=5 else ""),Vector2(42,450),17,274)
  label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.set_deferred("size",Vector2(274,70))
  if not unlocks.is_empty():flourish(perk_icon(unlocks[-1].id,Vector2(260,505),44))
  flourish(card)
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
 ui.label_at("RM Cash +%d · Balance %d" % [report.get("rm_cash",0),game.profile.rm_cash],Vector2(390,510),15,495,true)
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
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.position=pos;icon.size=Vector2(size,size)
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
  var icon=TextureRect.new();icon.texture=load("res://assets/achievements/"+data.id+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.position=pos+Vector2(8,14);icon.size=Vector2(52,52);ui.panel.add_child(icon)
  ui.label_at(data.name+(" · CLAIMED" if claimed else " · EARNED" if earned else " · LOCKED"),pos+Vector2(70,8),18,450,true)
  var desc=ui.label_at(data.description,pos+Vector2(70,35),14,440);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(440,38))
  ui.label_at("Reward: up to +%d XP · 1 × %s" % [data.xp,ItemCatalog.ITEMS[data.item].name],pos+Vector2(70,77),13,440)
  ui.label_at(game.profile.achievement_progress(data.id),pos+Vector2(280,104),14,225)
  var id=data.id
  var b=ui.button("Claim reward" if not claimed else "Claimed",pos+Vector2(70,98),func():
   var old_rank=game.profile.rank_index()
   var old_xp=game.profile.xp
   if game.profile.claim_achievement(id):
    last_claimed=id
    game.audio_event("achievement_claim")
    if game.profile.rank_index()>old_rank:game.audio_event("mythic_perk" if game.profile.rank_index()==6 else "perk_unlocked")
    game.profile.warning="Claimed: +%d XP · 1 × %s" % [game.profile.xp-old_xp,ItemCatalog.ITEMS[RewardCatalog.achievement(id).item].name]
   else:game.audio_event("failure")
   show_achievements(),180,28)
  b.disabled=not earned or claimed or game.profile.read_only
  if (earned and not claimed) or last_claimed==id:flourish(icon)
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
 var source=StageCatalog.stage(offer.source)
 var target=StageCatalog.stage(offer.target)
 ui.label_at("Earned: Stage %d · %s → Next: Stage %d · %s" % [source.number,source.title,target.number,target.title],Vector2(115,166),16,1040)
 ui.label_at("Choose one. Saved for this stage only; separate from permanent perks and consumables.",Vector2(115,194),15,1040)
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
