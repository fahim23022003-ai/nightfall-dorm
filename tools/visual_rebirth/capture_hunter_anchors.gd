extends "res://tools/capture_visual_rebirth.gd"
## Compare rendered evolution anchors in one frozen room, without changing zoom.

const LEVELS := [1, 4, 7, 10]
const CROP := Vector2i(224, 154)
const CROP_OFFSET := Vector2i(-104, -113)

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 if OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") != "1":
  push_error("Enable the production visual preview before capturing anchor art.")
  quit(2)
  return

 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 var direction := Vector2(-1, 1).normalized()
 game.presentation.identity.heading = direction
 for frame in range(8):
  game.presentation.update(.125, model)
  await _render_frame()

 var results: Array[Dictionary] = []
 var complete_headings := {}
 var crop_rect := Rect2i(Vector2i(root.get_final_transform() * game.world_to_screen(model.hunter.position)) + CROP_OFFSET, CROP)
 var saved_frames := 0
 for archetype in StrategyCatalog.ARCHETYPE_IDS:
  model.hunter.archetype = archetype
  model.strategy.archetype = archetype
  game.presentation.identity.heading = direction
  game.presentation.nightmare_visual.reset()
  var digests := {}
  for level in LEVELS:
   model.evolution.evolution_level = level
   model.evolution.final_revealed = level == 10
   model.evolution.rebirth_remaining = 0.0
   game.ui.update_match()
   check(game.ui.hunter_label.text.begins_with("HUNTER EVO %d " % level), "HUD reports staged evolution %d" % level)
   await _render_frame()
   var view := root.get_texture().get_image()
   var path := _art_path(archetype, level)
   var stem := "%s-l%02d" % [archetype, level]
   check(not path.is_empty(), stem + " bound its exact production asset")
   check(view.get_size() == Vector2i(1280, 720), stem + " rendered at 720p")
   check(Rect2i(Vector2i.ZERO, view.get_size()).encloses(crop_rect), stem + " native crop inside viewport")
   check(view.save_png(destination.path_join(stem + "-720.png")) == OK, stem + " full native frame")
   var crop := view.get_region(crop_rect)
   var hash := HashingContext.new()
   hash.start(HashingContext.HASH_SHA256)
   hash.update(crop.get_data())
   var digest := hash.finish().hex_encode()
   digests[digest] = true
   check(crop.save_png(destination.path_join(stem + ".png")) == OK, stem + " unscaled crop")
   results.append({"hunter": archetype, "level": level, "art": path, "crop_pixels_sha256": digest})
   saved_frames += 1
  check(digests.size() == LEVELS.size(), archetype + " four native crops differ")
  complete_headings[archetype] = await _check_anchor_headings(archetype)

 var record := {
  "viewport": [1280, 720],
  "crop": [crop_rect.position.x, crop_rect.position.y, CROP.x, CROP.y],
  "fixture": "Prepared frozen 16-slot Endless room. Archetype and evolution are staged for matching views.",
  "levels": LEVELS,
  "frames": results,
  "level10_heading_art": complete_headings,
 }
 var json := FileAccess.open(destination.path_join("anchor-captures.json"), FileAccess.WRITE)
 check(json != null, "open capture metadata")
 if json != null:
  json.store_string(JSON.stringify(record, "  ") + "\n")
 print("HUNTER_ANCHOR_FRAMES=", saved_frames)
 await _finish()

func _art_path(archetype: String, level: int) -> String:
 if archetype == "witch":
  var witch = game.presentation.nightmare_visual.witch_preview
  var path: String = witch.ART_PATH % [level, "oblique"]
  return path if witch.textures.has(path) and witch.textures[path] != null else ""
 var preview = game.presentation.nightmare_visual.get(archetype + "_preview")
 if preview == null or preview.active_level != level or preview.texture == null:
  return ""
 var expected := "level_%02d_oblique.png" % level
 if archetype == "stalker" and level == 1:
  expected = "level_01_left_prototype.png"
 return preview.texture.resource_path if preview.texture.resource_path.ends_with(expected) else ""


func _check_anchor_headings(archetype: String) -> Dictionary:
 var facing := {"north": Vector2.UP, "south": Vector2.DOWN, "west": Vector2.LEFT, "east": Vector2.RIGHT}
 var bindings := {}
 for label in facing:
  var heading: Vector2 = facing[label]
  game.presentation.identity.heading = heading
  await _render_frame()
  var path := ""
  var preview = game.presentation.nightmare_visual.get(archetype + "_preview")
  if archetype == "witch":
   var wanted: String = preview.ART_PATH % [10, preview.facing(heading)]
   path = wanted if preview.textures.has(wanted) and preview.textures[wanted] != null else _art_path(archetype, 10)
  elif preview.active_level == 10 and preview.texture != null and not preview.pose_name.is_empty():
   path = preview.texture.resource_path
  check(path.get_file().begins_with("level_10_"), archetype + " L10 preserves modern art facing " + label)
  bindings[label] = path
 return bindings
