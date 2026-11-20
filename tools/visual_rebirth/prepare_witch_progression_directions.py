"""Repack the Phantom Witch's separately illustrated intermediate directions.

Run from the project root with Pillow installed.
"""

from prepare_hunter_turnarounds import pack_sheet

# Each sheet records the foot anchors in panel order and the clear row gap
# in its left and right columns. The 328x264 destination uses floor (164,260).
SHEETS = {
    2: ((333, 920, 348, 966), (598, 598)),
    3: ((321, 894, 351, 945), (590, 590)),
    5: ((292, 875, 332, 955), (603, 603)),
    6: ((336, 903, 348, 908), (594, 594)),
    8: ((281, 883, 349, 973), (600, 600)),
    9: ((346, 892, 337, 951), (595, 599)),
}

if __name__ == "__main__":
    for level, (foot_anchors, split_rows) in SHEETS.items():
        pack_sheet(
            "witch", level, f"phase14f/witch-directions/witch-l{level:02d}-source.png",
            328, foot_anchors, split_rows=split_rows
        )
