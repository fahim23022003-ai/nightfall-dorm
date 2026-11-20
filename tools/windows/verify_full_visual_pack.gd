extends SceneTree

const FIXED := ["bed","door","frost","barrier","antenna"]
const WEAPON_ATLASES := ["turret","heavy","flame"]
const MOTION_ATLASES := ["generator","repair","economy","enhancer","shock","auto_repair","shield","decoy","plasma"]
const CARDINAL_VIEWS := ["front","back","left","right"]
const ART := "res://assets/visual_rebirth/"
var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func require(condition: bool, message: String):
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func require_texture(path: String, expected := Vector2i.ZERO):
 var texture := ResourceLoader.load(path) as Texture2D
 require(texture != null and texture.get_width() > 0 and texture.get_height() > 0
  and (expected == Vector2i.ZERO or Vector2i(texture.get_size()) == expected),
  "imported pack texture %s has expected dimensions %s" % [path, expected])

func hunter_pose_size(kind: String, level: int, view: String) -> Vector2i:
 if kind in ["witch", "stalker"] and level == 1:
  return Vector2i(264, 768) if kind == "stalker" and view == "oblique" else Vector2i(216, 264)
 if (kind == "storm" and level > 1) or (kind == "electric" and level == 8 and view != "oblique"):
  return Vector2i(432, 264)
 return Vector2i(328, 264)

func check_construction(game):
 var grid_enabled := OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1"
 var started: bool = game.start_endless("abandoned_dorm", "standard", 71)
 require(started, "packaged game starts Endless")
 if not started:
  return
 var model = game.model
 require(model.claim_room(0), "Endless player claims the test room")
 var room = model.player()
 if room == null:
  return
 model.player_position = room.bed_position()
 require(model.sleep_player(), "Endless player occupies the bed")
 require(room.spatial != null and room.spatial.grid == grid_enabled, "Endless construction mode follows launcher")
 if not grid_enabled:
  require(room.expansion_tier == 0, "reference retains the initial paid expansion tier")
  return
 var candidate := Vector2.INF
 var bounds: Rect2 = room.bounds()
 for y in range(16, int(bounds.size.y), 16):
  for x in range(16, int(bounds.size.x), 16):
   var point: Vector2 = room.spatial.aligned(bounds.position + Vector2(x, y), "turret", 0)
   if room.spatial.purchase_reason("turret", point) == "":
    candidate = point
    break
  if candidate.is_finite():
   break
 require(candidate.is_finite(), "full room exposes a legal aligned construction cell")
 if candidate.is_finite():
  var expected_gold: float = room.gold - room.quote_build("turret").x
  require(model.place_building("turret", candidate, 0), "packaged model executes paid grid placement")
  require(not model.place_building("turret", candidate, 0), "packaged model rejects occupied grid cells")
  require(room.buildings.size() == 1 and is_equal_approx(room.gold, expected_gold),
   "legal placement and rejected overlap charge exactly once")

func run():
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var all_roles := FIXED + WEAPON_ATLASES + MOTION_ATLASES
 require(all_roles.size() == Catalog.BUILDINGS.size() + 2, "all 17 building types declared")
 for kind in all_roles:
  var folder: String = ART + "buildings/%s/" % kind
  var cell := 112 if kind == "turret" else 96
  require_texture(folder + "base.png", Vector2i(6 * cell, 4 * cell))
  if kind in WEAPON_ATLASES:
   require_texture(folder + "launcher.png", Vector2i(12 * cell, 22 * cell))
  if kind in MOTION_ATLASES:
   require_texture(folder + "motion.png", Vector2i(8 * cell, 22 * cell))
 var direction_count := 0
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for level in range(1,11):
   var oblique := "left_prototype" if kind == "stalker" and level == 1 else "oblique"
   require_texture(ART + "%s/level_%02d_%s.png" % [kind,level,oblique], hunter_pose_size(kind, level, "oblique"))
   for view in CARDINAL_VIEWS:
    require_texture(ART + "%s/level_%02d_%s.png" % [kind,level,view], hunter_pose_size(kind, level, view))
    direction_count += 1
 for form in ["approach","transformed"]:
  require_texture(ART + "grim_reaper/" + form + ".png", Vector2i(224, 264))
  for view in CARDINAL_VIEWS:
   require_texture(ART + "grim_reaper/%s_%s.png" % [form,view], Vector2i(224, 264))
   direction_count += 1
 require(direction_count == 248, "all 248 cardinal Hunter and Reaper assets visited")
 require_texture(ART + "buildings/masterwork_details.svg")
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 require(game.profile != null and game.presentation != null, "real packaged game boots")
 var visual = game.presentation.building_visual
 for kind in FIXED:
  var bound: bool = visual.weapon_rebirth_active(kind) if kind == "frost" else visual.STATIC_BRANCHES.has(kind) and visual.load_rebirth_atlas(kind,"")
  require(bound == pilot, "packaged static building follows mode " + kind)
 for kind in WEAPON_ATLASES:
  require(visual.weapon_rebirth_active(kind) == pilot, "packaged weapon follows mode " + kind)
 for kind in MOTION_ATLASES:
  require(visual.support_rebirth_active(kind) == pilot, "packaged machine follows mode " + kind)
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var preview = game.presentation.nightmare_visual.get(kind+"_preview")
  require(preview != null and preview.enabled == pilot, "packaged Hunter follows mode " + kind)
 require(game.presentation.boss_presentation.preview_enabled == pilot, "packaged Reaper follows mode")
 var practice_started: bool = game.start_practice("stalker", false, ["shield","repair"])
 require(practice_started, "packaged game starts a real encounter")
 if not practice_started:
  quit(1)
  return
 await process_frame
 require(game.model.hunter.archetype == "stalker" and game.model.player() != null, "encounter rooms and model initialized")
 for cue in ["cinematic_stalker_breath","cinematic_crusher_approach","cinematic_ravager_approach","cinematic_witch_approach","cinematic_electric_approach","cinematic_storm_approach"]:
  require(game.audio_system.streams.has(cue), "distinct Hunter cue registered " + cue)
 if OS.has_environment("NIGHTFALL_FULL_ROOM_GRID"):
  require(game.model.player().spatial == null, "Practice retains its designed construction layout")
  game.return_menu()
  check_construction(game)
 game.return_menu()
 game.audio_system.shutdown()
 await create_timer(.5).timeout
 game.queue_free()
 await create_timer(.2).timeout
 print("FULL_VISUAL_WINDOWS_PACK_CHECKS=", checks, " FAILURES=", failures, " PILOT=", pilot, " NATIVE_WINDOWS=UNVERIFIED")
 quit(1 if failures > 0 else 0)
