function Resolve-FfmpegPath {
    [CmdletBinding()]
    param()

    $command = Get-Command -Name 'ffmpeg' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) {
        return $command.Source
    }

    $guidance = if ($IsWindows) {
        @(
            'ffmpeg was not found in PATH.',
            'Install with winget: winget install Gyan.FFmpeg',
            'Or install with Chocolatey: choco install ffmpeg'
        )
    }
    elseif ($IsMacOS) {
        @(
            'ffmpeg was not found in PATH.',
            'Install with Homebrew: brew install ffmpeg'
        )
    }
    else {
        @(
            'ffmpeg was not found in PATH.',
            'Install with your package manager, for example:',
            'apt install ffmpeg',
            'dnf install ffmpeg',
            'pacman -S ffmpeg'
        )
    }

    $message = $guidance -join [Environment]::NewLine
    throw [System.InvalidOperationException]::new($message)
}
