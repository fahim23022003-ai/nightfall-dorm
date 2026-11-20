"""Pack independently illustrated Ravager intermediate directions with Pillow."""

from prepare_hunter_turnarounds import pack_sheet

HEIGHTS = {8: 204}
SHEETS = {
    2: ((320, 972, 270, 985), (589, 590), (602, 631), ("front", "left", "back", "right")),
    3: ((341, 1021, 353, 1049), (568, 567), (687, 687), ("front", "left", "back", "right")),
    5: ((337, 1021, 358, 1052), (557, 556), (675, 696), ("front", "left", "back", "right")),
    6: ((307, 957, 308, 1021), (586, 587), (579, 644), ("front", "left", "back", "right")),
    8: ((337, 1026, 343, 1055), (555, 551), (666, 701), ("front", "left", "back", "right")),
    9: ((330, 976, 336, 980), (588, 590), (647, 658), ("front", "left", "back", "right")),
}


if __name__ == "__main__":
    for level, (centers, row_gaps, columns, views) in SHEETS.items():
        pack_sheet(
            "ravager", level, f"phase14f/ravager-directions/ravager-l{level:02d}-source.png",
            328, centers, height=HEIGHTS.get(level, 208), views=views, split_columns=columns, split_rows=row_gaps,
        )
