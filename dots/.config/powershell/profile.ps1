# PowerShell Profile - Notes functions
# Symlink to: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

$NotesVault = "$HOME\repos\docs"

# gd - Go to daily note
function gd {
    $date = Get-Date -Format "yyyy-MM-dd"
    $dailyDir = "$NotesVault\daily"
    $file = "$dailyDir\$date.md"

    if (-not (Test-Path $dailyDir)) {
        New-Item -ItemType Directory -Path $dailyDir -Force | Out-Null
    }

    nvim $file
}

# gw - Go to weekly note (with template)
function gw {
    $weekNum = Get-Date -UFormat "%V"
    $year = Get-Date -Format "yyyy"
    $weeklyDir = "$NotesVault\weekly"
    $file = "$weeklyDir\$year-W$weekNum.md"

    if (-not (Test-Path $weeklyDir)) {
        New-Item -ItemType Directory -Path $weeklyDir -Force | Out-Null
    }

    # Create from template if doesn't exist
    if (-not (Test-Path $file)) {
        $templatePath = "$NotesVault\templates\weekly.md"

        if (Test-Path $templatePath) {
            # Calculate Monday-Friday range
            $today = Get-Date
            $dayOfWeek = [int]$today.DayOfWeek
            if ($dayOfWeek -eq 0) { $dayOfWeek = 7 }  # Sunday = 7
            $monday = $today.AddDays(-($dayOfWeek - 1))
            $friday = $monday.AddDays(4)

            $monMonth = $monday.ToString("MMMM")
            $friMonth = $friday.ToString("MMMM")
            $monDay = $monday.Day
            $friDay = $friday.Day
            $friYear = $friday.Year

            if ($monMonth -eq $friMonth) {
                $weekRange = "$monMonth $monDay-$friDay, $friYear"
            } else {
                $weekRange = "$monMonth $monDay - $friMonth $friDay, $friYear"
            }

            $dateShort = Get-Date -Format "yyyy-MM-dd"

            $content = Get-Content $templatePath -Raw
            $content = $content -replace '\{\{date\}\}', $dateShort
            $content = $content -replace '\{\{week_range\}\}', $weekRange
            # Handle Templater syntax for basic dates
            $content = $content -replace '<% tp\.date\.now\("YYYY-MM-DD"\) %>', $dateShort
            $content = $content -replace '<% tp\.date\.now\("MMMM DD"\) %>', $monday.ToString("MMMM dd")
            $content = $content -replace '<% tp\.date\.now\("MMMM DD, YYYY", 6\) %>', $friday.ToString("MMMM dd, yyyy")
            $content = $content -replace '<% tp\.date\.now\("YYYY-\[W\]WW", -7\) %>', "$year-W$([int]$weekNum - 1)"
            $content = $content -replace '<% tp\.date\.now\("YYYY-\[W\]WW", 7\) %>', "$year-W$([int]$weekNum + 1)"

            Set-Content -Path $file -Value $content
        }
    }

    nvim $file
}

# gn - Go to notes with interactive selection
function gn {
    $notesDir = "$NotesVault\notes"

    if (-not (Test-Path $notesDir)) {
        Write-Host "Notes directory not found: $notesDir" -ForegroundColor Red
        return
    }

    # Check if fzf is available
    $hasFzf = Get-Command fzf -ErrorAction SilentlyContinue

    if ($hasFzf) {
        # Use fzf for selection
        $folders = @("[New Note]") + (Get-ChildItem -Path $notesDir -Directory | Select-Object -ExpandProperty Name)
        $selectedFolder = $folders | fzf --prompt="Select folder: " --height=40% --reverse

        if (-not $selectedFolder) { return }

        if ($selectedFolder -eq "[New Note]") {
            $noteName = Read-Host "Enter note name"
            if ($noteName) {
                $file = "$notesDir\$noteName.md"
                nvim $file
            }
            return
        }

        $folderPath = "$notesDir\$selectedFolder"
        $notes = @("[New Note]", "[Back]") + (Get-ChildItem -Path $folderPath -Filter "*.md" | Select-Object -ExpandProperty Name)
        $selectedNote = $notes | fzf --prompt="Select note in $selectedFolder : " --height=40% --reverse

        if (-not $selectedNote -or $selectedNote -eq "[Back]") {
            gn  # Recursive call to go back
            return
        }

        if ($selectedNote -eq "[New Note]") {
            $noteName = Read-Host "Enter note name"
            if ($noteName) {
                if (-not $noteName.EndsWith(".md")) { $noteName += ".md" }
                $file = "$folderPath\$noteName"
                nvim $file
            }
            return
        }

        nvim "$folderPath\$selectedNote"
    }
    else {
        # Fallback: simple menu without fzf
        Write-Host "`nFolders in notes:" -ForegroundColor Cyan
        $folders = Get-ChildItem -Path $notesDir -Directory
        $i = 1
        Write-Host "  0. [New Note in root]" -ForegroundColor Yellow
        foreach ($folder in $folders) {
            Write-Host "  $i. $($folder.Name)"
            $i++
        }

        $choice = Read-Host "`nSelect folder number"

        if ($choice -eq "0") {
            $noteName = Read-Host "Enter note name"
            if ($noteName) {
                nvim "$notesDir\$noteName.md"
            }
            return
        }

        $selectedFolder = $folders[$choice - 1]
        if (-not $selectedFolder) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }

        Write-Host "`nNotes in $($selectedFolder.Name):" -ForegroundColor Cyan
        $notes = Get-ChildItem -Path $selectedFolder.FullName -Filter "*.md"
        $i = 1
        Write-Host "  0. [New Note]" -ForegroundColor Yellow
        foreach ($note in $notes) {
            Write-Host "  $i. $($note.BaseName)"
            $i++
        }

        $noteChoice = Read-Host "`nSelect note number"

        if ($noteChoice -eq "0") {
            $noteName = Read-Host "Enter note name"
            if ($noteName) {
                if (-not $noteName.EndsWith(".md")) { $noteName += ".md" }
                nvim "$($selectedFolder.FullName)\$noteName"
            }
            return
        }

        $selectedNote = $notes[$noteChoice - 1]
        if ($selectedNote) {
            nvim $selectedNote.FullName
        }
    }
}

# Aliases
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value nvim -ErrorAction SilentlyContinue

Write-Host "Notes functions loaded: gd (daily), gw (weekly), gn (notes browser)" -ForegroundColor Green
