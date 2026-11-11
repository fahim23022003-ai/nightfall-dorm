class_name DormMobileInterface
extends RefCounted
var game
var stick
var interact_button: Button

class StickVisual extends Control:
 var owner_game
 func _process(_delta):
  if visible: queue_redraw()
 func _draw():
  var center=Vector2(98,98)
  draw_circle(center,78,Color(0.07,0.14,0.19,0.8))
  draw_arc(center,78,0,TAU,48,Color("7BE3A1"),3)
  draw_circle(center+owner_game.touch.direction*48,30,Color("607D8B"))
  draw_arc(center+owner_game.touch.direction*48,30,0,TAU,32,Color("DDF5EF"),2)

func _init(owner_game): game=owner_game
func heading(ui,title: String,subtitle: String=""):
 ui.box(Rect2(24,18,1232,684),"203747","607D8B")
 ui.label_at(title,Vector2(56,36),30,1120,true)
 if subtitle!="": text(ui,subtitle,Vector2(56,90),Vector2(1120,66),22)
 game.mobile_layout.apply()

func text(ui,value: String,pos: Vector2,size: Vector2,font=22,parent: Control=null):
 var label=ui.label_at(value,pos,font,size.x,false,parent)
 label.clip_text=true
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size=size
 return label

func large(ui,value: String,pos: Vector2,callback: Callable,width=360,parent: Control=null):
 var b=ui.button(value,pos,callback,width,68,parent)
 b.add_theme_font_size_override("font_size",22)
 return b

func show_menu(ui):
 ui.current_screen="menu"
 heading(ui,"NIGHTFALL DORM","Choose a room. Sleep, build and defend against the hunter.")
 ui.progression.badge(game.profile.rank_index(),Vector2(1060,30),96)
 text(ui,"%s · %d XP" % [game.profile.rank_name(),game.profile.xp],Vector2(56,154),Vector2(1100,40),24)
 large(ui,"Start Game",Vector2(64,220),ui.progression.show_loadout,550)
 large(ui,"Ranks & rewards",Vector2(658,220),ui.progression.show_ranks,550)
 large(ui,"How to Play",Vector2(64,326),ui.show_help,550)
 large(ui,"Settings",Vector2(658,326),ui.show_settings,550)
 large(ui,"Exit Game",Vector2(64,432),game.request_quit,550)
 var message="Left stick moves. Tap a room to walk in and claim it. Tap its bed to sleep."
 if game.profile.warning!="": message=game.profile.warning
 text(ui,message,Vector2(64,536),Vector2(1140,126))

func scroll(ui,rect: Rect2,height: float):
 var view=ScrollContainer.new()
 view.name="MobileScroll"
 view.position=rect.position
 view.size=rect.size
 view.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 view.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 view.scroll_deadzone=16
 view.follow_focus=true
 ui.panel.add_child(view)
 var body=Control.new()
 body.custom_minimum_size=Vector2(rect.size.x-24,height)
 body.size=body.custom_minimum_size
 view.add_child(body)
 return body

func show_rewards(ui,loadout: bool):
 ui.clear()
 ui.current_screen="loadout" if loadout else "ranks"
 game.audio_event("menu")
 var p=game.profile
 var rank=p.rank_index()
 var next="All rewards unlocked" if rank==5 else "Next: %s at %d XP" % [RankCatalog.PERKS[rank+1].name,RankCatalog.THRESHOLDS[rank+1]]
 heading(ui,"PREPARE FOR THE NIGHT" if loadout else "RANKS & REWARDS","%s · %d XP · %s · %d boost slot" % [p.rank_name(),p.xp,next,RankCatalog.MAX_EQUIPPED])
 var body=scroll(ui,Rect2(52,164,1176,328 if loadout else 420),6*132)
 for i in range(6):
  var item=RankCatalog.PERKS[i]
  var id=item.id
  var y=i*132.0
  var art=ui.progression.badge(i,Vector2.ZERO,78)
  art.reparent(body)
  art.position=Vector2(8,y+12)
  var unlocked=id in p.unlocked()
  var state="Unlocked" if unlocked else "%s · %d XP required" % [RankCatalog.NAMES[i],RankCatalog.THRESHOLDS[i]]
  text(ui,item.name+" · "+state+"\n"+item.description,Vector2(104,y+8),Vector2(770,118),22,body)
  var b=large(ui,"Equipped ✓" if id in p.equipped else "Equip",Vector2(900,y+28),func():
   if p.equip(id): game.audio_event("reward")
   show_rewards(ui,loadout),220,body)
  b.disabled=not unlocked or p.read_only
 if loadout:
  text(ui,"DIFFICULTY",Vector2(56,506),Vector2(280,40))
  for i in range(2):
   var key=["standard","hard"][i]
   large(ui,("✓ " if ui.progression.difficulty==key else "")+RankCatalog.DIFFICULTIES[key].name,Vector2(360+i*430,500),func():
    ui.progression.difficulty=key
    show_rewards(ui,true),400)
  large(ui,"Back",Vector2(56,614),ui.show_menu,290)
  large(ui,"Ranks & rewards",Vector2(376,614),ui.progression.show_ranks,400)
  large(ui,"Start Night",Vector2(806,614),func(): game.start_match(ui.progression.difficulty),420)
 else:
  large(ui,"Back",Vector2(56,614),ui.show_menu,300)
  large(ui,"Choose loadout",Vector2(806,614),ui.progression.show_loadout,420)

func show_settings(ui):
 ui.current_screen="settings"
 heading(ui,"SETTINGS")
 for i in range(3):
  var key=["music","effects","ambient"][i]
  text(ui,key.capitalize()+" volume",Vector2(64,120+i*86),Vector2(330,60),24)
  var slider=HSlider.new()
  slider.name=key+"_volume"
  slider.position=Vector2(420,112+i*86)
  slider.size=Vector2(760,68)
  slider.step=0.01
  slider.value=game.profile.settings[key]*100
  slider.value_changed.connect(func(value): game.change_setting(key,value/100.0))
  ui.panel.add_child(slider)
 for i in range(3):
  var key=["muted","tutorial","battery_saver"][i]
  var toggle=CheckButton.new()
  toggle.name=key
  toggle.text=["Mute all audio","First-night guide","Battery saver: 30 FPS cap"][i]
  toggle.position=Vector2(64,385+i*66)
  toggle.size=Vector2(1110,60)
  toggle.add_theme_font_size_override("font_size",24)
  toggle.button_pressed=game.profile.settings.get(key,false)
  toggle.toggled.connect(func(value): game.change_setting(key,value))
  ui.panel.add_child(toggle)
 large(ui,"Back",Vector2(64,614),ui.show_menu,350)

func show_help(ui):
 ui.current_screen="help"
 heading(ui,"SURVIVAL HANDBOOK")
 var body=scroll(ui,Rect2(56,110,1168,470),650)
 text(ui,"Move with the left stick, or tap a vacant room to walk through its doorway and claim it.\n\nTap your bed to walk near it and sleep. Interact also works inside rooms. Gold starts while sleeping; you cannot leave the bed afterward.\n\nTap a marked floor pad, choose a building, then Confirm. Tap Cancel to leave without spending. Tap a machine to see its effect, upgrade cost or why it is unavailable.\n\nBed and Door buttons open upgrades. Repair spends gold to heal an intact damaged door. A Dynamo makes electricity for advanced purchases.\n\nMap switches the whole dorm / focused room. Pause freezes the match. Android Back cancels placement, closes a panel, then pauses.\n\nDefeat the hunter to win. Your elimination loses. Earn rank XP and equip one unlocked reward for your next match.",Vector2(8,0),Vector2(1110,640),24,body)
 large(ui,"Back",Vector2(56,614),ui.show_menu,350)

func match_layout(ui):
 ui.current_screen="match"
 for child in ui.panel.get_children():
  if child is Panel and child.position==Vector2(18,12): child.mouse_filter=Control.MOUSE_FILTER_STOP
 # Keep resource/camera data shared; enlarge the actual controls, not invisible targets.
 for node in ui.panel.get_children():
  if node is Button and node.position.y==24:
   node.position.y=18
   node.size.y=60
   node.add_theme_font_size_override("font_size",22)
 ui.room_dock.position=Vector2(20,610)
 ui.room_dock.size=Vector2(1240,94)
 ui.room_dock.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.details.position=Vector2(36,615)
 ui.details.size=Vector2(1200,26)
 ui.details.add_theme_font_size_override("font_size",20)
 var buttons=[ui.room_bed_summary,ui.room_door_summary,ui.room_selected_summary,ui.quick_repair]
 for i in range(4):
  buttons[i].position=Vector2(34+i*306,644)
  buttons[i].size=Vector2(294,56)
  buttons[i].add_theme_font_size_override("font_size",20)
 ui.guide_box.position=Vector2(20,100)
 ui.guide_label.position=Vector2(34,109)
 ui.warning_box.position=Vector2(360,94)
 ui.warning_label.position=Vector2(372,104)
 stick=StickVisual.new()
 stick.owner_game=game
 stick.position=Vector2(20,412)
 stick.size=Vector2(196,196)
 stick.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.panel.add_child(stick)
 interact_button=large(ui,"Interact",Vector2(1014,500),func():
  if game.model.player()!=null: game.touch.navigate_bed()
  else: game.model.interact(),226)
 game.mobile_layout.apply()

func update_match(ui):
 if is_instance_valid(stick):
  var awake=game.model.player()==null or not game.model.player().sleeping
  stick.visible=awake and game.model.running
  interact_button.visible=awake and game.model.running and not ui.context_open
  interact_button.text="Bed / Sleep" if game.model.player()!=null else "Interact"
 if ui.context_open:
  ui.guide_box.visible=false
  ui.guide_label.visible=false
 ui.quick_repair.text="Repair %d G" % Catalog.REPAIR_COST
 for action in ui.actions:
  if action.begins_with("build:"): ui.actions[action].disabled=false

func context(ui):
 if not ui.context_open: return
 ui.context_box.position.x=838
 ui.context_box.size.x=420
 if ui.context_mode=="build":
  ui.context_box.position.y=148
  ui.context_box.size.y=450
  ui.context_title.text="BUILD · tap to choose"
  var index=0
  for node in ui.build_items:
   if node is Button:
    var col=index%3
    var row=int(index/3)
    var shift=Vector2(col*18, row*28+36)
    # Each group contains its button, illustration and labels.
    for n in range(5):
     var item=ui.build_items[index*5+n]
     if not item.has_meta("mobile_base"): item.set_meta("mobile_base",item.position)
     item.position=item.get_meta("mobile_base")+shift
    node.size=Vector2(126,166)
    if not node.has_meta("mobile_card_configured"):
     var base=node.position
     var art=ui.build_items[index*5+1]
     art.position=base+Vector2(38,6)
     art.size=Vector2(50,44)
     for n in range(2,5):
      var label=ui.build_items[index*5+n]
      label.clip_text=true
      label.add_theme_font_size_override("font_size",18)
      label.position=base+Vector2(3,[50,103,134][n-2])
      label.size=Vector2(120,48 if n==2 else 26)
      label.set_meta("mobile_base",label.position-Vector2(col*18,row*28+36))
     art.set_meta("mobile_base",art.position-Vector2(col*18,row*28+36))
     node.set_meta("mobile_card_configured",true)
    index+=1
 else:
  ui.context_box.position.y=132 if ui.context_mode=="door" else 230
  ui.context_box.size.y=466 if ui.context_mode=="door" else 368
  for button in [ui.actions.upgrade,ui.bed_button,ui.door_button,ui.actions.repair,ui.confirm_button]:
   button.position.x=14
   button.size=Vector2(392,64)
  ui.actions.upgrade.position.y=286
  ui.bed_button.position.y=286
  ui.door_button.position.y=310
  ui.actions.repair.position.y=386
  ui.confirm_button.position.y=208
  for item in ui.confirmation_items:
   if item is Button and item!=ui.confirm_button:
    item.position=Vector2(14,286)
    item.size=Vector2(392,64)
  var reason=ui.game.placement_reason() if ui.context_mode=="confirm" else ui.action_reason("upgrade") if ui.context_mode=="upgrade" else ui.action_reason(ui.context_mode)
  if ui.context_mode in ["bed","door","upgrade"] and reason!="":
   # Existing shared details already include the reason; no hover is needed.
   pass
 for label in [ui.selected_details,ui.bed_details,ui.door_details,ui.confirmation_details]:
  label.clip_text=true
  label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  label.size=Vector2(302,200 if label!=ui.confirmation_details else 150)
  if not label.has_meta("mobile_font"):
   label.add_theme_font_size_override("font_size",20)
   label.set_meta("mobile_font",true)
 for item in ui.context_box.get_children():
  if item is Button and item.text=="×":
   item.position=Vector2(350,4)
   item.size=Vector2(64,60)
 game.mobile_layout.apply()

func show_pause(ui):
 var veil=ColorRect.new()
 veil.size=Vector2(1280,720)
 veil.color=Color(0.03,0.08,0.13,0.85)
 ui.panel.add_child(veil)
 var bg=ui.box(Rect2(350,140,580,420))
 var title=ui.label_at("NIGHTWATCH PAUSED",Vector2(382,182),28,520,true)
 var subtitle=text(ui,"Tap Resume when you are ready.",Vector2(382,240),Vector2(500,60))
 var resume=large(ui,"Resume",Vector2(382,320),game.toggle_pause,516)
 var menu=large(ui,"Return to main menu",Vector2(382,414),game.return_menu,516)
 ui.pause_items=[veil,bg,title,subtitle,resume,menu]

func result_layout(ui):
 ui.current_screen="result"
 for child in ui.panel.get_children():
  if child is Label and ("No XP:" in child.text or "Difficulty +" in child.text):
   child.clip_text=true
   child.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   child.size=Vector2(548,70)
  if child is Panel: child.position=Vector2(250,24); child.size=Vector2(780,674)
  if child is Button:
   child.size=Vector2(232,72)
   child.add_theme_font_size_override("font_size",22)
   if child.text=="Restart": child.position=Vector2(274,610)
   elif child.text=="Loadout": child.position=Vector2(524,610)
   elif child.text=="Main menu": child.position=Vector2(774,610)
   else:
    child.position=Vector2(280,530)
    child.size=Vector2(720,64)
 game.mobile_layout.apply()

func tutorial_text() -> String:
 var room=game.model.player()
 if room==null: return "Tap a room, or use the stick.\nInteract claims it from inside."
 if not room.sleeping: return "Tap your bed to walk to it.\nBed / Sleep also gets you there."
 if room.buildings.is_empty(): return "Tap a floor pad, choose a card,\nthen Confirm to build."
 return "Use Bed and Door to upgrade.\nBuild a Dynamo for electricity."
