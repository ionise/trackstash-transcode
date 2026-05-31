#requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$privateScripts = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File | Sort-Object Name
foreach ($script in $privateScripts) {
    . $script.FullName
}

$publicScripts = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File | Sort-Object Name
foreach ($script in $publicScripts) {
    . $script.FullName
}

if (-not $env:TRACKSTASH_SKIP_FFMPEG_CHECK) {
    try {
        Resolve-FfmpegPath | Out-Null
    }
    catch {
        throw
    }
}

Export-ModuleMember -Function @(
    'Invoke-TrackStashTranscode',
    'Get-TrackStashTranscodeInfo',
    'Test-TrackStashFfmpeg'
)
