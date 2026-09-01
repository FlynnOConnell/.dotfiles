# MBO PowerShell Profile

# === Path ===
$env:Path = "$env:USERPROFILE\.local\bin;$env:Path"

# === Network drives (RBO-S1) ===
if (!(Test-Path Y:)) {
    net use Y: \\RBO-S1\mbospace /user:foconnell "foconnell@RU2$" /persistent:yes 2>$null
}

# === PSReadLine ===
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# === Aliases ===
Set-Alias -Name lg -Value lazygit -ErrorAction SilentlyContinue
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name g -Value git -ErrorAction SilentlyContinue

# === ls -> eza ===
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { eza -l --icons --group-directories-first --no-permissions --no-time --no-user @args }
function lsv { eza -l --icons --group-directories-first @args }
function la { eza -la --icons --group-directories-first --no-permissions --no-time --no-user @args }
function lt { eza -T --icons --group-directories-first @args }
function ll { eza -l --icons --group-directories-first @args }

# === cat -> bat ===
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
function cat { bat --paging=never @args }

# === rm (unix-style) ===
Remove-Item Alias:rm -ErrorAction SilentlyContinue
function rm {
    param(
        [switch]$r, [switch]$f, [switch]$rf,
        [Parameter(ValueFromRemainingArguments)][string[]]$paths
    )
    $recurse = $r -or $rf
    $force = $f -or $rf
    foreach ($path in $paths) {
        Remove-Item $path -Recurse:$recurse -Force:$force -ErrorAction $(if($force){'SilentlyContinue'}else{'Stop'})
    }
}

# === Navigation ===
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# === Git shortcuts ===
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git pull @args }
function gd { git diff @args }
function gco { git checkout @args }
function gb { git branch @args }
function glog { git log --oneline --graph --decorate -20 @args }

# === Notes functions ===
$NotesVault = "$HOME\repos\arctic-lake"

# gsync - git sync repos (pull, commit, push)
function gsync {
    $repos = @("$HOME\repos\arctic-lake", "$HOME\repos\.dotfiles")
    foreach ($repo in $repos) {
        if (Test-Path "$repo\.git") {
            $name = Split-Path $repo -Leaf
            Write-Host "syncing $name..."
            git -C $repo pull --rebase --quiet 2>$null
            git -C $repo add -A
            $hasChanges = git -C $repo diff --cached --quiet 2>$null; $LASTEXITCODE -ne 0
            if ($hasChanges) {
                $d = Get-Date -Format "yyyy-MM-dd"
                git -C $repo commit -m "sync $d" --quiet
                git -C $repo push --quiet 2>$null
                Write-Host "  ${name}: pushed changes"
            } else {
                Write-Host "  ${name}: up to date"
            }
        }
    }
}

function _notesPull { git -C $NotesVault pull --rebase --quiet 2>$null }

# on - open notes (fzf browser)
function on {
    _notesPull
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $files = Get-ChildItem -Path $NotesVault -Recurse -Filter "*.md" | Select-Object -ExpandProperty FullName
        $selected = $files | ForEach-Object { $_.Replace("$NotesVault\", "") } | fzf --prompt="Note: " --height=40% --reverse
        if ($selected) { nvim "$NotesVault\$selected" }
    } else {
        nvim "$NotesVault\notes"
    }
}

# === nvim-keys ===
function nvim-keys {
    param([string]$mode = "n", [string]$filter = "")
    $lua = "for _,map in ipairs(vim.api.nvim_get_keymap('$mode')) do local desc = map.desc or map.rhs or '' if desc then print('$mode | ' .. map.lhs .. ' | ' .. desc) end end"
    $output = nvim --headless -c "lua $lua" -c "qa!" 2>&1 | ForEach-Object { $_.ToString() } | Where-Object { $_ -match "^\w+ \|" }
    if ($filter) { $output = $output | Where-Object { $_ -match $filter } }
    if ($output) { @("MODE | KEY | DESCRIPTION", "---- | --- | -----------") + ($output | Sort-Object) | bat --language=markdown --style=plain }
    else { Write-Host "No keybindings found for mode '$mode'" -ForegroundColor Yellow }
}

# === nvim-keys lsp cheat sheet ===
function nvim-lsp {
    $cheat = @"
# lsp navigation (active in any lsp-attached buffer)

  gd             goto definition        jump to where function/class/var is defined
  gr             goto references        show all callers/usages of symbol under cursor
  gI             goto implementation    jump to the actual implementation
  gD             goto declaration       jump to declaration
  <leader>D      type definition        jump to the type's definition
  <leader>ds     document symbols       list all functions/classes/vars in current file
  <leader>ws     workspace symbols      search all symbols across the entire project
  K              hover docs             show docstring/signature popup
  Ctrl-t         jump back              return to previous location after gd/gr/gI

# editing / refactoring

  <leader>rn     rename                 rename symbol across all files
  <leader>ca     code action            quick fixes, refactors, imports
  <leader>th     toggle inlay hints     show/hide inline type hints

# diagnostics

  gn             next diagnostic        jump to next error/warning
  gp             prev diagnostic        jump to previous error/warning
  <leader>e      show diagnostic        open error float at cursor
  <leader>q      quickfix list          open all diagnostics in quickfix

# python-specific (ruff + ty)

  ruff provides linting/formatting, ty provides go-to-definition/completions/hover
  use <leader>ds to browse all functions in a module
  use gr on a function to find everything that calls it
"@
    $cheat | bat --language=markdown --style=plain
}

# === Starship prompt ===
# Must come before zoxide: starship replaces `prompt`, zoxide only wraps it.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# === Startup: fastfetch + quick reference ===
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
    Write-Host ""
    Write-Host "  quick reference" -ForegroundColor Cyan
    Write-Host "    ls           list files                lsv         detailed list" -ForegroundColor Gray
    Write-Host "    lt           tree view                 la          list all (hidden)" -ForegroundColor Gray
    Write-Host "    cd <name>    smart jump (zoxide)       cd -        go back" -ForegroundColor Gray
    Write-Host "    on           browse notes (fzf)        lg          lazygit" -ForegroundColor Gray
    Write-Host "    gsync        sync notes + dotfiles     nvim-keys   show nvim keybindings" -ForegroundColor Gray
    Write-Host "    nvim-lsp     lsp cheat sheet           nvim-keys -filter lsp" -ForegroundColor Gray
    Write-Host ""
}

# === zoxide (smart cd) - must be last, after starship and any other prompt hooks ===
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# git bash on PATH, so .sh scripts (hpc/deploy.sh) run from powershell
$GitBin = "C:\Program Files\Git\bin"
if ((Test-Path $GitBin) -and ($env:Path -notlike "*$GitBin*")) {
    $env:Path = "$env:Path;$GitBin"
}
