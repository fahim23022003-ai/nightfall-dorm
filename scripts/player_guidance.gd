class_name PlayerGuidance
extends RefCounted
var target: Control
var old_color=Color.WHITE
var learned={}
func mark(control):
 if is_instance_valid(target):target.modulate=old_color
 target=control
 if is_instance_valid(target):old_color=target.modulate;target.modulate=Color(1.14,1.08,.83)
func objective(game) -> Dictionary:
 var m=game.model;var r=m.player();var mode=game.profile.settings.get("guidance_mode","show")
 if game.tutorial_active:return {}
 if mode=="off" or m.result!="":return {}
 if m.run_kind=="endless" and m.endless.phase=="intermission":return {"text":"Wave cleared. Review → prepare → choose aid → continue.","key":"wave"}
 if mode=="minimal":return {}
 if r==null:return {"text":"Claim an empty room · walk inside, then E.","key":"claim"}
 if not r.sleeping:return {"text":"Sleep to earn Gold · approach your bed, then E.","key":"sleep"}
 var weapons=r.buildings.values().any(func(b):return b.kind in DefenseEffects.WEAPONS)
 if not weapons:return {"text":"Defend your door · Build [B], then select a turret. Use [O] to inspect range.","key":"build"}
 if r.electricity<=0 and not r.buildings.values().any(func(b):return b.kind=="generator") and not learned.has("dynamo"):
  return {"text":"Build a Dynamo for Electricity. Beds produce Gold; Dynamos do not attack.","key":"dynamo"}
 if r.buildings.values().any(func(b):return b.kind=="generator"):learned.dynamo=true
 if r.door_hp>0 and r.door_hp<r.max_hp()*.35:
  var wallet=game.item_wallet();var loadout=wallet.active_match.get("items",[])
  if "repair" in loadout and int(wallet.inventory.get("repair",0))>0 and m.items.can_activate("repair",m)=="":return {"text":"Repair kit equipped · use [%d] if needed. One stock is spent only on success." % (loadout.find("repair")+1),"key":"item","slot":loadout.find("repair")}
 if r.door_hp>0 and r.door_hp<r.max_hp()*.65 and r.gold>=r.manual_repair_cost():return {"text":"Your door needs attention · repair [R] when safe. Watch the danger warning.","key":"repair"}
 if m.run_kind=="endless" and r.buildings.size()>=r.tile_count() and r.tile_count()<16:return {"text":"Room full · inspect Expand room for more usable floor. Move [V] / undo [Z] during preparation.","key":"expand"}
 return {}
func tutorial_target(game):
 var fx=game.onboarding;var ui=game.ui
 match fx.step:
  3:return ui.gold_label
  4:return ui.actions.get("build:generator") if ui.context_open and ui.context_mode=="build" else ui.room_selected_summary
  5:return ui.actions.get("build:turret") if ui.context_open and ui.context_mode=="build" else ui.room_selected_summary
  6:
   if fx.upgraded:return ui.quick_repair
   var r=game.model.player()
   if r!=null and r.buildings.has(game.selected_tile) and r.buildings[game.selected_tile].kind in ["turret","heavy"]:return ui.actions.get("upgrade") if ui.context_open else ui.bottom_context.upgrade_shortcut
   return null
  8:return fx.continue_button
 return null
func refresh(game):
 var ui=game.ui
 if game.mobile_mode or game.mode!="match" or ui.current_screen!="match":mark(null);return
 if is_instance_valid(ui.items_ui.item_toggle):ui.items_ui.item_toggle.modulate=Color(.72,.76,.79) if game.tutorial_active else Color.WHITE
 if game.tutorial_active:
  mark(tutorial_target(game));ui.guide_box.visible=false;ui.guide_label.visible=false;return
 ui.guide_box.position=Vector2(20,145);ui.guide_box.size=Vector2(330,280 if ui.help_open else 102);ui.guide_label.position=Vector2(34,158);ui.guide_label.size=Vector2(300,250 if ui.help_open else 80)
 var next=objective(game);var control=null
 if not next.is_empty():
  match next.key:
   "build","dynamo":control=ui.room_selected_summary
   "repair":control=ui.quick_repair
   "item":control=ui.items_ui.hotbar[next.slot] if next.slot<ui.items_ui.hotbar.size() else ui.items_ui.item_toggle
   "expand":control=ui.expansion_ui.shortcut if ui.context_open else ui.room_selected_summary
 mark(control)
 if not next.is_empty() and not ui.help_open and game.presentation.clock>=ui.feedback_until and not ui.context_open:
  ui.guide_box.position=Vector2(20,145);ui.guide_box.size=Vector2(330,102);ui.guide_label.position=Vector2(34,158);ui.guide_label.size=Vector2(300,80)
  ui.guide_box.visible=true;ui.guide_label.visible=true;ui.guide_label.text=next.text
