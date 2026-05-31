Describe 'CLI wrapper' {
    It 'exists at the expected path' {
        $cliPath = Join-Path $PSScriptRoot '../cli/trackstash-transcode.ps1'
        Test-Path -LiteralPath $cliPath -PathType Leaf | Should -BeTrue
    }

    It 'supports required long options in source' {
        $cliPath = Join-Path $PSScriptRoot '../cli/trackstash-transcode.ps1'
        $content = Get-Content -LiteralPath $cliPath -Raw

        $content | Should -Match '--input'
        $content | Should -Match '--output'
        $content | Should -Match '--format'
        $content | Should -Match '--verbose'
        $content | Should -Match '--dry-run'
    }
}
