"""sciview: a window for looking at arrays sent from the debugger.

Started by nvim (lua/config/sciview.lua) as its own process, so it stays live
while the debugged program is paused and can't take that program down.
Arrays arrive from python/nvim_sciview_send.py over a unix socket.

  1D     trace plot and histogram
  2D+    image with colormap and contrast; a slider per leading axis (axis 0
         is time: play/pause); hovering a pixel plots its trace over axis 0
Left column: the call stack and the paused frame's variables (sent by nvim on
every pause and frame change; click a frame to move the debugger there, an
array to load it: the viewer asks nvim over its RPC socket, --nvim), then
every array shown so far.

Future: on-demand frames for arrays too big to send whole (a frame server in
the debugged program), GPU tensors shared without a CPU copy (CUDA IPC).
"""

import argparse
import json
import os
import queue
import socket
import subprocess
import threading
import time

import numpy as np
from imgui_bundle import hello_imgui, imgui, immapp, immvision, implot

import nvim_sciview_send as send

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
        self.pending: str | None = None  # a clicked variable on its way
        self.status = ""
        # opened objects: expr -> list of child rows, or "loading" / error text
        self.children: dict[str, list | str] = {}
        self.force_open: set[str] = set()  # testing: rows opened as if clicked
        self.styled = False
        self.scrolled_to = None  # the frame the stack list last scrolled to

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
                    self.frame_vars, self.running = message, False
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
                if message.get("kind") == "running":
                    self.running = True
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
        if self.current < 0:
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

    def variables_panel(self):
        frame = self.frame_vars
        if frame is None:
            pill("waiting", "dim")
            imgui.spacing()
            imgui.text_wrapped("Variables appear here when the debugger pauses.")
            return
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
        if self.running:
            imgui.begin_disabled()
        flags = imgui.TableFlags_.row_bg | imgui.TableFlags_.resizable | imgui.TableFlags_.no_borders_in_body_until_resize
        if imgui.begin_table("##vars", 2, flags):
            # names wider than this are clipped (hover for the full row); drag the divider
            imgui.table_setup_column("name", imgui.TableColumnFlags_.width_fixed, px(150))
            imgui.table_setup_column("value", imgui.TableColumnFlags_.width_stretch)
            self.variable_rows(frame["variables"], frame["stop"])
            imgui.end_table()
        if self.running:
            imgui.end_disabled()

    def stack_rows(self, stack: list, current):
        """The stopped thread's frames, outermost first (like nvim's stack
        pane): click one to go there. Long stacks scroll, kept on the current."""
        row = imgui.get_text_line_height_with_spacing()
        height = min(len(stack), 8) * row + px(4)
        imgui.begin_child("##stack", imgui.ImVec2(0, height))
        if self.running or not self.nvim:
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
        if self.running or not self.nvim:
            imgui.end_disabled()
        imgui.end_child()

    def load(self, expr: str, loaded):
        if self.running:
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
                    if children is None and not self.running:
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
        lines = ["nothing shown yet", "",
                 "click an array or object on the left,", "or press ,m on a variable in nvim"]
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
    args = parser.parse_args()

    path = send.socket_path()
    if already_running(path):
        print("sciview already running")
        return
    if os.path.exists(path):
        os.unlink(path)  # left by a viewer that didn't exit cleanly
    viewer = Viewer(args.nvim)
    threading.Thread(target=viewer.serve, args=(path,), daemon=True).start()

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
