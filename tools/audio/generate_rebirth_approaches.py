"""Bake original positional approach cues for the Phase 14 preview."""

from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile


RATE = 44_100
TIME = np.arange(round(2.4 * RATE)) / RATE
OUTPUT = Path(__file__).resolve().parents[2] / "assets" / "audio"


def band(source, low, high):
    return signal.sosfilt(signal.butter(2, [low, high], fs=RATE, btype="bandpass", output="sos"), source)


def swell(center, width):
    return np.exp(-0.5 * ((TIME - center) / width) ** 2)


def phase(pitch):
    return np.cumsum(pitch) * (2 * np.pi / RATE)


def glottis(pitch):
    angle = phase(pitch)
    return sum(np.sin(harmonic * angle) / harmonic**1.3 for harmonic in range(1, 13))


def crusher(noise):
    breath = band(noise, 110, 810) * (swell(0.45, 0.20) + 0.8 * swell(1.32, 0.38))
    iron = np.zeros_like(TIME)
    for index, onset in enumerate((0.33, 0.46, 1.02, 1.11, 1.30, 1.65, 1.72)):
        age = np.maximum(TIME - onset, 0)
        strike = (TIME >= onset) * np.exp(-age * (17 + index))
        rings = sum(np.sin(2 * np.pi * (frequency + index * 21) * age)
                    for frequency in (891, 1544, 2178, 3107))
        iron += rings * strike * (0.08 if index % 3 == 0 else 0.045)
    growl = band(glottis(58 + 9 * np.cos(TIME * 2.1)), 180, 720) * swell(1.25, 0.26)
    return 0.42 * breath + iron + 0.24 * growl


def electric(noise):
    radio = band(noise, 850, 3950)
    gate = swell(0.43, 0.12) + 0.55 * swell(0.70, 0.04) + swell(1.34, 0.19)
    breaks = 0.26 + 0.74 * (np.sin(TIME * 133) > -0.62)
    voice = band(glottis(123 + 15 * np.sin(TIME * 11) - TIME * 8), 600, 1800)
    return 0.53 * radio * gate * breaks + 0.51 * voice * swell(1.12, 0.31) * breaks


def storm(noise):
    gust = band(noise, 105, 1800) * (swell(0.68, 0.41) + 0.5 * swell(1.57, 0.35))
    rumble = band(noise, 38, 230) * swell(0.30, 0.32)
    howl = band(glottis(146 - TIME * 30 + 6 * np.sin(TIME * 14)), 210, 960) * swell(1.15, 0.32)
    return 0.38 * gust + 0.65 * rumble + 0.30 * howl


def ravager(noise):
    growl = band(glottis(201 + 21 * np.sin(TIME * 18)), 350, 2850)
    breath = band(noise, 950, 4700)
    stutter = sum(swell(center, width) for center, width in ((0.38, .06), (0.58, .08), (0.86, .09), (1.22, .07)))
    claw = band(noise, 2300, 5300) * (swell(1.53, .07) + swell(1.85, .10))
    return stutter * (growl * .36 + breath * .35) + claw * .22


def witch(noise):
    tremor = glottis(209 + 11 * np.sin(TIME * 29) - TIME * 17)
    vowel = .8 * band(tremor, 430, 820) + .4 * band(tremor, 1140, 1720)
    air = band(noise, 900, 4250) * (swell(0.28, .15) + .66 * swell(1.63, .22))
    return .47 * vowel * (swell(.83, .21) + .65 * swell(1.28, .16)) + .23 * air


def write(name, seed, render):
    dry = render(np.random.default_rng(seed).standard_normal(TIME.size))
    mixed = dry.copy()
    for delay, gain in ((.041, .15), (.093, -.12), (.175, .11), (.28, .068)):
        offset = round(delay * RATE)
        mixed[offset:] += gain * dry[:-offset]
    mixed *= np.minimum(TIME / 0.035, 1) * np.clip((2.39 - TIME) / 0.25, 0, 1)
    mixed *= .72 / np.max(np.abs(mixed))
    wavfile.write(OUTPUT / f"cinematic_{name}_approach.wav", RATE, np.rint(mixed * 32767).astype(np.int16))


if __name__ == "__main__":
    for number, render in enumerate((crusher, ravager, witch, electric, storm), start=1411):
        write(render.__name__, number, render)
