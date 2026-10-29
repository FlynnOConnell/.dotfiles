# /// script
# requires-python = ">=3.11,<3.13"
# dependencies = ["kokoro>=0.9.4", "soundfile", "numpy"]
# ///
"""
Spoken lines for an animation, one clip each, through Kokoro (a local text-to-speech model, no API key).

    uv run -p 3.12 animations/narrate.py --lines <lines.json> --out <dir> [--voice af_heart]

Reads a JSON list of strings, writes <dir>/clips.json ([{"text", "seconds", "filepath"}, ...]) and one 24 kHz wav per
line. Clips are cached by voice and text under ~/.cache/imgui_studio_manim/tts, so re-runs only speak changed lines. The
animation's kit calls this in a subprocess so that torch never enters the manim environment.

NOTE: the bundled espeak-ng keeps its data path in a 160-byte buffer and silently falls back to a build-machine path
when the environment's path is longer (espeakng-loader 0.2.4), so this must run from a short venv path such as uv's cache.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import soundfile as sf

SAMPLE_RATE = 24000
DIR_CACHE = Path.home() / ".cache" / "imgui_studio_manim" / "tts"


def clip_path(text: str, voice: str) -> Path:
    return DIR_CACHE / f"{voice}-{hashlib.sha1(text.encode()).hexdigest()[:12]}.wav"


def speak(lines: list, voice: str) -> list:
    """Every line as a wav (cached), returning (text, seconds, filepath) per line."""
    DIR_CACHE.mkdir(parents=True, exist_ok=True)
    missing = [text for text in lines if not clip_path(text, voice).exists()]
    if missing:
        from kokoro import KPipeline

        pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
        for text in missing:
            pieces = [audio for _, _, audio in pipeline(text, voice=voice)]
            audio = np.concatenate([np.asarray(p, dtype=np.float32) for p in pieces])
            sf.write(clip_path(text, voice), audio, SAMPLE_RATE)
    out = []
    for text in lines:
        filepath = clip_path(text, voice)
        out.append({"text": text, "seconds": sf.info(filepath).frames / SAMPLE_RATE, "filepath": str(filepath)})
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--lines", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--voice", default="af_heart")
    args = parser.parse_args()
    lines = json.loads(args.lines.read_text())
    clips = speak(lines, args.voice)
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "clips.json").write_text(json.dumps(clips, indent=1))
    for clip in clips:
        print(f"{clip['seconds']:5.1f} s  {clip['text']}")


if __name__ == "__main__":
    main()
