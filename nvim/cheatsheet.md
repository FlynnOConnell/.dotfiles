# Cheatsheet

`SPC k` toggle  ·  `e` edit source  ·  `q` close

## Debug: run & step

| Key          | Action                     | PyCharm       |
| ------------ | -------------------------- | ------------- |
| `,c` | Start / continue           | Shift+F9 / F9 |
| `,o` | Step over                  | F8            |
| `,i` | Step into                  | F7            |
| `,O` | Step out                   | Shift+F8      |
| `,s` | Run to here and stop, skipping other breakpoints; not debugging: pick a `,dd` command (last one first) | Alt+F9 |
| `,C` | Run to cursor (not paused: runs the cell, or reruns the last) | Alt+F9 |
| `,q` | Terminate                  | Ctrl+F2       |
| `,p` | Pause                      | Pause         |
| `,l` | Re-run last session        | Ctrl+F5       |
| `,dc` | Debug current file         | Shift+F9      |
| `,dd` | Run configs: saved commands, `<CR>` debugs, `dd` `yyp` edit; `<Tab>` to Variables (`SAMPLE = ~/data/x.tif`, used as `$SAMPLE`); a `# name` line above a command names it | Run configurations |
| `,dv` | The same run configs in the viewer: a form per command from its `--help`, data locations with file pickers; Debug, Run to nvim cursor, Run, Copy | Edit Configurations |

## Debug: breakpoints

| Key          | Action                     | PyCharm       |
| ------------ | -------------------------- | ------------- |
| `,b` | Toggle breakpoint          | Ctrl+F8       |
| `,B` | Conditional breakpoint     | Ctrl+Shift+F8 |

## Debug: inspect (popups; values show at line ends)

| Key          | Action                                        | PyCharm       |
| ------------ | --------------------------------------------- | ------------- |
| `,x` | Expand the values on this line (tree)            | Click inline value |
| `,V` | All your variables in this frame (tree)          | Variables |
| `<CR>` `h` `s` | In a tree: expand, collapse/parent, summary   |           |
| `,v` | Summary: type, shape, dtype, min/max/mean/std | View as Array |
| `,m` | Viewer: stack, variables, step buttons (on a variable: show it) | SciView |
| `,e` | Eval word / visual selection                  | Alt+F8        |
| `,k` | Up the call stack (toward the caller)         | Frames        |
| `,j` | Down the call stack                           | Frames        |
| `<CR>` | In the call stack pane (or viewer): go to frame | Frames      |
| `,g` | Go to the paused line (the arrow), from anywhere | Alt+F10 (Show Execution Point) |
| `,f` | Stack frames popup, Enter jumps               | Frames        |
| `,D` | Hide / show the console + call stack row      | Console       |
| `,u` | Variables / watches / breakpoints column      | Debug tab     |

## Tests (pytest via neotest)

| Key          | Action                          | PyCharm       |
| ------------ | ------------------------------- | ------------- |
| `<leader>td` | Debug nearest test              | Debug test    |
| `<leader>tr` | Run nearest test                | Ctrl+Shift+F10 |
| `<leader>tt` | Run whole file                  |               |
| `<leader>to` | Show output of test             |               |
| `<leader>ts` | Toggle test summary tree        | Run window    |
| `,c` | Pick "pytest: choose tests" to debug any -k selection |   |

## REPL (IPython, cells split by # %%)

| Key          | Action                               | PyCharm      |
| ------------ | ------------------------------------ | ------------ |
| `,rs` | Open / hide REPL                     | Python console |
| `,rc` | Run cell, move to next               | Run cell     |
| `,rl` | Run current line                     | Alt+Shift+E  |
| `,rr` | Run visual selection                 | Alt+Shift+E  |
| `,ru` | Run file up to cursor                |              |
| `,rf` | Run whole file                       |              |
| `,ri` | Interrupt (Ctrl-C)                   |              |
| `,rR` | Restart REPL                         | Rerun console |
| `,dr` | Debug cell: pause on its first line, `,i` steps in | Debug cell |
| `,da` | Attach debugger to REPL (then breakpoints in source stop) | Attach to process |

## Errors & diagnostics

| Key          | Action                               | PyCharm      |
| ------------ | ------------------------------------ | ------------ |
| `]e` `[e`    | Next / prev error                    | F2 / Shift+F2 |
| `]w` `[w`    | Next / prev warning                  |              |
| `]d` `[d`    | Next / prev any diagnostic           |              |
| `<leader>cd` | Show full message on this line       | Ctrl+F1      |
| `<leader>xX` | All problems in this file            | Problems tab |
| `<leader>xx` | All problems in project              | Problems tab |
| `]q` `[q`    | Next / prev item in that list        |              |

## Code (LSP)

| Key          | Action                               | PyCharm      |
| ------------ | ------------------------------------ | ------------ |
| `<leader>ca` | Quick fix / code action              | Alt+Enter    |
| `gd`         | Go to definition                     | Ctrl+B       |
| `gr`         | Find usages                          | Alt+F7       |
| `gI`         | Go to implementation                 | Ctrl+Alt+B   |
| `gy`         | Go to type definition                | Ctrl+Shift+B |
| `K`          | Hover docs                           | Ctrl+Q       |
| `gK`         | Signature help                       | Ctrl+P       |
| `<leader>cr` | Rename symbol                        | Shift+F6     |
| `<leader>cf` | Format file                          | Ctrl+Alt+L   |
| `<leader>ss` | Symbols in file                      | Ctrl+F12     |
| `<C-o>` `<C-i>` | Jump back / forward               | Ctrl+Alt+←/→ |
| `<leader>cv` | Pick venv                            |              |

## Shell

| Key          | Action                                   | PyCharm   |
| ------------ | ---------------------------------------- | --------- |
| `<C-/>`      | Toggle floating terminal (uses nvim env) | Alt+F12   |
| `:!`         | One-off shell command: :!uv pip install x |           |
