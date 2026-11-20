"""Generate the original ritual cues in assets/audio (Python standard library)."""
from array import array
from math import exp, pi, sin
from pathlib import Path
from random import Random
import sys
import wave

RATE = 22050
DEST = Path(__file__).resolve().parents[2] / "assets" / "audio"
RITUALS = {
    "retreat": (2.2, 53.4, (1.0, 1.48, 2.05), .12, .21),
    "north": (4.3, 131.1, (1.0, 2.01, 2.94, 4.09), .18, .12),
    "south": (4.5, 65.1, (1.0, 1.28, 1.73, 2.33), .17, .31),
    "west": (4.2, 155.7, (1.0, 1.41, 2.33, 3.06), .11, .21),
    "east": (4.6, 91.9, (1.0, 1.52, 2.07, 3.11), .22, .16),
    "release": (1.7, 78.3, (1.0, 1.48, 2.52), .09, .11),
}


def generate(name, seconds, root, ratios, air, dissonance):
    random = Random(name)
    raw = []
    noise = 0.0
    for i in range(round(seconds * RATE)):
        t = i / RATE
        noise = .966 * noise + .034 * random.uniform(-1.0, 1.0)
        bow = sin(pi * min(1.0, t / seconds)) ** .82
        drone = sin(2 * pi * (root * t + .6 * sin(t * 1.45)))
        sound = .22 * bow * drone + noise * 3 * air * bow * (.54 + .46 * sin(t * 6.9) ** 2)
        for part, ratio in enumerate(ratios):
            start = .1 + part * .26
            age = t - start
            if age <= 0:
                continue
            edge = min(age * (45 if name in ("north", "west") else 7.0), 1.0)
            decay = exp(-age * (1.27 + part * .16))
            rate = root * ratio
            detune = dissonance * (3 + part)
            sound += .17 / (1 + part * .27) * edge * decay * (
                sin(2 * pi * (rate * age + .13 * sin(age * 4.1)))
                + .23 * sin(2 * pi * (rate * 1.81 + detune) * age)
            )
        raw.append(sound * min(1.0, t / .025, (seconds - t) / .45))
    gain = .68 / max(abs(value) for value in raw)
    samples = array("h", (round(value * gain * 32767) for value in raw))
    if sys.byteorder != "little":
        samples.byteswap()
    with wave.open(str(DEST / f"haunted_hall_{name}.wav"), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(samples.tobytes())


if __name__ == "__main__":
    for cue, recipe in RITUALS.items():
        generate(cue, *recipe)
