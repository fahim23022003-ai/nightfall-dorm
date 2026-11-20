extends SceneTree
## Deterministic identities and live production ticks at three Story encounters.

const SEED_BASE := 32157
const MODELS_TO_COMPARE := [1, 4, 14, 17, 21, 29, 36, 44, 50]
var checks := 0
var failures := 0


func _initialize() -> void:
 call_deferred("run")


func check(condition: bool, detail: String) -> void:
 checks+=1
 if condition:
  return
 failures+=1
 push_error(detail)


func model_at(level: int, mode: String = "standard") -> MatchModel:
 var mission := StoryCatalog.mission(level)
 var seed := StoryProgress.seed_for(StoryProgress.fresh(SEED_BASE),level)
 var model := MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(seed)
 if not model.configure_match(mode) or not model.configure_stage(mission.stage_id) or not model.configure_balance():
  return null
 model.story_level=level
 model.preparation=maxf(model.preparation,mission.preparation)
 if not model.configure_strategy(seed,mission.archetype):
  return null
 StoryCatalog.apply_encounter(model)
 return model


func identity_and_balance() -> void:
 OS.set_environment("NIGHTFALL_PHASE16","0")
 var story := StoryProgress.fresh(SEED_BASE)
 var vanilla_seeds: Array[int]=[]
 for level: int in range(1,StoryCatalog.FINAL_LEVEL+1):
  vanilla_seeds.append(StoryProgress.seed_for(story,level))
 OS.set_environment("NIGHTFALL_PHASE16","1")
 var combinations: Dictionary={}
 for level: int in range(1,StoryCatalog.FINAL_LEVEL+1):
  var mission := StoryCatalog.mission(level)
  check(StoryProgress.seed_for(story,level)==vanilla_seeds[level-1],"Level %d keeps the saved mission seed" % level)
  check(mission.discovery!=mission.briefing and not mission.discovery.is_empty(),"Level %d has a distinct discovery" % level)
  combinations[str(mission.theme)+"/"+str(mission.topology)+"/"+str(mission.archetype)+"/"+str(mission.encounter.name)]=true
 check(combinations.size()==50,"All 50 missions have distinct map/profile/enemy combinations")
 for level: int in MODELS_TO_COMPARE:
  for difficulty: String in StoryProgress.DIFFICULTIES:
   OS.set_environment("NIGHTFALL_PHASE16","0")
   var old := model_at(level,difficulty)
   OS.set_environment("NIGHTFALL_PHASE16","1")
   var updated := model_at(level,difficulty)
   check(old!=null and updated!=null,"Both setup paths accept level %d %s" % [level,difficulty])
   if old==null or updated==null:
    continue
   check(updated.map_data==old.map_data and updated.stage_id==old.stage_id and updated.hunter.archetype==old.hunter.archetype,"Identical geometry, stage and Hunter at level %d %s" % [level,difficulty])
   check(updated.hunter.hp==old.hunter.hp and updated.hunter.damage==old.hunter.damage and updated.hunter.speed==old.hunter.speed,"Base stats intact at level %d %s" % [level,difficulty])
   check(updated.preparation>=old.preparation and updated.hunter.boss_policy.hp_fraction==old.hunter.boss_policy.hp_fraction,"No preparation squeeze or changed transformation HP threshold")
 var original_story := story.duplicate(true)
 var plain := MatchModel.new()
 plain.configure_stage("stage_5")
 var prep: float=plain.preparation
 var boss := plain.hunter.boss_policy.duplicate()
 StoryCatalog.apply_encounter(plain)
 check(prep==plain.preparation and boss==plain.hunter.boss_policy,"Classic Campaign ignores the Story profiles")
 check(StoryProgress.valid(story) and story==original_story,"Catalog evaluation leaves stored progress untouched")


func occupy(model: MatchModel) -> RoomState:
 if not model.claim_room(0):
  return null
 var room: RoomState=model.player()
 model.player_position=room.bed_position()
 if not model.sleep_player():
  return null
 # Model encounters below isolate one resident. The production Hunter
 # room, warning, defense, navigation and damage checks still run.
 model.bot_claimed=5
 return room


func find_event(model: MatchModel, kind: String) -> Dictionary:
 for event: Dictionary in model.presentation_events:
  if event.type==kind:
   return event
 return {}


func electric_contact() -> void:
 var model := model_at(4)
 var room := occupy(model)
 check(room!=null and not model.hunter.boss_policy.enabled,"Blackout Protocol opens as a first-form-only encounter")
 if room==null:
  return
 var hunter := model.hunter
 hunter.target=room.index
 hunter.position=room.door_approach()
 hunter.state=HunterState.State.ATTACK
 hunter.cooldown=60.0
 model.time=model.preparation
 var before: float=room.door_hp
 for step: int in range(560):
  model.tick(0.05)
  if not find_event(model,"arcane_impact").is_empty():
   break
 var warning := find_event(model,"hunter_ability_warning")
 var hit := find_event(model,"arcane_impact")
 check(warning.get("ability")=="interference" and float(warning.get("time",0))>=model.preparation+11.95,"Electric Ghost emits the existing interference warning after its chapter grace")
 check(hit.get("ability")=="interference" and room.door_hp<before and room.magic_state.disrupt>0,"The live cast impacts the door and briefly locks ordinary weapons")
 print("STORY_ENCOUNTER 04 ",{"prep":model.preparation,"warning":warning.get("time"),"impact":hit.get("time"),"door_loss":before-room.door_hp})


func hall_recovery_window() -> void:
 var model := model_at(29)
 var room := occupy(model)
 check(room!=null and model.map_data.get("halls",{}).size()==4,"Echoes of the Lost loads four real Haunted Halls")
 if room==null:
  return
 var hunter := model.hunter
 var hall: Dictionary=model.map_data.halls.west
 hunter.target=room.index
 hunter.position=hall.entrance
 hunter.state=HunterState.State.MOVE
 hunter.hp=hunter.max_hp*0.40
 model.time=model.preparation+29.89
 model.tick(0.05)
 check(find_event(model,"hunter_retreat").is_empty(),"Hall recovery cannot start before chapter eligibility")
 for step: int in range(380):
  model.tick(0.05)
  if model.haunt_recovery.visits>0:
   break
 var retreat := find_event(model,"hunter_retreat")
 var channel := find_event(model,"hunter_recovering")
 check(not retreat.is_empty() and float(retreat.get("time",0))>=model.preparation+30.0,"Existing Hunter physically enters a reachable Hall after its window opens")
 var completed := find_event(model,"hunter_recovery_ended")
 var healed: float=completed.get("healed",0.0)
 check(not channel.is_empty() and model.haunt_recovery.visits==1 and completed.get("reason")=="completed" and healed>0.0,"Real channel completes and heals the wounded Hunter")
 print("STORY_ENCOUNTER 29 ",{"prep":model.preparation,"retreat":retreat.get("time"),"channel":channel.get("time"),"healed":healed})


func reaper_opener() -> void:
 var model := model_at(36)
 var room := occupy(model)
 check(room!=null and model.hunter.boss_policy.enabled,"The Funeral Bell enables the Reaper on Standard")
 if room==null:
  return
 model.hunter.target=room.index
 model.hunter.state=HunterState.State.SEEK
 model.hunter.position=room.door_approach()
 var deadline: float=model.hunter.boss_policy.deadline
 model.time=model.preparation+deadline-0.075
 model.tick(0.05)
 check(find_event(model,"boss_transform").is_empty(),"Reaper deadline does not fire early")
 for step: int in range(110):
  model.tick(0.05)
  if not find_event(model,"boss_awakened").is_empty():
   break
 var transform := find_event(model,"boss_transform")
 var awakened := find_event(model,"boss_awakened")
 check(model.hunter.transformed and not transform.is_empty() and not awakened.is_empty(),"Production Hunter finishes its existing transformation")
 print("STORY_ENCOUNTER 36 ",{"prep":model.preparation,"deadline":deadline,"transform":transform.get("time"),"awakened":awakened.get("time")})


func run() -> void:
 identity_and_balance()
 electric_contact()
 hall_recovery_window()
 reaper_opener()
 print("PHASE16_STORY_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
