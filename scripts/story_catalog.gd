class_name StoryCatalog
extends RefCounted

const FINAL_LEVEL := 50
const CHAPTER_LENGTH := 5
const CHAPTERS := [
 ["The First Night", "A dorm key opens five places on the night roster. Follow the names before they disappear."],
 ["The Rooms Remember", "The names have vanished from the roster. Their footsteps continue through the ward."],
 ["Hunted", "A watcher has marked the survivors' doors. Follow its route to the first Haunted Hall."],
 ["Unquiet Rooms", "The footsteps belong to patients who never left. Something has learned how to speak with their voices."],
 ["The Truth Beneath", "The night bell was part of an experiment. Recover the surviving records from the places it joined."],
 ["Haunted Paths", "The experiment folded the buildings around four Halls. The records show how to follow the paths back."],
 ["The Curse Evolves", "The first voice on the recordings is yours. It describes what happens when a Hunter reaches the red door."],
 ["The Reaper's Bargain", "The Reaper traded away the residents' dawn. Every door it breaks extends the bargain."],
 ["No Dawn", "The bargain binds the dorm, ward, hotel, laboratory and manor together. The bell is counting the last night."],
 ["The Final Night", "Hold the final lock while the manor's bell unwinds. Let the living see dawn again."],
]
const ENDING := "The bell rings once in the daylight. On the roster, every empty room has a name again."

# Planned route families are part of the level design. Story seeds are
# selected through the existing generator for these themes; geometry
# remains its ordinary six-room, four-Hall procedural output.
const ROUTE_FAMILIES := [
 ["ring","spine","branching","twin_wings","courtyards"],
 ["zigzag","branching","twin_wings","spine","radial"],
 ["scattered","zigzag","hybrid","radial","labyrinth"],
 ["spine","branching","scattered","labyrinth","courtyards"],
 ["twin_wings","spine","radial","hybrid","courtyards"],
 ["courtyards","zigzag","spine","twin_wings","radial"],
 ["ring","labyrinth","branching","hybrid","courtyards"],
 ["radial","scattered","spine","twin_wings","labyrinth"],
 ["ring","zigzag","branching","hybrid","courtyards"],
 ["spine","twin_wings","radial","labyrinth","hybrid"],
]

# Each row selects an existing map/encounter baseline, a specific Hunter and a
# mission clue. The original five Campaign entries remain separately replayable.
const MISSIONS := [
 ["The Haunted Dorm", 1, "crusher", "The night roster has a room number beside your name."],
 ["Whispers in the Ward", 2, "stalker", "A patient whispers your room number from an empty corridor."],
 ["Room Thirteen", 3, "ravager", "The hotel has no thirteenth floor. The key still fits."],
 ["Blackout Protocol", 4, "electric", "A backup generator powers a countdown nobody started."],
 ["The Cursed Manor", 5, "witch", "The manor keeps a second copy of the roster, written in ash."],
 ["Return to Darkness", 1, "stalker", "The dorm lights return. Your name has moved to an occupied room."],
 ["The Forgotten Wing", 2, "witch", "Behind a plaster wall, a ward still has fresh flowers at every bed."],
 ["Footsteps Behind the Wall", 3, "ravager", "One guest has checked in to both sides of the same wall."],
 ["Hallway of the Missing", 2, "electric", "Emergency receivers play the missing patients' final calls."],
 ["The Night Bell", 5, "storm", "The bell rings before the storm. Each ringing crosses out another name."],
 ["No Safe Door", 1, "ravager", "Every dorm lock bears the same fresh claw marks."],
 ["Blood on the Staircase", 3, "crusher", "Tracks on the stairs end at an intact door."],
 ["The Watcher's Window", 4, "electric", "The observation glass reflects a corridor outside the building."],
 ["The West Haunted Hall", 2, "storm", "An orderly's note describes a bell in the west and a Hunter that returns from it whole."],
 ["The Uninvited", 5, "stalker", "A guest arrives at midnight wearing one of the missing names."],
 ["The Weeping Corridor", 2, "witch", "When the corridor falls quiet, its floor is wet."],
 ["Voices Under the Floor", 4, "electric", "The lab intercom repeats a conversation still taking place above it."],
 ["The Empty Bed", 1, "crusher", "Someone has made up a bed for the resident who never came home."],
 ["The Vanishing Door", 3, "stalker", "The hotel floor plan gains a room each time you look away."],
 ["Last Light Out", 5, "ravager", "The last lit window closes on a hand reaching from the inside."],
 ["Fractured Records", 4, "electric", "Half the experiment log was filed before the experiment began."],
 ["The Patient Without a Name", 2, "witch", "The first patient has a discharge date but no birth date."],
 ["Elevator to Nowhere", 3, "storm", "The elevator opens on the corridor printed at the back of the log."],
 ["The Severed Circuit", 4, "stalker", "Cut power to the recorder and the voices get clearer."],
 ["The Buried Experiment", 5, "crusher", "The lab's first apparatus still hums under the manor."],
 ["The Broken Courtyard", 1, "storm", "Rain falls upward where the courtyard broke."],
 ["Paths That Shift", 3, "ravager", "A route marked safe last night loops back through the front desk."],
 ["The Endless Hall", 2, "crusher", "One corridor has no far wall, only doors facing each other."],
 ["Echoes of the Lost", 4, "electric", "Four distant transmitters echo the same patient record."],
 ["Four Halls of Mourning", 5, "witch", "The four Halls were built to hold the people the experiment took."],
 ["The Sleepless Floor", 1, "ravager", "The people in the beds have not blinked since the bell began."],
 ["Shadows Learn Your Name", 3, "stalker", "A guest signature appears each time you close your eyes."],
 ["The Hollow Oath", 2, "witch", "An orderly signed the ward away, then kept working as though nothing had changed."],
 ["The Hunter's Return", 4, "electric", "The test subject returns without the restraints in the old footage."],
 ["The Crimson Warning", 5, "storm", "A red wax seal warns that the final lock must stay closed."],
 ["The Funeral Bell", 2, "witch", "The bell carries one voice singing the names it has collected."],
 ["The Last Survivor", 1, "crusher", "The next signature will close the last line in the roster."],
 ["Ten Dead at the Door", 3, "ravager", "The ledger counts ten bodies. A new hand is making an eleventh mark."],
 ["The Scythe in the Dark", 4, "stalker", "The observation window shows a blade moving before its wielder."],
 ["The Red Domain", 5, "electric", "The walls ring like a struck bell when the seal turns red."],
 ["The Walls Are Alive", 1, "witch", "All five buildings breathe in time with the floor under the dorm."],
 ["The Door That Breathes", 2, "crusher", "The ward's sealed exit inhales the moment the bell goes quiet."],
 ["Night Without End", 3, "storm", "The hotel clocks all return to midnight before the hour can turn."],
 ["The Blood Moon Ward", 4, "electric", "The lab's emergency lights trace the last unbroken line of the seal."],
 ["The Reaper Awakens", 5, "ravager", "The Reaper rises where the Halls meet, still holding the contract."],
 ["The Final Lock", 2, "stalker", "The ward log shows one lock the experiment was never able to open."],
 ["Beneath the Cursed Dorm", 1, "crusher", "The lock still leads to the dorm. Its key has been yours all along."],
 ["The Deathless Procession", 3, "witch", "The traders and patients file past the hotel desk on their way to the manor."],
 ["The Last Sanctuary", 4, "storm", "The laboratory's emergency door is the last shelter before the bell tower."],
 ["Dawn or Oblivion", 5, "crusher", "The last contract lies beneath the bell. Survive long enough to break it."],
]

# Seconds relative to Hunter arrival. These shape breathing room, first-form
# specials, Hall recovery eligibility and Reaper timing without changing damage.
const ENCOUNTERS := [
 {"name":"Opening watch","preparation":48.0,"tactics":8.0,"arcane":12.0,"hall":90.0,"reaper_opening":14.0,"reaper_deadline":240.0},
 {"name":"Delayed recovery","preparation":44.0,"tactics":7.0,"arcane":10.0,"hall":72.0,"reaper_opening":12.0,"reaper_deadline":230.0},
 {"name":"Early contact","preparation":43.0,"tactics":5.0,"arcane":9.0,"hall":55.0,"reaper_opening":10.0,"reaper_deadline":220.0},
 {"name":"Guarded approach","preparation":46.0,"tactics":8.0,"arcane":12.0,"hall":62.0,"reaper_opening":12.0,"reaper_deadline":230.0},
 {"name":"Arcane investigation","preparation":45.0,"tactics":7.0,"arcane":8.0,"hall":60.0,"reaper_opening":10.0,"reaper_deadline":225.0},
 {"name":"Haunted Hall recovery","preparation":48.0,"tactics":6.0,"arcane":10.0,"hall":30.0,"reaper_opening":12.0,"reaper_deadline":230.0},
 {"name":"Rapid first form","preparation":42.0,"tactics":4.0,"arcane":7.0,"hall":50.0,"reaper_opening":8.0,"reaper_deadline":218.0},
 {"name":"The Reaper's terms","preparation":46.0,"tactics":6.0,"arcane":9.0,"hall":48.0,"reaper_opening":8.0,"reaper_deadline":210.0},
 {"name":"Pressured opening","preparation":44.0,"tactics":4.0,"arcane":6.0,"hall":45.0,"reaper_opening":8.0,"reaper_deadline":210.0},
 {"name":"The final stand","preparation":50.0,"tactics":6.0,"arcane":9.0,"hall":52.0,"reaper_opening":10.0,"reaper_deadline":220.0},
]
# First-form encounters leave more room for the authored arcane and tactical
# abilities. The chapter eight opener and final lock always include the Reaper.
const FIRST_FORM_LEVELS := [4, 17, 21, 29, 34, 44]
const REAPER_LEVELS := [36, 50]

const DISCOVERIES := [
 "The roster has five signatures and a sixth line awaiting its resident.",
 "The voice came through the call system long after the ward was disconnected.",
 "Someone built the missing floor into the hotel plans, then crossed it out.",
 "The backup circuit connects all five buildings to the same clock.",
 "The roster in the ashes was written before the dorm opened.",
 "The occupied room is listed under two different years.",
 "The flowers were delivered to a ward officially sealed for decades.",
 "The two guests checked in at the exact time the night bell rang.",
 "Every last call asks the same orderly to open the west Hall.",
 "One crossed-out name is written on the inside of the bell.",
 "The same claw marks lead from the dorm locks toward the hotel.",
 "The stairs carry two trails. One belongs to someone being dragged.",
 "The windows show a real passage the lab plans never recorded.",
 "The west Hall lets a wounded Hunter recover if the channel goes undisturbed.",
 "The missing guest left the address of the sealed ward.",
 "The water traces the path of an old hospital supply tunnel.",
 "The intercom is carrying the voices from the other end of the tunnel.",
 "The bed has the patient's wristband sewn into its cover.",
 "The missing room opens on the old ward, not another hotel suite.",
 "The last window overlooks a bell tower that should be miles away.",
 "The log records an experiment that made the nightly shift repeat.",
 "The patient was moved here from the dorm under a borrowed name.",
 "The elevator stopped at the same unseen floor every midnight.",
 "The disconnected recorder still captures the bell's signal.",
 "The first apparatus was built to hold the night open for one extra minute.",
 "The courtyard fracture joins the dorm to the first Haunted Hall.",
 "The folded halls each preserve a route back to an ordinary corridor.",
 "The ward's long corridor once linked to three other buildings.",
 "The signals mark the entrances to the four Haunted Halls.",
 "The missing residents were meant to leave through these four Halls.",
 "The lost residents are awake inside the repeat and waiting for dawn.",
 "The guest signature matches the witness on the original experiment log.",
 "The orderly signed to keep a patient alive through a single night.",
 "The recordings show which ailments were treated as acceptable losses.",
 "The seal turns red when the Hunter has a path to the last lock.",
 "The names in the song are the residents the Reaper still remembers.",
 "The last line on the roster is reserved for the bearer of the key.",
 "The ledger counts ten attempts to break the same contract.",
 "The scythe appears where the boundary between night and dawn gives way.",
 "The red seal anchors the Reaper's final domain to the manor.",
 "The five buildings share one living foundation inside the bargain.",
 "The breathing door opens only after the last stroke of the bell.",
 "The hotel clocks preserve the instant before the original night ended.",
 "The remaining seal can be held from the laboratory.",
 "The Reaper is tethered to the same clock as the residents.",
 "The ward's last lock can be turned from the other side of the bargain.",
 "The dorm key was issued to the first survivor on the roster.",
 "The procession carries the names back to their original rooms.",
 "The laboratory has kept the exit lit for the final crossing.",
 "The final contract breaks. The dawn belongs to the living again.",
]

static func phase16_enabled() -> bool:
 return OS.get_environment("NIGHTFALL_PHASE16")=="1"

static func reaper_policy(mission: Dictionary, difficulty: String) -> Dictionary:
 var boss := BossCatalog.encounter(mission.stage_id,difficulty)
 if not phase16_enabled():
  return boss
 if mission.level in FIRST_FORM_LEVELS:
  boss.enabled=false
 elif mission.level in REAPER_LEVELS:
  boss.enabled=true
 boss.opening=mission.encounter.reaper_opening
 boss.deadline=mission.encounter.reaper_deadline
 return boss

static func apply_encounter(model) -> void:
 if not phase16_enabled() or model.story_level<1 or model.story_level>FINAL_LEVEL or model.time>0.0 or model.player_room>=0:
  return
 var entry := mission(model.story_level)
 var encounter: Dictionary=entry.encounter
 model.preparation=maxf(model.preparation,encounter.preparation)
 model.hunter.tactical_cooldown=maxf(model.hunter.tactical_cooldown,encounter.tactics)
 model.hunter.arcane.cooldown=maxf(model.hunter.arcane.cooldown,encounter.arcane)
 model.hunter.boss_policy=reaper_policy(entry,model.difficulty)
 if not model.map_data.get("halls",{}).is_empty():
  model.haunt_recovery.available_at=maxf(model.haunt_recovery.available_at,model.preparation+encounter.hall)

static func mission(level: int) -> Dictionary:
 if level<1 or level>FINAL_LEVEL:return {}
 var chapter:=ceili(float(level)/CHAPTER_LENGTH)
 var row: Array=MISSIONS[level-1]
 var stage_id:="stage_%d" % int(row[1])
 var baseline:=StageCatalog.stage(stage_id)
 var encounter: Dictionary=ENCOUNTERS[chapter-1].duplicate()
 return {
  "level":level,"chapter":chapter,"chapter_title":CHAPTERS[chapter-1][0],
  "title":row[0],"stage_id":stage_id,"theme":baseline.map,"archetype":row[2],
  "topology":ROUTE_FAMILIES[chapter-1][(level-1)%CHAPTER_LENGTH],
  "objective":"Survive and defeat the Grim Reaper." if level==FINAL_LEVEL else "Survive and defeat %s." % StrategyCatalog.ARCHETYPES[row[2]].name,
  "briefing":row[3],"chapter_opening":CHAPTERS[chapter-1][1],"chapter_start":(level-1)%CHAPTER_LENGTH==0,
  "encounter":encounter,"discovery":DISCOVERIES[level-1],
  "preparation":encounter.preparation if phase16_enabled() else 44.0 if chapter==1 else 42.0 if chapter<=3 else 40.0,
  "first_clear_xp":int(baseline.first_clear_xp) if level<=5 else mini(105,55+chapter*5),
 }
