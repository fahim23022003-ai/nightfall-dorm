extends "res://tools/phase21/capture_ui.gd"
## Expand the prior fixed-seed walkthrough without changing its model clock or combat setup.
## Additional menu/inspector steady-state timings use independent wall clocks while simulation is frozen.

var audit := {}
var controls_exercised := 0
var catalogued: Array = []
var latencies := {}

func click(button: Button):
 if is_instance_valid(button) and button.is_visible_in_tree():
  var visible_rect := button.get_global_rect()
  var ancestor := button.get_parent()
  while ancestor is Control:
   if ancestor.clip_contents:
    visible_rect = visible_rect.intersection(ancestor.get_global_rect())
   ancestor = ancestor.get_parent()
  check(visible_rect.has_point(button.get_global_rect().get_center()), "mouse target inside clipping parents: " + str(button.name))
  check(button.get_viewport_rect().has_point(button.get_global_rect().get_center()), "mouse target on screen: " + str(button.name))
  controls_exercised += 1
 if "latency" in OS.get_cmdline_user_args():
  var point := root.get_final_transform() * button.get_global_rect().get_center()
  var motion := InputEventMouseMotion.new()
  motion.position = point
  motion.global_position = point
  Input.parse_input_event(motion)
  await process_frame
  var hover := root.gui_get_hovered_control()
  check(hover == button or (hover != null and button.is_ancestor_of(hover)), "pointer reaches advertised control: " + str(button.name))
  var label := str(button.name)
  for down: bool in [true,false]:
   var event := InputEventMouseButton.new()
   event.position = point
   event.global_position = point
   event.button_index = MOUSE_BUTTON_LEFT
   event.pressed = down
   var started := Time.get_ticks_usec()
   Input.parse_input_event(event)
   await process_frame
   if not down:
    await RenderingServer.frame_post_draw
    if not latencies.has(label):latencies[label]=[]
    latencies[label].append((Time.get_ticks_usec()-started)/1000.0)
 else:await super.click(button)

func eligible_buttons() -> Array:
 var result: Array = []
 for key in game.ui.actions:
  if str(key).begins_with("build:") and game.ui.actions[key].is_visible_in_tree():
   result.append(str(key).trim_prefix("build:"))
 return result

func screen_controls(label: String) -> void:
 # A clipped list may legitimately extend beyond its viewport. Check the exposed
 # geometry only, and report text suspects for pixel review instead of guessing.
 var short_labels: Array = []
 var exposed: int = 0
 var focusable: int = 0
 var clipped_buttons: Array = []
 for cell in game.ui.panel.find_children("*", "Button", true, false):
  var button: Button = cell
  if not button.is_visible_in_tree():continue
  var bounds := button.get_global_rect()
  var visible_bounds := bounds
  var owner_node := button.get_parent()
  while owner_node is Control:
   if owner_node.clip_contents:
    visible_bounds = visible_bounds.intersection(owner_node.get_global_rect())
   owner_node = owner_node.get_parent()
  if not visible_bounds.has_area():continue
  exposed += 1
  if button.focus_mode != Control.FOCUS_NONE:focusable += 1
  if not button.get_viewport_rect().grow(1.5).encloses(visible_bounds):
   clipped_buttons.append(str(button.name))
  var text_size := button.get_theme_font_size("font_size")
  if button.text != "" and text_size * float(viewport_size.x) / 1280 < 11:
   short_labels.append({"name":str(button.name), "font_px":text_size * float(viewport_size.x) / 1280})
 audit[label] = {"visible_buttons":exposed, "focusable_buttons":focusable, "offscreen_buttons":clipped_buttons, "small_text_candidates":short_labels}

func extra_frames(surface: String) -> void:
 if "bench" not in OS.get_cmdline_user_args():return
 var frames: Array[float] = []
 var previous := Time.get_ticks_usec()
 for frame in range(50):
  await RenderingServer.frame_post_draw
  var current := Time.get_ticks_usec()
  if frame >= 5:frames.append((current - previous) / 1000.0)
  previous = current
 frames.sort()
 presets[surface + "_render_only"] = {"frames":frames.size(), "median_ms":frames[22], "p95_ms":frames[42], "p99_ms":frames[44]}

func still(label: String):
 await super.still(label)
 screen_controls(label)
 match label:
  "02-settings-1":
   await extra_frames("audio_settings")
   if "latency" in OS.get_cmdline_user_args():
    for i in range(7):
     await press("settings_page_0", game.ui.panel)
     await press("settings_page_1", game.ui.panel)
  "02-settings-4":
   if "transactions" in OS.get_cmdline_user_args():
    await press("reading_text", game.ui.panel)
    check(game.ui.large_reading_text, "accessibility choice enables larger reading text")
  "02-settings-5":
   if "remember" in OS.get_cmdline_user_args():
    await key(KEY_ESCAPE)
    await press("menu_settings",game.ui.panel)
    check(game.ui.tactical_settings.title.text=="Interface / HUD","reopening Settings restores its last page")
  "03-inventory":
   await extra_frames("inventory")
   var owned := game.ui.panel.find_child("inventory_stock", true, false) as ItemList
   check(owned.item_count == 1 and "Radar" in owned.get_item_text(0), "initial inventory prioritizes owned equipment")
   await press("inventory_group", game.ui.panel)
   check(owned.item_count == ItemCatalog.IDS.size() - 1, "browse remaining unowned item types")
   await press("inventory_group", game.ui.panel)
   check(owned.item_count == 1, "return to owned equipment")
   if "remember" in OS.get_cmdline_user_args():
    await key(KEY_ESCAPE)
    await press("menu_inventory",game.ui.panel)
    check(game.ui.items_ui.inventory_menu.selected=="radar","reopening Inventory restores the owned item")
  "05-rank":
   await press("rank_perks", game.ui.panel)
   await press("rank_records", game.ui.panel)
   await press("rank_progress", game.ui.panel)
  "08-hud-calm":
   if "hints" in OS.get_cmdline_user_args():await dock_hint_probe()
   await key(KEY_T)
   check(game.ui.teammates.expanded,"T opens the actual teammate roster")
   await key(KEY_ESCAPE)
   check(not game.ui.teammates.expanded and game.model.running,"Escape dismisses the roster without pausing")
  "09-build":
   check(not game.ui.teammates.toggle.is_visible_in_tree(),"closed roster shortcut stays out of the catalogue")
   catalogued.clear()
   var attack := eligible_buttons()
   check("turret" in attack and attack.size() < 15, "Attack tab exposes a filtered catalogue")
   catalogued.append_array(attack)
   var count := game.model.player().buildings.size() as int
   for category in ["economy", "defense", "support"]:
    await press("category_" + category, game.ui.panel)
    var cards := eligible_buttons()
    check(not cards.is_empty(), "visible cards in " + category)
    if category == "economy":check("generator" in cards, "Dynamo under Economy")
    for kind in cards:
     check(not catalogued.has(kind), "machine belongs to one category: " + kind)
     catalogued.append(kind)
    if category == "economy":await extra_frames("economy_tab")
   check(catalogued.size() == Catalog.BUILDINGS.size(), "all 15 placeable families reachable by category")
   check(game.model.player().buildings.size() == count, "browsing categories never purchases")
   # Verify remembered category and keyboard dismissal before the matched purchase.
   var remembered := eligible_buttons()
   await key(KEY_ESCAPE)
   await key(KEY_B)
   await create_timer(.25).timeout
   check(eligible_buttons() == remembered, "Build remembers the last open category")
   await press("category_attack", game.ui.panel)
   if "latency" in OS.get_cmdline_user_args():
    for i in range(7):
     await press("category_economy", game.ui.panel)
     await press("category_attack", game.ui.panel)
  "10-placement-valid":
   check(game.ui.tactical_hud.last_cursor==Input.CURSOR_CROSS,"valid floor selects the placement crosshair")
   var angle: int = game.construction.rotation
   await key(KEY_Q)
   check(game.construction.rotation == posmod(angle + 1, 4), "Q rotates the live footprint")
   for i in range(3):await key(KEY_Q)
  "11-placement-blocked":
   check(game.ui.tactical_hud.last_cursor==Input.CURSOR_FORBIDDEN,"blocked floor selects the forbidden cursor")
   var wallet := Vector2(game.model.player().gold, game.model.player().electricity)
   await mouse(true,game.model.player().door_position())
   check(game.model.player().buildings.is_empty() and wallet == Vector2(game.model.player().gold, game.model.player().electricity), "blocked world click leaves wallet and grid intact")
  "12-machine-inspector":
   await extra_frames("machine_inspector")
   await press("MachineDetails", game.ui.panel)
   await press("MachineDetails", game.ui.panel)
   if "transactions" in OS.get_cmdline_user_args():await inspect_transactions()
  "13-items":
   check(game.profile.inventory.get("radar",0)==1,"examining a carried item preserves stock")
  "15-help":
   if "transactions" in OS.get_cmdline_user_args():
    var help = game.phase20_help
    await click(help.navigation[4])
    var scroller: ScrollContainer = help.copy.get_parent()
    check(help.copy.get_theme_font_size("font_size")==24 and help.copy.get_line_count()>1, "larger reading font reached real Help text")
    await wheel_down(scroller)
    check(scroller.scroll_vertical > 0 or scroller.get_v_scroll_bar().max_value <= scroller.size.y, "long Hunter guide scrolls or fits without overflow")
  "18-critical-door":
   if "siege-build" in OS.get_cmdline_user_args():await verify_siege_build()
   await extra_frames("crisis")
   check(game.ui.quick_repair.is_visible_in_tree() and game.ui.room_door_summary.is_visible_in_tree(), "crisis keeps Repair and Door on HUD")

   var ward := game.ui.panel.find_child("critical_ward", true, false) as Button
   check(ward != null and ward.is_visible_in_tree(), "actual Ward shortcut exposed on critical HUD")
   if "transactions" in OS.get_cmdline_user_args() and ward != null:
    var room: RoomState = game.model.player()
    room.electricity = 12
    game.ui.update_match()
    check(game.model.ward_reason().is_empty() and not ward.disabled, "funded crisis room can use Ward")
    await click(ward)
    check(room.electricity == 6 and game.model.ward_until > game.model.time, "Ward click pays exactly 6 Electricity and activates protection")

func verify_siege_build() -> void:
 var model: MatchModel=game.model
 var room: RoomState=model.player()
 var before_position: Vector2=game.camera.position
 var before_zoom: Vector2=game.camera.zoom
 var before_count:=room.buildings.size()
 await key(KEY_B)
 check(game.ui.context_open and game.ui.context_mode=="build","Build opens during active siege")
 var rect: Rect2=game.ui.context_box.get_global_rect()
 var start: Vector2=game.world_to_screen(room.bounds().position)
 var projected:=Rect2(start,game.world_to_screen(room.bounds().end)-start)
 var room_overlap:=rect.intersection(projected).get_area()/projected.get_area()
 check(room_overlap<=.15,"Build covers at most 15% of the visible room in the fixed siege")
 check(not rect.has_point(game.world_to_screen(room.door_position())),"Build leaves the real door visible")
 check(not rect.has_point(game.world_to_screen(model.hunter.position)),"Build leaves the active Hunter visible")
 check(game.ui.warning_box.visible and not rect.intersects(game.ui.warning_box.get_global_rect()),"Build leaves active combat warning visible")
 check(game.ui.room_door_summary.is_visible_in_tree(),"Door HP stays visible while browsing")
 check(game.camera.position==before_position and game.camera.zoom==before_zoom,"Build opens without moving or zooming the camera")
 await image("19-build-during-siege",viewport_size)
 await key(KEY_ESCAPE)
 check(not game.ui.context_open and before_count==room.buildings.size(),"Escape closes Build without buying")
 check(game.camera.position==before_position and game.camera.zoom==before_zoom,"Build closes without a camera shift")
 # Pan through the normal middle-mouse input path, then confirm side selection.
 var pan:=InputEventMouseMotion.new()
 pan.position=Vector2(640,360)
 pan.relative=Vector2(260,0)
 pan.button_mask=MOUSE_BUTTON_MASK_MIDDLE
 Input.parse_input_event(pan)
 await process_frame
 if game.phase20_free_camera and game.world_to_screen(room.center()).x>780:
  var manual: Vector2=game.camera.position
  await key(KEY_B)
  check(game.ui.context_box.position.x<100,"right-side room anchors Build on the left")
  check(game.camera.position==manual,"Build keeps the manually panned camera")
  check(not game.ui.context_box.get_global_rect().intersects(game.construction.plan_button.get_global_rect()),"Plan never overlaps left-anchored Build")
  presets["siege_build"]={"room_overlap":room_overlap,"left_anchor":true}
  await key(KEY_ESCAPE)
  await key(KEY_HOME)

func dock_hint_probe() -> void:
 var button: Button = game.ui.quick_repair
 var point: Vector2 = root.get_final_transform() * button.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position = point
 motion.global_position = point
 Input.parse_input_event(motion)
 await process_frame
 game.ui.update_match()
 var hint: Label = game.ui.panel.find_child("dock_hint", true, false)
 check(hint != null and hint.is_visible_in_tree() and not hint.text.is_empty(), "actual Repair hover shows a useful hint")
 if hint != null:
  check(hint.mouse_filter == Control.MOUSE_FILTER_IGNORE and root.gui_get_hovered_control()==button,"hint does not intercept Repair")
  var displayed := hint.get_global_rect()
  check(hint.get_viewport_rect().encloses(displayed) and displayed.end.x < game.ui.quick_repair.get_global_rect().position.x and not displayed.intersects(button.get_global_rect()), "hint stays within the left dock edge, away from the action")
  await image("08b-repair-hint",viewport_size)

func wheel_down(scroller: ScrollContainer) -> void:
 var point := root.get_final_transform() * scroller.get_global_rect().get_center()
 for i in range(3):
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_WHEEL_DOWN
  event.position = point
  event.global_position = point
  event.pressed = true
  Input.parse_input_event(event)
  await process_frame

func alternate_move(room: RoomState, id: int) -> Vector2:
 var origin := room.tile_position(id)
 var bounds := room.spatial.grid_bounds()
 for y in range(ceili(bounds.size.y/SpatialConstruction.CELL_SIZE)):
  for x in range(ceili(bounds.size.x/SpatialConstruction.CELL_SIZE)):
   var point := room.spatial.aligned(bounds.position+Vector2(x,y)*SpatialConstruction.CELL_SIZE,"turret",0)
   if point == origin or not Rect2(350,210,380,345).has_point(game.world_to_screen(point)):continue
   if room.spatial.geometry_reason(point,id,{},"turret",0)=="":return point
 return Vector2.INF

func inspect_transactions() -> void:
 var room: RoomState = game.model.player()
 var id: int = game.selected_tile
 var original: Vector2 = room.tile_position(id)
 var alternate: Vector2 = alternate_move(room,id)
 check(alternate.is_finite() and alternate != original, "a second legal grid location is visible")
 if not alternate.is_finite():return
 var identity: int = room.buildings[id].instance_id
 var before := Vector2(room.gold,room.electricity)
 await click(game.construction.move_button)
 check(game.construction.moving == id, "Move targets the inspected instance")
 await pointer(alternate)
 await mouse(true, alternate)
 check(room.tile_position(id) == alternate and room.buildings[id].instance_id == identity, "physical move preserves instance")
 await key(KEY_Z)
 check(room.tile_position(id) == original and before == Vector2(room.gold,room.electricity), "Undo restores the same instance and wallet")
 if game.ui.context_open:await key(KEY_ESCAPE)
 await mouse(true, original)
 await create_timer(.25).timeout
 # Fund only this dedicated transaction fixture. This variant is never used for timing.
 room.gold += 500
 room.electricity += 100
 game.ui.update_match()
 await click(game.ui.actions.upgrade)
 check(room.buildings[id].level == 2, "paid Upgrade raises the selected level")
 var before_sale := Vector2(room.gold,room.electricity)
 var refund := room.building_refund(id)
 await click(game.ui.actions.sell)
 await press("KeepMachine",game.ui.panel)
 check(room.buildings.has(id) and before_sale == Vector2(room.gold,room.electricity), "canceling Sell retains machine and cash")
 await click(game.ui.actions.sell)
 await press("ConfirmSale",game.ui.panel)
 check(not room.buildings.has(id) and Vector2(room.gold,room.electricity).is_equal_approx(before_sale + refund), "confirmed Sell pays exactly the model refund")

func finish():
 var receipt := {"screens":audit, "actual_button_clicks":controls_exercised, "families":catalogued, "release_to_present_ms":latencies}
 FileAccess.open(destination.path_join("layout.json"), FileAccess.WRITE).store_string(JSON.stringify(receipt,"  ")+"\n")
 await super.finish()
