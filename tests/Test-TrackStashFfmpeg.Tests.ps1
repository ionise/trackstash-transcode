Describe 'Test-TrackStashFfmpeg' {
    BeforeAll {
        $env:TRACKSTASH_SKIP_FFMPEG_CHECK = '1'
        Import-Module (Join-Path $PSScriptRoot '../trackstash.transcode/TrackStash.Transcode.psd1') -Force
    }

    AfterAll {
        Remove-Item Env:TRACKSTASH_SKIP_FFMPEG_CHECK -ErrorAction SilentlyContinue
        Remove-Module TrackStash.Transcode -ErrorAction SilentlyContinue
    }

    It 'returns available diagnostics when ffmpeg resolves' {
        InModuleScope TrackStash.Transcode {
            Mock Resolve-FfmpegPath { '/usr/bin/ffmpeg' }

            $result = Test-TrackStashFfmpeg

            $result.IsAvailable | Should -BeTrue
            $result.Path | Should -Be '/usr/bin/ffmpeg'
        }
    }

    It 'returns unavailable diagnostics when ffmpeg resolve fails' {
        InModuleScope TrackStash.Transcode {
            Mock Resolve-FfmpegPath { throw 'missing ffmpeg' }

            $result = Test-TrackStashFfmpeg

            $result.IsAvailable | Should -BeFalse
            $result.Diagnostic | Should -Match 'missing ffmpeg'
        }
    }
}
