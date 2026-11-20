extends SceneTree
## Isolated profile migration, active Story entry, and real terminal transitions.

const BASE := "user://living-story-qa-"
const Support := preload("res://tests/replay_test_support.gd")
const ENDLESS_FIXTURE := "res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"
var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(condition: bool, description: String):
 checks += 1
 if condition:
  return
 failures += 1
 push_error(description)

func write(path: String, value: Dictionary) -> void:
 var file := FileAccess.open(path, FileAccess.WRITE)
 file.store_string(JSON.stringify(value, " "))
 file.close()

func read(path: String) -> Dictionary:
 var value = JSON.parse_string(FileAccess.get_file_as_string(path))
 return value if value is Dictionary else {}

func configure_terminal(model: MatchModel, won: bool) -> bool:
 if not model.claim_room(0):
  return false
 model.player_position = model.player().bed_position()
 if not model.sleep_player():
  return false
 model.time = model.preparation + 40.0
 model.bot_claimed = 5
 model.player().occupied_seconds = 40.0
 model.player().damage_dealt = 500.0
 model.hunter.state = HunterState.State.SEEK
 if won:
  # Low pre-existing HP isolates terminal bookkeeping while leaving the
  # regular damage, outcome finalization, and strategy seal in production.
  model.hunter.hp = 1.0
  model.apply_target_damage(1, 50.0, 0)
 else:
  model.hunter.target = 0
  model.hunter.position = model.player().bed_position()
  model.hunter.state = HunterState.State.BREACH
  model.player().door_hp = 0.0
  if not model.eliminate_resident(0):
   return false
 model.tick(.05)
 return model.terminal_recorded and model.result == ("victory" if won else "defeat")

func archive_win(profile: PlayerProfile, stage: String, difficulty: String) -> Dictionary:
 if profile.pending_stage_bonus.get("target") == stage and profile.pending_stage_bonus.get("choice") == "":
  if not profile.choose_stage_bonus("battle"):
   return {}
 var entry := profile.begin_match(difficulty, stage)
 if entry.is_empty():
  return {}
 var model := MatchModel.new()
 var configured: bool = model.configure_match(difficulty, RankCatalog.bonuses(entry.equipped)) and model.configure_stage(stage)
 if not configured or not configure_terminal(model, true):
  return {}
 return profile.settle_match(entry.id, model)

func discard_spins(profile: PlayerProfile):
 while not profile.pending_spins.is_empty():
  var match_id: int = profile.pending_spins.front().match_id
  if profile.claim_spin(match_id).is_empty():
   break

func story_model(entry: Dictionary, seed_override := -1) -> MatchModel:
 var model := MatchModel.new()
 model.procedural_v2_requested = true
 var seed_value: int = int(entry.story.seed) if seed_override < 0 else seed_override
 model.reset(seed_value)
 if not (model.configure_match(entry.difficulty, RankCatalog.bonuses(entry.equipped)) and model.configure_stage(entry.stage_id) and model.configure_balance()):
  return null
 model.story_level = int(entry.story.level)
 if not model.configure_strategy(seed_value, entry.archetype, entry.contract, int(entry.id)):
  return null
 return model

func story_entry(profile: PlayerProfile, mode: String, level: int) -> Dictionary:
 return profile.begin_match(mode, StoryCatalog.mission(level).stage_id, true, level)

func verify_migration():
 var path := BASE + "migration.json"
 var legacy := PlayerProfile.new(path)
 legacy.xp = 700
 legacy.rm_cash = 200
 legacy.tutorial_completed = true
 check(legacy.equip("dreamer") and legacy.buy_common("repair", 1), "old permanent perk and normal purchase saved")
 check(legacy.update_setting("music", .25) and legacy.update_setting("muted", true), "old audio preferences saved")
 var record_one := archive_win(legacy, "stage_1", "standard")
 var record_two := archive_win(legacy, "stage_2", "hard")
 check(record_one.get("campaign", {}).get("cleared", false) and record_two.get("campaign", {}).get("cleared", false),
  "legacy profile has two old Campaign records from production settlements")
 check(legacy.save_profile(), "old Campaign record generation writes")
 var before := read(path)
 before.erase("story")
 write(path, before)
 var source_hash := FileAccess.get_sha256(path)
 var migrated := PlayerProfile.new(path)
 check(migrated.load_profile(true) and not migrated.read_only and StoryProgress.valid(migrated.story), "healthy old profile migrates")
 var backup := path + ".before-story-v1.bak"
 check(FileAccess.file_exists(backup) and FileAccess.get_sha256(backup) == source_hash, "immutable backup exactly preserves old bytes")
 var serialized := read(path)
 for field in ["xp", "campaign", "progression", "consumables", "rewards", "onboarding", "settings", "replay", "strategy", "last_award", "next_match_id"]:
  check(serialized.get(field) == before.get(field), "Story migration preserves legacy " + field)
 check(StoryProgress.summary(migrated.story, "hell").highest == 0,
  "legacy Standard/Hard records establish no Hell advancement")
 check(migrated.story.rewards.has(1) and migrated.story.rewards.has(2), "first-clear credit recognizes historical rewards")
 check(migrated.update_setting("music", .35), "migrated profile persists a normal change")
 check(FileAccess.get_sha256(backup) == source_hash, "subsequent saves never rotate the pre-Story backup away")
 var restarted := PlayerProfile.new(path)
 check(restarted.load_profile() and Support.numeric_same(restarted.story, migrated.story), "legacy launcher preserves Story fields")
 var damaged := read(path)
 damaged.story.tracks.hell.position = 50
 write(path, damaged)
 var damaged_hash := FileAccess.get_sha256(path)
 var quarantine := PlayerProfile.new(path)
 check(quarantine.load_profile(true) and quarantine.read_only, "corrupt Story opens read-only without discarding permanent progress")
 check(quarantine.xp == migrated.xp and quarantine.inventory == migrated.inventory and quarantine.rm_cash == migrated.rm_cash, "damaged Story keeps XP, stock and RM in memory")
 check(not quarantine.save_profile() and FileAccess.get_sha256(path) == damaged_hash, "damaged Story remains unchanged on disk")

func verify_active_endless():
 var path := BASE + "endless.json"
 var checkpoint := read(ENDLESS_FIXTURE)
 var previous := ReplaySnapshot.restore(checkpoint)
 check(previous != null and previous.endless != null, "generated migration fixture starts from the archived earned Wave 45")
 if previous == null or previous.endless == null:
  return
 var p := PlayerProfile.new(path)
 p.xp = 700
 p.inventory = {"repair": 4}
 p.rm_cash = 65
 p.tutorial_completed = true
 var active := p.begin_endless(previous.map_id, previous.difficulty, previous.endless.seed_value)
 check(not active.is_empty(), "existing Endless session identity generated")
 if active.is_empty():
  return
 # Align the checked-in earned checkpoint's identity with its isolated copy;
 # room geometry, investments, puzzle state and completed waves stay intact.
 var raw := read(path)
 raw.erase("story")
 checkpoint.run_id = active.id
 raw.replay.checkpoint = checkpoint
 raw.replay.best_wave = previous.endless.completed
 write(path, raw)
 var migrated := PlayerProfile.new(path)
 check(migrated.load_profile(true) and not migrated.read_only, "profile with active Endless migrates")
 var restored = migrated.resume_endless()
 check(restored != null and restored.endless.completed == previous.endless.completed, "earned Wave 45 resumes after Story migration")
 if restored != null:
  check(restored.player().buildings == previous.player().buildings, "existing Endless machine investments survive unchanged")
 check(Support.numeric_same(migrated.active_match, active) and migrated.inventory == {"repair": 4} and migrated.rm_cash == 65, "Endless identity, inventory and RM survive")
 check(story_entry(migrated, "standard", 1).is_empty(), "Story refuses to replace an active Endless run")

func verify_transactions():
 var path := BASE + "transactions.json"
 var p := PlayerProfile.new(path)
 check(p.load_profile(true), "new isolated profile initializes Story")
 if p.story.is_empty():
  return
 var first := story_entry(p, "standard", 1)
 check(not first.is_empty(), "only the current mission issues a persistent ticket")
 if first.is_empty():
  return
 check(story_entry(p, "standard", 2).is_empty() and p.active_match == first, "locked match does not replace current ticket")
 var wrong_seed := story_model(first, int(first.story.seed) + 1)
 check(wrong_seed != null and configure_terminal(wrong_seed, true) and p.settle_match(first.id, wrong_seed).is_empty(), "forged seed cannot advance Story")
 var model := story_model(first)
 check(model != null and configure_terminal(model, false), "defeat enters the normal terminal model")
 if model == null:
  return
 var failed := p.settle_match(first.id, model)
 check(failed.get("story", {}).get("position") == 1, "losing Level 1 leaves position at 1")
 discard_spins(p)
 var retry := story_entry(p, "standard", 1)
 check(not retry.is_empty() and retry.story.seed == first.story.seed, "persisted retry reuses Story seed")
 if retry.is_empty():
  return
 var replay := story_model(retry)
 check(replay != null and NightmareMap.pack(replay.map_data) == NightmareMap.pack(model.map_data), "retry uses byte-equivalent packed map geometry")
 check(replay != null and configure_terminal(replay, true), "retry victory enters the normal terminal model")
 if replay == null:
  return
 var old_path: String = p.path
 var old_state := p.story.duplicate(true)
 var old_xp: int = p.xp
 p.path = "user://not-a-living-story-qa-directory/rejected.json"
 check(p.settle_match(retry.id, replay).is_empty() and p.story == old_state and p.xp == old_xp and p.active_match == retry,
  "disk failure rolls back Story state, permanent XP and active ticket")
 p.path = old_path
 var clear := p.settle_match(retry.id, replay)
 check(clear.get("story", {}).get("position") == 2 and clear.story.first_clear and clear.story.reward_xp > 0, "normal victory advances exactly one and pays first-clear XP")
 check(p.settle_match(retry.id, replay).is_empty(), "same settled model cannot award twice")
 discard_spins(p)
 var archive := archive_win(p, "stage_1", "hard")
 check(archive.get("campaign", {}).get("reward_xp") == 0, "Story clear fences off the same archive reward")
 discard_spins(p)
 var loaded := PlayerProfile.new(path)
 check(loaded.load_profile() and not loaded.read_only, "before changing difficulty the prior global reward is read from persisted JSON")
 p = loaded
 var hard := story_entry(p, "hard", 1)
 if hard.is_empty():
  check(false, "Hard track remains independently available")
  return
 var hard_model := story_model(hard)
 check(hard_model != null and configure_terminal(hard_model, true), "Hard uses its own genuine battle")
 if hard_model == null:
  return
 var hard_clear := p.settle_match(hard.id, hard_model)
 check(hard_clear.get("story", {}).get("position") == 2 and hard_clear.story.reward_xp == 0, "Hard advances independently with no duplicate first-clear XP")
 check(StoryProgress.summary(p.story, "hell").position == 1, "both victories leave Hell position at 1")

func finish_boss_fixture(model: MatchModel) -> bool:
 if not model.claim_room(0):
  return false
 var room := model.player()
 model.player_position = room.bed_position()
 if not model.sleep_player():
  return false
 # Stage resources and approach to verify the ending transition in isolation.
 # All damage thresholds, transformation, ultimate and terminal use real ticks.
 model.time = model.preparation + 40.0
 model.bot_claimed = 5
 room.occupied_seconds = 40.0
 room.door_level = 9
 room.door_hp = room.max_hp()
 var hunter := model.hunter
 hunter.state = HunterState.State.ATTACK
 hunter.target = 0
 hunter.position = room.door_approach()
 model.tick(.05)
 model.apply_target_damage(1, hunter.max_hp * 2.0, 0)
 for i in range(65):
  model.tick(.05)
 check(hunter.transformed, "Level 50 uses the actual Grim Reaper transformation")
 model.apply_target_damage(1, hunter.max_hp * 2.0, 0)
 for i in range(35):
  model.tick(.05)
 model.apply_target_damage(1, hunter.max_hp * 2.0, 0)
 for i in range(80):
  model.tick(.05)
 check(model.wrath.final_used, "Level 50 enters actual Crimson Execution")
 for i in range(90):
  if not model.result.is_empty():
   break
  model.apply_target_damage(1, hunter.max_hp * 2.0, 0)
  model.tick(.05)
 return model.result == "victory" and model.terminal_recorded and model.player().alive

func verify_game_and_finale():
 var path := BASE + "game.json"
 OS.set_environment("NIGHTFALL_PROFILE_PATH", path)
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE", "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS_V2", "1")
 var p := PlayerProfile.new(path)
 check(p.load_profile(true) and p.complete_tutorial(), "preview starts from an isolated game profile")
 var next_id: int = p.next_match_id
 # Simulate previous valid Story records without replaying 49 complete matches.
 for level in range(1, 50):
  var row := StoryProgress.settle(p.story, "standard", level, true, next_id)
  if row.is_empty():
   check(false, "prepared Level 49 record accepted")
   return
  next_id += 1
 p.next_match_id = next_id
 check(p.save_profile(), "prepared Level 49 state is saved through valid codec")
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 if game.model == null:
  check(false, "preview scene initializes its match model")
  game.queue_free()
  await process_frame
  return
 check(game.ui.menu_start.text == "CONTINUE STORY", "preview has one primary Continue Story entry")
 game.ui.campaign.show_story()
 check(game.ui.current_screen == "story_prepare", "Continue Story opens preparation first")
 check(game.ui.panel.get_node_or_null("StartStoryMission") is Button, "preparation contains a functioning Start Mission button")
 check(game.start_story("standard") and game.model.story_level == 50, "real Game start_story resumes exact final Story level")
 if game.model.story_level == 50:
  var data := StoryCatalog.mission(50)
  check(game.model.stage_id == data.stage_id and game.model.hunter.archetype == data.archetype,
   "real Game launches the authoritative final mission configuration")
  check(game.model.map_seed == StoryProgress.seed_for(game.profile.story, 50), "Game uses the persistent final mission seed")
  check(game.model.map_data.get("family") == data.topology, "Game loads the authored final route family")
  check(finish_boss_fixture(game.model), "prepared boss fixture can earn a genuine Stage 50 terminal victory")
  if game.model.result == "victory":
   game._process(.01)
   await process_frame
   check(game.last_progression.get("story", {}).get("finished", false), "real game settles and shows completed Story state")
   check(game.profile.story.tracks.standard.highest == 50 and game.profile.story.tracks.standard.position == 50,
    "completion preserves capped position and highest record")
   check(game.mode == "result", "completed finale uses normal result presentation")
   check(not game.start_story("standard"), "completed Story cannot launch Level 51 or replay the first reward")
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame

func run():
 verify_migration()
 verify_active_endless()
 verify_transactions()
 await verify_game_and_finale()
 print("LIVING_STORY_INTEGRATION_CHECKS=%d FAILURES=%d" % [checks, failures])
 quit(int(failures != 0))
