#!/usr/bin/env bash
# Run from the repository root with ImageMagick 7.
set -euo pipefail

source_dir="docs/evidence/visual-rebirth/witch-directional"
output_dir="assets/visual_rebirth/witch"
turnaround="$source_dir/witch-turnaround-source.png"
oblique="$source_dir/witch-oblique-source.png"
mkdir -p "$output_dir"

# Preserve the original RGBA art inside each crop. Resize each figure to
# 256 pixels and place its lowest foot at the shared floor pivot (108, 260).
# Source crop boxes and offsets refer to the archived, fixed source images.
pack() {
    local source=$1 crop=$2 x_offset=$3 direction=$4
    magick -size 216x264 xc:none \
        \( "$source" -crop "$crop" +repage -filter Lanczos -resize x256 \) \
        -geometry "+$x_offset+4" -compose Over -composite -strip \
        "PNG32:$output_dir/level_01_$direction.png"
}

pack "$turnaround" '361x610+153+7'    39 front
pack "$turnaround" '405x603+725+11'   35 left
pack "$turnaround" '379x605+134+635'  27 back
pack "$turnaround" '398x605+750+635'   9 right
pack "$oblique"    '879x1465+41+54'  36 oblique
