"""Render four original Living Nightmare cues and a sampled heartbeat.

All instruments come from the checked-in CC0 VSCO library used by the
existing score. NumPy and SciPy are offline tools. Godot plays baked PCM.
"""
import json
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, resample_poly, sosfilt

ROOT = Path(__file__).resolve().parents[2]
SAMPLES = Path(__file__).resolve().parent / "source/vsco"
OUTPUT = ROOT / "assets/audio"
RATE = 22050
INSTRUMENTS = {
    "piano": ("Keys/Upright Piano/Player_dyn1_rr1_020.wav", 61),
    "bell": ("Percussion/Glock/glock_medium_C5.wav", 72),
    "strings": ("Strings/Violin Section/susVib/VlnEns_susVib_C4_v1.wav", 60),
    "tremolo": ("Strings/Violin Section/Trem/VlnEns_Trem_C4_v1.wav", 60),
    "bass_drum": ("Percussion/BDrumNewhit_v3_rr1_Sum.wav", 36),
    "timpani": ("Percussion/Timpani/Timpani1_Hit_v3_rr1_Sum.wav", 48),
}


def load_instrument(relative_path):
    rate, samples = wavfile.read(SAMPLES / relative_path)
    samples = samples.astype(float)
    if samples.ndim == 2:
        samples = samples.mean(axis=1)
    samples = resample_poly(samples, RATE, rate)
    return samples / np.max(np.abs(samples))


class Arrangement:
    def __init__(self, duration, tempo):
        self.audio = np.zeros((round(duration * RATE), 2))
        self.beat = 60 / tempo
        self.score = []

    def note(self, instrument, pitch, beat, length, gain, pan=0.0):
        samples, natural_pitch = instruments[instrument]
        start = round(float(beat) * self.beat * RATE)
        length = min(round(float(length) * self.beat * RATE), len(self.audio) - start)
        if length <= 0:
            return
        positions = np.arange(length) * 2 ** ((pitch - natural_pitch) / 12)
        signal = np.interp(positions, np.arange(len(samples)), samples, right=0)
        attack = min(int(.035 * RATE), length // 6)
        release = min(int(.36 * RATE), length // 3)
        signal[:attack] *= np.linspace(0, 1, attack)
        signal[-release:] *= np.linspace(1, 0, release)
        weights = np.array([.75 - .25 * pan, .75 + .25 * pan])
        self.audio[start:start + length] += signal[:, None] * weights * gain
        self.score.append([instrument, pitch, round(float(beat), 3), round(float(length / RATE / self.beat), 3), gain, pan])

    def save(self, name, loop):
        dry = self.audio.copy()
        for seconds, gain in [(.123, .17), (.271, .12), (.397, .07), (.617, .045)]:
            samples = round(seconds * RATE)
            if loop:
                self.audio += np.roll(dry, samples, axis=0) * gain
            else:
                self.audio[samples:] += dry[:-samples] * gain
        return write(name, self.audio, .61, self.score, 60 / self.beat, loop)


def write(name, samples, peak, score, tempo=None, loop=False):
    samples *= peak / np.max(np.abs(samples))
    attack = int(.025 * RATE)
    release = int((.025 if loop else .42) * RATE)
    shape = (-1,) + (1,) * (samples.ndim - 1)
    samples[:attack] *= np.linspace(0, 1, attack).reshape(shape)
    samples[-release:] *= np.linspace(1, 0, release).reshape(shape)
    path = OUTPUT / f"{name}.wav"
    wavfile.write(path, RATE, np.round(samples * 32767).astype("<i2"))
    return {"name": name, "duration": len(samples) / RATE, "tempo": tempo,
            "loop": loop, "peak": float(abs(samples).max()), "score": score}


def hall():
    score = Arrangement(40, 54)
    chords = [(44, 51, 59), (46, 53, 58), (42, 49, 57), (43, 49, 58),
              (44, 51, 61), (41, 48, 56), (42, 50, 57), (43, 50, 59),
              (44, 51, 59)]
    for bar, chord in enumerate(chords):
        beat = bar * 4
        for voice, pitch in enumerate(chord):
            score.note("strings", pitch, beat + voice * .35, 4.8, .19, [-.5, .2, .55][voice])
        score.note("bell", chord[1] + 24, beat + .25, 3.1, .17, .35)
        if bar not in (3, 7):
            score.note("piano", chord[2] + 9, beat + 2.75, 2.35, .19, -.3)
        if bar in (2, 5, 7):
            score.note("piano", chord[0] - 5, beat + 1.75, 2, .34, -.2)
    return score.save("music_hall", True)


def hell():
    score = Arrangement(45, 64)
    harmony = [(38, 50, 56, 57), (39, 51, 55, 58), (35, 47, 53, 54), (36, 48, 56, 58)]
    for bar in range(12):
        beat = bar * 4
        low, anchor, tension, top = harmony[(bar // 3) % len(harmony)]
        score.note("piano", low, beat, 2.4, .36, -.25)
        score.note("piano", anchor, beat + 2.75, 1.75, .23, .25)
        score.note("tremolo", tension, beat + .35, 3.4, .21, -.45)
        score.note("strings", top, beat + 1.15, 3.25, .17, .55)
        if bar % 3 != 1:
            score.note("piano", top + 12 - (bar % 2) * 5, beat + 1.75, 1.25, .15, -.35)
            score.note("timpani", low + 8, beat + .1, 2.25, .24)
        if bar in (4, 6, 9, 11):
            score.note("bass_drum", 34, beat + 3.75, 1.6, .15)
    return score.save("music_hell", True)


def ending(victory):
    score = Arrangement(13, 58 if victory else 50)
    chord_path = ([(43, 50, 58, 62), (46, 53, 60, 65), (48, 55, 60, 67),
                   (43, 55, 62, 67)] if victory else
                  [(43, 50, 54, 59), (42, 50, 54, 57), (41, 48, 53, 56),
                   (37, 44, 49, 50)])
    timings = (0, 2.5, 5.5, 8.25)
    for index, chord in enumerate(chord_path):
        beat = timings[index]
        score.note("piano", chord[0], beat, 3.2, .33, -.35)
        for voice, pitch in enumerate(chord[1:]):
            score.note("strings", pitch, beat + .14 * voice, 3.7,
                       .21, [-.4, .05, .45][voice])
            score.note("piano", pitch + 12, beat + .3 + .52 * voice,
                       1.8, .17, [.4, .15, -.2][voice])
        if victory and index in (1, 3):
            score.note("bell", chord[-1] + 12, beat + .95, 3.1, .21, .4)
        elif not victory and index in (0, 3):
            score.note("timpani", chord[0] + 7, beat + .1, 2.3, .24)
    return score.save("music_victory" if victory else "music_defeat", False)


def heartbeat():
    beat_sample, _ = instruments["bass_drum"]
    low = sosfilt(butter(3, [36, 145], "bandpass", fs=RATE, output="sos"), beat_sample)
    low /= np.max(np.abs(low))
    audio = np.zeros(round(4.96 * RATE))
    beats = [.10, .96, 1.72, 2.40, 3.00, 3.52, 3.98, 4.41, 4.72]
    for index, time in enumerate(beats):
        power = [.48, .58, .67, .78, .90, 1.0, 1.0, .73, .40][index]
        for delay, pitch, gain in [(0.0, .84, 1.0), (.145, 1.09, .53)]:
            start = round((time + delay) * RATE)
            width = min(round(.29 * RATE), len(audio) - start)
            samples = np.interp(np.arange(width) * pitch, np.arange(len(low)), low, right=0)
            samples *= np.exp(-np.arange(width) / (RATE * .105))
            audio[start:start + width] += samples * power * gain
    return write("siege_heartbeat", audio, .66, beats)


if __name__ == "__main__":
    instruments = {name: (load_instrument(path), pitch)
                   for name, (path, pitch) in INSTRUMENTS.items()}
    arrangements = [hall(), hell(), ending(True), ending(False), heartbeat()]
    (OUTPUT / "living-score-arrangements.json").write_text(json.dumps({
        "license": "Original Nightfall Dorm arrangements using in-repository CC0 VSCO instruments",
        "source_directory": "tools/audio/source/vsco",
        "sample_rate_hz": RATE,
        "instruments": INSTRUMENTS,
        "arrangements": arrangements,
    }, indent=2) + "\n")
