# Sends a Telegram notification when Claude finishes a session.
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
} catch {}

# Extract session name from transcript (JSONL: one JSON line = one record)
$sessionName = $null
try {
    $transcriptPath = $null
    if ($data -and $data.transcript_path) {
        $transcriptPath = $data.transcript_path
    }
    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        $lines = Get-Content -Path $transcriptPath -Encoding utf8
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try {
                $entry = $line | ConvertFrom-Json
                if ($entry.type -eq 'user' -and $entry.message -and $entry.message.content) {
                    $raw = $entry.message.content
                    if ($raw -is [string] -and -not [string]::IsNullOrWhiteSpace($raw)) {
                        $firstLine = ($raw -split "`n")[0].Trim()
                        if ($firstLine.Length -gt 100) {
                            $firstLine = $firstLine.Substring(0, 100) + '...'
                        }
                        $sessionName = $firstLine
                        break
                    }
                }
            } catch { continue }
        }
    }
} catch {}

$project = Resolve-ProjectName -PayloadCwd $(if ($data) { $data.cwd } else { $null })

if ($sessionName) {
    $text = "✅ Claude: $project — $sessionName"
} else {
    $text = "✅ Claude: $project done"
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
