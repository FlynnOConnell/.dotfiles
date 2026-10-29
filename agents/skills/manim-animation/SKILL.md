---
name: manim-animation
description: Build a manim animation: 30 to 60 s that explains one method or metric from a numpy model, chapter by chapter, with a number that reacts to the picture. Use when asked for a manim animation, explainer, tutorial gif or README movie of a pipeline step (d', dF/F, registration, NMF, SVD, PMD), or to tune one. The companion skill imgui-lesson covers the hands-on interactive page.
user-invocable: true
---

# manim animation

An animation explains. It is manim used as a drawing engine (a Cairo camera, no `Scene`), driven by a `build()` that
returns nested `AnimationGroup`s, scrubbed to any second, and rendered to an mp4, a gif and one PNG per chapter.
The reference is the d' animation in imgui_ophys, which the user tuned over nine rounds on 2026-10-28; everything below
is what those rounds settled. Read it before writing a new one:

- `kit.py` beside this file: the kit (camera, chapters, scrubbing, labels, axes, scale bars, images, grids, `Count`,
  `Play`, `Recolor`, the render command line, and with `narrate.py` an optional spoken line per chapter through
  Kokoro). It is the newest copy: imgui_ophys's `animations/kit.py` (and `~/repos/imgui_ophys-dprime-narrated`'s)
  predate two fixes listed under "Animation rules that bit". Copy it into a new repo's `animations/`, and diff
  against the repo's own copy before touching an older one.
- `~/repos/imgui_ophys/animations/dprime.py`: the one to imitate. Its gif is `docs/animations/dprime.gif` and its
  stills are in `~/agent_assets/imgui_ophys/20261028_lesson-stories_02/artifacts/story/dprime/`.
- `~/repos/imgui_ophys/animations/{motion,nmf,traces,svd}.py`: four more on the same kit (movies with `Play`,
  grids with `Recolor`, equations as chapter titles).
- `~/repos/imgui_ophys/animations/subcellular.py` (branch `worktree-subcellular`): the d' arc on a membrane
  voltage model with two zooms at their own scales, three traces in slots, two numbers counting at once, and a
  closing table of shapes with a snippet per row.
- `~/repos/imgui_masknmf_manim/src/imgui_masknmf_manim/canvas.py`: the same machinery inside an imgui window, with
  movie panels that follow a frame slider (the imgui-lesson skill).
- The text rules live in the deslop skill, section "Titles, captions and labels in figures, pages and explainers".
  This skill adds the manim-specific ones.

The word is "animation" and the directory `animations/` (renamed from "story" / `stories/` on 2026-10-28; imgui_masknmf_manim's
`canvas.py` still says `Story`, `story()` and `set_story()` where imgui_ophys's kit says `Timeline`, `timeline()` and `seek()`).

## The shape of an animation

The d' arc, which generalizes to any score or decomposition:

1. The object. The whole trace (or movie, or image) with its scale bars and a provenance label. The headline title
   ("d': a measure of how well spikes stand out from noise") is on screen only here; it fades out the moment the
   next chapter's first element appears.
2. One instance. A box on the object; the boxed segment and a copy of the box fly down and grow into the zoom. The
   zoom shares the vertical scale with its parent and gets only a time bar. The segment that flew is then the zoom
   trace, so later morphs transform it.
3. The computation on that instance. The things that go into the number appear on the zoom (the frames before, the
   frames at the peak) and fly from there into their own figure (the clusters).
4. Pool. The same for every instance, lagged, with a count ("8 spikes x 6 frames").
5. The number. Mean lines, SD bars, the gap arrow, then the number large and in the key color.
6. Perturb. Three chapters titled by the action ("Add noise", "Remove noise", "Add photobleaching"). The title comes
   first and alone for about 1 s to prime the viewer; then everything on screen (the object, the zoom, the clusters,
   the marks) morphs at once over about 4 s, and the number counts along with it.
7. Examples. Everything but the object clears; a table comes in, one row per level of the number with its meaning
   beside it (d' 0.5 to 4.9 against % correct), traces on a shared scale, lagged.

Chapters run 4 to 7 s each (12 s for a table), the whole animation 35 to 60 s. Chapter 1 and the examples have no
title; the computation chapters get a one-line grey caption at the bottom; the perturb chapters get a title only.
For a method rather than a score, the equation is the chapter title ("dF/F = (F - F0) / F0", "Y = A C: a footprint
(where) times a trace (when) per source", "Power iteration: u = R v, v = R'u, until v settles") and the perturb
chapters are the method's knobs ("Remove neuropil", "Gaussian smoothing, SD 1 frame", "SD 3 frames").

## Text

The deslop rules, as they bit here. Left is what was cut, right is what stayed.

| cut | kept |
|-----|------|
| "One cell, one trace", "The number", "Two piles", "What d' says", "Every spike" | no title, or "Two clusters" |
| "d': how far one spike stands above the noise" | "d': a measure of how well spikes stand out from noise" |
| "when the cell spiked", "the green ticks are the moments it..." | "Ground truth spikes (simulated)" |
| "one spike, 1.6 s around it" | "spike +/- 0.8 s" |
| "20 photons / pixel / frame", "one cell's dF/F over 40 s" | a 5 s bar and a 20% dF/F bar |
| "More noise?" | "Add noise" (an action, no punctuation) |
| "d' = (peak mean - before mean) / pooled SD", "gap = 0.125 - 0.026", "pooled SD = 0.036" | "d' = 2.7" |
| "a threshold halfway between the piles gets 91% of single spikes right" | the closing table: d' against % correct |
| "How clearly does each spike stand out of this trace?" under the title | nothing: it restated the title |

- A chapter title names the content or the action, in the field's terms. Never a question, never a rhetorical
  frame ("What it misses"), never an embedded question ("How it is computed").
- One statement per idea: no caption that restates a title, no prose beside a number, no formula line next to the
  number it produced. The meaning of the number goes in the closing table.
- Labels name the thing and its provenance: "Ground truth spikes (simulated)", "6 frames before the spike",
  "6 at the peak", "clustered", "8 spikes x 6 frames", "fitted" / "true (simulated)".
- Captions are secondary: `caption()` is 18 pt DIM grey at y = -3.5, one line, and only on the chapters that build
  the computation. Chapter titles are 24 pt DIM at y = 3.1. The headline title is 30 pt TEXT at y = 3.6. The number
  is 44 pt KEY. Everything else is 17 to 22 pt.
- Text only, no LaTeX: `mn.Text` through `kit.label`, never `MathTex`, `Tex`, `DecimalNumber` or axis numbers.
  Equations are plain text ("u = R v", "Y ~ A C", "+/-").

## Picture

- Traces get scale bars, never axes or axis labels: `scale_bars(axes, ...)` puts a time bar under the right end and
  a dF/F bar at the top right; `nice()` rounds the bar to 1, 2 or 5 x 10^n. Bars and their labels are BAR, a step
  greyer than the TRACE they sit under. A zoom gets a time bar only.
  Exception, from the subcellular animation (2026-10-29): when the zoomed event is an order of magnitude smaller
  than the trace's largest (an EPSP against a bAP), the zoom gets its own dF/F bar, and so does any second zoom
  at another scale; the bars are what tells the viewer the scales differ.
- `plain_axes(..., visible=False)` maps coordinates for a trace drawn with bars; `visible=True` draws a bare frame
  for a plot that needs one (the clusters).
- Plot ranges are fixed over every cell the animation will show (take the min and max across all of them before
  building), so a perturbation moves the dots, not the axes.
- Ground truth is TRUTH green; the two pools are ACCENT blue (before) and KEY yellow (peak); the number is KEY.
  Parts of a sum use PARTS in equation order. Images are `gray_rgb`, `tinted_rgb` or `diverging_rgb` (pink for
  negative), drawn with nearest-neighbour resampling at a height in scene units.
- Movies play with `Play` (an `ImageMobject` stepping through frames) or `Recolor` (a `grid` of rectangles, for
  small arrays where each pixel should read as a cell). A frame that unrolls into a matrix column is a `grid` at
  opacity 0 transformed into the column.
- Show change by making the picture react. A new value is never faded out and in: the number is a `Count`, the
  trace a `Transform`, the dots a `Transform` into `dots_at` of the new points. Everything that a perturbation
  touches morphs in the same `AnimationGroup`.
- Stills: `stills()` writes a PNG at the end of each chapter's hold, named by its title or `UNTITLED[k]`. Those are
  what the user reviews; look at every one before rendering the movie.

## Animation rules that bit

- Every mobject is introduced by an animation. A mobject only ever moved by a `Transform` is drawn from t = 0, so
  such sources start at opacity 0 (`dots_at(..., opacity=0.0)`, `set_stroke(opacity=0.0)`, `grid(..., opacity=0.0)`)
  and the Transform reveals them. The "pre-drawn middle of the trace at the start of the movie" bug was this.
- A mobject used as a Transform target must never also get its own animation: a `FadeOut` of a target draws it
  from t = 0.
- `Transform` needs equal families: pad a `VGroup` with invisible members rather than make it shorter.
- Text to text goes through `replace()` (FadeOut, then FadeIn, lag_ratio 1), never `Transform`. A FadeOut and a
  FadeIn in one group overlap for the whole transition.
- `Count(label, start, end, make)` redraws the label per 0.1 (cached) and keeps its left edge; it runs inside the
  morph group so the number moves with the picture.
- The title lead of a perturb chapter is its own group with `run_time=1.0`, then the morph, `lag_ratio=1.0`
  (see `morph()` in animations/dprime.py).
- `chapter(duration, *animations, lag_ratio, active=0.8)` plays the animations in the first 80% and holds; the
  hold is where the still is taken. Inside a `lag_ratio=1.0` sequence, anything that fades in and then out again
  within the chapter (a popup, a dropdown menu) needs a `mn.Wait(run_time=1.5)` between the two, or the viewer
  never sees it: the sequence is rescaled to the chapter's active share, not the chapter to the sequence.
- `Count` must not use `become()`: it pads both families to the longer one and never shrinks them, so a label whose
  glyph count changes ("d: 0" to "d: 1999") breaks any FadeIn or FadeOut of it begun at another length
  (`ValueError: zip() argument 2 is shorter`). The kit's `Count` swaps the glyph submobjects instead.
- A `FadeIn` or `FadeOut` must not overlap a `Count` of the same label whose glyph count changes meanwhile
  ("9 ROIs" to "10 ROIs" inside the fade's 0.3 s): the fade zips the families it captured and crashes with
  `zip() argument 2 is shorter`. Put the fade and the count in a `lag_ratio=1.0` group. The stills pass (they seek
  to chapter ends only); the movie finds it.
- Draw order is first appearance. A mobject is drawn where its first animation lists it, as a Scene's `add()`
  would; the kit's `seek` dedupes the draw list by family. Before that fix a FadeOut in the last chapter lifted the
  whole window chrome over panels introduced in between, and a child animated on its own (a checkbox inside a
  panel group, Transformed later) was drawn twice, once on top of everything.
- A `FadeIn` of a mobject that an earlier chapter faded out shows nothing: `FadeIn` targets the mobject's state at
  its begin, which is the faded one. Fade in a fresh `copy()` instead (the Studio suite2p demo's source label).
- To check mid-chapter frames, not only the stills: `ffmpeg -ss <t> -i x.mp4 -frames:v 1 f.png` at the moments a
  thing is supposed to be on screen, tiled four at a time with PIL.

## An app demo

Never redraw an app's widgets in manim (the user: "This is not the purpose, to recreate the U/I in manim"; then,
of small drawn cards, "Can we use the actual windows used in the U/I rather than making small snippets?"). Capture
the real windows and animate those:

- The Studio renders offscreen with no display: `_create_image_widget(array, widget="preview" | "manualroi",
  figure_kwargs_override={"canvas": "offscreen", "size": (w, h)})`, the side widget is
  `next(g for g in iw.figure.imgui_windows.values() if g)`, `iw.figure.canvas.draw()` returns the composited frame.
  Popups and tabs by their flags (`gui._show_metadata_popup`, `gui._force_run_tab`, `manual_roi.focus_tab`); runs by
  `manual_roi.load_run(plane_dir)`, cells by `select_derived(si, k)` and `buffer_toggle(si, k)`.
- `iw.current_index = {"t": k}` between draws gives a frame sequence of the whole window: the movie, the T slider and
  the trace cursor move as in the app. Save it as one uint8 npz and `Play` it on the window's `ImageMobject`.
- Windows are `ImageMobject`s with bicubic resampling at one scale (0.0078 scene units per px), all centered at one
  place; chapters cross-fade them. Render at `--width 1920`, gif 960: at 1280 the UI text is unreadable.
- manim text sits beside the window, never on it: the typed command (a `Count` over the string's prefix), a frame
  around the button in use (`scene_rect` from the button's pixel rectangle), counts, measured step timings, file
  names. The reference is `~/repos/imgui_studio_manim/animations/suite2p_demo.py` with its capture script in
  `~/agent_assets/imgui_studio_manim/20261029_studio-suite2p-demo/code/capture_windows.py`.

## manim outside a Scene

`kit.timeline()` begins every leaf animation in time order (`begin()`, `interpolate(1)`), then rewinds them all;
`seek(t)` sets the leaves whose alpha changed, unstarted ones to 0 latest first, started ones in start order.
Four traps, all handled in the kit and in `canvas.py`:

1. `AnimationGroup.mobject` leaves out introducers (`FadeIn`, `Create`); draw every leaf's mobject instead.
2. Never call `AnimationGroup.begin()`: it begins every leaf at once, so a later `FadeIn` captures an already faded
   target and stays invisible.
3. Rewinding, `AnimationGroup.interpolate` lets a later chapter's start state win over an earlier chapter's end
   state when both move one mobject; rewind latest first.
4. `FadeTransform` draws its source at full opacity until it starts; bring the source in with its own `FadeIn`.

`Succession` only moves forward; use `AnimationGroup(..., lag_ratio=1.0)`.

## Costs and environment

- Every animation deep-copies its mobject. A `Text` keeps the svgelements path of every glyph, which made a label
  15 ms to copy; `kit.label` sets `glyph.path_obj = None` (30x faster). A page's first build pays Pango once per
  label; manim caches the SVG after that in `~/.cache/<repo>_manim`.
- Scripts are PEP 723 (`uv run -p 3.12 animations/<name>.py --out <dir>`), dependencies manim, numpy, pillow. Keep
  `pillow<13` until manim ships the fix for `ValueError: Invalid mode for data type` (manim #5074; 0.22.1 still
  needs it as of 2026-10-28). manim needs Python 3.11+.
- The model is pure numpy and lives in the app package; `kit.lesson_model(name)` imports `lessons/<name>/model.py`
  by stubbing every lesson package so their `__init__` files (which import imgui_bundle) never run. Nothing from
  the animation is added to the app's environment.
- `Camera(pixel_width=1280, frame_width=128/9, frame_height=8)` at 20 fps. 20 fps because a gif's frame delays
  are hundredths of a second, so 20 is exact and 12 is not. `capture()` costs 15 to 30 ms at 960 px; images
  dominate.
- ffmpeg on PATH. The mp4 is h264 crf 20 from raw rgb24 frames; the gif comes from the mp4 with one palette
  (`palettegen=max_colors=128:stats_mode=full`, `paletteuse=dither=none`: panels are flat blocks and dithering
  costs a third more). README gifs are 720 px at 10 fps, 1.4 to 3.5 MB for 35 to 56 s. For a movie that plays
  inside the animation, step it at 10 Hz and hold the last frame 2 to 3 s before a 0.6 s fade to background so the
  loop restarts clean (`scripts/overview_gif.py`).
- Rendering is deterministic (seeds fixed in the model), so the same `build()` gives the stills, the mp4 and the
  gif; a test can seek to a chapter midpoint after random jumps and compare pixels against a fresh one
  (`imgui_masknmf_manim/tests/test_stories.py`).

## Workflow

1. Model first: `src/<pkg>/lessons/<name>/model.py`, numpy only, with the numbers the animation will show, tested in
   `tests/`. The animation reads it; it never computes the science itself.
2. Write `animations/<name>.py` on the kit: `TITLE`, `CHAPTERS` ((title, seconds) tuples, "" for none),
   `UNTITLED` (still file names for the untitled chapters), `build()` returning `timeline(...)`, `kit.run(...)`.
   Print the numbers the animation shows (d' per cell, error per sweep) so the log carries them.
3. `--stills-only` first (seconds). Open every PNG and check it against the lists above: title present only where
   it should be, scale bars on every trace, no caption restating a title, no formula beside a number, the morph
   sources invisible at the chapters before they fly.
4. Render the movie. Open the gif, scrub the mp4 at the chapter boundaries. Check: the number counts rather than
   blinks, nothing is pre-drawn, nothing overlaps during a `replace`.
5. Outputs go to `~/agent_assets/<repo>/<YYYYMMDD_slug>/artifacts/animations/<name>/` (mp4, gif, PNG per chapter,
   `render.log`), the README gif to `docs/animations/<name>.gif` at 720 px, with one line in the README naming what
   the animation shows. `runhub check` the topic directory.
6. Expect rounds. The user tunes by looking at the stills and the gif and sending a list of cuts; apply all of
   them, re-render the stills, and show the changed ones. Record each round in the topic's `MEMORIES.md` as the d'
   topic does (`~/agent_assets/imgui_ophys/20261028_dprime-lesson/MEMORIES.md`), and move any new rule into this
   skill or deslop.

## Review checklist

Before sending a round back, every item answers yes:

- No title or caption is a question, a wh-clause, or a restatement of another line on screen.
- Every trace has scale bars and no axis labels; bars are greyer than traces; the zoom shares its parent's scale.
- Every label states the thing and its provenance; simulated data say so.
- The number appears once, large, in KEY, and only counts when the picture morphs.
- Perturbation chapters: title first, then everything morphs at once; the title is an action without punctuation.
- Nothing is visible before its chapter (scrub to 0.1 s and to each chapter's start).
- Plot ranges do not move between chapters.
- The animation ends on a table or a comparison the viewer can read without the narration.
