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
$NotesVault = "$HOME\repos\docs"

# gsync - git sync repos (pull, commit, push)
function gsync {
    $repos = @("$HOME\repos\docs", "$HOME\repos\.dotfiles")
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

# od - open daily note with template
function od {
    _notesPull
    $date = Get-Date -Format "yyyy-MM-dd"
    $file = "$NotesVault\daily\$date.md"
    if (!(Test-Path "$NotesVault\daily")) { New-Item -ItemType Directory -Path "$NotesVault\daily" -Force | Out-Null }

    if (!(Test-Path $file)) {
        $templatePath = "$NotesVault\templates\daily.md"
        if (Test-Path $templatePath) {
            $content = Get-Content $templatePath -Raw
            $content = $content -replace '\{\{date\}\}', $date
            Set-Content -Path $file -Value $content -NoNewline
        }
    }
    nvim $file
}

# ow - open weekly note with template
function ow {
    _notesPull
    $weekNum = [int](Get-Date -UFormat "%V")
    $year = Get-Date -Format "yyyy"
    $file = "$NotesVault\weekly\$year-W$($weekNum.ToString('00')).md"

    if (!(Test-Path "$NotesVault\weekly")) { New-Item -ItemType Directory -Path "$NotesVault\weekly" -Force | Out-Null }

    if (!(Test-Path $file)) {
        $templatePath = "$NotesVault\templates\weekly.md"
        if (Test-Path $templatePath) {
            $today = Get-Date
            $dayOfWeek = [int]$today.DayOfWeek
            if ($dayOfWeek -eq 0) { $dayOfWeek = 7 }
            $monday = $today.AddDays(-($dayOfWeek - 1))
            $friday = $monday.AddDays(4)

            $dateShort = Get-Date -Format "yyyy-MM-dd"
            $monDate = $monday.ToString("MMMM dd")
            $friDate = $friday.ToString("MMMM dd, yyyy")
            $prevWeek = "$year-W$(($weekNum - 1).ToString('00'))"
            $nextWeek = "$year-W$(($weekNum + 1).ToString('00'))"

            $content = Get-Content $templatePath -Raw
            # Templater syntax
            $content = $content -replace '<%\s*tp\.date\.now\("YYYY-MM-DD"\)\s*%>', $dateShort
            $content = $content -replace '<%\s*tp\.date\.now\("MMMM DD"\)\s*%>', $monDate
            $content = $content -replace '<%\s*tp\.date\.now\("MMMM DD, YYYY", 6\)\s*%>', $friDate
            $content = $content -replace '<%\s*tp\.date\.now\("YYYY-\[W\]WW", -7\)\s*%>', $prevWeek
            $content = $content -replace '<%\s*tp\.date\.now\("YYYY-\[W\]WW", 7\)\s*%>', $nextWeek
            # Obsidian syntax
            $content = $content -replace '\{\{date\}\}', $dateShort
            $content = $content -replace '\{\{week_range\}\}', "$monDate - $friDate"

            Set-Content -Path $file -Value $content -NoNewline
        }
    }
    nvim $file
}

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

# === zoxide (smart cd) ===
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# === Starship prompt ===
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
    Write-Host "    od           open daily note           ow          open weekly note" -ForegroundColor Gray
    Write-Host "    on           browse notes (fzf)        lg          lazygit" -ForegroundColor Gray
    Write-Host "    gsync        sync docs + dotfiles      nvim-keys   show nvim keybindings" -ForegroundColor Gray
    Write-Host ""
}
