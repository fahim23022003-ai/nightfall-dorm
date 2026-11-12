extends RefCounted
## Campaign navigation reuses the existing ranked loadout and profile.
var ui
var game
func _init(owner_ui):
 ui=owner_ui
 game=ui.game

func show_stages():
 if game.mode=="result": game.return_menu()
 game.campaign_mode=true
 ui.clear()
 ui.current_screen="stages"
 game.audio_event("menu")
 ui.box(Rect2(70,35,1140,650))
 ui.label_at("THE NIGHTFALL CAMPAIGN",Vector2(104,55),30,1060,true)
 var completed=0
 for definition in StageCatalog.STAGES:
  if int(game.profile.stage_record(definition.id).get("clears",0))>0: completed+=1
 ui.label_at("Campaign: %d / %d cleared · Rank: %s · %d XP" % [completed,StageCatalog.STAGES.size(),game.profile.rank_name(),game.profile.xp],Vector2(106,99),18,1050)
 ui.label_at("Stages unlock through victory. Replays retain your best record; first-clear rewards are earned once.",Vector2(106,132),16,1060)
 for i in range(StageCatalog.STAGES.size()):
  var definition=StageCatalog.STAGES[i]
  var id=definition.id
  var record=game.profile.stage_record(id)
  var unlocked=game.profile.stage_unlocked(id)
  var y=170+i*80
  ui.box(Rect2(104,y,1072,72),"263E50","7BE3A1" if int(record.get("clears",0))>0 else "607D8B")
  ui.label_at("%d · %s" % [definition.number,definition.title],Vector2(120,y+9),20,600,true)
  var status="CLEARED" if int(record.get("clears",0))>0 else "UNLOCKED" if unlocked else "LOCKED · clear Stage %d" % i
  var best=" · "+str(MapCatalog.map(definition.map).get("title",""))
  if int(record.get("clears",0))>0: best+=" · Best %.1fs" % float(record.get("best_time",0))
  ui.label_at(status+best+" · First clear +%d XP" % definition.first_clear_xp,Vector2(120,y+39),16,820)
  var button=ui.button("Replay" if int(record.get("clears",0))>0 else "Prepare" if unlocked else "Locked",Vector2(988,y+13),func(): prepare(id),170,46)
  button.disabled=not unlocked or game.profile.read_only
 var difficulty=game.profile.selected_difficulty
 ui.label_at("Selected difficulty: "+RankCatalog.DIFFICULTIES[difficulty].name+" · set independently in preparation",Vector2(106,585),17,1030)
 ui.button("Main menu",Vector2(106,628),game.return_menu,220,42)
 ui.button("Ranks & rewards",Vector2(360,628),ui.progression.show_ranks,260,42)

func prepare(id: String):
 if not game.profile.pending_stage_bonus.is_empty() and game.profile.pending_stage_bonus.target==id and game.profile.pending_stage_bonus.choice=="":
  ui.progression.show_stage_bonus();return false
 if not game.profile.stage_unlocked(id): return false
 if game.mode=="result": game.return_menu()
 if not game.profile.select_stage(id): return false
 game.campaign_mode=true
 ui.progression.difficulty=game.profile.selected_difficulty
 ui.progression.show_loadout()
 return true

func result_actions():
 var id=game.model.stage_id
 var report=game.last_progression.get("campaign",{})
 if game.model.result=="victory":
  var next_id=str(report.get("next_stage",StageCatalog.next_stage(id)))
  if next_id!="" and game.profile.stage_unlocked(next_id):
   ui.button("Next Stage",Vector2(390,530),func(): prepare(next_id),235,44)
  else:
   ui.label_at("Campaign complete" if next_id=="" else "Stage clear not recorded",Vector2(390,538),18,235,true)
  ui.button("Stage Select",Vector2(650,530),show_stages,235,44)
  ui.button("Main menu",Vector2(650,580),game.return_menu,235,32)
 else:
  ui.button("Retry Stage",Vector2(390,530),func(): game.start_stage(id,game.selected_difficulty),235,44)
  ui.button("Change Loadout",Vector2(650,530),func(): prepare(id),235,44)
  ui.button("Main menu",Vector2(650,580),game.return_menu,235,32)
