<#
.SYNOPSIS
Tests whether ffmpeg is available for trackstash-transcode.

.DESCRIPTION
Checks whether ffmpeg can be resolved in PATH and returns structured diagnostics
for automation use.

.OUTPUTS
PSCustomObject with availability, path, and diagnostic information.

.EXAMPLE
Test-TrackStashFfmpeg
#>
function Test-TrackStashFfmpeg {
    [CmdletBinding()]
    param()

    try {
        $ffmpegPath = Resolve-FfmpegPath
        return [PSCustomObject]@{
            IsAvailable = $true
            Path        = $ffmpegPath
            Diagnostic  = 'ffmpeg was found in PATH.'
        }
    }
    catch {
        return [PSCustomObject]@{
            IsAvailable = $false
            Path        = $null
            Diagnostic  = $_.Exception.Message
        }
    }
}
