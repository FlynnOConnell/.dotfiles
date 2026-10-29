---
name: imgui-lesson
description: Build an interactive imgui-bundle page that lets the user work a method or metric by hand on simulated and real data (sliders, presets, clicks on pixels), in the same visual language as the manim animations. Use when asked for an imgui tutorial, lesson, explainer page or app for a pipeline step, or to embed a manim animation in a window. The companion skill manim-animation covers the animation that describes the method.
user-invocable: true
---

# imgui lesson

PLACEHOLDER, started 2026-10-28. The manim-animation skill is the finished one; this one holds the pointers and the
rules already settled, and grows as the imgui repos are brought up to the d' story's quality.

An animation describes; a lesson is hands on. The same model, the same figures and the same text rules, but the user
turns the knobs: brightness, bleaching, F0, a seed, a preset that reproduces each cell the animation showed, a click on
a pixel or a block to follow it everywhere. Real data loads beside the simulation.

## Reference repos

- `~/repos/imgui_ophys`: one page per pipeline step on synthetic data with a known ground truth. The d' page
  (`src/imgui_ophys/lessons/dprime/view.py`) is the lesson that matches its animation section for section; start from
  it. `README.md` "Adding a page or subsection" and `ARCHITECTURE.md` are current.
- `~/repos/imgui_masknmf_manim`: manim drawn inside the window (a Cairo camera on a worker thread, the window
  shows the latest finished drawing), a timeline that scrubs, a frame slider the movie panels follow, clicks on
  panels that re-pick the pixel. Real movies via `--movie x.tif --fs 30`. `ARCHITECTURE.md` has the threads and
  the scrubbing notes; `scripts/demo.py` records the window to mp4 with a scripted cursor.
- `~/repos/imgui_lab4_interface`: the shell, palette and Font Awesome 6 icons the windows share;
  `~/repos/imgui_vnoiser`: the scale handling and plotting helpers imgui_ophys copied.

## Settled so far

- Split `model.py` (numpy, tested without imgui) from `view.py` (a `Lesson` subclass: `key`, `title`, `summary`,
  `sections`, `section_<i>()`, `controls()`). The summary is the quantity's definition in one line.
- Sections mirror the animation's chapters and carry its names: Trace, Spike +/- 0.8 s, Clusters, Examples. No
  captions; scale bars instead of axes (`diagram.py`, `plotting.py`); labels with provenance; the number large in
  KEY beside its figure.
- A parameter change morphs: `make()` keeps the on-screen state as the start and the new one as the end,
  `update(dt)` blends over `MORPH` = 1.2 s (smoothstep) and re-scores the blend each frame; the number is lerped
  between the two end values rather than scored from the blend (a blend of two noise draws is quieter than either
  end and overshoots). A seed change snaps. While `animating()`, hello_imgui's idling is off.
- Plot ranges are fixed over the reference cells, so a slider moves the dots, not the axes.
- Presets on the rail reproduce the animation's cells (Add noise, Remove noise, Add photobleaching, Reset), so the page
  and the gif agree on every number.
- Media for the README and runhub: `capture.py` in the topic's `code/` renders a hidden GLFW window and reads the
  framebuffer (`glReadPixels(GL_FRONT)`), ramping a parameter and calling `settle()` after each step, to a PNG per
  section and a gif per ramp; `tests/test_headless_render.py` draws every section on hello_imgui's null backend.

## Gotchas (from both ARCHITECTURE.md files)

- `imgui.push_font(None, size)` takes a size before `style.font_scale_main`; divide it out (`widgets.push_size`).
  Text drawn at an explicit size must be measured at that size.
- `ImDrawList.add_rect` is (p_min, p_max, col, rounding, thickness, flags) and `add_polyline` (points, col,
  thickness, flags): thickness before flags, unlike C++.
- hello_imgui loads Font Awesome 4 unless `runner_params` sets `default_icon_font` to 6; newer icons draw as "?".
- `implot.add_colormap` asserts on a duplicate name; look the name up first. Colormaps need an ImPlot context, so
  make them on the page's first draw.
- Headless tests on the null backend need `renderer_has_textures` set in `post_init`.
- GLFW reports content scale 1 under XWayland; the app owns its scale (Ctrl +/-, a slider, `--scale`, an env var)
  and saves it to `~/.<app>/settings.json`.
- `ImageMobject` keeps its opacity in the alpha of `pixel_array`; when a movie frame replaces the RGB, keep the
  alpha the animation set. A trace cursor stores its scene coordinates when built: reading them from axes that
  `Create` has collapsed fails.
- Record a window without PyOpenGL: in `callbacks.after_swap`, redraw with `opengl3_render_draw_data` and read
  pixels through ctypes `libGL.so.1`; scripted clicks go through `io.add_mouse_pos_event` /
  `add_mouse_button_event`.
- The venv may hold a non-editable copy of the package; run checks with `PYTHONPATH=src` so they see the source.

## To fill in

- The page layout contract (rail, sections, controls) written out the way the chapter arc is in manim-animation.
- Loading real data next to the simulation on every page, and what "real" means per step (a tif for motion, an
  npz split for compression, a traces npy for d').
- Which figures the window draws itself (ImPlot, draw lists) and which it takes from manim (`canvas.py`), and
  when each is right.
- The media recipe for READMEs: per-section PNG, a ramp gif, the window tour mp4, their sizes.
