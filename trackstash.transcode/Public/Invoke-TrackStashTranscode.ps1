<#
.SYNOPSIS
Transcodes audio files with ffmpeg while preserving metadata.

.DESCRIPTION
Transcodes one or more input files to FLAC, AIFF, WAV, or MP3 through ffmpeg.
Metadata is preserved by default using -map_metadata 0. The cmdlet supports
pipeline input and continues processing remaining files when a per-file error occurs.

.PARAMETER InputPath
One or more input file paths. Accepts pipeline input and objects with Path/FullName.

.PARAMETER OutputDirectory
Existing output directory where transcoded files are written.

.PARAMETER Format
Target format: Flac, Aiff, Wav, or Mp3.

.PARAMETER BitrateKbps
MP3 bitrate in kbps. Defaults to 320.

.PARAMETER SampleRate
Optional output sample rate. If omitted, source sample rate is preserved.

.PARAMETER Force
Overwrite existing output files.

.OUTPUTS
PSCustomObject containing per-file results, summary, and aggregate exit code.

.EXAMPLE
Get-ChildItem ./input/*.flac | Invoke-TrackStashTranscode -OutputDirectory ./out -Format Mp3 -Verbose
#>
function Invoke-TrackStashTranscode {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Path', 'FullName')]
        [string[]]$InputPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDirectory,

        [Parameter(Mandatory)]
        [ValidateSet('Flac', 'Aiff', 'Wav', 'Mp3')]
        [string]$Format,

        [Parameter()]
        [ValidateRange(8, 320)]
        [int]$BitrateKbps = 320,

        [Parameter()]
        [ValidateRange(8000, 384000)]
        [int]$SampleRate,

        [Parameter()]
        [switch]$Force
    )

    begin {
        $ffmpegPath = Resolve-FfmpegPath
        $startedUtc = (Get-Date).ToUniversalTime()

        if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("Output directory not found: $OutputDirectory")
        }

        $resolvedOutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
        $collectedInputs = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($path in $InputPath) {
            if ([string]::IsNullOrWhiteSpace($path)) {
                continue
            }

            [void]$collectedInputs.Add($path)
        }
    }

    end {
        if ($collectedInputs.Count -eq 0) {
            throw [System.ArgumentException]::new('At least one input file path is required.')
        }

        $results = @()
        $transcodeOptions = $null
        if ($PSBoundParameters.ContainsKey('SampleRate')) {
            $transcodeOptions = Convert-TranscodeOptions -TargetFormat $Format -BitrateKbps $BitrateKbps -SampleRate $SampleRate
        }
        else {
            $transcodeOptions = Convert-TranscodeOptions -TargetFormat $Format -BitrateKbps $BitrateKbps
        }

        foreach ($path in $collectedInputs) {
            $result = [PSCustomObject]@{
                InputPath  = $path
                OutputPath = $null
                Format     = $Format
                Success    = $false
                Skipped    = $false
                ExitCode   = 1
                Error      = $null
            }

            try {
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                    throw [System.IO.FileNotFoundException]::new("Input file not found: $path")
                }

                $resolvedInputPath = (Resolve-Path -LiteralPath $path).Path
                $outputName = "{0}.{1}" -f [System.IO.Path]::GetFileNameWithoutExtension($resolvedInputPath), $transcodeOptions.Extension
                $outputPath = Join-Path -Path $resolvedOutputDirectory -ChildPath $outputName
                $result.OutputPath = $outputPath

                if ((Test-Path -LiteralPath $outputPath -PathType Leaf) -and -not $Force) {
                    throw [System.IO.IOException]::new("Output file already exists: $outputPath. Use -Force to overwrite.")
                }

                $overwriteArgument = '-n'
                if ($Force) {
                    $overwriteArgument = '-y'
                }

                $arguments = @(
                    '-hide_banner',
                    $overwriteArgument,
                    '-i', $resolvedInputPath,
                    '-map_metadata', '0'
                )

                $arguments += $transcodeOptions.AudioArguments
                $arguments += $transcodeOptions.MuxerArguments
                $arguments += $outputPath

                if ($PSCmdlet.ShouldProcess($resolvedInputPath, "Transcode to $Format")) {
                    $processResult = Start-FfmpegProcess -FfmpegPath $ffmpegPath -ArgumentList $arguments -InputPath $resolvedInputPath -OutputPath $outputPath
                    $result.Success = $processResult.Success
                    $result.ExitCode = $processResult.ExitCode

                    if (-not $processResult.Success) {
                        $result.Error = if ([string]::IsNullOrWhiteSpace($processResult.StdErr)) {
                            "ffmpeg exited with code $($processResult.ExitCode)."
                        }
                        else {
                            $processResult.StdErr.Trim()
                        }

                        Write-Error -Message "Transcode failed for '$resolvedInputPath': $($result.Error)" -ErrorAction Continue
                    }
                }
                else {
                    $result.Skipped = $true
                    $result.Success = $true
                    $result.ExitCode = 0
                }
            }
            catch {
                $result.Error = $_.Exception.Message
                $result.Success = $false
                $result.Skipped = $false
                $result.ExitCode = 1
                Write-Error -Message "Transcode failed for '$path': $($_.Exception.Message)" -ErrorAction Continue
            }

            $results += $result
        }

        $processed = @($results | Where-Object { -not $_.Skipped })
        $summary = [PSCustomObject]@{
            Total      = $results.Count
            Processed  = $processed.Count
            Succeeded  = @($processed | Where-Object { $_.Success }).Count
            Failed     = @($processed | Where-Object { -not $_.Success }).Count
            Skipped    = @($results | Where-Object { $_.Skipped }).Count
            StartedUtc = $startedUtc
            EndedUtc   = (Get-Date).ToUniversalTime()
        }

        $aggregateExitCode = 0
        if ($summary.Failed -gt 0) {
            $aggregateExitCode = 1
        }

        return [PSCustomObject]@{
            Results  = $results
            Summary  = $summary
            ExitCode = $aggregateExitCode
        }
    }
}
