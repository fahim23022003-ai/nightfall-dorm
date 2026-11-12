class_name GothicTheme
extends RefCounted
# Original cached material artwork. Textures are generated once, never per redraw.
static var materials: Dictionary={}
static func surface(fill: String,edge: String,role: String="panel") -> StyleBoxTexture:
 var accent=Color(edge)
 var danger=Color(fill).r>Color(fill).g*1.35 and Color(fill).r>.25
 var glass=role=="panel" and fill in ["203747","172839","182B3A","182B3A"]
 var family="alarm" if danger else "gold" if accent.r>.7 and accent.g>.5 and accent.b<.7 else "blue" if accent.b>accent.r*1.12 and accent.g>accent.r*1.1 else "violet" if accent.b>accent.g*1.1 and accent.b>.6 else "green" if accent.g>accent.r*1.12 and accent.g>accent.b*1.08 else "neutral"
 var key=role+":"+family+(":glass" if glass else "")
 if materials.has(key):return materials[key]
 accent={"alarm":Color("BC626B"),"gold":Color("B49C6E"),"blue":Color("839FA9"),"violet":Color("A28EB2"),"green":Color("91AA91"),"neutral":Color("93998B")}[family]
 var base=Color("302329") if danger else Color("22292B") if role.begins_with("button") else Color("171C22")
 if role.begins_with("primary_"):
  base=Color("273B32");accent=Color("C4B27D")
 if role=="button_hover":base=Color("35443F");accent=Color("ADC4AE")
 if role=="button_pressed":base=Color("131B1B")
 if role=="button_disabled":base=Color("1C2023");accent=Color("535B5B")
 if role=="button_focus":base=Color("293A35");accent=Color("B8C3A3")
 if role.begins_with("mode_"):
  base=Color("271D33") if "endless" in role else Color("3A2228") if "hell" in role else Color("292538") if "hard" in role else Color("25332E")
  accent=Color("BF88B5") if "endless" in role else Color("CD8A6A") if "hell" in role else Color("B3A3CC") if "hard" in role else Color("A4B99E")
  if role.ends_with("hover"):base=base.lightened(.07)
  if role.ends_with("selected"):base=base.lightened(.035);accent=accent.lightened(.15)
 if danger:accent=Color("BC626B")
 # Antique-metal edge is deliberately restrained; rarity remains an icon/detail accent.
 accent=accent.lerp(Color("9C9685"),.58)
 var image=Image.create(256,128,false,Image.FORMAT_RGBA8)
 for y in range(128):
  for x in range(256):
   var edge_dist=mini(mini(x,255-x),mini(y,127-y))
   var grain=float(posmod(x*37+y*71+x*y*3,23)-11)/1600.0
   var light=.048*(1-float(y)/128)+.016*sin(float(x)/43)+grain
   var color=base.lightened(light) if light>0 else base.darkened(-light)
   if y<17:color=color.lightened(.045*(1-float(y)/17))
   if glass and y>17 and y<112 and posmod(x+y*2,113)<3:color=color.lightened(.012)
   if role=="panel" and y>106:color=color.darkened(.06)
   if edge_dist==0:color=Color("080C11")
   elif edge_dist==1:color=accent.darkened(.42)
   elif edge_dist==2:color=accent.lightened(.1) if y<64 else accent.darkened(.6)
   elif edge_dist==3:color=Color("0B1016")
   elif edge_dist==6:color=accent.darkened(.75)
   if y==12 and x>17 and x<238:color=accent.darkened(.65)
   if role.begins_with("primary_") and (x in [9,10,11] or x in [244,245,246]) and y>15 and y<113:color=accent.darkened(.2)
   if role=="primary_hover":color=color.lightened(.045)
   if role=="primary_pressed":color=color.darkened(.06)
   if role=="primary_disabled":color=color.darkened(.15)
   if role.begins_with("mode_endless"):
    if y>16 and y<108:color=color.lerp(Color("4E2538") if x<90 else Color("322544"),.2*(1-float(y)/128))
    if y in [13,114] and x>23 and x<232:color=Color("795579").darkened(.25)
   if x in [10,245] and y in [10,117]:color=accent
   if x in [11,246] and y in [11,118]:color=Color("05080D")
   # Fine worn hatch along the protected outer edge, leaving the label center quiet.
   if edge_dist>6 and edge_dist<10 and posmod(x+y,17)<2:color=color.lightened(.09)
   if role.begins_with("button_") or role.begins_with("primary_") or role.begins_with("mode_"):
    # Raised rail, deep cast shadow and bright upper chamfer read at actual 44px.
    if y>=125:color=Color(.015,.025,.035,.48-float(y-125)*.1)
    elif y>=122:color=base.darkened(.32)
    if y in [4,5,6] and x>8 and x<248:color=accent.lightened(.24 if role.ends_with("hover") else .08)
    if y in [120,121] and x>8 and x<248:color=base.darkened(.5)
    if x<3 or x>252:color=color.darkened(.2)
    if x in [3,4,251,252] and y>16 and y<103:color=accent.darkened(.2 if role.ends_with("hover") else .55)
    if role.ends_with("pressed"):color=color.darkened(.15)
    if role.ends_with("focus"):
     if edge_dist>4 and edge_dist<8:color=Color("D8D6AF")
     elif edge_dist>=8:color.a=0
   image.set_pixel(x,y,color)
 var style=StyleBoxTexture.new();style.texture=ImageTexture.create_from_image(image)
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  style.set_texture_margin(side,14)
  style.set_content_margin(side,4 if (role.begins_with("button_") or role.begins_with("primary_")) and side in [SIDE_TOP,SIDE_BOTTOM] else 8)
 if role.ends_with("pressed"):
  style.set_content_margin(SIDE_TOP,7);style.set_content_margin(SIDE_BOTTOM,1)
 materials[key]=style
 return style
static func make_theme(font: Font) -> Theme:
 var theme=Theme.new();theme.default_font=font;theme.default_font_size=18
 for state in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(state,"Button",surface("22292B","938876","button_"+state))
 theme.set_color("font_color","Button",Color("EEE8D9"));theme.set_color("font_disabled_color","Button",Color("92968F"))
 theme.set_color("font_color","Label",Color("E7E3D8"))
 for state in ["normal","pressed","hover","disabled"]:theme.set_color("font_"+state+"_color","CheckButton",Color("E7E3D8"))
 theme.set_stylebox("panel","Panel",surface("171C22","938876"))
 theme.set_stylebox("background","ProgressBar",surface("15191D","656C68"))
 var fill=StyleBoxFlat.new();fill.bg_color=Color("9D7C4C");fill.set_corner_radius_all(3);theme.set_stylebox("fill","ProgressBar",fill)
 var rail=StyleBoxFlat.new();rail.bg_color=Color("4A4D49");rail.content_margin_top=3;rail.content_margin_bottom=3;theme.set_stylebox("slider","HSlider",rail)
 var fillrail=StyleBoxFlat.new();fillrail.bg_color=Color("94AA95");fillrail.content_margin_top=3;fillrail.content_margin_bottom=3
 theme.set_stylebox("grabber_area","HSlider",fillrail);theme.set_stylebox("grabber_area_highlight","HSlider",fillrail)
 for checked in [false,true]:
  var icon=Image.create(46,24,false,Image.FORMAT_RGBA8);icon.fill(Color.TRANSPARENT)
  for y in range(24):
   for x in range(46):
    var center=Vector2(12 if not checked else 34,12)
    var pill=Vector2(clampf(x,12,34),12)
    if Vector2(x,y).distance_to(pill)<11:icon.set_pixel(x,y,Color("38463F") if checked else Color("242B2D"))
    if Vector2(x,y).distance_to(center)<8:icon.set_pixel(x,y,Color("BAC8A7") if checked else Color("92998C"))
  var tex=ImageTexture.create_from_image(icon)
  theme.set_icon("checked" if checked else "unchecked","CheckButton",tex)
  theme.set_icon("checked_disabled" if checked else "unchecked_disabled","CheckButton",tex)
 return theme
