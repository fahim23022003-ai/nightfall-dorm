"""Pack the six intermediate Electric Ghost turnaround sheets."""
from pathlib import Path
import json

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "docs/evidence/visual-rebirth/phase14f/electric-intermediates"
# Ordered front, left, back, right. Foot X and near hand/far hand/mouth/chest.
# Far limbs occluded in profile use the visible adjacent palm as the deformation socket.
SHEETS = {
    2: (328,
        ((321, ((210,411),(343,270),(310,92),(321,177))),
         (909, ((788,394),(829,267),(793,91),(888,178))),
         (318, ((434,1028),(217,876),(335,716),(310,806))),
         (905, ((1012,1040),(1003,917),(1017,736),(957,802))))),
    3: (328,
        ((337, ((147,363),(453,256),(344,88),(348,175))),
         (958, ((730,356),(901,266),(866,88),(923,170))),
         (337, ((531,939),(229,849),(355,660),(337,761))),
         (933, ((1071,973),(1047,847),(1035,687),(976,775))))),
    5: (328,
        ((319, ((190,402),(526,141),(315,103),(320,187))),
         (930, ((765,397),(1054,162),(827,94),(894,186))),
         (333, ((480,1021),(119,761),(360,708),(333,788))),
         (964, ((1011,1029),(1160,772),(1045,709),(1006,793))))),
    6: (328,
        ((341, ((189,435),(446,383),(351,120),(349,206))),
         (915, ((922,409),(914,388),(864,127),(913,207))),
         (336, ((474,1040),(216,1017),(347,727),(334,816))),
         (941, ((875,1055),(901,1020),(978,744),(928,820))))),
    8: (432,
        ((228, ((105,397),(479,290),(240,122),(237,207))),
         (854, ((937,296),(763,368),(775,123),(840,201))),
         (416, ((549,1002),(177,895),(452,718),(431,797))),
         (972, ((978,1011),(1175,897),(1068,729),(1012,813))))),
    9: (328,
        ((320, ((154,375),(495,368),(338,75),(332,169))),
         (928, ((890,358),(837,367),(873,81),(918,178))),
         (319, ((488,1000),(165,1000),(349,697),(323,789))),
         (930, ((998,989),(981,972),(976,717),(932,803))))),
}
VIEWS = ("front", "left", "back", "right")
SOCKETS = ("near", "far", "face", "chest")


def pack():
    records = {}
    assets = ROOT / "assets/visual_rebirth/electric"
    assets.mkdir(exist_ok=True)
    for level, (width, points) in SHEETS.items():
        source_path = FOLDER / f"electric-l{level:02d}-source.png"
        source = Image.open(source_path).convert("RGBA")
        record = records[level] = {"source": source_path.name, "size": [width,264], "pivot": [width//2,260], "views": {}}
        for index, (view, (foot, marks)) in enumerate(zip(VIEWS, points, strict=True)):
            col, row = index % 2, index // 2
            left, right = (0, source.width//2) if col == 0 else (source.width//2, source.width)
            top, bottom = (0, source.height//2) if row == 0 else (source.height//2, source.height)
            crop = source.crop((left, top, right, bottom))
            alpha = crop.getchannel("A").point(lambda a: round(255*max(a-12,0)/243))
            crop.putalpha(alpha)
            x0,y0,x1,y1 = alpha.getbbox()
            if min(x0,y0,right-left-x1,bottom-top-y1) < 2:
                raise ValueError(f"Check source edge for L{level} {view}: {(x0,y0,x1,y1)}")
            scale = 256 / (y1-y0)
            sprite = crop.crop((x0,y0,x1,y1)).resize((round((x1-x0)*scale),256), Image.Resampling.LANCZOS)
            px = width//2-round((foot-left-x0)*scale)
            if px < 3 or px+sprite.width >= width-3:
                raise ValueError(f"Check packed border L{level} {view}: {px} + {sprite.width}")
            result = Image.new("RGBA",(width,264))
            result.alpha_composite(sprite,(px,4))
            filename = f"level_{level:02d}_{view}.png"
            result.save(assets/filename,optimize=True)
            normalized = [[px+round((x-left-x0)*scale),4+round((y-top-y0)*scale)] for x,y in marks]
            mask = result.getchannel("A")
            for socket, (x,y) in zip(SOCKETS,normalized,strict=True):
                if mask.getpixel((x,y)) < 128:
                    raise ValueError(f"Check socket for L{level} {view} {socket}: {(x,y)}")
            record["views"][view] = {"texture": filename, "socket_pixels": dict(zip(SOCKETS,normalized,strict=True)), "alpha_bbox": mask.getbbox(), "foot_anchor_x_in_source": foot}
    (FOLDER/"landmarks.json").write_text(json.dumps(records,indent=2)+"\n")


if __name__ == "__main__":
    pack()
