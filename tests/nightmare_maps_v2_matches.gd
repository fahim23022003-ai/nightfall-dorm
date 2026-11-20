extends "res://tools/nightmare_maps/check_nightmare_matches.gd"
## Matched seeded Campaign trials with passive and earned defensive policies.

const FAMILY_IDS := ["ring", "branching", "scattered", "spine", "zigzag", "radial", "twin_wings", "labyrinth", "courtyards", "hybrid"]
const PLANS := ["passive", "balanced", "needle_defense"]
const DIFFICULTIES := ["standard", "hard", "hell"]
const V2_FLAG := "NIGHTFALL_PROCEDURAL_MAPS_V2"

func select_seed(theme: String, family: String, base: int, macro: GDScript) -> int:
 # Only the family narrows the candidates. Outcomes play no role in selection.
 for seed in range(base, base + 256):
  if macro.family_for(theme, seed) == family:
   return seed
 return -1

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute JSON receipt path after --.")
  quit(2)
  return
 var macro: GDScript = load("res://scripts/nightmare_macro_layout.gd")
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "1")
 grid = true
 var rows := []
 var totals := {}
 var family_totals := {}
 var visits := 0
 var reroutes := 0
 var terminal := 0
 var start := Time.get_ticks_usec()
 for family_index in range(FAMILY_IDS.size()):
  var family: String = FAMILY_IDS[family_index]
  family_totals[family] = {"runs": 0, "defensive_wins": 0, "passive_wins": 0}
  for difficulty_index in range(DIFFICULTIES.size()):
   var difficulty: String = DIFFICULTIES[difficulty_index]
   var theme_index := (family_index + 2 * difficulty_index) % THEMES.size()
   var stage: String = THEMES[theme_index]
   var theme: String = StageCatalog.stage(stage).map
   var seed := select_seed(theme, family, 2800 + family_index * 1000 + difficulty_index * 266, macro)
   if seed < 0:
    push_error("Could not select a seed for " + family + "/" + difficulty)
    failures += 1
    continue
   var room_index := (family_index + difficulty_index * 3) % 6
   var preflight := MatchModel.new()
   preflight.reset(seed)
   if not preflight.configure_stage(stage) or preflight.map_data.get("family") != family:
    push_error("Ordinary Campaign selection did not choose " + family)
    failures += 1
    continue
   for policy: String in PLANS:
    var row := simulate(stage, difficulty, seed, room_index, policy)
    row.family = family
    rows.append(row)
    var outcome: String = row.get("outcome", "invalid")
    var key: String = "%s/%s/%s" % [difficulty, policy, outcome]
    totals[key] = totals.get(key, 0) + 1
    terminal += int(outcome in ["victory", "defeat"])
    visits += int(row.get("recovery_visits", 0))
    reroutes += int(row.get("hunter_retargets", 0))
    family_totals[family].runs += 1
    if outcome == "victory":
     if policy == "passive":
      family_totals[family].passive_wins += 1
     else:
      family_totals[family].defensive_wins += 1
    if not row.invalid.is_empty():
     failures += 1
     push_error("%s/%s/%s %s" % [family, difficulty, policy, row.invalid])
    print("NIGHTMARE_V2_MATCH ", JSON.stringify(row))
 if rows.size() != FAMILY_IDS.size() * DIFFICULTIES.size() * PLANS.size() or terminal != rows.size():
  failures += 1
 for difficulty in DIFFICULTIES:
  if totals.get(difficulty + "/balanced/victory", 0) + totals.get(difficulty + "/needle_defense/victory", 0) == 0:
   failures += 1
   push_error("Neither earned defense policy could win on " + difficulty)
 var output := FileAccess.open(args[0], FileAccess.WRITE)
 if output == null:
  failures += 1
 else:
  output.store_string(JSON.stringify({
   "cases": rows, "failures": failures, "outcomes": totals, "by_family": family_totals,
   "terminal_matches": terminal, "successful_hall_visits": visits, "hunter_target_changes": reroutes,
   "wall_seconds": (Time.get_ticks_usec() - start) / 1000000.0,
   "tick_seconds": MODEL_STEP, "limit_simulated_seconds": LIMIT,
   "fixture": "Matched seeds and room choices per topology and difficulty. The condition begins with ordinary opening wages and the survivor placed at the bed for normal interaction. All later purchases and combat use normal runtime methods."
  }, "  ") + "\n")
 print("NIGHTMARE_V2_MATCHES cases=", rows.size(), " terminal=", terminal, " outcomes=", totals, " by_family=", family_totals, " visits=", visits, " retargets=", reroutes, " failures=", failures)
 quit(int(failures != 0))
