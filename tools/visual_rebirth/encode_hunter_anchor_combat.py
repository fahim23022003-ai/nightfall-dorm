"""Encode finished Godot capture frames into one chaptered MP4 per Hunter."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess


def encode(captures, destination):
    metadata = captures / "anchor-motion.json"
    record = json.loads(metadata.read_text(encoding="utf-8"))
    levels = [segment["level"] for segment in record["segments"]]
    if not levels or levels != sorted(set(levels)) or any(not 1 <= level <= 10 for level in levels):
        raise ValueError("Capture must contain a nonempty, sorted set of evolution levels")
    fps = record["fps"]
    destination.mkdir(parents=True, exist_ok=True)
    chapter_path = captures / "chapters.ffmeta"
    chapters = [";FFMETADATA1"]
    inputs = []
    position = 0
    for segment in record["segments"]:
        level = segment["level"]
        frames = captures / f"l{level:02}" / "frames"
        filenames = sorted(frames.glob("*.png"))
        count = segment["frame_count"]
        expected = [frames / f"{frame:04}.png" for frame in range(count)]
        if filenames != expected:
            raise ValueError(f"Capture frame inventory differs at L{level}")
        inputs += ["-framerate", str(fps), "-i", str(frames / "%04d.png")]
        chapters.extend(["[CHAPTER]", f"TIMEBASE=1/{fps}", f"START={position}", f"END={position + count}", f"title=Level {level}"])
        position += count
    chapter_path.write_text("\n".join(chapters) + "\n", encoding="utf-8")

    archetype = record["archetype"]
    output = destination / f"{archetype}-anchors.mp4"
    joins = "".join(f"[{index}:v]" for index in range(len(record["segments"])))
    filters = f"{joins}concat=n={len(record['segments'])}:v=1:a=0[video]"
    subprocess.run([
        "ffmpeg", "-loglevel", "error", "-y", *inputs, "-i", str(chapter_path),
        "-filter_complex", filters, "-map", "[video]", "-map_metadata", str(len(record["segments"])),
        "-map_chapters", str(len(record["segments"])), "-c:v", "libx264", "-crf", "19",
        "-preset", "fast", "-threads", "2", "-pix_fmt", "yuv420p", "-r", str(fps),
        "-movflags", "+faststart", str(output),
    ], check=True)
    result = subprocess.run([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height,r_frame_rate,nb_frames,duration",
        "-of", "json", str(output),
    ], check=True, capture_output=True, text=True)
    stream = json.loads(result.stdout)["streams"][0]
    if [stream["width"], stream["height"]] != record["viewport"] or int(stream["nb_frames"]) != position:
        raise ValueError(f"Encoded frame count or viewport differs for {archetype}")
    shutil.copyfile(metadata, destination / f"{archetype}-anchors.json")
    print(f"{archetype}: {position} frames, {stream['duration']} seconds")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    encode(args.captures, args.destination)


if __name__ == "__main__":
    main()
