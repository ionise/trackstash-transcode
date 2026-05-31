<#
.SYNOPSIS
Gets ffmpeg and format support details for trackstash-transcode.

.DESCRIPTION
Resolves ffmpeg, returns version information, and reports target formats
supported by this module.

.OUTPUTS
PSCustomObject with ffmpeg path, version line, and module format support.

.EXAMPLE
Get-TrackStashTranscodeInfo
#>
function Get-TrackStashTranscodeInfo {
    [CmdletBinding()]
    param()

    $ffmpegPath = Resolve-FfmpegPath
    $versionLine = (& $ffmpegPath -version 2>$null | Select-Object -First 1)

    $formatInfo = @(
        Convert-TranscodeOptions -TargetFormat Flac
        Convert-TranscodeOptions -TargetFormat Aiff
        Convert-TranscodeOptions -TargetFormat Wav
        Convert-TranscodeOptions -TargetFormat Mp3
    ) | ForEach-Object {
        [PSCustomObject]@{
            Format    = $_.TargetFormat
            Extension = $_.Extension
        }
    }

    return [PSCustomObject]@{
        FfmpegPath       = $ffmpegPath
        FfmpegVersion    = $versionLine
        SupportedFormats = $formatInfo
        CheckedAtUtc     = (Get-Date).ToUniversalTime()
    }
}
