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

static func mission(level: int) -> Dictionary:
 if level<1 or level>FINAL_LEVEL:return {}
 var chapter:=ceili(float(level)/CHAPTER_LENGTH)
 var row: Array=MISSIONS[level-1]
 var stage_id:="stage_%d" % int(row[1])
 var baseline:=StageCatalog.stage(stage_id)
 return {
  "level":level,"chapter":chapter,"chapter_title":CHAPTERS[chapter-1][0],
  "title":row[0],"stage_id":stage_id,"theme":baseline.map,"archetype":row[2],
  "topology":ROUTE_FAMILIES[chapter-1][(level-1)%CHAPTER_LENGTH],
  "objective":"Survive and defeat the Grim Reaper." if level==FINAL_LEVEL else "Survive and defeat %s." % StrategyCatalog.ARCHETYPES[row[2]].name,
  "briefing":row[3],"chapter_opening":CHAPTERS[chapter-1][1],"chapter_start":(level-1)%CHAPTER_LENGTH==0,
  "preparation":44.0 if chapter==1 else 42.0 if chapter<=3 else 40.0,
  "first_clear_xp":int(baseline.first_clear_xp) if level<=5 else mini(105,55+chapter*5),
 }
