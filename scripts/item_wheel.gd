extends Control
var angle=0.0:
 set(value): angle=value; queue_redraw()
var icons=[]
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 for id in ItemCatalog.IDS: icons.append(load("res://assets/items/"+id+".svg"))
func _draw():
 var center=Vector2(210,190)
 draw_circle(center,166,Color("101D2B"))
 draw_arc(center,166,0,TAU,96,Color("E5BE73"),4)
 for i in range(ItemCatalog.IDS.size()):
  var a=angle+i*TAU/ItemCatalog.IDS.size()-PI/2
  var point=center+Vector2.from_angle(a)*123
  draw_circle(point,18,Color("30475E"))
  draw_arc(point,18,0,TAU,32,Color(ItemCatalog.ITEMS[ItemCatalog.IDS[i]].color),2)
  if i<icons.size(): draw_texture_rect(icons[i],Rect2(point-Vector2(15,15),Vector2(30,30)),false)
 draw_colored_polygon(PackedVector2Array([Vector2(192,3),Vector2(228,3),Vector2(210,27)]),Color("FFE092"))
 draw_circle(center,40,Color("7B4F93"))
 draw_arc(center,40,0,TAU,32,Color("E5BE73"),3)
 draw_string(ThemeDB.fallback_font,center+Vector2(-25,6),"LUCK",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("FFE7AE"))
