extends SceneTree
## Catalog and Story state invariants without constructing synthetic match results.

const TITLES := [
 "The Haunted Dorm", "Whispers in the Ward", "Room Thirteen", "Blackout Protocol", "The Cursed Manor",
 "Return to Darkness", "The Forgotten Wing", "Footsteps Behind the Wall", "Hallway of the Missing", "The Night Bell",
 "No Safe Door", "Blood on the Staircase", "The Watcher's Window", "The West Haunted Hall", "The Uninvited",
 "The Weeping Corridor", "Voices Under the Floor", "The Empty Bed", "The Vanishing Door", "Last Light Out",
 "Fractured Records", "The Patient Without a Name", "Elevator to Nowhere", "The Severed Circuit", "The Buried Experiment",
 "The Broken Courtyard", "Paths That Shift", "The Endless Hall", "Echoes of the Lost", "Four Halls of Mourning",
 "The Sleepless Floor", "Shadows Learn Your Name", "The Hollow Oath", "The Hunter's Return", "The Crimson Warning",
 "The Funeral Bell", "The Last Survivor", "Ten Dead at the Door", "The Scythe in the Dark", "The Red Domain",
 "The Walls Are Alive", "The Door That Breathes", "Night Without End", "The Blood Moon Ward", "The Reaper Awakens",
 "The Final Lock", "Beneath the Cursed Dorm", "The Deathless Procession", "The Last Sanctuary", "Dawn or Oblivion",
]
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

func verify_catalog():
 check(StoryCatalog.FINAL_LEVEL == TITLES.size(), "Story catalog reaches exactly 50 levels")
 check(StoryCatalog.mission(0).is_empty() and StoryCatalog.mission(51).is_empty(), "catalog rejects out-of-range levels")
 var themes := {}
 var archetypes := {}
 var topology := {}
 var story := StoryProgress.fresh(91737)
 for i in range(TITLES.size()):
  var level := i + 1
  var mission := StoryCatalog.mission(level)
  check(not mission.is_empty(), "mission exists at level %d" % level)
  if mission.is_empty():
   continue
  check(mission.level == level and mission.title == TITLES[i], "canonical level title %d" % level)
  check(int(mission.chapter) == i / 5 + 1, "chapter groups five stages at level %d" % level)
  check(mission.chapter_start == (i % 5 == 0), "chapter opening flag at level %d" % level)
  check(MapCatalog.IDS.has(mission.theme) and not StageCatalog.stage(mission.stage_id).is_empty(),
   "mission %d uses a valid encounter and map theme" % level)
  check(StrategyCatalog.ARCHETYPES.has(mission.archetype), "mission %d uses a production Hunter" % level)
  check(mission.first_clear_xp > 0 and not mission.briefing.is_empty(), "mission %d has first-clear credit and narrative" % level)
  themes[mission.theme] = true
  archetypes[mission.archetype] = true
  topology[mission.topology] = true
  check(NightmareMacroLayout.family_for(mission.theme, StoryProgress.seed_for(story, level)) == mission.topology,
   "mission %d seed selects the authored topology" % level)
 check(topology.size() == 10, "Story visits all ten V2 topologies")
 check(themes.size() == MapCatalog.IDS.size(), "Story revisits every map theme")
 check(archetypes.size() == StrategyCatalog.ARCHETYPES.size(), "Story uses all six ordinary Hunter archetypes")

func verify_progress():
 var state := StoryProgress.fresh(4123)
 check(StoryProgress.valid(state), "fresh saved Story validates")
 check(StoryProgress.position(state, "standard") == 1, "fresh Story starts at level 1")
 var seed := StoryProgress.seed_for(state, 1)
 check(seed == StoryProgress.seed_for(StoryProgress.fresh(4123), 1), "same save base and mission reproduce the seed")
 check(seed != StoryProgress.seed_for(state, 2), "adjacent levels have distinct fixture seeds")
 var before := state.duplicate(true)
 var skip := StoryProgress.settle(state, "hell", 2, true, 1)
 check(skip.is_empty() and state == before, "cannot skip an uncleared Hell mission")
 var lost_first := StoryProgress.settle(state, "standard", 1, false, 1)
 check(not lost_first.is_empty() and StoryProgress.position(state, "standard") == 1, "loss stays at lower bound")
 check(StoryProgress.seed_for(state, 1) == seed, "retry preserves established seed")

 var match_id := 2
 for level in range(1, 51):
  var supplied := StoryProgress.settle(state, "standard", level, true, match_id)
  match_id += 1
  check(not supplied.is_empty() and supplied.cleared and supplied.first_clear and supplied.reward_xp > 0,
   "first clear earns the configured reward at level %d" % level)
  check(StoryProgress.valid(state), "saved Story remains valid after level %d" % level)
  var normal := StoryProgress.summary(state, "standard")
  check(normal.highest == level and normal.position == mini(50, level + 1), "position and highest differ at level %d" % level)
  check(normal.finished == (level == 50), "completion is earned only at Level 50")
  if level == 5:
   var loss := StoryProgress.settle(state, "standard", 6, false, match_id)
   match_id += 1
   check(not loss.is_empty() and loss.position == 5 and loss.checkpoint == 5 and loss.highest == 5,
    "loss after level 5 returns to the prior checkpoint")
   loss = StoryProgress.settle(state, "standard", 5, false, match_id)
   match_id += 1
   check(not loss.is_empty() and loss.position == 5 and loss.highest == 5, "extra defeat cannot cross checkpoint floor")
   var replay := StoryProgress.settle(state, "standard", 5, true, match_id)
   match_id += 1
   check(not replay.is_empty() and replay.position == 6 and not replay.first_clear and replay.reward_xp == 0,
    "re-clearing checkpoint advances position without another first-clear reward")
 check(StoryProgress.position(state, "hard") == 1 and StoryProgress.position(state, "hell") == 1,
  "Normal completion never advances Hard or Hell")
 before = state.duplicate(true)
 check(StoryProgress.settle(state, "standard", 50, true, match_id).is_empty() and state == before,
  "completed difficulty cannot repeat completion transaction")
 var hard_clear := StoryProgress.settle(state, "hard", 1, true, match_id)
 check(not hard_clear.is_empty() and hard_clear.position == 2 and hard_clear.highest == 1 and not hard_clear.first_clear and hard_clear.reward_xp == 0,
  "other difficulty advances independently without duplicating a global first-clear reward")
 before = state.duplicate(true)
 check(StoryProgress.settle(state, "hard", 2, true, match_id).is_empty() and state == before,
  "duplicate transaction ID cannot settle the next mission")
 var bad := state.duplicate(true)
 bad.tracks.hell.position=50
 check(not StoryProgress.valid(bad), "corrupt unearned Level 50 position rejected")

func run():
 verify_catalog()
 verify_progress()
 print("LIVING_STORY_PROGRESS_CHECKS=%d FAILURES=%d" % [checks, failures])
 quit(int(failures != 0))
