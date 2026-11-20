extends SceneTree

const FIXED := ["bed","door","frost","barrier","antenna"]
const WEAPON_ATLASES := ["turret","heavy","flame"]
const MOTION_ATLASES := ["generator","repair","economy","enhancer","shock","auto_repair","shield","decoy","plasma"]
const WITCH_VIEWS := ["oblique","front","back","left","right"]
const CARDINAL_VIEWS := ["front","back","left","right"]
var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func require(condition: bool, message: String):
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func require_texture(path: String):
 var texture := ResourceLoader.load(path) as Texture2D
 require(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "imported pack texture " + path)

func run():
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var all_roles := FIXED + WEAPON_ATLASES + MOTION_ATLASES
 require(all_roles.size() == Catalog.BUILDINGS.size() + 2, "all 17 building types declared")
 for kind in all_roles:
  var folder: String = "res://assets/visual_rebirth/buildings/%s/" % kind
  require_texture(folder + "base.png")
  if kind in WEAPON_ATLASES:
   require_texture(folder + "launcher.png")
  if kind in MOTION_ATLASES:
   require_texture(folder + "motion.png")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for level in range(1,11):
   if kind == "stalker" and level == 1:
    require_texture("res://assets/visual_rebirth/stalker/level_01_left_prototype.png")
   elif kind == "witch" and level == 1:
    for view in WITCH_VIEWS:
     require_texture("res://assets/visual_rebirth/witch/level_01_%s.png" % view)
   else:
    require_texture("res://assets/visual_rebirth/%s/level_%02d_oblique.png" % [kind,level])
 for form in ["approach","transformed"]:
  require_texture("res://assets/visual_rebirth/grim_reaper/" + form + ".png")
 require_texture("res://assets/visual_rebirth/buildings/masterwork_details.svg")
 for view in CARDINAL_VIEWS:
  require_texture("res://assets/visual_rebirth/stalker/level_01_%s.png" % view)
  require_texture("res://assets/visual_rebirth/stalker/level_10_%s.png" % view)
  require_texture("res://assets/visual_rebirth/witch/level_10_%s.png" % view)
  require_texture("res://assets/visual_rebirth/storm/level_10_%s.png" % view)
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
 require(game.start_practice("stalker", false, ["shield","repair"]), "packaged game starts a real encounter")
 await process_frame
 require(game.model.hunter.archetype == "stalker" and game.model.player() != null, "encounter rooms and model initialized")
 for cue in ["cinematic_stalker_breath","cinematic_crusher_approach","cinematic_ravager_approach","cinematic_witch_approach","cinematic_electric_approach","cinematic_storm_approach"]:
  require(game.audio_system.streams.has(cue), "distinct Hunter cue registered " + cue)
 game.return_menu()
 game.audio_system.shutdown()
 await create_timer(.5).timeout
 game.queue_free()
 await create_timer(.2).timeout
 print("FULL_VISUAL_WINDOWS_PACK_CHECKS=", checks, " FAILURES=", failures, " PILOT=", pilot, " NATIVE_WINDOWS=UNVERIFIED")
 quit(1 if failures > 0 else 0)
