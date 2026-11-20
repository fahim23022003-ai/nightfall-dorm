extends "res://tools/visual_rebirth/capture_hunter_anchor_combat.gd"
## Native rendered coverage of the ordinary Hunter catalog, in resumable shards.

const CARDINALS := ["right", "front", "left", "back"]
const TURN_ROUTE := [
 Vector2(95, 305), Vector2(150, 305), Vector2(150, 344),
 Vector2(102, 344), Vector2(102, 305),
]
const ANCHOR_STILLS := ["crusher", "ravager", "storm"]
const VIEWPORT_SIZE := Vector2i(1280, 720)
var save_stills := false
var quality := "medium"
var native_frames := 0
var turns_observed := 0

func run():
 var args := OS.get_cmdline_user_args()
 var selected_family := args[1] if args.size() >= 2 else "all"
 var selected_level := args[2] if args.size() >= 3 else "all"
 var valid_family := selected_family == "all" or selected_family in StrategyCatalog.ARCHETYPE_IDS
 var selected_tokens := selected_level.split(",", false)
 var selected_values := Array(selected_tokens).map(func(token):return token.to_int())
 var valid_level := selected_level == "all" or (not selected_values.is_empty() and Array(selected_tokens).all(func(token):return token.is_valid_int() and token.to_int() in range(1,11)) and selected_values==unique_levels(selected_values))
 if args.is_empty() or not args[0].is_absolute_path() or not valid_family or not valid_level:
  push_error("Pass absolute output path, Hunter ID or all, and levels 1-10 (comma-separated) or all after --.")
  quit(2)
  return
 if DisplayServer.get_name() == "headless":
  push_error("This verification needs real raster output from a graphical Godot session.")
  quit(2)
  return
 var available_only := "--available" in args
 save_stills = "--stills" in args
 if "--low" in args:
  quality = "low"
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE", "1")
 OS.set_environment("NIGHTFALL_VISUAL_REBIRTH", "1")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "0")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS_V2", "0")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 var destination := args[0].trim_suffix("/")
 DirAccess.make_dir_recursive_absolute(destination)
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 root.size = VIEWPORT_SIZE
 await setup_game()
 game.onboarding.close_welcome()
 game.profile.settings.graphics_quality = quality
 check(root.get_texture().get_size() == Vector2(VIEWPORT_SIZE), "native viewport at 1280×720")
 var records: Array[Dictionary] = []
 var unavailable: Array[String] = []
 var chosen_families: Array = StrategyCatalog.ARCHETYPE_IDS if selected_family == "all" else [selected_family]
 var chosen_levels: Array = range(1, 11) if selected_level == "all" else selected_values
 var cases := []
 for hunter: String in chosen_families:
  for level: int in chosen_levels:
   cases.append([hunter, level])
 for argument: String in args.slice(3):
  if not argument.begins_with("--cases="):
   continue
  var supplied := decode_cases(argument.trim_prefix("--cases="))
  if supplied.is_empty():
   push_error("Pass comma-separated Hunter and level pairs, such as --cases=crusher:6,witch:7.")
   quit(2)
   return
  cases = supplied
 for pair: Array in cases:
  var hunter: String = pair[0]
  var level: int = pair[1]
  var key := Articulation.catalog_key(hunter, level)
  if key.is_empty():
   var missing := "%s_l%02d" % [hunter, level]
   unavailable.append(missing)
   if not available_only:
    check(false, missing + " has no rig catalog entry")
   continue
  var state := await verify_state(hunter, level, key, destination)
  records.append(state)
  print("ARTICULATION_STATE ", hunter, " L", level, " views=", state.textures.size(), " contact_error=", state.contact_error_px, " failures=", state.failures)
 check(not records.is_empty(), "at least one ordinary state presented")
 var lifecycle := {}
 if "--lifecycle" in args:
  lifecycle = await observe_lifecycle(destination)
 var receipt := FileAccess.open(destination.path_join("articulation-catalog.json"), FileAccess.WRITE)
 check(receipt != null, "native catalog receipt opens")
 if receipt != null:
  receipt.store_string(JSON.stringify({
   "viewport": [1280, 720], "quality": quality, "engine": Engine.get_version_info().string,
   "display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
   "frame_step": STEP, "frames_rendered": native_frames, "selected_family": selected_family,
   "turn_samples": turns_observed, "lifecycle": lifecycle,
   "selected_level": selected_level, "available_only": available_only,
   "expected_states": cases.size(), "selected_cases": cases, "rendered_states": records.size(),
   "verified_states": records.filter(func(state): return state.failures == 0).size(),
   "unavailable": unavailable, "states": records, "checks": checks, "failures": failures,
   "fixture": "Prepared seeded Endless room and Hunter evolution. Validated corridor routes use the ordinary navigation primitive. Combat advances through normal gameplay ticks, a paid Needle, existing Hunter windup and real doorstep damage. Render samples are sparse. Graphics validation checks atlas binding and event contact, not artistic approval.",
  }, "  ") + "\n")
  receipt.close()
 print("ARTICULATION_CATALOG_STATES=", records.size(), " UNAVAILABLE=", unavailable.size(), " RENDERED_FRAMES=", native_frames)
 await _finish()

static func decode_cases(value: String) -> Array:
 var chosen := []
 for pair in value.split(",", false):
  var parts := pair.split(":", false)
  if parts.size() != 2 or parts[0] not in StrategyCatalog.ARCHETYPE_IDS or not parts[1].is_valid_int():
   return []
  var level := parts[1].to_int()
  var item := [parts[0], level]
  if level not in range(1, 11) or item in chosen:
   return []
  chosen.append(item)
 return chosen

static func unique_levels(values: Array) -> Array:
 var unique := []
 for level in values:
  if level not in unique:
   unique.append(level)
 return unique

func verify_state(hunter: String, level: int, key: String, destination: String) -> Dictionary:
 var before_failures: int = failures
 var label := "%s L%d" % [hunter, level]
 var model: MatchModel = _setup_anchor_combat(hunter, level)
 check(game.ui.hunter_label.text.begins_with("HUNTER EVO %d " % level), label + " HUD agrees with staged evolution")
 var directions := {}
 var all_views := {}
 var joint_range := 0.0
 var minimum_joint_span := INF
 var rig = game.presentation.nightmare_visual.articulated
 var state_turns := 0
 for index in range(1, TURN_ROUTE.size()):
  var to: Vector2 = TURN_ROUTE[index]
  var cardinal: String = CARDINALS[index - 1]
  check(model._visible(model.hunter.position, to), label + " walkable " + cardinal + " route")
  var route_steps := 0
  var direction_poses: Array[Vector2] = []
  var view_path := ""
  while not model.hunter.position.is_equal_approx(to) and route_steps < 45:
   model.hunter.navigate(to, STEP)
   game.presentation.update(STEP, model)
   route_steps += 1
   if route_steps % 3 == 0 or model.hunter.position.is_equal_approx(to):
    await native_frame()
    var path: String = rig.last_asset
    if not path.is_empty():
     all_views[path] = true
    if rig.pose_name == "turn":
     turns_observed += 1
     state_turns += 1
    if rig.pose_name in ["move", "turn"] and path.ends_with("%s_%s.png" % [key, cardinal]) and rig.joint_points.size() == 4:
     view_path = path
     var shoulder: Vector2 = rig.joint_points[0]
     var tip: Vector2 = rig.joint_points[3]
     direction_poses.append(tip - shoulder)
     minimum_joint_span = minf(minimum_joint_span, shoulder.distance_to(tip))
  check(model.hunter.position.is_equal_approx(to), label + " completes " + cardinal + " walk")
  check(direction_poses.size() >= 2, label + " moves with the independent " + cardinal + " rig")
  var articulation_range := 0.0
  for pose: Vector2 in direction_poses:
   articulation_range = maxf(articulation_range, pose.distance_to(direction_poses[0]))
  joint_range = maxf(joint_range, articulation_range)
  directions[cardinal] = {"path": view_path, "poses": direction_poses.size(), "relative_tip_motion_px":snappedf(articulation_range, .001),
                          "atlas_sha256":FileAccess.get_sha256(view_path) if not view_path.is_empty() else ""}
 check(all_views.size() == 4 and directions.values().filter(func(direction): return direction.path != "").size() == 4, label + " binds four distinct directional textures")
 check(joint_range > .18 and is_finite(minimum_joint_span) and minimum_joint_span > 4.0, label + " limbs move relative to the torso in the raster draw")

 var door := model.player().door_approach()
 var corner := Vector2(113, 342)
 check(walk_to(model, Vector2(158, 305)) and walk_to(model, corner) and walk_to(model, door), label + " approaches the real door through legal waypoints")
 var combat := await observe_combat(model, key, label, destination)
 return {
  "hunter": hunter, "level": level, "key": key, "textures": all_views.keys(), "directions": directions,
  "joint_range_px": snappedf(joint_range, .001), "minimum_joint_span_px": snappedf(minimum_joint_span,.001) if is_finite(minimum_joint_span) else null,
  "contact_error_px": combat.error_px, "event": combat.event, "poses": combat.poses,
  "turn_samples": state_turns, "post_strike_pose": combat.post_strike_pose,
  "door_damage": combat.door_damage, "needle_damage": combat.needle_damage, "failures": failures - before_failures,
 }

func walk_to(model: MatchModel, goal: Vector2) -> bool:
 if not model._visible(model.hunter.position, goal):
  return false
 for step in range(45):
  if model.hunter.position.is_equal_approx(goal):
   return true
  model.hunter.navigate(goal, STEP)
  game.presentation.update(STEP, model)
 return model.hunter.position.is_equal_approx(goal)

func observe_combat(model: MatchModel, key: String, label: String, destination: String) -> Dictionary:
 var room := model.player()
 var original_door: float = room.door_hp
 var original_hunter: float = model.hunter.hp
 var rig = game.presentation.nightmare_visual.articulated
 var seen := {}
 var impact := {}
 var contact_error := -1.0
 var needle_hit := false
 var readiness_pose := ""
 for tick in range(150):
  game._process(STEP)
  var hit: Dictionary = game.presentation.hunter_combat.latest_body_contact(model)
  var flashing := model.hunter.hit_flash > 0.0 and model.hunter.hp < original_hunter
  var windup: bool = model.hunter.windup_remaining > 0.0
  var contact_now: bool = not hit.is_empty() and hit.age <= Articulation.CONTACT_HOLD
  var follow_now: bool = not hit.is_empty() and hit.age >= .11 and hit.age <= .21
  var recovering: bool = not hit.is_empty() and hit.age > Articulation.STRIKE_RECOVERY
  var after_follow := seen.has("follow") and hit.is_empty() and not windup
  if ((flashing and not seen.has("hit")) or (windup and not seen.has("windup")) or
     (contact_now and not seen.has("contact")) or (follow_now and not seen.has("follow")) or
     (recovering and not seen.has("recover")) or
     (after_follow and readiness_pose.is_empty())):
   await native_frame()
   var pose: String = rig.pose_name
   var asset: String = rig.last_asset
   check(asset.get_file().begins_with(key + "_"), label + " combat samples bind exact-level atlas")
   if pose in ["hit", "windup", "contact", "follow", "recover"]:
    seen[pose] = true
   if after_follow and pose in ["idle", "recover", "hit"]:
    readiness_pose = pose
   if pose == "contact" and contact_now and impact.is_empty() and rig.contact.is_finite():
    var point: Vector2 = Vector2(hit.point) + game.MAP_OFFSET
    contact_error = rig.contact.distance_to(point)
    impact = {"id": hit.id, "source": hit.source, "room": hit.room, "time": hit.time, "style": hit.style,
              "door_socket": [point.x, point.y], "limb_tip": [rig.contact.x, rig.contact.y]}
    if save_stills and key in ANCHOR_STILLS.map(func(family):return Articulation.catalog_key(family,1)):
     var still := root.get_texture().get_image()
     check(still.get_size() == VIEWPORT_SIZE and still.save_png(destination.path_join(key + "-contact.png")) == OK, label + " native contact still")
  for event: Dictionary in model.combat_events:
   if event.room == room.index and event.kind == "turret" and event.type == "impact":
    needle_hit = true
  if seen.size() == 5 and not readiness_pose.is_empty() and needle_hit:
   break
 check(needle_hit and model.hunter.hp < original_hunter and seen.has("hit"), label + " real Needle impact causes rendered hit reaction")
 check(seen.has("windup") and seen.has("contact") and not impact.is_empty(), label + " real telegraph reaches a rendered contact")
 check(model.hunter.attacks > 0 and room.door_hp < original_door and contact_error >= 0.0 and contact_error <= 2.0,
       label + " landed door damage and limb contact share a socket within 2px")
 check(seen.has("follow") and seen.has("recover") and not readiness_pose.is_empty(), label + " lands, follows through, recovers and resumes combat posture")
 return {"event": impact, "error_px": snappedf(contact_error,.001), "poses": seen.keys(), "post_strike_pose": readiness_pose,
         "door_damage": original_door - room.door_hp, "needle_damage": original_hunter - model.hunter.hp}

func observe_lifecycle(destination: String) -> Dictionary:
 var start_checks: int = checks
 var start_failures: int = failures
 var model := MatchModel.new()
 model.procedural_v2_requested = true
 model.reset(72)
 var configured: bool = model.configure_match("standard") and model.configure_stage("stage_1") and model.configure_balance()
 configured = configured and model.configure_strategy(72, "stalker")
 check(configured and model.is_procedural() and model.map_data.get("halls",{}).size() == 4, "native lifecycle uses a real V2 map")
 if not configured or not model.map_data.has("halls"):
  return {"failure": "could not configure V2"}
 var west: Dictionary = model.map_data.halls.west
 var approach: Vector2 = west.entrance + (west.entrance - west.center).normalized() * 64.0
 if not model.navigation_walkable(approach):
  approach = west.entrance
 var closest := INF
 var nearest := -1
 for room: RoomState in model.rooms:
  var route := model.navigation_path(approach, room.door_approach())
  if route.is_empty():
   continue
  var distance := 0.0
  var previous := approach
  for waypoint: Vector2 in route:
   distance += previous.distance_to(waypoint)
   previous = waypoint
  if distance < closest:
   closest = distance
   nearest = room.index
 check(nearest >= 0 and model.claim_room(nearest), "native lifecycle claims reachable neighboring room")
 if model.player() == null:
  return {"failure": "could not claim room"}
 model.player_position = model.player().bed_position()
 check(model.sleep_player(), "native lifecycle uses real bed action")
 model.bot_claimed = 5
 model.time = model.preparation + 75.15
 model.hunter.position = approach
 model.hunter.state = HunterState.State.MOVE
 model.hunter.target = nearest
 model.hunter.boss_policy.enabled = false
 model.hunter.tactical_cooldown = 999
 model.hunter.nightmare.cooldown = 999
 model.hunter.arcane.cooldown = 999
 model.hunter.tick(0.0, model)
 model.hunter.hp = model.hunter.max_hp * .34
 model.evolution.evolution_level = 1
 game._adopt_session(model)
 game.set_process(false)
 game.ui.show_match()
 game.focus_camera(true)
 var rig = game.presentation.nightmare_visual.articulated
 var observed := {}
 var evolution_record := {}
 var recovery_record := {}
 for index in range(480):
  game._process(STEP)
  if not game.hunter_spectating and model.haunt_recovery.is_active():
   check(game.watch_hunter(), "native watch control opens the real retreat camera")
  for event: Dictionary in model.presentation_events:
   if event.type == "nightmare_level" and evolution_record.is_empty():
    evolution_record = event.duplicate(true)
   elif event.type == "hunter_recovering" and recovery_record.is_empty():
    recovery_record = event.duplicate(true)
  if index < 6 and not evolution_record.is_empty() and not observed.has("evolve"):
   await native_frame()
   if rig.pose_name == "evolve":
    observed.evolve = {"asset": rig.last_asset, "time": model.time}
  if not recovery_record.is_empty() and model.haunt_recovery.healed > 0.0:
   await native_frame()
   if rig.pose_name == "heal":
    observed.heal = {"asset": rig.last_asset, "time": model.time, "amount": model.haunt_recovery.healed, "hall": model.haunt_recovery.hall_id}
    if save_stills:
     check(root.get_texture().get_image().save_png(destination.path_join("stalker-hall-recovery.png")) == OK, "native Haunted Hall still")
    break
 check(not evolution_record.is_empty() and int(evolution_record.get("level",0)) == 2 and observed.has("evolve"),
       "real nightmare level advancement triggers a native L2 evolution pose")
 check(not recovery_record.is_empty() and observed.has("heal"), "real named Hall recuperation heals and renders an articulated pose")
 if observed.has("heal"):
  var damage: float = model.apply_target_damage(1, model.hunter.max_hp * 2.0, nearest)
  check(damage > 0.0 and model.hunter.hp == 0.0 and model.hunter.state == HunterState.State.DEAD,
        "existing damage model produces a genuine Hunter death")
  game.presentation.update(STEP, model)
  await native_frame()
  if rig.pose_name == "vanish":
   observed.vanish = {"asset": rig.last_asset, "damage": damage, "time": model.time}
  check(observed.has("vanish"), "native joint rig renders death before clearing")
  game.presentation.update(1.6, model)
  await native_frame()
  check(rig.last_asset.is_empty() and game.presentation.death_age > 1.5, "native Hunter fade clears after death")
 return {"observed": observed, "evolution_event_id": evolution_record.get("id",0), "recovery_event_id": recovery_record.get("id",0),
         "checks": checks-start_checks, "failures": failures-start_failures, "rig": "stalker L2"}

func native_frame():
 await _render_frame()
 native_frames += 1
