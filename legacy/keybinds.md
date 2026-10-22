# Keybinding Reference


## Modifier Keys

- `Mod` / `Win` = Windows/Super key (Mod4)
- `Alt` = Alt key (Mod1)

## Window Focus

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Focus left | `Mod+H` | `Win+H` |
| Focus down | `Mod+J` | `Win+J` |
| Focus up | `Mod+K` | `Win+K` |
| Focus right | `Mod+L` | `Win+L` |
| Focus left (arrow) | `Mod+Left` | `Win+Left` |
| Focus down (arrow) | `Mod+Down` | `Win+Down` |
| Focus up (arrow) | `Mod+Up` | `Win+Up` |
| Focus right (arrow) | `Mod+Right` | `Win+Right` |
| Focus parent | `Mod+A` | `Win+A` |

## Window Movement

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Move left | `Mod+Shift+H` | `Win+Shift+H` |
| Move down | `Mod+Shift+J` | `Win+Shift+J` |
| Move up | `Mod+Shift+K` | `Win+Shift+K` |
| Move right | `Mod+Shift+L` | `Win+Shift+L` |
| Move left (arrow) | `Mod+Shift+Left` | `Win+Shift+Left` |
| Move down (arrow) | `Mod+Shift+Down` | `Win+Shift+Down` |
| Move up (arrow) | `Mod+Shift+Up` | `Win+Shift+Up` |
| Move right (arrow) | `Mod+Shift+Right` | `Win+Shift+Right` |
| Promote to master | - | `Win+Return` |

## Window Actions

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Close window | `Mod+Q` | `Win+Q` |
| Minimize window | - | `Win+M` |
| Toggle fullscreen | `Mod+F` | `Win+F` (monocle) |
| Toggle floating | `Mod+M` | `Win+T` |

## Workspaces

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Switch to workspace 1-9 | `Mod+1-9` | `Win+1-9` |
| Move to workspace 1-9 | `Mod+Shift+1-9` | `Win+Shift+1-9` |
| Move workspace to output | `Mod+N` | `Win+N` (cycle monitor) |

## Layouts

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Stacking layout | `Mod+S` | `Win+S` (h-stack) |
| Tabbed layout | `Mod+W` | `Win+W` (cycle) |
| Toggle split | `Mod+E` | `Win+E` (flip h) |
| Split horizontal | `Mod+Shift+'` | - |
| Split vertical | `Mod+Shift+V` | - |

## Window Manager

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Restart WM | `Mod+Shift+R` | `Win+Shift+R` |
| Reload config | - | `Win+Shift+O` (whkd) |
| Exit WM | `Mod+Shift+E` | - |
| Pause WM | - | `Win+P` |

## Application Launchers

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| App launcher | `Alt+Space` | `Alt+Space` |
| Terminal | `Mod+Shift+T` | `Win+Shift+T` |
| Browser | `Mod+Shift+F` | `Win+Shift+B` |

## Resizing Windows

| Action | i3 (Linux) | komorebi (Windows) |
|--------|------------|-------------------|
| Resize mode | `Mod+R` | - |
| Increase horizontal | - | `Win++` |
| Decrease horizontal | - | `Win+-` |
| Increase vertical | - | `Win+Shift++` |
| Decrease vertical | - | `Win+Shift+-` |

### i3 Resize Mode Bindings

When in resize mode (`Mod+R`):
- `H` - Shrink width
- `J` - Shrink height
- `K` - Grow height
- `L` - Grow width
- `Esc` / `Return` - Exit resize mode

## Stacking (komorebi only)

| Action | Binding |
|--------|---------|
| Stack left | `Alt+Left` |
| Stack down | `Alt+Down` |
| Stack up | `Alt+Up` |
| Stack right | `Alt+Right` |
| Unstack | `Alt+;` |
| Cycle stack prev | `Win+[` |
| Cycle stack next | `Win+]` |

## Notes

### Platform Differences

**i3 (Linux)**
- Has a dedicated resize mode activated with `Mod+R`
- Supports true splitting (horizontal/vertical)
- Tabbed and stacking layouts work differently

**komorebi (Windows)**
- Resizing is done directly with `+/-` keys
- Uses different layout types (BSP, Stack, etc.)
- Has stacking feature with Alt+Arrows
- Monocle mode is similar to fullscreen

- **i3**: Edit `~/.config/i3/config`
- **komorebi**: Edit `~/.config/komorebi/komorebi.json` and `~/.config/whkd/whkdrc`
