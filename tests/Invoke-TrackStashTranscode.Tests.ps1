Describe 'Invoke-TrackStashTranscode' {
    BeforeAll {
        $env:TRACKSTASH_SKIP_FFMPEG_CHECK = '1'
        Import-Module (Join-Path $PSScriptRoot '../trackstash.transcode/TrackStash.Transcode.psd1') -Force
    }

    AfterAll {
        Remove-Item Env:TRACKSTASH_SKIP_FFMPEG_CHECK -ErrorAction SilentlyContinue
        Remove-Module TrackStash.Transcode -ErrorAction SilentlyContinue
    }

    It 'builds a metadata-preserving transcode command and succeeds' {
        InModuleScope TrackStash.Transcode {
            $outputDir = Join-Path $TestDrive 'out'
            New-Item -Path $outputDir -ItemType Directory | Out-Null
            $inputFile = Join-Path $TestDrive 'input.flac'
            Set-Content -Path $inputFile -Value 'fake'

            Mock Resolve-FfmpegPath { '/usr/bin/ffmpeg' }
            Mock Convert-TranscodeOptions {
                [PSCustomObject]@{
                    TargetFormat   = 'Mp3'
                    Extension      = 'mp3'
                    AudioArguments = @('-c:a', 'libmp3lame', '-b:a', '320k', '-joint_stereo', '1')
                    MuxerArguments = @('-id3v2_version', '3')
                }
            }
            Mock Start-FfmpegProcess {
                [PSCustomObject]@{
                    InputPath  = $InputPath
                    OutputPath = $OutputPath
                    Success    = $true
                    ExitCode   = 0
                    Arguments  = @($ArgumentList)
                }
            }

            $result = Invoke-TrackStashTranscode -InputPath $inputFile -OutputDirectory $outputDir -Format Mp3

            $result.ExitCode | Should -Be 0
            $result.Summary.Succeeded | Should -Be 1
            Should -Invoke Start-FfmpegProcess -Times 1 -ParameterFilter { $ArgumentList -contains '-map_metadata' }
        }
    }

    It 'continues on per-file error and returns aggregate non-zero exit code' {
        InModuleScope TrackStash.Transcode {
            $outputDir = Join-Path $TestDrive 'out2'
            New-Item -Path $outputDir -ItemType Directory | Out-Null

            $okInput = Join-Path $TestDrive 'ok.wav'
            Set-Content -Path $okInput -Value 'fake'
            $missingInput = Join-Path $TestDrive 'missing.wav'

            Mock Resolve-FfmpegPath { '/usr/bin/ffmpeg' }
            Mock Convert-TranscodeOptions {
                [PSCustomObject]@{
                    TargetFormat   = 'Flac'
                    Extension      = 'flac'
                    AudioArguments = @('-c:a', 'flac')
                    MuxerArguments = @()
                }
            }
            Mock Start-FfmpegProcess {
                [PSCustomObject]@{
                    InputPath  = $InputPath
                    OutputPath = $OutputPath
                    Success    = $true
                    ExitCode   = 0
                    Arguments  = @($ArgumentList)
                }
            }

            $result = Invoke-TrackStashTranscode -InputPath @($okInput, $missingInput) -OutputDirectory $outputDir -Format Flac

            $result.ExitCode | Should -Be 1
            $result.Summary.Total | Should -Be 2
            $result.Summary.Failed | Should -Be 1
            $result.Results.Count | Should -Be 2
        }
    }
}
