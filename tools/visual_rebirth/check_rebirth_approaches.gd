extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func expect(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func run() -> void:
 var director := AudioDirector.new()
 root.add_child(director)
 var model := MatchModel.new()
 model.claim_room(1)
 model.player_position = model.player().bed_position()
 model.sleep_player()
 model.running = true
 model.hunter.state = HunterState.State.MOVE
 model.hunter.position = model.player().door_position() + Vector2(200, 0)
 for archetype in StrategyCatalog.ARCHETYPE_IDS:
  model.hunter.archetype = archetype
  var cue: String = AudioDirector.STALKER_BREATH if archetype == "stalker" else "cinematic_" + archetype + "_approach"
  director.new_encounter(model)
  OS.set_environment("NIGHTFALL_VISUAL_REBIRTH", "0")
  director.update_state(.016, model, "match")
  expect(director.event_counts.get(cue, 0) == 0, cue + " opt-out")
  OS.set_environment("NIGHTFALL_VISUAL_REBIRTH", "1")
  director.update_state(.016, model, "match")
  expect(director.event_counts.get(cue, 0) == 1, cue + " opt-in")
  var active_voice := false
  for voice in director.voices:
   if director._voice_names.get(voice.get_instance_id(), "") == cue:
    active_voice = voice.playing and voice.bus == "Effects" and voice.volume_db < -17.0
  expect(active_voice, cue + " playing and attenuated")
  director.update_state(.016, model, "match")
  expect(director.event_counts.get(cue, 0) == 1, cue + " cooldown")
 director.shutdown()
 await create_timer(.5).timeout
 director.queue_free()
 await create_timer(.1).timeout
 print("REBIRTH_APPROACH_CHECKS=", checks, " FAILURES=", failures)
 quit(1 if failures else 0)
