extends RefCounted
## Retained desktop catalogue. Card and detail actions use the same purchase entry
## point as the floor tool; browsing an unavailable machine never spends resources.
const BOUNDS := Rect2(430,150,830,488)
const LESSON_BOUNDS := Rect2(838,450,422,170)
const ROW_SIZE := Vector2i(265,65)
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
var detail_name: Label
var detail_purpose: Label
var detail_stats: Label
var detail_cost: Label
var detail_status: Label
var detail_art: Artwork
var place: Button

func _init(interface):
 ui=interface
 root.name="BuildCatalogue"
 root.position=Vector2(14,49)
 root.size=BOUNDS.size-Vector2(28,60)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.context_box.add_child(root)
 root.hide()
 row_atlas.disable_3d=true
 row_atlas.transparent_bg=true
 row_atlas.gui_disable_input=true
 row_atlas.size=Vector2i(ROW_SIZE.x,ROW_SIZE.y*5)
 row_atlas.render_target_update_mode=SubViewport.UPDATE_DISABLED
 root.add_child(row_atlas)
 var widths: Array[int]=[142,219,153,151]
 var x:=0
 for group: String in GROUPS:
  var width: int=widths[tabs.size()]
  var tab: Button=ui.button(GROUP_NAMES[group],Vector2(x,0),select_category.bind(group),width,40,root)
  tab.name="category_"+group
  tabs[group]=tab
  x+=width+8
 card_heading=ui.label_at("",Vector2(2,44),16,377,false,root)
 for kind: String in Catalog.BUILDINGS:
  var card: Button=ui.button("",Vector2.ZERO,choose.bind(kind),383,65,root)
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
  var art:=artwork(static_row,73,62,.86)
  art.kind=kind
  var name_label: Label=ui.label_at(Catalog.BUILDINGS[kind].name.capitalize(),Vector2(71,4),18,194,false,static_row)
  name_label.size.y=27
  var role: Label=ui.label_at(CARD_ROLES[kind],Vector2(71,32),16,194,false,static_row)
  role.size.y=25
  role.modulate=GothicTheme.palette().muted
  var cost: Label=ui.label_at("",Vector2(266,5),16,107,false,card)
  cost.size.y=25
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  var state: Label=ui.label_at("",Vector2(266,32),15,107,false,card)
  state.size.y=24
  state.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  availability[kind]=state
  style_button(card,"card")
  cards[kind]=card
  prices[kind]=cost
 detail=ui.box(Rect2(395,52,406,375),"","",root)
 detail.add_theme_stylebox_override("panel",flat_style(GothicTheme.living_surface("inset")))
 detail_art=artwork(detail,150,142,1.92)
 detail_art.position=Vector2(10,4)
 detail_name=ui.label_at("",Vector2(172,19),23,219,true,detail)
 detail_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_name.size.y=56
 detail_purpose=ui.label_at("",Vector2(172,80),17,219,false,detail)
 detail_purpose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_purpose.size.y=62
 detail_stats=ui.label_at("",Vector2(16,145),17,373,false,detail)
 detail_stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_stats.size.y=76
 detail_cost=ui.label_at("",Vector2(16,228),20,373,false,detail)
 detail_cost.modulate=GothicTheme.palette().gold
 detail_status=ui.label_at("",Vector2(16,257),17,373,false,detail)
 detail_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_status.size.y=53
 place=ui.button("Place",Vector2(14,315),func():choose(selected),378,46,detail)
 place.name="place_selected"
 style_button(place,"primary")

func drawer_bounds() -> Rect2:
 return LESSON_BOUNDS if not current_lesson.is_empty() else BOUNDS

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
  root.size=drawer_bounds().size-Vector2(28,60)
  var kinds: Array=GROUPS[group] if lesson.is_empty() else [lesson]
  card_heading.text=("%s  ·  %d machines" % [GROUP_NAMES[group],kinds.size()]) if lesson.is_empty() else "Practice  ·  "+GROUP_NAMES[group]
  detail.visible=lesson.is_empty()
  card_heading.position.y=44 if lesson.is_empty() else 0
  for key in tabs:
   var tab: Button=tabs[key]
   tab.visible=lesson.is_empty()
   style_button(tab,"selected" if key==group else "quiet")
   tab.text=("✓  " if key==group else "")+GROUP_NAMES[key]
   if not lesson.is_empty():tab.position.x=0
   else:tab.position.x={"attack":0,"economy":150,"defense":377,"support":538}[key]
  for key in cards:
   var card: Button=cards[key]
   var index:=kinds.find(key)
   card.visible=index>=0
   atlas_rows[key].visible=index>=0
   if index>=0:
    card.position=Vector2(0,76+index*70 if lesson.is_empty() else 32)
    var at:=Vector2(0,index*ROW_SIZE.y)
    atlas_rows[key].position=at
    row_images[key].region=Rect2(at,Vector2(ROW_SIZE))
  row_atlas.render_target_update_mode=SubViewport.UPDATE_ONCE
  var next: String=ui.recent_build_choices.get(group,kinds.front()) if lesson.is_empty() else lesson
  preview(next)
 for kind: String in GROUPS[group]:
  if not cards[kind].visible:continue
  var ready: bool=ui.action_reason("build:"+kind).is_empty()
  var cost: Label=prices[kind]
  var quote: Vector2=room.quote_build(kind)
  cost.text="%s G  ·  %s E" % [ui._price_amount(quote.x),ui._price_amount(quote.y)]
  cost.modulate=GothicTheme.palette().gold if ready else GothicTheme.palette().muted
  var state: Label=availability[kind]
  state.text="✓ Ready" if ready else "Locked"
  state.modulate=GothicTheme.palette().success if ready else GothicTheme.palette().warning
 update_detail(room)

func preview(kind: String):
 if not cards.has(kind) or not cards[kind].visible:return
 if selected!=kind:
  if cards.has(selected):style_button(cards[selected],"card")
  selected=kind
  detail_art.kind=kind
  detail_art.queue_redraw()
  detail_name.text=Catalog.BUILDINGS[kind].name.capitalize()
  detail_purpose.text=PURPOSE[kind]
 style_button(cards[kind],"selected")
 update_detail(ui.game.model.player())

func format_cost(quote: Vector2) -> String:
 return "%s Gold  ·  %s Electricity" % [ui._price_amount(quote.x),ui._price_amount(quote.y)]

func update_detail(room):
 if selected.is_empty() or room==null or not detail.visible:return
 var quote: Vector2=room.quote_build(selected)
 var reason: String=ui.action_reason("build:"+selected)
 var footprint: String="1 pad"
 if room.spatial!=null:
  if room.spatial.grid:
   var cells:=SpatialConstruction.grid_cells(selected,0,room.spatial.rules_version)
   footprint="%d × %d cells" % [cells.x,cells.y]
  else:footprint="%d × %d world units" % [int(SpatialConstruction.FOOT_SIZE.x),int(SpatialConstruction.FOOT_SIZE.y)]
 var stats:=BuildingStats.machine_stats(ui.game.model,room,{"kind":selected,"level":1,"specialization":""})
 var output: String
 match selected:
  "turret","heavy","flame","frost","shock":output="%.1f hit  ·  %.2f s interval\nRange %.0f world units" % [stats.hit,stats.interval,stats.range]
  "generator":output="%.2f Electricity / s" % stats.rate
  "repair":output="Up to %.2f door HP / s" % stats.get("nominal_rate",stats.rate)
  "auto_repair":output="%.1f HP / burst  ·  %.1f s interval" % [stats.heal,stats.interval]
  "shield":output="%.1f shield HP  ·  %.1f s duration" % [stats.capacity,stats.duration]
  "decoy":output="%.1f s lure  ·  %.0f range" % [stats.duration,stats.range]
  "barrier":output="Reflects %.0f%% of eligible Magic" % (stats.reflect*100)
  "plasma":output="Absorbs %.0f%% of Magic  ·  %.0f capacity" % [stats.absorb*100,stats.capacity]
  "antenna":output="%.0f Magic shield HP  ·  %.1f s recharge" % [stats.capacity,stats.interval]
  "enhancer":output="+%.0f%% base turret hit" % (stats.rate*100)
  "economy":output="+%.0f%% base income bonus" % (stats.rate*100)
 detail_stats.text="Level 1  ·  "+footprint+"\n"+output
 detail_cost.text=format_cost(quote)
 detail_status.text="Ready to place" if reason.is_empty() else reason
 detail_status.modulate=GothicTheme.palette().success if reason.is_empty() else GothicTheme.palette().warning
 place.disabled=not reason.is_empty()
 place.text="Place "+Catalog.BUILDINGS[selected].name.capitalize() if reason.is_empty() else "Placement unavailable"

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
