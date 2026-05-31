Describe 'Module import' {
    BeforeAll {
        $env:TRACKSTASH_SKIP_FFMPEG_CHECK = '1'
        $script:modulePath = Join-Path $PSScriptRoot '../trackstash.transcode/TrackStash.Transcode.psd1'
    }

    AfterAll {
        Remove-Item Env:TRACKSTASH_SKIP_FFMPEG_CHECK -ErrorAction SilentlyContinue
        Remove-Module TrackStash.Transcode -ErrorAction SilentlyContinue
    }

    It 'imports and exports expected functions' {
        Import-Module $script:modulePath -Force

        Get-Command Invoke-TrackStashTranscode -Module TrackStash.Transcode | Should -Not -BeNullOrEmpty
        Get-Command Get-TrackStashTranscodeInfo -Module TrackStash.Transcode | Should -Not -BeNullOrEmpty
        Get-Command Test-TrackStashFfmpeg -Module TrackStash.Transcode | Should -Not -BeNullOrEmpty
    }
}
