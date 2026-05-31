Describe 'Integration transcode (optional)' -Tag 'Integration' {
    BeforeAll {
        if (-not $env:TRACKSTASH_TEST_FFMPEG) {
            $env:TRACKSTASH_SKIP_FFMPEG_CHECK = '1'
        }

        Import-Module (Join-Path $PSScriptRoot '../trackstash.transcode/TrackStash.Transcode.psd1') -Force
    }

    AfterAll {
        if ($env:TRACKSTASH_SKIP_FFMPEG_CHECK) {
            Remove-Item Env:TRACKSTASH_SKIP_FFMPEG_CHECK -ErrorAction SilentlyContinue
        }

        Remove-Module TrackStash.Transcode -ErrorAction SilentlyContinue
    }

    It 'can transcode a tiny fixture when integration is enabled' {
        if (-not $env:TRACKSTASH_TEST_FFMPEG) {
            Set-ItResult -Skipped -Because 'TRACKSTASH_TEST_FFMPEG is not set.'
            return
        }

        $outDir = Join-Path $TestDrive 'out'
        New-Item -Path $outDir -ItemType Directory | Out-Null

        $inputFile = Join-Path $TestDrive 'input.wav'
        $ffmpeg = (Get-Command -Name ffmpeg -CommandType Application -ErrorAction Stop).Source
        & $ffmpeg -hide_banner -y -f lavfi -i 'sine=frequency=1000:duration=0.2' -c:a pcm_s16le $inputFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Failed to generate integration test fixture with ffmpeg.'
        }

        $result = Invoke-TrackStashTranscode -InputPath $inputFile -OutputDirectory $outDir -Format Mp3 -Force

        $result.ExitCode | Should -Be 0
        $result.Summary.Failed | Should -Be 0
    }
}
