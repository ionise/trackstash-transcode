function Convert-TranscodeOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Flac', 'Aiff', 'Wav', 'Mp3')]
        [string]$TargetFormat,

        [Parameter()]
        [ValidateRange(8, 320)]
        [int]$BitrateKbps = 320,

        [Parameter()]
        [ValidateRange(8000, 384000)]
        [int]$SampleRate
    )

    $formatMap = @{
        Flac = [ordered]@{
            Extension      = 'flac'
            AudioArguments = @('-c:a', 'flac')
            MuxerArguments = @()
        }
        Aiff = [ordered]@{
            Extension      = 'aiff'
            AudioArguments = @('-c:a', 'pcm_s16be')
            MuxerArguments = @('-write_id3v2', '1')
        }
        Wav = [ordered]@{
            Extension      = 'wav'
            AudioArguments = @('-c:a', 'pcm_s16le')
            MuxerArguments = @()
        }
        Mp3 = [ordered]@{
            Extension      = 'mp3'
            AudioArguments = @(
                '-c:a', 'libmp3lame',
                '-b:a', ("{0}k" -f $BitrateKbps),
                '-joint_stereo', '1'
            )
            MuxerArguments = @('-id3v2_version', '3')
        }
    }

    $selected = $formatMap[$TargetFormat]
    $audioArguments = @($selected.AudioArguments)

    if ($PSBoundParameters.ContainsKey('SampleRate')) {
        $audioArguments += @('-ar', $SampleRate.ToString())
    }

    return [PSCustomObject]@{
        TargetFormat   = $TargetFormat
        Extension      = $selected.Extension
        AudioArguments = $audioArguments
        MuxerArguments = @($selected.MuxerArguments)
    }
}
