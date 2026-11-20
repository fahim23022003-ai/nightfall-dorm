extends "res://tools/nightmare_maps/measure_hell_tactics.gd"
## Timed native frames from the same dense Campaign room and combat state.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=3 or not args[0].is_absolute_path() or args[1] not in ["medium","low"] or args[2] not in ["stalker","reaper"]:
  push_error("Pass absolute output directory, medium or low, and stalker or reaper after --.")
  quit(2)
  return
 var destination:=args[0].trim_suffix("/")
 var quality:=args[1]
 var encounter:=args[2]
 var preview:=OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE")=="1"
 phase=destination.get_file()
 output=destination.get_base_dir()+"/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 var started:=Time.get_ticks_usec()
 await setup_game()
 var scene_load_ms:=(Time.get_ticks_usec()-started)/1000.0
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",quality)
 game.set_process(false)
 var model:=MatchModel.new()
 model.reset(MATCH_SEED)
 # Campaign L6 previously bypassed the Stalker pilot for the entire run.
 var stage: String="stage_1" if encounter=="stalker" else CAMPAIGN_STAGE
 var difficulty: String="standard" if encounter=="stalker" else "hell"
 check(model.configure_match(difficulty) and model.configure_stage(stage) and model.configure_balance(),"configure the matched Campaign fixture")
 check(model.configure_strategy(MATCH_SEED,"stalker"),"configure authored Stalker")
 game._adopt_session(model)
 var room:=make_room_fixture(model)
 if room==null:
  await _finish()
  return
 model.time=model.preparation+24.0
 model.bot_claimed=5
 for ally: RoomState in model.rooms:
  if ally==room:continue
  ally.owner=ally.index+1
  ally.sleeping=true
  ally.closed=true
  ally.resident_position=ally.bed_position()
 var hunter:=model.hunter
 hunter.target=room.index
 hunter.position=room.door_approach()
 if encounter=="reaper":
  hunter.hp=hunter.max_hp*.53
  hunter.state=HunterState.State.ATTACK
  model.tick(.016)
  check(hunter.transformed,"real Hunter transformation triggered")
  for i in range(160):model.tick(.016)
  check(hunter.state!=HunterState.State.TRANSFORM,"real transform timer elapsed")
  # Isolate a normal boss strike between broader Wrath ability windows.
  # The existing sequencer still schedules and lands the scythe.
  model.wrath.interrupt(model,"benchmark inter-ability setup")
  model.wrath.phase=2
  model.wrath.recovery=20.0
  hunter.boss_cooldowns.siege=20.0
  hunter.boss_cooldowns.surge=20.0
  hunter.boss_cooldowns.scythe=0.0
 else:
  hunter.boss_policy.enabled=false
 hunter.target=room.index
 hunter.position=room.door_approach()
 hunter.state=HunterState.State.ATTACK
 hunter.cooldown=.5
 hunter.siege_start_hp=room.door_hp
 game.full_map=false
 game.focus_camera(true)
 await _render_frame()
 check(root.get_texture().get_image().get_size()==Vector2i(1280,720),"native viewport at 1280×720")
 var initial:=_state_digest(model)
 var combat:=await measure_active_siege(model)
 var rig=game.presentation.boss_presentation.articulated if encounter=="reaper" else game.presentation.nightmare_visual.articulated
 var atlas: String=rig.last_asset
 if preview:
  check(not atlas.is_empty(),"verified articulated atlas on the final active frame")
 if encounter=="stalker":
  check(model.evolution.evolution_level==1,"L1 fixture remains on the articulated pilot")
 await capture("active-combat-720")
 var f:=FileAccess.open(destination.path_join("benchmark.json"),FileAccess.WRITE)
 check(f!=null,"write benchmark")
 if f!=null:
  f.store_string(JSON.stringify({
   "preview":preview,"encounter":encounter,"quality":quality,"renderer":RenderingServer.get_video_adapter_name(),
   "seed":MATCH_SEED,"stage":stage,"evolution":model.evolution.evolution_level,"atlas":atlas,"room":room.index,"buildings":room.buildings.size(),"initial_sha256":initial,
   "combat":combat,"scene_setup_ms":scene_load_ms,"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),
   "video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"checks":checks,"failures":failures,
  },"  ")+"\n")
  f.close()
 await _finish()
