# Sends a Telegram notification when Claude needs user input or is about to run a dangerous command.
# Fires on PreToolUse for: AskUserQuestion, Bash (dangerous patterns only).
# Required env vars: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID.

. (Join-Path $PSScriptRoot 'project-name.ps1')

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
        $text = "❓ Claude: $project — Question"
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
                $text = "⚠️ Claude: $project — Approval: $short"
                break
            }
        }
    }
}

if (-not $text) {
    # Not our case — silently pass through
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
