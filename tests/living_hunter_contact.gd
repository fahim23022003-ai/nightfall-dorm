extends SceneTree
## Real model hits, provenance and scoped visual contact routing.

var assertions := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(condition: bool, statement: String):
 assertions += 1
 if not condition:
  failures += 1
  push_error(statement)

func fixture(archetype: String) -> MatchModel:
 var model := MatchModel.new()
 model.procedural_v2_requested = true
 model.reset(10358)
 model.configure_match("hard")
 model.configure_stage("stage_2")
 model.configure_strategy(10358,archetype)
 model.configure_balance()
 model.claim_room(1)
 var room := model.player()
 model.player_position = room.bed_position()
 model.sleep_player()
 model.time = model.preparation + 10.0
 model.hunter.target = room.index
 model.hunter.state = HunterState.State.ATTACK
 model.hunter.position = room.door_approach()
 return model

func run():
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 var visual := HunterCombatVisual.new()
 check(visual.enabled,"the Living Nightmare opt-in activates contact effects")
 for archetype: String in HunterCombatVisual.ARCHETYPE_STYLES:
  var model := fixture(archetype)
  var room := model.player()
  check(model.hunter.archetype == archetype,"the normal strategy configured its Hunter")
  var origin: Vector2 = model.hunter.position
  var hp: float = room.door_hp
  check(model.apply_room_damage(room.index,16.0) > 0.0 and room.door_hp < hp,"the real door took a landed strike")
  visual.observe(model)
  var contact := visual.latest_body_contact(model)
  check(contact.get("style") == HunterCombatVisual.ARCHETYPE_STYLES[archetype],"archetype gets its contact style")
  check(contact.get("origin") == origin and contact.get("age") == 0.0 and contact.get("room") == room.index,"contact keeps the exact origin, room and event time")
  check(contact.get("point") == HunterCombatVisual.door_socket(room),"body and impact share a door socket")
  var expected_material := "wood" if archetype in ["crusher","stalker","ravager"] else ""
  check(contact.get("material") == expected_material,"wood fragments are only for a suitable physical strike")
  check((visual.door_kick(model,room.index).length() > 0.0) == (archetype == "crusher"),"only heavy impact moves this door face")
  model.time += HunterCombatVisual.IMPACT_AGE + .01
  visual.observe(model)
  check(visual.latest_body_contact(model).is_empty(),"contact expires")
 var ravager := fixture("ravager")
 var defended := ravager.player()
 defended.barrier_remaining = 10.0
 defended.barrier_hp = 200.0
 check(ravager.apply_room_damage(defended.index,25.0) == 0.0,"barrier absorbs the whole live attack")
 visual.observe(ravager)
 check(visual.latest_body_contact(ravager).is_empty() and visual._contacts.is_empty() and visual._marks.is_empty(),"blocked hit leaves no Hunter contact or material damage")
 ravager.hunter.position = defended.door_approach() + defended.door_normal() * 40.0
 defended.barrier_remaining = 0.0
 check(ravager.apply_room_damage(defended.index,25.0) == 0.0,"out-of-range melee is rejected")
 visual.observe(ravager)
 check(visual.latest_body_contact(ravager).is_empty() and visual._contacts.is_empty(),"no synthetic contact after a failed attack")
 var reaper := fixture("crusher")
 reaper.hunter.transformed = true
 var door := reaper.player()
 door.door_level = 4
 door.door_hp = door.max_hp()
 check(reaper.apply_room_damage(door.index,80.0,"scythe",1,true) > 0.0,"boss strike reaches the model door")
 visual.observe(reaper)
 var contact := visual.latest_body_contact(reaper)
 check(contact.get("boss") and contact.get("style") == "scythe" and contact.get("material") == "iron","reinforced door receives iron sparks and scythe contact")
 check(visual._marks.has(door.index),"physical impact remembers its scoped door mark")
 reaper.record_event("door_upgrade",door.index)
 visual.observe(reaper)
 check(visual._marks.is_empty(),"replacing a door clears its old marks")
 reaper.time += 1.0
 reaper.apply_room_damage(door.index,30.0,"Embedded Scythe",1,true)
 visual.observe(reaper)
 check(visual._contacts.size() == 1 and visual.latest_body_contact(reaper).is_empty(),"the embedded weapon pulses without triggering a rig swing")
 var ghost := fixture("electric")
 var ghost_door := ghost.player()
 ghost.apply_room_damage(ghost_door.index,16.0,"interference",1,true,DamageRules.source("interference"))
 visual.observe(ghost)
 check(visual._contacts.size() == 1 and visual._contacts[0].style == "electric" and visual.latest_body_contact(ghost).is_empty(),"non-melee ability uses its element and never moves a melee rig")
 for attempt in range(HunterCombatVisual.MAX_CONTACTS + 7):
  ghost.apply_room_damage(ghost_door.index,1.0,"interference",1,true,DamageRules.source("interference"))
 visual.observe(ghost)
 check(visual._contacts.size() == HunterCombatVisual.MAX_CONTACTS,"busy contacts stay bounded at constant match density")
 visual.new_encounter()
 visual.observe(ghost)
 check(visual._contacts.is_empty(),"wave handoff drops old transients without replaying the event queue")
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","0")
 var fallback := HunterCombatVisual.new()
 ghost.apply_room_damage(ghost_door.index,10.0)
 fallback.observe(ghost)
 check(not fallback.enabled and fallback.latest_body_contact(ghost).is_empty() and fallback._contacts.is_empty(),"fallback does not consume any new contact effects")
 print("LIVING_HUNTER_CONTACT_CHECKS=",assertions," FAILURES=",failures)
 quit(int(failures > 0))
