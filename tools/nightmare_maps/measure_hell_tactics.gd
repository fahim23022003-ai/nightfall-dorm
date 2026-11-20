extends "res://tools/nightmare_maps/measure_nightmare_maps_v2.gd"
## Paired baseline and candidate measurement from the same Hell Campaign state.

const CAMPAIGN_STAGE := "stage_5"
const MATCH_SEED := 73
const ACTIVE_SAMPLES := 150

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
 model.hard_tactics_enabled = policy == "candidate"
 check(model.uses_tactical_sieges() == (policy == "candidate"), "control the tactics comparison switch")
 if failures > 0:
  await _finish()
  return
 game._adopt_session(model)
 var room := make_room_fixture(model)
 if room == null or failures > 0:
  await _finish()
  return
 var hunter := model.hunter
 model.time = model.preparation + 10.0
 model.bot_claimed = 5
 for ally: RoomState in model.rooms:
  if ally == room:
   continue
  ally.owner = ally.index + 1
  ally.profile = Catalog.BOT_PROFILES[ally.index % Catalog.BOT_PROFILES.size()]
  ally.resident_position = ally.bed_position()
  ally.sleeping = true
  ally.closed = true
 hunter.state = HunterState.State.ATTACK
 hunter.position = room.door_approach()
 hunter.target = room.index
 hunter.cooldown = .5
 # Start mid-siege so already earned progress can cross the ordinary
 # reassessment timing during a bounded, still-active window.
 hunter.siege_start_hp = room.max_hp()
 room.door_hp -= room.max_hp() * .15
 var reassess_at := maxf(RankCatalog.pressure(model.difficulty).commit * StrategyCatalog.ARCHETYPES[hunter.archetype].commit, Catalog.HUNTER_ESCALATION.minimum_commitment)
 hunter.target_time = reassess_at - 2.5
 hunter.siege_seconds = hunter.target_time
 hunter.reassess_seconds = hunter.target_time
 game.full_map = false
 game.focus_camera(true)
 await _render_frame()
 check(root.size == Vector2i(1280, 720), "real 1280×720 viewport")
 var before := _state_digest(model)
 var active := await measure_active_siege(model)
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
   "initial_sha256": before, "combat": active, "checks": checks, "failures": failures
  }
  receipt.store_string(JSON.stringify(data, "  ", true, true) + "\n")
 await _finish()

func measure_active_siege(model: MatchModel) -> Dictionary:
 var hunter := model.hunter
 var start_hp: float
 var start_shots: int
 var start_attacks: int
 var start_retargets: int
 var end_warmup_hash: String
 var frames := []
 var updates := []
 var draws := []
 var events := {}
 var states := {}
 for index in range(TIMING_WARMUP + ACTIVE_SAMPLES):
  if index == TIMING_WARMUP:
   start_hp = hunter.hp
   start_shots = model.shots
   start_attacks = hunter.attacks
   start_retargets = hunter.retargets
   end_warmup_hash = _state_digest(model)
  var started := Time.get_ticks_usec()
  game._process(COMBAT_STEP)
  var updated := Time.get_ticks_usec()
  await _render_frame()
  if index < TIMING_WARMUP:
   continue
  frames.append((Time.get_ticks_usec() - started) / 1000.0)
  updates.append((updated - started) / 1000.0)
  draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
  var state := HunterState.State.keys()[hunter.state] as String
  states[state] = int(states.get(state, 0)) + 1
  for event: Dictionary in model.presentation_events:
   if not events.has(event.id):
    events[event.id] = [event.type, event.get("reason", "")]
 var counts := {}
 var tactical_switches := 0
 for entry: Array in events.values():
  var type: String = entry[0]
  counts[type] = int(counts.get(type, 0)) + 1
  tactical_switches += int(type == "hunter_reassess" and entry[1] == "better_breach_route")
 check(model.result.is_empty(), "combat remains active throughout the benchmark")
 check(hunter.attacks > start_attacks and model.shots > start_shots and hunter.hp < start_hp, "real strikes, shots and damage")
 return {
  "frame_ms": summarized(frames), "update_ms": summarized(updates), "draw_calls": summarized(draws),
  "wall_samples_ms": frames, "cpu_samples_ms": updates, "warmup_frames": TIMING_WARMUP,
  "sample_frames": ACTIVE_SAMPLES, "sample_seconds": ACTIVE_SAMPLES * COMBAT_STEP,
  "warmup_sha256": end_warmup_hash, "final_sha256": _state_digest(model),
  "strikes": hunter.attacks - start_attacks, "shots": model.shots - start_shots,
  "retargets": hunter.retargets - start_retargets, "hp_lost": start_hp - hunter.hp,
  "states": states, "event_counts": counts, "tactical_switches": tactical_switches
 }
