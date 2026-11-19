"""Bake the dormitory bed's woodwork and quilt at every obtainable level."""
from functools import partial
from math import ceil, cos, pi, sin
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, bake_atlas
from bake_needle import PALETTE

MATERIALS = PALETTE | {
    "oak": (.278, .147, .081, 1),
    "polished_oak": (.398, .225, .108, 1),
    "wool": (.29, .060, .074, 1),
    "linen": (.67, .56, .41, 1),
    "lining": (.16, .074, .091, 1),
    "conductive": (.30, .60, .64, 1),
    "copper": (.47, .25, .13, 1),
}
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("lucid", "conductor") for level in range(6, 11)]
OUT = Path("assets/visual_rebirth/buildings/bed")


def drape(model, width, length, start_y, z, material, sag, depth):
    columns, rows = 14, 18
    vertices, faces = [], []
    for row in range(rows + 1):
        v = row / rows
        for column in range(columns + 1):
            u = column / columns
            x = (u-.5)*width
            y = start_y-v*length
            edge = min(1.0, max(0.0, (abs(u-.5)-.39)/.11))
            front = min(1.0,max(0.0,(v-.83)/.17))
            fold = depth*(cos(u*pi*9+v*4)+.33*cos(v*pi*8-u*4))
            vertices.append((x, y, z+fold-sag*max(edge,front)))
            if column < columns and row < rows:
                index = row*(columns+1)+column
                faces.append((index,index+columns+1,index+columns+2,index+1))
    model.add(vertices, faces, material, smooth=True)


def board(model, y, z, width, height, material):
    spans = 16
    vertices = []
    for depth in (-.052,.052):
        for index in range(spans+1):
            x = width*(index/spans-.5)
            crown = .59+.41*cos(pi*x/width)**2
            vertices.extend(((x,y+depth,z),(x,y+depth,z+height*crown)))
    n = 2*(spans+1)
    faces = []
    for index in range(spans):
        at = 2*index
        faces.extend(((at,at+2,at+3,at+1), (n+at,n+at+1,n+at+3,n+at+2),
                      (at+1,at+3,n+at+3,n+at+1), (at,n+at,n+at+2,at+2)))
    faces.extend(((0,1,n+1,n),(n-2,2*n-2,2*n-1,n-1)))
    model.add(vertices,faces,material)


def post(model, x, y, top, size, color):
    model.cylinder((x,y,.03),(x,y,top),size,size*.83,color,10)
    for z in (.16,top-.19):
        model.ring((x,y,z),size*.92,.021,"bronze",sides=14)
    model.cylinder((x,y,top),(x,y,top+.069),size*.95,size*.42,"bronze",10)


def bed(model, level, branch):
    width, length = 1.26, 1.92
    head_y, foot_y = .80, -1.02
    model.box(0,-.10,.31,width,length,.18,"oak")
    model.box(0,-.10,.425,width*.94,length*.94,.149,"linen")
    model.box(0,.51,.526,.77,.38,.126,"linen")
    drape(model,width*1.10,1.57,.56,.58,"wool",.18,.037)
    for side in (-1,1):
        x = side*.63
        model.box(x,-.10,.27,.074,length+.08,.102,"polished_oak")
        post(model,x,head_y,1.04 if level<4 else 1.24,.063,"oak")
        post(model,x,foot_y,.45 if level<3 else .69,.063,"oak")
    board(model,head_y,.39,1.24,.67 if level<4 else .90,"oak" if level<4 else "iron")
    board(model,foot_y,.26,1.26,.28 if level<3 else .52,"oak")
    if level >= 2:
        for x in (-.40,0,.40):
            model.box(x,foot_y-.067,.24,.068,.039,.35,"bronze")
        for x in (-.67,.67):
            model.cylinder((x,foot_y,.23),(x*1.15,foot_y-.16,.057),.078,.052,"iron",8)
            model.box(x*1.08,-.15,.255,.108,1.49,.103,"polished_oak")
    if level >= 3:
        for x in (-.49,.49):
            model.cylinder((x,foot_y-.083,.37),(x*.62,foot_y-.083,.63),.038,.018,"polished_oak",8)
        board(model,foot_y-.065,.37,1.39,.59,"polished_oak")
        for x in (-.69,.69):
            post(model,x,foot_y,.80,.082,"polished_oak")
    if level >= 4:
        board(model,head_y,.46,1.38,1.17,"iron")
        for x in (-.40,0,.40):
            model.ring((x,head_y-.086,1.10),.141,.023,"bronze",(0,-1,0),sides=16)
    if level >= 5:
        for x in (-.77,.77):
            model.cylinder((x,.67,.44),(x,.67,1.48),.054,.038,"iron",8)
            model.ring((x,.65,1.47),.113,.031,"bronze",(0,-1,0),sides=14)
    if level >= 6:
        model.box(0,foot_y-.082,.38,1.15,.07,.124,"iron")
        model.ring((0,foot_y-.12,.57),.155,.033,"bronze",(0,-1,0),sides=18)
        for x in (-.69,.69):
            model.cylinder((x,foot_y,.45),(x*1.22,foot_y-.064,.78),.065,.050,"iron",10)
    if level >= 7:
        for x in (-.62,.62):
            post(model,x,head_y,1.98,.066,"oak")
            model.cylinder((x,head_y,1.88),(x,-.28,1.88),.040,.036,"iron",8)
        board(model,head_y,1.63,1.3,.40,"iron")
        drape(model,1.22,.47,.78,1.91,"lining",.28,.028)
    if level >= 8:
        for x in (-.56,.56):
            model.cylinder((x,.42,1.88),(x,.42,1.12),.030,.018,"bronze",8)
            model.ring((x,.42,1.14),.074,.020,"bronze",(0,-1,0),sides=14)
            model.cylinder((x,.43,1.86),(x*1.37,.19,1.63),.048,.032,"bronze",8)
            model.cylinder((x*1.37,.19,1.63),(x*1.41,.19,1.31),.055,.027,"bronze",8)
    if level >= 9:
        for x in (-.69,.69):
            model.cylinder((x,-.23,.31),(x,-.23,1.85),.044,.036,"iron",8)
            model.cylinder((x,-.23,1.78),(x,.30,1.97),.052,.039,"bronze",8)
        drape(model,1.37,.85,.65,1.99,"lining",.20,.023)
    if level == 10:
        for x in (-.64,.64):
            model.cylinder((x,-.25,1.88),(0,-.25,2.20),.057,.038,"bronze",10)
        board(model,-.32,1.88,1.58,.68,"iron")
        model.ring((0,-.42,2.45),.126,.033,"bronze",(0,-1,0),sides=18)
        for x in (-.64,.64):
            model.cylinder((x,-.25,1.85),(x*.89,-.63,2.13),.065,.039,"iron",10)
            model.cylinder((x*.89,-.63,2.13),(0,-.63,2.36),.042,.027,"bronze",10)
    if branch == "lucid":
        model.box(0,foot_y-.15,.42,.52,.16,.183,"polished_oak")
        for x in (-.16,.16):
            model.ring((x,foot_y-.24,.52),.095,.026,"gold",(0,-1,0),sides=16)
    elif branch == "conductor":
        for x in (-.61,.61):
            model.cylinder((x,foot_y-.04,.37),(x,foot_y-.04,.88),.084,.063,"copper",12)
            for n in range(3):
                model.ring((x,foot_y-.04,.5+n*.11),.088,.024,"conductive",sides=16)


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True, parents=True)
    bake_atlas(OUT / "base.png", MATERIALS, BASE_COLUMNS, ceil(len(STATES)/BASE_COLUMNS), (
        (index % BASE_COLUMNS, index // BASE_COLUMNS, partial(bed, level=level, branch=branch))
        for index, (level, branch) in enumerate(STATES)
    ))
