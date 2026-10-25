"""sciview: a window for looking at arrays sent from the debugger.

Started by nvim (lua/config/sciview.lua) as its own process, so it stays live
while the debugged program is paused and can't take that program down.
Arrays arrive from python/nvim_sciview_send.py over a unix socket.

  1D     trace plot and histogram
  2D+    image with colormap and contrast; a slider per leading axis (axis 0
         is time: play/pause); hovering a pixel plots its trace over axis 0
Left column: the debugger's controls (continue, pause, stop, step over / into /
out, the same as ,c ,p ,q ,o ,i ,O in nvim), the call stack and the paused frame's variables (sent by nvim on
every pause and frame change; click a frame to move the debugger there, an
array to load it: the viewer asks nvim over its RPC socket, --nvim), then
every array shown so far. The gear on the toolbar (,dv in nvim) opens the run
configs page: the saved commands of ,dd as forms read off each one's --help,
the project's data locations, and buttons to debug or run them in nvim.

Future: on-demand frames for arrays too big to send whole (a frame server in
the debugged program), GPU tensors shared without a CPU copy (CUDA IPC).
"""

import argparse
import json
import os
import queue
import re
import shutil
import socket
import subprocess
import threading
import time

import numpy as np
from imgui_bundle import hello_imgui, imgui, immapp, immvision, implot
from imgui_bundle import portable_file_dialogs as pfd

import nvim_sciview_form as cli
import nvim_sciview_send as send

# the toolbar: (action sent to nvim, codicon, name, nvim key, color, usable when)
CONTROLS = [
    ("continue", "\ueacf", "Continue", ",c", "ok", "paused"),
    ("pause", "\uead1", "Pause", ",p", "number", "running"),
    ("terminate", "\uead7", "Stop", ",q", "error", "live"),
    ("step_over", "\uead6", "Step over", ",o", "accent", "paused"),
    ("step_into", "\uead4", "Step into", ",i", "accent", "paused"),
    ("step_out", "\uead5", "Step out", ",O", "accent", "paused"),
]
GEAR = "\ueb51"
COLORMAPS = ["Gray", "Viridis", "Magma", "Inferno", "Plasma", "Turbo", "Parula", "Cividis", "Hot", "Jet"]
# sizes below are at 1x; px() scales them by the display scale (HiDPI)
UI_SCALE = 1.0
TRACE_HEIGHT = 190
ZOOM_BUTTONS_HEIGHT = 34  # immvision's row under the image
MAX_UPSAMPLE = 8  # small frames are enlarged nearest-neighbor so pixels stay square
STRETCH_MAX = 64  # per-axis repeat for stretched (lopsided) matrices
MAX_TEXTURE_PIXELS = 4_000_000


def px(n: float) -> float:
    return n * UI_SCALE


# -- looks: nvim's colorscheme (sent with --theme), tokyonight when run alone
THEME = {
    "bg": "#1a1b26", "raised": "#292e42", "selection": "#283457", "fg": "#c0caf5", "dim": "#565f89",
    "accent": "#7aa2f7", "border": "#27a1b9", "number": "#ff9e64", "string": "#9ece6a", "type": "#2ac3de",
    "constant": "#ff9e64", "error": "#db4b4b", "ok": "#9ece6a",
}
FONT = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"
FONT_BOLD = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf"
FONT_SIZE = 14.0
fonts: dict = {}


def color(role: str, alpha: float = 1.0, toward: str | None = None, t: float = 0.0) -> imgui.ImVec4:
    """THEME[role] as an ImVec4, optionally mixed a fraction t toward another role."""
    def rgb(hexcode):
        return [int(hexcode[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    c = rgb(THEME[role])
    if toward:
        c = [a + (b - a) * t for a, b in zip(c, rgb(THEME[toward]))]
    return imgui.ImVec4(*c, alpha)


def load_fonts():
    if not os.path.exists(FONT):
        hello_imgui.imgui_default_settings.load_default_font_with_font_awesome_icons()
        return
    fonts["regular"] = hello_imgui.load_font(FONT, FONT_SIZE)
    if os.path.exists(FONT_BOLD):
        fonts["bold"] = hello_imgui.load_font(FONT_BOLD, FONT_SIZE)


def bold(text: str, role: str = "fg"):
    if "bold" in fonts:
        imgui.push_font(fonts["bold"], 0.0)
    imgui.text_colored(color(role), text)
    if "bold" in fonts:
        imgui.pop_font()


def heading(text: str):
    """A small dim section label with a rule after it."""
    imgui.spacing()
    imgui.push_style_color(imgui.Col_.text, color("dim"))
    imgui.separator_text(text)
    imgui.pop_style_color()


def pill(text: str, role: str):
    """A rounded chip of `text` in THEME[role] on a tint of it."""
    pad = imgui.ImVec2(px(7), px(1))
    size = imgui.calc_text_size(text)
    start = imgui.get_cursor_screen_pos()
    end = imgui.ImVec2(start.x + size.x + 2 * pad.x, start.y + size.y + 2 * pad.y)
    draw = imgui.get_window_draw_list()
    draw.add_rect_filled(start, end, imgui.color_convert_float4_to_u32(color(role, 0.16)), px(9))
    draw.add_text(imgui.ImVec2(start.x + pad.x, start.y + pad.y), imgui.color_convert_float4_to_u32(color(role)), text)
    imgui.dummy(imgui.ImVec2(end.x - start.x, end.y - start.y))


def value_role(var: dict) -> str:
    """Explorer values colored by kind, like nvim's syntax colors."""
    kind = var.get("type", "")
    if var.get("array"):
        return "accent"
    if kind in ("int", "float", "complex") or kind.startswith(("int", "uint", "float", "complex")):
        return "number"
    if kind in ("str", "bytes"):
        return "string"
    if kind in ("bool", "bool_", "NoneType"):
        return "constant"
    if var.get("expandable"):
        return "type"
    return "dim"


def setup_style():
    style = imgui.get_style()
    style.window_padding = imgui.ImVec2(12, 12)
    style.frame_padding = imgui.ImVec2(8, 4)
    style.cell_padding = imgui.ImVec2(6, 3)
    style.item_spacing = imgui.ImVec2(8, 6)
    style.item_inner_spacing = imgui.ImVec2(6, 4)
    style.indent_spacing = 14
    style.scrollbar_size = 10
    style.grab_min_size = 10
    for name in ("window_rounding", "child_rounding", "popup_rounding"):
        setattr(style, name, 8)
    for name in ("frame_rounding", "grab_rounding", "scrollbar_rounding", "tab_rounding"):
        setattr(style, name, 5)
    style.window_border_size = 0
    style.child_border_size = 1
    style.frame_border_size = 0
    style.separator_text_border_size = 1
    style.separator_text_padding = imgui.ImVec2(0, 4)
    # sizes are at 1x: hello_imgui scales the style for HiDPI itself

    C = imgui.Col_
    panel = color("bg", toward="raised", t=0.7)
    colors = {
        C.text: color("fg"), C.text_disabled: color("dim"),
        C.window_bg: color("bg"), C.child_bg: color("bg", 0.0), C.popup_bg: color("raised"),
        C.border: color("raised", toward="dim", t=0.25), C.border_shadow: color("bg", 0.0),
        C.frame_bg: panel, C.frame_bg_hovered: color("raised"), C.frame_bg_active: color("selection"),
        C.title_bg: color("bg"), C.title_bg_active: color("bg"), C.menu_bar_bg: color("bg"),
        C.scrollbar_bg: color("bg", 0.0), C.scrollbar_grab: color("raised"),
        C.scrollbar_grab_hovered: color("dim", 0.6), C.scrollbar_grab_active: color("dim"),
        C.check_mark: color("accent"), C.slider_grab: color("accent", 0.85), C.slider_grab_active: color("accent"),
        C.button: color("raised"), C.button_hovered: color("selection", toward="accent", t=0.15),
        C.button_active: color("accent", 0.5),
        C.header: color("selection"), C.header_hovered: color("raised", toward="selection", t=0.6),
        C.header_active: color("selection", toward="accent", t=0.2),
        C.separator: color("raised", toward="dim", t=0.25), C.separator_hovered: color("accent", 0.6),
        C.separator_active: color("accent"),
        C.resize_grip: color("bg", 0.0), C.resize_grip_hovered: color("accent", 0.5), C.resize_grip_active: color("accent"),
        C.table_header_bg: panel, C.table_border_strong: color("raised"), C.table_border_light: color("raised"),
        C.table_row_bg: color("bg", 0.0), C.table_row_bg_alt: color("raised", 0.22),
        C.text_selected_bg: color("selection"), C.nav_cursor: color("accent"),
        C.plot_lines: color("accent"), C.plot_histogram: color("accent"),
    }
    for index, value in colors.items():
        style.set_color_(index, value)


def setup_plot_style():
    """implot's look; needs the implot context, so it runs on the first frame."""
    style = implot.get_style()
    P = implot.Col_
    for index, value in {
        P.frame_bg: color("bg", 0.0), P.plot_bg: color("bg", toward="raised", t=0.3), P.plot_border: color("raised"),
        P.legend_bg: color("raised", 0.9), P.legend_border: color("raised"), P.legend_text: color("fg"),
        P.title_text: color("fg"), P.inlay_text: color("dim"), P.axis_text: color("dim"),
        P.axis_grid: color("raised", 0.8), P.axis_tick: color("raised"), P.axis_bg: color("bg", 0.0),
        P.axis_bg_hovered: color("raised", 0.5), P.axis_bg_active: color("selection"),
        P.selection: color("accent", 0.6), P.crosshairs: color("dim"),
    }.items():
        style.set_color_(index, value)
    style.plot_padding = imgui.ImVec2(px(8), px(8))
    # plot lines in the theme's colors, accent first
    roles = ["accent", "number", "string", "type", "error", "constant"]
    rgba = np.array([[*(lambda c: (c.x, c.y, c.z, 1.0))(color(r))] for r in roles], dtype=np.float32)
    style.colormap = implot.add_colormap("nvim", rgba, True)


def row_tooltip(name_hovered: bool, expr: str, summary: str):
    """Explorer names and values get clipped: hovering either shows the whole row."""
    if name_hovered or imgui.is_item_hovered():
        imgui.set_tooltip(f"{expr}\n{summary}")


def flow(width: float):
    """same_line() if the next widget (about `width` wide) fits on this line, else wrap."""
    spacing = imgui.get_style().item_spacing.x
    right = imgui.get_window_pos().x + imgui.get_window_width() - imgui.get_style().window_padding.x
    if imgui.get_item_rect_max().x + spacing + width <= right:
        imgui.same_line()


def display_scale() -> float:
    """The monitor scale imgui must draw at, or 0 to let hello_imgui decide.

    imgui-bundle's GLFW runs through XWayland. With Hyprland's
    xwayland:force_zero_scaling (Omarchy's default) such windows get native
    pixels and must scale themselves, else text is half size on a 2x screen.
    SCIVIEW_SCALE overrides.
    """
    if os.environ.get("SCIVIEW_SCALE"):
        return float(os.environ["SCIVIEW_SCALE"])
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return 0.0
    try:
        zero = json.loads(subprocess.run(["hyprctl", "getoption", "xwayland:force_zero_scaling", "-j"],
                                         capture_output=True, text=True, timeout=2).stdout)
        if not zero.get("int", zero.get("bool")):
            return 0.0
        monitors = json.loads(subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=2).stdout)
        return float(next((m["scale"] for m in monitors if m.get("focused")), monitors[0]["scale"]))
    except Exception:
        return 0.0
# default contrast: 99.9 keeps bright transients (active cells) from saturating
CONTRAST_PERCENTILES = [1, 99.9]
HIST_SAMPLES = 2_000_000


class Item:
    def __init__(self, message: dict, data: np.ndarray):
        self.label = message["label"]
        self.type = message.get("type", "")
        self.notes = message.get("notes", [])
        self.data = data
        self.received = time.strftime("%H:%M:%S")
        flat = data.reshape(-1)
        sample = flat[:: max(1, flat.size // HIST_SAMPLES)].astype(np.float64)
        finite = sample[np.isfinite(sample)]
        self.sample = finite.astype(np.float32)
        self.nan_count = int(flat.size - np.isfinite(flat).sum()) if np.issubdtype(data.dtype, np.floating) else 0
        if finite.size:
            self.min, self.max = float(finite.min()), float(finite.max())
            low, high = np.percentile(finite, CONTRAST_PERCENTILES)
            self.vmin, self.vmax = float(low), float(high) if high > low else float(low) + 1.0
        else:
            self.min = self.max = self.vmin = 0.0
            self.vmax = 1.0
        self.index = [0] * max(0, data.ndim - 2)
        self.colormap = 0
        self.params = immvision.ImageParams()
        self.params.show_options_button = False
        self.params.show_image_info = False
        self.params.zoom_with_mouse_wheel = True
        self.params.pan_with_mouse = True
        self.params.colormap_settings.colormap = "None"  # Gray is mapped in frame()
        self.params.show_pixel_info = False  # it would show the 8-bit gray, not the data; see view_image
        self.params.show_grid = False
        self.upsample = (1, 1)  # (rows, cols) repeat factors for display
        h, w = (data.shape[-2], data.shape[-1]) if data.ndim >= 2 else (1, 1)
        # lopsided matrices (a 1024x19 spatial basis) fill the view instead of
        # showing as a sliver; toggle per array
        self.stretch = max(h / w, w / h) > 4
        self.pixel = None  # (y, x) last hovered
        self.stop = None  # the pause it was sent at (set by the viewer)
        self.error = None  # set if drawing it failed
        self.playing = False
        self.fps = 20.0
        self.last_step = 0.0
        self.show_hist = False

    def frame(self) -> np.ndarray:
        frame = np.asarray(self.data[tuple(self.index)], dtype=np.float32)
        ky, kx = self.upsample
        if ky > 1:
            frame = frame.repeat(ky, axis=0)
        if kx > 1:
            frame = frame.repeat(kx, axis=1)
        if COLORMAPS[self.colormap] == "Gray":
            # immvision's "Gray" colormap runs white -> black, so map the
            # contrast range to 8-bit gray here instead (black = vmin)
            scaled = (frame - self.vmin) * (255.0 / (self.vmax - self.vmin))
            return np.ascontiguousarray(np.clip(scaled, 0, 255).astype(np.uint8))
        return np.ascontiguousarray(frame)


class Viewer:
    def __init__(self, nvim: str | None = None):
        self.items: list[Item] = []
        self.current = -1
        self.incoming: queue.Queue = queue.Queue()
        self.nvim = nvim  # the nvim that started us: asked for clicked variables
        # {"stop", "frame", "frame_id", "location", "stack", "variables"}; "stop"
        # names the pause and frame, so another frame's objects aren't reused
        self.frame_vars: dict | None = None
        self.running = False  # the program resumed: the variables are stale
        self.ended = False  # the run finished: nothing to step
        self.pending: str | None = None  # a clicked variable on its way
        self.status = ""
        # opened objects: expr -> list of child rows, or "loading" / error text
        self.children: dict[str, list | str] = {}
        self.force_open: set[str] = set()  # testing: rows opened as if clicked
        self.styled = False
        self.scrolled_to = None  # the frame the stack list last scrolled to
        self.configs = ConfigsPage(self)
        self.page_open = False  # the run configs page instead of the shown array
        self.page_request: dict | None = None  # open it on this project (from nvim)

    @property
    def stale(self) -> bool:
        """The variables are from an earlier pause: the program resumed or ended."""
        return self.running or self.ended

    def call_nvim(self, function: str, expr: str, on_error):
        """Call require'config.sciview'.<function>(expr) in the nvim that started us."""
        # a JSON string is also a valid vimscript double-quoted string
        command = f"v:lua.require'config.sciview'.{function}({json.dumps(expr)})"

        def run():
            try:
                subprocess.run(["nvim", "--server", self.nvim, "--remote-expr", command],
                               capture_output=True, timeout=10, check=True)
            except Exception as error:
                on_error(f"could not reach nvim: {error}")

        threading.Thread(target=run, daemon=True).start()

    def ask_nvim(self, function: str, arg: str | None = None) -> dict:
        """v:lua.<function>(arg) in nvim, answered in JSON. Blocks: call it off the ui thread."""
        call = f"v:lua.{function}({'' if arg is None else json.dumps(arg)})"
        done = subprocess.run(["nvim", "--server", self.nvim, "--remote-expr", call],
                              capture_output=True, text=True, timeout=10, check=True)
        return json.loads(done.stdout)

    def toggle_page(self):
        if self.page_open:
            self.configs.close()
            self.page_open = False
            return
        self.page_open = True
        if not self.nvim:
            self.configs.open(self.configs.root or os.getcwd())
            return

        def ask():  # nvim's current project
            try:
                self.page_request = self.ask_nvim("require'config.run_configs'.viewer_state")
            except Exception as error:
                self.configs.status = (f"could not reach nvim: {error}", "error")

        threading.Thread(target=ask, daemon=True).start()

    def request(self, expr: str):
        """Ask nvim to send `expr` from the paused frame (like ,m)."""
        self.pending, self.status = expr, f"loading {expr}..."

        def failed(text):
            self.pending, self.status = None, text

        self.call_nvim("request", expr, failed)

    def open_children(self, expr: str):
        self.children[expr] = "loading"

        def failed(text):
            self.children[expr] = text

        self.call_nvim("children", expr, failed)

    def select_frame(self, frame_id: int):
        """Ask nvim to move to this frame (like ,k / ,j); its variables follow."""
        def failed(text):
            self.status = text

        self.call_nvim("select_frame", str(frame_id), failed)

    # -- socket: one message per connection, reply "ok" once loaded ---------
    def serve(self, path: str):
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(path)
        server.listen(8)
        while True:
            conn, _ = server.accept()
            threading.Thread(target=self.receive, args=(conn,), daemon=True).start()

    def receive(self, conn: socket.socket):
        with conn:
            line = conn.makefile().readline()
            if not line.strip():
                return  # a connect-only check that the viewer is up
            try:
                message = json.loads(line)
                if message.get("ping"):
                    conn.sendall(b"ok\n")
                    return
                if message.get("kind") == "variables":
                    if not self.frame_vars or self.frame_vars.get("stop") != message.get("stop"):
                        self.children = {}  # a new pause: attribute values may have changed
                    self.frame_vars, self.running, self.ended = message, False, False
                    conn.sendall(b"ok\n")
                    return
                if message.get("kind") == "children":
                    if self.frame_vars and message.get("stop") not in (None, self.frame_vars.get("stop")):
                        conn.sendall(b"ok\n")  # for a frame no longer shown
                        return
                    rows = message.get("children") or []
                    # nvim's json writes an empty lua table as {}
                    self.children[message["parent"]] = rows if isinstance(rows, list) else (message.get("error") or "no attributes")
                    if not rows and message.get("error"):
                        self.children[message["parent"]] = message["error"]
                    conn.sendall(b"ok\n")
                    return
                if message.get("kind") == "configs":
                    self.page_request = message
                    conn.sendall(b"ok\n")
                    return
                if message.get("kind") in ("running", "ended"):
                    self.running = message["kind"] == "running"
                    self.ended = message["kind"] == "ended"
                    conn.sendall(b"ok\n")
                    return
                path = message["path"]
                data = np.load(path)
                os.unlink(path)
                self.incoming.put(Item(message, data))
                conn.sendall(b"ok\n")
            except Exception as error:  # report back to the sender, keep serving
                try:
                    conn.sendall(f"error: {error}\n".encode())
                except OSError:
                    pass

    # -- ui -----------------------------------------------------------------
    def gui(self):
        if not self.styled:
            setup_plot_style()
            self.styled = True
        while not self.incoming.empty():
            item = self.incoming.get()
            item.stop = self.frame_vars["stop"] if self.frame_vars else None
            self.items.append(item)
            self.current = len(self.items) - 1
            if item.label == self.pending:
                self.pending, self.status = None, ""
            if self.page_open:  # a new array (,m): show it
                self.toggle_page()
        if self.page_request:
            request, self.page_request = self.page_request, None
            self.configs.open(request.get("root"), request.get("store"))
            self.page_open = True

        # drag its right edge to widen the explorer
        imgui.push_style_color(imgui.Col_.child_bg, color("bg", toward="raised", t=0.25))
        imgui.push_style_var(imgui.StyleVar_.window_padding, imgui.ImVec2(px(10), px(10)))
        imgui.begin_child("##side", imgui.ImVec2(px(340), 0),
                          imgui.ChildFlags_.borders | imgui.ChildFlags_.resize_x | imgui.ChildFlags_.always_use_window_padding)
        imgui.pop_style_var()
        imgui.pop_style_color()
        self.variables_panel()
        if self.items:
            heading("SHOWN")
            for i in range(len(self.items) - 1, -1, -1):
                item = self.items[i]
                shape = " x ".join(str(n) for n in item.data.shape) or "scalar"
                clicked, _ = imgui.selectable(f"{item.label}##shown{i}", i == self.current,
                                              imgui.SelectableFlags_.span_all_columns)
                if clicked:
                    self.current = i
                imgui.same_line()
                imgui.text_colored(color("dim"), shape)
        imgui.end_child()
        imgui.same_line()

        imgui.begin_child("##view", imgui.ImVec2(0, 0), imgui.ChildFlags_.always_use_window_padding)
        if self.page_open:
            self.configs.draw()
        elif self.current < 0:
            self.empty_view()
        else:
            item = self.items[self.current]
            if item.error:
                bold(item.label)
                imgui.text_colored(color("error"), f"could not draw: {item.error}")
            else:
                state = imgui.internal.ErrorRecoveryState()
                imgui.internal.error_recovery_store_state(state)
                try:
                    self.view(item)
                except Exception as error:
                    # one bad array must not take the viewer (and its history)
                    # down: close whatever it left open, show the error instead
                    imgui.internal.error_recovery_try_to_recover_state(state)
                    item.error = f"{type(error).__name__}: {error}"
        imgui.end_child()

    def control(self, action: str):
        """Ask nvim to continue / pause / stop / step (its listeners update us)."""
        def failed(text):
            self.status = text

        self.call_nvim("control", action, failed)

    def controls(self):
        """The toolbar: codicons from the nerd font, names without it."""
        state = {"paused": self.frame_vars is not None and not self.stale, "running": self.running}
        state["live"] = state["paused"] or state["running"]
        for i, (action, icon, name, key, role, usable) in enumerate(CONTROLS):
            if i:
                imgui.same_line(0, px(4))
            enabled = state[usable] and self.nvim is not None
            if not enabled:
                imgui.begin_disabled()
            imgui.push_style_color(imgui.Col_.text, color(role))
            label = icon if "regular" in fonts else name
            if imgui.button(f"{label}##{action}", imgui.ImVec2(px(34) if "regular" in fonts else 0, px(28))):
                self.control(action)
            imgui.pop_style_color()
            if not enabled:
                imgui.end_disabled()
            if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
                imgui.set_tooltip(f"{name}  ({key} in nvim)")
        # the run configs page, apart from the stepping buttons
        imgui.same_line(0, px(14))
        imgui.push_style_color(imgui.Col_.text, color("accent" if self.page_open else "fg"))
        if self.page_open:
            imgui.push_style_color(imgui.Col_.button, color("selection"))
        if imgui.button(f"{GEAR if 'regular' in fonts else 'Configs'}##configs",
                        imgui.ImVec2(px(34) if "regular" in fonts else 0, px(28))):
            self.toggle_page()
        imgui.pop_style_color(2 if self.page_open else 1)
        if imgui.is_item_hovered():
            imgui.set_tooltip("Run configs and data locations  (,dv in nvim)")
        imgui.spacing()

    def variables_panel(self):
        self.controls()
        frame = self.frame_vars
        if frame is None:
            pill("waiting", "dim")
            imgui.spacing()
            imgui.text_wrapped("Variables appear here when the debugger pauses.")
            return
        if self.ended:
            pill("finished", "dim")
        else:
            pill("running" if self.running else "paused", "number" if self.running else "ok")
        imgui.same_line()
        bold(frame["frame"], "accent")
        imgui.text_colored(color("dim"), frame["location"])
        if self.status:
            imgui.text_colored(color("error") if self.status.startswith("could") else color("dim"), self.status)
        if frame.get("stack"):
            heading("CALL STACK")
            self.stack_rows(frame["stack"], frame.get("frame_id"))
        heading("VARIABLES")
        if not frame["variables"]:
            imgui.text_disabled("none defined yet")
        if self.stale:
            imgui.begin_disabled()
        flags = imgui.TableFlags_.row_bg | imgui.TableFlags_.resizable | imgui.TableFlags_.no_borders_in_body_until_resize
        if imgui.begin_table("##vars", 2, flags):
            # names wider than this are clipped (hover for the full row); drag the divider
            imgui.table_setup_column("name", imgui.TableColumnFlags_.width_fixed, px(150))
            imgui.table_setup_column("value", imgui.TableColumnFlags_.width_stretch)
            self.variable_rows(frame["variables"], frame["stop"])
            imgui.end_table()
        if self.stale:
            imgui.end_disabled()

    def stack_rows(self, stack: list, current):
        """The stopped thread's frames, outermost first (like nvim's stack
        pane): click one to go there. Long stacks scroll, kept on the current."""
        row = imgui.get_text_line_height_with_spacing()
        height = min(len(stack), 8) * row + px(4)
        imgui.begin_child("##stack", imgui.ImVec2(0, height))
        if self.stale or not self.nvim:
            imgui.begin_disabled()
        for f in stack:
            here = f["id"] == current
            # a full-width row to click, with the name and location drawn over it
            start = imgui.get_cursor_pos()
            clicked, _ = imgui.selectable(f"##frame{f['id']}", here, imgui.SelectableFlags_.allow_overlap)
            if clicked and not here:
                self.select_frame(f["id"])
            if imgui.is_item_hovered():
                imgui.set_tooltip(f"{f['name']}\n{f['location']}")
            if here and self.scrolled_to != (self.frame_vars or {}).get("stop"):
                imgui.set_scroll_here_y(0.5)
                self.scrolled_to = (self.frame_vars or {}).get("stop")
            imgui.set_cursor_pos(start)
            if here:
                bold(f"> {f['name']}", "accent")
            else:
                imgui.text_colored(color("dim" if f.get("subtle") else "fg"), f"  {f['name']}")
            imgui.same_line()
            imgui.text_colored(color("dim"), f["location"])
        if self.stale or not self.nvim:
            imgui.end_disabled()
        imgui.end_child()

    def load(self, expr: str, loaded):
        if self.stale:
            return
        if loaded is not None:
            self.current = loaded  # already loaded at this pause
        elif self.nvim:
            self.request(expr)
        else:
            self.status = "started without --nvim: use ,m"

    def variable_rows(self, rows: list, stop):
        """Rows of the explorer: objects open into their attributes (fetched
        from nvim on first open), arrays load into the view when clicked."""
        tree = imgui.TreeNodeFlags_
        for var in rows:
            name, expr = var["name"], var.get("expr") or var["name"]
            summary = var.get("brief") or var.get("value", "")
            imgui.table_next_row()
            imgui.table_next_column()
            loaded = None
            if var.get("array"):
                loaded = next((i for i, it in enumerate(self.items) if it.label == expr and it.stop == stop), None)
            if var.get("expandable"):
                # the arrow opens its attributes; for a lazy array class
                # (CompressionArray, ...) clicking the name loads it as an array
                flags = tree.span_full_width | tree.open_on_arrow | (tree.selected if loaded is not None and loaded == self.current else 0)
                if expr in self.force_open:
                    imgui.set_next_item_open(True, imgui.Cond_.once)
                opened = imgui.tree_node_ex(f"{name}##{expr}", flags)
                hovered = imgui.is_item_hovered()
                if var.get("array") and imgui.is_item_clicked() and not imgui.is_item_toggled_open():
                    self.load(expr, loaded)
                imgui.table_next_column()
                imgui.text_colored(color(value_role(var)), summary)
                row_tooltip(hovered, expr, summary)
                if opened:
                    children = self.children.get(expr)
                    if children is None and not self.stale:
                        self.open_children(expr)
                    elif isinstance(children, str):
                        imgui.table_next_row()
                        imgui.table_next_column()
                        imgui.text_colored(color("dim"), "loading..." if children == "loading" else children)
                    elif children:
                        self.variable_rows(children, stop)
                    imgui.tree_pop()
            elif var.get("array"):
                selected = loaded is not None and loaded == self.current
                flags = tree.leaf | tree.no_tree_push_on_open | tree.span_full_width | (tree.selected if selected else 0)
                imgui.tree_node_ex(f"{name}##{expr}", flags)
                hovered = imgui.is_item_hovered()
                if imgui.is_item_clicked():
                    self.load(expr, loaded)
                imgui.table_next_column()
                imgui.text_colored(color("accent"), summary)
                row_tooltip(hovered, expr, summary)
            else:
                imgui.tree_node_ex(f"{name}##{expr}", tree.leaf | tree.no_tree_push_on_open | tree.span_full_width)
                hovered = imgui.is_item_hovered()
                imgui.table_next_column()
                imgui.text_colored(color(value_role(var)), summary)
                row_tooltip(hovered, expr, summary)

    def empty_view(self):
        avail = imgui.get_content_region_avail()
        lines = ["nothing shown yet", "", "Click a variable to display it"]
        imgui.set_cursor_pos_y(imgui.get_cursor_pos_y() + avail.y * 0.4)
        for i, line in enumerate(lines):
            width = imgui.calc_text_size(line).x
            imgui.set_cursor_pos_x(imgui.get_cursor_pos_x() + max(0.0, (avail.x - width) / 2))
            imgui.text_colored(color("fg" if i == 0 else "dim"), line)

    def view(self, item: Item):
        data = item.data
        bold(item.label)
        imgui.same_line()
        pill(" x ".join(str(n) for n in data.shape) or "scalar", "accent")
        imgui.same_line()
        pill(str(data.dtype), "type")
        if item.nan_count:
            imgui.same_line()
            pill(f"{item.nan_count} nan", "error")
        imgui.same_line()
        imgui.text_colored(color("dim"), f"{item.type}  {item.received}")
        imgui.text_colored(color("dim"), "min")
        imgui.same_line()
        imgui.text_colored(color("number"), f"{item.min:.6g}")
        imgui.same_line(0, px(16))
        imgui.text_colored(color("dim"), "max")
        imgui.same_line()
        imgui.text_colored(color("number"), f"{item.max:.6g}")
        for note in item.notes:
            imgui.text_colored(color("dim"), note)
        imgui.spacing()

        if data.size == 0:
            imgui.text_colored(color("dim"), "empty array")
        elif data.ndim == 0:
            bold(repr(data.item()), "number")
        elif data.ndim == 1:
            self.view_1d(item)
        else:
            self.view_image(item)

    def view_1d(self, item: Item):
        values = item.data.astype(np.float64)
        avail = imgui.get_content_region_avail()
        height = avail.y - (px(TRACE_HEIGHT + 10) if item.show_hist else px(30))
        if implot.begin_plot(f"##line{id(item)}", imgui.ImVec2(-1, max(height, px(150)))):
            try:
                implot.setup_axes("index", "value")
                implot.plot_line(item.label, values)
            finally:
                implot.end_plot()
        _, item.show_hist = imgui.checkbox("histogram", item.show_hist)
        if item.show_hist:
            self.histogram(item)

    def view_image(self, item: Item):
        data = item.data
        changed = False

        # leading axes: axis 0 is time, with playback
        for axis in range(data.ndim - 2):
            imgui.set_next_item_width(imgui.get_content_region_avail().x - px(60))
            moved, value = imgui.slider_int(f"axis {axis}##{id(item)}", item.index[axis], 0, data.shape[axis] - 1)
            if moved:
                item.index[axis], changed = value, True
        if item.playing and data.ndim >= 3:
            now = time.perf_counter()
            if now - item.last_step >= 1.0 / item.fps:
                item.index[0] = (item.index[0] + 1) % data.shape[0]
                item.last_step = now
                changed = True

        if data.ndim >= 3:
            if imgui.button(("pause" if item.playing else "play") + f"##{id(item)}"):
                item.playing = not item.playing
                item.last_step = time.perf_counter()
            flow(px(100))
            imgui.set_next_item_width(px(70))
            _, item.fps = imgui.slider_float(f"fps##{id(item)}", item.fps, 1.0, 60.0, "%.0f")
            flow(px(250))
        imgui.set_next_item_width(px(190))
        moved, low, high = imgui.drag_float_range2(
            f"contrast##{id(item)}", item.vmin, item.vmax, (item.max - item.min) / 500 or 0.01, item.min, item.max, "%.4g"
        )
        if moved:
            item.vmin, item.vmax, changed = low, max(high, low + 1e-12), True
        flow(px(45))
        if imgui.button(f"auto##{id(item)}"):
            low, high = np.percentile(item.sample, CONTRAST_PERCENTILES) if item.sample.size else (0.0, 1.0)
            item.vmin, item.vmax, changed = float(low), float(high), True
        flow(px(100))
        imgui.set_next_item_width(px(100))
        moved, item.colormap = imgui.combo(f"##cmap{id(item)}", item.colormap, COLORMAPS)
        changed = changed or moved
        flow(px(105))
        _, item.show_hist = imgui.checkbox(f"histogram##{id(item)}", item.show_hist)
        if max(h_w := (data.shape[-2] / data.shape[-1]), 1 / h_w) > 1.5:
            flow(px(90))
            moved, item.stretch = imgui.checkbox(f"stretch##{id(item)}", item.stretch)
            changed = changed or moved

        settings = item.params.colormap_settings
        settings.colormap = "None" if COLORMAPS[item.colormap] == "Gray" else COLORMAPS[item.colormap]
        if COLORMAPS[item.colormap] == "Gray":
            settings.colormap_scale_min, settings.colormap_scale_max = 0.0, 255.0  # frame() is already 8-bit
        else:
            settings.colormap_scale_min, settings.colormap_scale_max = item.vmin, item.vmax

        # image sized to the space left above the trace plot
        avail = imgui.get_content_region_avail()
        below = px(ZOOM_BUTTONS_HEIGHT) + (px(TRACE_HEIGHT + 8) if data.ndim >= 3 else 0) + (px(TRACE_HEIGHT + 8) if item.show_hist else 0)
        h, w = data.shape[-2], data.shape[-1]
        box_w, box_h = avail.x - px(10), avail.y - below - px(10)
        if item.stretch:
            # repeat rows and columns by separate factors so the texture
            # already has the view's shape: cells stay crisp blocks
            ky, kx = max(1, min(STRETCH_MAX, int(box_h // h))), max(1, min(STRETCH_MAX, int(box_w // w)))
            while h * ky * w * kx > MAX_TEXTURE_PIXELS and max(ky, kx) > 1:
                ky, kx = (max(1, ky // 2), kx) if ky >= kx else (ky, max(1, kx // 2))
        else:
            k = max(min(box_w / w, box_h / h), 0.05)
            ky = kx = int(max(1, min(MAX_UPSAMPLE, k)))
        if (ky, kx) != item.upsample:
            item.upsample, changed = (ky, kx), True
        tex_h, tex_w = h * ky, w * kx
        scale = max(min(box_w / tex_w, box_h / tex_h), 0.05)
        if scale >= 1:
            scale = float(int(scale))  # whole-number zoom: every data pixel the same size on screen
        item.params.image_display_size = (int(tex_w * scale), int(tex_h * scale))
        item.params.refresh_image = changed
        origin = imgui.get_cursor_screen_pos()
        immvision.image(f"##frame{id(item)}", item.frame(), item.params)

        # the pixel under the mouse: immvision's zoom_pan_matrix maps image
        # coordinates to screen offsets from the image's top-left corner
        mouse = imgui.get_mouse_pos()
        dx, dy = mouse.x - origin.x, mouse.y - origin.y
        shown_w, shown_h = item.params.image_display_size
        if imgui.is_window_hovered() and 0 <= dx < shown_w and 0 <= dy < shown_h:
            ix, iy, _ = np.linalg.solve(np.array(item.params.zoom_pan_matrix), [dx, dy, 1.0])
            x, y = int(ix // item.upsample[1]), int(iy // item.upsample[0])
            if 0 <= y < h and 0 <= x < w:
                item.pixel = (y, x)
                value = item.data[tuple(item.index) + (y, x)]
                imgui.text_colored(color("dim"), f"y {y}  x {x}")
                imgui.same_line()
                imgui.text_colored(color("number"), f"{float(value):.6g}")

        if data.ndim >= 3:
            self.pixel_trace(item)
        if item.show_hist:
            self.histogram(item)

    def pixel_trace(self, item: Item):
        if item.pixel is None:
            imgui.text_disabled("hover a pixel to plot its trace over axis 0")
            return
        y, x = item.pixel
        trace = item.data[(slice(None),) + tuple(item.index[1:]) + (y, x)].astype(np.float64)
        if implot.begin_plot(f"pixel y={y} x={x} over axis 0##trace{id(item)}", imgui.ImVec2(-1, px(TRACE_HEIGHT))):
            try:
                implot.setup_axes("axis 0", "value")
                implot.setup_legend(implot.Location_.north_east)
                implot.plot_line(f"y={y} x={x}", trace)
                implot.plot_inf_lines("frame", np.array([float(item.index[0])]))
            finally:
                implot.end_plot()

    def histogram(self, item: Item):
        if implot.begin_plot(f"values##hist{id(item)}", imgui.ImVec2(-1, px(TRACE_HEIGHT))):
            try:
                implot.setup_axes("value", "count")
                implot.plot_histogram("all values", item.sample.astype(np.float64), 200)
                if item.data.ndim >= 2:
                    implot.plot_inf_lines("contrast", np.array([item.vmin, item.vmax]))
            finally:
                implot.end_plot()


# -- the run configs page: the gear on the toolbar, ,dv in nvim ---------------
# the store config/run_configs.lua (,dd) keeps: per project root, its saved
# lines, and under "variables" its `NAME = value` data locations
VARIABLE = re.compile(r"^\s*(?:export\s+)?\$?([A-Za-z_]\w*)\s*=\s*(.*?)\s*$")  # run_configs.lua's parse_variables
NO_HELP = "doesn't look like it reads arguments, so --help would run it"
# the buttons under a config: (action for run_configs.from_viewer, codicon, name, color, tooltip)
ACTIONS = [
    ("debug", "", "Debug", "accent", "Debug it in nvim  (<CR> in ,dd)"),
    ("run_to_cursor", "", "Run to nvim cursor", "ok",
     "Debug it, stopping only at the line nvim's cursor is on  (,s)"),
    ("run", "", "Run", "number", "Run it without the debugger, in an nvim terminal"),
    ("copy", "", "Copy as shell command", "fg",
     "The command with its $NAMEs filled in, for a terminal or a SLURM script"),
]
ICONS = {"add": "", "copy": "", "delete": "", "close": "", "reload": "",
         "file": "", "folder": ""}


def icon(name: str, text: str) -> str:
    return ICONS[name] if "regular" in fonts else text


def tilde(path: str) -> str:
    home = os.path.expanduser("~")
    return "~" + path[len(home):] if path == home or path.startswith(home + "/") else path


def default_store() -> str:
    data = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    return os.path.join(data, "nvim", "run_configs.json")


def as_list(value) -> list:
    return value if isinstance(value, list) else []  # nvim's json writes an empty table as {}


def entries_of(lines: list) -> list[dict]:
    """Saved lines -> configs {name, line} and notes {note}: a # line right
    above a command is its name (run_configs.lua's named())."""
    entries = []
    for line in lines:
        if not isinstance(line, str) or not line.strip():
            continue
        if line.lstrip().startswith("#"):
            entries.append({"note": line})
        elif entries and "note" in entries[-1]:
            entries.append({"name": entries.pop()["note"].lstrip()[1:].strip(), "line": line})
        else:
            entries.append({"name": "", "line": line})
    return entries


def lines_of(entries: list[dict]) -> list[str]:
    lines = []
    for entry in entries:
        if "note" in entry:
            lines.append(entry["note"])
        elif entry["line"].strip():  # a config with no command yet isn't saved
            lines += ([f"# {entry['name'].strip()}"] if entry["name"].strip() else []) + [entry["line"].strip()]
    return lines


def locations_of(lines: list) -> list[dict]:
    """`NAME = value` lines -> {name, value}; other lines kept as {raw}."""
    locations = []
    for line in lines:
        if not isinstance(line, str) or not line.strip():
            continue
        found = VARIABLE.match(line)
        if found:
            value = found.group(2)
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            locations.append({"name": found.group(1), "value": value})
        else:
            locations.append({"raw": line})
    return locations


def variable_lines(locations: list[dict]) -> list[str]:
    return [loc["raw"] if "raw" in loc else f"{loc['name']} = {loc['value']}"
            for loc in locations if "raw" in loc or loc["name"]]


def script_parses_args(path: str) -> bool:
    try:
        with open(path, errors="replace") as f:
            return bool(cli.PARSES_ARGS.search(f.read(512_000)))
    except OSError:
        return False


def reads_arguments(how: dict) -> bool:
    """Whether `command --help` only prints help: an env command (masknmf,
    pytest), an installed module, or a project file that parses its
    arguments. A plain script would just run."""
    if how.get("installed"):
        return True
    cwd = how.get("cwd") or "."
    if how.get("module"):
        parts = how["module"].split(".")
        for base in (cwd, os.path.join(cwd, "src")):
            for path in (os.path.join(base, *parts) + ".py", os.path.join(base, *parts, "__main__.py")):
                if os.path.isfile(path):
                    return script_parses_args(path)
        return True  # not the project's: an installed tool
    path = os.path.join(cwd, how.get("program") or "")
    return os.path.isfile(path) and script_parses_args(path)


def program(line: str) -> str:
    """Which program a line runs: its first word, or -m and the module."""
    tokens = cli.split(line)
    return cli.join(tokens[:2] if tokens[:1] == ["-m"] else tokens[:1])


def copy_text(text: str) -> bool:
    """To the Wayland clipboard; False if there's no wl-copy (imgui's then)."""
    if os.environ.get("WAYLAND_DISPLAY") and shutil.which("wl-copy"):
        subprocess.run(["wl-copy"], input=text, text=True, timeout=5)
        return True
    return False


class ConfigsPage:
    """The saved commands of config/run_configs.lua (,dd) as forms, and the
    project's data locations. Reads and writes the same store as ,dd; each
    form comes from the command's --help (nvim_sciview_form), and the buttons
    go through nvim (run_configs.from_viewer), which fills in $NAMEs the way
    ,dd does."""

    def __init__(self, viewer: "Viewer"):
        self.viewer = viewer
        self.root: str | None = None
        self.store = default_store()
        self.entries: list[dict] = []  # entries_of() the project's lines
        self.locations: list[dict] = []
        self.selected = 0  # index into configs()
        self.mtime = None  # the store's, when last read or written
        self.checked = 0.0  # when the store's mtime was last looked at
        self.dirty_at: float | None = None  # edited, not saved yet
        self.specs: dict = {}  # (root, help line) -> cli.Spec, "loading", or why there's none
        self.known: dict = {}  # line -> the Spec its form was drawn with
        self.forced: set = set()  # programs whose --help is read even though they look unsafe
        self.editing: dict = {}  # field id -> its text while typed in
        self.front: dict = {}  # (config, spec) -> names shown above "more flags"
        self.filter = ""
        self.dialog = None  # (portable file dialog, what to do with the path)
        self.clipboard: str | None = None  # for imgui's clipboard, set on the ui thread
        self.status = ("", "dim")
        self.exists: dict = {}  # path -> (it exists, when checked)
        self.deleting = False

    # -- the store --------------------------------------------------------
    def configs(self) -> list[dict]:
        return [e for e in self.entries if "line" in e]

    def open(self, root: str | None = None, store: str | None = None):
        if self.dirty_at:
            self.save()
        if store:
            self.store = store
        if root and root != self.root:
            self.root, self.selected, self.status = root, 0, ("", "dim")
            self.editing.clear()
        self.load()

    def close(self):
        if self.dirty_at:
            self.save()

    def read(self) -> dict:
        try:
            with open(self.store) as f:
                data = json.load(f)
            return data if isinstance(data, dict) else {}
        except (OSError, ValueError):
            return {}

    def load(self):
        configs = self.configs()
        current = configs[self.selected] if 0 <= self.selected < len(configs) else None
        data = self.read()
        try:
            self.mtime = os.stat(self.store).st_mtime_ns
        except OSError:
            self.mtime = None
        variables = data.get("variables") if isinstance(data.get("variables"), dict) else {}
        self.entries = entries_of(as_list(data.get(self.root)))
        self.locations = locations_of(as_list(variables.get(self.root)))
        configs = self.configs()
        if current:  # stay on it if it's still there
            same = [i for i, e in enumerate(configs) if e["line"] == current["line"] or (
                current["name"] and e["name"] == current["name"])]
            self.selected = same[0] if same else min(self.selected, max(len(configs) - 1, 0))
        self.dirty_at = None

    def save(self):
        if not self.root:
            return
        data = self.read()
        lines, variables = lines_of(self.entries), variable_lines(self.locations)
        if lines:
            data[self.root] = lines
        else:
            data.pop(self.root, None)
        per_root = data.get("variables") if isinstance(data.get("variables"), dict) else {}
        if variables:
            per_root[self.root] = variables
        else:
            per_root.pop(self.root, None)
        data["variables"] = per_root
        try:
            os.makedirs(os.path.dirname(self.store), exist_ok=True)
            with open(self.store + ".tmp", "w") as f:
                json.dump(data, f)
            os.replace(self.store + ".tmp", self.store)
            self.mtime = os.stat(self.store).st_mtime_ns
        except OSError as error:
            self.status = (f"could not save: {error}", "error")
        self.dirty_at = None
        # why a --help couldn't be read may be fixed now (a data location added)
        for key in [k for k, v in self.specs.items() if k[0] == self.root and isinstance(v, str) and v != "loading"]:
            del self.specs[key]

    def touch(self):
        self.dirty_at = time.monotonic()

    def poll(self):
        """Each frame: a file dialog's answer, saving after edits, and ,dd's
        edits (the store changed on disk)."""
        if self.dialog and self.dialog[0].ready(0):
            dialog, done = self.dialog
            self.dialog = None
            result = dialog.result()
            path = result[0] if isinstance(result, list) and result else result if isinstance(result, str) else ""
            if path:
                done(tilde(path))
        if self.clipboard is not None:
            imgui.set_clipboard_text(self.clipboard)
            self.clipboard = None
        now = time.monotonic()
        if self.dirty_at and now - self.dirty_at > 0.5 and not imgui.is_any_item_active():
            self.save()
        if now - self.checked > 1.0 and not self.dirty_at:
            self.checked = now
            try:
                mtime = os.stat(self.store).st_mtime_ns
            except OSError:
                mtime = None
            if mtime != self.mtime:
                self.load()

    def projects(self) -> list[str]:
        data = self.read()
        roots = {k for k in data if k not in ("variables", "last")}
        if isinstance(data.get("variables"), dict):
            roots |= set(data["variables"])
        return sorted(roots | ({self.root} if self.root else set()), key=lambda r: os.path.basename(r).lower())

    # -- --help -----------------------------------------------------------
    def spec(self, entry: dict):
        """The Spec to draw entry's form with, and a note about its --help:
        "loading", or why there's none."""
        line = entry["line"]
        if not cli.split(line):
            return None, None
        last = entry.get("spec") or self.known.get(line)
        # a new command: its own --help, not the last one's
        key_line = cli.help_line(cli.parse_line(line, last), last) if last and not entry.get("fresh") else line
        key = (self.root, key_line)
        entry["help_key"] = key_line
        got = self.specs.get(key)
        if got is None:
            self.read_help(key_line)
            got = "loading"
        if isinstance(got, cli.Spec):
            entry["spec"], self.known[line] = got, got
            entry.pop("fresh", None)
            if got.whole_line:  # also filed under the part of the line it depends on, as later edits ask for it
                self.specs.setdefault((self.root, cli.help_line(cli.parse_line(line, got), got)), got)
            return got, None
        return last, got

    def read_help(self, line: str):
        key, forced = (self.root, line), program(line) in self.forced
        self.specs[key] = "loading"

        def run():
            try:
                self.specs[key] = self.fetch_help(key[0], line, forced)
            except Exception as error:
                self.specs[key] = f"could not read --help: {error}"

        threading.Thread(target=run, daemon=True).start()

    def fetch_help(self, root: str, line: str, forced: bool):
        if not self.viewer.nvim:
            return "started without --nvim: can't read --help"
        def resolve(line):
            return self.viewer.ask_nvim("require'config.run_configs'.from_viewer",
                                        json.dumps({"action": "resolve", "root": root, "line": line}))

        asked = line
        how = resolve(line)
        if "not set" in how.get("error", ""):  # an undefined $NAME needn't keep the form away
            line = cli.join([t for t in cli.split(line) if "$" not in t])
            how = resolve(line)
        if how.get("error"):
            return how["error"]
        if not forced and not reads_arguments(how):
            return NO_HELP
        argv, env = how["argv"], {**os.environ, **(how.get("env") or {})}
        head = 3 if how.get("module") else 2  # python -m module, python program
        leading = []
        for arg in argv[head:]:
            if arg.startswith("-"):
                break
            leading.append(arg)
        # the whole line (masknmf's flags depend on --pipeline), else less of it
        for attempt in dict.fromkeys(map(tuple, (argv, argv[:head] + leading, argv[:head]))):
            whole = list(attempt) == argv and line == asked
            try:
                done = subprocess.run([*attempt, "--help"], cwd=how.get("cwd"), env=env, capture_output=True,
                                      text=True, timeout=90, stdin=subprocess.DEVNULL)
            except subprocess.TimeoutExpired:
                return "--help took over 90 s"
            spec = (cli.parse_help(done.stdout) or cli.parse_help(done.stderr)) if done.returncode == 0 else None
            if spec:
                spec.whole_line = whole
                return spec
        return "no argparse --help: edit the command line below"

    # -- actions ----------------------------------------------------------
    def act(self, action: str, entry: dict):
        if self.dirty_at:
            self.save()  # nvim reads the data locations from the store
        request = {"action": "resolve" if action == "copy" else action, "root": self.root,
                   "line": entry["line"], "name": entry["name"].strip() or None}
        self.status = ("asking nvim...", "dim")

        def run():
            try:
                answer = self.viewer.ask_nvim("require'config.run_configs'.from_viewer", json.dumps(request))
            except Exception as error:
                self.status = (f"could not reach nvim: {error}", "error")
                return
            if answer.get("error"):
                self.status = (answer["error"], "error")
            elif action == "copy":
                if not copy_text(answer["shell"]):
                    self.clipboard = answer["shell"]
                self.status = (f"copied: {answer['shell']}", "ok")
            else:
                self.status = (answer.get("ok", ""), "ok")

        threading.Thread(target=run, daemon=True).start()

    def put(self, entry: dict, arg: cli.Arg, token: str):
        """A picked data location or path into a field: added to one taking
        several values, else in place of its value."""
        spec = entry.get("spec")
        parsed = cli.parse_line(entry["line"], spec)
        values = parsed.values.get(arg.name, []) if arg.several else []
        parsed.values[arg.name] = [*values, token]
        entry["line"] = cli.to_line(parsed, spec)
        self.editing.clear()
        self.touch()

    def choose(self, title: str, start: str, folder: bool, done):
        """A file or folder dialog (zenity); `done(path)` once it's answered."""
        start = os.path.expanduser(start or "")
        if start and not os.path.isdir(start):
            start = os.path.dirname(start)
        start = start if os.path.isdir(start) else (self.root or os.path.expanduser("~"))
        dialog = pfd.select_folder(title, start) if folder else pfd.open_file(title, start)
        self.dialog = (dialog, done)

    def path_exists(self, value: str) -> bool:
        cached = self.exists.get(value)
        if cached and time.monotonic() - cached[1] < 2.0:
            return cached[0]
        found = os.path.exists(os.path.expanduser(value))
        self.exists[value] = (found, time.monotonic())
        return found

    # -- drawing ----------------------------------------------------------
    def text_field(self, fid: str, text: str, hint: str, width: float) -> tuple[bool, str]:
        """An input that keeps what you type while you're in it (the line is
        re-read from the fields every frame, which would eat a trailing space)."""
        shown = self.editing.get(fid, text)
        imgui.set_next_item_width(width)
        changed, new = imgui.input_text_with_hint(f"##{fid}", hint, shown)
        if imgui.is_item_active():
            self.editing[fid] = new
        else:
            self.editing.pop(fid, None)
        return changed, new

    def draw(self):
        self.poll()
        bold("Run configs", "accent")
        imgui.same_line(0, px(12))
        if self.root:
            imgui.set_next_item_width(px(260))
            if imgui.begin_combo("##project", os.path.basename(self.root) or self.root):
                for root in self.projects():
                    if imgui.selectable(f"{os.path.basename(root)}   {tilde(root)}", root == self.root)[0]:
                        self.open(root)
                imgui.end_combo()
            if imgui.is_item_hovered():
                imgui.set_tooltip(f"{tilde(self.root)}\nsaved with ,dd's commands in {tilde(self.store)}")
        else:
            imgui.text_colored(color("dim"), "asking nvim which project...")
        imgui.same_line(imgui.get_window_width() - px(52))
        if imgui.button(f"{icon('close', 'x')}##close_page", imgui.ImVec2(px(30), 0)):
            self.viewer.toggle_page()
        if imgui.is_item_hovered():
            imgui.set_tooltip("Back to the arrays  (or the gear)")
        if not self.root:
            return

        row = imgui.get_frame_height_with_spacing()
        data_height = (min(max(len(self.locations), 1), 6) + 2.6) * row
        avail = imgui.get_content_region_avail()
        imgui.begin_child("##configs_top", imgui.ImVec2(0, max(avail.y - data_height, row * 8)))
        self.config_list()
        imgui.same_line()
        imgui.begin_child("##form", imgui.ImVec2(0, 0), imgui.ChildFlags_.always_use_window_padding)
        self.config_form()
        imgui.end_child()
        imgui.end_child()
        self.data_locations()

    def config_list(self):
        configs = self.configs()
        imgui.push_style_color(imgui.Col_.child_bg, color("bg", toward="raised", t=0.25))
        imgui.begin_child("##list", imgui.ImVec2(px(230), 0),
                          imgui.ChildFlags_.borders | imgui.ChildFlags_.resize_x | imgui.ChildFlags_.always_use_window_padding)
        imgui.pop_style_color()
        imgui.text_colored(color("dim"), "CONFIGS")
        imgui.same_line(imgui.get_window_width() - px(104))
        if imgui.small_button(f"{icon('add', '+')}##add_config"):
            self.entries.append({"name": "new config", "line": ""})
            self.selected = len(self.configs()) - 1
            self.touch()
        if imgui.is_item_hovered():
            imgui.set_tooltip("New config")
        current = configs[self.selected] if 0 <= self.selected < len(configs) else None
        imgui.same_line()
        if current is None:
            imgui.begin_disabled()
        if imgui.small_button(f"{icon('copy', 'copy')}##duplicate"):
            copy = {"name": (current["name"] or "config") + " copy", "line": current["line"]}
            self.entries.insert(self.entries.index(current) + 1, copy)
            self.selected += 1
            self.touch()
        if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
            imgui.set_tooltip("Duplicate")
        imgui.same_line()
        if imgui.small_button(f"{icon('delete', '-')}##delete"):
            imgui.open_popup("delete config")
        if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
            imgui.set_tooltip("Delete")
        if current is None:
            imgui.end_disabled()
        if imgui.begin_popup("delete config"):
            imgui.text(f"Delete \"{current['name'] or current['line']}\"?" if current else "")
            if imgui.button("Delete") and current:
                self.entries.remove(current)
                self.selected = max(0, min(self.selected, len(self.configs()) - 1))
                self.touch()
                imgui.close_current_popup()
            imgui.same_line()
            if imgui.button("Cancel"):
                imgui.close_current_popup()
            imgui.end_popup()
        imgui.spacing()
        for i, entry in enumerate(configs):
            label = entry["name"].strip() or entry["line"].strip() or "(empty)"
            if imgui.selectable(f"{label}##config{i}", i == self.selected)[0]:
                self.selected = i
            if imgui.is_item_hovered() and entry["line"]:
                imgui.set_tooltip(entry["line"])
        if not configs:
            imgui.text_wrapped("None yet: + adds one, or ,dd in nvim.")
        imgui.end_child()

    def config_form(self):
        configs = self.configs()
        if not configs:
            imgui.text_colored(color("dim"), "No run configs for this project yet.")
            return
        self.selected = max(0, min(self.selected, len(configs) - 1))
        entry = configs[self.selected]
        uid = id(entry)
        width = imgui.get_content_region_avail().x
        label_width = px(180)

        flags = imgui.TableFlags_.sizing_fixed_fit | imgui.TableFlags_.no_borders_in_body
        if imgui.begin_table("##head", 2, flags):
            imgui.table_setup_column("label", imgui.TableColumnFlags_.width_fixed, label_width)
            imgui.table_setup_column("field", imgui.TableColumnFlags_.width_stretch)
            self.label("Name", "Shown in the list; saved as a # line above the command, so ,dd shows it too")
            changed, text = self.text_field(f"{uid}:name", entry["name"], "a name for the list", -1)
            if changed:
                entry["name"] = text
                self.touch()
            spec, note = self.spec(entry)
            parsed = cli.parse_line(entry["line"], spec)
            self.label("Command", "The program and its subcommands: masknmf run, scripts/foo.py, -m package.module")
            reload_width = px(34)
            changed, text = self.text_field(f"{uid}:command", cli.join(parsed.command), "masknmf run, a script, or -m module",
                                            imgui.get_content_region_avail().x - reload_width - px(8))
            if changed:
                parsed.command = cli.split(text)
                entry["line"] = cli.to_line(parsed, spec)
                entry["fresh"] = True
                self.touch()
            imgui.same_line()
            if imgui.button(f"{icon('reload', 'reload')}##help{uid}", imgui.ImVec2(reload_width, 0)):
                for key in [k for k, v in self.specs.items() if k[0] == self.root and v != "loading"]:
                    del self.specs[key]
                entry["fresh"] = True
            if imgui.is_item_hovered():
                imgui.set_tooltip("Read its --help again (after changing the code that parses its arguments)")
            imgui.end_table()
        if note == "loading":
            imgui.text_colored(color("dim"), f"reading {cli.join(parsed.command)} --help...")
        elif note:
            imgui.text_colored(color("number" if note == NO_HELP else "error"),
                               f"{cli.join(parsed.command) or 'it'} {note}" if note == NO_HELP else note)
            if note == NO_HELP:
                imgui.same_line()
                if imgui.small_button("read it anyway"):
                    self.forced.add(program(entry["line"]))
                    self.specs.pop((self.root, entry.get("help_key")), None)

        if spec:
            self.fields(entry, spec, parsed, label_width)

        heading("COMMAND LINE")
        imgui.set_next_item_width(-1)
        fid = f"{uid}:line"
        shown = self.editing.get(fid, entry["line"])
        changed, text = imgui.input_text_multiline(f"##{fid}", shown, imgui.ImVec2(-1, imgui.get_text_line_height() * 3 + px(10)),
                                                   imgui.InputTextFlags_.word_wrap if hasattr(imgui.InputTextFlags_, "word_wrap") else 0)
        if imgui.is_item_active():
            self.editing[fid] = text
        else:
            self.editing.pop(fid, None)
        if changed:
            entry["line"] = " ".join(text.split("\n"))
            self.touch()
        imgui.spacing()
        usable = bool(self.viewer.nvim and cli.split(entry["line"]))
        for i, (action, glyph, name, role, tip) in enumerate(ACTIONS):
            if i:
                imgui.same_line()
            if not usable:
                imgui.begin_disabled()
            imgui.push_style_color(imgui.Col_.text, color(role))
            if imgui.button(f"{glyph}  {name}" if "regular" in fonts else name, imgui.ImVec2(0, px(28))):
                self.act(action, entry)
            imgui.pop_style_color()
            if not usable:
                imgui.end_disabled()
            if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
                imgui.set_tooltip(tip if self.viewer.nvim else "started without --nvim")
        text, role = self.status
        if text:
            imgui.push_style_color(imgui.Col_.text, color(role))
            imgui.text_wrapped(text)
            imgui.pop_style_color()

    def label(self, text: str, tip: str, role: str = "fg"):
        imgui.table_next_row()
        imgui.table_next_column()
        imgui.align_text_to_frame_padding()
        imgui.text_colored(color(role), text)
        if imgui.is_item_hovered() and tip:
            imgui.set_tooltip(tip)
        imgui.table_next_column()

    def fields(self, entry: dict, spec: cli.Spec, parsed: cli.Form, label_width: float):
        """A row per argument: the positionals, required and set ones first
        (as of when the config was picked, so a field doesn't jump while you
        fill it in), the rest under "more flags"."""
        key = (id(entry), id(spec))
        if key not in self.front:
            self.front[key] = {a.name for a in spec.args if a.positional or a.required or a.name in parsed.values}
        front = self.front[key]
        flags = imgui.TableFlags_.sizing_fixed_fit | imgui.TableFlags_.no_borders_in_body | imgui.TableFlags_.row_bg
        heading("ARGUMENTS")
        changed = False
        if imgui.begin_table("##fields", 2, flags):
            imgui.table_setup_column("label", imgui.TableColumnFlags_.width_fixed, label_width)
            imgui.table_setup_column("field", imgui.TableColumnFlags_.width_stretch)
            for arg in spec.args:
                if arg.name in front:
                    changed |= self.field(entry, spec, parsed, arg)
            self.label("extra args", "Anything the --help doesn't list, passed on as typed")
            fid = f"{id(entry)}:extra"
            moved, text = self.text_field(fid, cli.join(parsed.extra), "passed on as typed", -1)
            if moved:
                parsed.extra, changed = cli.split(text), True
            imgui.end_table()
        more = [a for a in spec.args if a.name not in front]
        if "more flags" in self.viewer.force_open:  # testing
            imgui.set_next_item_open(True, imgui.Cond_.once)
        if more and imgui.tree_node_ex(f"more flags ({len(more)})##more{id(entry)}", imgui.TreeNodeFlags_.span_avail_width):
            if len(more) > 10:
                imgui.set_next_item_width(px(240))
                _, self.filter = imgui.input_text_with_hint("##filter", "filter", self.filter)
            wanted = self.filter.lower()
            groups = {a.group for a in more}
            if imgui.begin_table("##more_fields", 2, flags):
                imgui.table_setup_column("label", imgui.TableColumnFlags_.width_fixed, label_width - imgui.get_style().indent_spacing)
                imgui.table_setup_column("field", imgui.TableColumnFlags_.width_stretch)
                group = None
                for arg in more:
                    if wanted and wanted not in arg.name.lower() and wanted not in arg.help.lower():
                        continue
                    if len(groups) > 2 and arg.group != group:
                        group = arg.group
                        imgui.table_next_row()
                        imgui.table_next_column()
                        imgui.text_colored(color("dim"), group)
                    changed |= self.field(entry, spec, parsed, arg)
                imgui.end_table()
            imgui.tree_pop()
        if changed:
            entry["line"] = cli.to_line(parsed, spec)
            self.touch()

    def field(self, entry: dict, spec: cli.Spec, parsed: cli.Form, arg: cli.Arg) -> bool:
        """One argument's row: a checkbox (a switch), a dropdown (choices), or
        text with a picker for data locations, files and folders."""
        values = parsed.values.get(arg.name)
        missing = arg.required and not values and arg.nargs != "0"
        tip = "\n".join(filter(None, [
            arg.help,
            "also " + ", ".join(f for f in arg.flags if f != parsed.used.get(arg.name, arg.name)) if len(arg.flags) > 1 else "",
            "required" if arg.required else "",
        ]))
        self.label(parsed.used.get(arg.name, arg.name), tip, "error" if missing else "fg" if values is not None else "dim")
        fid = f"{id(entry)}:{arg.name}"

        def set_values(new):
            if new is None:
                parsed.values.pop(arg.name, None)
                parsed.used.pop(arg.name, None)
                parsed.joined.discard(arg.name)
            else:
                parsed.values[arg.name] = new

        if arg.nargs == "0":
            clicked, on = imgui.checkbox(f"##{fid}", values is not None)
            if clicked:
                set_values([] if on else None)
            return clicked
        unset = f"default: {arg.default}" if arg.default not in (None, "None", "") else "not set"
        if arg.choices and not arg.several:
            imgui.set_next_item_width(-1)
            changed = False
            if imgui.begin_combo(f"##{fid}", values[0] if values else unset):
                if imgui.selectable(unset, not values)[0]:
                    set_values(None)
                    changed = True
                for choice in arg.choices + ([values[0]] if values and values[0] not in arg.choices else []):
                    if imgui.selectable(choice, values == [choice])[0]:
                        set_values([choice])
                        changed = True
                imgui.end_combo()
            return changed
        # a number takes no path: no picker
        pick = not re.fullmatch(r"-?[\d.]+(?:e-?\d+)?", arg.default or "")
        hint = unset if unset != "not set" else (arg.metavar or "value")
        if arg.several:
            hint += "  (several: space separated)"
        changed, text = self.text_field(fid, cli.join(values or []), hint,
                                        imgui.get_content_region_avail().x - (px(42) if pick else 0))
        if changed:
            tokens = cli.split(text)
            set_values(tokens if tokens else None)
        if pick:
            imgui.same_line()
            self.picker(fid, entry, arg)
        return changed

    def picker(self, fid: str, entry: dict, arg: cli.Arg):
        if self.dialog:
            imgui.begin_disabled()
        if imgui.button(f"{icon('folder', '...')}##pick{fid}", imgui.ImVec2(px(34), 0)):
            imgui.open_popup(f"pick##{fid}")
        if self.dialog:
            imgui.end_disabled()
        if imgui.is_item_hovered():
            imgui.set_tooltip("A data location, a file or a folder" + ("  (added to the others)" if arg.several else ""))
        if imgui.begin_popup(f"pick##{fid}"):
            imgui.text_colored(color("dim"), "DATA LOCATIONS")
            named = [loc for loc in self.locations if loc.get("name")]
            for loc in named:
                if imgui.selectable(f"${loc['name']}##{fid}{loc['name']}")[0]:
                    self.put(entry, arg, "$" + loc["name"])
                imgui.same_line()
                imgui.text_colored(color("dim"), loc["value"])
            if not named:
                imgui.text_disabled("none yet: add them below the form")
            imgui.separator()
            if imgui.selectable(f"{icon('file', '')} File...")[0]:
                self.choose(arg.name, "", False, lambda path: self.put(entry, arg, path))
            if imgui.selectable(f"{icon('folder', '')} Folder...")[0]:
                self.choose(arg.name, "", True, lambda path: self.put(entry, arg, path))
            imgui.end_popup()

    def data_locations(self):
        heading("DATA LOCATIONS")
        if imgui.small_button(f"{icon('add', '+')} Add##location"):
            taken = {loc.get("name") for loc in self.locations}
            name = next(n for n in (f"DATA{k}" if k else "DATA" for k in range(1000)) if n not in taken)
            self.locations.append({"name": name, "value": ""})
            self.touch()
        imgui.same_line(0, px(12))
        imgui.text_colored(color("dim"), "a field's folder button picks one, or type $NAME in a command (,dd: Variables)")
        named = [loc for loc in self.locations if "raw" not in loc]
        flags = imgui.TableFlags_.sizing_fixed_fit | imgui.TableFlags_.no_borders_in_body | imgui.TableFlags_.row_bg
        imgui.begin_child("##locations", imgui.ImVec2(0, 0))
        if imgui.begin_table("##location_rows", 3, flags):
            imgui.table_setup_column("name", imgui.TableColumnFlags_.width_fixed, px(170))
            imgui.table_setup_column("path", imgui.TableColumnFlags_.width_stretch)
            imgui.table_setup_column("buttons", imgui.TableColumnFlags_.width_fixed, px(124))
            names = [loc["name"] for loc in named]
            for k, loc in enumerate(named):
                imgui.table_next_row()
                imgui.table_next_column()
                lid = f"location{k}"
                twice = names.count(loc["name"]) > 1
                if twice or not loc["name"]:
                    imgui.push_style_color(imgui.Col_.text, color("error"))
                changed, text = self.text_field(f"{lid}:name", loc["name"], "NAME", -1)
                if twice or not loc["name"]:
                    imgui.pop_style_color()
                if imgui.is_item_hovered():
                    imgui.set_tooltip("used twice: the first one counts" if twice else f"${loc['name']} in a command")
                if changed:
                    name = re.sub(r"\W", "", text)
                    loc["name"] = "_" + name if name[:1].isdigit() else name
                    self.touch()
                imgui.table_next_column()
                gone = bool(loc["value"]) and not self.path_exists(loc["value"])
                note_width = imgui.calc_text_size("not found").x + px(10) if gone else 0
                changed, text = self.text_field(f"{lid}:value", loc["value"], "a file or folder: ~/data/movie.tif",
                                                imgui.get_content_region_avail().x - note_width)
                if changed:
                    loc["value"] = text.strip()
                    self.touch()
                if gone:
                    imgui.same_line()
                    imgui.text_colored(color("error"), "not found")
                imgui.table_next_column()

                def set_value(path, loc=loc):
                    loc["value"] = path
                    self.editing.clear()
                    self.touch()

                if self.dialog:
                    imgui.begin_disabled()
                if imgui.button(f"{icon('file', 'file')}##{lid}file", imgui.ImVec2(px(34), 0)):
                    self.choose(loc["name"] or "file", loc["value"], False, set_value)
                if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
                    imgui.set_tooltip("Pick a file")
                imgui.same_line(0, px(4))
                if imgui.button(f"{icon('folder', 'dir')}##{lid}folder", imgui.ImVec2(px(34), 0)):
                    self.choose(loc["name"] or "folder", loc["value"], True, set_value)
                if imgui.is_item_hovered(imgui.HoveredFlags_.allow_when_disabled):
                    imgui.set_tooltip("Pick a folder")
                if self.dialog:
                    imgui.end_disabled()
                imgui.same_line(0, px(4))
                if imgui.button(f"{icon('delete', 'x')}##{lid}remove", imgui.ImVec2(px(34), 0)):
                    self.locations.remove(loc)
                    self.editing.clear()
                    self.touch()
                if imgui.is_item_hovered():
                    imgui.set_tooltip("Remove")
            imgui.end_table()
        if not named:
            imgui.text_disabled("None yet: + Add, then pick a file or folder.")
        imgui.end_child()


def already_running(path: str) -> bool:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(1)
            sock.connect(path)
            sock.sendall(b'{"ping": true}\n')
            return sock.makefile().readline().strip() == "ok"
    except OSError:
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nvim", help="the nvim (v:servername) to ask for clicked variables")
    parser.add_argument("--theme", help="json {role: '#rrggbb'} of colors (nvim sends its colorscheme)")
    parser.add_argument("--test-frames", type=int, default=0, help="testing: hidden window, run N frames, then exit")
    parser.add_argument("--screenshot", help="testing: save the last frame as a PNG")
    parser.add_argument("--test-mouse", help="testing: x,y window position to put the mouse at")
    parser.add_argument("--test-size", help="testing: WxH window size (logical, before the dpi factor)")
    parser.add_argument("--test-click", help="testing: click this variable once the variables arrive")
    parser.add_argument("--test-open", action="append", default=[], help="testing: open this row of the explorer (repeatable)")
    parser.add_argument("--test-configs", action="store_true", help="testing: start on the run configs page")
    args = parser.parse_args()

    path = send.socket_path()
    if already_running(path):
        print("sciview already running")
        return
    if os.path.exists(path):
        os.unlink(path)  # left by a viewer that didn't exit cleanly
    viewer = Viewer(args.nvim)
    threading.Thread(target=viewer.serve, args=(path,), daemon=True).start()
    if args.test_configs:
        viewer.toggle_page()

    if args.theme:
        THEME.update({k: v for k, v in json.loads(args.theme).items() if isinstance(v, str) and v.startswith("#")})
    global UI_SCALE
    scale = display_scale()
    UI_SCALE = scale or 1.0
    params = hello_imgui.RunnerParams()
    if scale:
        params.dpi_aware_params.dpi_window_size_factor = scale
    params.app_window_params.window_title = "sciview"
    params.app_window_params.window_geometry.size = (1280, 900)  # hello_imgui applies the dpi factor itself
    params.imgui_window_params.default_imgui_window_type = hello_imgui.DefaultImGuiWindowType.provide_full_screen_window
    params.callbacks.show_gui = viewer.gui
    params.callbacks.load_additional_fonts = load_fonts
    params.callbacks.setup_imgui_style = setup_style
    params.fps_idling.fps_idle = 15  # still polls the socket queue when idle
    # the remembered layout (explorer width) goes in ~/.config/sciview, not the cwd
    params.ini_folder_type = hello_imgui.IniFolderType.app_user_config_folder
    params.ini_filename = "sciview/sciview.ini"
    if args.test_size:
        params.app_window_params.window_geometry.size = tuple(int(v) for v in args.test_size.split("x"))
    if args.test_frames:
        params.app_window_params.hidden = True
        params.ini_disable = True
        params.fps_idling.enable_idling = False
        frames = [0]

        def count():
            if args.test_click and viewer.frame_vars and frames[0] % 40 == 20:
                if not any(it.label == args.test_click for it in viewer.items) and viewer.pending is None:
                    print(f"frame {frames[0]}: clicking {args.test_click}", flush=True)
                    viewer.request(args.test_click)
                elif any(it.label == args.test_click for it in viewer.items):
                    viewer.current = next(i for i, it in enumerate(viewer.items) if it.label == args.test_click)
            viewer.force_open.update(args.test_open)
            if args.test_mouse:
                x, y = (float(v) for v in args.test_mouse.split(","))
                imgui.get_io().add_mouse_pos_event(x, y)
            # exercise every view: each array in turn, with hover, playback
            # and the histogram on (errors raised while drawing fail the run)
            frames[0] += 1
            if viewer.items and frames[0] % 40 == 0 and not args.test_click:
                viewer.current = (frames[0] // 40) % len(viewer.items)
                item = viewer.items[viewer.current]
                item.show_hist = not item.show_hist
                item.playing = item.data.ndim >= 3
                if item.data.ndim >= 2:
                    item.pixel = (item.data.shape[-2] // 2, item.data.shape[-1] // 2)
                print(f"frame {frames[0]}: drawing {item.label} hist={item.show_hist}", flush=True)
            if frames[0] >= args.test_frames:
                params.app_shall_exit = True

        params.callbacks.before_imgui_render = count
    try:
        immapp.run(params, immapp.AddOnsParams(with_implot=True))
        if args.screenshot:
            from PIL import Image

            Image.fromarray(hello_imgui.final_app_window_screenshot()).save(args.screenshot)
    finally:
        if os.path.exists(path):
            os.unlink(path)


if __name__ == "__main__":
    main()
