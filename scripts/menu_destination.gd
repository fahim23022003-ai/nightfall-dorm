class_name MenuDestination
extends Button
# Menu-only silhouettes, all children are non-interactive; the whole card is a button.
var silhouette="plaque"
var accent=Color("C8B686")
var reduced=false
var highlight=0.0:
 set(value):highlight=value;queue_redraw()
var highlight_tween: Tween
var data_key: Callable
var refresh_data: Callable
var last_data=""
var refresh_clock=0.0
func bind_data(key: Callable,refresh: Callable):
 data_key=key;refresh_data=refresh;last_data=str(data_key.call());refresh_data.call();set_process(true)
func _process(delta):
 if not data_key.is_valid():return
 refresh_clock+=delta
 if refresh_clock<.2:return
 refresh_clock=0
 var current=str(data_key.call())
 if current!=last_data:last_data=current;refresh_data.call()
func refresh_highlight():
 var target=1.0 if is_hovered() or has_focus() else 0.0
 if highlight_tween!=null and highlight_tween.is_valid():highlight_tween.kill()
 if reduced:highlight=target
 else:highlight_tween=create_tween();highlight_tween.tween_property(self,"highlight",target,.12)

func _ready():
 set_process(false)
 mouse_entered.connect(refresh_highlight);mouse_exited.connect(refresh_highlight)
 focus_entered.connect(refresh_highlight);focus_exited.connect(refresh_highlight)
 button_down.connect(queue_redraw);button_up.connect(queue_redraw)
func _draw():
 var edge=accent.lerp(accent.lightened(.24),highlight)
 var fill=Color("20282B").lerp(Color("34362F"),highlight)
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
 if silhouette=="rank":
  var center=Vector2(size.x*.5,54)
  draw_circle(center+Vector2(0,3),39,Color("111821"))
  draw_circle(center,37,Color("363443"))
  draw_arc(center,37,-PI*.95,PI*.05,32,Color("D3C6D8"),2)
  draw_arc(center,37,PI*.05,PI*1.05,32,Color("66556F"),2)
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
