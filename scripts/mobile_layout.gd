class_name DormMobileLayout
extends RefCounted

var game
var safe_rect=Rect2(0,0,1280,720)
var scale_factor=1.0
var origin=Vector2.ZERO
var safe_override=Rect2()

func _init(owner_game): game=owner_game

static func fit(viewport_size: Vector2,safe: Rect2) -> Dictionary:
 var available=safe.intersection(Rect2(Vector2.ZERO,viewport_size))
 if available.size.x<=0 or available.size.y<=0: available=Rect2(Vector2.ZERO,viewport_size)
 var factor=minf(available.size.x/1280.0,available.size.y/720.0)
 return {"scale":factor,"origin":available.get_center()-Vector2(640,360)*factor,"safe":available}

func apply():
 if not is_instance_valid(game.ui) or not is_instance_valid(game.ui.panel): return
 if not game.mobile_mode: return
 var viewport=game.get_viewport()
 var size=viewport.get_visible_rect().size
 var area=Rect2(Vector2.ZERO,size)
 if safe_override.size!=Vector2.ZERO: area=safe_override
 elif OS.get_name()=="Android":
  var physical=DisplayServer.get_display_safe_area()
  var window=Rect2i(DisplayServer.window_get_position(),DisplayServer.window_get_size())
  var clipped=physical.intersection(window)
  if clipped.size.x>0 and clipped.size.y>0:
   var inverse=viewport.get_screen_transform().affine_inverse()
   area=Rect2(inverse*Vector2(clipped.position),Vector2(clipped.size)/viewport.get_screen_transform().get_scale())
 var result=fit(size,area)
 safe_rect=result.safe
 scale_factor=result.scale
 origin=result.origin
 game.ui.panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 game.ui.panel.position=origin
 game.ui.panel.scale=Vector2.ONE*scale_factor
 game.ui.panel.size=Vector2(1280,720)

func screen_point(design: Vector2) -> Vector2:
 return origin+design*scale_factor
