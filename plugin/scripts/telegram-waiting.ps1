# Sends a Telegram notification when Claude needs user input or is about to run a dangerous command.
# Fires on PreToolUse for: AskUserQuestion, Bash (dangerous patterns only).
# Required env vars: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID.
#
# Keep this file pure ASCII. Windows PowerShell 5.1 reads a BOM-less script in the
# system ANSI codepage, so a literal glyph is decoded byte by byte: an em dash
# turns into a typographic quote, which PowerShell honours as a string delimiter
# and the whole script dies with a parser error before sending anything. Message
# glyphs are therefore built from code points below.

. (Join-Path $PSScriptRoot 'project-name.ps1')

# U+2753 BLACK QUESTION MARK ORNAMENT, U+26A0 WARNING SIGN followed by U+FE0F
# VARIATION SELECTOR-16 (renders the sign in colour), U+2014 EM DASH.
$glyphQuestion = [char]0x2753
$glyphWarning = [string][char]0x26A0 + [string][char]0xFE0F
$glyphDash = [char]0x2014

$input_json = [Console]::In.ReadToEnd()

$token = $env:TELEGRAM_BOT_TOKEN
$chatId = $env:TELEGRAM_CHAT_ID

if (-not $token -or -not $chatId) {
    Write-Output '{"continue":true}'
    exit 0
}

$data = $null
try {
    $data = $input_json | ConvertFrom-Json
} catch {
    Write-Output '{"continue":true}'
    exit 0
}

$toolName = $data.tool_name
$project = Resolve-ProjectName -PayloadCwd $data.cwd
$text = $null

switch ($toolName) {
    'AskUserQuestion' {
        # Claude is asking a clarifying question
        $text = "$glyphQuestion Claude: $project $glyphDash Question"
    }
    'Bash' {
        # Only notify for commands matching dangerous patterns
        $cmd = ''
        if ($data.tool_input -and $data.tool_input.command) {
            $cmd = $data.tool_input.command
        }
        $dangerousPatterns = @(
            '^\s*rm\b',
            '^\s*rmdir\b',
            '^\s*del\b',
            '^\s*kill\b',
            '^\s*curl\b',
            '^\s*wget\b',
            '^\s*eval\b',
            '^\s*chmod\b',
            '^\s*chown\b',
            '^\s*Remove-Item\b',
            '^\s*git\s+(push|reset|rebase|cherry-pick|merge|clean)\b',
            '--force',
            '--no-verify'
        )
        foreach ($pattern in $dangerousPatterns) {
            if ($cmd -match $pattern) {
                $short = $cmd
                if ($short.Length -gt 60) {
                    $short = $short.Substring(0, 60) + '...'
                }
                $text = "$glyphWarning Claude: $project $glyphDash Approval: $short"
                break
            }
        }
    }
}

if (-not $text) {
    # Not our case - silently pass through
    Write-Output '{"continue":true}'
    exit 0
}

$body = @{
    chat_id = $chatId
    text    = $text
} | ConvertTo-Json -Compress

$uri = "https://api.telegram.org/bot$token/sendMessage"

try {
    Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json; charset=utf-8' -Body $body -ErrorAction Stop | Out-Null
} catch {}

Write-Output '{"continue":true}'
exit 0
