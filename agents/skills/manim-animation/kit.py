"""
What the lesson animations share: manim as a drawing engine without a Scene (a Cairo camera, frames piped to ffmpeg),
chapters played one after the other and scrubbed to any time, text, axes, scale bars, images and small grids, and
the command line that renders stills, an mp4 and a gif, with a spoken line per chapter if the animation has one.

An animation is a `build()` that returns a Timeline: nested AnimationGroups, every mobject introduced by an animation (a
mobject only ever moved by a Transform is drawn from t = 0, so such sources start at opacity 0).
"""

import argparse
import importlib
import json
import subprocess
import sys
import textwrap
import types
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

import manim as mn
import numpy as np
from PIL import Image

FPS = 20
FONT = "Noto Sans"
FRAME_WIDTH, FRAME_HEIGHT = 128 / 9, 8.0
BG = (0.10, 0.10, 0.12)
TEXT = (0.92, 0.92, 0.94)
DIM = (0.62, 0.62, 0.65)
EDGE = (0.35, 0.35, 0.37)
TRACE = (0.70, 0.70, 0.72)
BAR = (0.52, 0.52, 0.55)  # scale bars sit back a little from the traces
TRUTH = (0.35, 0.85, 0.45)  # ground truth
ACCENT = (0.40, 0.68, 1.00)
KEY = (1.00, 0.80, 0.20)
HIGHLIGHT = (0.922, 0.408, 0.204)
PINK = (0.910, 0.482, 0.643)
PARTS = ((0.165, 0.471, 0.839), (0.929, 0.631, 0.000), (0.106, 0.686, 0.478), (0.533, 0.529, 0.502), (0.580, 0.404, 0.741))


DIR_SRC = Path(__file__).resolve().parents[1] / "src"


def lesson_model(name: str):
    """
    imgui_ophys.lessons.<name>.model, pure numpy, without the lesson packages' __init__ files (which import
    imgui_bundle): every lesson package is stood in for by an empty module that only knows its path.
    """
    if str(DIR_SRC) not in sys.path:
        sys.path.insert(0, str(DIR_SRC))
    dir_lessons = DIR_SRC / "imgui_ophys" / "lessons"
    packages = [("imgui_ophys.lessons", dir_lessons)] + [(f"imgui_ophys.lessons.{d.name}", d) for d in dir_lessons.iterdir() if (d / "model.py").exists()]
    for package, dir_package in packages:
        if package not in sys.modules:
            stub = types.ModuleType(package)
            stub.__path__ = [str(dir_package)]
            sys.modules[package] = stub
    return importlib.import_module(f"imgui_ophys.lessons.{name}.model")


def color(c: tuple) -> mn.ManimColor:
    return mn.ManimColor.from_rgb(c)


def label(text: str, c: tuple = DIM, font_size: float = 22) -> mn.Text:
    """Text without its glyphs' SVG paths: every animation deep-copies its mobject, and the paths made that slow."""
    mobject = mn.Text(text, font_size=font_size, color=color(c), line_spacing=0.9)
    for glyph in mobject.get_family():
        if hasattr(glyph, "path_obj"):
            glyph.path_obj = None
    mobject.id_to_vgroup_dict = {}
    return mobject


def caption(text: str, y: float = -3.5) -> mn.Text:
    return put(label("\n".join(textwrap.wrap(text, 110)), DIM, 18), 0.0, y)


def put(mobject: mn.Mobject, x: float, y: float) -> mn.Mobject:
    return mobject.move_to(np.array([x, y, 0.0]))


def at(x: float, y: float) -> np.ndarray:
    return np.array([x, y, 0.0])


def plain_axes(x_min: float, x_max: float, y_min: float, y_max: float, width: float, height: float, visible: bool = True) -> mn.Axes:
    """Axes without ticks or tips; invisible ones only map coordinates, for a plot that uses scale bars."""
    return mn.Axes(
        x_range=[x_min, x_max, x_max - x_min], y_range=[y_min, y_max, y_max - y_min], x_length=width, y_length=height,
        tips=False, axis_config={"include_ticks": False, "stroke_width": 1.5, "color": color(EDGE), "stroke_opacity": 1.0 if visible else 0.0},
    )


def nice(x: float) -> float:
    """x rounded down to 1, 2 or 5 times a power of ten."""
    power = 10 ** np.floor(np.log10(x))
    return float(power * max(m for m in (1, 2, 5) if m * power <= x))


def axes_points(axes: mn.Axes, x: np.ndarray, y: np.ndarray) -> np.ndarray:
    """(n, 3) scene points of (x, y) on linear axes."""
    origin = axes.c2p(0, 0)
    return origin + np.outer(x, axes.c2p(1, 0) - origin) + np.outer(y, axes.c2p(0, 1) - origin)


def hbar(axes: mn.Axes, x0: float, x1: float, y: float, text: str, drop: float = 0.0) -> mn.VGroup:
    """A horizontal scale bar from x0 to x1 at y (lowered by drop scene units), its size written under it."""
    a, b = axes_points(axes, np.array([x0, x1]), np.array([y, y])) - at(0, drop)
    bar = mn.Line(a, b, color=color(BAR), stroke_width=3.0)
    return mn.VGroup(bar, label(text, BAR, 17).next_to(bar, mn.DOWN, buff=0.06))


def vbar(axes: mn.Axes, x: float, y0: float, y1: float, text: str) -> mn.VGroup:
    """A vertical scale bar at x from y0 to y1, its size written to its left."""
    a, b = axes_points(axes, np.array([x, x]), np.array([y0, y1]))
    bar = mn.Line(a, b, color=color(BAR), stroke_width=3.0)
    return mn.VGroup(bar, label(text, BAR, 17).next_to(bar, mn.LEFT, buff=0.08))


def scale_bars(axes: mn.Axes, x_max: float, y_lo: float, y_hi: float, seconds: float, y_drop: float, with_dff: bool = True) -> mn.VGroup:
    """A time bar under a trace's right end and, with_dff, a dF/F bar at its top right."""
    bars = hbar(axes, x_max - seconds, x_max, y_lo, f"{seconds:g} s", y_drop)
    if with_dff:
        dff = nice(0.3 * (y_hi - y_lo))
        bars.add(*vbar(axes, x_max, y_hi - dff, y_hi, f"{100 * dff:g}% dF/F"))
    return bars


def path(axes: mn.Axes, x: np.ndarray, y: np.ndarray, c: tuple, stroke_width: float, y_min: float, y_max: float) -> mn.VMobject:
    points = axes_points(axes, x, np.clip(y, y_min, y_max))
    return mn.VMobject(stroke_color=color(c), stroke_width=stroke_width).set_points_as_corners(points)


def dots_at(points: np.ndarray, c: tuple, radius: float = 0.045, opacity: float = 0.9) -> mn.VGroup:
    """Dots at scene points. Transform sources start at opacity 0, so a Transform both moves and reveals them."""
    return mn.VGroup(*[mn.Dot(pt, radius=radius, color=color(c), fill_opacity=opacity) for pt in points])


class Count(mn.Animation):
    """A label reacting to the picture: its number runs from start to end, redrawn by make(value) per 0.1."""

    def __init__(self, mobject: mn.Text, start: float, end: float, make: Callable[[float], mn.Text], decimals: int = 1, **kwargs) -> None:
        super().__init__(mobject, **kwargs)
        self.start, self.end, self.make, self.decimals = start, end, make, decimals
        self.cache = {}

    def interpolate_mobject(self, alpha: float) -> None:
        value = round(self.start + (self.end - self.start) * self.rate_func(alpha), self.decimals)
        if value not in self.cache:
            self.cache[value] = self.make(value).move_to(self.mobject, aligned_edge=mn.LEFT)
        ## NOTE: not become(): that pads both families to the longer one and never shrinks them, so a label whose
        ## glyph count changes ("d: 0" to "d: 1999") would break any FadeIn or FadeOut of it begun at another length.
        self.mobject.submobjects = [glyph.copy() for glyph in self.cache[value].submobjects]


# ----------------------------------------------------------------------
# images and grids
# ----------------------------------------------------------------------


def gray_rgb(a: np.ndarray, lo: float, hi: float) -> np.ndarray:
    """(h, w, 3) uint8, lo black and hi white."""
    v = np.clip((a - lo) / ((hi - lo) or 1.0), 0, 1)
    return np.repeat((255 * v).astype(np.uint8)[..., None], 3, axis=-1)


def tinted_rgb(a: np.ndarray, lo: float, hi: float, c: tuple) -> np.ndarray:
    """(h, w, 3) uint8, lo black and hi the color."""
    v = np.clip((a - lo) / ((hi - lo) or 1.0), 0, 1)
    return (255 * v[..., None] * np.array(c)).astype(np.uint8)


def diverging_rgb(a: np.ndarray, m: float, c: tuple) -> np.ndarray:
    """(h, w, 3) uint8: -m pink, 0 black, +m the color."""
    v = np.clip(a / (m or 1.0), -1, 1)
    pos = np.maximum(v, 0)[..., None] * np.array(c)
    neg = np.maximum(-v, 0)[..., None] * np.array(PINK)
    return (255 * (pos + neg)).astype(np.uint8)


def image(rgb: np.ndarray, height: float, x: float, y: float) -> mn.ImageMobject:
    """An image drawn pixel for pixel (no smoothing), height scene units tall, centered at (x, y)."""
    mobject = mn.ImageMobject(rgb)
    mobject.set_resampling_algorithm(mn.RESAMPLING_ALGORITHMS["nearest"])
    mobject.height = height
    return put(mobject, x, y)


class Play(mn.Animation):
    """An image showing frames[0] .. frames[-1] in turn over the animation (each an (h, w, 3) uint8)."""

    def __init__(self, mobject: mn.ImageMobject, frames: list, **kwargs) -> None:
        super().__init__(mobject, **kwargs)
        self.frames = frames

    def interpolate_mobject(self, alpha: float) -> None:
        i = min(int(self.rate_func(alpha) * len(self.frames)), len(self.frames) - 1)
        self.mobject.pixel_array = mn.ImageMobject(self.frames[i]).pixel_array


def grid(rgb: np.ndarray, cell: float, x: float, y: float, gap: float = 0.0, cell_h: Optional[float] = None, opacity: float = 1.0) -> mn.VGroup:
    """One rectangle per pixel of an (h, w, 3) uint8 image, row-major, cell wide and cell_h (default cell) tall, centered at (x, y)."""
    h, w = rgb.shape[:2]
    cell_h = cell if cell_h is None else cell_h
    cells = mn.VGroup()
    for i in range(h):
        for j in range(w):
            rect = mn.Rectangle(width=cell - gap, height=cell_h - gap, stroke_width=0, fill_color=color(tuple(rgb[i, j] / 255)), fill_opacity=opacity)
            cells.add(rect.move_to(at((j - (w - 1) / 2) * cell, ((h - 1) / 2 - i) * cell_h)))
    return put(cells, x, y)


class Recolor(mn.Animation):
    """A grid showing frames[0] .. frames[-1] in turn: each an (h, w, 3) uint8 image recoloring its cells."""

    def __init__(self, mobject: mn.VGroup, frames: list, **kwargs) -> None:
        super().__init__(mobject, **kwargs)
        self.colors = [[color(tuple(c / 255)) for c in f.reshape(-1, 3)] for f in frames]
        self.shown = None

    def interpolate_mobject(self, alpha: float) -> None:
        i = min(int(self.rate_func(alpha) * len(self.colors)), len(self.colors) - 1)
        if i != self.shown:
            for cell, c in zip(self.mobject, self.colors[i]):
                cell.set_fill(c)
            self.shown = i


def frame_of(mobject: mn.Mobject, c: tuple = EDGE, buff: float = 0.0, stroke_width: float = 1.5) -> mn.Rectangle:
    return mn.Rectangle(width=mobject.width + 2 * buff, height=mobject.height + 2 * buff, color=color(c), stroke_width=stroke_width).move_to(mobject)


# ----------------------------------------------------------------------
# chapters and scrubbing
# ----------------------------------------------------------------------


def chapter(duration: float, *animations: mn.Animation, lag_ratio: float = 0.0, active: float = 0.8) -> mn.AnimationGroup:
    """One chapter: its animations in the first active share of duration seconds, then a hold."""
    return mn.AnimationGroup(mn.AnimationGroup(*animations, lag_ratio=lag_ratio, run_time=duration * active),
                             mn.Wait(run_time=duration))


def leaf_animations(animation: mn.Animation) -> list:
    if isinstance(animation, mn.AnimationGroup):
        return [leaf for a in animation.animations for leaf in leaf_animations(a)]
    return [animation]


def leaf_timings(animation: mn.Animation, start: float = 0.0, scale: float = 1.0) -> list:
    """(start, end, leaf) in seconds of every leaf of a nested group, in the order they start."""
    if not isinstance(animation, mn.AnimationGroup):
        return [(start, start + scale * animation.run_time, animation)]
    inner = scale * animation.run_time / max(animation.max_end_time, 1e-12)
    out = []
    for row in animation.anims_with_timings:
        out += leaf_timings(row["anim"], start + inner * row["start"], inner)
    return sorted(out, key=lambda timing: timing[0])


@dataclass
class Timeline:
    statics: list
    animation: mn.AnimationGroup
    duration: float
    leaves: list
    starts: np.ndarray
    ends: np.ndarray
    alphas: np.ndarray


def timeline(statics: list, chapters: list) -> Timeline:
    """Chapters played one after the other, every leaf begun in time order (as a Scene would) and rewound to 0."""
    animation = mn.AnimationGroup(*chapters, lag_ratio=1.0)
    timings = leaf_timings(animation)
    leaves = [leaf for _, _, leaf in timings]
    for leaf in leaves:
        leaf.begin()
        leaf.interpolate(1)
    for leaf in reversed(leaves):
        leaf.interpolate(0)
    return Timeline(list(statics), animation, float(animation.run_time), leaves,
                 np.array([s for s, _, _ in timings]), np.array([e for _, e, _ in timings]), np.zeros(len(leaves)))


def seek(s: Timeline, t: float) -> list:
    """Put the animation at t seconds; returns the mobjects to draw, bottom first."""
    alphas = np.clip((t - s.starts) / np.maximum(s.ends - s.starts, 1e-9), 0.0, 1.0)
    changed = np.flatnonzero(alphas != s.alphas)
    for i in changed[::-1]:
        if alphas[i] == 0:
            s.leaves[i].interpolate(0.0)
    for i in changed:
        if alphas[i] > 0:
            s.leaves[i].interpolate(float(alphas[i]))
    s.alphas = alphas
    drawn, seen = [], set()
    for mobject in [*s.statics, *[leaf.mobject for leaf in leaf_animations(s.animation)]]:
        if id(mobject) not in seen:  ## the first animation decides the draw order, as a Scene's add() does; a later
            seen.update(id(m) for m in mobject.get_family())  ## FadeOut, or a Transform of one of its children, keeps it there
            drawn.append(mobject)
    return drawn


def replace(old: Optional[mn.Mobject], new: Optional[mn.Mobject]) -> list:
    """Fade old out, then new in, so the two never overlap; either may be absent."""
    if old is None and new is None:
        return []
    if old is None:
        return [mn.FadeIn(new)]
    if new is None:
        return [mn.FadeOut(old)]
    return [mn.AnimationGroup(mn.FadeOut(old), mn.FadeIn(new), lag_ratio=1.0)]


def titles_for(chapters: tuple, y: float = 3.1) -> list:
    """A chapter title per (name, duration), None where the name is empty."""
    return [put(label(name, DIM, 24), 0.0, y) if name else None for name, _ in chapters]


# ----------------------------------------------------------------------
# rendering
# ----------------------------------------------------------------------


def new_camera(width: int) -> mn.Camera:
    return mn.Camera(pixel_width=width, pixel_height=int(round(width * 9 / 16)), frame_width=FRAME_WIDTH,
                     frame_height=FRAME_HEIGHT, background_color=color(BG))


def capture(camera: mn.Camera, mobjects: list) -> np.ndarray:
    camera.reset()
    camera.capture_mobjects(mobjects)
    return camera.pixel_array.copy()


def slug(name: str) -> str:
    return "".join(ch if ch.isalnum() else "-" for ch in name.lower()).strip("-").replace("--", "-")


def stills(s: Timeline, camera: mn.Camera, dir_out: Path, names: list, seconds: list, untitled: dict) -> list:
    """A PNG at the end of each chapter (its hold), named by its title or, without one, by untitled[k]."""
    for old in dir_out.glob("[0-9]*_*.png"):
        old.unlink()
    out = []
    for k, (name, end) in enumerate(zip(names, np.cumsum(seconds))):
        rgb = capture(camera, seek(s, float(end) - 0.05))[..., :3]
        filepath = dir_out / f"{k + 1}_{slug(name) or untitled[k]}.png"
        Image.fromarray(rgb).save(filepath)
        out.append(filepath)
    return out


def movie(s: Timeline, camera: mn.Camera, filepath_mp4: Path, filepath_gif: Path, gif_width: int = 960, gif_fps: int = 12, hold: float = 2.0) -> int:
    """Every frame at FPS through ffmpeg: an h264 mp4, then a palette gif from the same frames."""
    width, height = camera.pixel_width, camera.pixel_height
    n = int(round((s.duration + hold) * FPS))
    ffmpeg = subprocess.Popen(
        ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{width}x{height}", "-r", str(FPS),
         "-i", "-", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", str(filepath_mp4)],
        stdin=subprocess.PIPE,
    )
    for i in range(n):
        rgb = capture(camera, seek(s, min(i / FPS, s.duration)))[..., :3]
        ffmpeg.stdin.write(np.ascontiguousarray(rgb).tobytes())
    ffmpeg.stdin.close()
    if ffmpeg.wait() != 0:
        raise RuntimeError("ffmpeg failed to write the mp4")
    graph = f"fps={gif_fps},scale={gif_width}:-2:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=full[p];[b][p]paletteuse=dither=none"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(filepath_mp4), "-vf", graph, str(filepath_gif)], check=True)
    return n


# ----------------------------------------------------------------------
# narration: one spoken line per chapter, the chapter as long as the line needs
# ----------------------------------------------------------------------

LEAD = 0.4  # s into a chapter before its line is spoken
TAIL = 0.8  # s of silence after a line before the next chapter
SAMPLE_RATE = 24000
SPOKEN = (("d'", "d prime"), ("dF/F", "delta F over F"), ("(blue)", "in blue"), ("(yellow)", "in yellow"), ("+/-", "plus or minus"), (" x ", " by "))


def spoken(text: str) -> str:
    """A caption as the voice should read it."""
    for written, said in SPOKEN:
        text = text.replace(written, said)
    return text


def narrate(lines: list, dir_out: Path, voice: str) -> list:
    """Speak the lines through animations/narrate.py in its own uv environment; (text, seconds, filepath) per line."""
    dir_tts = dir_out / "tts"
    dir_tts.mkdir(parents=True, exist_ok=True)
    filepath_lines = dir_tts / "lines.json"
    filepath_lines.write_text(json.dumps([spoken(line) for line in lines]))
    subprocess.run(["uv", "run", "-p", "3.12", str(Path(__file__).with_name("narrate.py")), "--lines", str(filepath_lines),
                    "--out", str(dir_tts), "--voice", voice], check=True)
    return json.loads((dir_tts / "clips.json").read_text())


def chapter_seconds(minimums: list, clips: list) -> list:
    """Each chapter at least its hand-set length, and long enough for its line plus the lead and tail."""
    return [max(float(d), clip["seconds"] + LEAD + TAIL) for d, clip in zip(minimums, clips)]


def soundtrack(clips: list, starts: np.ndarray, duration: float, filepath_wav: Path) -> None:
    """The clips placed at their starts in duration seconds of silence, as 16-bit mono wav."""
    audio = np.zeros(int(round(duration * SAMPLE_RATE)), np.float32)
    for clip, start in zip(clips, starts):
        clip_audio = wav_samples(Path(clip["filepath"]))
        i = int(round(start * SAMPLE_RATE))
        audio[i:i + clip_audio.size] += clip_audio[:audio.size - i]
    pcm = (np.clip(audio, -1, 1) * 32767).astype("<i2")
    with wave.open(str(filepath_wav), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(pcm.tobytes())


def wav_samples(filepath: Path) -> np.ndarray:
    """A 16-bit mono wav's samples in [-1, 1]; a float wav is read through ffmpeg."""
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(filepath), "-f", "s16le", "-ac", "1", "-ar", str(SAMPLE_RATE), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, "<i2").astype(np.float32) / 32767


def srt_time(t: float) -> str:
    ms = int(round(t * 1000))
    return f"{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}"


def subtitles(lines: list, clips: list, starts: np.ndarray, filepath_srt: Path) -> None:
    """One cue per chapter while its line is spoken, in the written form."""
    cues = [f"{k + 1}\n{srt_time(start)} --> {srt_time(start + clip['seconds'])}\n{line}\n"
            for k, (line, clip, start) in enumerate(zip(lines, clips, starts))]
    filepath_srt.write_text("\n".join(cues))


def mux(filepath_video: Path, filepath_wav: Path, filepath_srt: Path, filepath_out: Path) -> None:
    """The silent mp4 with the voice as aac and the subtitles as a selectable track."""
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(filepath_video), "-i", str(filepath_wav), "-i", str(filepath_srt),
                    "-map", "0:v:0", "-map", "1:a:0", "-map", "2:s:0", "-c:v", "copy", "-c:a", "aac", "-c:s", "mov_text",
                    "-metadata:s:s:0", "language=eng", "-movflags", "+faststart", str(filepath_out)], check=True)


def run(name: str, chapters: tuple, untitled: dict, build: Callable[[list], Timeline], doc: str, narration: Optional[list] = None) -> None:
    """
    The command line every animation shares: --out, --width, --gif-width, --stills-only, and with a narration (one
    written line per chapter) --narrate, which speaks the lines, stretches each chapter to fit its line, and gives the
    mp4 a voice track and subtitles. build(seconds) gets the chapter lengths.
    """
    parser = argparse.ArgumentParser(description=doc.strip().splitlines()[0])
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--gif-width", type=int, default=960)
    parser.add_argument("--stills-only", action="store_true")
    if narration is not None:
        parser.add_argument("--narrate", action="store_true")
        parser.add_argument("--voice", default="af_heart")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    mn.config.media_dir = str(Path.home() / ".cache" / "imgui_studio_manim")
    mn.Text.set_default(font=FONT, color=color(TEXT))
    names, seconds = [n for n, _ in chapters], [float(d) for _, d in chapters]
    clips = None
    if narration is not None and args.narrate:
        if len(narration) != len(chapters):
            raise ValueError(f"{len(narration)} narration lines for {len(chapters)} chapters")
        clips = narrate(narration, args.out, args.voice)
        seconds = chapter_seconds(seconds, clips)
        print("chapters: " + ", ".join(f"{d:.1f}" for d in seconds) + f" s = {sum(seconds):.0f} s")
    s = build(seconds)
    camera = new_camera(args.width)
    for filepath in stills(s, camera, args.out, names, seconds, untitled):
        print(filepath)
    if args.stills_only:
        return
    filepath_mp4, filepath_gif = args.out / f"{name}.mp4", args.out / f"{name}.gif"
    filepath_video = args.out / "tts" / f"{name}_silent.mp4" if clips else filepath_mp4
    n = movie(s, camera, filepath_video, filepath_gif, gif_width=args.gif_width)
    if clips:
        starts = np.concatenate([[0.0], np.cumsum(seconds)[:-1]]) + LEAD
        filepath_wav, filepath_srt = args.out / "tts" / f"{name}.wav", args.out / f"{name}.srt"
        soundtrack(clips, starts, n / FPS, filepath_wav)
        subtitles(narration, clips, starts, filepath_srt)
        mux(filepath_video, filepath_wav, filepath_srt, filepath_mp4)
        print(f"{filepath_srt}: {len(clips)} cues")
    print(f"{filepath_mp4}: {n} frames at {FPS} fps, {s.duration:.0f} s of animation" + (", with voice" if clips else ""))
    print(f"{filepath_gif}: {filepath_gif.stat().st_size / 1e6:.1f} MB")
