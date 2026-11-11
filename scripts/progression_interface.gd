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
 var next="MASTER RANK" if p.rank_index()==5 else "%d XP to %s" % [RankCatalog.THRESHOLDS[p.rank_index()+1]-p.xp,RankCatalog.NAMES[p.rank_index()+1]]
 ui.label_at("%s · %d XP\n%s" % [p.rank_name(),p.xp,next],Vector2(430,488),16,240)
 ui.button("Ranks & rewards",Vector2(72,596),show_ranks,330,44)
 if p.warning!="":
  var notice=ui.label_at(p.warning,Vector2(430,560),16,224)
  notice.clip_text=true
  notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  notice.size=Vector2(224,95)
  notice.modulate=Color("FFD27A")

func show_ranks():
 if game.mode=="result": game.return_menu()
 ui.clear()
 game.audio_event("menu")
 ui.box(Rect2(60,40,1160,638))
 var p=game.profile
 badge(p.rank_index(),Vector2(86,62),90)
 ui.label_at("%s  ·  %d lifetime XP" % [p.rank_name().to_upper(),p.xp],Vector2(190,70),28,940,true)
 var rank=p.rank_index()
 var target=RankCatalog.THRESHOLDS[mini(5,rank+1)]
 var base=RankCatalog.THRESHOLDS[rank]
 ui.label_at("Master attained — all rewards unlocked." if rank==5 else "%d / %d rank XP · %d more XP for %s" % [p.xp-base,target-base,target-p.xp,RankCatalog.NAMES[rank+1]],Vector2(190,114),19,930)
 var bar=ProgressBar.new()
 bar.position=Vector2(190,150)
 bar.size=Vector2(960,20)
 bar.max_value=1 if rank==5 else target-base
 bar.value=1 if rank==5 else p.xp-base
 ui.panel.add_child(bar)
 for i in range(6):
  badge(i,Vector2(90+i*182,190),54)
  ui.label_at("%s\n%d XP" % [RankCatalog.NAMES[i],RankCatalog.THRESHOLDS[i]],Vector2(148+i*182,193),16,122)
 ui.label_at("REWARDS · "+("All unlocked" if rank==5 else "Next: "+RankCatalog.PERKS[rank+1].name)+" · slots: %d" % RankCatalog.MAX_EQUIPPED,Vector2(92,268),22,1040,true)
 for i in range(6):
  var perk=RankCatalog.PERKS[i]
  var pos=Vector2(92+(i%2)*544,312+int(i/2)*88)
  var owned=perk.id in p.unlocked()
  var text=ui.label_at(perk.name+"  ·  "+("Unlocked" if owned else RankCatalog.NAMES[i]+" required")+"\n"+perk.description,pos,16,412)
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  text.size=Vector2(412,76)
  var id=perk.id
  var b=ui.button("Equipped" if id in p.equipped else "Equip",pos+Vector2(416,10),func():
   if p.equip(id): game.audio_event("reward")
   show_ranks(),106,40)
  b.disabled=not owned or p.read_only
 ui.label_at("Wins: 120 base XP + capped performance. Losses: 35% performance, at most 80 XP.",Vector2(92,580),16,1050)
 ui.button("Back",Vector2(92,622),ui.show_menu,180,40)
 ui.button("Choose loadout",Vector2(900,622),show_loadout,270,40)

func show_loadout():
 if game.mode=="result": game.return_menu()
 ui.clear()
 game.audio_event("menu")
 ui.box(Rect2(90,40,1100,640))
 ui.label_at("PREPARE FOR THE NIGHT",Vector2(125,68),30,980,true)
 badge(game.profile.rank_index(),Vector2(1090,58),64)
 ui.label_at("Choose at most %d unlocked boost. Your selection is saved; bots receive no rank bonuses." % RankCatalog.MAX_EQUIPPED,Vector2(125,117),18,980)
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
 for index in range(2):
  var key=["standard","hard"][index]
  var selected=key
  var b=ui.button(("✓ " if difficulty==key else "")+RankCatalog.DIFFICULTIES[key].name,Vector2(340+index*260,496),func():
   difficulty=selected
   show_loadout(),242,46)
  b.tooltip_text="Baseline early game, gradual later escalation" if key=="standard" else "+15% hunter HP/damage, +5% speed; +25% XP before defeat adjustment"
 var names=PackedStringArray()
 for id in game.profile.equipped: names.append(RankCatalog.perk(id).name)
 ui.label_at("Boost: "+("None" if names.is_empty() else ", ".join(names))+" · "+RankCatalog.DIFFICULTIES[difficulty].name,Vector2(125,554),18,980)
 ui.button("Back",Vector2(125,612),ui.show_menu,180,44)
 ui.button("Ranks & rewards",Vector2(330,612),show_ranks,250,44)
 ui.button("Start Night",Vector2(860,612),func(): game.start_match(difficulty),290,44)

func result_summary():
 var report=game.last_progression
 if report.is_empty(): return
 var b=report.breakdown
 var line="No XP: occupy a bed for 20s and survive 10s after the hunter arrives."
 if b.eligible:
  line="Victory %d + Survival %d + Damage %d + Defense %d\nDifficulty +%d · Loss adjustment %d  =  +%d XP" % [b.victory,b.survival,b.damage,b.defense,b.difficulty_bonus,b.loss_adjustment,b.total]
 if b.get("ceiling_adjustment",0)<0: line+="\nLifetime XP cap adjustment: %d" % b.ceiling_adjustment
 var text=ui.label_at(line,Vector2(366,418),16,548)
 text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 text.size.y=70
 badge(game.profile.rank_index(),Vector2(382,480),42)
 var rankline=ui.label_at("%s · %d XP" % [game.profile.rank_name(),game.profile.xp],Vector2(434,486),18,415)
 if report.promoted:
  rankline.text="PROMOTED: "+rankline.text
  rankline.modulate=Color("FFD27A")
  rankline.scale=Vector2(0.92,0.92)
  rankline.create_tween().tween_property(rankline,"scale",Vector2.ONE,0.5).set_trans(Tween.TRANS_BACK)
 if not game.profile.save_ok:
  ui.button("Save failed — retry",Vector2(650,580),func():
   game.profile.save_profile()
   if game.profile.save_ok: ui.show_result(),235,32)
