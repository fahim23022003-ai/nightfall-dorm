extends RefCounted
## Retained desktop catalogue. Card and detail actions use the same purchase entry
## point as the floor tool; browsing an unavailable machine never spends resources.
const LEFT := Rect2(20,132,394,510)
const RIGHT := Rect2(866,132,394,510)
const LESSON_BOUNDS := Rect2(838,450,422,170)
const ROW_SIZE := Vector2i(262,48)
const Tutorial := preload("res://scripts/living_tutorial.gd")
const QuickTutorial := preload("res://scripts/quick_tutorial.gd")
const GROUPS := {
 "attack":["turret","heavy","flame","frost","shock"],
 "economy":["generator","economy"],
 "defense":["shield","barrier","plasma","antenna"],
 "support":["repair","auto_repair","enhancer","decoy"]
}
const GROUP_NAMES := {"attack":"Attack","economy":"Economy / Energy","defense":"Defense","support":"Support"}
const CARD_ROLES := {
 "turret":"Automatic darts","heavy":"Heavy projectile","flame":"Burn damage",
 "frost":"Slow on hit","shock":"Charged strike","generator":"Electricity output",
 "economy":"Bed income","shield":"Temporary barrier","barrier":"Magic reflection",
 "plasma":"Magic conversion","antenna":"Magic shield","repair":"Door maintenance",
 "auto_repair":"Emergency repairs","enhancer":"Weapon amplifier","decoy":"Hunter diversion"
}
const PURPOSE := {
 "turret":"Fires needles at nearby enemies.","heavy":"Launches heavy arc projectiles.",
 "flame":"Burns enemies after impact.","frost":"Slows enemies on impact.",
 "shock":"Delivers a charged electric strike.","generator":"Produces Electricity while you sleep.",
 "economy":"Increases income from your bed.","shield":"Raises a temporary barrier.",
 "barrier":"Reflects a share of incoming Magic.","plasma":"Stores Magic to mend your door.",
 "antenna":"Regenerates a Magic shield.","repair":"Mends an intact, damaged door.",
 "auto_repair":"Pays for emergency repair bursts.","enhancer":"Strengthens your room’s weapons.",
 "decoy":"Lures the Hunter away temporarily."
}

class Artwork extends Control:
 var presentation
 var profile
 var kind := ""
 var art_scale := 1.0
 func _draw():
  if kind.is_empty():return
  presentation.building_visual.draw(self,presentation,kind,1,Vector2(size.x*.5,size.y*.75),"",0,Vector2(1,-.35),0,0,art_scale)

var ui
var root := Control.new()
var detail: Panel
var bounds := RIGHT
var available_rows := {}
var next_detail_update := 0.0
# One small render target for the displayed category. Its static names and
# original layered illustrations redraw only when the visible roster changes.
var row_atlas := SubViewport.new()
var atlas_rows := {}
var row_images := {}
var flat_styles := {}
var tabs := {}
var cards := {}
var prices := {}
var availability := {}
var selected := ""
var current_group := ""
var current_lesson := ""
var card_heading: Label
var detail_purpose: Label
var detail_stats: Label
var detail_status: Label
var detail_art: Artwork
var place: Button

func _init(interface):
 ui=interface
 root.name="BuildCatalogue"
 root.position=Vector2(12,44)
 root.size=RIGHT.size-Vector2(24,60)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.context_box.add_child(root)
 root.hide()
 row_atlas.disable_3d=true
 row_atlas.transparent_bg=true
 row_atlas.gui_disable_input=true
 row_atlas.size=Vector2i(ROW_SIZE.x,ROW_SIZE.y*5)
 row_atlas.render_target_update_mode=SubViewport.UPDATE_DISABLED
 root.add_child(row_atlas)
 var index:=0
 for group: String in GROUPS:
  var tab: Button=ui.button(GROUP_NAMES[group],Vector2((index%2)*187,floori(index/2.0)*38),select_category.bind(group),181,34,root)
  tab.name="category_"+group
  tabs[group]=tab
  index+=1
 card_heading=ui.label_at("",Vector2(2,0),18,377,false,root)
 for kind: String in Catalog.BUILDINGS:
  var card: Button=ui.button("",Vector2.ZERO,choose.bind(kind),370,48,root)
  card.name="build_"+kind
  card.focus_mode=Control.FOCUS_ALL
  card.mouse_entered.connect(preview.bind(kind))
  card.focus_entered.connect(preview.bind(kind))
  ui.actions["build:"+kind]=card
  var static_row:=Control.new()
  static_row.size=Vector2(ROW_SIZE)
  static_row.theme=ui.panel.theme
  row_atlas.add_child(static_row)
  static_row.hide()
  atlas_rows[kind]=static_row
  var region:=AtlasTexture.new()
  region.atlas=row_atlas.get_texture()
  region.filter_clip=true
  var image:=TextureRect.new()
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  image.mouse_filter=Control.MOUSE_FILTER_IGNORE
  image.size=Vector2(ROW_SIZE)
  image.texture=region
  card.add_child(image)
  row_images[kind]=region
  var art:=artwork(static_row,48,46,.67)
  art.kind=kind
  var name_label: Label=ui.label_at(Catalog.BUILDINGS[kind].name.capitalize(),Vector2(48,1),19,213,false,static_row)
  name_label.size.y=24
  name_label.clip_text=true
  var role: Label=ui.label_at(CARD_ROLES[kind],Vector2(48,24),16,213,false,static_row)
  role.size.y=21
  role.modulate=GothicTheme.palette().muted
  var cost: Label=ui.label_at("",Vector2(239,1),18,122,false,card)
  cost.size.y=25
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  var state: Label=ui.label_at("",Vector2(238,23),18,123,false,card)
  state.size.y=24
  cost.clip_text=true
  state.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  availability[kind]=state
  style_button(card,"card")
  cards[kind]=card
  prices[kind]=cost
 detail=ui.box(Rect2(0,319,370,142),"","",root)
 detail.add_theme_stylebox_override("panel",flat_style(GothicTheme.living_surface("inset")))
 detail_art=artwork(detail,98,100,1.46)
 detail_art.position=Vector2(3,1)
 detail_purpose=ui.label_at("",Vector2(101,5),18,255,false,detail)
 detail_purpose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_purpose.size.y=42
 detail_stats=ui.label_at("",Vector2(101,46),18,255,false,detail)
 detail_stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_stats.size.y=56
 detail_status=ui.label_at("",Vector2(11,104),18,347,false,detail)
 detail_status.clip_text=true
 detail_status.tooltip_text=""
 place=ui.button("Place",Vector2(233,100),func():choose(selected),128,38,detail)
 place.name="place_selected"
 style_button(place,"primary")

func drawer_bounds() -> Rect2:
 return LESSON_BOUNDS if not current_lesson.is_empty() else bounds

func anchor(room) -> void:
 if room==null or not current_lesson.is_empty():return
 var game=ui.game
 var focus: Rect2=room.bounds().expand(room.door_approach())
 var hunter=game.model.hunter
 if hunter.target==room.index and hunter.position.distance_to(room.door_approach())<155.0:
  focus=focus.expand(hunter.position+Vector2(-45,-75)).expand(hunter.position+Vector2(45,25))
 var at: Vector2=game.world_to_screen(focus.position)
 var projected:=Rect2(at,game.world_to_screen(focus.end)-at)
 bounds=LEFT if LEFT.intersection(projected).get_area()<RIGHT.intersection(projected).get_area() else RIGHT

func flat_style(original: StyleBoxFlat) -> StyleBoxFlat:
 if not flat_styles.has(original):
  var flat: StyleBoxFlat=original.duplicate()
  flat.set_corner_radius_all(0)
  flat.anti_aliasing=false
  flat_styles[original]=flat
 return flat_styles[original]

func style_button(button: Button,role: String):
 if button.get_meta("catalogue_style","")==role:return
 ui.theme_button(button,role)
 for state in ["normal","hover","pressed","disabled","focus"]:
  button.add_theme_stylebox_override(state,flat_style(GothicTheme.living_surface(role,state)))
 button.set_meta("catalogue_style",role)


func artwork(parent: Control,width: int,height: int,scale_factor: float) -> Artwork:
 var thumb:=Artwork.new()
 thumb.presentation=ui.game.presentation
 thumb.profile=ui.game.profile
 thumb.art_scale=scale_factor
 thumb.size=Vector2(width,height)
 thumb.mouse_filter=Control.MOUSE_FILTER_IGNORE
 thumb.clip_contents=true
 parent.add_child(thumb)
 return thumb

func lesson_kind() -> String:
 if not ui.game.tutorial_active or ui.game.onboarding==null:return ""
 var course=ui.game.onboarding.course
 if not course is QuickTutorial:return ""
 match course.stage:
  Tutorial.Lesson.OPEN_BUILD,Tutorial.Lesson.SELECT_DYNAMO,Tutorial.Lesson.PLACE_DYNAMO,Tutorial.Lesson.CANCEL_PREVIEW:return "generator"
  Tutorial.Lesson.REOPEN_BUILD,Tutorial.Lesson.SELECT_NEEDLE,Tutorial.Lesson.PLACE_NEEDLE:return "turret"
 return ""

func select_category(group: String):
 if not current_lesson.is_empty():return
 ui.last_build_category=group
 refresh(ui.game.model.player())

func refresh(room):
 if room==null:return
 var lesson:=lesson_kind()
 var group: String=ui.last_build_category if lesson.is_empty() else "economy" if lesson=="generator" else "attack"
 if current_group!=group or current_lesson!=lesson:
  current_group=group
  current_lesson=lesson
  root.size=drawer_bounds().size-Vector2(24,60)
  available_rows.clear()
  var kinds: Array=GROUPS[group] if lesson.is_empty() else [lesson]
  card_heading.text="" if lesson.is_empty() else "Practice  ·  "+GROUP_NAMES[group]
  detail.visible=lesson.is_empty()
  card_heading.visible=not lesson.is_empty()
  for key in tabs:
   var tab: Button=tabs[key]
   tab.visible=lesson.is_empty()
   style_button(tab,"selected" if key==group else "quiet")
   tab.text=("✓  " if key==group else "")+GROUP_NAMES[key]
   tab.add_theme_font_size_override("font_size",18)
  for key in cards:
   var card: Button=cards[key]
   var index:=kinds.find(key)
   card.visible=index>=0
   atlas_rows[key].visible=index>=0
   if index>=0:
    card.position=Vector2(0,74+index*49 if lesson.is_empty() else 35)
    var at:=Vector2(0,index*ROW_SIZE.y)
    atlas_rows[key].position=at
    row_images[key].region=Rect2(at,Vector2(ROW_SIZE))
  row_atlas.size.y=ROW_SIZE.y*(5 if lesson.is_empty() else 1)
  row_atlas.render_target_update_mode=SubViewport.UPDATE_ONCE
  var next: String=ui.recent_build_choices.get(group,kinds.front()) if lesson.is_empty() else lesson
  preview(next)
 for kind: String in GROUPS[group]:
  if not cards[kind].visible:continue
  var quote: Vector2=room.quote_build(kind)
  var reason: String=ui.action_reason("build:"+kind)
  var ready:=reason.is_empty()
  if available_rows.get(kind,Vector3.INF)!=Vector3(quote.x,quote.y,float(ready)):
   available_rows[kind]=Vector3(quote.x,quote.y,float(ready))
   prices[kind].text="%s G / %s E" % [ui._price_amount(quote.x),ui._price_amount(quote.y)]
   prices[kind].modulate=GothicTheme.palette().gold if ready else GothicTheme.palette().muted
   availability[kind].text="✓ Ready" if ready else "Locked"
   availability[kind].modulate=GothicTheme.palette().success if ready else GothicTheme.palette().warning
  if kind==selected:update_availability(reason)
 if detail.visible and ui.game.presentation.clock>=next_detail_update:update_detail(room)

func update_availability(reason: String) -> void:
 if not detail.visible:return
 var available:=reason.is_empty()
 if reason==detail_status.tooltip_text and place.visible==available and not detail_status.text.is_empty():return
 detail_status.tooltip_text=reason
 if reason.contains("more electricity"):reason=reason.get_slice(".",0)
 detail_status.text="Ready to place" if available else reason
 detail_status.size.x=217 if available else 348
 detail_status.modulate=GothicTheme.palette().success if available else GothicTheme.palette().warning
 place.visible=available

func preview(kind: String):
 if not cards.has(kind) or not cards[kind].visible:return
 if selected!=kind:
  if cards.has(selected):style_button(cards[selected],"card")
  selected=kind
  detail_art.kind=kind
  detail_art.queue_redraw()
  detail_purpose.text=PURPOSE[kind]
 style_button(cards[kind],"selected")
 var room=ui.game.model.player()
 if room!=null:
  update_availability(ui.action_reason("build:"+kind))
  update_detail(room)

func update_detail(room):
 if selected.is_empty() or room==null or not detail.visible:return
 next_detail_update=ui.game.presentation.clock+.35
 var footprint: String="1 pad"
 if room.spatial!=null:
  if room.spatial.grid:
   var cells:=SpatialConstruction.grid_cells(selected,0,room.spatial.rules_version)
   footprint="%d × %d cells" % [cells.x,cells.y]
  else:footprint="%d × %d world units" % [int(SpatialConstruction.FOOT_SIZE.x),int(SpatialConstruction.FOOT_SIZE.y)]
 var stats:=BuildingStats.machine_stats(ui.game.model,room,{"kind":selected,"level":1,"specialization":""})
 var output: String
 match selected:
  "turret","heavy","flame","frost","shock":output="%.1f hit / %.2f s · %.0f range" % [stats.hit,stats.interval,stats.range]
  "generator":output="%.2f Electricity / s" % stats.rate
  "repair":output="Up to %.2f door HP / s" % stats.get("nominal_rate",stats.rate)
  "auto_repair":output="%.1f HP / burst  ·  %.1f s interval" % [stats.heal,stats.interval]
  "shield":output="%.1f shield HP  ·  %.1f s duration" % [stats.capacity,stats.duration]
  "decoy":output="%.1f s lure  ·  %.0f range" % [stats.duration,stats.range]
  "barrier":output="Reflects %.0f%% of eligible Magic" % (stats.reflect*100)
  "plasma":output="Absorbs %.0f%% of Magic  ·  %.0f capacity" % [stats.absorb*100,stats.capacity]
  "antenna":output="%.0f shield HP / %.1f s" % [stats.capacity,stats.interval]
  "enhancer":output="+%.0f%% base turret hit" % (stats.rate*100)
  "economy":output="+%.0f%% base income bonus" % (stats.rate*100)
 detail_stats.text=footprint+" · Level 1\n"+output

func choose(kind: String):
 if not ui.context_open or ui.context_mode!="build" or not cards.has(kind) or not cards[kind].visible:return
 preview(kind)
 var reason: String=ui.action_reason("build:"+kind)
 if not reason.is_empty():
  if reason.contains("more gold"):ui.game.audio_event("insufficient_gold")
  elif reason.contains("more electricity"):ui.game.audio_event("insufficient_power")
  return
 if current_lesson.is_empty():ui.recent_build_choices[current_group]=kind
 ui.game.build_selected(kind)
