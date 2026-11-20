extends "res://tools/nightmare_maps/measure_hell_tactics.gd"
## Compare V2.2 and V2.3 from the same second defended siege.

const PREVIOUS_DOOR := 4

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["medium", "low"] or args[2] not in ["baseline", "candidate"]:
  push_error("Pass absolute output directory, medium or low, and baseline or candidate after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality := args[1]
 var policy := args[2]
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", quality)
 game.set_process(false)
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "requested graphics preset")
 var model := MatchModel.new()
 model.reset(MATCH_SEED)
 check(model.configure_match("hell", {}), "configure the Hell ruleset")
 check(model.configure_stage(CAMPAIGN_STAGE), "configure Cursed Mansion campaign")
 check(model.configure_balance(), "current balance settings")
 check(model.configure_strategy(MATCH_SEED, "crusher"), "same Hunter archetype")
 check(model.map_data.get("version") == NightmareMap.MACRO_VERSION, "V2 macro map active")
 model.hard_tactics_enabled = true
 model.fair_siege_enabled = true
 model.starting_room_review_enabled = policy == "candidate"
 check(model.uses_tactical_sieges() and model.fair_siege_enabled, "both cases retain the V2.2 defense logic")
 if failures > 0:
  await _finish()
  return
 game._adopt_session(model)
 var room := make_room_fixture(model)
 if room == null or failures > 0:
  await _finish()
  return


 # Set up a second siege after the Hunter previously left the low-HP
 # alternative. Other bot doors can withstand a similar second assault.
 # Repairs, attacks and the new decision use the production update loop.
 check(room.index != PREVIOUS_DOOR, "recently defended door differs from the current siege")
 var previous: RoomState = model.rooms[PREVIOUS_DOOR]
 model.time = model.preparation + 20.0
 model.bot_claimed = 5
 for ally: RoomState in model.rooms:
  if ally == room:
   continue
  ally.owner = ally.index + 1
  ally.profile = Catalog.BOT_PROFILES[ally.index % Catalog.BOT_PROFILES.size()]
  ally.resident_position = ally.bed_position()
  ally.sleeping = true
  ally.closed = true
  if ally != previous:
   ally.door_level = 6
   ally.door_hp = ally.max_hp()
 var hunter := model.hunter
 hunter.state = HunterState.State.ATTACK
 hunter.position = room.door_approach()
 hunter.target = room.index
 hunter.cooldown = .5
 hunter.siege_start_hp = room.max_hp()
 var prior_door_loss := room.max_hp() * .18
 room.door_hp -= prior_door_loss
 hunter.siege_landed_damage = prior_door_loss * 3.3
 hunter.last_defended_door = previous.index
 hunter.last_defended_hp = previous.door_hp
 hunter.last_defended_breach = HunterSiegeStrategy.MAX_BREACH_ESTIMATE
 var reassess_at := maxf(RankCatalog.pressure(model.difficulty).commit * StrategyCatalog.ARCHETYPES[hunter.archetype].commit, Catalog.HUNTER_ESCALATION.minimum_commitment)
 hunter.target_time = reassess_at - 2.5
 hunter.siege_seconds = hunter.target_time
 hunter.reassess_seconds = hunter.target_time
 var staged := {
  "initial_door_hp": room.door_hp, "prior_landed_damage": hunter.siege_landed_damage,
  "siege_start_hp": hunter.siege_start_hp, "reassess_elapsed_s": hunter.reassess_seconds,
  "previous_room": previous.index, "previous_door_hp": previous.door_hp,
  "previous_breach_s": hunter.last_defended_breach,
 }
 game.full_map = false
 game.focus_camera(true)
 await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "real 1280×720 viewport")

 var before := _state_digest(model)
 var active := await measure_active_siege(model)
 active.erase("tactical_switches")
 var decisions := []
 for event: Dictionary in model.presentation_events:
  if event.type in ["hunter_reassess", "hunter_commit"]:
   decisions.append({
    "type": event.type, "time": event.time, "room": event.room,
    "reason": event.get("reason", ""), "next_room": event.get("next_room", -1),
    "current_cost": event.get("current_cost", -1.0), "alternative_cost": event.get("alternative_cost", -1.0),
   })
 if policy == "candidate":
  check(decisions.any(func(event): return event.reason == "breach_progress"), "V2.3 keeps working on the current door")
  check(not decisions.any(func(event): return event.next_room == PREVIOUS_DOOR), "V2.3 avoids the recently defended door")
 else:
  check(decisions.any(func(event): return event.reason == "defense_delays_breach" and event.next_room == PREVIOUS_DOOR), "V2.2 heads back to the recently defended door")
 await capture("active-combat-720")
 var receipt := FileAccess.open(destination.path_join("benchmark.json"), FileAccess.WRITE)
 check(receipt != null, "write benchmark receipt")
 if receipt != null:
  var data := {
   "engine": Engine.get_version_info(), "adapter": RenderingServer.get_video_adapter_name(),
   "quality": quality, "policy": policy, "stage": CAMPAIGN_STAGE, "difficulty": model.difficulty,
   "theme": model.map_id, "seed": MATCH_SEED, "family": model.map_data.family,
   "viewport": [1280, 720], "buildings": room.buildings.size(), "room": room.index,
   "geometry_sha256": JSON.stringify(NightmareMap.pack(model.map_data), "", true, true).sha256_text(),
   "initial_sha256": before, "staged_siege": staged, "combat": active, "decisions": decisions, "checks": checks, "failures": failures,
  }
  receipt.store_string(JSON.stringify(data, "  ", true, true) + "\n")
 await _finish()
