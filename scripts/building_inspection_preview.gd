extends Control
# Enlarged production art lives in the intentional drawer, never over other pads.
var ui
var profile
func _draw():
 if ui==null or not ui.context_open:return
 profile=ui.game.profile
 var room=ui.game.model.player()
 if room==null:return
 var kind="";var level=1;var branch=""
 if ui.context_mode=="upgrade" and room.buildings.has(ui.game.selected_tile):
  var b=room.buildings[ui.game.selected_tile];kind=b.kind;level=b.level;branch=b.get("specialization","")
 elif ui.context_mode=="bed":kind="bed";level=room.bed_level+1;branch=room.bed_branch
 elif ui.context_mode=="door":kind="door";level=room.door_level+1;branch=room.door_branch
 if kind=="":return
 draw_style_box(GothicTheme.surface("16232D","647D87","button_normal"),Rect2(0,0,178,154))
 ui.game.presentation.building_visual.draw(self,ui.game.presentation,kind,level,Vector2(89,122),branch,0,Vector2.UP,0,0,1.85 if kind not in ["bed","door"] else 1.25)
