---
name: imgui-layout
description: Dear ImGui layout and spacing reference for imgui_bundle in Python: cursor and item sizes, same_line, text baselines, widths and size arguments, style vars, stack layout, tables, child windows, ImPlot padding and the alignment formulas. Use when placing, sizing or aligning imgui, hello_imgui or implot widgets.
---

# Imgui layout

Names: Python (`imgui.*` unless prefixed). Defaults from `ImGuiStyle::ImGuiStyle()`. `avail` = `get_content_region_avail()`.

## A. Read position and sizes

| call | returns | coords | notes |
|---|---|---|---|
| `get_cursor_screen_pos()` | next emit position | absolute | preferred; matches draw-list coords |
| `get_cursor_pos()` / `_x()` / `_y()` | next emit position | window-local, scroll-affected | |
| `get_cursor_start_pos()` | position right after `begin()` | window-local | ~ `window_padding` |
| `get_content_region_avail()` | room from cursor to right/bottom edge | size | minus scrollbar; inside table/columns = cell |
| `get_window_pos()` / `get_window_size()` / `get_window_width()` / `_height()` | window rect | absolute | local -> absolute conversion only |
| `get_item_rect_min()` / `_max()` / `_size()` | last item bbox | absolute | after `end_group()` = whole group |
| `get_text_line_height()` | `font_size` | | |
| `get_text_line_height_with_spacing()` | `font_size + item_spacing.y` | | pitch of text rows |
| `get_frame_height()` | `font_size + 2*frame_padding.y` | | button height, checkbox square, `color_button` default |
| `get_frame_height_with_spacing()` | `frame_height + item_spacing.y` | | pitch of widget rows |
| `get_font_size()` | scaled font px | | the em unit |
| `calc_text_size(text, text_end=None, hide_text_after_double_hash=False, wrap_width=-1)` | text bbox | size | `True` strips `##id`; `wrap_width` for wrapped height |
| `calc_item_width()` | width next value widget gets | | negatives resolved |
| `get_tree_node_to_label_spacing()` | `font_size + 2*frame_padding.x` | | `bullet()` / `tree_node` label offset |
| `is_rect_visible(size)` / `(min, max)` | clip test | bool | skip offscreen work |
| `get_scroll_x()` / `_y()` / `get_scroll_max_x()` / `_y()` | scroll state | | `max = content - window - decorations` |

## B. Move the cursor

| call | effect | notes |
|---|---|---|
| `set_cursor_screen_pos(pos)` | jump, absolute | must be followed by an item or `dummy`, else content size not extended |
| `set_cursor_pos(pos)` / `_x(x)` / `_y(y)` | jump, window-local | same rule |
| `same_line(offset_from_start_x=0, spacing=-1)` | undo last carriage return | table C |
| `new_line()` | force carriage return | height `font_size`, or current line height if any |
| `spacing()` | blank of `item_spacing.y` | `item_size((0,0))` |
| `dummy(size)` | reserve `size`, no interaction, no nav | `invisible_button` = interactive twin |
| `indent(w=0)` / `unindent(w=0)` | `dc.indent += w` or `indent_spacing` | moves cursor x now |
| `tree_push(id)` / `tree_pop()` | `indent()` + `push_id()` | |
| `bullet()` | circle, cursor x += tree_node_to_label_spacing, stays on line | |
| `separator()` | 1px line to `work_rect.max.x`, no layout height | vertical inside horizontal layout / menu bar |
| `separator_text(label)` | line + label | `separator_text_padding` / `_align` / `_border_size` |
| `align_text_to_frame_padding()` | line height >= `frame_height`; baseline = `frame_padding.y` | before `text()` that precedes a framed widget |
| `begin_group()` / `end_group()` | lock line start x; group becomes one item | `same_line` / `is_item_hovered` / `get_item_rect_size` on it |
| `set_scroll_here_x(r=0.5)` / `_y(r=0.5)` | scroll so cursor visible | `0` = left/top, `0.5` = center, `1` = right/bottom |
| `set_scroll_from_pos_x(local, r)` / `_y` | same, explicit position | `get_cursor_start_pos() + offset` |
| `set_scroll_x(v)` / `_y(v)` | absolute scroll | |

## C. `same_line` cases

| call | `cursor.x` | gap |
|---|---|---|
| `same_line()` | `prev_line.x + item_spacing.x` | default |
| `same_line(0, 0)` | `prev_line.x` | none, touching |
| `same_line(0, w)` | `prev_line.x + w` | `w` |
| `same_line(x)` | `window.pos.x - scroll.x + x + group_offset + columns_offset` | none |
| `same_line(x, w)` | above `+ w` | `w` |

`cursor.y = prev_line.y`; line height and baseline restored from previous line.

## D. Text baseline

| widget | `item_size(size, baseline)` | line height |
|---|---|---|
| `text()` | baseline `0` | `font_size` |
| `button()`, `checkbox()`, `slider*`, `input*`, `combo` | baseline `frame_padding.y` | `frame_height` |
| `small_button()` | `frame_padding.y = 0` | `font_size` |
| `color_button(size < frame_height)` | baseline `0` | `size.y` |
| `align_text_to_frame_padding()` then `text()` | baseline `frame_padding.y` | `frame_height` |

Rule: shorter item shifted down by `curr_line_text_base_offset - baseline`; text after a framed item aligns for free, text before needs `align_text_to_frame_padding()`.

## E. Widths and size arguments

| call | scope |
|---|---|
| `push_item_width(w)` / `pop_item_width()` | value widgets: slider, drag, input, combo, color_edit, list_box |
| `set_next_item_width(w)` | next widget only |
| `imgui.internal.push_multi_items_widths(n, w)` | `drag_float3` style split: `(w - (n-1)*item_inner_spacing.x) / n` |

| value | meaning |
|---|---|
| `w > 0` | pixels |
| `w == 0` (push) | default: `0.65 * window width`, or `16 * font_size` in child/popup |
| `w < 0` | `avail.x + w` |
| `-imgui.FLT_MIN` | fill to right edge |

| size arg | `0` | `< 0` |
|---|---|---|
| `button(label, size)` | text + `2*frame_padding` | `avail + size` |
| `selectable(label, sel, flags, size)` | full width x text height | `avail + size` |
| `begin_child(id, size)` | fill remaining | `avail + size` |
| `input_text_multiline(label, s, size)` | `item_width` x 8 lines | `avail + size` |
| `progress_bar(frac, size=(-FLT_MIN, 0))` | full width | |
| `list_box(label, i, items, height_in_items=-1)` | ~7 items | |
| `plot_lines(..., graph_size)` | `item_width` x `frame_height` | |
| `implot.begin_plot(title, size)` | `plot_default_size` | `avail + size` |
| `implot.colormap_scale(label, lo, hi, size)` | 20px bar + labels, `plot_default_size.y` | `avail + size` |
| `image_button(id, tex, image_size)` | `image_size + 2*frame_padding` | |

## F. Text wrapping and in-rect alignment

| call | effect |
|---|---|
| `push_text_wrap_pos(x=0)` / `pop_text_wrap_pos()` | `< 0` none; `0` wrap at right edge; `> 0` wrap at window-local x |
| `text_wrapped(s)` | push(0) + text + pop; needs a sized window |
| `label_text(label, value)` | value in `item_width`, label after `item_inner_spacing.x` (same as sliders) |
| `bullet_text(s)` | `bullet()` + `text()` |
| `imgui.internal.render_text_clipped(pos_min, pos_max, text, text_end, size_known, align=(0,0), clip_rect=None)` | draw text aligned inside a rect; `(0.5,0.5)` = centered |
| `imgui.internal.render_text_clipped_ex(draw_list, ...)` | same, explicit draw list |
| `imgui.internal.text_aligned(align_x, size_x, fmt)` | text aligned within `size_x` |
| `imgui.internal.render_text_ellipsis(draw_list, pos_min, pos_max, ellipsis_max_x, text, ...)` | truncate with `...` |
| `imgui.internal.render_text_wrapped(pos, text, text_end, wrap_width)` | draw wrapped |
| `imgui.internal.calc_wrap_width_for_pos(pos, wrap_pos_x)` | wrap width at a position |

## G. Style: spacing and padding

| field | default | `StyleVar_` | consumed by |
|---|---|---|---|
| `window_padding` | (8,8) | yes | cursor start, content region |
| `frame_padding` | (4,3) | yes | framed widgets, `frame_height`, baseline |
| `item_spacing` | (8,4) | yes | `.x` after `same_line`, `.y` after each line |
| `item_inner_spacing` | (4,4) | yes | box->label, slider->label, multi-component gap |
| `cell_padding` | (4,2) | yes | tables; `.x` per table, `.y` per row |
| `indent_spacing` | 21 | yes | `indent`, tree nodes |
| `columns_min_spacing` | 6 | no | legacy columns |
| `separator_text_padding` | (20,3) | yes | `separator_text` |
| `separator_text_border_size` | 3 | yes | `separator_text` |
| `scrollbar_size` | 14 | yes | subtracts from `avail` |
| `scrollbar_padding` | 2 | yes | grab inside scrollbar |
| `grab_min_size` | 12 | yes | slider/scrollbar grab |
| `image_border_size` | 0 | yes | `image()` |
| `window_min_size` | (32,32) | yes | |
| `window_border_size` / `child_border_size` / `popup_border_size` / `frame_border_size` | 1 / 1 / 1 / 0 | yes | |
| `window_border_hover_padding` | 4 | no | resize hit zone |
| `touch_extra_padding` | (0,0) | no | hit boxes only |
| `display_window_padding` | (19,19) | no | keep windows on screen |
| `display_safe_area_padding` | (3,3) | no | popups/tooltips edge margin |
| `docking_separator_size` | 2 | yes | |
| `tab_bar_border_size` / `tab_bar_overline_size` | 1 / 1 | yes | |
| `tab_min_width_base` / `tab_min_width_shrink` | 1 / 80 | yes | |
| `tree_lines_size` / `tree_lines_rounding` | 1 / 0 | yes | |
| `drag_drop_target_padding` / `_border_size` | 3 / 2 | no | |
| `log_slider_deadzone` | 4 | no | |
| `layout_align` | 0.5 | yes | stack layout minor axis |

## H. Style: alignment fields (0 = left/top, 0.5 = center, 1 = right/bottom)

| field | default | `StyleVar_` | applies to |
|---|---|---|---|
| `button_text_align` | (0.5,0.5) | yes | `button` label when button larger than text |
| `selectable_text_align` | (0,0) | yes | `selectable` label |
| `separator_text_align` | (0,0.5) | yes | `separator_text` label |
| `window_title_align` | (0,0.5) | yes | title bar text |
| `table_angled_headers_text_align` | (0.5,0) | yes | angled headers |
| `table_angled_headers_angle` | 35 deg | yes | angled headers |
| `layout_align` | 0.5 | yes | `begin_horizontal` / `begin_vertical` cross-axis |
| `window_menu_button_position` | `Dir_.left` | no | collapse button side |
| `color_button_position` | `Dir_.right` | no | swatch side in `color_edit` |

## I. Style API

| call | notes |
|---|---|
| `get_style()` | poke fields between frames |
| `push_style_var(idx, float or ImVec2)` / `pop_style_var(n=1)` | inside a frame |
| `push_style_var_x(idx, x)` / `push_style_var_y(idx, y)` | one component of an ImVec2 var |
| `imgui_ctx.push_style_var(idx, val)` | context manager |
| `get_style().scale_all_sizes(f)` | truncs every size to int; once, on a fresh style |
| `font_scale_main` / `font_scale_dpi` / `font_size_base` | font scale only, sizes untouched |
| `imgui.internal.get_style_var_info(idx)` | offset / type of a `StyleVar_` |

## J. Stack layout (pthom fork, `IMGUI_HAS_STACK_LAYOUT`)

| call | notes |
|---|---|
| `begin_horizontal(id, size=(0,0), align=-1)` / `end_horizontal()` | `size` 0 on an axis = shrink to content |
| `begin_vertical(id, size=(0,0), align=-1)` / `end_vertical()` | |
| `spring(weight=1, spacing=-1)` | share of free space; `weight 0` = fixed `spacing` only; `spacing -1` = `item_spacing` |
| `suspend_layout()` / `resume_layout()` | opt out for self-laid-out widgets |
| `align -1` | use `style.layout_align` |
| nested layout with size 0 | inherits parent size on that axis |
| `imgui_ctx.begin_horizontal(...)` / `begin_vertical(...)` | context managers |
| `separator()` inside | auto vertical/horizontal |

## K. Tables

| item | notes |
|---|---|
| `begin_table(id, columns, flags=0, outer_size=(0,0), inner_width=0)` | `outer_size < 0` = `avail + size`; `inner_width` with `scroll_x` |
| `table_setup_column(label, flags=0, init_width_or_weight=0, user_id=0)` | `width_fixed` = px, `width_stretch` = weight |
| `TableFlags_.sizing_fixed_fit` | columns = content width (default with `scroll_x`) |
| `TableFlags_.sizing_fixed_same` | all columns = widest |
| `TableFlags_.sizing_stretch_prop` | stretch by content ratio |
| `TableFlags_.sizing_stretch_same` | equal stretch (default without `scroll_x`) |
| `TableFlags_.no_pad_outer_x` / `pad_outer_x` / `no_pad_inner_x` | outer/inner `cell_padding.x` |
| `TableFlags_.no_host_extend_x` / `_y` | do not grow to parent when `outer_size` is 0 |
| `TableFlags_.scroll_x` / `scroll_y` | wraps in a child |
| `TableColumnFlags_.indent_enable` / `indent_disable` | apply `dc.indent` in cell (default col 0 only) |
| `TableColumnFlags_.no_resize`, `angled_header` | |
| `table_next_row(flags=0, min_row_height=0)` | row height floor |
| `table_next_column()` / `table_set_column_index(i)` | |
| `cell_padding` | `.x` locked per table, `.y` may vary per row |
| alignment inside a cell | none built-in: `set_cursor_pos_x` + `calc_text_size`, or `internal.text_aligned` |
| `imgui.internal.table_get_column_width_auto(table, column)` / `table_get_header_row_height()` | |

## L. Legacy columns (prefer tables)

| call | notes |
|---|---|
| `columns(count=1, id=None, borders=True)` / `next_column()` | |
| `set_column_width(i, w)` / `get_column_width(i)` | `i = -1` current |
| `set_column_offset(i, x)` / `get_column_offset(i)` | from content region left |
| `columns_min_spacing` | style |
| `separator()` | spans all columns |

## M. Windows and children

| call | notes |
|---|---|
| `set_next_window_pos(pos, cond=0, pivot=(0,0))` | `pivot` = anchor: `(1,0)` top-right, `(0.5,0.5)` centered |
| `set_next_window_size(size, cond=0)` | axis `0` = auto-fit |
| `set_next_window_size_constraints(min, max, cb=None)` | `FLT_MAX` = unbounded |
| `set_next_window_content_size(size)` | scroll range without widgets |
| `set_next_window_scroll(pos)` | |
| `WindowFlags_.always_auto_resize` | window = content each frame |
| `begin_child(id, size=(0,0), child_flags=0, window_flags=0)` | `0` = fill, `< 0` = `avail + size` |
| `ChildFlags_.auto_resize_x` / `_y` | child = content on that axis |
| `ChildFlags_.always_auto_resize` | re-measure every frame |
| `ChildFlags_.borders`, `frame_style`, `always_use_window_padding` | border / widget-like padding / padding without border |
| `ChildFlags_.resize_x` / `_y` | user-resizable from border |
| `ChildFlags_.nav_flattened` | nav crosses child boundary |
| `hello_imgui.widget_with_resize_handle(id, fn, handle_size_em=1, on_item_resized=None, on_item_hovered=None)` | corner handle on any widget |
| `imgui.internal.calc_window_next_auto_fit_size(window)` | |

## N. Overlap and hit-testing

| call | notes |
|---|---|
| `set_next_item_allow_overlap()` | later items may sit on top of the next one |
| `invisible_button(id, size, flags=0)` | interactive `dummy` |
| `touch_extra_padding` | hit box only, not layout |
| `imgui.internal.item_hoverable(bb, id, flags)` | |

## O. Internal layout primitives (`imgui.internal`)

| call | notes |
|---|---|
| `item_size(size or bb, text_baseline_y=-1)` | advance cursor |
| `item_add(bb, id, nav_bb=None, extra_flags=0)` | register; returns visible |
| `calc_item_size(size, default_w, default_h)` | `0` -> default, `< 0` -> `avail + size` |
| `get_current_window().dc` | `cursor_pos`, `cursor_pos_prev_line`, `cursor_max_pos`, `curr_line_size`, `prev_line_size`, `curr_line_text_base_offset`, `indent`, `group_offset`, `columns_offset`, `is_same_line`, `item_width`, `text_wrap_pos`, `layout_type` |
| `render_frame(p_min, p_max, col, borders=True, rounding=0)` | framed background |
| `shrink_widths(items, count, width_excess, width_min)` | tab-bar style shrink |
| `set_window_pos(window, pos, cond=0)` | |
| `get_window_scrollbar_rect(window, axis)` | |

## P. imgui_bundle helpers

| call | notes |
|---|---|
| `hello_imgui.em_size()` | `get_font_size()` |
| `hello_imgui.em_size(n)` | `n` lines |
| `hello_imgui.em_to_vec2(x, y)` / `em_to_vec2(v)` | ImVec2 in em |
| `hello_imgui.pixels_to_em(v)` / `pixel_size_to_em(f)` | inverse |
| `immapp.em_size` / `immapp.em_to_vec2` | re-exports |
| `hello_imgui.begin_group_column()` / `end_group_column()` | `begin_group` / `end_group + same_line` |
| `hello_imgui.image_from_asset(path, size)` / `image_size_from_asset(path)` | |
| `hello_imgui.DpiAwareParams.dpi_window_size_factor` / `dpi_font_loading_factor` | |
| `imgui_ctx.begin_group()`, `begin_horizontal`, `begin_vertical`, `push_style_var`, `push_item_width`, `push_text_wrap_pos`, `push_id`, `begin_child`, `begin_table` | context managers |

## Q. ImPlot / ImPlot3D

| item | notes |
|---|---|
| `implot.StyleVar_.plot_padding` | plot edge to axes |
| `implot.StyleVar_.label_padding` | axis labels, tick labels, edge |
| `implot.StyleVar_.legend_padding` / `legend_inner_padding` / `legend_spacing` | (10,10) / (5,5) / (5,0) |
| `implot.StyleVar_.mouse_pos_padding` / `annotation_padding` / `fit_padding` | |
| `implot.StyleVar_.plot_default_size` / `plot_min_size` | `begin_plot` size 0 / shrink floor |
| `implot.StyleVar_.major_tick_len` / `minor_tick_len` / `plot_border_size` | |
| `implot.setup_legend(location, flags=0)` | `Location_` bitmask `north | south | west | east | center` |
| `implot.plot_text(text, x, y, pix_offset=(0,0), flags=0)` | centered at point; `TextFlags_.vertical` |
| `implot.annotation(x, y, col, pix_offset, clamp, round=False)` | offset label, `clamp` keeps inside plot |
| `implot.tag_x(x, col, round=False)` / `tag_y` | axis tags |
| `implot3d.StyleVar_.legend_padding` / `legend_inner_padding` / `legend_spacing`, `implot3d.setup_legend(location, flags)` | same model |

## R. Formulas

| need | expression |
|---|---|
| right-align item of width `w` | `set_cursor_pos_x(get_cursor_pos_x() + avail.x - w)` |
| right-align via `same_line` | `same_line(get_window_width() - w - style.window_padding.x)` |
| center item of width `w` | `set_cursor_pos_x(get_cursor_pos_x() + (avail.x - w) * 0.5)` |
| center text in rect (draw list) | `pos = rect.min + (rect.size - calc_text_size(s)) * 0.5` |
| centered label in oversized button | `style.button_text_align = (0.5, 0.5)` (default) |
| fill width | `-imgui.FLT_MIN` |
| `n` equal columns | `(avail.x - (n-1) * item_spacing.x) / n` |
| button width for label | `calc_text_size(label).x + 2 * frame_padding.x` |
| widget row pitch | `get_frame_height_with_spacing()` |
| text row pitch | `get_text_line_height_with_spacing()` |
| leave one bottom row in a child | `begin_child(id, (0, -get_frame_height_with_spacing()))` |
| checkbox total width | `frame_height + item_inner_spacing.x + label.x` |
| tree indent | `indent_spacing` (21 ~ `font_size + 2*frame_padding.x`) |
| em | `hello_imgui.em_size(n)` = `n * get_font_size()` |
| pixel snap | cursor truncated to int each `item_size`; pass integer sizes |
