extends "res://tools/nightmare_tactics/check_phase16_story_matrix.gd"
## Record path selections, defenders and the actual paid history without changing the match.

var opening_roster: Array = []
var approach_details: Array = []
var encounter_details: Array = []
var losses: Array = []
var built: Array = []
var last_observed_event := 0
var travel_per_target := [0.0,0.0,0.0,0.0,0.0,0.0]
var pre_contact_distances := [0.0,0.0,0.0,0.0,0.0,0.0]
var room_footprints := {}
var first_strike := [-1.0,-1.0,-1.0,-1.0,-1.0,-1.0]

func room_details(model: MatchModel) -> Array:
 var rows := []
 for r: RoomState in model.rooms:
  rows.append({
   "room":r.index+1, "owner":r.owner, "profile":r.profile, "trait":r.trait_id,
   "door_hp":r.door_hp, "max_hp":r.max_hp(), "gold":r.gold,"power":r.electricity,
   "bed_level":r.bed_level+1,"door_level":r.door_level+1,
   "sleeping":r.sleeping, "buildings":r.buildings.values().map(func(b):return [b.kind,b.level]),
   "alive":r.alive, "hunter_open_score":model.hunter.target_score(r),
  })
 return rows

func play_story(fixture: Dictionary, stock: String) -> Dictionary:
 opening_roster=[]
 approach_details=[]
 encounter_details=[]
 losses=[]
 built=[]
 last_observed_event=0
 room_footprints={}
 travel_per_target=[0.0,0.0,0.0,0.0,0.0,0.0]
 pre_contact_distances=travel_per_target.duplicate()
 first_strike=[-1.0,-1.0,-1.0,-1.0,-1.0,-1.0]
 var row := super(fixture, stock)
 row.directional_observations={
  "opening_roster":opening_roster,"approaches":approach_details,"contacts":encounter_details,"breaches_or_eliminations":losses,
  "paid_player_actions":built,"travel_per_target":travel_per_target,"pre_contact_distances":pre_contact_distances,
  "first_strike_by_room":first_strike,"room_footprints":room_footprints,
 }
 return row

func use_plan(model: MatchModel, profile: PlayerProfile, policy: String, items: Array, match_number: int) -> void:
 if policy != "timed_ward" and policy != "reserve_repair":
  super(model,profile,policy,items,match_number)
  return
 var room := model.player()
 var hunter := model.hunter
 var contested := hunter.target == room.index and hunter.state == HunterState.State.ATTACK
 if contested:
  if hunter.cooldown < 1.2 and room.door_hp < room.max_hp()*.92 and model.route_defense_power():
   return
  if room.max_hp()-room.door_hp >= Catalog.REPAIR_HEAL*room.repair_factor and model.repair_door():
   return
  if policy == "reserve_repair":
   return
 super(model,profile,"economics",items,match_number)

func observe(model: MatchModel, stats: Dictionary, previous: Vector2, wallet: Vector2, prior_evolution: int) -> bool:
 var h := model.hunter
 if room_footprints.is_empty():
  var r := model.player()
  room_footprints["version"]=r.spatial.snapshot().version
  for kind in ["turret","heavy","generator","repair"]:
   var extent: Vector2=r.spatial.footprint_for(r.bounds().get_center(),kind,0).size
   room_footprints[kind]=[extent.x,extent.y]
 if opening_roster.is_empty() and model.time >= model.preparation - MODEL_STEP and h.target < 0:
  opening_roster = room_details(model)
 var target: int = h.target
 if target >= 0 and target < model.rooms.size():
  var movement := previous.distance_to(h.position)
  travel_per_target[target]+=movement
  if h.state == HunterState.State.MOVE:
   pre_contact_distances[target]+=movement
 for event in model.presentation_events:
  var id: int = event.id
  if id<=last_observed_event:continue
  last_observed_event=id
  var kind: String=event.type
  var room: int=event.room
  if kind=="approach":
   var costs: Dictionary = h._route_costs.duplicate()
   approach_details.append({
    "time":event.time,"room":room+1,"hunter_position":[h.position.x,h.position.y],"hunter_hp":h.hp,
    "decision_count":h.decision_count,"route_costs":costs,"target_history":h.target_history.duplicate(),
    "roster":room_details(model),
   })
  elif kind=="encounter":
   encounter_details.append({"time":event.time,"room":room+1,"hunter_hp":h.hp,"door_hp":model.rooms[room].door_hp,"battle_roster":room_details(model)})
  elif kind in ["door_break","elimination"]:
   losses.append({"time":event.time,"room":room+1,"kind":kind,"hunter_hp":h.hp})
  elif kind=="door_damage" and room>=0 and first_strike[room]<0:
   first_strike[room]=event.time
  elif room == model.player_room and kind in ["build","building_upgrade","bed_upgrade","door_upgrade","repair","emergency_ward"]:
   var entry: Dictionary=event.duplicate(true)
   entry["frame_gold"]=model.player().gold
   entry["frame_power"]=model.player().electricity
   built.append(entry)
 return super(model, stats, previous, wallet, prior_evolution)
