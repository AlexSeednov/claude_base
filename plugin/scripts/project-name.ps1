# Resolves a display name for the current project, used in Telegram notifications.
# Dot-sourced by telegram-notify.ps1 and telegram-waiting.ps1.

# Returns the project name for the given project directory.
# Order: explicit CLAUDE_PROJECT_NAME -> pubspec `name:` -> directory name -> fallback.
# The env var comes first so a project can override an ugly package/folder name
# ("cross_stitch") with the name it ships under ("Stitchy").
function Resolve-ProjectName {
    param([string]$PayloadCwd)

    if ($env:CLAUDE_PROJECT_NAME) {
        return $env:CLAUDE_PROJECT_NAME
    }

    $dir = $PayloadCwd
    if (-not $dir) { $dir = $env:CLAUDE_PROJECT_DIR }
    if (-not $dir) { $dir = (Get-Location).Path }

    if ($dir) {
        $pubspec = Join-Path $dir 'pubspec.yaml'
        if (Test-Path $pubspec) {
            try {
                foreach ($line in (Get-Content -Path $pubspec -Encoding utf8)) {
                    if ($line -match '^name:\s*(.+?)\s*(#.*)?$') {
                        $name = $Matches[1].Trim().Trim('"').Trim("'")
                        if ($name) { return $name }
                        break
                    }
                }
            } catch {}
        }

        try {
            $base = Split-Path -Path $dir -Leaf
            if ($base) { return $base }
        } catch {}
    }

    return 'Unknown project'
}
