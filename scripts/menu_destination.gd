class_name MenuDestination
extends Button
# Menu-only silhouettes, all children are non-interactive; the whole card is a button.
var silhouette="plaque"
var accent=Color("C8B686")
func _ready():
 mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw)
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 button_down.connect(queue_redraw);button_up.connect(queue_redraw)
func _draw():
 var bright=is_hovered() or has_focus()
 var edge=accent.lightened(.24) if bright else accent
 var fill=Color("34362F") if bright else Color("20282B")
 if is_pressed():fill=Color("121C20")
 var box=StyleBoxFlat.new();box.bg_color=fill;box.border_color=edge;box.set_border_width_all(2)
 box.set_corner_radius_all(14)
 if silhouette=="start":
  box.corner_radius_top_left=42;box.corner_radius_top_right=42;box.corner_radius_bottom_left=18;box.corner_radius_bottom_right=18
 elif silhouette=="inventory":box.set_corner_radius_all(24)
 elif silhouette=="rank":
  var points=PackedVector2Array([Vector2(3,2),Vector2(size.x-3,2),Vector2(size.x-3,size.y-26),Vector2(size.x*.5,size.y-2),Vector2(3,size.y-26)])
  draw_colored_polygon(points,fill);draw_polyline(points+PackedVector2Array([points[0]]),edge,2,true)
 if silhouette!="rank":draw_style_box(box,Rect2(Vector2(2,2),size-Vector2(4,4)))
 if silhouette=="shop":
  for i in range(7):
   var width=(size.x-16)/7
   var canopy=Rect2(8+i*width,6,width,18)
   draw_rect(canopy,Color("78535D") if i%2==0 else Color("A7997C"))
   draw_circle(Vector2(canopy.get_center().x,24),width*.5,Color("78535D") if i%2==0 else Color("A7997C"))
 elif silhouette=="inventory":
  draw_arc(Vector2(size.x*.5,9),21,PI,TAU,16,edge,4)
  draw_style_box(box,Rect2(15,size.y-51,size.x-30,35))
 if has_focus():
  var focus_box=StyleBoxFlat.new();focus_box.bg_color=Color.TRANSPARENT;focus_box.border_color=Color("F4E6BB");focus_box.set_border_width_all(2);focus_box.set_corner_radius_all(12)
  draw_style_box(focus_box,Rect2(Vector2(7,7),size-Vector2(14,14)))
