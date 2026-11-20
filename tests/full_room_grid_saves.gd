extends "res://tests/spatial_construction.gd"

const GRID_ENV = "NIGHTFALL_FULL_ROOM_GRID"
const EARNED = "res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"

func building_investments(buildings: Dictionary) -> Dictionary:
 var investments := buildings.duplicate(true)
 for id in investments:
  investments[id].erase("position")
  investments[id].erase("rotation")
 return investments

func earned_migration() -> void:
 var hash := FileAccess.get_sha256(EARNED)
 var data = JSON.parse_string(FileAccess.get_file_as_string(EARNED))
 OS.set_environment(GRID_ENV,"0")
 var baseline := Snapshot.restore(data)
 check(baseline!=null and not baseline.player().spatial.grid,"real earned wave 45 loads with the grid off")
 if baseline==null:return
 var old := Snapshot.encode(baseline)
 check(old.version==Snapshot.SCHEMA and old.ruleset==Snapshot.RULESET,"fallback retains its spatial checkpoint format")
 var old_player: RoomState=baseline.player()
 OS.set_environment(GRID_ENV,"1")
 var converted := Snapshot.restore(old)
 check(converted!=null and converted.player().spatial.grid,"real earned wave 45 migrates with preview enabled")
 if converted==null or not converted.player().spatial.grid:return
 var room: RoomState=converted.player()
 check(room.buildings.size()==12 and building_investments(room.buildings)==building_investments(old_player.buildings),"all earned buildings, branches, cooldowns and investments survive")
 check([room.gold,room.electricity,room.spent,room.construction_actions]==[old_player.gold,old_player.electricity,old_player.spent,old_player.construction_actions],"migration charges no wallet or ledger")
 check([room.bed_position(),room.layout.cabinet,room.layout.plant]==[old_player.bed_position(),old_player.layout.cabinet,old_player.layout.plant],"migration preserves all furniture anchors")
 check(room.door_hp==old_player.door_hp and converted.random.state==baseline.random.state and converted.endless.completed==45,"migration preserves door HP, RNG and wave")
 for index in range(1,6):
  check(converted.rooms[index].buildings==baseline.rooms[index].buildings and converted.rooms[index].layout==baseline.rooms[index].layout,"migration preserves NPC room %d" % index)
 var migrated := Snapshot.encode(converted)
 check(Snapshot.valid(migrated) and migrated.version==Snapshot.GRID_SCHEMA and migrated.ruleset==Snapshot.GRID_RULESET,"migrated live room produces a grid checkpoint")
 OS.set_environment(GRID_ENV,"0")
 var restored := Snapshot.restore(JSON.parse_string(JSON.stringify(migrated)))
 check(restored!=null and restored.player().spatial.grid,"saved grid remains playable with environment opt-in disabled")
 if restored!=null:
  check(Support.numeric_same(Snapshot.encode(restored),migrated),"earned grid saves and restores identical data and positions")
  check(restored.continue_wave("repair") and restored.endless.wave==46,"earned grid resumes the actual next wave")
 check(FileAccess.get_sha256(EARNED)==hash,"canonical earned save remains unchanged")
 OS.set_environment(GRID_ENV,"1")
 var from_legacy := Snapshot.restore(data)
 check(from_legacy!=null and from_legacy.player().spatial.grid,"same real legacy schema 1 checkpoint migrates directly")
 if from_legacy!=null:
  check(from_legacy.player().buildings==room.buildings,"schema 1 and spatial schema 2 choose the same migrated layout")

func ground_points(room: RoomState) -> Array[Vector2]:
 var points: Array[Vector2]=[]
 var bounds := room.spatial.grid_bounds()
 var dims := Vector2i(bounds.size/SpatialConstruction.CELL_SIZE)
 for y in range(1,dims.y):
  for x in range(1,dims.x):
   var point := bounds.position+Vector2(x,y)*SpatialConstruction.CELL_SIZE
   points.append(room.spatial.aligned(point,"turret"))
 return points

func dense_profile_roundtrip() -> void:
 OS.set_environment(GRID_ENV,"1")
 var a=fixture("abandoned_dorm")
 var model: MatchModel=a.m
 var profile: PlayerProfile=a.p
 var room: RoomState=model.player()
 check(room.spatial.grid,"new opted-in profile session starts in grid mode")
 if not room.spatial.grid:return
 var candidates := ground_points(room)
 var approach := room.door_approach()
 candidates.sort_custom(func(x,y):return x.distance_squared_to(approach)<y.distance_squared_to(approach))
 var rotated := -1
 for point in candidates:
  var rotation=1 if rotated<0 else 0
  if room.spatial.purchase_reason("turret",point,rotation)!="":continue
  check(model.place_building("turret",point,rotation),"legal dense grid purchase spends in the normal model")
  if rotated<0:rotated=room.spatial.next_id-1
  if room.buildings.size()==17:break
 check(rotated>=0 and room.buildings.size()==17,"a real 17-building room passes the physical grid limit")
 if room.buildings.size()!=17:return
 check(room.buildings[rotated].rotation==1,"a nonzero quarter turn exists in the live room")
 clear_wave(a)
 if model.endless.phase!="intermission":return
 var saved := profile.checkpoint_endless(model) and profile.save_profile()
 check(saved,"actual profile transaction writes the dense grid and a valid backup")
 if not saved:return
 var primary: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(profile.path))
 var expected: Dictionary=primary.replay.checkpoint.duplicate(true)
 OS.set_environment(GRID_ENV,"0")
 var loader := PlayerProfile.new(profile.path)
 check(loader.load_profile() and not loader.read_only,"disk profile accepts grid data with opt-in switched off")
 var restored: MatchModel=loader.resume_endless()
 check(restored!=null and restored.player().spatial.grid and restored.player().spatial.actor_points_provider.is_valid(),"normal profile Resume rebinds the saved grid and live collision guard")
 if restored!=null:
  check(restored.player().buildings[rotated].rotation==1,"JSON roundtrip keeps the exact nonzero rotation")
  check(Support.numeric_same(Snapshot.encode(restored,profile.active_match.get("use_counts",{})),expected),"disk grid roundtrip retains every encoded field")

 var index: int=model.player_room
 for mutation in ["missing_rotation","invalid_rotation","overlap","wrong_tier","no_marker","legacy_header"]:
  var corrupt := expected.duplicate(true)
  match mutation:
   "missing_rotation":corrupt.rooms[index].buildings[0].erase("rotation")
   "invalid_rotation":corrupt.rooms[index].buildings[0].rotation=4
   "overlap":corrupt.rooms[index].buildings[0].position=corrupt.rooms[index].buildings[1].position
   "wrong_tier":corrupt.expansion.levels[index]-=1
   "no_marker":corrupt.rooms[index].construction.erase("grid")
   "legacy_header":
    corrupt.version=Snapshot.SCHEMA
    corrupt.ruleset=Snapshot.RULESET
  check(not Snapshot.valid(corrupt),"grid validation rejects "+mutation)

 primary.replay.checkpoint.rooms[index].buildings[0].rotation=5
 var source := JSON.stringify(primary)
 var file := FileAccess.open(profile.path,FileAccess.WRITE)
 file.store_string(source)
 file.close()
 var recovered := PlayerProfile.new(profile.path)
 check(recovered.load_profile() and not recovered.read_only and recovered.warning.contains("backup"),"corrupt known grid checkpoint recovers compatible backup")
 check(recovered.resume_endless()!=null and FileAccess.get_file_as_string(profile.path)==source,"grid recovery keeps damaged primary bytes and a resumable model")

func failed_fit_rollback() -> void:
 OS.set_environment(GRID_ENV,"0")
 var a=fixture("abandoned_dorm")
 var model: MatchModel=a.m
 var room: RoomState=model.player()
 check(model.place_building("turret",free_point(room)),"rollback fixture starts with one paid building")
 # Deliberately stage an impossible in-memory floor. The test never encodes it.
 room.expansion_tier=RoomExpansion.SLOTS.size()-1
 room.layout.bounds=Rect2(room.bounds().position,Vector2(24,24))
 var before := room.buildings.duplicate(true)
 var layout := room.layout.duplicate(true)
 var saved := room.spatial.snapshot()
 var funds := Vector2(room.gold,room.electricity)
 check(not model.enable_player_grid(),"unfit grid candidate is rejected")
 check(room.buildings==before and room.layout==layout and room.spatial.snapshot()==saved and Vector2(room.gold,room.electricity)==funds,"failed conversion preserves every position, identity and wallet value")

func run():
 var setting := OS.get_environment(GRID_ENV)
 earned_migration()
 dense_profile_roundtrip()
 failed_fit_rollback()
 OS.set_environment(GRID_ENV,setting)
 Support.cleanup(prefix)
 print("FULL_GRID_SAVE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
