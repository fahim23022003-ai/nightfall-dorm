"""Synthesize the original Phase 14 Stalker cue without external recordings."""

from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile


SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[2] / "assets/audio/cinematic_stalker_breath.wav"


def render():
    rng = np.random.default_rng(1402)
    time = np.arange(round(2.1 * SAMPLE_RATE)) / SAMPLE_RATE
    noise = rng.standard_normal(time.size)

    def pulse(center, length, attack):
        position = (time - center) / length
        envelope = np.exp(-0.5 * position**2)
        return envelope * (0.5 + 0.5 * np.tanh((time - center + length) / attack))

    def formants(source, frequencies):
        color = np.zeros_like(source)
        for center, width, weight in frequencies:
            b, a = signal.iirpeak(center, center / width, fs=SAMPLE_RATE)
            color += weight * signal.lfilter(b, a, source)
        return color

    inhale = formants(noise, [(820, 560, 0.45), (2_850, 1_400, 0.8)])
    voiced_start = pulse(0.8, 0.18, 0.035)
    voiced_end = pulse(1.22, 0.19, 0.05)
    shake = 0.79 + 0.15 * np.sin(2 * np.pi * 7.3 * time + np.sin(time * 21))
    pitch = 153 - 24 * time + 7 * np.sin(2 * np.pi * 5.4 * time) + 3 * np.sin(2 * np.pi * 13 * time)
    phase = 2 * np.pi * np.cumsum(pitch) / SAMPLE_RATE
    glottis = sum(np.sin(harmonic * phase) / harmonic**1.25 for harmonic in range(1, 17))
    throat = 0.36 * glottis + noise
    open_vowel = formants(throat, [(510, 125, 0.85), (1_460, 260, 0.5), (2_480, 520, 0.3)])
    close_vowel = formants(throat, [(360, 120, 0.7), (1_790, 280, 0.55), (2_700, 650, 0.3)])
    breath = (
        0.46 * pulse(0.39, 0.17, 0.055) * inhale
        + shake * (voiced_start * open_vowel + 0.74 * voiced_end * close_vowel)
        + 0.21 * pulse(1.46, 0.18, 0.06) * inhale
    )
    reverberant = np.copy(breath)
    for delay, gain in [(0.051, 0.19), (0.114, -0.13), (0.207, 0.1), (0.313, 0.08)]:
        samples = round(delay * SAMPLE_RATE)
        reverberant[samples:] += gain * breath[:-samples]

    bandpass = signal.butter(2, [120, 4_900], fs=SAMPLE_RATE, btype="bandpass", output="sos")
    cue = signal.sosfilt(bandpass, reverberant)
    cue *= np.minimum(time / 0.045, 1) * np.clip((2.09 - time) / 0.18, 0, 1)
    cue *= 0.72 / np.max(np.abs(cue))
    return np.rint(cue * np.iinfo(np.int16).max).astype(np.int16)


if __name__ == "__main__":
    wavfile.write(OUTPUT, SAMPLE_RATE, render())
