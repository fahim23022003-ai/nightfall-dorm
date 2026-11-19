extends "res://tools/capture_visual_rebirth.gd"
## Fixture-only sensitivity check. Resource substitutions do not modify the model.

const ADDITIONS := ["flame","frost","shock","economy","enhancer","bed","auto_repair","shield","door","decoy","barrier","plasma","antenna"]
const WARM := 24
const SAMPLES := 120

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 var previous := _state_digest(model)
 var full := await _sample(model)
 await capture("full-catalog-720")
 var visual = game.presentation.building_visual
 for kind in ADDITIONS:
  visual.rebirth_atlases[kind] = []
 var masked := await _sample(model)
 await capture("additions-masked-720")
 check(_state_digest(model) == previous, "diagnostic preserves selected model state")
 var file := FileAccess.open(destination.path_join("diagnostic.json"),FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify({"full":full,"masked":masked,"masked_atlas_families":ADDITIONS,"model_digest":previous},"  ")+"\n")
 await _finish()

func _sample(model) -> Dictionary:
 var values: Array[float] = []
 for index in range(WARM+SAMPLES):
  var begin := Time.get_ticks_usec()
  game.presentation.update(STEP,model)
  await _render_frame()
  if index >= WARM:
   values.append((Time.get_ticks_usec()-begin)/1000.0)
 values.sort()
 return {
  "median_ms": (values[SAMPLES/2-1]+values[SAMPLES/2])/2.0,
  "p95_ms": values[ceili(SAMPLES*.95)-1],
  "estimated_render_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
  "samples": SAMPLES, "warmup": WARM,
 }
