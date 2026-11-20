"""Pack the authored Crusher intermediate turnarounds from their source sheets."""

from prepare_hunter_turnarounds import VIEWS, pack_sheet


SOURCE_DIR = "phase14f/crusher-intermediates"
# Foot centers and any noncentral gutter are measured in the original sheets.
# L6's profiles are assigned to match their displayed facing.
SHEETS = {
    2: ((297, 938, 349, 890), VIEWS, None),
    3: ((321, 989, 348, 967), VIEWS, (575, 573)),
    5: ((349, 946, 307, 956), VIEWS, (604, 606)),
    6: ((305, 974, 331, 905), ("front", "right", "back", "left"), None),
    8: ((338, 932, 353, 945), VIEWS, None),
    9: ((369, 944, 293, 979), VIEWS, None),
}


if __name__ == "__main__":
    for level, (feet, views, split_rows) in SHEETS.items():
        source = f"{SOURCE_DIR}/crusher-l{level:02d}-source.png"
        pack_sheet("crusher", level, source, 328, feet, views=views, split_rows=split_rows)
