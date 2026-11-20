extends SceneTree
## Launch the offline Story lobby through the real preparation button.

const PROFILE := "user://qa-survivor-lobby.json"
const STEP := 0.05
var game
var checks := 0
var failures := 0
var destination := ""
var measurements := {}
var first_map: Dictionary = {}
var first_spawn := Vector2.INF

func _initialize():
 call_deferred("run")

func check(condition: bool, label: String):
 checks += 1
 if not condition:
  failures += 1
  push_error(label)

func expect_button(name: String, within: Node) -> Button:
 var button := within.find_child(name, true, false) as Button
 check(button != null and button.is_visible_in_tree() and not button.disabled, "usable actual " + name + " button")
 return button

func press(name: String, within: Node):
 var button := expect_button(name, within)
 if button != null:
  await click(button)

func click(button: Button):
 if DisplayServer.get_name() == "headless":
  button.pressed.emit()
  await process_frame
  return
 var point := root.get_final_transform() * button.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 for down: bool in [true,false]:
  var event := InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func snapshot() -> Dictionary:
 var model: MatchModel = game.model
 var profile: PlayerProfile = game.profile
 var occupancy := []
 for room in model.rooms:
  occupancy.append([room.owner, room.sleeping, room.closed, room.gold, room.electricity])
 return {
  "model_id": model.get_instance_id(), "time": model.time, "room": model.player_room, "occupancy": occupancy,
  "profile": profile._reward_snapshot(), "cash": profile.rm_cash,
  "story": profile.story.duplicate(true), "difficulty": profile.selected_difficulty,
  "stock": profile.inventory.duplicate(true), "items": profile.item_loadout.duplicate(), "perks": profile.equipped.duplicate(),
  "match_serial": profile.next_match_id, "file_sha": FileAccess.get_sha256(profile.path),
 }

func image(label: String, expected: Vector2i):
 if DisplayServer.get_name() == "headless":
  return
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var shot := root.get_texture().get_image()
 check(shot.get_size() == expected, "native raster dimensions at " + label)
 if not destination.is_empty():
  check(shot.save_png(destination.path_join(label + ".png")) == OK, "save native " + label + " still")

func open_prepared_lobby():
 await press("StartStoryMission", game.ui.panel)
 var lobby = game.story_lobby
 check(is_instance_valid(lobby) and game.mode == "story_lobby" and game.ui.current_screen == "story_lobby", "wired Start Match opens the offline Story lobby")
 if not is_instance_valid(lobby):
  return null
 # The initial frame arms the control. Afterwards a deterministic clock
 # isolates 15.00 seconds from OS focus and scheduling jitter.
 for frame in range(12):
  if lobby.armed:
   break
  await process_frame
 check(lobby.armed, "actual lobby view arms after first presented frame")
 lobby.set_process(false)
 if not lobby.window_focused:
  lobby._focus_entered()
 lobby.set_suspended(false)
 check(game.audio_system.lobby_active, "host activates the actual lobby audio bus context")
 var roster: Array = lobby.roster()
 check(roster.size() == 6 and roster.filter(func(row): return row.human).size() == 1, "exactly one human and five AI survivor entries")
 check(roster.filter(func(row):return not row.human).size() == 5, "no seventh participant")
 return lobby

func advance(lobby: Control, seconds: float):
 var left := seconds
 while left > 0.00001:
  var frame_step := minf(left, .10)
  lobby.advance(frame_step)
  # The normal Game callback must keep the original model frozen in lobby.
  game._process(frame_step)
  left -= frame_step

func check_fit(lobby: Control, expected: Vector2i):
 var canvas_rect := Rect2(Vector2.ZERO, Vector2(expected)).grow(2.0)
 var transform := root.get_final_transform()
 for name in ["LobbyReady", "LobbyBack"]:
  var button := lobby.find_child(name,true,false) as Button
  check(button != null, "resized action remains present: " + name)
  if button != null:
   var rect := button.get_global_rect()
   var raster := Rect2(transform * rect.position, rect.size * transform.get_scale())
   check(canvas_rect.encloses(raster) and raster.size.x >= 80.0 and raster.size.y >= 32.0, "resized action is usable and fully inside canvas: " + name)

func cancel_probe():
 var before := snapshot()
 var lobby = await open_prepared_lobby()
 if lobby == null:
  return
 await image("01-offline-lobby-1280",Vector2i(1280,720))
 check_fit(lobby, Vector2i(1280,720))
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(960,540)
  await image("02-offline-lobby-960",Vector2i(960,540))
  check_fit(lobby, Vector2i(960,540))
  root.size = Vector2i(1280,720)
  await process_frame
 await press("LobbyReady",lobby)
 check(lobby.human_ready and lobby.ready_ai_count() < 5 and not lobby.loading, "early button marks only the human Ready while AIs are still joining")
 advance(lobby, 2.4)
 check(game.audio_system._mode == "lobby", "waiting routes through actual lobby audio rather than the match")
 check(snapshot() == before, "waiting cannot tick the match, assign rooms, spend currency or save profile changes")
 var elapsed: float = lobby.elapsed
 lobby.set_suspended(true)
 advance(lobby, 3.0)
 check(lobby.elapsed == elapsed and snapshot() == before, "suspension freezes lobby and match time")
 lobby.set_suspended(false)
 await press("LobbyBack",lobby)
 check(game.mode == "menu" and game.ui.current_screen == "story_prepare" and game.story_lobby == null, "back returns to the matching Story preparation")
 check(not game.audio_system.lobby_active, "back clears the lobby audio context")
 check(snapshot() == before, "cancel leaves match ID, profile bytes, difficulty, loadout and occupants unchanged")
 measurements.cancel = {"elapsed": elapsed, "profile_bytes_unchanged": snapshot() == before}

func cancel_loading_probe():
 var before := snapshot()
 var lobby = await open_prepared_lobby()
 if lobby == null:
  return
 advance(lobby, 7.0)
 check(lobby.ready_ai_count() == 5, "all five AI are ready for back-during-loading test")
 await press("LobbyReady",lobby)
 check(lobby.loading, "ready team begins the actual transition")
 advance(lobby,.21)
 await press("LobbyBack",lobby)
 await process_frame
 check(game.story_lobby == null and game.ui.current_screen == "story_prepare" and snapshot() == before, "cancel mid-transition neither creates a match ticket nor changes wallet, rooms or loadout")
 measurements.cancel_loading = {"profile_bytes_unchanged":snapshot()==before}

func check_started(before: Dictionary, label: String):
 check(game.mode == "match" and game.story_lobby == null, label + " enters the actual game")
 check(not game.audio_system.lobby_active, label + " releases the lobby mix")
 var after := snapshot()
 check(after.match_serial == before.match_serial + 1, label + " emits exactly one match ticket")
 check(after.cash == before.cash and after.stock == before.stock, label + " reserves no item stock or wallet charge before combat")
 check(game.profile.active_match.get("items") == before.items and game.profile.active_match.get("equipped") == before.perks, label + " carries selected items and perks")
 check(game.model.difficulty == before.difficulty and game.model.story_level == StoryProgress.position(before.story,before.difficulty), label + " carries the prepared Story and difficulty")
 check(game.model.time == 0.0 and game.model.player_room < 0 and game.model.rooms.all(func(room): return room.owner < 0), label + " begins at ordinary tick-zero room state")

func early_probe():
 var before := snapshot()
 var lobby = await open_prepared_lobby()
 if lobby == null:
  return
 advance(lobby, 10.75)
 check(lobby.ready_ai_count() == 5 and lobby.seconds_left() > 0, "all five AI ready before countdown expires")
 check(snapshot() == before, "AI lobby readiness creates no rooms, income, or match progression")
 var ready_elapsed: float = lobby.elapsed
 var cues_before: int = game.audio_system.lobby_cue_counts.get("ready",0)
 await press("LobbyReady",lobby)
 var cues_after: int = game.audio_system.lobby_cue_counts.get("ready",0)
 lobby.press_ready()
 check(game.audio_system.lobby_cue_counts.get("ready",0) == cues_after,"repeated Ready cannot play another cue")
 # The headless fixture steps several seconds inside one frame. Deferred
 # audio voices can still be busy while their simulated clock has advanced.
 if DisplayServer.get_name()!="headless":
  check(cues_after == cues_before + 1,"the deliberate Ready plays one cue in a graphical session")
 check(lobby.loading and game.mode == "story_lobby", "actual Ready button enters the loading transition")
 await image("03-ready-loading",Vector2i(1280,720))
 advance(lobby,.41)
 check(game.mode == "story_lobby" and snapshot() == before, "loading holds prepared values until transition ends")
 advance(lobby,.02)
 await process_frame
 await process_frame
 check_started(before, "early launch")
 measurements.early = {"seconds":ready_elapsed,"initial_time":game.model.time,"serial_increment":game.profile.next_match_id-before.match_serial}
 if game.mode == "match":
  first_map=NightmareMap.pack(game.model.map_data)
  first_spawn=game.model.player_position
  await walk_probe()

func timeout_probe():
 game.return_menu()
 game.ui.campaign.show_story()
 await process_frame
 var before := snapshot()
 var lobby = await open_prepared_lobby()
 if lobby == null:
  return
 # Reset the small amount of elapsed real time while the first frame arms.
 lobby.elapsed = 0.0
 advance(lobby,14.99)
 check(game.mode == "story_lobby" and not lobby.loading, "no Ready action waits through 14.99 seconds")
 check(snapshot() == before, "countdown controls neither save nor tick the active game")
 advance(lobby,.01)
 check(lobby.elapsed == 15.0 and lobby.loading and game.mode=="story_lobby", "15.0 seconds auto-readies the offline lobby")
 advance(lobby,.43)
 await process_frame
 await process_frame
 check_started(before, "timeout launch")
 measurements.timeout = {"ready_at":15.0,"initial_time":game.model.time,"serial_increment":game.profile.next_match_id-before.match_serial}
 if not first_map.is_empty():
  check(NightmareMap.pack(game.model.map_data) == first_map, "retry keeps the same seeded map")
  check(game.model.player_position != first_spawn and RoomRush.exterior(game.model, game.model.player_position), "retry receives a different lawful corridor spawn")

func walk_probe():
 var model: MatchModel = game.model
 var spawn: Vector2 = model.player_position
 check(model.room_rush_active() and model.room_rush_spawn() == spawn and RoomRush.exterior(model,spawn), "actual Story launch activates exterior room rush")
 var runners: Array = model.room_rush_runners()
 check(runners.size() == 5 and runners.all(func(runner):return runner.position == spawn), "exactly five physical AIs co-spawn with the player")
 check(not model.claim_room(0), "room rush guards direct claims from outside")
 await image("04-exterior-spawn",Vector2i(1280,720))
 interact_key()

 check(model.player_room < 0 and model.rooms.all(func(room):return room.owner < 0), "interact at outdoor spawn cannot claim a room remotely")
 var best_room: RoomState
 var best_route: Array = []
 var shortest := INF
 for room: RoomState in model.rooms:
  var inside: Vector2 = room.door_position() - room.door_normal() * 35.0
  var route := model.player_navigation_path(spawn,inside)
  if route.is_empty() or not Vector2(route.back()).is_equal_approx(inside):
   continue
  var length := 0.0
  var previous := spawn
  for waypoint: Vector2 in route:
   length += previous.distance_to(waypoint)
   previous = waypoint
  if length < shortest:
   shortest = length
   best_room = room
   best_route = route
 check(best_room != null and shortest > 3.0, "real spawn has a reachable physical room route")
 if best_room == null:
  return
 var initial: float = model.time
 var max_step := 0.0
 var max_bot_step := 0.0
 var legal_egress := true
 for waypoint: Vector2 in best_route:
  var moved := false
  for index in range(270):
   var old: Vector2 = model.player_position
   if old.distance_to(waypoint) <= 1.0:
    moved = true
    break
   var previous_bots := {}
   for runner: Dictionary in model.room_rush_runners():
    previous_bots[runner.owner] = runner.position
   model.move_player((waypoint - old)/(model.SURVIVOR_SPEED*STEP), STEP)
   model.tick(STEP)
   for runner: Dictionary in model.room_rush_runners():
    var last: Vector2 = previous_bots.get(runner.owner, runner.position)
    max_bot_step = maxf(max_bot_step,last.distance_to(runner.position))
    legal_egress=legal_egress and model.can_walk(runner.position,model.room_rush.egress_room(model,runner.position))
   max_step = maxf(max_step, old.distance_to(model.player_position))
  check(moved, "move_player reaches each route waypoint through production collision")
  if not moved:
   return
 check(best_room.floor_has_point(model.player_position) and model.can_walk(model.player_position), "no teleport, player position reaches legal room floor")
 interact_key()
 check(model.player() == best_room and best_room.owner == 0, "physical arrival plus E permits local room claim")
 check(max_step <= model.SURVIVOR_SPEED*STEP+.01 and max_bot_step > 0.0 and max_bot_step <= model.SURVIVOR_SPEED*.5*STEP+.01 and legal_egress,
       "physical runner movement stays walkable and at most half player speed")
 measurements.walk = {"spawn":[spawn.x,spawn.y],"room":best_room.index,"distance":shortest,"claim_seconds":model.time-initial,
                      "max_player_speed":max_step/STEP,"max_bot_speed":max_bot_step/STEP}
 game.focus_camera(true)
 await image("05-claimed-room",Vector2i(1280,720))
 if model.player() == best_room:
  await sleep_probe(model,best_room)

func sleep_probe(model: MatchModel, room: RoomState):
 var before: float = room.gold
 var route: Array = []
 for direction: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
  var at: Vector2 = room.bed_position()+direction*54.0
  if not room.floor_has_point(at) or not model.can_walk(at):
   continue
  var candidate := model.player_navigation_path(model.player_position,at)
  if not candidate.is_empty() and Vector2(candidate.back()).is_equal_approx(at):
   route=candidate
   break
 check(not route.is_empty(), "own bed is reachable inside real room")
 if route.is_empty():
  return
 for waypoint: Vector2 in route:
  for index in range(240):
   var old: Vector2 = model.player_position
   if old.distance_to(waypoint) <= 1.0:
    break
   model.move_player((waypoint-old)/(model.SURVIVOR_SPEED*STEP),STEP)
   model.tick(STEP)
  check(model.player_position.distance_to(waypoint) <= 1.0, "same legal walking commands reach bed waypoint")
 check(room.gold == before and not room.sleeping and room.income_total == 0.0, "claimed room produces no gold until sleep")
 interact_key()
 check(room.sleeping and room.closed, "E at the bed locks the owned room")
 model.tick(.2)
 check(room.gold > before and room.income_total > 0.0, "real bed starts normal gold production")
 measurements.walk.merge({"slept_at":model.time-.2,"income_after_tick":room.gold-before})
 game.focus_camera(true)
 await image("06-sleep-and-income",Vector2i(1280,720))

func interact_key():
 var event := InputEventKey.new()
 event.keycode=KEY_E
 event.physical_keycode=KEY_E
 event.pressed=true
 game._unhandled_input(event)

func run():
 var args := OS.get_cmdline_user_args()
 if not args.is_empty():
  destination = args[0]
  DirAccess.make_dir_recursive_absolute(destination)
 for suffix in ["",".bak",".tmp",".before-story-v1.bak"]:
  if FileAccess.file_exists(PROFILE+suffix):
   DirAccess.remove_absolute(PROFILE+suffix)
 OS.set_environment("NIGHTFALL_PROFILE_PATH",PROFILE)
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS_V2","1")
 OS.set_environment("NIGHTFALL_VISUAL_REBIRTH","1")
 root.size = Vector2i(1280,720)
 var profile := PlayerProfile.new(PROFILE)
 check(profile.load_profile(true), "isolated Story test profile starts")
 profile.story = StoryProgress.fresh(32157)
 profile.xp = 700
 profile.rm_cash = 100
 profile.tutorial_completed = true
 check(profile.equip("dreamer") and profile.buy_common("repair",1) and profile.equip_item("repair"), "prepare legitimate saved item/perk")
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.close_welcome()
 await click(game.ui.menu_start)
 check(game.ui.current_screen == "story_prepare", "actual menu button opens Story preparation")
 await press("StoryDifficulty_hard", game.ui.panel)
 check(game.profile.selected_difficulty == "hard", "real preparation selects Long Night track")
 await cancel_probe()
 if game.mode == "menu":
  await cancel_loading_probe()
 if game.mode == "menu":
  await early_probe()
 await timeout_probe()
 if not destination.is_empty():
  var report := FileAccess.open(destination.path_join("integration.json"),FileAccess.WRITE)
  if report != null:
   report.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "measurements":measurements,"checks":checks,"failures":failures}, "  ")+"\n")
   report.close()
 game.audio_system.shutdown()
 await create_timer(.35).timeout
 game.queue_free()
 await process_frame
 print("SURVIVOR_LOBBY_INTEGRATION_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures != 0))
