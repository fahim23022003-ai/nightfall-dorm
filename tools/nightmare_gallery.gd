extends Node2D
# Runtime art inspector only. Uses the same production renderer, not a mockup.
var game
var profile
var mode="levels"
var level=1
var kinds=[]
var font=preload("res://assets/fonts/Interface.ttf")
func _draw():
 draw_rect(Rect2(0,0,1280,720),Color("111923"))
 draw_string(font,Vector2(24,30),"NIGHTMARE REBIRTH · GODOT RUNTIME ART INSPECTOR",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("DEC798"))
 draw_string(font,Vector2(24,54),"Production modular renderer · controlled inspection, not a match · all levels preserve gameplay prices/statistics",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("A9BCC7"))
 if mode=="all":
  for i in range(kinds.size()):
   var kind=kinds[i];var point=Vector2(125+(i%5)*245,143+int(i/5)*143)
   draw_rect(Rect2(point-Vector2(105,76),Vector2(212,137)),Color("1D2B37"))
   var branches=StrategyCatalog.branches(kind);var branch=branches[0] if level>=5 and not branches.is_empty() else ""
   game.presentation.building_visual.draw(self,game.presentation,kind,level,point,branch,0,Vector2(0,-1),0)
   draw_string(font,point+Vector2(-100,58),(Catalog.BUILDINGS[kind].name if kind in Catalog.BUILDINGS else kind.capitalize())+" · L%d" % level,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("DBD2BD"))
 else:
  var rows=kinds
  for row in range(rows.size()):
   var kind=rows[row];var pitch=35 if mode=="matrix" else 180
   var base=122 if mode=="matrix" else 175
   draw_string(font,Vector2(10,base+row*pitch),Catalog.BUILDINGS[kind].name if kind in Catalog.BUILDINGS else kind.capitalize(),HORIZONTAL_ALIGNMENT_LEFT,-1,9 if mode=="matrix" else 13,Color("D8C6A7"))
   for lv in range(1,11):
    var point=Vector2(220+(lv-1)*107,base-10+row*pitch)
    var factor=(.28 if kind in ["bed","door"] else .4) if mode=="matrix" else .9
    var branches=StrategyCatalog.branches(kind);var branch=branches[0] if lv>=5 and not branches.is_empty() else ""
    game.presentation.building_visual.draw(self,game.presentation,kind,lv,point,branch,0,Vector2(0,-1),0,0,factor)
    if row==0:draw_string(font,Vector2(point.x-8,78),str(lv),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("E7CB99"))
