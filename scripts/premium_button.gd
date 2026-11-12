class_name PremiumButton
extends RefCounted
static var icons: Dictionary={}
static func action(text: String) -> String:
 var t=text.to_lower()
 if "expand" in t or "expansion" in t:return "expansion"
 if "endless" in t:return "endless"
 if "challenge" in t:return "challenge"
 if "practice" in t:return "practice"
 if "cosmetic" in t or "appearance" in t:return "cosmetic"
 if "lose" in t or "analysis" in t:return "analysis"
 if t.begins_with("start") or t.begins_with("confirm") or t.begins_with("play"):return "play"
 if "shop" in t or t.begins_with("buy"):return "shop"
 if "inventory" in t or t.begins_with("items"):return "inventory"
 if "loadout" in t or "equip" in t:return "loadout"
 if "rank" in t:return "rank"
 if "achievement" in t or "claim" in t:return "achievement"
 if "tutorial" in t or "how to" in t or "help"==t:return "tutorial"
 if "setting" in t:return "settings"
 if "pause" in t or text=="Ⅱ":return "pause"
 if "retry" in t or "replay" in t:return "retry"
 if "repair" in t:return "repair"
 if "upgrade" in t:return "upgrade"
 if "sell" in t:return "sell"
 if "build" in t or "pad" in t:return "build"
 if "contract" in t:return "contract"
 if "stage" in t or "continue" in t or "back" in t or "prepare" in t:return "next"
 return ""
static func texture(id: String) -> Texture2D:
 if not icons.has(id):icons[id]=load("res://assets/premium_ui/"+id+".svg")
 return icons[id]
static func decorate(button: Button,reduced: bool=false):
 var id=action(button.text)
 if id!="" and button.size.y>=34 and (button.size.x>=160 or id=="pause"):
  button.icon=texture(id);button.expand_icon=true
  button.add_theme_constant_override("icon_max_width",22 if button.size.x<=180 else 28 if button.size.y>=44 else 22)
  button.add_theme_constant_override("h_separation",6 if button.size.x<=180 else 12 if button.size.y>=44 else 8)
  button.clip_text=true
  button.set_meta("action_icon",id)
  if button.size.y<40:button.add_theme_font_size_override("font_size",15)
 var tween_holder={"tween":null}
 var animate=func(bright: bool):
  if tween_holder.tween!=null and tween_holder.tween.is_valid():tween_holder.tween.kill()
  var tint=Color(1.13,1.12,1.06) if bright and not button.disabled else Color.WHITE
  if reduced:button.self_modulate=tint
  else:tween_holder.tween=button.create_tween();tween_holder.tween.tween_property(button,"self_modulate",tint,.12)
 button.mouse_entered.connect(func():animate.call(true))
 button.mouse_exited.connect(func():animate.call(button.has_focus()))
 button.focus_entered.connect(func():animate.call(true))
 button.focus_exited.connect(func():animate.call(false))
